extends Node2D

var _scroll_distance := 0.0
var _segment_index := 0
var _profile_override: Dictionary = {}

const BASE_MIN := 0.05
const BASE_MAX := 0.40
const AMP_MIN := 4.0
const AMP_MAX := 120.0

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

func ceiling_height_at_screen_x(screen_x: float) -> float:
	var size := get_viewport_rect().size
	var profile := _profile_for_segment(_segment_index)
	var world_x := screen_x + _scroll_distance
	var base := size.y * float(profile["base"])
	var amp := float(profile["amp"])
	var y := base
	y += sin(world_x * 0.0089) * amp
	y += cos(world_x * 0.019) * amp * 0.46
	y += sin(world_x * 0.0037) * amp * 0.8
	return clampf(y, 26.0, size.y * 0.42)

func _draw() -> void:
	var size := get_viewport_rect().size
	var profile := _profile_for_segment(_segment_index)
	var fill_color: Color = profile["fill"]
	var line_color: Color = profile["line"]
	var points := PackedVector2Array()
	var ridge := PackedVector2Array()

	points.push_back(Vector2(0, 0))
	var step := 24.0
	var x := 0.0
	while x <= size.x + step:
		var y := ceiling_height_at_screen_x(x)
		var point := Vector2(x, y)
		points.push_back(point)
		ridge.push_back(point)
		x += step
	points.push_back(Vector2(size.x + step, 0))

	draw_colored_polygon(points, fill_color)
	draw_polyline(ridge, line_color, 2.5)

func _profile_for_segment(index: int) -> Dictionary:
	var profiles := [
		{
			"base": 0.16,
			"amp": 18.0,
			"fill": Color(0.14, 0.17, 0.13),
			"line": Color(0.27, 0.35, 0.24)
		},
		{
			"base": 0.17,
			"amp": 26.0,
			"fill": Color(0.21, 0.17, 0.12),
			"line": Color(0.39, 0.31, 0.20)
		},
		{
			"base": 0.18,
			"amp": 34.0,
			"fill": Color(0.17, 0.13, 0.21),
			"line": Color(0.31, 0.24, 0.40)
		}
	]
	var profile := profiles[min(index, profiles.size() - 1)]
	if _profile_override.is_empty():
		return profile
	return _merge_profile(profile, _profile_override)

func _merge_profile(base: Dictionary, override: Dictionary) -> Dictionary:
	var merged := base.duplicate(true)
	var base_value := override.get("base")
	if typeof(base_value) == TYPE_FLOAT or typeof(base_value) == TYPE_INT:
		merged["base"] = clampf(float(base_value), BASE_MIN, BASE_MAX)
	var amp_value := override.get("amp")
	if typeof(amp_value) == TYPE_FLOAT or typeof(amp_value) == TYPE_INT:
		merged["amp"] = clampf(float(amp_value), AMP_MIN, AMP_MAX)
	var fill_value := override.get("fill")
	if typeof(fill_value) == TYPE_COLOR:
		merged["fill"] = fill_value
	var line_value := override.get("line")
	if typeof(line_value) == TYPE_COLOR:
		merged["line"] = line_value
	return merged
