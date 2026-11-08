# scripts/ui/pause_menu.gd
extends CanvasLayer

var _waiting_remap_action: String = ""

@onready var root_panel: Control = $RootPanel
@onready var resume_btn: Button = $RootPanel/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ResumeButton
@onready var options_box: VBoxContainer = $RootPanel/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/OptionsBox
@onready var music_slider: HSlider = $RootPanel/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/OptionsBox/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $RootPanel/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/OptionsBox/SfxRow/SfxSlider
@onready var fullscreen_check: CheckButton = $RootPanel/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/OptionsBox/FullscreenCheck
@onready var flashes_check: CheckButton = $RootPanel/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/OptionsBox/FlashesCheck
@onready var remap_jump_btn: Button = $RootPanel/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/OptionsBox/RemapJumpBtn
@onready var remap_pulse_btn: Button = $RootPanel/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/OptionsBox/RemapPulseBtn
@onready var menu_btn: Button = $RootPanel/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/MenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root_panel.visible = false

	resume_btn.pressed.connect(_toggle_pause)
	menu_btn.pressed.connect(_on_menu_pressed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	flashes_check.toggled.connect(_on_flashes_toggled)
	remap_jump_btn.pressed.connect(func() -> void: _start_remap("jump"))
	remap_pulse_btn.pressed.connect(func() -> void: _start_remap("pulse"))

	_sync_ui()

func _unhandled_input(event: InputEvent) -> void:
	if _waiting_remap_action != "" and event is InputEventKey and event.pressed:
		var kev: InputEventKey = event
		GameState.remap_action_key(_waiting_remap_action, kev.keycode if kev.keycode != KEY_NONE else kev.physical_keycode)
		_waiting_remap_action = ""
		_sync_ui()
		GameState.state_updated.emit()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_toggle_pause()

func _toggle_pause() -> void:
	AudioManager.play_sfx("click")
	var paused := not get_tree().paused
	get_tree().paused = paused
	root_panel.visible = paused
	if paused:
		_sync_ui()
		resume_btn.grab_focus()

func _sync_ui() -> void:
	music_slider.value = GameState.music_volume
	sfx_slider.value = GameState.sfx_volume
	fullscreen_check.button_pressed = GameState.fullscreen
	flashes_check.button_pressed = GameState.reduce_flashes
	remap_jump_btn.text = "Remapear Pulo (%s)" % GameState.get_action_key_label("jump")
	remap_pulse_btn.text = "Remapear Pulso (%s)" % GameState.get_action_key_label("pulse")

func _start_remap(action_name: String) -> void:
	_waiting_remap_action = action_name
	if action_name == "jump":
		remap_jump_btn.text = "Pressione uma tecla..."
	elif action_name == "pulse":
		remap_pulse_btn.text = "Pressione uma tecla..."

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

func _on_menu_pressed() -> void:
	AudioManager.play_sfx("click")
	get_tree().paused = false
	root_panel.visible = false
	SceneLoader.load_main_menu()

