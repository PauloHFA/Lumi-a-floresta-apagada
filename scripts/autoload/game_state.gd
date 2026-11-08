# scripts/autoload/game_state.gd
extends Node

signal state_updated

var current_level: int = 1
var unlocked_pulse: bool = false
var unlocked_glide: bool = false
var unlocked_stomp: bool = false
var collected_shards: Array[int] = []
var total_sparks: int = 0
var max_light_bonus: float = 0.0
var radiance_level: int = 1

# Configurações de acessibilidade e áudio (RNF-06, CA-08)
var music_volume: float = 0.8
var sfx_volume: float = 0.9
var fullscreen: bool = false
var reduce_flashes: bool = false
var font_scale: float = 1.0
var custom_keybinds: Dictionary = {}

func _ready() -> void:
	_setup_default_inputs()
	load_from_disk()
	Events.shard_collected.connect(_on_shard_collected)
	Events.spark_collected.connect(_on_spark_collected)
	Events.level_completed.connect(_on_level_completed)

func _setup_default_inputs() -> void:
	var actions := {
		"move_left": {
			"keys": [KEY_A, KEY_LEFT],
			"joy_buttons": [JOY_BUTTON_DPAD_LEFT],
			"joy_axis": [JOY_AXIS_LEFT_X, -1.0]
		},
		"move_right": {
			"keys": [KEY_D, KEY_RIGHT],
			"joy_buttons": [JOY_BUTTON_DPAD_RIGHT],
			"joy_axis": [JOY_AXIS_LEFT_X, 1.0]
		},
		"jump": {
			"keys": [KEY_SPACE, KEY_W, KEY_UP],
			"joy_buttons": [JOY_BUTTON_A]
		},
		"pulse": {
			"keys": [KEY_J, KEY_X, KEY_K],
			"joy_buttons": [JOY_BUTTON_X]
		},
		"stomp": {
			"keys": [KEY_S, KEY_DOWN],
			"joy_buttons": [JOY_BUTTON_DPAD_DOWN]
		},
		"dash": {
			"keys": [KEY_SHIFT, KEY_L, KEY_C],
			"joy_buttons": [JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_B]
		},
		"pause": {
			"keys": [KEY_ESCAPE, KEY_P],
			"joy_buttons": [JOY_BUTTON_START]
		},
		"interact": {
			"keys": [KEY_E, KEY_ENTER, KEY_SPACE],
			"joy_buttons": [JOY_BUTTON_A, JOY_BUTTON_B]
		}
	}

	for action_name: String in actions.keys():
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name, 0.2)
		else:
			InputMap.action_erase_events(action_name)

		var cfg: Dictionary = actions[action_name]
		for k: int in cfg.get("keys", []):
			var ev := InputEventKey.new()
			ev.physical_keycode = k as Key
			ev.keycode = k as Key
			InputMap.action_add_event(action_name, ev)

		for jb: int in cfg.get("joy_buttons", []):
			var ev := InputEventJoypadButton.new()
			ev.button_index = jb as JoyButton
			InputMap.action_add_event(action_name, ev)

		if cfg.has("joy_axis"):
			var axis_info: Array = cfg["joy_axis"]
			var ev := InputEventJoypadMotion.new()
			ev.axis = axis_info[0] as JoyAxis
			ev.axis_value = float(axis_info[1])
			InputMap.action_add_event(action_name, ev)

func remap_action_key(action_name: String, new_key: Key) -> void:
	if not InputMap.has_action(action_name):
		return
	var existing_events := InputMap.action_get_events(action_name)
	InputMap.action_erase_events(action_name)
	var ev_key := InputEventKey.new()
	ev_key.keycode = new_key
	ev_key.physical_keycode = new_key
	InputMap.action_add_event(action_name, ev_key)

	for ev: InputEvent in existing_events:
		if not (ev is InputEventKey):
			InputMap.action_add_event(action_name, ev)

	custom_keybinds[action_name] = int(new_key)
	save_to_disk()

func get_action_key_label(action_name: String) -> String:
	if not InputMap.has_action(action_name):
		return "-"
	for ev: InputEvent in InputMap.action_get_events(action_name):
		if ev is InputEventKey:
			var k: InputEventKey = ev
			var code: Key = k.keycode if k.keycode != KEY_NONE else k.physical_keycode
			return OS.get_keycode_string(code)
	return "-"

func reset_new_game() -> void:
	current_level = 1
	unlocked_pulse = false
	unlocked_glide = false
	unlocked_stomp = false
	collected_shards.clear()
	total_sparks = 0
	max_light_bonus = 0.0
	radiance_level = 1
	save_to_disk()
	state_updated.emit()

