extends RigidBody2D

@export var acceleration = 0.2
@export var maxAcceleration = 5
@export var simulator: Node

var wheels: Array
var cannon: Node2D
var cannonTip: Node2D
var bodyAnimation: AnimatedSprite2D
var cannonAnimation: AnimatedSprite2D
var splashAnim: CPUParticles2D

signal ai_turn_end
signal water_level_change

var rng: RandomNumberGenerator

var fireSound: AudioStreamPlayer2D
var engineSound: AudioStreamPlayer2D

var soundLevel = -75

var movement: int = -1
var direction: int

var fireSpeed: float

var rotatingCannon: bool = false
var targetCannonRotation: float
var t: float = 0.0

var readyToFire: bool

var maxParticlesContained: int = 50
var particlesContained: int

var playerTank

func _ready() -> void:
		# assigning parts
	wheels.append($FrontWheel/TankWheel)
	wheels.append($RearWheel/TankWheel)
	wheels.append($FrontMidWheel/TankWheel)
	wheels.append($RearMidWheel/TankWheel)
	
	bodyAnimation = $BodyAnimatedSprite
	cannonAnimation = $Cannon/CannonAnimatedSprite
	cannon = $Cannon
	cannonTip = $Cannon/CannonTip
	splashAnim = $WaterSplash
	
	fireSound = $FireSound
	engineSound = $EngineSound
	
	rng = RandomNumberGenerator.new()
	
	loadVolumeLevel()
	
func loadVolumeLevel() -> void:
	if ResourceLoader.exists("res://Resources/Settings.tres"):
		var result = ResourceLoader.load("res://Resources/Settings.tres")
		
		soundLevel = result.soundEffectVolume
		
		fireSound.volume_db = soundLevel - 75
		engineSound.volume_db = soundLevel - 75

func start(pos) -> void:
	# setting start position
	position = pos
	show()

func rotateWheels(force: float) -> void:
	for wheel in wheels:
		wheel.angular_velocity += force
		
		# limiting max speed via acceleration
		if abs(wheel.angular_velocity) > maxAcceleration:
			if wheel.angular_velocity > 0:
				wheel.angular_velocity = maxAcceleration
			if wheel.angular_velocity < 0:
				wheel.angular_velocity = -maxAcceleration

func stopWheels() -> void:
	for wheel in wheels:
		wheel.lock_rotation = true
	
func executeTurn() -> void:
	# moving tank
	direction = rng.randi_range(-1, 1)
	if direction != 0:
		if position.x > 1300:
			direction = -1
		movement = rng.randi_range(100, 500)
	else: movement = 0

# draws incrementing arc every update
func getTrajectory(startPos: Vector2, targetPos:Vector2) -> void:
	var xDist = startPos.x - targetPos.x + 20
	
	# pick random fire velocity
	if (xDist < 500): 
		fireSpeed = rng.randi_range(500, 1500)
	if (xDist > 500): 
		fireSpeed = rng.randi_range(1000, 1500)
	
	var angle = 0.5 * asin(980 * abs(xDist) / (fireSpeed * fireSpeed))
	
	#print("Fire Velocity : ", fireSpeed, " FireRadians : ", angle)
	
	targetCannonRotation = angle + -rotation
	
func rotateCannon(delta: float):
	# snapping to 0.1 radians equals around 5 degrees of error
	if snappedf(cannon.rotation, 0.1) != snappedf(targetCannonRotation, 0.1):
		t += delta * 0.1
		cannon.rotation = lerp_angle(cannon.rotation, targetCannonRotation, t)
	else:
		t = 0.0
		rotatingCannon = false
		readyToFire = true
	
func fireCannon():
	var vel = Vector2.from_angle(cannon.rotation + rotation) * -fireSpeed
	simulator.FireBlob(15, cannonTip.global_position, vel)
	fireSound.play()
	
func _process(delta) -> void:
	if movement == -1:
		stopWheels()
	if movement == 0:
		engineSound.stop()
		getTrajectory(position, playerTank.position)
		rotatingCannon = true
		movement = -1
	if movement > 0:
		if not engineSound.playing:
			engineSound.play()
			
		rotateWheels(acceleration * direction)
		movement -= 1
		
	if rotatingCannon:
		rotateCannon(delta)
		
	if readyToFire:
		fireCannon()
		readyToFire = false
		ai_turn_end.emit()
		
	if abs(linear_velocity.x) < 1:
		bodyAnimation.stop()
		cannonAnimation.stop()

func _on_water_area_body_shape_entered(_body_rid, _body, _body_shape_index, _local_shape_index) -> void:
	particlesContained += 1
	water_level_change.emit()
	splashAnim.emitting = true
	
func _on_water_area_body_shape_exited(_body_rid, _body, _body_shape_index, _local_shape_index) -> void:
	particlesContained -= 1
	water_level_change.emit()
