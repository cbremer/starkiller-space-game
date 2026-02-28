extends Node2D
class_name FuelTank

@export var speed := 120.0
@export var hit_radius := 14.0
@export var fuel_amount := 26.0

var is_active := true

func _ready() -> void:
	add_to_group("fuel_tanks")

func _process(delta: float) -> void:
	if not is_active:
		return
	position.x -= speed * delta
	if position.x < -30.0:
		queue_free()

func _draw() -> void:
	draw_rect(Rect2(Vector2(-10, -16), Vector2(20, 32)), Color(0.86, 0.84, 0.74))
	draw_rect(Rect2(Vector2(-6, -20), Vector2(12, 6)), Color(0.78, 0.2, 0.2))
	draw_line(Vector2(-4, -4), Vector2(4, -4), Color(0.2, 0.2, 0.2), 2.0)
