extends Resource
class_name StageSegmentSettings

const DEFAULT_SEGMENTS: Array[Dictionary] = [
	{
		"segment_name": "Sector 1: Open Sky",
		"length_px": 11400.0,
		"enemy_spawn_interval": 1.4,
		"enemy_spawn_variance": 0.35,
		"ground_target_chance": 0.20,
		"air_speed_min": 120.0,
		"air_speed_max": 185.0,
		"ground_speed_min": 90.0,
		"ground_speed_max": 125.0,
		"fuel_tank_interval": 18.0,
		"fuel_tank_amount": 28.0
	},
	{
		"segment_name": "Sector 2: Canyon",
		"length_px": 11400.0,
		"enemy_spawn_interval": 1.2,
		"enemy_spawn_variance": 0.32,
		"ground_target_chance": 0.30,
		"air_speed_min": 135.0,
		"air_speed_max": 205.0,
		"ground_speed_min": 100.0,
		"ground_speed_max": 140.0,
		"fuel_tank_interval": 15.0,
		"fuel_tank_amount": 25.0
	},
	{
		"segment_name": "Sector 3: Fortress Run",
		"length_px": 11400.0,
		"enemy_spawn_interval": 1.0,
		"enemy_spawn_variance": 0.26,
		"ground_target_chance": 0.38,
		"air_speed_min": 150.0,
		"air_speed_max": 220.0,
		"ground_speed_min": 110.0,
		"ground_speed_max": 150.0,
		"fuel_tank_interval": 13.0,
		"fuel_tank_amount": 23.0
	}
]
const TERRAIN_BASE_MIN := 0.62
const TERRAIN_BASE_MAX := 0.92
const CEILING_BASE_MIN := 0.08
const CEILING_BASE_MAX := 0.35
const PROFILE_AMP_MIN := 4.0
const PROFILE_AMP_MAX := 120.0

@export var segments: Array[Dictionary] = []

func normalized_segments() -> Array[Dictionary]:
	var normalized: Array[Dictionary] = []
	for raw_segment in segments:
		if typeof(raw_segment) != TYPE_DICTIONARY:
			continue
		normalized.append(_normalize_segment(raw_segment))
	return normalized

func normalized_segments_or_default() -> Array[Dictionary]:
	var normalized := normalized_segments()
	if not normalized.is_empty():
		return normalized
	return default_segments()

static func default_segments() -> Array[Dictionary]:
	var copy: Array[Dictionary] = []
	for segment in DEFAULT_SEGMENTS:
		copy.append(segment.duplicate(true))
	return copy

func _normalize_segment(raw_segment: Dictionary) -> Dictionary:
	var ground_target_chance := _to_float_or(raw_segment.get("ground_target_chance"), 0.40)
	var normalized := {
		"segment_name": String(raw_segment.get("segment_name", "Unnamed Sector")),
		"length_px": maxf(_to_float_or(raw_segment.get("length_px"), 2400.0), 100.0),
		"enemy_spawn_interval": maxf(_to_float_or(raw_segment.get("enemy_spawn_interval"), 1.0), 0.1),
		"enemy_spawn_variance": maxf(_to_float_or(raw_segment.get("enemy_spawn_variance"), 0.2), 0.0),
		"ground_target_chance": clampf(ground_target_chance, 0.0, 1.0),
		"air_speed_min": maxf(_to_float_or(raw_segment.get("air_speed_min"), 120.0), 10.0),
		"air_speed_max": maxf(_to_float_or(raw_segment.get("air_speed_max"), 180.0), 10.0),
		"ground_speed_min": maxf(_to_float_or(raw_segment.get("ground_speed_min"), 90.0), 10.0),
		"ground_speed_max": maxf(_to_float_or(raw_segment.get("ground_speed_max"), 130.0), 10.0),
		"fuel_tank_interval": maxf(_to_float_or(raw_segment.get("fuel_tank_interval"), 6.0), 0.0),
		"fuel_tank_amount": maxf(_to_float_or(raw_segment.get("fuel_tank_amount"), 20.0), 0.0)
	}
	var terrain_profile := _normalize_terrain_profile(raw_segment.get("terrain_profile"))
	if not terrain_profile.is_empty():
		normalized["terrain_profile"] = terrain_profile
	var ceiling_profile := _normalize_ceiling_profile(raw_segment.get("ceiling_profile"))
	if not ceiling_profile.is_empty():
		normalized["ceiling_profile"] = ceiling_profile
	var sky_palette := _normalize_sky_palette(raw_segment.get("sky_palette"))
	if not sky_palette.is_empty():
		normalized["sky_palette"] = sky_palette
	var background_style := _normalize_background_style(raw_segment.get("background_style"))
	if not background_style.is_empty():
		normalized["background_style"] = background_style
	var enemy_style := _normalize_enemy_style(raw_segment.get("enemy_style"))
	if not enemy_style.is_empty():
		normalized["enemy_style"] = enemy_style
	return normalized

