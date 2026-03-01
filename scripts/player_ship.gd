extends Node2D
class_name PlayerShip

@export var speed := 300.0
@export var horizontal_margin := 40.0
@export var top_margin := 52.0
@export var bottom_margin := 28.0

var input_vector := Vector2.ZERO

func _physics_process(delta: float) -> void:
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()
	position += input_vector * speed * delta

	var viewport_size := get_viewport_rect().size
	var min_x := horizontal_margin
	var max_x := maxf(min_x, viewport_size.x - horizontal_margin)
	var min_y := top_margin
	var max_y := maxf(min_y, viewport_size.y - bottom_margin)

	position = Vector2(
		clampf(position.x, min_x, max_x),
		clampf(position.y, min_y, max_y)
	)
	queue_redraw()

func _draw() -> void:
	draw_polygon(PackedVector2Array([
		Vector2(18, 0),
		Vector2(-14, -12),
		Vector2(-6, 0),
		Vector2(-14, 12)
	]), PackedColorArray([Color.CYAN]))
	draw_line(Vector2(-10, 0), Vector2(-18, 0), Color.YELLOW, 2.0)
