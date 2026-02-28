extends Node2D
class_name PlayerShip

@export var speed := 300.0
@export var bounds := Rect2(Vector2(40, 120), Vector2(880, 420))

var input_vector := Vector2.ZERO

func _physics_process(delta: float) -> void:
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()
	position += input_vector * speed * delta
	position = Vector2(
		clampf(position.x, bounds.position.x, bounds.end.x),
		clampf(position.y, bounds.position.y, bounds.end.y)
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
