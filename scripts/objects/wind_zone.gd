# scripts/objects/wind_zone.gd
class_name WindZone
extends Area2D

@export var wind_force: Vector2 = Vector2(0.0, -240.0)
@export var is_story_gust: bool = false
var _story_triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if is_story_gust and not _story_triggered:
		_story_triggered = true
		if body.has_method("drain_light_by_gust"):
			body.call("drain_light_by_gust", 18.0)
		var lines: Array[String] = [
			"A ventania gélida apaga quase toda a luz de Lumi...",
			"Vovó Coruja: A luz não é só brilhar, pequeno. É não se apagar sozinho."
		]
		Events.dialogue_requested.emit(lines)
	elif body.has_method("set_wind_force"):
		body.call("set_wind_force", wind_force)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("set_wind_force"):
		body.call("set_wind_force", Vector2.ZERO)

