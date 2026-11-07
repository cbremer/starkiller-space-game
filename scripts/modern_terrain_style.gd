extends RefCounted
## Reuses the exact collision ridge; adds depth only on its solid side.
static func draw_surface(canvas: Node2D, ridge: PackedVector2Array, fill: Color, rim: Color, floor_side: bool) -> void:
	var direction := 1.0 if floor_side else -1.0
	for depth in [72.0, 32.0, 9.0]:
		var points := PackedVector2Array(ridge)
		var colors := PackedColorArray()
		var top := rim.lerp(Color(0.58, 0.77, 0.86), 0.25)
		for _point in ridge:
			colors.append(top)
		for i in range(ridge.size() - 1, -1, -1):
			points.append(ridge[i] + Vector2(0.0, direction * depth))
			colors.append(fill.darkened(0.45))
		canvas.draw_polygon(points, colors)
	canvas.draw_polyline(ridge, rim.lightened(0.3), 1.5, true)
