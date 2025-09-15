# PlayerController.gd
extends CharacterBody3D

@export var move_speed := 5.0
@export var accel := 12.0
@export var gravity := ProjectSettings.get_setting("physics/3d/default_gravity") as float
@export var mouse_sens := 0.08         # degrees per pixel
@export var stick_sens := 120.0        # degrees/second at full deflection
@export var pitch_min := -85.0
@export var pitch_max := 85.0
@export var interaction_distance := 4.0

@onready var pivot: Node3D = $Pivot
@onready var head: Node3D = $Pivot/Head
@onready var fp_cam: Camera3D = $Pivot/Head/FPCamera
@onready var tp_cam: Camera3D = $Pivot/TPSpringarm/TPCamera
@onready var interact_prompt: Control = $"UI/Interaction Prompt"
@onready var prompt_label: Label = $"UI/Interaction Prompt/Label"
@onready var inspect_overlay: Control = $UI/inspectOverlay
@onready var open_link_btn: Button = $"UI/inspectOverlay/Panel/HBoxContainer/Artist Social"
@onready var close_btn: Button = $UI/inspectOverlay/Panel/HBoxContainer/Close
@onready var title_label: Label = $"UI/inspectOverlay/Panel/Art Title"
@onready var image_rect: TextureRect = $"UI/inspectOverlay/Panel/Art Closeup"

var _vel: Vector3
var _yaw := 0.0     # degrees
var _pitch := 0.0   # degrees
var _third_person := true
var _can_look := true
var _focused_interactable: Node = null
var _focused_data := {}  # {title, texture, url}

func _ready():
	# Start in third person
	_apply_camera_mode(true)
	# Hide UI
	interact_prompt.visible = false
	inspect_overlay.visible = false
	# Wire overlay buttons
	open_link_btn.pressed.connect(_on_open_link)
	close_btn.pressed.connect(_close_inspect)
	# Capture mouse for mouselook
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	if inspect_overlay.visible:
		# When overlay is open, freeze movement & look
		move_and_slide() # keep gravity off while paused or keep body stable
		return

	# Gravity
	if not is_on_floor():
		_vel.y -= gravity * delta
	else:
		_vel.y = 0.0

	# Movement (WASD/Arrows or left stick)
	var mv := Input.get_vector("moveLeft", "moveRight", "moveForward", "moveBack") # x=left/right, y=forward/back
	var aim_yaw_basis := Basis(Vector3.UP, deg_to_rad(_yaw))
	var wishdir := (aim_yaw_basis * Vector3(mv.x, 0.0, mv.y)).normalized()
	var target_vel := wishdir * move_speed
	_vel.x = lerp(_vel.x, target_vel.x, 1.0 - exp(-accel * delta))
	_vel.z = lerp(_vel.z, target_vel.z, 1.0 - exp(-accel * delta))

	move_and_slide()

	# Gamepad right-stick look
	if _can_look:
		var lx := Input.get_action_strength("lookRight") - Input.get_action_strength("lookLeft")
		var ly := Input.get_action_strength("lookDown") - Input.get_action_strength("lookUp")
		if absf(lx) > 0.001 or absf(ly) > 0.001:
			_yaw += lx * stick_sens * delta
			_pitch = clamp(_pitch + ly * stick_sens * delta, pitch_min, pitch_max)
			_apply_look()

	# Interaction check (ray from current camera forward)
	_update_interaction()

func _unhandled_input(event):
	if event.is_action_pressed("toggleView"):
		_apply_camera_mode(not _third_person)

	if inspect_overlay.visible:
		if event.is_action_pressed("uiBack"):
			_close_inspect()
		return

	if _can_look and event is InputEventMouseMotion:
		_yaw -= event.relative.x * mouse_sens
		_pitch = clamp(_pitch - event.relative.y * mouse_sens, pitch_min, pitch_max)
		_apply_look()

	if event.is_action_pressed("interactArt"):
		if _focused_interactable:
			_open_inspect_from_interactable()

func _apply_look():
	pivot.rotation_degrees.y = _yaw
	head.rotation_degrees.x = _pitch

func _apply_camera_mode(third_person: bool):
	_third_person = third_person
	tp_cam.current = _third_person
	fp_cam.current = not _third_person
	# Mouse mode: captured in FP; your call for TP (I keep it captured for both)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _current_camera() -> Camera3D:
	return tp_cam if _third_person else fp_cam

func _update_interaction():
	var cam := _current_camera()
	var origin := cam.global_transform.origin
	var dir := -cam.global_transform.basis.z
	var to := origin + dir * interaction_distance

	var params := PhysicsRayQueryParameters3D.new()
	params.from = origin
	params.to = to
	params.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(params)

	if hit.size() > 0 and hit.has("collider"):
		var n := hit.collider as Node
		if n and (n.is_in_group("interactable") or n.has_method("get_interact_data")):
			_focused_interactable = n
			var data := {}
			if n.has_method("get_interact_data"):
				data = n.get_interact_data()
			else:
				# Fallback: read exported vars if present
				if "title" in n: data.title = n.title
				if "image" in n: data.texture = n.image
				if "artist_url" in n: data.url = n.artist_url
			_focused_data = data
			prompt_label.text = "Press [E] / (A) to view: %s" % (data.get("title", "Artwork"))
			interact_prompt.visible = true
			return

	_focused_interactable = null
	_focused_data.clear()
	interact_prompt.visible = false

func _open_inspect_from_interactable():
	if _focused_data.is_empty():
		return
	title_label.text = str(_focused_data.get("title", "Artwork"))
	image_rect.texture = _focused_data.get("texture", null)
	inspect_overlay.visible = true
	_can_look = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _close_inspect():
	inspect_overlay.visible = false
	_can_look = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_open_link():
	var url := str(_focused_data.get("url", ""))
	if url.begins_with("http"):
		OS.shell_open(url) # Opens external browser / new tab on Web
