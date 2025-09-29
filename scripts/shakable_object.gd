extends Node3D


@export var sfx: Array[AudioStream] = []
@export var loot_scene: PackedScene
@onready var audio: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var wob: Node3D = $visual

func _ready():
	if has_node("Area3D"):
		$Area3D.body_entered.connect(_on_bump)

func interact(strength: float = 1.0) -> void:
	wobble(strength)
	play_sfx()
	puff()
	if randf() < 0.1 and loot_scene:
		var loot = loot_scene.instantiate()
		loot.global_transform.origin = global_transform.origin + Vector3(0, 0.6, 0)
		get_tree().current_scene.add_child(loot)

func _on_bump(_body):
	interact(0.7)

func wobble(strength: float) -> void:
	var t = create_tween()
	var amt = randf_range(20.0, 50.0) * strength
	#t.tween_property(wob, "rotation_degrees:y", rotation_degrees.y + amt, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	#t.tween_property(wob, "rotation_degrees:y", rotation_degrees.y, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	t.tween_property(wob, "rotation_degrees:x", rotation_degrees.x + amt, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(wob, "rotation_degrees:x", rotation_degrees.x, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	t.tween_property(wob, "rotation_degrees:z", rotation_degrees.z + amt, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(wob, "rotation_degrees:z", rotation_degrees.z, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func play_sfx() -> void:
	if sfx.size() == 0: return
	audio.pitch_scale = randf_range(0.92, 1.08)
	audio.stream = sfx.pick_random()
	audio.play()

func puff() -> void:
	if has_node("GPUParticles3D"):
		var p = $GPUParticles3D
		p.restart()
