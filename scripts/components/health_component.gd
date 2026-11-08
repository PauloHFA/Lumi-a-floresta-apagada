# scripts/components/health_component.gd
class_name HealthComponent
extends Node

signal health_changed(current: float, maximum: float)
signal depleted

@export var base_max_light: float = 100.0
var max_light: float = 100.0
var current_light: float = 100.0
var invulnerable_timer: float = 0.0

func _ready() -> void:
	max_light = base_max_light + GameState.max_light_bonus
	current_light = max_light
	Events.light_changed.emit(current_light, max_light)

func _process(delta: float) -> void:
	if invulnerable_timer > 0.0:
		invulnerable_timer -= delta

func take_damage(amount: float) -> bool:
	if invulnerable_timer > 0.0 or current_light <= 0.0:
		return false
	invulnerable_timer = 0.8
	current_light = maxf(0.0, current_light - amount)
	health_changed.emit(current_light, max_light)
	Events.light_changed.emit(current_light, max_light)
	if current_light <= 0.0:
		depleted.emit()
	return true

func heal(amount: float) -> void:
	max_light = base_max_light + GameState.max_light_bonus
	current_light = minf(max_light, current_light + amount)
	health_changed.emit(current_light, max_light)
	Events.light_changed.emit(current_light, max_light)

func restore_full() -> void:
	max_light = base_max_light + GameState.max_light_bonus
	current_light = max_light
	invulnerable_timer = 0.5
	health_changed.emit(current_light, max_light)
	Events.light_changed.emit(current_light, max_light)

func get_ratio() -> float:
	return clampf(current_light / maxf(1.0, max_light), 0.0, 1.0)

