extends Node2D

var _scroll_distance := 0.0
var _segment_index := 0
var _profile_override: Dictionary = {}

const BASE_MIN := 0.55
const BASE_MAX := 0.95
const AMP_MIN := 4.0
const AMP_MAX := 160.0

func set_scroll_distance(distance: float) -> void:
	_scroll_distance = distance
	queue_redraw()

func set_segment_index(index: int) -> void:
	_segment_index = max(index, 0)
	queue_redraw()

func set_profile_override(profile: Dictionary) -> void:
	if typeof(profile) == TYPE_DICTIONARY:
		_profile_override = profile
	else:
		_profile_override = {}
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
	var profile: Dictionary = profiles[min(index, profiles.size() - 1)]
	if _profile_override.is_empty():
		return profile
	return _merge_profile(profile, _profile_override)

func _merge_profile(base: Dictionary, override: Dictionary) -> Dictionary:
	var merged: Dictionary = base.duplicate(true)
	var base_value: Variant = override.get("base")
	if typeof(base_value) == TYPE_FLOAT or typeof(base_value) == TYPE_INT:
		merged["base"] = clampf(float(base_value), BASE_MIN, BASE_MAX)
	var amp_value: Variant = override.get("amp")
	if typeof(amp_value) == TYPE_FLOAT or typeof(amp_value) == TYPE_INT:
		merged["amp"] = clampf(float(amp_value), AMP_MIN, AMP_MAX)
	var fill_value: Variant = override.get("fill")
	if typeof(fill_value) == TYPE_COLOR:
		merged["fill"] = fill_value
	var line_value: Variant = override.get("line")
	if typeof(line_value) == TYPE_COLOR:
		merged["line"] = line_value
	return merged
