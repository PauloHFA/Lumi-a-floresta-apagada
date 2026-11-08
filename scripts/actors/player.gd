# scripts/actors/player.gd
class_name Player
extends CharacterBody2D

@export var max_speed: float = 140.0
@export var acceleration: float = 1050.0
@export var friction: float = 1550.0
@export var jump_velocity: float = -325.0
@export var gravity: float = 840.0
@export var fall_gravity: float = 1320.0
@export var max_fall_speed: float = 420.0
@export var apex_threshold: float = 48.0
@export var apex_gravity_mult: float = 0.45
@export var glide_gravity: float = 210.0
@export var glide_max_fall_speed: float = 72.0
@export var glide_boost_velocity: float = -185.0
@export var dash_speed: float = 345.0
@export var dash_duration: float = 0.14
@export var wall_slide_speed: float = 68.0
@export var coyote_time: float = 0.11
@export var jump_buffer_time: float = 0.11
@export var pulse_radius: float = 96.0
@export var pulse_cooldown: float = 2.0
@export var stomp_speed: float = 560.0
@export var stomp_bounce_velocity: float = -270.0
@export var fall_death_y: float = 356.0

var _coyote: float = 0.0
var _buffer: float = 0.0
var _pulse_timer: float = 0.0
var _dash_timer: float = 0.0
var _dash_cooldown: float = 0.0
var _can_dash: bool = true
var _dash_dir: float = 1.0
var _was_on_floor: bool = false
var _was_on_wall: bool = false
var _is_wall_sliding: bool = false
var _last_vy: float = 0.0
var _used_glide_jump: bool = false
var _is_gliding: bool = false
var _is_dying: bool = false
var _hurt_timer: float = 0.0
var _pulse_anim_timer: float = 0.0
var _is_stomping: bool = false
var _stomp_hit: bool = false
var _afterimage_timer: float = 0.0
var _step_dust_timer: float = 0.0
var _in_mud: bool = false
var _wind_force: Vector2 = Vector2.ZERO
var _controls_locked: bool = false
var _squash_tween: Tween
var spawn_position: Vector2 = Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var light: PointLight2D = $Light
@onready var camera: Camera2D = $Camera2D
@onready var health: HealthComponent = $HealthComponent
@onready var pulse_area: Area2D = $PulseArea
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var pulse_visual: Sprite2D = $PulseVisual
@onready var stomp_area: Area2D = $StompArea

func _ready() -> void:
	add_to_group("player")
	spawn_position = global_position
	health.health_changed.connect(_on_health_changed)
	health.depleted.connect(_on_health_depleted)
	hurtbox.hit_received.connect(_on_hit_received)
	stomp_area.area_entered.connect(_on_stomp_area_entered)
	Events.checkpoint_reached.connect(_on_checkpoint_reached)
	Events.spark_collected.connect(_on_spark_collected)
	Events.shard_collected.connect(_on_shard_collected)
	Events.radiance_level_up.connect(_on_radiance_level_up)
	Events.dialogue_requested.connect(_on_dialogue_started)
	Events.dialogue_finished.connect(_on_dialogue_finished)
	_update_light_visual()

