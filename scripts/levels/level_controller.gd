# scripts/levels/level_controller.gd
class_name LevelController
extends Node2D

@export var level_id: int = 1
@export var level_title: String = "Ato 1 - Raízes"
@export var music_track: String = "mystery"
@export var intro_dialogue: Array[String] = []
@export var is_final_oak_level: bool = false

@onready var canvas_modulate: CanvasModulate = $CanvasModulate

const STAR_PATH := "res://assets/sprites/fx/particle_star.png"

func _ready() -> void:
	GameState.current_level = level_id
	GameState.unlock_abilities_for_level(level_id)
	GameState.save_to_disk()
	AudioManager.play_music(music_track)
	_register_story_owl()

	_spawn_atmosphere_fireflies()
	_spawn_parallax_trees()

	if is_final_oak_level:
		Events.light_shared.connect(_on_final_light_shared)

	if not intro_dialogue.is_empty():
		await get_tree().create_timer(0.35).timeout
		Events.dialogue_requested.emit(intro_dialogue)

func _register_story_owl() -> void:
	var background := get_node_or_null("BackgroundDecor")
	if not background:
		return
	for decoration: Node in background.get_children():
		if decoration is Sprite2D and decoration.name.begins_with("GrandmaOwl"):
			decoration.add_to_group("story_owl")

func _spawn_atmosphere_fireflies() -> void:
	var fireflies := CPUParticles2D.new()
	fireflies.name = "AmbientFireflies"
	fireflies.position = Vector2(680, 140)
	fireflies.amount = 36
	fireflies.lifetime = 5.5
	fireflies.preprocess = 3.0
	if ResourceLoader.exists(STAR_PATH):
		fireflies.texture = load(STAR_PATH) as Texture2D
	fireflies.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fireflies.emission_rect_extents = Vector2(750, 260)
	fireflies.direction = Vector2(0, -1)
	fireflies.spread = 180.0
	fireflies.gravity = Vector2(0, -4.0)
	fireflies.initial_velocity_min = 6.0
	fireflies.initial_velocity_max = 18.0
	fireflies.scale_amount_min = 0.35
	fireflies.scale_amount_max = 0.85
	fireflies.color = Color(1.0, 0.95, 0.55, 0.45)
	add_child(fireflies)

func _spawn_parallax_trees() -> void:
	var decor := get_node_or_null("BackgroundDecor")
	if not decor:
		return
	for i in range(12):
		var tree_sil := ColorRect.new()
		var w := randf_range(28.0, 54.0)
		var x_pos := float(i) * 135.0 - 60.0
		tree_sil.offset_left = x_pos
		tree_sil.offset_top = -220.0
		tree_sil.offset_right = x_pos + w
		tree_sil.offset_bottom = 340.0
		tree_sil.color = Color(0.03, 0.04, 0.09, 0.42)
		decor.add_child(tree_sil)

func _on_final_light_shared(_pos: Vector2) -> void:
	for s: Node in get_tree().get_nodes_in_group("shadows"):
		if s.has_method("transform_into_light"):
			s.call("transform_into_light")

	if canvas_modulate:
		var tw := create_tween()
		tw.tween_property(canvas_modulate, "color", Color(0.95, 0.92, 0.82, 1.0), 1.8)

	var ending_lines: Array[String] = [
		"Os três fragmentos se unem e o Grande Carvalho desperta em luz dourada!",
		"As sombras ao redor deixam o medo para trás e se transformam em pequenas luzes.",
		"Lumi: Não precisamos escolher entre luz e escuridão. Cabe todo mundo."
	]
	Events.dialogue_requested.emit(ending_lines)
	await Events.dialogue_finished
	Events.level_completed.emit(4)
	SceneLoader.load_credits()
