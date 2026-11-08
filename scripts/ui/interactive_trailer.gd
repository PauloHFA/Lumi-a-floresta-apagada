extends Node2D

const STEPS: Array[Dictionary] = [
	{"scene": 0, "speaker": "NARRADOR", "text": "A floresta que antes brilhava mergulhou em uma escuridão repentina."},
	{"scene": 0, "speaker": "Lumi", "text": "Ei! O que aconteceu? Minha luz... mal consigo enxergar!"},
	{"scene": 1, "speaker": "Vovó Coruja", "text": "Acorde, pequeno. A noite está longa demais."},
	{"scene": 1, "speaker": "Lumi", "text": "Vovó, por que tudo ficou escuro?"},
	{"scene": 2, "speaker": "Vovó Coruja", "text": "O Grande Carvalho, que iluminava esta floresta, se partiu. Sua luz se espalhou em três fragmentos."},
	{"scene": 2, "speaker": "Lumi", "text": "E se ninguém encontrar os fragmentos?"},
	{"scene": 2, "speaker": "Vovó Coruja", "text": "A escuridão vai cobrir cada caminho. Sem o Carvalho, a floresta pode esquecer como era brilhar."},
	{"scene": 3, "speaker": "Lumi", "text": "Então eu vou encontrá-los. Mesmo que minha luz seja pequena."},
	{"scene": 3, "speaker": "Vovó Coruja", "text": "Comece pelas raízes. Cada fragmento fortalece sua luz e revela novos caminhos."},
	{"scene": 4, "speaker": "Lumi", "text": "O pântano está cheio de sombras... elas querem me impedir?"},
	{"scene": 4, "speaker": "Lumi", "text": "Meu pulso de luz pode afastá-las, mas será que todas são inimigas?"},
	{"scene": 5, "speaker": "Vovó Coruja", "text": "Elas fogem do seu brilho, Lumi. Talvez não saibam como se aproximar."},
	{"scene": 6, "speaker": "Lumi", "text": "Espere... você está chorando? Você não quer me machucar, quer?"},
	{"scene": 6, "speaker": "Escolha de Lumi", "text": "Como Lumi deve responder?", "choice": true},
	{"scene": 6, "speaker": "Sombra", "text": "Eu só tenho medo de ficar sozinha no escuro..."},
	{"scene": 6, "speaker": "Lumi", "text": "Eu também fiquei com medo. Mas não precisa enfrentar a escuridão sozinha."},
	{"scene": 5, "speaker": "Lumi", "text": "A ventania está apagando minha luz! Não consigo ver o caminho..."},
	{"scene": 5, "speaker": "Vovó Coruja", "text": "A luz não é só brilhar. É não se apagar sozinho."},
	{"scene": 7, "speaker": "Lumi", "text": "Chegamos ao Grande Carvalho. As sombras estão cercando os últimos fragmentos!"},
	{"scene": 7, "speaker": "Lumi", "text": "Não vou afastá-las. Vou dividir minha luz com elas."},
	{"scene": 8, "speaker": "Lumi", "text": "Não precisamos escolher entre luz e escuridão. Cabe todo mundo."},
]

var _step_index: int = -1
var _scene_id: int = -1
var _used_pulse: bool = false
var _busy: bool = false
var _typing: bool = false
var _type_timer: float = 0.0
var _pip_counter: int = 0
var _scene_tween: Tween
var _camera_tween: Tween
var _ui: Control
var _chapter_label: Label
var _speaker_label: Label
var _dialogue_label: Label
var _progress_label: Label
var _continue_button: Button
var _choice_container: HBoxContainer
var _ending_container: HBoxContainer
var _lumi: AnimatedSprite2D
var _owl: Sprite2D
var _shadow: AnimatedSprite2D
var _pulse: Sprite2D
var _camera: Camera2D

