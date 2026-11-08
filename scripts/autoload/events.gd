# scripts/autoload/events.gd
extends Node

signal player_died
signal player_respawned
signal shard_collected(shard_id: int)
signal spark_collected(amount: float)
signal light_changed(current: float, maximum: float)
signal dialogue_requested(lines: Array[String])
signal dialogue_finished
signal level_completed(level_id: int)
signal checkpoint_reached(position: Vector2)
signal pulse_triggered(position: Vector2, radius: float)
signal pulse_cooldown_updated(remaining: float, total: float)
signal radiance_level_up(new_level: int)
signal light_shared(position: Vector2)
signal settings_changed
