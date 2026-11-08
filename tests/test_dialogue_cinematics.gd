extends SceneTree

func _initialize() -> void:
	call_deferred("_run_cinematic_test")

func _run_cinematic_test() -> void:
	var error := change_scene_to_file("res://scenes/levels/level_01.tscn")
	assert(error == OK, "Could not load opening level.")

	await process_frame
	await create_timer(0.7, true).timeout

	var dialogue := current_scene.get_node("Dialogue")
	var camera := get_root().get_camera_2d()
	assert(paused, "Opening dialogue should pause gameplay.")
	assert(camera != null, "Opening level should have an active camera.")

	var speaker_label: Label = dialogue.get_node("PanelContainer/MarginContainer/VBoxContainer/SpeakerLabel")
	assert(speaker_label.text == "NARRADOR", "Opening scene should start with the narration.")
	dialogue.set("_typing", false)
	dialogue.call("_advance")
	await create_timer(0.4, true).timeout
	assert(speaker_label.text == "Lumi", "Second opening line should focus on Lumi.")
	assert(camera.zoom.x > 3.0, "Dialogue should zoom in on the speaker.")

	dialogue.set("_typing", false)
	dialogue.call("_advance")
	await create_timer(0.4, true).timeout
	assert(speaker_label.text == "Vovó Coruja", "Third opening line should focus on the owl.")
	var owl_nodes := get_nodes_in_group("story_owl")
	assert(not owl_nodes.is_empty(), "Opening level should register the story owl.")
	var owl := owl_nodes[0] as Node2D
	assert(camera.global_position.distance_to(owl.global_position) < 70.0, "Camera should close up on the owl.")

	for line_index in range(5):
		dialogue.set("_typing", false)
		dialogue.call("_advance")
		await create_timer(0.4, true).timeout

	dialogue.set("_typing", false)
	dialogue.call("_advance")
	await create_timer(0.3, true).timeout
	assert(not paused, "Gameplay should resume after the opening dialogue.")
	assert(is_equal_approx(camera.zoom.x, 1.0), "Camera zoom should return to gameplay framing.")
	print("[OK] Cinematic dialogue pauses gameplay, focuses the speaker, and restores the camera.")
	quit()
