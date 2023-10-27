extends Line2D
	
func update_trajectory(speed:float):
	clear_points()
	
	var length: float = speed / 100
	var pos: Vector2 = Vector2.ZERO
	
	for i in length:
		add_point(pos)
		pos += Vector2(10, 0)
