extends ColorRect

@export var nextScenePath : String 

@onready var animPlayer = $AnimationPlayer

func _ready():
	animPlayer.play_backwards("Fade")
	#get_tree().change_scene_to_file(nextScenePath)
	
func transitionTo(nextScene) -> void:
	nextScenePath = nextScene
	animPlayer.play("Fade")
	await animPlayer.animation_finished
	get_tree().change_scene_to_file(nextScenePath)
