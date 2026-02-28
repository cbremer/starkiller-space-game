extends Node2D
class_name LaserBolt

@export var speed := 520.0

func _process(delta: float) -> void:
	position.y -= speed * delta
	if position.y < -24.0:
		queue_free()

func _draw() -> void:
	draw_rect(Rect2(Vector2(-2, -10), Vector2(4, 18)), Color(1.0, 0.9, 0.35))
	draw_rect(Rect2(Vector2(-1, -8), Vector2(2, 12)), Color(1.0, 0.55, 0.15))
