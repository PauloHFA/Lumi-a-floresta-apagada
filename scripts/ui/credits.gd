# scripts/ui/credits.gd
extends Control

@onready var back_btn: Button = $CenterContainer/VBoxContainer/BackButton

func _ready() -> void:
	AudioManager.play_music("menu")
	back_btn.grab_focus()
	back_btn.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	AudioManager.play_sfx("click")
	SceneLoader.load_main_menu()

