extends AnimatedSprite3D

@onready var sprite = $"."

func idleForward():
	sprite.play("idle")

func idleSide():
	sprite.play("idle")
	
func idleBackward():
	sprite.play("idle")

func walkForwardsLeft():
	if sprite.animation != "walkForward":
		sprite.flip_h = true
		sprite.play("walkForward")
	
func walkForwardsRight():
	if sprite.animation != "walkForward":
		sprite.flip_h = false
		sprite.play("walkForward")
	
func walkSideLeft():
	if sprite.animation != "walkSide":
		sprite.flip_h = true
		sprite.play("walkSide")
		
func walkSideRight():
	if sprite.animation != "walkSide":
		sprite.flip_h = false
		sprite.play("walkSide")
		
func walkBackwardsLeft():
	if sprite.animation != "walkBackward":
		sprite.flip_h = true
		sprite.play("walkBackward")
		
func walkBackwardsRight():
	if sprite.animation != "walkBackward":
		sprite.flip_h = false
		sprite.play("walkBackward")
		
func jump():
	sprite.play("jump")  # You can separate if you want different jump frames

func fall():
	sprite.play("fall")  # Same here, optional
	
func set_speed_scale_from_magnitude(m: float) -> void:
	sprite.speed_scale = clamp(lerp(0.6, 1.4, m), 0.0, 2.0)

# Flip sprite depending on input direction
func set_facing_direction(direction: Vector2):
	if direction.x != 0:
		sprite.flip_h = direction.x < 0
