extends Node

# All arrays below will have their collisions generated through this script
# List contains SS2D_shapes
@export var shapeList: Array[SS2D_Shape_Closed]
# !!! POSITION MUST BE 0,0 for all destructable polygons !!!
@export var destructablePolyList: Array[Polygon2D]
# Simpler shapes without custom texture
@export var polygonList: Array[Polygon2D]

var waterClip: Array = [
	Vector2(0, -10),
	Vector2(-8, -8),
	Vector2(-10, 0),
	Vector2(-8, 8),
	Vector2(0, 10),
	Vector2(8, 8),
	Vector2(10, 0),
	Vector2(8, -8)
]

# called once
func _ready() -> void:
	generateCollisionPoly()

# returns points of merged polygons
# if returns 2 polygons, they are not mergable
func mergePolygons(poly1: PackedVector2Array, pos1: Vector2, poly2: PackedVector2Array, pos2: Vector2):
	var poly1Offset: PackedVector2Array = []
	var poly2Offset: PackedVector2Array = []
	
	for point in poly1:
		poly1Offset.append(point + pos1)
		
	for point in poly2:
		poly2Offset.append(point + pos2)
		
	return Geometry2D.merge_polygons(poly1Offset, poly2Offset)

				
# assigns each polygon a rigidbody polygon for collisions
# destructable polygons get a staticbody, everything else gets a rigidbody 
func generateCollisionPoly() -> void:
	# Polygon2D, generate rigidbody
	for p in polygonList:
		var collisionPolygon = CollisionPolygon2D.new()
		var body = RigidBody2D.new()
		body.name = "polygon"
		
		collisionPolygon.polygon = p.polygon
		
		body.set_collision_layer_value(3, true)
		body.set_collision_mask_value(1, true)
		body.set_collision_mask_value(2, true)
		body.freeze = true
		
		p.add_child(body)
		body.add_child(collisionPolygon)
		
	# Polygon2D, generate staticbody
	for p in destructablePolyList:
		var collisionPolygon = CollisionPolygon2D.new()
		var body = StaticBody2D.new()
		body.name = "polygon"
		
		collisionPolygon.polygon = p.polygon
		
		body.set_collision_layer_value(3, true)
		body.set_collision_mask_value(1, true)
		body.set_collision_mask_value(2, true)
		
		p.add_child(body)
		body.add_child(collisionPolygon)
	
	# SS2D_shape_closed, generate rigidbody
	for p in shapeList:
		var poly: PackedVector2Array = p.generate_collision_points()
		
		var collisionPolygon = CollisionPolygon2D.new()
		var body = RigidBody2D.new()
		body.name = "polygon"
		
		collisionPolygon.polygon = poly
		
		body.set_collision_layer_value(3, true)
		body.set_collision_mask_value(1, true)
		body.set_collision_mask_value(2, true)
		body.freeze = true
		
		p.add_child(body)
		body.add_child(collisionPolygon)
			
# given the original .polygon, triangulation points, and position : returns new array of polygon2Ds with offset added
func generateTriangles(oldPoints: PackedVector2Array, pos: Vector2):
	var trianglePoints = Geometry2D.triangulate_polygon(oldPoints)
	
	var newPol = Polygon2D.new()
	var points = PackedVector2Array()
	
	var triangles: Array[Polygon2D] = []
	
	# for color variation
	var color = 0
	
	for index in trianglePoints:
		points.append(oldPoints[index])
		if points.size() == 3:
			# creating the new polygon
			newPol.polygon = PackedVector2Array(points)
			newPol.position += pos
			
			# color variation
			if color == 0:
				newPol.color = Color.BLUE_VIOLET
			if color == 1:
				newPol.color = Color.ORANGE
			if color == 2:
				newPol.color = Color.GOLD
			if color == 3:
				newPol.color = Color.RED
			if color == 4:
				newPol.color = Color.GREEN
				color = -1
				
			color += 1
		
			# resetting for a new polygon
			points = PackedVector2Array()
			triangles.append(newPol)
			newPol = Polygon2D.new()
		
	return triangles
	
func _on_simulation_particle_collision(position, body) -> void:
	var terrain: CollisionPolygon2D = body.get_child(0)
	var terrainPoly: PackedVector2Array = []
	
	for point in terrain.polygon:
		terrainPoly.append(point + terrain.global_position)
	
	var waterPoly: PackedVector2Array = []
	
	for point in waterClip:
		waterPoly.append(point + position)
		
	var newPoints = Geometry2D.clip_polygons(terrainPoly, waterPoly)
	
	# need to implement adding another polygon shape in case it splits in two
	terrain.polygon = newPoints[0]
	
# updates the visual shape of destructable polygons every frame
func updateDestructableVisualPolygon():
	for p in destructablePolyList:
		var collisionShape: CollisionPolygon2D = p.get_child(0).get_child(0); # staticbody -> collisionPolygon2D
		if p.polygon != collisionShape.polygon:
			p.polygon = collisionShape.polygon
	
func _process(_delta) -> void:
	updateDestructableVisualPolygon()
