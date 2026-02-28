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
	position.y -= speed * delta
	if position.y < -24.0:
		queue_free()

func _draw() -> void:
	draw_rect(Rect2(Vector2(-2, -10), Vector2(4, 18)), Color(1.0, 0.9, 0.35))
	draw_rect(Rect2(Vector2(-1, -8), Vector2(2, 12)), Color(1.0, 0.55, 0.15))
