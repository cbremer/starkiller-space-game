extends Node2D

const SPACEPORT_SPIRES_TEXTURE := preload("res://assets/concept_samples/props/spaceport_spires.svg")
const MONOLITH_GATE_TEXTURE := preload("res://assets/concept_samples/props/monolith_gate.svg")

var _scroll_distance := 0.0
var _segment_index := 0
var _palette_override: Dictionary = {}
var _style_override: Dictionary = {}

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

func set_style_override(style: Dictionary) -> void:
	if typeof(style) == TYPE_DICTIONARY:
		_style_override = style
	else:
		_style_override = {}
	queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	var palette := _palette_for_segment(_segment_index)
	var style := _style_for_segment(_segment_index)

	draw_rect(Rect2(Vector2.ZERO, size), palette["sky"])
	draw_rect(Rect2(Vector2(0, size.y * 0.48), Vector2(size.x, size.y * 0.52)), palette["haze"])

	match String(style.get("mode", "atmosphere")):
		"space":
			_draw_stars(size, style, palette)
			_draw_planet(size, style, palette)
		"moon":
			_draw_stars(size, style, palette)
			_draw_moon_surface(size, palette)
			_draw_planet(size, style, palette)
			_draw_prop_clusters(size, style, palette)
		"jupiter":
			_draw_gas_bands(size, style, palette)
			_draw_distant_traffic(size, palette)
			_draw_prop_clusters(size, style, palette)
		"tunnel":
			_draw_tunnel_glow(size, palette)
			_draw_distant_traffic(size, palette)
		_:
			_draw_clouds(size, style, palette)
			_draw_prop_clusters(size, style, palette)
			_draw_hill_band(size, 0.20, size.y * 0.56, 34.0, palette["far_hill"])
			_draw_hill_band(size, 0.35, size.y * 0.64, 46.0, palette["mid_hill"])

func _draw_prop_clusters(size: Vector2, style: Dictionary, palette: Dictionary) -> void:
	var prop_density := clampf(float(style.get("prop_density", 1.0)), 0.35, 2.4)
	var stride := int(clampf(360.0 / prop_density, 170.0, 520.0))
	var scroll_parallax := 0.17
	var tint := Color(palette["cloud"]).lerp(palette["far_hill"], 0.55)
	tint.a = 0.34
	var base_y := size.y * 0.69
	for x in range(-stride, int(size.x) + stride * 2, stride):
		var cluster_index := int(floor((float(x) + _scroll_distance * scroll_parallax) / float(stride)))
		var draw_x := float(x) - fmod(_scroll_distance * scroll_parallax, float(stride))
		var variant_roll: int = abs(cluster_index) % 5
		var is_city_cluster: bool = variant_roll == 0 or variant_roll == 3
		var texture: Texture2D = SPACEPORT_SPIRES_TEXTURE if is_city_cluster else MONOLITH_GATE_TEXTURE
		var width_bias := 1.0 if is_city_cluster else 0.82
		var scale := 0.18 + float(abs(cluster_index * 17) % 7) * 0.035
		if is_city_cluster:
			scale += 0.05
		var prop_size := texture.get_size() * scale
		prop_size.x *= width_bias
		var y_jitter := float((abs(cluster_index * 29) % 28) - 14)
		var prop_rect := Rect2(
			Vector2(draw_x - prop_size.x * 0.5, base_y - prop_size.y + y_jitter),
			prop_size
		)
		if prop_rect.position.x > size.x + 80.0 or prop_rect.end.x < -80.0:
			continue
		draw_texture_rect(texture, prop_rect, false, tint)
		if is_city_cluster and scale > 0.28:
			var annex_scale := scale * 0.58
			var annex_size := MONOLITH_GATE_TEXTURE.get_size() * annex_scale
			var annex_rect := Rect2(
				Vector2(prop_rect.position.x + prop_size.x * 0.52, base_y - annex_size.y + y_jitter + 10.0),
				annex_size
			)
			draw_texture_rect(MONOLITH_GATE_TEXTURE, annex_rect, false, Color(tint.r, tint.g, tint.b, tint.a * 0.82))

func _draw_clouds(size: Vector2, style: Dictionary, palette: Dictionary) -> void:
	var cloud_speed := 0.22
	var cloud_density := maxf(0.3, float(style.get("cloud_density", 1.0)))
	for x in range(-120, int(size.x) + 200, 120):
		if int(x / 120) % int(maxi(1, int(round(2.0 / cloud_density)))) != 0:
			continue
		var draw_x := float(x) - fmod(_scroll_distance * cloud_speed, 120.0)
		var y := size.y * 0.24 + sin((draw_x + _scroll_distance * 0.12) / 130.0) * 12.0
		draw_circle(Vector2(draw_x, y), 20.0, palette["cloud"])
		draw_circle(Vector2(draw_x + 22.0, y + 4.0), 14.0, palette["cloud"])
		draw_circle(Vector2(draw_x - 20.0, y + 6.0), 13.0, palette["cloud"])

func _draw_stars(size: Vector2, style: Dictionary, palette: Dictionary) -> void:
	var star_density := clampf(float(style.get("star_density", 1.0)), 0.2, 2.2)
	var stride := int(clampf(28.0 / star_density, 12.0, 42.0))
	for x in range(-stride, int(size.x) + stride, stride):
		var draw_x := float(x) - fmod(_scroll_distance * 0.08, float(stride))
		var y := 24.0 + fmod((float(x) * 0.73), size.y * 0.42)
		var c := Color.WHITE.lerp(palette["cloud"], 0.4)
		c.a = 0.75
		draw_circle(Vector2(draw_x, y), 1.1 + fmod(float(x), 2.0), c)

