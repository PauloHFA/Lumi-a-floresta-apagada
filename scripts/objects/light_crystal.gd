# scripts/objects/light_crystal.gd
class_name LightCrystal
extends Area2D

signal crystal_activated

@export var target_gate: NodePath
@export var activation_message: String = "CRISTAL DE LUZ ATIVADO!"

var is_lit: bool = false
var _time: float = 0.0
var _base_y: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var light: PointLight2D = $PointLight2D

func _ready() -> void:
	_base_y = position.y
	Events.pulse_triggered.connect(_on_pulse_triggered)
	body_entered.connect(_on_body_entered)
	_update_visual()

func _process(delta: float) -> void:
	_time += delta * 3.2
	position.y = _base_y + sin(_time) * 2.5
	if is_lit and sprite:
		sprite.rotation = sin(_time * 1.5) * 0.12

func _on_body_entered(body: Node2D) -> void:
	# Também permite ativar ao tocar durante um Dash de Luz ou se ainda não tiver Pulso
	if not is_lit and body.is_in_group("player") and not GameState.unlocked_pulse:
		activate_crystal()

func _on_pulse_triggered(pulse_pos: Vector2, radius: float) -> void:
	if is_lit:
		return
	if global_position.distance_to(pulse_pos) <= radius + 16.0:
		activate_crystal()

func activate_crystal() -> void:
	if is_lit:
		return
	is_lit = true
	AudioManager.play_sfx("crystal", 0.03)
	_update_visual()
	if sprite:
		sprite.scale = Vector2(1.8, 1.8)
		var tw := create_tween()
		tw.tween_property(sprite, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	VfxHelper.spawn_dust_burst(get_parent(), global_position, 22, Color(1.0, 0.95, 0.55, 1.0), true, Vector2.UP, 180.0, 50.0, 140.0)
	VfxHelper.spawn_floating_text(get_parent(), global_position, activation_message, Color(1.0, 0.96, 0.55, 1.0))
	VfxHelper.hitstop(self, 0.06, 0.05)

	if not target_gate.is_empty():
		var gate := get_node_or_null(target_gate)
		if gate and gate is Node2D:
			var g_node: Node2D = gate
			VfxHelper.spawn_dust_burst(get_parent(), g_node.global_position, 24, Color(0.85, 0.7, 1.0, 1.0), true, Vector2.UP, 180.0, 45.0, 130.0)
			var gtw := create_tween()
			gtw.tween_property(g_node, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			gtw.tween_callback(g_node.queue_free)

	crystal_activated.emit()

func _update_visual() -> void:
	if sprite:
		sprite.region_rect = Rect2(16 if is_lit else 0, 0, 16, 16)
	if light:
		light.enabled = is_lit

