extends Control


@onready var item_icon: Sprite2D = $innerRect/itemIcon

@onready var item_quantity: Label = $innerRect/itemQuantity
@onready var details_panel: ColorRect = $detailsPanel
@onready var item_name: Label = $detailsPanel/itemName
@onready var item_type: Label = $detailsPanel/itemType
@onready var item_effect: Label = $detailsPanel/itemEffect
@onready var usage_panel: ColorRect = $UsagePanel

#slot item
var item = null


func _ready() -> void:
	$innerRect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # background lets clicks through
	$itemButton.mouse_filter = Control.MOUSE_FILTER_STOP    # button is the click target
	$itemButton.focus_mode = Control.FOCUS_ALL              # optional, for keyboard/pad


func _on_item_button_mouse_exited() -> void:
	details_panel.visible = false
	


func _on_item_button_mouse_entered() -> void:
	if item != null:
		usage_panel.visible = false
		details_panel.visible = true


func _on_item_button_pressed() -> void:
	if item != null:
		usage_panel.visible = !usage_panel.visible 

func set_empty():
	item_icon.texture = null
	item_quantity.text = ""
	
func set_item(new_item):
	item = new_item
	item_icon.texture = new_item["texture"]
	item_quantity.text = str(item["quantity"])
	
	item_name.text = str(item["name"])
	item_type.text = str(item["type"])
	if item["effect"] != "":
		item_effect.text = str("+", item["effect"])
	else:
		item_effect.text = ""


func _on_drop_button_pressed() -> void:
	if item != null:
		var drop_position = Global.playerNode.global_position
		var drop_offset = Vector3(0, 0,50)
		#drop_offset = drop_offset.rotated(Global.playerNode.rotation)
		Global.drop_item(item, drop_position )
		Global.removeItem(item["type"], item["effect"])
		usage_panel.visible = false


func _on_use_button_pressed() -> void:
	usage_panel.visible = false
	
	if item != null and item["effect"] != "":
		if Global.playerNode:
			Global.playerNode.applyItemEffects(item)
			Global.removeItem(item["type"], item["effect"])
		else:
			print("player could not be found")
			
	
			