func _ready() -> void:
	_lumi = $Lumi
	_owl = $GrandmaOwl
	_shadow = $CryingShadow
	_pulse = $PulseEffect
	_camera = $TrailerCamera
	_lumi.scale = Vector2(3.2, 3.2)
	_owl.scale = Vector2(3.2, 3.2)
	_shadow.scale = Vector2(3.2, 3.2)
	_pulse.texture = load("res://assets/sprites/fx/pulse_ring.png")
	_pulse.modulate = Color(1.0, 0.92, 0.58, 0.88)
	_create_interface()
	AudioManager.play_music("mystery")
	_show_step(0)

func _process(delta: float) -> void:
	if not _typing:
		return
	_type_timer += delta
	if _type_timer < 0.022:
		return
	_type_timer = 0.0
	_dialogue_label.visible_characters += 1
	_pip_counter += 1
	if _pip_counter % 2 == 0:
		AudioManager.play_sfx("voice_pip", 0.14)
	if _dialogue_label.visible_characters >= _dialogue_label.text.length():
		_finish_typing()

func _draw() -> void:
	var sky_colors: Array[Color] = [
		Color("#080d20"), Color("#0c1125"), Color("#17132b"),
		Color("#102038"), Color("#10243a"), Color("#14203a"),
		Color("#15152d"), Color("#1b1830"), Color("#473147"),
	]
	var ground_colors: Array[Color] = [
		Color("#171d33"), Color("#171d33"), Color("#201b31"),
		Color("#20283c"), Color("#24434a"), Color("#20364b"),
		Color("#25203b"), Color("#32233b"), Color("#80616d"),
	]
	var palette_index := clampi(_scene_id, 0, sky_colors.size() - 1)
	draw_rect(Rect2(0, 0, 640, 360), sky_colors[palette_index])
	if _scene_id == 8:
		draw_rect(Rect2(0, 196, 640, 164), Color("#e6a56c"))
		draw_rect(Rect2(0, 234, 640, 126), Color("#9b6470"))

	var star_positions: Array[Vector2] = [
		Vector2(45, 50), Vector2(110, 82), Vector2(174, 35),
		Vector2(251, 68), Vector2(330, 42), Vector2(404, 75),
		Vector2(492, 39), Vector2(568, 83), Vector2(612, 45),
	]
	if _scene_id < 8:
		for star_position in star_positions:
			draw_rect(Rect2(star_position, Vector2(3, 3)), Color("#b9c9e8"))
	else:
		draw_circle(Vector2(520, 98), 34, Color("#ffd784"))

	var tree_color := Color("#121a2d")
	var tree_positions: Array[int] = [28, 118, 522, 600]
	for tree_x in tree_positions:
		draw_rect(Rect2(tree_x, 86, 14, 224), tree_color)
		draw_rect(Rect2(tree_x - 22, 126, 16, 8), tree_color)
		draw_rect(Rect2(tree_x + 10, 162, 20, 8), tree_color)
		draw_rect(Rect2(tree_x - 24, 100, 14, 8), tree_color)
	draw_rect(Rect2(0, 264, 640, 96), ground_colors[palette_index])
	draw_rect(Rect2(0, 264, 640, 5), Color("#53605c"))

	if _scene_id >= 2:
		var oak_color := Color("#30243a") if _scene_id < 8 else Color("#654752")
		draw_rect(Rect2(300, 103, 42, 166), oak_color)
		draw_rect(Rect2(274, 140, 16, 14), oak_color)
		draw_rect(Rect2(342, 127, 18, 14), oak_color)
		draw_rect(Rect2(283, 115, 18, 13), oak_color)
		draw_rect(Rect2(337, 96, 16, 14), oak_color)
		if _scene_id == 8:
			draw_circle(Vector2(321, 177), 74, Color(1.0, 0.79, 0.42, 0.2))
			draw_rect(Rect2(316, 112, 10, 125), Color("#f5cf7a"))
		elif _scene_id == 7:
			draw_rect(Rect2(315, 140, 9, 55), Color("#e7bd72"))

	if _scene_id == 3:
		for shard_x in [210, 348, 485]:
			draw_rect(Rect2(shard_x, 249, 8, 8), Color("#f5d477"))
	if _scene_id == 4:
		draw_rect(Rect2(0, 238, 640, 26), Color("#31545c"))
		draw_rect(Rect2(0, 238, 640, 5), Color("#648477"))
	if _scene_id == 8:
		for light_position in [Vector2(253, 155), Vector2(375, 120), Vector2(418, 185)]:
			draw_circle(light_position, 5, Color("#fff0a5"))

