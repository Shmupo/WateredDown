extends RigidBody2D

@export var acceleration: float = 0.2
@export var maxAcceleration: float = 5
@export var fireVelocity: float = 500
@export var simulator: Node

# tank cannot move if fuel = 0
var fuel: int = 1000
# true when tank fires, signaling end of turn and disabling cannon input
var turn: bool = false

var maxParticlesContained: int = 50
var particlesContained: int = 0

var wheels: Array
var cannon: Node2D
var cannonTip: Node2D
var bodyAnimation: AnimatedSprite2D
var cannonAnimation: AnimatedSprite2D
var trajectory: Line2D
var splashAnim: CPUParticles2D

var turretSprite: AnimatedSprite2D
var turretInternalSprite: AnimatedSprite2D

var fireSound: AudioStreamPlayer2D
var engineSound: AudioStreamPlayer2D

var soundLevel = -75

signal player_turn_end
signal water_level_change
signal fuel_level_change

func _ready():
		# assigning parts
	wheels.append($FrontWheel/TankWheel)
	wheels.append($RearWheel/TankWheel)
	wheels.append($FrontMidWheel/TankWheel)
	wheels.append($RearMidWheel/TankWheel)
	
	bodyAnimation = $BodyAnimatedSprite
	cannonAnimation = $Cannon/CannonAnimatedSprite
	turretSprite = $TurretAnimatedSprite
	turretInternalSprite = $TurretInternalAnimatedSprite
	cannon = $Cannon
	cannonTip = $Cannon/CannonTip
	trajectory = $Cannon/CannonTip/Trajectory
	splashAnim = $WaterSplash
	
	fireSound = $FireSound
	engineSound = $EngineSound
	
	loadVolumeLevel()
	
func loadVolumeLevel() -> void:
	if ResourceLoader.exists("res://Resources/Settings.tres"):
		var result = ResourceLoader.load("res://Resources/Settings.tres")
		
		soundLevel = result.soundEffectVolume
		
		fireSound.volume_db = soundLevel - 75
		engineSound.volume_db = soundLevel - 75

func start(pos: Vector2) -> void:
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

func _process(_delta) -> void:
	# movement
	if fuel > 0:
		if Input.is_action_pressed("move_left"):
			rotateWheels(-acceleration)
			bodyAnimation.play()
			cannonAnimation.play()
			turretSprite.play()
			turretInternalSprite.play()
			fuel -= 1
			fuel_level_change.emit()
			if not engineSound.playing:
				engineSound.play()
		if Input.is_action_pressed("move_right"):
			rotateWheels(acceleration)
			bodyAnimation.play()
			cannonAnimation.play()
			turretSprite.play()
			turretInternalSprite.play()
			fuel -= 1
			fuel_level_change.emit()
			if not engineSound.playing:
				engineSound.play()
		if !Input.is_anything_pressed():
			stopWheels()
			if engineSound.playing:
				engineSound.stop()
	
	if fuel == 0:
		stopWheels()
		
	if turn:
		# cannon
		if Input.is_action_pressed("aim_up"):
			if cannon.rotation_degrees > -200:
				cannon.rotate(-0.01)
		if Input.is_action_pressed("aim_down"):
			if cannon.rotation_degrees < 20:
				cannon.rotate(0.01)
		if Input.is_action_just_pressed("fire"):
			var vel = Vector2.from_angle(cannon.rotation + rotation) * fireVelocity
			if simulator != null:
				simulator.FireBlob(15, cannonTip.global_position, vel)
				fireSound.play()
				fuel = 0
				turn = false
				player_turn_end.emit()
			
		if Input.is_action_pressed("fire_velocity_up"): 
			if fireVelocity < 1500:
				fireVelocity += 2
		if Input.is_action_pressed("fire_velocity_down"):
			if fireVelocity > 0:
				fireVelocity -= 2
		
		trajectory.show()
		trajectory.update_trajectory(fireVelocity)
		
	if !turn:
		trajectory.hide()
	
	# idle
	if abs(linear_velocity.x) < 1:
		bodyAnimation.stop()
		cannonAnimation.stop()

func _on_water_area_body_shape_entered(_body_rid, _body, _body_shape_index, _local_shape_index) -> void:
	particlesContained += 1
	water_level_change.emit()
	splashAnim.emitting = true;
	
func _on_water_area_body_shape_exited(_body_rid, _body, _body_shape_index, _local_shape_index) -> void:
	particlesContained -= 1
	water_level_change.emit()
	
func turretVisibility(toggled: bool) -> void:
	if toggled:
		turretSprite.hide()
	if not toggled:
		turretSprite.show()
