# scripts/ui/hud.gd
extends CanvasLayer

@onready var light_bar: ProgressBar = $MarginContainer/VBoxContainer/TopRow/LightBar
@onready var light_label: Label = $MarginContainer/VBoxContainer/TopRow/LightLabel
@onready var shards_label: Label = $MarginContainer/VBoxContainer/TopRow/ShardsLabel
@onready var radiance_label: Label = $MarginContainer/VBoxContainer/TopRow/RadianceLabel
@onready var ability_label: Label = $MarginContainer/VBoxContainer/BottomRow/AbilityLabel
@onready var pulse_status_label: Label = $MarginContainer/VBoxContainer/BottomRow/PulseStatusLabel
@onready var route_hint: Label = $MarginContainer/VBoxContainer/RouteHint
@onready var level_banner: Label = $LevelBanner

func _ready() -> void:
	Events.light_changed.connect(_on_light_changed)
	Events.pulse_cooldown_updated.connect(_on_pulse_cooldown_updated)
	Events.radiance_level_up.connect(_on_radiance_level_up)
	GameState.state_updated.connect(_update_info)
	Events.settings_changed.connect(_apply_accessibility)
	_update_info()
	_apply_accessibility()
	_show_level_banner()

func _show_level_banner() -> void:
	if not level_banner:
		return
	var titles := {
		1: "ATO 1 — RAÍZES DA FLORESTA",
		2: "ATO 2 — O PÂNTANO SOMBRIO",
		3: "ATO 2 — COPA DAS ÁRVORES",
		4: "ATO 3 — O GRANDE CARVALHO"
	}
	level_banner.text = titles.get(GameState.current_level, "FLORESTA APAGADA")
	level_banner.modulate = Color(1, 0.95, 0.65, 0.0)
	level_banner.scale = Vector2(0.8, 0.8)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(level_banner, "modulate:a", 1.0, 0.4)
	tw.tween_property(level_banner, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(1.8)
	tw.chain().tween_property(level_banner, "modulate:a", 0.0, 0.5)

func _on_light_changed(current: float, maximum: float) -> void:
	if light_bar:
		light_bar.max_value = maximum
		var tw := create_tween()
		tw.tween_property(light_bar, "value", current, 0.12)
	if light_label:
		light_label.text = "Luz: %d/%d" % [int(current), int(maximum)]

func _on_pulse_cooldown_updated(remaining: float, _total: float) -> void:
	if not pulse_status_label:
		return
	if not GameState.unlocked_pulse:
		pulse_status_label.text = ""
		return
	if remaining <= 0.01:
		pulse_status_label.text = "Pulso [%s]: PRONTO!" % GameState.get_action_key_label("pulse")
		pulse_status_label.modulate = Color(0.55, 1.0, 0.65, 1.0)
	else:
		pulse_status_label.text = "Pulso: %.1fs" % remaining
		pulse_status_label.modulate = Color(1.0, 0.75, 0.45, 0.85)

func _on_radiance_level_up(_new_level: int) -> void:
	_update_info()
	if radiance_label:
		radiance_label.scale = Vector2(1.5, 1.5)
		var tw := create_tween()
		tw.tween_property(radiance_label, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _update_info() -> void:
	if shards_label:
		shards_label.text = "Fragmentos: %d/3 | Centelhas: %d" % [GameState.collected_shards.size(), GameState.total_sparks]
	if radiance_label:
		var bonus_pct := int((GameState.get_speed_multiplier() - 1.0) * 100.0)
		radiance_label.text = "★ Brilho Nv.%d (+%d%% Vel)" % [GameState.radiance_level, bonus_pct]
		radiance_label.modulate = GameState.get_aura_color()
	if ability_label:
		var abilities: Array[String] = ["Dash [%s]" % GameState.get_action_key_label("dash")]
		if GameState.unlocked_pulse:
			abilities.append("Pulso [%s]" % GameState.get_action_key_label("pulse"))
		if GameState.unlocked_stomp:
			abilities.append("Stomp [S/↓]")
		if GameState.unlocked_glide:
			abilities.append("Planar [2x %s]" % GameState.get_action_key_label("jump"))
		ability_label.text = "Habilidades: " + ", ".join(abilities)
	if route_hint:
		route_hint.visible = GameState.current_level == 3
	if pulse_status_label:
		if GameState.unlocked_pulse:
			pulse_status_label.text = "Pulso [%s]: PRONTO!" % GameState.get_action_key_label("pulse")
			pulse_status_label.modulate = Color(0.55, 1.0, 0.65, 1.0)
		else:
			pulse_status_label.text = ""

func _apply_accessibility() -> void:
	var s := GameState.font_scale
	if light_label:
		light_label.scale = Vector2(s, s)
	if shards_label:
		shards_label.scale = Vector2(s, s)
	if ability_label:
		ability_label.scale = Vector2(s, s)
