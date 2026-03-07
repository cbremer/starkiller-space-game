extends Node2D
class_name ImpactFlash

@export var lifetime := 0.14
@export var start_radius := 4.0
@export var end_radius := 24.0
@export var fill_color := Color(1.0, 0.92, 0.58, 0.8)
@export var ring_color := Color(1.0, 0.74, 0.32, 1.0)

var _age := 0.0

func _ready() -> void:
	add_to_group("combat_vfx")

func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t := clampf(_age / lifetime, 0.0, 1.0)
	var radius := lerpf(start_radius, end_radius, t)
	var alpha := 1.0 - t
	var fill := fill_color
	fill.a *= alpha
	var ring := ring_color
	ring.a *= alpha
	var halo := fill
	halo.a *= 0.45
	draw_circle(Vector2.ZERO, radius * 1.55, halo)
	draw_circle(Vector2.ZERO, radius, fill)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 36, ring, 2.0)
