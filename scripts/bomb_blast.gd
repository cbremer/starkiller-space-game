extends Node2D
class_name BombBlast

@export var lifetime := 0.35
@export var max_radius := 160.0
@export var line_width := 5.0

var _age := 0.0

func _ready() -> void:
	add_to_group("bomb_blasts")

func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t := clampf(_age / lifetime, 0.0, 1.0)
	var radius := lerpf(8.0, max_radius, t)
	var alpha := 1.0 - t
	draw_circle(Vector2.ZERO, radius * 0.72, Color(1.0, 0.86, 0.42, alpha * 0.18))
	draw_arc(
		Vector2.ZERO,
		radius,
		0.0,
		TAU,
		72,
		Color(0.95, 0.85, 0.25, alpha),
		line_width
	)
