# scripts/actors/shadow.gd
class_name ShadowEnemy
extends CharacterBody2D

@export var patrol_speed: float = 42.0
@export var patrol_distance: float = 56.0
@export var is_crying_shadow: bool = false
@export var is_boss_shadow: bool = false
@export var gravity: float = 900.0

var _start_x: float = 0.0
var _direction: float = 1.0
var _stun_timer: float = 0.0
var _dialogue_triggered: bool = false
var _transformed: bool = false
var _boss_peace_progress: float = 0.0
var _wobble_time: float = 0.0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hitbox: Hitbox = $Hitbox
@onready var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
	add_to_group("shadows")
	_start_x = global_position.x
	if is_crying_shadow and hitbox:
		hitbox.monitoring = false
		hitbox.monitorable = false
	if is_boss_shadow:
		scale = Vector2(2.2, 2.2)

func _physics_process(delta: float) -> void:
	if _transformed:
		return

	_wobble_time += delta * 6.0

	if not is_on_floor():
		velocity.y += gravity * delta

	if is_crying_shadow:
		velocity.x = 0.0
		move_and_slide()
		if sprite:
			sprite.scale = Vector2(1.0 + sin(_wobble_time * 1.5) * 0.08, 1.0 - sin(_wobble_time * 1.5) * 0.08)
		_play_anim("crying")
		_check_crying_interaction()
		return

	if is_boss_shadow:
		_process_boss(delta)
		return

	if _stun_timer > 0.0:
		_stun_timer = maxf(0.0, _stun_timer - delta)
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
		if hitbox:
			hitbox.set_deferred("monitorable", false)
		if sprite:
			sprite.rotation = sin(_wobble_time * 4.5) * 0.25
		_play_anim("stunned")
	else:
		if hitbox:
			hitbox.set_deferred("monitorable", true)
		velocity.x = _direction * patrol_speed
		if absf(global_position.x - _start_x) >= patrol_distance or is_on_wall():
			_direction *= -1.0
			_start_x = global_position.x
			_squash(Vector2(0.72, 1.28))
		if sprite:
			sprite.flip_h = _direction < 0.0
			sprite.rotation = sin(_wobble_time) * 0.08
		_play_anim("move")

	move_and_slide()

func _process_boss(delta: float) -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var p: Node2D = players[0] as Node2D
	var dist := global_position.distance_to(p.global_position)
	if _stun_timer > 0.0:
		_stun_timer = maxf(0.0, _stun_timer - delta)
		velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
		_play_anim("stunned")
	elif dist < 88.0:
		velocity.x = 0.0
		if hitbox:
			hitbox.set_deferred("monitorable", false)
		_boss_peace_progress += delta
		if sprite:
			sprite.modulate = Color(1.0, 0.95, 0.75, 1.0)
		_play_anim("idle")
		if _boss_peace_progress >= 2.2:
			transform_into_light()
			Events.light_shared.emit(global_position)
	else:
		if hitbox:
			hitbox.set_deferred("monitorable", true)
		if sprite:
			sprite.modulate = Color.WHITE
		var dir := signf(p.global_position.x - global_position.x)
		velocity.x = dir * (patrol_speed * 0.65)
		_play_anim("move")
	move_and_slide()

func _check_crying_interaction() -> void:
	if _dialogue_triggered:
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var p: Node2D = players[0] as Node2D
	if global_position.distance_to(p.global_position) <= 42.0:
		_dialogue_triggered = true
		var lines: Array[String] = [
			"Lumi: Você está chorando... Você não quer me machucar, quer?",
			"Sombra: Nós só temos medo de ficar sozinhas no escuro..."
		]
		Events.dialogue_requested.emit(lines)

func apply_pulse_stun(push_dir: Vector2, duration: float = 2.0) -> void:
	if is_crying_shadow or _transformed:
		return
	_stun_timer = duration
	velocity = Vector2(push_dir.x * 195.0, -125.0)
	_squash(Vector2(1.70, 0.45))
	VfxHelper.spawn_dust_burst(get_parent(), global_position, 14, Color(0.75, 0.55, 1.0, 0.95), true, push_dir, 140.0, 45.0, 120.0)
	VfxHelper.spawn_floating_text(get_parent(), global_position, "ATORDOADA!", Color(0.85, 0.75, 1.0, 1.0))
	if is_boss_shadow:
		_boss_peace_progress = 0.0

func apply_stomp() -> bool:
	if is_crying_shadow or _transformed:
		return false
	apply_pulse_stun(Vector2.UP, 2.0)
	return true

func transform_into_light() -> void:
	if _transformed:
		return
	_transformed = true
	if hitbox:
		hitbox.set_deferred("monitorable", false)
		hitbox.set_deferred("monitoring", false)
	_squash(Vector2(1.6, 1.6))
	VfxHelper.spawn_dust_burst(get_parent(), global_position, 22, Color(1.0, 0.92, 0.5, 1.0), true, Vector2.UP, 180.0, 40.0, 130.0)
	_play_anim("vanish")
	AudioManager.play_sfx("collect", 0.1)

func _squash(target_scale: Vector2) -> void:
	if not sprite:
		return
	sprite.scale = target_scale
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _play_anim(anim_name: String) -> void:
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name:
			sprite.play(anim_name)
