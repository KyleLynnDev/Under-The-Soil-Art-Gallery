extends CharacterBody3D


@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var audio_stream_player_2: AudioStreamPlayer = $AudioStreamPlayer2
@onready var audio_stream_player_3: AudioStreamPlayer = $AudioStreamPlayer3



@export_group("Movement variables")

@export var walk_speed: float = 5.0;
@export var sprint_speed: float = 10.0;

@export var move_speed: float = walk_speed; ## max run speed on ground
@export var acceleration: float = 20.0; ## ground movement accel 
@export var jump_impulse: float = 12.0; ## when you press the hmp button, vertical velocity is set to this
@export var rotation_speed: float = 12.0; ## player model rotation speed - how fast model orients to movement or camera direction
@export var stopping_speed: float = 1.0; ## min horizontal speed on ground. controls character's animation changes



@export_group("Camera")

@export_range(0.0, 1.0) var mouse_sensitivity := 0.25; ## range of mouse snesitivity 
@export var tilt_upper_limit: float = PI / 3.0; # ~1.046
@export var til_lower_limit: float = PI / 8.0; # ~0.3925

@onready var main_camera = %mainCamera ##main 3rd person camera 
@onready var camera_pivot: Node3D = %CameraPivot
@onready var visual: Node3D = $Visual




##physics related private variables 

var ground_height := 0.0;
var gravity: float = 30.0;
var _was_on_floor_last_frame: bool = false;
var camera_input_direction := Vector2.ZERO;
var can_interact: bool = true;
var isPlayerInRange: bool = false;



## movement direction variables 

@onready var body_visual_capsule: MeshInstance3D = $Visual/BodyVisualCapsule



## Click to move variables 
var targetPosition : Vector3 ; 
var currentlyNavigating : bool;
var isLocked : bool = false; 
var isClickMoving := false;
var mousePos : Vector2; 
@onready var player_body: CharacterBody3D = $"."
@onready var navigationAgent: NavigationAgent3D = $NavigationAgent3D
var currentLookDirection : float; 

enum PlayerState {IDLE, WALK,  PICKUP, INVENTORY, EMOTE}
enum DirectionFace {DOWN, LEFT, RIGHT, UP }

var currentState = PlayerState.IDLE;
var currentDirection = DirectionFace.DOWN;

@onready var player_sprites: AnimatedSprite3D = $Visual/PlayerSprites
var walk_threshold = 0.1




##directional sprite variables 

var _last_lr_sign := 1.0  # >=0 => use Right variants when ambiguous
var side 
var left_of_away

const DOT_ENTER := 0.80  # enter Forward/Backward if |dot| >= this
const EPS_LEN   := 0.0001
const SIDE_NEAR := 0.05  # treat as perfectly front/back if |side| < this



#### shapecast checks
@onready var shape_cast: Area3D = $Visual/BodyVisualCapsule/BodyVisualCapsule2/shapeCast
var closestCollidedObject = null;
var interactCooldown = 0.1;

## some more ui stuff
var UICooldown = 0.2; 

##

	
	




func _ready() -> void:
	var UICooldown = 0.2; 
	#Global.setPlayerReference(self)
	Global.isPlayerInRange = false
	#self.position = Global.wherePlayerShouldSpawn
	Global.say_quick("hello")



func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE 
		
	
func _input(event: InputEvent) -> void:
	raycastInput(event)
	handleButtonInteractionInput(event)


func _physics_process(delta: float) -> void:
	
	if self.global_position.y <= -10:
		var respawnLocation = Vector3(4, 56, -10)
		respawnLocation.y += 10
		self.global_position = respawnLocation
	
	
	
	interactCooldown -= delta
	UICooldown -= delta
	
	#if(Global.canMove == false):
		#return


	
	if not is_on_floor(): #apply gravity
		velocity.y -= gravity*delta
	else:
		velocity.y = 0; 
		
	#jump	
	if Input.is_action_just_pressed("jump") and is_on_floor(): #set vertical velocity 
		velocity.y = jump_impulse; 
		
		
		
	
	var input_dir := Input.get_vector("moveLeft", "moveRight", "moveBack", "moveForward") # make direction input vector
	
	if input_dir.length() > 0.1:
		# Cancel click‐to‐move whenever the player pushes a stick/key
		if isClickMoving:
			isClickMoving = false
		handleMovement(input_dir, delta)
			
	# 2) If no direct input, but we are click‐navigating, do that
	elif isClickMoving:
		handleRaycastMovement(delta)
		# When nav finishes, clear the state so you fall back to standing
		if navigationAgent.is_navigation_finished():
			isClickMoving = false
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		
	move_and_slide()
	
	getFaceDirection()
	
	
#end _phsyics process 


