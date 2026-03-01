extends Node2D
class_name BombPayload

@export var velocity := Vector2(145.0, 80.0)
@export var gravity := 620.0
@export var hit_radius := 12.0

var is_active := true

func _ready() -> void:
	add_to_group("bomb_payloads")

func _process(delta: float) -> void:
	if not is_active:
		return
	velocity.y += gravity * delta
	position += velocity * delta
	if position.x > get_viewport_rect().size.x + 20.0 or position.x < -40.0 or position.y > get_viewport_rect().size.y + 40.0:
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, Color(0.95, 0.85, 0.2))
	draw_circle(Vector2.ZERO, 3.0, Color(0.15, 0.15, 0.15))
