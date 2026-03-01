extends Node2D

var _scroll_distance := 0.0
var _segment_index := 0
var _palette_override: Dictionary = {}

func set_scroll_distance(distance: float) -> void:
	_scroll_distance = distance
	queue_redraw()

func set_segment_index(index: int) -> void:
	_segment_index = max(index, 0)
	queue_redraw()

func set_palette_override(palette: Dictionary) -> void:
	if typeof(palette) == TYPE_DICTIONARY:
		_palette_override = palette
	else:
		_palette_override = {}
	queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	var palette := _palette_for_segment(_segment_index)

	draw_rect(Rect2(Vector2.ZERO, size), palette["sky"])
	draw_rect(Rect2(Vector2(0, size.y * 0.5), Vector2(size.x, size.y * 0.5)), palette["haze"])

	var cloud_speed := 0.22
	for x in range(-120, int(size.x) + 160, 120):
		var draw_x := float(x) - fmod(_scroll_distance * cloud_speed, 120.0)
		var y := size.y * 0.24 + sin((draw_x + _scroll_distance * 0.12) / 130.0) * 12.0
		draw_circle(Vector2(draw_x, y), 20.0, palette["cloud"])
		draw_circle(Vector2(draw_x + 22.0, y + 4.0), 14.0, palette["cloud"])
		draw_circle(Vector2(draw_x - 20.0, y + 6.0), 13.0, palette["cloud"])

	_draw_hill_band(size, 0.18, size.y * 0.56, 34.0, palette["far_hill"])
	_draw_hill_band(size, 0.34, size.y * 0.64, 46.0, palette["mid_hill"])

func _draw_hill_band(size: Vector2, parallax: float, base_y: float, amplitude: float, color: Color) -> void:
	var step := 8.0
	var x := 0.0
	while x <= size.x + step:
		var world_x := x + _scroll_distance * parallax
		var y := base_y + sin(world_x * 0.0103) * amplitude + cos(world_x * 0.0048) * amplitude * 0.65
		draw_line(Vector2(x, y), Vector2(x, size.y), color, step + 1.0)
		x += step

func _palette_for_segment(index: int) -> Dictionary:
	var palettes := [
		{
			"sky": Color(0.39, 0.62, 0.84),
			"haze": Color(0.53, 0.69, 0.78, 0.8),
			"cloud": Color(0.92, 0.95, 1.0, 0.45),
			"far_hill": Color(0.22, 0.40, 0.48),
			"mid_hill": Color(0.15, 0.32, 0.38)
		},
		{
			"sky": Color(0.47, 0.56, 0.70),
			"haze": Color(0.60, 0.58, 0.50, 0.75),
			"cloud": Color(0.88, 0.84, 0.77, 0.38),
			"far_hill": Color(0.36, 0.33, 0.28),
			"mid_hill": Color(0.29, 0.24, 0.18)
		},
		{
			"sky": Color(0.30, 0.35, 0.50),
			"haze": Color(0.41, 0.38, 0.45, 0.72),
			"cloud": Color(0.74, 0.72, 0.88, 0.34),
			"far_hill": Color(0.22, 0.19, 0.30),
			"mid_hill": Color(0.16, 0.13, 0.22)
		}
	]
	var palette: Dictionary = palettes[min(index, palettes.size() - 1)]
	if _palette_override.is_empty():
		return palette
	return _merge_palette(palette, _palette_override)

func _merge_palette(base: Dictionary, override: Dictionary) -> Dictionary:
	var merged: Dictionary = base.duplicate(true)
	for key in ["sky", "haze", "cloud", "far_hill", "mid_hill"]:
		var value: Variant = override.get(key)
		if typeof(value) == TYPE_COLOR:
			merged[key] = value
	return merged
