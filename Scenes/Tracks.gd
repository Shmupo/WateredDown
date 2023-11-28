extends Line2D

@export var rWheel: RigidBody2D
@export var rmWheel: RigidBody2D
@export var fmWheel: RigidBody2D
@export var fWheel: RigidBody2D

@onready var bot: Vector2 = Vector2(0, 10)
@onready var top: Vector2 = Vector2(0, -10)
@onready var left: Vector2 = Vector2(-10, 0)
@onready var right: Vector2 = Vector2(10, 0)
# for rear wheel
@onready var topLeft: Vector2 = Vector2(-7, -7)
@onready var botLeft: Vector2 = Vector2(-7, 7)
# for front wheel
@onready var topRight: Vector2 = Vector2(7, -7)
@onready var botRight: Vector2 = Vector2(7, 7)

func _ready():
	add_point(to_local(rWheel.global_position + topLeft))	
	add_point(to_local(rWheel.global_position + left))
	add_point(to_local(rWheel.global_position + botLeft))
	
	add_point(to_local(rWheel.global_position + bot))
	
	add_point(to_local(rmWheel.global_position + bot))
	add_point(to_local(fmWheel.global_position + bot))
	
	add_point(to_local(fWheel.global_position + bot))
	
	add_point(to_local(fWheel.global_position + botRight))
	add_point(to_local(fWheel.global_position + right))
	add_point(to_local(fWheel.global_position + topRight))
	
	add_point(to_local(fWheel.global_position + top))
	add_point(to_local(fmWheel.global_position + top))
	add_point(to_local(rmWheel.global_position + top))
	add_point(to_local(rWheel.global_position + top))
	
	add_point(to_local(rWheel.global_position + topLeft))	
	
func _process(_delta):
	set_point_position(0, to_local(rWheel.global_position + topLeft))	
	set_point_position(1, to_local(rWheel.global_position + left))
	set_point_position(2, to_local(rWheel.global_position + botLeft))
	
	set_point_position(3, to_local(rWheel.global_position + bot))
	
	set_point_position(4, to_local(rmWheel.global_position + bot))
	set_point_position(5, to_local(fmWheel.global_position + bot))
	
	set_point_position(6, to_local(fWheel.global_position + bot))
	
	set_point_position(7, to_local(fWheel.global_position + botRight))
	set_point_position(8, to_local(fWheel.global_position + right))
	set_point_position(9, to_local(fWheel.global_position + topRight))
	
	set_point_position(10, to_local(fWheel.global_position + top))
	set_point_position(11, to_local(fmWheel.global_position + top))
	set_point_position(12, to_local(rmWheel.global_position + top))
	set_point_position(13, to_local(rWheel.global_position + top))
	
	set_point_position(14, to_local(rWheel.global_position + topLeft))	
