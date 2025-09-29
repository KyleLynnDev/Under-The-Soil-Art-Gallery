#@tool

extends StaticBody3D


@export var interact_name: String = "Unknown Object" 
@export var display_name : String = "Unknown Object"

@export var description : String
@export var effect : String = "none"

@export var sprite_preview : Texture 
@export var interact_type : String 

var scene_path : String = "res://Entities/Items/interactable_object.tscn"

@onready var visualSprite = $Visual

@export var npc_name: String = ""  # Optional — leave blank for non-NPCs

var playerInRange = false;
var player = Global.playerNode;



### Animated items variables 

const TRANSLATION_DISTANCE := 0.5
const TRANSLATION_SPEED := 2.0
const ROTATION_SPEED := 0.5
@export var _reverse_direction := false
var _time := 0.0
@onready var _default_transform: Transform3D = get_transform()

###



func _ready():
	if not Engine.is_editor_hint():
		visualSprite.texture = sprite_preview
		visualSprite.scale = Vector3(4.0,4.0,4.0)



func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		visualSprite.texture = sprite_preview
		
	if interact_type == "Item":
		self._time += delta
		self.transform = get_animated_transform(
			self._default_transform, self._time, self._reverse_direction
		)
	#UI.closeAllInteractUIs()
	#showInteractionUIElement()
	


func _physics_process(delta: float) -> void:

	if Global.isPlayerInRange:
		playerInRange = true
	else:
		playerInRange = false 
		
	#showInteractionUIElement()



func interact():
	# show you interacted with object 
	print("You interacted with:", interact_name)

	#logic for choosing which function to use: 
	if (interact_type == "Object"): 
		print("interaction type: Object")
		observe()
		
	if (interact_type == "NPC" && !Global.IsCurrentlyInDialogue): 
		print("interaction type: NPC")
		##TODO: replace this with a more customizable system based on context
		#Dialogic.start("example1")
		
	if (interact_type == "Skill"): 
		print("interaction type: Skill")
		useSKill()
		
	if (interact_type == "Item"): 
		print("interaction type: Item")
		pickupItem() 
		
	if (interact_type == "Gate"):
		print("interaction type: Gate")
		useDoor()



## picks up an item from the ground and adds to inventory 
func pickupItem():
	var item = {
		"quantity" : 1,
		"type": interact_type,
		"name": interact_name,
		"effect": effect,
		"texture": sprite_preview,
		"scene_path" : scene_path
	}
	print("picking up item", item["name"])
	
	if Global.playerNode:
		Global.addItem(item)
		self.queue_free()
	



## Choose which item from the context menu should be shown when interactable
## is in range of player 	
func showInteractionUIElement():
	print("[", name, "] type=", interact_type, " calling UI")
	match interact_type:
		"Item":
			UI.showItemPickup()
		"Skill":
			UI.showSkillDo()
		"NPC":
			if(!Global.IsCurrentlyInDialogue):
				UI.showNPCSpeak()
		"Object":
			UI.showObjectObserve()
		"_":
			UI.closeAllInteractUIs()	



func set_item_data(data):
	interact_type = data["type"]
	interact_name = data["name"]
	effect = data["effect"]
	sprite_preview = data["texture"]
	
	
	
## This will be highly context sensitive based on the type of skill object
## the player uses. Examples include fishing spot, tree to cut, rock to mine, etc. 	
func useSKill():
	## [TODO] go to skill manager 
	pass
	
	
	
func observe():
	## [TODO] just print the item 
	print(description)
	if(!Global.IsCurrentlyInDialogue):
		Global.say_quick(description)
	
	
## [TODO] - this should link to the door object and fire off its animation 
## opening door if closed, unlocking if locked and then using, or telling
## the player they need something in order to progress such as HEART points
func useDoor():
	pass
	
	
static func get_animated_transform(
	p_default_transform: Transform3D, p_time: float, p_reverse_direction: bool
) -> Transform3D:
	var rotation = Vector3.ONE * p_time * ROTATION_SPEED
	var translation_direction := -1 if p_reverse_direction else 1
	var y_pos := sin(p_time * TRANSLATION_SPEED) * TRANSLATION_DISTANCE * translation_direction
	var offset_transform := Transform3D(Basis.from_euler(rotation), Vector3.UP * y_pos)
	return p_default_transform * offset_transform
	
	
	
