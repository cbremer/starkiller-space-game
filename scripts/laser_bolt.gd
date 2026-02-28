extends Node2D
class_name LaserBolt

@export var speed := 520.0
@export var hit_radius := 10.0

var is_active := true

func _ready() -> void:
	add_to_group("laser_bolts")

func _process(delta: float) -> void:
	if not is_active:
		return
	position.x += speed * delta
	if position.x > 1088.0:
		queue_free()

func _draw() -> void:
	draw_rect(Rect2(Vector2(-10, -2), Vector2(18, 4)), Color(1.0, 0.9, 0.35))
	draw_rect(Rect2(Vector2(-8, -1), Vector2(12, 2)), Color(1.0, 0.55, 0.15))
