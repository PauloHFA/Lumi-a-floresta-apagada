# scripts/autoload/save_system.gd
extends Node

const PATH := "user://save.json"

func save_game(data: Dictionary) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))

func load_game() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if not f:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}

func has_save() -> bool:
	var data := load_game()
	return data.has("current_level") and int(data.get("current_level", 1)) >= 1