func _draw_planet(size: Vector2, style: Dictionary, palette: Dictionary) -> void:
	var planet_scale := clampf(float(style.get("planet_scale", 1.0)), 0.5, 2.4)
	var planet_color: Color = style.get("planet_a", palette["far_hill"])
	var ring_color: Color = style.get("planet_b", palette["mid_hill"])
	var center := Vector2(size.x * 0.72 - fmod(_scroll_distance * 0.04, size.x * 1.2), size.y * 0.20)
	var radius := 58.0 * planet_scale
	draw_circle(center, radius, planet_color)
	draw_arc(center, radius + 7.0, -0.5, 2.8, 48, ring_color, 3.0)

func _draw_gas_bands(size: Vector2, style: Dictionary, palette: Dictionary) -> void:
	var stripe_density := clampf(float(style.get("stripe_density", 1.0)), 0.3, 2.2)
	var a: Color = style.get("accent_a", palette["far_hill"])
	var b: Color = style.get("accent_b", palette["mid_hill"])
	var stripe_height := maxf(10.0, 28.0 / stripe_density)
	var y := 0.0
	while y < size.y * 0.72:
		var t := fmod(y / stripe_height, 2.0)
		var col := a if t < 1.0 else b
		col.a = 0.32
		draw_rect(Rect2(Vector2(0, y + sin((y + _scroll_distance * 0.1) * 0.02) * 4.0), Vector2(size.x, stripe_height)), col)
		y += stripe_height

func _draw_tunnel_glow(size: Vector2, palette: Dictionary) -> void:
	var glow := Color(palette["cloud"])
	glow.a = 0.25
	for i in range(6):
		var inset := float(i) * 36.0 + fmod(_scroll_distance * 0.4, 36.0)
		draw_rect(Rect2(Vector2(inset, inset * 0.35), size - Vector2(inset * 2.0, inset * 0.7)), glow, false, 2.0)

func _draw_moon_surface(size: Vector2, palette: Dictionary) -> void:
	var regolith := Color(palette["mid_hill"])
	regolith.a = 0.65
	draw_rect(Rect2(Vector2(0, size.y * 0.70), Vector2(size.x, size.y * 0.30)), regolith)
	for x in range(40, int(size.x), 95):
		draw_arc(Vector2(float(x), size.y * 0.70), 24.0, PI, TAU, 18, Color(palette["far_hill"]), 2.0)

func _draw_distant_traffic(size: Vector2, palette: Dictionary) -> void:
	var tone := Color(palette["cloud"])
	tone.a = 0.35
	for i in range(5):
		var x := fmod(float(i * 220) - _scroll_distance * (0.10 + i * 0.02), size.x + 120.0) - 60.0
		var y := size.y * (0.18 + i * 0.09)
		draw_rect(Rect2(Vector2(x, y), Vector2(24 + i * 4, 3)), tone)
		draw_rect(Rect2(Vector2(x - 8, y + 1), Vector2(7, 1)), tone)

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
		{"sky": Color(0.39, 0.62, 0.84), "haze": Color(0.53, 0.69, 0.78, 0.8), "cloud": Color(0.92, 0.95, 1.0, 0.45), "far_hill": Color(0.22, 0.40, 0.48), "mid_hill": Color(0.15, 0.32, 0.38)},
		{"sky": Color(0.47, 0.56, 0.70), "haze": Color(0.60, 0.58, 0.50, 0.75), "cloud": Color(0.88, 0.84, 0.77, 0.38), "far_hill": Color(0.36, 0.33, 0.28), "mid_hill": Color(0.29, 0.24, 0.18)},
		{"sky": Color(0.30, 0.35, 0.50), "haze": Color(0.41, 0.38, 0.45, 0.72), "cloud": Color(0.74, 0.72, 0.88, 0.34), "far_hill": Color(0.22, 0.19, 0.30), "mid_hill": Color(0.16, 0.13, 0.22)}
	]
	var palette: Dictionary = palettes[min(index, palettes.size() - 1)]
	if _palette_override.is_empty():
		return palette
	return _merge_palette(palette, _palette_override)

func _style_for_segment(index: int) -> Dictionary:
	var defaults := [
		{"mode": "atmosphere", "planet_scale": 1.0, "cloud_density": 1.0},
		{"mode": "atmosphere", "planet_scale": 1.2, "cloud_density": 0.8},
		{"mode": "space", "planet_scale": 1.4, "star_density": 1.3}
	]
	var style: Dictionary = defaults[min(index, defaults.size() - 1)]
	if _style_override.is_empty():
		return style
	var merged := style.duplicate(true)
	for key in _style_override.keys():
		merged[key] = _style_override[key]
	return merged

func _merge_palette(base: Dictionary, override: Dictionary) -> Dictionary:
	var merged: Dictionary = base.duplicate(true)
	for key in ["sky", "haze", "cloud", "far_hill", "mid_hill"]:
		var value: Variant = override.get(key)
		if typeof(value) == TYPE_COLOR:
			merged[key] = value
	return merged