func _physics_process(delta: float) -> void:
	var total_cd := maxf(0.6, pulse_cooldown - GameState.get_pulse_cooldown_reduction())
	if _pulse_timer > 0.0:
		_pulse_timer = maxf(0.0, _pulse_timer - delta)
		Events.pulse_cooldown_updated.emit(_pulse_timer, total_cd)
	if _hurt_timer > 0.0:
		_hurt_timer = maxf(0.0, _hurt_timer - delta)
	if _pulse_anim_timer > 0.0:
		_pulse_anim_timer = maxf(0.0, _pulse_anim_timer - delta)
	if _dash_cooldown > 0.0:
		_dash_cooldown = maxf(0.0, _dash_cooldown - delta)

	if _is_dying:
		velocity.y += gravity * 0.65 * delta
		move_and_slide()
		sprite.rotation += 14.0 * delta
		return

	if global_position.y > fall_death_y:
		_trigger_death(true)
		return

	if _controls_locked:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		_apply_gravity(delta)
		move_and_slide()
		_update_animation(delta)
		return

	# Durante o Dash de Luz: movimento horizontal puro e invulnerável
	if _dash_timer > 0.0:
		_dash_timer = maxf(0.0, _dash_timer - delta)
		velocity = Vector2(_dash_dir * dash_speed * GameState.get_speed_multiplier(), 0.0)
		move_and_slide()
		_handle_trail_and_dust(delta)
		_update_animation(delta)
		return

	_last_vy = velocity.y
	_apply_gravity(delta)
	_handle_horizontal(delta)
	_handle_jump(delta)
	_handle_dash()
	_handle_stomp()
	_handle_pulse()

	velocity += _wind_force * delta
	move_and_slide()
	if _is_stomping:
		for area: Area2D in stomp_area.get_overlapping_areas():
			if _try_stomp_enemy(area):
				break

	if not _was_on_wall and is_on_wall() and not is_on_floor():
		_squash_sprite(Vector2(0.62, 1.38), 0.18)
		VfxHelper.spawn_dust_burst(get_parent(), global_position, 6, Color(0.85, 0.9, 1.0, 0.8), false, Vector2.UP, 90.0, 20.0, 65.0)
		_shake_camera(2.0, 0.08)

	if not _was_on_floor and is_on_floor():
		var impact_ratio := clampf(absf(_last_vy) / max_fall_speed, 0.25, 1.0)
		if _is_stomping:
			_is_stomping = false
			VfxHelper.spawn_dust_burst(get_parent(), global_position + Vector2(0, 7), 12, GameState.get_aura_color(), true, Vector2.UP, 180.0, 45.0, 115.0)
			VfxHelper.spawn_floating_text(get_parent(), global_position, "POW!", GameState.get_aura_color())
		AudioManager.play_sfx("land", 0.09)
		_used_glide_jump = false
		_is_gliding = false
		_can_dash = true
		sprite.rotation = 0.0
		var sx := lerpf(1.28, 1.68, impact_ratio)
		var sy := lerpf(0.75, 0.44, impact_ratio)
		_squash_sprite(Vector2(sx, sy), 0.26)
		var dust_color := Color(0.65, 0.42, 0.85, 0.9) if _in_mud else Color(0.95, 0.95, 1.0, 0.85)
		VfxHelper.spawn_dust_burst(get_parent(), global_position + Vector2(0, 7), int(8 + impact_ratio * 10), dust_color, false, Vector2.UP, 150.0, 30.0, 95.0)
		if impact_ratio > 0.65:
			_shake_camera(3.5 * impact_ratio, 0.12)

	if is_on_floor():
		_used_glide_jump = false
		_is_gliding = false
		_can_dash = true

	_was_on_floor = is_on_floor()
	_was_on_wall = is_on_wall()
	_handle_trail_and_dust(delta)
	_update_animation(delta)

func _apply_gravity(delta: float) -> void:
	_is_wall_sliding = false
	if _is_stomping:
		velocity.y = stomp_speed
		return
	if not is_on_floor():
		var input_dir := Input.get_axis("move_left", "move_right")
		if is_on_wall_only() and velocity.y > 0.0 and input_dir != 0.0:
			# Wall Slide (Deslizar na parede suavemente)
			_is_wall_sliding = true
			velocity.y = minf(velocity.y + gravity * 0.4 * delta, wall_slide_speed)
			return

		var can_glide := GameState.unlocked_glide and Input.is_action_pressed("jump") and velocity.y > 0.0
		_is_gliding = can_glide
		if _is_gliding:
			velocity.y = minf(velocity.y + glide_gravity * delta, glide_max_fall_speed)
		elif absf(velocity.y) < apex_threshold:
			velocity.y += gravity * apex_gravity_mult * delta
		elif velocity.y < 0.0:
			velocity.y += gravity * delta
		else:
			velocity.y = minf(velocity.y + fall_gravity * delta, max_fall_speed)

