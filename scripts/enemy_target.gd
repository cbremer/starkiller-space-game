extends Node2D
class_name EnemyTarget

@export var speed := 120.0
@export var hit_radius := 16.0
@export var target_type := "air"
@export var laser_points := 50
@export var bomb_points := 80

var is_active := true
var _destroyed := false

func _ready() -> void:
	add_to_group("enemy_targets")

func _process(delta: float) -> void:
	if not is_active:
		return
	position.x -= speed * delta
	if position.x < -32.0:
		queue_free()

func apply_hit(weapon: String) -> int:
	if _destroyed:
		return 0
	if target_type == "ground" and weapon != "bomb":
		return 0
	_destroyed = true
	queue_free()
	if weapon == "bomb":
		return bomb_points
	return laser_points

func _draw() -> void:
	if target_type == "ground":
		draw_rect(Rect2(Vector2(-16, -8), Vector2(32, 16)), Color(0.58, 0.48, 0.32))
		draw_rect(Rect2(Vector2(-10, -16), Vector2(20, 8)), Color(0.82, 0.23, 0.23))
		draw_line(Vector2(0, -16), Vector2(12, -22), Color(0.95, 0.85, 0.25), 2.0)
		return

	draw_polygon(PackedVector2Array([
		Vector2(-18, 0),
		Vector2(0, -16),
		Vector2(18, 0),
		Vector2(0, 16)
	]), PackedColorArray([Color(0.9, 0.2, 0.2)]))
	draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.8, 0.2))