func _normalize_terrain_profile(raw_profile: Variant) -> Dictionary:
	return _normalize_profile(raw_profile, TERRAIN_BASE_MIN, TERRAIN_BASE_MAX)

func _normalize_ceiling_profile(raw_profile: Variant) -> Dictionary:
	return _normalize_profile(raw_profile, CEILING_BASE_MIN, CEILING_BASE_MAX)

func _normalize_profile(raw_profile: Variant, base_min: float, base_max: float) -> Dictionary:
	if typeof(raw_profile) != TYPE_DICTIONARY:
		return {}
	var profile: Dictionary = raw_profile
	var normalized: Dictionary = {}
	var base_value: Variant = profile.get("base")
	if typeof(base_value) == TYPE_FLOAT or typeof(base_value) == TYPE_INT:
		normalized["base"] = clampf(float(base_value), base_min, base_max)
	var amp_value: Variant = profile.get("amp")
	if typeof(amp_value) == TYPE_FLOAT or typeof(amp_value) == TYPE_INT:
		normalized["amp"] = clampf(float(amp_value), PROFILE_AMP_MIN, PROFILE_AMP_MAX)
	for key in ["freq_a", "freq_b", "freq_c", "weight_b", "weight_c", "jagged", "step"]:
		var value: Variant = profile.get(key)
		if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
			normalized[key] = float(value)
	var fill_value: Variant = profile.get("fill")
	if typeof(fill_value) == TYPE_COLOR:
		normalized["fill"] = fill_value
	var line_value: Variant = profile.get("line")
	if typeof(line_value) == TYPE_COLOR:
		normalized["line"] = line_value
	return normalized

func _normalize_sky_palette(raw_palette: Variant) -> Dictionary:
	if typeof(raw_palette) != TYPE_DICTIONARY:
		return {}
	var palette: Dictionary = raw_palette
	var normalized: Dictionary = {}
	for key in ["sky", "haze", "cloud", "far_hill", "mid_hill"]:
		var value: Variant = palette.get(key)
		if typeof(value) == TYPE_COLOR:
			normalized[key] = value
	return normalized

func _normalize_background_style(raw_style: Variant) -> Dictionary:
	if typeof(raw_style) != TYPE_DICTIONARY:
		return {}
	var style: Dictionary = raw_style
	var normalized: Dictionary = {}
	var mode_value: Variant = style.get("mode")
	if typeof(mode_value) == TYPE_STRING:
		normalized["mode"] = String(mode_value)
	for key in ["planet_scale", "star_density", "cloud_density", "stripe_density", "prop_density"]:
		var value: Variant = style.get(key)
		if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
			normalized[key] = float(value)
	for key in ["planet_a", "planet_b", "accent_a", "accent_b"]:
		var color_value: Variant = style.get(key)
		if typeof(color_value) == TYPE_COLOR:
			normalized[key] = color_value
	return normalized

func _normalize_enemy_style(raw_style: Variant) -> Dictionary:
	if typeof(raw_style) != TYPE_DICTIONARY:
		return {}
	var style: Dictionary = raw_style
	var normalized: Dictionary = {}
	for key in ["air_variant", "ground_variant"]:
		var value: Variant = style.get(key)
		if typeof(value) == TYPE_STRING:
			normalized[key] = String(value)
	for key in ["distant_flyby_chance", "distant_scale_min", "distant_scale_max"]:
		var n: Variant = style.get(key)
		if typeof(n) == TYPE_FLOAT or typeof(n) == TYPE_INT:
			normalized[key] = float(n)
	return normalized

func _to_float_or(value: Variant, fallback: float) -> float:
	var value_type := typeof(value)
	if value_type == TYPE_FLOAT or value_type == TYPE_INT:
		return float(value)
	return fallback
