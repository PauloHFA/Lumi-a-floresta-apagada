# scripts/ui/dialogue_box.gd
extends CanvasLayer

var _lines: Array[String] = []
var _index: int = 0
var _active: bool = false
var _typing: bool = false
var _char_timer: float = 0.0
var _pip_counter: int = 0
var _was_tree_paused: bool = false
var _camera: Camera2D
var _camera_tween: Tween
var _camera_home_position: Vector2
var _camera_home_zoom: Vector2
var _camera_home_smoothing: bool
var _camera_home_process_mode: Node.ProcessMode

@onready var panel: PanelContainer = $PanelContainer
@onready var cinematic_shade: ColorRect = $CinematicShade
@onready var speaker_label: Label = $PanelContainer/MarginContainer/VBoxContainer/SpeakerLabel
@onready var text_label: Label = $PanelContainer/MarginContainer/VBoxContainer/DialogueLabel
@onready var prompt_label: Label = $PanelContainer/MarginContainer/VBoxContainer/PromptLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	cinematic_shade.visible = false
	Events.dialogue_requested.connect(_on_dialogue_requested)
	Events.settings_changed.connect(_apply_font_scale)
	_apply_font_scale()

func _process(delta: float) -> void:
	if not _active or not _typing:
		return
	_char_timer += delta
	if _char_timer >= 0.022:
		_char_timer = 0.0
		text_label.visible_characters += 1
		_pip_counter += 1
		if _pip_counter % 2 == 0:
			AudioManager.play_sfx("voice_pip", 0.14)
		if text_label.visible_characters >= text_label.text.length():
			_typing = false
			text_label.visible_ratio = 1.0

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _typing:
			# Completar linha atual instantaneamente
			_typing = false
			text_label.visible_ratio = 1.0
			AudioManager.play_sfx("click", 0.05)
		else:
			AudioManager.play_sfx("click", 0.05)
			_advance()

func _on_dialogue_requested(lines: Array[String]) -> void:
	if lines.is_empty():
		return
	_lines = lines.duplicate()
	_index = 0
	_was_tree_paused = get_tree().paused
	get_tree().paused = true
	_active = true
	panel.visible = true
	cinematic_shade.visible = true
	panel.scale = Vector2(0.92, 0.85)
	var tw := create_tween()
	tw.tween_property(panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_capture_camera()
	_show_current_line()

func _show_current_line() -> void:
	var line := _lines[_index]
	var separator := line.find(":")
	var speaker := "NARRADOR"
	text_label.text = line
	if separator >= 0:
		speaker = line.substr(0, separator).strip_edges()
		text_label.text = line.substr(separator + 1).strip_edges()
	speaker_label.text = speaker
	text_label.visible_characters = 0
	_typing = true
	_char_timer = 0.0
	_pip_counter = 0
	prompt_label.text = "[Espaço / Enter / Botão A] Continuar (%d/%d)" % [_index + 1, _lines.size()]
	_focus_speaker(speaker)

func _advance() -> void:
	_index += 1
	if _index >= _lines.size():
		_active = false
		_typing = false
		panel.visible = false
		_restore_cinematic_state()
	else:
		_show_current_line()

func _capture_camera() -> void:
	_camera = get_viewport().get_camera_2d()
	if not _camera:
		return
	_camera_home_position = _camera.global_position
	_camera_home_zoom = _camera.zoom
	_camera_home_smoothing = _camera.position_smoothing_enabled
	_camera_home_process_mode = _camera.process_mode
	_camera.process_mode = Node.PROCESS_MODE_ALWAYS
	_camera.position_smoothing_enabled = false

func _focus_speaker(speaker: String) -> void:
	if not _camera or not is_instance_valid(_camera):
		return
	if _camera_tween and _camera_tween.is_running():
		_camera_tween.kill()

	_camera.make_current()
	_camera_tween = create_tween()
	_camera_tween.set_trans(Tween.TRANS_CUBIC)
	_camera_tween.set_ease(Tween.EASE_IN_OUT)
	var focus_position := _camera_home_position
	var focus_zoom := _camera_home_zoom
	var focus_actor := _find_speaker_actor(speaker)
	if focus_actor:
		focus_position = focus_actor.global_position
		focus_zoom = Vector2(3.2, 3.2)
	_camera_tween.tween_property(_camera, "global_position", focus_position, 0.32)
	_camera_tween.parallel().tween_property(_camera, "zoom", focus_zoom, 0.32)

func _find_speaker_actor(speaker: String) -> Node2D:
	if speaker.begins_with("NARRADOR"):
		return null
	var group_name := "player"
	if speaker.begins_with("Vovó Coruja"):
		group_name = "story_owl"
	elif speaker.begins_with("Sombra"):
		group_name = "shadows"

	var candidates := get_tree().get_nodes_in_group(group_name)
	if speaker.begins_with("Sombra"):
		for candidate: Node in candidates:
			if candidate is Node2D and candidate.get("is_crying_shadow") == true:
				return candidate as Node2D
	for candidate: Node in candidates:
		if candidate is Node2D:
			return candidate as Node2D
	return null

func _restore_cinematic_state() -> void:
	if _camera and is_instance_valid(_camera):
		if _camera_tween and _camera_tween.is_running():
			_camera_tween.kill()
		_camera_tween = create_tween()
		_camera_tween.set_trans(Tween.TRANS_CUBIC)
		_camera_tween.set_ease(Tween.EASE_IN_OUT)
		_camera_tween.tween_property(_camera, "global_position", _camera_home_position, 0.22)
		_camera_tween.parallel().tween_property(_camera, "zoom", _camera_home_zoom, 0.22)
		await _camera_tween.finished
		_camera.position_smoothing_enabled = _camera_home_smoothing
		_camera.process_mode = _camera_home_process_mode
	cinematic_shade.visible = false
	get_tree().paused = _was_tree_paused
	Events.dialogue_finished.emit()

func _apply_font_scale() -> void:
	if text_label:
		text_label.add_theme_font_size_override("font_size", int(12 * GameState.font_scale))
