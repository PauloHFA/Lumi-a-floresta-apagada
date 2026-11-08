# scripts/objects/moving_platform.gd
class_name MovingPlatform
extends AnimatableBody2D

@export var move_offset: Vector2 = Vector2(64.0, 0.0)
@export var speed: float = 1.2

var _start_pos: Vector2
var _time: float = 0.0

func _ready() -> void:
	_start_pos = position

func _physics_process(delta: float) -> void:
	_time += delta * speed
	var factor := (sin(_time) + 1.0) * 0.5
	position = _start_pos.lerp(_start_pos + move_offset, factor)

