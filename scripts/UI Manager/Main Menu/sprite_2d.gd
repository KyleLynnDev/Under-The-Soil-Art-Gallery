extends Sprite2D

var scroll_speed = Vector2(10, 0) # Adjust for desired speed and direction

func _process(delta):
	region_rect.position += scroll_speed * delta
	# Ensure the position loops to create a seamless effect
	if region_rect.position.x >= texture.get_width():
		region_rect.position.x -= texture.get_width()
	if region_rect.position.y >= texture.get_height():
		region_rect.position.y -= texture.get_height()
