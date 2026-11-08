# scripts/ui/main_menu.gd
extends Control

var _waiting_remap: String = ""

@onready var continue_btn: Button = $CenterContainer/MainBox/ButtonsBox/ContinueButton
@onready var new_game_btn: Button = $CenterContainer/MainBox/ButtonsBox/NewGameButton
@onready var trailer_btn: Button = $CenterContainer/MainBox/ButtonsBox/TrailerButton
@onready var level_select_btn: Button = $CenterContainer/MainBox/ButtonsBox/LevelSelectButton
@onready var settings_btn: Button = $CenterContainer/MainBox/ButtonsBox/SettingsButton
@onready var credits_btn: Button = $CenterContainer/MainBox/ButtonsBox/CreditsButton
@onready var quit_btn: Button = $CenterContainer/MainBox/ButtonsBox/QuitButton
@onready var stats_label: Label = $CenterContainer/MainBox/StatsLabel

@onready var level_modal: PanelContainer = $LevelSelectModal
@onready var lvl1_btn: Button = $LevelSelectModal/MarginContainer/VBoxContainer/Lvl1Btn
@onready var lvl2_btn: Button = $LevelSelectModal/MarginContainer/VBoxContainer/Lvl2Btn
@onready var lvl3_btn: Button = $LevelSelectModal/MarginContainer/VBoxContainer/Lvl3Btn
@onready var lvl4_btn: Button = $LevelSelectModal/MarginContainer/VBoxContainer/Lvl4Btn
@onready var close_lvl_btn: Button = $LevelSelectModal/MarginContainer/VBoxContainer/CloseLvlBtn

@onready var settings_panel: PanelContainer = $SettingsModal
@onready var music_slider: HSlider = $SettingsModal/MarginContainer/VBoxContainer/MusicSlider
@onready var sfx_slider: HSlider = $SettingsModal/MarginContainer/VBoxContainer/SfxSlider
@onready var fullscreen_check: CheckButton = $SettingsModal/MarginContainer/VBoxContainer/FullscreenCheck
@onready var flashes_check: CheckButton = $SettingsModal/MarginContainer/VBoxContainer/FlashesCheck
@onready var remap_jump_btn: Button = $SettingsModal/MarginContainer/VBoxContainer/RemapJumpBtn
@onready var remap_pulse_btn: Button = $SettingsModal/MarginContainer/VBoxContainer/RemapPulseBtn
@onready var close_settings_btn: Button = $SettingsModal/MarginContainer/VBoxContainer/CloseSettingsBtn

func _ready() -> void:
	AudioManager.play_music("menu")
	settings_panel.visible = false
	level_modal.visible = false

	var has_save := SaveSystem.has_save()
	continue_btn.disabled = not has_save
	if has_save:
		continue_btn.text = "Continuar (Fase %d)" % GameState.current_level
		continue_btn.grab_focus()
	else:
		new_game_btn.grab_focus()

	if stats_label:
		stats_label.text = "★ Brilho Nv.%d  |  Fragmentos: %d/3  |  Centelhas: %d" % [
			GameState.radiance_level,
			GameState.collected_shards.size(),
			GameState.total_sparks
		]

	continue_btn.pressed.connect(_on_continue_pressed)
	new_game_btn.pressed.connect(_on_new_game_pressed)
	trailer_btn.pressed.connect(_on_trailer_pressed)
	level_select_btn.pressed.connect(_on_level_select_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	credits_btn.pressed.connect(_on_credits_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

	lvl1_btn.pressed.connect(func() -> void: _start_selected_level(1))
	lvl2_btn.pressed.connect(func() -> void: _start_selected_level(2))
	lvl3_btn.pressed.connect(func() -> void: _start_selected_level(3))
	lvl4_btn.pressed.connect(func() -> void: _start_selected_level(4))
	close_lvl_btn.pressed.connect(_on_close_level_select)

	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	flashes_check.toggled.connect(_on_flashes_toggled)
	remap_jump_btn.pressed.connect(func() -> void: _start_remap("jump"))
	remap_pulse_btn.pressed.connect(func() -> void: _start_remap("pulse"))
	close_settings_btn.pressed.connect(_on_close_settings)

	_sync_settings_ui()

func _input(event: InputEvent) -> void:
	if _waiting_remap != "" and event is InputEventKey and event.pressed:
		var kev: InputEventKey = event
		GameState.remap_action_key(_waiting_remap, kev.keycode if kev.keycode != KEY_NONE else kev.physical_keycode)
		_waiting_remap = ""
		_sync_settings_ui()
		get_viewport().set_input_as_handled()

func _sync_settings_ui() -> void:
	music_slider.value = GameState.music_volume
	sfx_slider.value = GameState.sfx_volume
	fullscreen_check.button_pressed = GameState.fullscreen
	flashes_check.button_pressed = GameState.reduce_flashes
	remap_jump_btn.text = "Tecla Pular: %s" % GameState.get_action_key_label("jump")
	remap_pulse_btn.text = "Tecla Pulso de Luz: %s" % GameState.get_action_key_label("pulse")

func _start_remap(action_name: String) -> void:
	_waiting_remap = action_name
	if action_name == "jump":
		remap_jump_btn.text = "Pressione nova tecla..."
	else:
		remap_pulse_btn.text = "Pressione nova tecla..."

func _on_continue_pressed() -> void:
	AudioManager.play_sfx("click")
	GameState.load_from_disk()
	SceneLoader.load_level(GameState.current_level)

func _on_new_game_pressed() -> void:
	AudioManager.play_sfx("click")
	GameState.reset_new_game()
	SceneLoader.load_level(1)

func _on_trailer_pressed() -> void:
	AudioManager.play_sfx("click")
	SceneLoader.change_scene("res://scenes/ui/interactive_trailer.tscn")

func _on_level_select_pressed() -> void:
	AudioManager.play_sfx("click")
	level_modal.visible = true
	lvl1_btn.grab_focus()

func _on_close_level_select() -> void:
	AudioManager.play_sfx("click")
	level_modal.visible = false
	level_select_btn.grab_focus()

func _start_selected_level(lvl_id: int) -> void:
	AudioManager.play_sfx("click")
	SceneLoader.load_level(lvl_id)

func _on_settings_pressed() -> void:
	AudioManager.play_sfx("click")
	_sync_settings_ui()
	settings_panel.visible = true
	close_settings_btn.grab_focus()

func _on_close_settings() -> void:
	AudioManager.play_sfx("click")
	settings_panel.visible = false
	settings_btn.grab_focus()

func _on_credits_pressed() -> void:
	AudioManager.play_sfx("click")
	SceneLoader.load_credits()

func _on_quit_pressed() -> void:
	AudioManager.play_sfx("click")
	get_tree().quit()

func _on_music_changed(val: float) -> void:
	GameState.music_volume = val
	GameState.apply_settings()
	GameState.save_to_disk()

func _on_sfx_changed(val: float) -> void:
	GameState.sfx_volume = val
	GameState.apply_settings()
	GameState.save_to_disk()

func _on_fullscreen_toggled(pressed: bool) -> void:
	GameState.fullscreen = pressed
	GameState.apply_settings()
	GameState.save_to_disk()

func _on_flashes_toggled(pressed: bool) -> void:
	GameState.reduce_flashes = pressed
	GameState.apply_settings()
	GameState.save_to_disk()
