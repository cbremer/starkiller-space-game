extends Node2D
class_name EnemyTarget

@export var speed := 120.0
@export var hit_radius := 16.0
@export var laser_points := 100
@export var bomb_points := 60

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
	_destroyed = true
	queue_free()
	if weapon == "bomb":
		return bomb_points
	return laser_points

func _draw() -> void:
	draw_polygon(PackedVector2Array([
		Vector2(-18, 0),
		Vector2(0, -16),
		Vector2(18, 0),
		Vector2(0, 16)
	]), PackedColorArray([Color(0.9, 0.2, 0.2)]))
	draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.8, 0.2))
