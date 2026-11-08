extends SceneTree

func _initialize() -> void:
	call_deferred("_run_trailer_test")

func _run_trailer_test() -> void:
	var error := change_scene_to_file("res://scenes/ui/interactive_trailer.tscn")
	assert(error == OK, "Could not load interactive trailer.")
	await process_frame
	await create_timer(1.3, true).timeout

	var trailer := current_scene
	trailer.call("_show_step", 13)
	await create_timer(1.0, true).timeout

	var choice_container: HBoxContainer = trailer.get("_choice_container")
	assert(choice_container.visible, "Trailer should present the player's choice.")
	trailer.call("_make_choice", "pulse")
	await create_timer(0.4, true).timeout

	assert(trailer.get("_used_pulse"), "Pulse choice should be recorded.")
	assert((trailer.get("_lumi") as AnimatedSprite2D).animation == "pulse", "Pulse choice should play Lumi's pulse animation.")

	trailer.call("_finish_typing")
	trailer.call("_advance")
	await create_timer(0.4, true).timeout
	var speaker_label: Label = trailer.get("_speaker_label")
	assert(speaker_label.text == "Sombra", "The choice should continue to the shadow's reply.")
	print("[OK] Interactive trailer presents a choice and plays the matching 4.7 animation.")
	quit()
