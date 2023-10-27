extends RigidBody2D

var wheels: Array
@export var acceleration = 0.5

# Called when the node enters the scene tree for the first time.
func _ready():
	$BodyAnimatedSprite.play()
	$Cannon/CannonAnimatedSprite.play()
	
	wheels.append($FrontWheel/RigidBody2D)
	wheels.append($RearWheel/RigidBody2D)
	wheels.append($FrontMidWheel/RigidBody2D)
	wheels.append($RearMidWheel/RigidBody2D)

func _process(_delta):
	for wheel in wheels:
		wheel.angular_velocity += acceleration
	
		if abs(wheel.angular_velocity) > 5:
			if wheel.angular_velocity > 0:
				wheel.angular_velocity = 2
			if wheel.angular_velocity < 0:
				wheel.angular_velocity = -2
