# KillPlane.gd
extends Area3D

@export var y_lift := 0.5	# small lift so they don't clip into the floor
@export var respawnLocation	: Vector3 # optional: a SpawnPoint used if no checkpoint yet


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	respawnLocation = Vector3(0, 10, 0)

func _on_body_entered(body: Node3D) -> void:
	
	print("body entered kill plane")
	if not body.is_in_group("Player"):
		return
	
	respawnLocation = Vector3(0, 10, 0)
	respawnLocation.y += y_lift

	# Reset common motion fields safely (works for CharacterBody3D or custom players)
	if "velocity" in body:
		body.velocity = Vector3.ZERO
	if body.has_method("set_linear_velocity"):
		body.call("set_linear_velocity", Vector3.ZERO)
	if body.has_method("set_angular_velocity"):
		body.call("set_angular_velocity", Vector3.ZERO)

	# Defer position change to avoid fighting the current physics step
	body.global_position = respawnLocation
