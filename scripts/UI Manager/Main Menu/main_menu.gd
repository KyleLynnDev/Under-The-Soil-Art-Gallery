extends Node3D

@onready var start_game: Button = $"CanvasLayer/VBoxContainer/Start Game"
@onready var transition = $CanvasLayer/SceneTransitionRect

var rotation_speed = 0.10



func _ready() -> void:
	start_game.grab_focus()



func _on_start_game_pressed():
	print("Starting Game")
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	#get_tree().change_scene_to_file("res://World/GameWorld.tscn") ## old way of transitioning screen



func _on_exit_pressed() -> void:
	print("Exiting game")
	get_tree().quit()