func handleMovement(input_dir, delta):
	var cam_basis = camera_pivot.global_transform.basis
	
	var forward = -cam_basis.z
	forward.y = 0
	forward = forward.normalized() 
	
	var right = cam_basis.x
	right.y = 0
	right = right.normalized() 
	
	var direction = (right * input_dir.x + forward * input_dir.y) # get overall direction
	
	#player_sprites.walkUp()
	
	if direction.length() > 0.1:
		direction = direction.normalized()
		var target_yaw := atan2(-direction.x, -direction.z)
		var current_yaw := visual.rotation.y
		visual.rotation.y = lerp_angle(current_yaw, target_yaw, delta * rotation_speed)
	
	if direction:
		velocity.x = direction.x * move_speed;
		velocity.z = direction.z * move_speed;
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)



func handleRaycastMovement(delta):
	#play noise if walking 
	if currentlyNavigating:
		play_step_sounds();
	
	moveToPoint(delta, move_speed );
	pathfindNavAgent()
	currentlyNavigating = not navigationAgent.is_navigation_finished()


func play_step_sounds():
	pass
	
	
	
func moveToPoint(delta, speed ):
	var _targetPosition = navigationAgent.target_position; 
	var direction = global_position.direction_to(_targetPosition);
	


func 	handleButtonInteractionInput(event):


	#if Input.is_action_just_pressed("moveUIRight") and !UI.canZoom and UICooldown <= 0:
		#print("Right bumper pressed")
		#UICooldown = 0.1
		#UI.switchRight()
		#
	#if Input.is_action_just_pressed("moveUILeft") and !UI.canZoom and UICooldown <= 0:
		#print("Left bumper pressed")
		#UICooldown = 0.1
		#UI.switchLeft()
		#
		


	##Menu item input - D Pad / pause 
	#if Input.is_action_just_pressed("openInventory") and UICooldown <= 0:
		#print("opening inventory")
		#UICooldown = 0.1
		#UI.toggle_inventory()
		#
	#if Input.is_action_just_pressed("openMap") and UICooldown <= 0:
		#print("opening map")
		#UICooldown = 0.1
		#UI.toggle_map()
		#
	#if Input.is_action_just_pressed("openQuests") and UICooldown <= 0:
		#print("opening quest log")
		#UICooldown = 0.1
		#UI.toggle_quest()
		
	if Input.is_action_just_pressed("pauseGame") and UICooldown <= 0:
		print("opening pause menu")
		UICooldown = 0.1
		#UI.toggle_pause()
	
		
	
	# A/B for interactions
	
	if Input.is_action_just_pressed("interactObject") and closestCollidedObject != null and interactCooldown <= 0:
		if(closestCollidedObject.has_method("interact")):
			closestCollidedObject.interact()
		interactCooldown = 0.1
	
	
	# Run trigger 
	if Input.is_action_pressed("engageSprint"):
		if(is_on_floor()):
			move_speed = sprint_speed
	else: 
		move_speed = walk_speed
	
	if Input.is_action_just_pressed("toggleFullscreen"):
		#TODO: add fullscreen
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	#



func raycastInput(event):
	
	# when LM is clicked raycast from current position to mouse pos direction
	# and the length is rayLength
	
	if Input.is_action_just_pressed("leftMouse") and !isLocked:
		mousePos = get_viewport().get_mouse_position();
		var rayLength = 70;
		var from = main_camera.project_ray_origin(mousePos);
		var to = from + main_camera.project_ray_normal(mousePos) * rayLength;
		var space = get_world_3d().direct_space_state;
		
		var rayQuery = PhysicsRayQueryParameters3D.new();
		rayQuery.from = from;
		rayQuery.to = to;
		rayQuery.collide_with_areas = true; 
		rayQuery.collision_mask = 1  # only terrain layer
		
		var result = space.intersect_ray(rayQuery);
		
		#print result of raycast 
		if (result): 
			var hit = result.collider
			print ("Hit position: ", result.position);
			print ("Hit Object: ", hit);
			#if the object has the interactable method, interact, if terrain then just navigate
			
			if result.collider.has_method("interact"):
				hit.interact();
				currentlyNavigating = false;
				isClickMoving = false;
			elif hit.is_in_group("ground"): #terrain MUST be in group ground 
				targetPosition = result.position
				currentlyNavigating = true;
				isClickMoving = true;
			else:
				print("Hit object is neither ground not interactable")
				
				#point.position = targetPosition; #floating pointer here 
				#point.visible = true; 
			
			
func pathfindNavAgent():
	navigationAgent.target_position = targetPosition;
	var next_location = navigationAgent.get_next_path_position();
	var current_location = transform.origin; 
	
	#var new_velocity = (next_location-current_location).normalized() * move_speed 
	#velocity = velocity.move_toward(new_velocity, 0.25);
	
	var new_direction = (next_location - current_location)
	new_direction.y = 0
	
	var new_velocity = new_direction.normalized() * move_speed
	
	velocity.x = lerp(velocity.x, new_velocity.x, 0.25)
	velocity.z = lerp(velocity.z, new_velocity.z, 0.25)
	
	if new_velocity.length() > 0.1:
		var target_yaw := atan2(-new_velocity.x, -new_velocity.z)
		var current_yaw := visual.rotation.y
		visual.rotation.y = lerp_angle(current_yaw, target_yaw, get_process_delta_time() * rotation_speed)
	getFaceDirection()
	
	
	#if !isLocked:
	#	move_and_slide();
	
