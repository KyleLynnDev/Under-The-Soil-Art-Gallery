extends Node3D

@export var spring_arm: SpringArm3D
@export var rotate_speed := 0.01
@export var zoom_speed := 1.0
@export var min_zoom := 2.0
@export var max_zoom := 10.0
@export var invert_y := false

var yaw := 0.0
var pitch := 0.0

@export var actor: Node3D
@export var focus_speed := 3.0
@export var focus_keep_current_pitch := true
@export var focus_defualt_pitch_degrees := -10

var is_focusing := false
var focus_yaw := 0.0
var focus_pitch := 0.0

func _ready():
	if not spring_arm:
		spring_arm = %SpringArm3D
	# Initialize rotation
	yaw = rotation.y
	pitch = rotation.x

func _unhandled_input(event):
	# Mouse look with MMB held
	#We can middle mouse click to move camera. it captures movement and then releases mouse 
	 # 1) Detect middle‐mouse button press/release
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		print("middle click pressed")
		if event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return   # done—don’t fall through to motion logic this frame
	# 2) Only when we’re in captured mode do we react to motion
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * rotate_speed
		pitch -= event.relative.y * rotate_speed * (-1 if invert_y else 1)
		pitch = clamp(pitch, deg_to_rad(-60), deg_to_rad(60))
	
	
	# Mouse wheel zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			spring_arm.spring_length = max(min_zoom, spring_arm.spring_length - zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			spring_arm.spring_length = min(max_zoom, spring_arm.spring_length + zoom_speed)
			
func _process(delta):
	handle_gamepad_input(delta)
	update_camera_rotation()
	var player = $".."
	player.getFaceDirection()
	
	# If we're focusing, drive the interpolation each frame
	if is_focusing:
		update_focus(delta)

func handle_gamepad_input(delta):
	
	if Input.is_action_just_pressed("focusCamera"):
		print("beginning to focus")
		begin_focus()
	
	
	if Input.is_action_pressed("cameraZoomIn"):
		spring_arm.spring_length = max(min_zoom, spring_arm.spring_length - zoom_speed * 0.1)
	if Input.is_action_pressed("cameraZoomOut"):
		spring_arm.spring_length = min(max_zoom, spring_arm.spring_length + zoom_speed * 0.1)
		
	
	var input_x = Input.get_action_strength("lookRight") - Input.get_action_strength("lookLeft")
	var input_y = Input.get_action_strength("lookUp") - Input.get_action_strength("lookDown")

	if input_x != 0 or input_y != 0:
		yaw -= input_x * rotate_speed * delta * 100.0
		pitch -= input_y * rotate_speed * delta * 100.0 * (-1 if invert_y else 1)
		pitch = clamp(pitch, deg_to_rad(-60), deg_to_rad(60))

func update_camera_rotation():
	rotation = Vector3(pitch, yaw, 0)
	
func begin_focus() -> void:
	if actor == null:
		return
		
	focus_yaw = wrapf(actor.global_rotation.y, -PI, PI)
	
	focus_pitch = pitch if focus_keep_current_pitch else deg_to_rad(focus_defualt_pitch_degrees)
	is_focusing = true 
	
func update_focus(delta: float) -> void:
	#smooth step 
	var t := 1.0 - pow(0.001, delta * focus_speed)
	
	yaw = lerp_angle(yaw, focus_yaw, t)
	
	if not focus_keep_current_pitch:
		pitch = lerp(pitch, focus_pitch, t)
		
	pitch = clamp(pitch, deg_to_rad(-60), deg_to_rad(60))
	
	update_camera_rotation()
	
	var yaw_err := absf(wrapf(focus_yaw - yaw, -PI, PI))
	var pitch_err := absf(focus_pitch - pitch)
	if yaw_err < 0.005 and (focus_keep_current_pitch or pitch_err < 0.005):
		is_focusing = false

	
	
	