func _handle_horizontal(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	var mud_mult := 0.65 if _in_mud else 1.0
	var apex_bonus := 1.12 if (not is_on_floor() and absf(velocity.y) < apex_threshold) else 1.0
	var current_max_speed := max_speed * GameState.get_speed_multiplier() * mud_mult * apex_bonus

	if dir != 0.0:
		_dash_dir = signf(dir)
		velocity.x = move_toward(velocity.x, dir * current_max_speed, acceleration * delta)
		sprite.flip_h = dir < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

func _handle_jump(delta: float) -> void:
	_coyote = coyote_time if is_on_floor() else _coyote - delta
	_buffer = jump_buffer_time if Input.is_action_just_pressed("jump") else _buffer - delta

	var effective_jump := jump_velocity * (0.70 if _in_mud else 1.0)

	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = effective_jump
		_buffer = 0.0
		_coyote = 0.0
		AudioManager.play_sfx("jump")
		_squash_sprite(Vector2(0.52, 1.58), 0.25)
		var jump_color := Color(0.7, 0.45, 0.9, 0.9) if _in_mud else GameState.get_aura_color()
		VfxHelper.spawn_dust_burst(get_parent(), global_position + Vector2(0, 7), 10, jump_color, false, Vector2.UP, 110.0, 35.0, 90.0)
		_shake_camera(1.6, 0.07)
	elif Input.is_action_just_pressed("jump") and is_on_wall_only() and not is_on_floor():
		# Wall Jump (Quicar na parede com impulso diagonal!)
		var wall_normal := get_wall_normal()
		velocity.x = wall_normal.x * max_speed * 1.35
		velocity.y = effective_jump * 0.92
		_dash_dir = signf(wall_normal.x)
		sprite.flip_h = _dash_dir < 0.0
		AudioManager.play_sfx("jump", 0.1)
		_squash_sprite(Vector2(0.55, 1.55), 0.24)
		VfxHelper.spawn_dust_burst(get_parent(), global_position, 12, GameState.get_aura_color(), true, wall_normal, 90.0, 40.0, 100.0)
		_shake_camera(2.2, 0.08)
	elif Input.is_action_just_pressed("jump") and not is_on_floor() and GameState.unlocked_glide and not _used_glide_jump:
		_used_glide_jump = true
		velocity.y = glide_boost_velocity
		_is_gliding = true
		AudioManager.play_sfx("double_jump", 0.08)
		_squash_sprite(Vector2(1.45, 0.62), 0.24)
		_do_aerial_spin()
		VfxHelper.spawn_dust_burst(get_parent(), global_position, 14, GameState.get_aura_color(), true, Vector2.DOWN, 180.0, 45.0, 110.0)
		_shake_camera(2.2, 0.09)

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.45

func _handle_dash() -> void:
	if _is_stomping:
		return
	if Input.is_action_just_pressed("dash") and _can_dash and _dash_cooldown <= 0.0:
		_can_dash = false
		_dash_timer = dash_duration
		_dash_cooldown = 0.42
		health.invulnerable_timer = maxf(health.invulnerable_timer, dash_duration + 0.08)
		var input_dir := Input.get_axis("move_left", "move_right")
		if input_dir != 0.0:
			_dash_dir = signf(input_dir)
		else:
			_dash_dir = -1.0 if sprite.flip_h else 1.0
		AudioManager.play_sfx("dash", 0.06)
		_squash_sprite(Vector2(1.85, 0.42), 0.22)
		_shake_camera(3.8, 0.12)
		VfxHelper.spawn_dust_burst(get_parent(), global_position, 16, GameState.get_aura_color(), true, Vector2(-_dash_dir, 0), 75.0, 55.0, 145.0)

func _handle_stomp() -> void:
	if Input.is_action_just_pressed("stomp"):
		_start_stomp()

func _start_stomp() -> void:
	if not GameState.unlocked_stomp or _is_stomping or _dash_timer > 0.0 or (is_on_floor() and velocity.y >= 0.0):
		return
	_is_stomping = true
	_stomp_hit = false
	velocity.y = stomp_speed
	_is_gliding = false
	health.invulnerable_timer = maxf(health.invulnerable_timer, 0.22)
	AudioManager.play_sfx("pulse", 0.08)
	_squash_sprite(Vector2(0.72, 1.45), 0.18)
	VfxHelper.spawn_dust_burst(get_parent(), global_position + Vector2(0, 6), 10, GameState.get_aura_color(), true, Vector2.UP, 90.0, 55.0, 110.0)

func _on_stomp_area_entered(area: Area2D) -> void:
	_try_stomp_enemy(area)

func _try_stomp_enemy(area: Area2D) -> bool:
	if not _is_stomping or _stomp_hit:
		return false
	var enemy := area.get_parent() as ShadowEnemy
	if not enemy or not enemy.apply_stomp():
		return false
	_stomp_hit = true
	_is_stomping = false
	health.invulnerable_timer = maxf(health.invulnerable_timer, 0.3)
	AudioManager.play_sfx("bounce", 0.06)
	bounce(stomp_bounce_velocity)
	VfxHelper.spawn_dust_burst(get_parent(), global_position, 18, GameState.get_aura_color(), true, Vector2.UP, 180.0, 55.0, 135.0)
	VfxHelper.spawn_floating_text(get_parent(), global_position, "STOMP!", GameState.get_aura_color())
	_shake_camera(5.0, 0.16)
	VfxHelper.hitstop(self, 0.06, 0.05)
	return true

func bounce(bounce_velocity: float = -430.0) -> void:
	velocity.y = bounce_velocity
	_used_glide_jump = false
	_can_dash = true
	_is_gliding = false
	_squash_sprite(Vector2(0.48, 1.72), 0.30)
	_do_aerial_spin()
	_shake_camera(4.2, 0.14)

func _do_aerial_spin() -> void:
	if not sprite:
		return
	var spin_dir := -1.0 if sprite.flip_h else 1.0
	sprite.rotation = 0.0
	var tw := create_tween()
	tw.tween_property(sprite, "rotation", TAU * spin_dir, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void: sprite.rotation = 0.0)

func _handle_pulse() -> void:
	if not GameState.unlocked_pulse:
		return
	var total_cd := maxf(0.6, pulse_cooldown - GameState.get_pulse_cooldown_reduction())
	if Input.is_action_just_pressed("pulse") and _pulse_timer <= 0.0:
		_pulse_timer = total_cd
		_pulse_anim_timer = 0.35
		Events.pulse_cooldown_updated.emit(_pulse_timer, total_cd)
		AudioManager.play_sfx("pulse")
		_trigger_pulse_effect()

func _trigger_pulse_effect() -> void:
	var effective_radius := pulse_radius + GameState.get_pulse_radius_bonus()
	_squash_sprite(Vector2(1.65, 1.65), 0.30)
	_shake_camera(5.0, 0.18)
	VfxHelper.spawn_dust_burst(get_parent(), global_position, 20, GameState.get_aura_color(), true, Vector2.UP, 180.0, 60.0, 150.0)

	if pulse_visual:
		pulse_visual.visible = true
		pulse_visual.scale = Vector2(0.2, 0.2)
		var alpha_start := 0.45 if GameState.reduce_flashes else 0.95
		var c := GameState.get_aura_color()
		pulse_visual.modulate = Color(c.r, c.g, c.b, alpha_start)
		var target_scale := 3.0 * (effective_radius / 96.0)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(pulse_visual, "scale", Vector2(target_scale, target_scale), 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(pulse_visual, "modulate:a", 0.0, 0.32)
		tw.chain().tween_callback(func() -> void: pulse_visual.visible = false)

	Events.pulse_triggered.emit(global_position, effective_radius)

	var hit_any := false
	for node: Node in get_tree().get_nodes_in_group("shadows"):
		if node is Node2D:
			var enemy: Node2D = node
			var dist := global_position.distance_to(enemy.global_position)
			if dist <= effective_radius and enemy.has_method("apply_pulse_stun"):
				var push_dir := (enemy.global_position - global_position).normalized()
				if push_dir == Vector2.ZERO:
					push_dir = Vector2.RIGHT
				enemy.call("apply_pulse_stun", push_dir, 2.0)
				hit_any = true

	if hit_any:
		VfxHelper.hitstop(self, 0.06, 0.05)

func _handle_trail_and_dust(delta: float) -> void:
	_afterimage_timer -= delta
	_step_dust_timer -= delta

	var high_motion := _dash_timer > 0.0 or absf(velocity.y) > 165.0 or _is_gliding or _pulse_anim_timer > 0.0 or (absf(velocity.x) > 125.0 and GameState.radiance_level >= 2)
	if high_motion and _afterimage_timer <= 0.0:
		_afterimage_timer = 0.025 if _dash_timer > 0.0 else 0.045
		var aura := GameState.get_aura_color()
		VfxHelper.spawn_afterimage(get_parent(), sprite, global_position, Color(aura.r, aura.g, aura.b, 0.65))

	if is_on_floor() and absf(velocity.x) > 60.0 and _step_dust_timer <= 0.0:
		_step_dust_timer = 0.14
		var step_c := Color(0.65, 0.4, 0.85, 0.75) if _in_mud else Color(1.0, 0.92, 0.65, 0.65)
		VfxHelper.spawn_dust_burst(get_parent(), global_position + Vector2(0, 7), 3, step_c, false, Vector2(-signf(velocity.x), -0.5).normalized(), 45.0, 15.0, 40.0)
	elif _is_wall_sliding and _step_dust_timer <= 0.0:
		_step_dust_timer = 0.12
		VfxHelper.spawn_dust_burst(get_parent(), global_position, 2, Color(0.85, 0.95, 1.0, 0.75), false, Vector2.UP, 40.0, 15.0, 35.0)

func set_in_mud(in_mud: bool) -> void:
	if in_mud and not _in_mud:
		VfxHelper.spawn_dust_burst(get_parent(), global_position + Vector2(0, 6), 10, Color(0.6, 0.35, 0.85, 0.9), false, Vector2.UP, 130.0, 25.0, 75.0)
	_in_mud = in_mud

func set_wind_force(force: Vector2) -> void:
	_wind_force = force

func drain_light_by_gust(remaining_light: float = 15.0) -> void:
	health.current_light = minf(health.current_light, remaining_light)
	Events.light_changed.emit(health.current_light, health.max_light)
	_shake_camera(6.5, 0.25)
	_squash_sprite(Vector2(1.5, 0.55), 0.3)
	_update_light_visual()

func _on_hit_received(damage: float, source_pos: Vector2, knockback: float) -> void:
	if _is_dying or _dash_timer > 0.0:
		return
	if health.take_damage(damage):
		_hurt_timer = 0.32
		AudioManager.play_sfx("hurt")
		var dir := signf(global_position.x - source_pos.x)
		if dir == 0.0:
			dir = -1.0
		velocity = Vector2(dir * knockback * 1.15, -185.0)
		_squash_sprite(Vector2(1.70, 0.42), 0.28)
		VfxHelper.spawn_dust_burst(get_parent(), global_position, 16, Color(1.0, 0.35, 0.35, 1.0), true, Vector2.UP, 180.0, 50.0, 130.0)
		VfxHelper.spawn_floating_text(get_parent(), global_position, "-%d LUZ!" % int(damage), Color(1.0, 0.4, 0.4, 1.0))
		_shake_camera(7.0, 0.22)
		VfxHelper.hitstop(self, 0.05, 0.06)

func _on_health_changed(_current: float, _maximum: float) -> void:
	_update_light_visual()

func _update_light_visual() -> void:
	if not light:
		return
	var ratio := health.get_ratio()
	var bonus_scale := float(GameState.collected_shards.size()) * 0.28 + float(GameState.radiance_level - 1) * 0.12
	light.color = GameState.get_aura_color()
	light.texture_scale = clampf(0.55 + ratio * 1.15 + bonus_scale, 0.35, 2.8)
	light.energy = clampf(0.45 + ratio * 0.90 + float(GameState.radiance_level - 1) * 0.08, 0.3, 1.75)

func _on_health_depleted() -> void:
	_trigger_death(false)

func _trigger_death(fell_in_abyss: bool) -> void:
	if _is_dying:
		return
	_is_dying = true
	_controls_locked = true
	Events.player_died.emit()

	AudioManager.play_sfx("death")
	_shake_camera(9.0, 0.28)

	velocity = Vector2(0.0, -195.0 if fell_in_abyss else -150.0)
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
	_squash_sprite(Vector2(1.75, 1.75), 0.35)

	var death_msg := "CAIU NO ABISMO!" if fell_in_abyss else "LUZ APAGADA!"
	VfxHelper.spawn_floating_text(get_parent(), global_position + Vector2(0, -14), death_msg, Color(1.0, 0.45, 0.4, 1.0))
	VfxHelper.spawn_dust_burst(get_parent(), global_position, 28, GameState.get_aura_color(), true, Vector2.UP, 180.0, 65.0, 170.0)

	var tw := create_tween()
	tw.tween_property(sprite, "modulate:a", 0.0, 0.36)
	await tw.finished

	global_position = spawn_position
	velocity = Vector2.ZERO
	sprite.rotation = 0.0
	_can_dash = true
	health.restore_full()
	_update_light_visual()

	VfxHelper.spawn_dust_burst(get_parent(), global_position, 22, GameState.get_aura_color(), true, Vector2.UP, 180.0, 50.0, 140.0)
	AudioManager.play_sfx("checkpoint", 0.1)
	sprite.scale = Vector2(0.15, 1.9)
	var tw_in := create_tween()
	tw_in.set_parallel(true)
	tw_in.tween_property(sprite, "modulate:a", 1.0, 0.22)
	tw_in.tween_property(sprite, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await tw_in.finished

	_is_dying = false
	_controls_locked = false
	Events.player_respawned.emit()

func _on_checkpoint_reached(pos: Vector2) -> void:
	spawn_position = pos
	health.heal(35.0)
	_squash_sprite(Vector2(1.35, 1.35), 0.24)
	_shake_camera(2.5, 0.10)

func _on_spark_collected(amount: float) -> void:
	health.heal(amount)
	_squash_sprite(Vector2(1.38, 0.72), 0.22)
	_update_light_visual()

func _on_shard_collected(_shard_id: int) -> void:
	health.restore_full()
	_squash_sprite(Vector2(1.65, 1.65), 0.35)
	_shake_camera(6.0, 0.25)
	_update_light_visual()

func _on_radiance_level_up(new_level: int) -> void:
	_update_light_visual()
	_squash_sprite(Vector2(1.6, 1.6), 0.35)
	_shake_camera(4.5, 0.18)
	VfxHelper.spawn_dust_burst(get_parent(), global_position, 26, GameState.get_aura_color(), true, Vector2.UP, 180.0, 60.0, 155.0)
	VfxHelper.spawn_floating_text(get_parent(), global_position + Vector2(0, -12), "BRILHO NV. %d! (+VELOCIDADE & LUZ)" % new_level, GameState.get_aura_color())

func _on_dialogue_started(_lines: Array[String]) -> void:
	_controls_locked = true

func _on_dialogue_finished() -> void:
	_controls_locked = false

func _squash_sprite(target_scale: Vector2, duration: float = 0.24) -> void:
	if not sprite:
		return
	if _squash_tween and _squash_tween.is_running():
		_squash_tween.kill()
	sprite.scale = target_scale
	_squash_tween = create_tween()
	_squash_tween.tween_property(sprite, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _shake_camera(intensity: float, duration: float) -> void:
	if not camera or GameState.reduce_flashes:
		return
	var tw := create_tween()
	var steps := 6
	for i in range(steps):
		var decay := 1.0 - (float(i) / float(steps))
		var offset_vec := Vector2(
			randf_range(-intensity, intensity) * decay,
			randf_range(-intensity, intensity) * decay
		)
		tw.tween_property(camera, "offset", offset_vec, duration / float(steps))
	tw.tween_property(camera, "offset", Vector2.ZERO, 0.03)

func _update_animation(delta: float) -> void:
	if not sprite or not sprite.sprite_frames or _is_dying:
		return

	if is_on_floor():
		var target_tilt := clampf(velocity.x / max_speed, -1.0, 1.0) * 0.22
		sprite.rotation = lerpf(sprite.rotation, target_tilt, 14.0 * delta)
	elif not _used_glide_jump:
		var air_tilt := clampf(velocity.x / max_speed, -1.0, 1.0) * 0.14
		sprite.rotation = lerpf(sprite.rotation, air_tilt, 8.0 * delta)

	var anim := "idle"
	if _dash_timer > 0.0:
		anim = "dash"
	elif _is_stomping:
		anim = "fall"
	elif _hurt_timer > 0.0:
		anim = "hurt"
	elif _pulse_anim_timer > 0.0:
		anim = "pulse"
	elif not is_on_floor():
		if _is_gliding:
			anim = "glide"
		elif velocity.y < 0.0:
			anim = "jump"
		else:
			anim = "fall"
	elif absf(velocity.x) > 5.0:
		anim = "run"

	if sprite.animation != anim and sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)
