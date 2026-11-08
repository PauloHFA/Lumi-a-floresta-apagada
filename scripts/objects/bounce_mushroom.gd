# scripts/objects/bounce_mushroom.gd
class_name BounceMushroom
extends Area2D

@export var bounce_velocity: float = -435.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var light: PointLight2D = $PointLight2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("bounce"):
		body.call("bounce", bounce_velocity)
		AudioManager.play_sfx("bounce", 0.06)
		if sprite:
			sprite.region_rect = Rect2(16, 0, 16, 16)
			sprite.scale = Vector2(1.75, 0.42)
			var tw := create_tween()
			tw.tween_property(sprite, "scale", Vector2.ONE, 0.36).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			tw.tween_callback(func() -> void: sprite.region_rect = Rect2(0, 0, 16, 16))
		if light:
			light.energy = 1.6
			var ltw := create_tween()
			ltw.tween_property(light, "energy", 0.75, 0.4)
		VfxHelper.spawn_dust_burst(get_parent(), global_position, 16, Color(0.45, 0.95, 1.0, 0.95), true, Vector2.UP, 140.0, 45.0, 130.0)
		VfxHelper.spawn_floating_text(get_parent(), global_position, "BOING!", Color(0.5, 1.0, 1.0, 1.0))

