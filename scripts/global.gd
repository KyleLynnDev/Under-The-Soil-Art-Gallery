extends Node


#player and references
var playerNode: Node = null
#@onready var inventorySlotScene = preload("res://Utilities/UI Manager/inventory/inventorySlot.tscn")
var canMove : bool = true 

## PLAYER STATS AND COLLECTABLES
var HEART : int = 0;
var HEARTEXP : int = 0;

var coin : int = 25;
var keys : int = 1; 

##


##inventory items
var inventory = []

##signals
signal inventory_updated

##var
var isPlayerInRange: bool = false;
var IsCurrentlyInDialogue : bool = false; 


### Player Position in levels
var wherePlayerShouldSpawn : Vector3; 

var checkpointPosition : Vector3;

func _ready() -> void:
	inventory.resize(20)
	print("Resizing inventory")
	
	print("contecting to Dialogic signals")
	#Dialogic.timeline_started.connect(_on_dialog_start)
	#Dialogic.timeline_ended.connect(_on_dialog_end)


func updateHEART():
	#TODO: set HEART level to be a function of HEARTEXP
	pass



## used new checkpoint location 
func setCheckpoint(pos :Vector3) -> void:
	print("pos is ", pos)
	print("checkpoint position is ", checkpointPosition)
	checkpointPosition = pos;
	
	print("checkpoint position is ", checkpointPosition)
	

## These next two functions update if you are in dialogue and if you can move
func _on_dialog_start() -> void:
	#UI.closeAllInteractUIs()
	IsCurrentlyInDialogue = true;
	canMove = false

func _on_dialog_end() -> void:
	IsCurrentlyInDialogue = false;
	canMove = true




## helper function for adding items to inventory array 
func addItem(item):
	print("adding item", item)
	for i in range(inventory.size()):
		# Check if the item exists in the inventory and matches both type and effect
		if inventory[i] != null and inventory[i]["type"] == item["type"] and inventory[i]["effect"] == item["effect"]:
			inventory[i]["quantity"] += item["quantity"]
			inventory_updated.emit()
			print("Item added", inventory)
			return true
		elif inventory[i] == null:
			inventory[i] = item
			inventory_updated.emit()
			print("Item added", inventory)
			return true
	return false
	
	
## helper functuion for removing items from inventory array 
func removeItem(item_type,item_effect):
	for i in range(inventory.size()):
		if inventory[i] != null and inventory[i]["type"] == item_type and inventory[i]["effect"] == item_effect:
			inventory[i]["quantity"] -= 1
			if inventory[i]["quantity"] <= 0:
				inventory[i] = null
			inventory_updated.emit()
			return true
	return false
	
	
	
	
## could be useful for if stubert gets an item that adds inventory slots
func increaseInventorySize():
	inventory_updated.emit()	
	
	
## Absolutely vital to tell the global singleton which stubert is the correct one
## when a script refers to "player" in code. This is done here and called when
## player is first loaded into screen in their start function 	
func setPlayerReference(player):
	playerNode = player; 
	
	
	
	
## This is broken and should adjust where the item is dropped around the player
## so that it doesn't just go under you and give you some added height. idk
## that seems like a fun feature, not a bug though 
func adjust_drop_position(position):
	var radius = 100
	var nearby_items = get_tree().get_nodes_in_group("Items")
	for item in nearby_items:
		if item.global_position.distance_to(position) < radius:
			var random_offset = Vector2(randf_range(-radius, radius), randf_range(-radius, radius))
			position += random_offset
			break
	return position
	
	
	
	
## This is fired when you are in the inventory and press the drop button
func drop_item(item_data, drop_position):
	var item_scene = load(item_data["scene_path"])
	var item_instance = item_scene.instantiate()
	item_instance.set_item_data(item_data)
	drop_position = adjust_drop_position(drop_position)
	item_instance.global_position = drop_position
	get_tree().current_scene.add_child(item_instance)
	



## Very important to be able to shoot off one shot dialoguee from anywhere 
## I use this inside interactable to fire off a textbox with the description
## in order to just show what you're looking at. A short observation or 
## any situation where you need to bring up some text feedback 
func say_quick(text:String) -> void:	
	var tl := DialogicTimeline.new()
	tl.from_text(text)
	#Dialogic.Styles.load_style("res://style.tres")
	Dialogic.start(tl)