func _create_interface() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	_ui = Control.new()
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(_ui)

	_chapter_label = Label.new()
	_chapter_label.position = Vector2(20, 14)
	_chapter_label.add_theme_font_size_override("font_size", 12)
	_chapter_label.add_theme_color_override("font_color", Color("#f6dc91"))
	_ui.add_child(_chapter_label)

	_progress_label = Label.new()
	_progress_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_progress_label.offset_left = 20
	_progress_label.offset_top = 14
	_progress_label.offset_right = -20
	_progress_label.offset_bottom = 34
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_progress_label.add_theme_font_size_override("font_size", 10)
	_progress_label.add_theme_color_override("font_color", Color("#d2d7e8"))
	_ui.add_child(_progress_label)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 18
	panel.offset_top = -150
	panel.offset_right = -18
	panel.offset_bottom = -12
	panel.custom_minimum_size = Vector2(0, 138)
	_ui.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var dialogue_box := VBoxContainer.new()
	dialogue_box.add_theme_constant_override("separation", 5)
	margin.add_child(dialogue_box)

	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", 12)
	_speaker_label.add_theme_color_override("font_color", Color("#f6dc91"))
	dialogue_box.add_child(_speaker_label)

	_dialogue_label = Label.new()
	_dialogue_label.custom_minimum_size = Vector2(0, 42)
	_dialogue_label.add_theme_font_size_override("font_size", 13)
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_box.add_child(_dialogue_label)

	_choice_container = HBoxContainer.new()
	_choice_container.add_theme_constant_override("separation", 8)
	dialogue_box.add_child(_choice_container)
	_add_choice_button("Aproximar devagar", "gentle")
	_add_choice_button("Usar pulso de luz", "pulse")

	_continue_button = Button.new()
	_continue_button.text = "Continuar  [Espaço / Enter / A]"
	_continue_button.custom_minimum_size = Vector2(210, 28)
	_continue_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_continue_button.pressed.connect(_advance)
	dialogue_box.add_child(_continue_button)

	_ending_container = HBoxContainer.new()
	_ending_container.add_theme_constant_override("separation", 8)
	dialogue_box.add_child(_ending_container)
	_add_ending_button("Rever trailer", _replay)
	_add_ending_button("Começar jogo", _start_game)
	_add_ending_button("Voltar ao menu", _return_to_menu)
	_choice_container.visible = false
	_ending_container.visible = false

func _add_choice_button(button_text: String, choice: String) -> void:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(180, 28)
	button.pressed.connect(_make_choice.bind(choice))
	_choice_container.add_child(button)