func getFaceDirection():
	var camera = main_camera
		# 1) Player forward in world (flattened to XZ)
	var p_fwd: Vector3 = -visual.global_transform.basis.z
	p_fwd.y = 0.0
	if p_fwd.length_squared() < EPS_LEN:
		return
	p_fwd = p_fwd.normalized()

	# 2) "Away from camera" at the player (flattened to XZ)
	var cam_to_player: Vector3 = visual.global_transform.origin - camera.global_transform.origin
	cam_to_player.y = 0.0
	if cam_to_player.length_squared() < EPS_LEN:
		return
	var away: Vector3 = -cam_to_player.normalized()  # away from cam, i.e., screen "up"

	# 3) Alignment and left/right sign (relative to 'away')
	var dot := p_fwd.dot(away)                                  # +1 = forwards (away), -1 = backwards (toward)
	left_of_away = Vector3(-away.z, 0.0, away.x)   # 90° CCW on XZ
	side = p_fwd.dot(left_of_away)                         # + => Left, - => Right

	# If almost perfectly forward/back, keep previous side to avoid popping
	if abs(side) < SIDE_NEAR:
		side = _last_lr_sign

	# 4) Choose animation
	#TODO: add to handleAnimations
	
	handleAnimations()
	
	if(currentState == PlayerState.WALK):
		chooseWalkAnimation(dot)
	elif(currentState == PlayerState.PICKUP):
		pass
	else:
		currentState = PlayerState.IDLE
		chooseIdleAnimation(dot)
	
		
		

func chooseWalkAnimation(dot):
	if dot >= DOT_ENTER:
		if side >= 0.0:
			player_sprites.walkBackwardsLeft()
			_last_lr_sign = 1.0
			#print("1")
		else:
			player_sprites.walkBackwardsRight()
			_last_lr_sign = -1.0
			#print("2")
	elif dot <= -DOT_ENTER:
		if side >= 0.0:
			player_sprites.walkForwardsLeft()
			_last_lr_sign = 1.0
			#print("3")
		else:
			player_sprites.walkForwardsRight()
			_last_lr_sign = -1.0
			#print("4")
	else:
		if side >= 0.0:
			player_sprites.walkSideLeft()
			_last_lr_sign = 1.0
			#print("5")
		else:
			player_sprites.walkSideRight()
			_last_lr_sign = -1.0
			#print("6")	

func chooseIdleAnimation(dot):
	if dot >= DOT_ENTER:
		if side >= 0.0:
			player_sprites.idleBackward()
			_last_lr_sign = 1.0
			#print("1")
		else:
			player_sprites.idleBackward()
			_last_lr_sign = -1.0
			#print("2")
	elif dot <= -DOT_ENTER:
		if side >= 0.0:
			player_sprites.idleForward()
			_last_lr_sign = 1.0
			#print("3")
		else:
			player_sprites.idleForward()
			_last_lr_sign = -1.0
			#print("4")
	else:
		if side >= 0.0:
			player_sprites.idleSide()
			_last_lr_sign = 1.0
			#print("5")
		else:
			player_sprites.idleSide()
			_last_lr_sign = -1.0
			#print("6")		
	
func handleAnimations():
	if(player_body.velocity.length() > 0.1):
		currentState = PlayerState.WALK
	else:
		currentState = PlayerState.IDLE
	
	
	
	
func _on_shape_cast_body_entered(body) -> void:
	if body.is_in_group("Interactable"):
		Global.isPlayerInRange = true
		closestCollidedObject = body
		#closestCollidedObject.showInteractionUIElement()
	#TODO: if multiple colliders, choose closest one - do distance calculation 
	if closestCollidedObject != null and closestCollidedObject.has_method("interact"):
		print("Is colliding with interactable object")
		print (closestCollidedObject)
		#closestCollidedObject.showInteractionUIElement()
	if closestCollidedObject != null and closestCollidedObject.has_method("showInteractionUIElement"):
		closestCollidedObject.showInteractionUIElement()
		print("firing off correctly")
		
	

func _on_shape_cast_body_exited(body) -> void:
	print("no longer colliding with interactable object")
	#Global.isPlayerInRange = false
	#UI.closeAllInteractUIs()
	closestCollidedObject = null; 
	print (closestCollidedObject)
	
	
	##########################################################3
	
	
	##apply item effect, TODO: in future to manage this turn into its own utlity script 
func applyItemEffects(item):
	match item["effect"]:
		"Stamina":
			move_speed += 50
			print("Speed increased to ", move_speed)
		"_":
			print("there is no effect")
			
func has_key():
	return true
	
	
	
func play_song(song_name: String):
	stop_all_music()
	if song_name == "lake":
		audio_stream_player.play()
	elif song_name == "stroll":
		audio_stream_player_2.play()
	elif song_name == "":
		audio_stream_player_2.play()

func stop_all_music():
	audio_stream_player.stop()
	audio_stream_player_2.stop()
	audio_stream_player_3.stop()

func _on_button_pressed(song_to_play):
	play_song(song_to_play)
	
