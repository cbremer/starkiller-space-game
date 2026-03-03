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
	var freq_a := float(profile.get("freq_a", 0.0089))
	var freq_b := float(profile.get("freq_b", 0.019))
	var freq_c := float(profile.get("freq_c", 0.0037))
	var weight_b := float(profile.get("weight_b", 0.46))
	var weight_c := float(profile.get("weight_c", 0.80))
	var jagged := float(profile.get("jagged", 0.0))
	var y := base
	y += sin(world_x * freq_a) * amp
	y += cos(world_x * freq_b) * amp * weight_b
	y += sin(world_x * freq_c) * amp * weight_c
	if jagged > 0.0:
		y += (snapped(cos(world_x * 0.14), 0.2) * amp * 0.30 * jagged)
	return clampf(y, 26.0, size.y * 0.42)

func _draw() -> void:
	var size := get_viewport_rect().size
	var profile := _profile_for_segment(_segment_index)
	var fill_color: Color = profile["fill"]
	var line_color: Color = profile["line"]
	var points := PackedVector2Array()
	var ridge := PackedVector2Array()

	points.push_back(Vector2(0, 0))
	var step := maxf(8.0, float(profile.get("step", 20.0)))
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
	_draw_ceiling_teeth(ridge, line_color)

func _draw_ceiling_teeth(ridge: PackedVector2Array, line_color: Color) -> void:
	if ridge.size() < 2:
		return
	var tooth_color := line_color.lerp(Color.WHITE, 0.08)
	tooth_color.a = 0.34
	for i in range(0, ridge.size(), 3):
		var p := ridge[i]
		var tooth_len := 11.0 + (sin((p.x + _scroll_distance) * 0.09) + 1.0) * 7.5
		draw_line(p, p + Vector2(0, tooth_len), tooth_color, 1.0)

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
