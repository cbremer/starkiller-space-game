extends Node2D

var _scroll_distance := 0.0
var _segment_index := 0
var _override_profile: Dictionary = {}

func set_scroll_distance(distance: float) -> void:
	_scroll_distance = distance
	queue_redraw()

func set_segment_index(index: int) -> void:
	_segment_index = max(index, 0)
	queue_redraw()

func set_profile_override(profile: Dictionary) -> void:
	_override_profile = profile.duplicate(true)
	queue_redraw()

func ground_height_at_screen_x(screen_x: float) -> float:
	var size := get_viewport_rect().size
	var profile := _profile_for_segment(_segment_index)
	var world_x := screen_x + _scroll_distance
	var base := size.y * float(profile["base"])
	var amp := float(profile["amp"])
	var y := base
	y += sin(world_x * 0.0105) * amp
	y += sin(world_x * 0.027) * amp * 0.42
	y += cos(world_x * 0.0041) * amp * 0.58
	return clampf(y, size.y * 0.55, size.y - 34.0)

func _draw() -> void:
	var size := get_viewport_rect().size
	var profile := _profile_for_segment(_segment_index)
	var fill_color: Color = profile["fill"]
	var line_color: Color = profile["line"]
	var points := PackedVector2Array()
	var ridge := PackedVector2Array()

	points.push_back(Vector2(0, size.y))
	var step := 24.0
	var x := 0.0
	while x <= size.x + step:
		var y := ground_height_at_screen_x(x)
		var point := Vector2(x, y)
		points.push_back(point)
		ridge.push_back(point)
		x += step
	points.push_back(Vector2(size.x + step, size.y))

	draw_colored_polygon(points, fill_color)
	draw_polyline(ridge, line_color, 2.5)

func _profile_for_segment(index: int) -> Dictionary:
	var profiles := [
		{
			"base": 0.84,
			"amp": 18.0,
			"fill": Color(0.18, 0.23, 0.16),
			"line": Color(0.30, 0.42, 0.24)
		},
		{
			"base": 0.82,
			"amp": 30.0,
			"fill": Color(0.25, 0.20, 0.14),
			"line": Color(0.45, 0.36, 0.23)
		},
		{
			"base": 0.80,
			"amp": 38.0,
			"fill": Color(0.20, 0.16, 0.22),
			"line": Color(0.36, 0.28, 0.44)
		}
	]
	var profile := profiles[min(index, profiles.size() - 1)].duplicate(true)
	for key in _override_profile.keys():
		profile[key] = _override_profile[key]
	return profile
