# scripts/autoload/scene_loader.gd
extends CanvasLayer

signal scene_loaded(scene_path: String)

var _fade_rect: ColorRect
var _is_transitioning: bool = false

const LEVEL_PATHS: Dictionary = {
	1: "res://scenes/levels/level_01.tscn",
	2: "res://scenes/levels/level_02.tscn",
	3: "res://scenes/levels/level_03.tscn",
	4: "res://scenes/levels/level_04.tscn",
}

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.02, 0.02, 0.05, 0.0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)

func change_scene(scene_path: String, fade_duration: float = 0.35) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 1.0, fade_duration)
	await tw.finished

	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)

	var tw_in := create_tween()
	tw_in.tween_property(_fade_rect, "color:a", 0.0, fade_duration)
	await tw_in.finished

	_is_transitioning = false
	scene_loaded.emit(scene_path)

func load_level(level_id: int) -> void:
	GameState.current_level = level_id
	GameState.unlock_abilities_for_level(level_id)
	GameState.save_to_disk()
	var path: String = LEVEL_PATHS.get(level_id, LEVEL_PATHS[1])
	change_scene(path)

func load_main_menu() -> void:
	change_scene("res://scenes/ui/main_menu.tscn")

func load_credits() -> void:
	change_scene("res://scenes/ui/credits.tscn")

