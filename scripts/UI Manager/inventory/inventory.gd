extends Control

@onready var grid_container: GridContainer = $"Inventory backdrop"/GridContainer

@onready var heart_label: Label = $HeartPickup/HEARTLabel
@onready var coin_label: Label = $Coins/CoinLabel
@onready var key_label: Label = $NormalKey/KeyLabel



func _ready() -> void:
	Global.inventory_updated.connect(_onInventoryUpdated)
	_onInventoryUpdated()
	
	#get first child of grid container and
	#grab focus of it 
	var button = focusButton(grid_container)
	if button:
		print(button)
		button.grab_focus()	
		
		
func _process(delta: float) -> void:
	if(!self.visible):
		return
	heart_label.text = str(Global.HEART)
	coin_label.text = str(Global.coin)
	key_label.text = str(Global.keys)
	
		

func _onInventoryUpdated():
	clear_grid_container()
	#add slots for each inventory position
	for item in Global.inventory:
		var slot = Global.inventorySlotScene.instantiate()
		grid_container.add_child(slot)
		if item != null:
			slot.set_item(item)
		else:
			slot.set_empty()

func clear_grid_container():
	while grid_container.get_child_count() > 0:
		var child = grid_container.get_child(0)
		grid_container.remove_child(child)
		child.queue_free()
		
		
func focusButton(node: Node):
	for c in node.get_children():
		if c is Button:
			return c
		var nested = focusButton(c)
		if nested:
			return nested
	return null
		
		
			
			
			
