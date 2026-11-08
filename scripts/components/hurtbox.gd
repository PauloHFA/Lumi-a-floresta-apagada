# scripts/components/hurtbox.gd
class_name Hurtbox
extends Area2D

signal hit_received(damage: float, source_position: Vector2, knockback: float)

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox:
		var hb: Hitbox = area
		hit_received.emit(hb.damage, hb.global_position, hb.knockback_force)