func unlock_abilities_for_level(level_id: int) -> void:
	if level_id >= 2:
		unlocked_pulse = true
		unlocked_stomp = true
	if level_id >= 3:
		unlocked_glide = true
	state_updated.emit()

func _recalculate_radiance_level() -> void:
	var new_lvl := 1 + int(total_sparks / 2) + collected_shards.size()
	if new_lvl > radiance_level:
		radiance_level = new_lvl
		AudioManager.play_sfx("levelup", 0.02)
		Events.radiance_level_up.emit(radiance_level)
	else:
		radiance_level = max(1, new_lvl)

func get_speed_multiplier() -> float:
	return 1.0 + float(radiance_level - 1) * 0.06

func get_pulse_radius_bonus() -> float:
	return float(radiance_level - 1) * 14.0

func get_pulse_cooldown_reduction() -> float:
	return minf(0.85, float(radiance_level - 1) * 0.16)

func get_aura_color() -> Color:
	match clampi(radiance_level, 1, 5):
		1:
			return Color(1.0, 0.88, 0.55, 1.0)
		2:
			return Color(1.0, 0.96, 0.40, 1.0)
		3:
			return Color(0.55, 0.95, 1.0, 1.0)
		4:
			return Color(0.85, 0.72, 1.0, 1.0)
		_:
			return Color(1.0, 1.0, 0.95, 1.0)

func _on_shard_collected(shard_id: int) -> void:
	if not collected_shards.has(shard_id):
		collected_shards.append(shard_id)
		max_light_bonus += 25.0
	_recalculate_radiance_level()
	save_to_disk()
	state_updated.emit()

func _on_spark_collected(_amount: float) -> void:
	total_sparks += 1
	max_light_bonus += 5.0
	_recalculate_radiance_level()
	save_to_disk()
	state_updated.emit()

func _on_level_completed(level_id: int) -> void:
	var next_level := clampi(level_id + 1, 1, 4)
	current_level = next_level
	unlock_abilities_for_level(current_level)
	save_to_disk()

func apply_settings() -> void:
	var music_bus := AudioServer.get_bus_index("Music")
	if music_bus >= 0:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(maxf(0.0001, music_volume)))
		AudioServer.set_bus_mute(music_bus, music_volume <= 0.01)

	var sfx_bus := AudioServer.get_bus_index("SFX")
	if sfx_bus >= 0:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(maxf(0.0001, sfx_volume)))
		AudioServer.set_bus_mute(sfx_bus, sfx_volume <= 0.01)

	var mode := DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WindowMode.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)

	Events.settings_changed.emit()

func save_to_disk() -> void:
	var data := {
		"current_level": current_level,
		"unlocked_pulse": unlocked_pulse,
		"unlocked_glide": unlocked_glide,
		"unlocked_stomp": unlocked_stomp,
		"collected_shards": collected_shards,
		"total_sparks": total_sparks,
		"max_light_bonus": max_light_bonus,
		"radiance_level": radiance_level,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"fullscreen": fullscreen,
		"reduce_flashes": reduce_flashes,
		"font_scale": font_scale,
		"custom_keybinds": custom_keybinds
	}
	SaveSystem.save_game(data)

func load_from_disk() -> void:
	var data := SaveSystem.load_game()
	if data.is_empty():
		apply_settings()
		return

	current_level = int(data.get("current_level", 1))
	unlocked_pulse = bool(data.get("unlocked_pulse", current_level >= 2))
	unlocked_glide = bool(data.get("unlocked_glide", current_level >= 3))
	unlocked_stomp = bool(data.get("unlocked_stomp", current_level >= 2))

	collected_shards.clear()
	var saved_shards: Variant = data.get("collected_shards", [])
	if saved_shards is Array:
		for item: Variant in saved_shards:
			collected_shards.append(int(item))

	total_sparks = int(data.get("total_sparks", 0))
	max_light_bonus = float(data.get("max_light_bonus", collected_shards.size() * 25.0 + total_sparks * 5.0))
	radiance_level = int(data.get("radiance_level", 1 + int(total_sparks / 2) + collected_shards.size()))
	music_volume = float(data.get("music_volume", 0.8))
	sfx_volume = float(data.get("sfx_volume", 0.9))
	fullscreen = bool(data.get("fullscreen", false))
	reduce_flashes = bool(data.get("reduce_flashes", false))
	font_scale = float(data.get("font_scale", 1.0))

	var binds: Variant = data.get("custom_keybinds", {})
	if binds is Dictionary:
		for action_name: String in binds.keys():
			remap_action_key(action_name, int(binds[action_name]) as Key)

	apply_settings()
	state_updated.emit()
