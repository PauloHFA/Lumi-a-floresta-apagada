# scripts/objects/spark.gd
class_name Spark
extends Area2D

@export var light_restore: float = 20.0
var _time: float = 0.0
var _base_y: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_base_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_time += delta * 4.5
	position.y = _base_y + sin(_time) * 3.0
	if sprite:
		var s := 1.0 + sin(_time * 1.5) * 0.15
		sprite.scale = Vector2(s, s)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		AudioManager.play_sfx("collect", 0.08)
		VfxHelper.spawn_dust_burst(get_parent(), global_position, 14, Color(1.0, 0.95, 0.55, 1.0), true, Vector2.UP, 180.0, 40.0, 110.0)
		VfxHelper.spawn_floating_text(get_parent(), global_position, "+%d LUZ" % int(light_restore), Color(1.0, 0.96, 0.6, 1.0))
		Events.spark_collected.emit(light_restore)
		queue_free()
