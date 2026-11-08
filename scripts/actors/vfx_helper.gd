# scripts/actors/vfx_helper.gd
class_name VfxHelper
extends RefCounted

const STAR_PATH := "res://assets/sprites/fx/particle_star.png"
const DUST_PATH := "res://assets/sprites/fx/dust_puff.png"

static func _get_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

static func spawn_dust_burst(
	parent: Node,
	global_pos: Vector2,
	amount: int = 12,
	color: Color = Color(1.0, 0.95, 0.7, 1.0),
	use_stars: bool = false,
	direction: Vector2 = Vector2.UP,
	spread_deg: float = 120.0,
	speed_min: float = 35.0,
	speed_max: float = 115.0
) -> void:
	if not is_instance_valid(parent):
		return
	var p := CPUParticles2D.new()
	p.global_position = global_pos
	p.amount = max(2, amount)
	p.one_shot = true
	p.explosiveness = 0.92
	p.lifetime = 0.42
	p.texture = _get_tex(STAR_PATH if use_stars else DUST_PATH)
	p.direction = direction
	p.spread = spread_deg
	p.gravity = Vector2(0, 180.0 if not use_stars else 60.0)
	p.initial_velocity_min = speed_min
	p.initial_velocity_max = speed_max
	p.scale_amount_min = 0.55
	p.scale_amount_max = 1.35
	p.color = color
	parent.add_child(p)
	p.emitting = true
	var tree := parent.get_tree()
	if tree:
		tree.create_timer(0.6).timeout.connect(func() -> void:
			if is_instance_valid(p):
				p.queue_free()
		)

static func spawn_afterimage(
	parent: Node,
	source_sprite: AnimatedSprite2D,
	global_pos: Vector2,
	tint: Color = Color(1.0, 0.92, 0.5, 0.65)
) -> void:
	if not is_instance_valid(parent) or not is_instance_valid(source_sprite):
		return
	if not source_sprite.sprite_frames:
		return
	var anim := source_sprite.animation
	var frame := source_sprite.frame
	if not source_sprite.sprite_frames.has_animation(anim):
		return
	var tex := source_sprite.sprite_frames.get_frame_texture(anim, frame)
	if not tex:
		return

	var ghost := Sprite2D.new()
	ghost.texture = tex
	ghost.global_position = global_pos
	ghost.flip_h = source_sprite.flip_h
	ghost.rotation = source_sprite.rotation
	ghost.scale = source_sprite.scale
	ghost.modulate = tint
	ghost.z_index = -1
	parent.add_child(ghost)

	var tw := ghost.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ghost, "modulate:a", 0.0, 0.22)
	tw.tween_property(ghost, "scale", ghost.scale * 0.5, 0.22)
	tw.chain().tween_callback(ghost.queue_free)

static func spawn_floating_text(
	parent: Node,
	global_pos: Vector2,
	text_str: String,
	color: Color = Color(1.0, 0.95, 0.5, 1.0)
) -> void:
	if not is_instance_valid(parent):
		return
	var lbl := Label.new()
	lbl.text = text_str
	lbl.global_position = global_pos + Vector2(-36, -22)
	lbl.z_index = 20
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1, 1.0))
	lbl.add_theme_constant_override("outline_size", 3)
	parent.add_child(lbl)

	var tw := lbl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "global_position:y", lbl.global_position.y - 24.0, 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.65).set_delay(0.2)
	tw.chain().tween_callback(lbl.queue_free)

static func hitstop(node: Node, slow_scale: float = 0.08, duration_sec: float = 0.055) -> void:
	if GameState.reduce_flashes or not is_instance_valid(node):
		return
	Engine.time_scale = slow_scale
	var tree := node.get_tree()
	if tree:
		await tree.create_timer(duration_sec * slow_scale, true, false, true).timeout
	Engine.time_scale = 1.0
