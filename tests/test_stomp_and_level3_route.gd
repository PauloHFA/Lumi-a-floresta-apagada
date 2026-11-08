extends SceneTree

func _initialize() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var error := change_scene_to_file("res://scenes/levels/level_03.tscn")
	assert(error == OK, "Could not load level 3.")
	for _frame in range(10):
		if current_scene:
			break
		await process_frame
	if not current_scene:
		push_error("Level 3 did not become the current scene.")
		quit(1)
		return
	var level: Node = current_scene
	var no_dialogue: Array[String] = []
	level.set("intro_dialogue", no_dialogue)
	await create_timer(0.45).timeout

	var game_state: Node = root.get_node("GameState")
	if not bool(game_state.get("unlocked_stomp")) or not InputMap.has_action("stomp"):
		push_error("Stomp must be unlocked on level 3 and have a configured input.")
		quit(1)
		return
	if not level.get_node("MushroomHint").text.contains("COGUMELO") or not level.get_node("WorldGeometry/WindHint").text.contains("VENTO"):
		push_error("Level 3 must label the mushroom and updraft route.")
		quit(1)
		return
	if not level.get_node("HUD/MarginContainer/VBoxContainer/RouteHint").visible:
		push_error("Level 3 HUD should show the climbing route.")
		quit(1)
		return

	root.get_node("Events").emit_signal("dialogue_finished")
	paused = false

	var player := level.get_node("Player") as CharacterBody2D
	var health: Node = player.get_node("HealthComponent")
	var enemies := level.get_node("Enemies")
	var enemy_scene := load("res://scenes/actors/shadow.tscn") as PackedScene
	var enemy := enemy_scene.instantiate() as CharacterBody2D
	enemy.set_physics_process(false)
	enemy.position = Vector2(200, 145)
	enemies.add_child(enemy)
	var initial_light := float(health.get("current_light"))
	player.global_position = Vector2(200, 100)
	player.velocity = Vector2(0, -200)
	await physics_frame
	Input.action_press("stomp")
	await physics_frame
	Input.action_release("stomp")
	for _frame in range(12):
		await physics_frame

	if not bool(player.get("_stomp_hit")) or float(enemy.get("_stun_timer")) <= 0.0 or player.velocity.y >= 0.0 or float(health.get("current_light")) < initial_light:
		push_error("Stomp failed: hit=%s stun=%.2f velocity=%s player=%s enemy=%s" % [
			player.get("_stomp_hit"),
			float(enemy.get("_stun_timer")),
			player.velocity,
			player.global_position,
			enemy.global_position
		])
		quit(1)
		return

	for shadow: Node in enemies.get_children():
		if not shadow is CharacterBody2D:
			continue
		shadow.set_physics_process(false)
		var hitbox: Area2D = shadow.get_node("Hitbox")
		hitbox.set_deferred("monitorable", false)
		hitbox.set_deferred("monitoring", false)
	player.global_position = Vector2(340, 208)
	player.velocity = Vector2.ZERO
	for _frame in range(10):
		await physics_frame
		if player.is_on_floor():
			break
	if not player.is_on_floor():
		push_error("Lumi should land on the first branch before the traversal check.")
		quit(1)
		return
	Input.action_press("move_right")
	Input.action_press("jump")
	await physics_frame
	Input.action_release("jump")
	for _frame in range(12):
		await physics_frame
	Input.action_press("jump")
	await physics_frame
	for _frame in range(90):
		if player.global_position.x >= 450.0:
			Input.action_release("move_right")
		await physics_frame
		if player.is_on_floor() and player.global_position.x >= 386.0 and player.global_position.x <= 514.0:
			break
	Input.action_release("jump")
	Input.action_release("move_right")

	var branch2: Node2D = level.get_node("WorldGeometry/Branch2")
	if not player.is_on_floor() or player.global_position.x < branch2.global_position.x - 64.0 or player.global_position.x > branch2.global_position.x + 64.0:
		push_error("Double-jump route should land Lumi on the second branch; player=%s" % player.global_position)
		quit(1)
		return

	Input.action_release("move_right")
	Input.action_release("jump")
	player.global_position = Vector2(590, 100)
	player.velocity = Vector2.ZERO
	for _frame in range(10):
		await physics_frame
		if player.get("_wind_force").y < 0.0:
			break
	if player.get("_wind_force").y >= 0.0:
		push_error("The blue updraft should apply its lift to Lumi.")
		quit(1)
		return
	for _frame in range(180):
		await physics_frame
		if player.global_position.y < -42.0:
			break
	if player.global_position.y >= -42.0:
		push_error("Updraft should lift Lumi to the upper branch; player=%s wind=%s" % [
			player.global_position,
			player.get("_wind_force")
		])
		quit(1)
		return
	player.call("set_wind_force", Vector2.ZERO)
	player.global_position = Vector2(670, -80)
	player.velocity = Vector2.ZERO
	for _frame in range(60):
		await physics_frame
		if player.is_on_floor() and player.global_position.x >= 660.0 and player.global_position.x <= 1020.0:
			break
	if not player.is_on_floor() or player.global_position.x < 660.0 or player.global_position.x > 1020.0:
		push_error("The updraft should allow Lumi to land on the upper branch; player=%s" % player.global_position)
		quit(1)
		return
	print("[OK] Level 3 route hints are visible and Stomp stuns shadows with a rebound.")
	print("[OK] Double-jump route reaches the second branch.")
	print("[OK] Updraft lifts Lumi onto the upper branch.")
	quit()
