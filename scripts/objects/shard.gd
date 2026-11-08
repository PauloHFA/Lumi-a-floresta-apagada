# scripts/objects/shard.gd
class_name Shard
extends Area2D

@export var shard_id: int = 1
@export var target_next_level: int = 2
@export var pickup_dialogue: Array[String] = ["Lumi: Está quente... e está vivo!"]

var _collected: bool = false
var _time: float = 0.0
var _base_y: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_base_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_time += delta * 3.5
	position.y = _base_y + sin(_time) * 4.0
	if sprite:
		var pulse_s := 1.0 + sin(_time * 2.0) * 0.18
		sprite.scale = Vector2(pulse_s, pulse_s)
		sprite.rotation = sin(_time) * 0.15

func _on_body_entered(body: Node2D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	visible = false
	AudioManager.play_sfx("collect", 0.02)
	AudioManager.play_sfx("levelup", 0.01)
	VfxHelper.spawn_dust_burst(get_parent(), global_position, 36, Color(1.0, 0.95, 0.5, 1.0), true, Vector2.UP, 180.0, 65.0, 180.0)
	VfxHelper.spawn_floating_text(get_parent(), global_position, "FRAGMENTO DE LUZ RECUPERADO!", Color(1.0, 0.98, 0.65, 1.0))
	VfxHelper.hitstop(self, 0.06, 0.08)
	Events.shard_collected.emit(shard_id)

	if not pickup_dialogue.is_empty():
		Events.dialogue_requested.emit(pickup_dialogue)
		await Events.dialogue_finished

	Events.level_completed.emit(shard_id)
	if target_next_level <= 4:
		SceneLoader.load_level(target_next_level)
	else:
		SceneLoader.load_credits()