func _add_ending_button(button_text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(145, 28)
	button.pressed.connect(callback)
	_ending_container.add_child(button)

func _show_step(step_index: int) -> void:
	_busy = true
	_step_index = step_index
	var step: Dictionary = STEPS[_step_index]
	var next_scene: int = int(step["scene"])
	_speaker_label.text = str(step["speaker"])
	_dialogue_label.text = str(step["text"])
	if _step_index == 15 and _used_pulse:
		_dialogue_label.text = "O pulso te afastou... eu entendo. Também senti medo. Não precisa ficar sozinha."
	_dialogue_label.visible_characters = 0
	_choice_container.visible = bool(step.get("choice", false))
	_continue_button.visible = not _choice_container.visible
	_ending_container.visible = false
	_progress_label.text = "%02d / %02d" % [_step_index + 1, STEPS.size()]
	if next_scene != _scene_id:
		await _enter_scene(next_scene)
	_start_typing()
	await _focus_speaker(str(step["speaker"]))
	_busy = false
	if _choice_container.visible:
		(_choice_container.get_child(0) as Button).grab_focus()
	else:
		_continue_button.grab_focus()

func _enter_scene(scene_id: int) -> void:
	_scene_id = scene_id
	queue_redraw()
	if _scene_tween and _scene_tween.is_running():
		_scene_tween.kill()
	_lumi.speed_scale = 1.0
	_shadow.speed_scale = 1.0
	_lumi.visible = true
	_owl.visible = scene_id in [1, 2, 3, 5, 8]
	_shadow.visible = scene_id in [4, 6, 7, 8]
	_shadow.modulate = Color("#ffe29b") if scene_id == 8 else Color.WHITE
	_pulse.visible = false

	match scene_id:
		0:
			_lumi.position = Vector2(460, -24)
			_lumi.play("fall")
			_scene_tween = create_tween()
			_scene_tween.tween_property(_lumi, "position", Vector2(260, 205), 0.85)
			await _scene_tween.finished
			_lumi.play("idle")
		1:
			_lumi.position = Vector2(260, 205)
			_lumi.play("idle")
			_owl.position = Vector2(530, 192)
			_scene_tween = create_tween()
			_scene_tween.tween_property(_owl, "position", Vector2(438, 192), 0.55)
			await _scene_tween.finished
		2:
			_lumi.position = Vector2(235, 205)
			_lumi.play("idle")
			_owl.position = Vector2(438, 192)
		3:
			_lumi.position = Vector2(165, 205)
			_lumi.play("run")
			_owl.position = Vector2(500, 192)
			_scene_tween = create_tween()
			_scene_tween.tween_property(_lumi, "position:x", 368.0, 0.65)
			await _scene_tween.finished
			_lumi.play("idle")
		4:
			_lumi.position = Vector2(190, 205)
			_lumi.play("dash")
			_shadow.position = Vector2(448, 205)
			_shadow.play("move")
			_scene_tween = create_tween()
			_scene_tween.tween_property(_lumi, "position:x", 340.0, 0.4)
			await _scene_tween.finished
			_lumi.play("idle")
		5:
			_lumi.position = Vector2(180, 206)
			_lumi.play("glide")
			_owl.position = Vector2(468, 184)
			_scene_tween = create_tween()
			_scene_tween.tween_property(_lumi, "position", Vector2(340, 153), 0.6)
			await _scene_tween.finished
			_lumi.play("idle")
		6:
			_lumi.position = Vector2(180, 205)
			_lumi.play("run")
			_shadow.position = Vector2(430, 205)
			_shadow.play("crying")
			_scene_tween = create_tween()
			_scene_tween.tween_property(_lumi, "position:x", 300.0, 0.55)
			await _scene_tween.finished
			_lumi.play("idle")
		7:
			_lumi.position = Vector2(185, 204)
			_lumi.play("dash")
			_shadow.position = Vector2(420, 204)
			_shadow.play("move")
			_scene_tween = create_tween()
			_scene_tween.tween_property(_lumi, "position:x", 305.0, 0.42)
			await _scene_tween.finished
			_lumi.play("idle")
		8:
			_lumi.position = Vector2(263, 205)
			_lumi.play("idle")
			_owl.position = Vector2(367, 197)
			_shadow.position = Vector2(438, 205)
			_shadow.play("idle")

func _focus_speaker(speaker: String) -> void:
	var focus_actor: Node2D
	if speaker.begins_with("Vovó Coruja"):
		focus_actor = _owl
	elif speaker.begins_with("Sombra"):
		focus_actor = _shadow
	elif not speaker.begins_with("NARRADOR"):
		focus_actor = _lumi

	if _camera_tween and _camera_tween.is_running():
		_camera_tween.kill()
	_camera_tween = create_tween()
	_camera_tween.set_trans(Tween.TRANS_CUBIC)
	_camera_tween.set_ease(Tween.EASE_IN_OUT)
	var target_position := Vector2(320, 180)
	var target_zoom := Vector2.ONE
	if focus_actor:
		target_position = focus_actor.position
		target_zoom = Vector2(3.2, 3.2)
	_camera_tween.tween_property(_camera, "position", target_position, 0.32)
	_camera_tween.parallel().tween_property(_camera, "zoom", target_zoom, 0.32)
	await _camera_tween.finished
	_lumi.speed_scale = 0.0
	_shadow.speed_scale = 0.0

func _start_typing() -> void:
	_type_timer = 0.0
	_pip_counter = 0
	_typing = true
	_dialogue_label.visible_characters = 0

func _finish_typing() -> void:
	_typing = false
	_dialogue_label.visible_characters = -1

func _advance() -> void:
	if _busy or _choice_container.visible or _ending_container.visible:
		return
	AudioManager.play_sfx("click")
	if _typing:
		_finish_typing()
	elif _step_index + 1 < STEPS.size():
		_show_step(_step_index + 1)
	else:
		_show_ending()

func _make_choice(choice: String) -> void:
	if _busy:
		return
	_used_pulse = choice == "pulse"
	_choice_container.visible = false
	_continue_button.visible = true
	_speaker_label.text = "Lumi"
	if _used_pulse:
		AudioManager.play_sfx("pulse")
		_dialogue_label.text = "Lumi libera um pulso de luz. A sombra recua, assustada — não era uma inimiga."
		_lumi.play("pulse")
		_pulse.visible = true
		_pulse.position = _lumi.position
		_pulse.scale = Vector2(0.1, 0.1)
		_pulse.modulate.a = 0.9 if not GameState.reduce_flashes else 0.45
		var pulse_tween := create_tween()
		pulse_tween.set_parallel(true)
		pulse_tween.tween_property(_pulse, "scale", Vector2(6.0, 6.0), 0.42)
		pulse_tween.tween_property(_pulse, "modulate:a", 0.0, 0.42)
		pulse_tween.chain().tween_callback(func() -> void: _pulse.visible = false)
		_shadow.position.x = 530
	else:
		AudioManager.play_sfx("click")
		_dialogue_label.text = "Lumi abaixa o brilho e se aproxima devagar. A sombra para de tremer."
	_start_typing()
	_focus_speaker("Lumi")
	_continue_button.grab_focus()

func _show_ending() -> void:
	_chapter_label.text = "LUMI E A FLORESTA APAGADA"
	_speaker_label.text = "FIM DO TRAILER"
	_dialogue_label.text = "Encontre os três fragmentos, atravesse a floresta e descubra o que acontece quando a luz é compartilhada."
	_finish_typing()
	_continue_button.visible = false
	_choice_container.visible = false
	_ending_container.visible = true
	_lumi.speed_scale = 1.0
	_shadow.speed_scale = 1.0
	_camera_tween = create_tween()
	_camera_tween.set_trans(Tween.TRANS_CUBIC)
	_camera_tween.set_ease(Tween.EASE_IN_OUT)
	_camera_tween.tween_property(_camera, "position", Vector2(320, 180), 0.45)
	_camera_tween.parallel().tween_property(_camera, "zoom", Vector2.ONE, 0.45)
	(_ending_container.get_child(1) as Button).grab_focus()

func _replay() -> void:
	_step_index = -1
	_scene_id = -1
	_used_pulse = false
	_camera.position = Vector2(320, 180)
	_camera.zoom = Vector2.ONE
	_show_step(0)

func _start_game() -> void:
	GameState.reset_new_game()
	SceneLoader.load_level(1)

func _return_to_menu() -> void:
	SceneLoader.load_main_menu()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_return_to_menu()
		return
	if _choice_container.visible or _ending_container.visible:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_advance()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		_advance()
