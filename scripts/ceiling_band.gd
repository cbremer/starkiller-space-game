extends Node2D

const SEGMENT_PROFILES := [
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

var _scroll_distance := 0.0
var _segment_index := 0
var _profile_override: Dictionary = {}
var _base_ratio := 0.16
var _amplitude := 18.0
var _freq_a := 0.0089
var _freq_b := 0.019
var _freq_c := 0.0037
var _weight_b := 0.46
var _weight_c := 0.80
var _jagged := 0.0
var _sample_step := 20.0
var _fill_color := Color(0.14, 0.17, 0.13)
var _line_color := Color(0.27, 0.35, 0.24)

const BASE_MIN := 0.05
const BASE_MAX := 0.40
const AMP_MIN := 4.0
const AMP_MAX := 120.0

func set_scroll_distance(distance: float) -> void:
	if is_equal_approx(_scroll_distance, distance):
		return
	_scroll_distance = distance
	queue_redraw()

func set_segment_index(index: int) -> void:
	var next_index: int = max(index, 0)
	if _segment_index == next_index:
		return
	_segment_index = next_index
	_refresh_profile_cache()
	queue_redraw()

func set_profile_override(profile: Dictionary) -> void:
	var next_override: Dictionary = profile if typeof(profile) == TYPE_DICTIONARY else {}
	if _profile_override == next_override:
		return
	_profile_override = next_override
	_refresh_profile_cache()
	queue_redraw()

func ceiling_height_at_screen_x(screen_x: float) -> float:
	var size := get_viewport_rect().size
	return _ceiling_height_for_world_x(screen_x + _scroll_distance, size.y)

func _draw() -> void:
	var size := get_viewport_rect().size
	var points := PackedVector2Array()
	var ridge := PackedVector2Array()

	points.push_back(Vector2(0, 0))
	var step := _sample_step
	var x := 0.0
	while x <= size.x + step:
		var y := _ceiling_height_for_world_x(x + _scroll_distance, size.y)
		var point := Vector2(x, y)
		points.push_back(point)
		ridge.push_back(point)
		x += step
	points.push_back(Vector2(size.x + step, 0))

	draw_colored_polygon(points, _fill_color)
	draw_polyline(ridge, _line_color, 2.5)
	_draw_ceiling_teeth(ridge)

func _draw_ceiling_teeth(ridge: PackedVector2Array) -> void:
	if ridge.size() < 2:
		return
	var tooth_color := _line_color.lerp(Color.WHITE, 0.08)
	tooth_color.a = 0.34
	for i in range(0, ridge.size(), 3):
		var p := ridge[i]
		var tooth_len := 11.0 + (sin((p.x + _scroll_distance) * 0.09) + 1.0) * 7.5
		draw_line(p, p + Vector2(0, tooth_len), tooth_color, 1.0)

func _refresh_profile_cache() -> void:
	var base_profile: Dictionary = SEGMENT_PROFILES[min(_segment_index, SEGMENT_PROFILES.size() - 1)]
	var resolved := base_profile if _profile_override.is_empty() else _merge_profile(base_profile, _profile_override)
	_base_ratio = float(resolved["base"])
	_amplitude = float(resolved["amp"])
	_freq_a = float(resolved.get("freq_a", 0.0089))
	_freq_b = float(resolved.get("freq_b", 0.019))
	_freq_c = float(resolved.get("freq_c", 0.0037))
	_weight_b = float(resolved.get("weight_b", 0.46))
	_weight_c = float(resolved.get("weight_c", 0.80))
	_jagged = float(resolved.get("jagged", 0.0))
	_sample_step = maxf(8.0, float(resolved.get("step", 20.0)))
	_fill_color = resolved["fill"]
	_line_color = resolved["line"]

func _ceiling_height_for_world_x(world_x: float, viewport_height: float) -> float:
	var y := viewport_height * _base_ratio
	y += sin(world_x * _freq_a) * _amplitude
	y += cos(world_x * _freq_b) * _amplitude * _weight_b
	y += sin(world_x * _freq_c) * _amplitude * _weight_c
	if _jagged > 0.0:
		y += snapped(cos(world_x * 0.14), 0.2) * _amplitude * 0.30 * _jagged
	return clampf(y, 26.0, viewport_height * 0.42)

func _merge_profile(base: Dictionary, override: Dictionary) -> Dictionary:
	var merged: Dictionary = base.duplicate(true)
	var base_value: Variant = override.get("base")
	if typeof(base_value) == TYPE_FLOAT or typeof(base_value) == TYPE_INT:
		merged["base"] = clampf(float(base_value), BASE_MIN, BASE_MAX)
	var amp_value: Variant = override.get("amp")
	if typeof(amp_value) == TYPE_FLOAT or typeof(amp_value) == TYPE_INT:
		merged["amp"] = clampf(float(amp_value), AMP_MIN, AMP_MAX)
	for key in ["freq_a", "freq_b", "freq_c", "weight_b", "weight_c", "jagged", "step"]:
		var key_value: Variant = override.get(key)
		if typeof(key_value) == TYPE_FLOAT or typeof(key_value) == TYPE_INT:
			merged[key] = float(key_value)
	var fill_value: Variant = override.get("fill")
	if typeof(fill_value) == TYPE_COLOR:
		merged["fill"] = fill_value
	var line_value: Variant = override.get("line")
	if typeof(line_value) == TYPE_COLOR:
		merged["line"] = line_value
	return merged
