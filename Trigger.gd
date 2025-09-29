# OneShotDialogTrigger.gd
extends Area3D

## The line (or timeline text block) to run.
@export_multiline var dialog_text := "This is a default one time trigger "
@export var oneTime : bool = false;

## The group your player is in (change to match your project).
@export var player_group := "Player"

var _fired := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	var player = Global.playerNode
	print("body entered")
	
	if _fired:
		return
	if not body.is_in_group(player_group):
		return
	_fired = true

	# Build and start a timeline on the fly from a plain string.
	print("now saying", dialog_text)
	#Global.say_quick(dialog_text)
	player.audio_stream_player_2.play("stroll")
	
	#Dialogic.start(timeline)

	# Make sure we won't retrigger, then remove this trigger.
	monitoring = false
	set_deferred("monitoring", false)
	
	if (oneTime):
		queue_free()
