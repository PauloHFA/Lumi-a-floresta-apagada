# scripts/objects/checkpoint.gd
class_name Checkpoint
extends Area2D

var is_active: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var light: PointLight2D = $PointLight2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_visual()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_active:
		is_active = true
		AudioManager.play_sfx("checkpoint")
		Events.checkpoint_reached.emit(global_position)
		_update_visual()
		if sprite:
			sprite.scale = Vector2(1.6, 0.55)
			var tw := create_tween()
			tw.tween_property(sprite, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		VfxHelper.spawn_dust_burst(get_parent(), global_position, 18, Color(1.0, 0.92, 0.5, 1.0), true, Vector2.UP, 160.0, 40.0, 120.0)
		VfxHelper.spawn_floating_text(get_parent(), global_position, "CHECKPOINT ACESO!", Color(1.0, 0.95, 0.55, 1.0))

func _update_visual() -> void:
	if sprite:
		sprite.region_rect = Rect2(16 if is_active else 0, 0, 16, 16)
	if light:
		light.enabled = is_active
