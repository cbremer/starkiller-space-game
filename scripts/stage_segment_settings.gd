extends Resource
class_name StageSegmentSettings

const DEFAULT_TERRAIN_PROFILE := {
	"base": 0.84,
	"amp": 18.0,
	"fill": Color(0.18, 0.23, 0.16),
	"line": Color(0.30, 0.42, 0.24)
}
const DEFAULT_CEILING_PROFILE := {
	"base": 0.16,
	"amp": 18.0,
	"fill": Color(0.14, 0.17, 0.13),
	"line": Color(0.27, 0.35, 0.24)
}
const DEFAULT_SKY_PALETTE := {
	"sky": Color(0.39, 0.62, 0.84),
	"haze": Color(0.53, 0.69, 0.78, 0.8),
	"cloud": Color(0.92, 0.95, 1.0, 0.45),
	"far_hill": Color(0.22, 0.40, 0.48),
	"mid_hill": Color(0.15, 0.32, 0.38)
}
const DEFAULT_SEGMENTS: Array[Dictionary] = [
	{
		"segment_name": "Sector 1: Open Sky",
		"length_px": 2400.0,
		"enemy_spawn_interval": 1.15,
		"enemy_spawn_variance": 0.20,
		"ground_target_chance": 0.30,
		"air_speed_min": 120.0,
		"air_speed_max": 185.0,
		"ground_speed_min": 90.0,
		"ground_speed_max": 125.0,
		"fuel_tank_interval": 7.0,
		"fuel_tank_amount": 24.0,
		"terrain_profile": DEFAULT_TERRAIN_PROFILE,
		"ceiling_profile": DEFAULT_CEILING_PROFILE,
		"sky_palette": DEFAULT_SKY_PALETTE
	},
	{
		"segment_name": "Sector 2: Canyon",
		"length_px": 2600.0,
		"enemy_spawn_interval": 0.95,
		"enemy_spawn_variance": 0.22,
		"ground_target_chance": 0.45,
		"air_speed_min": 135.0,
		"air_speed_max": 205.0,
		"ground_speed_min": 100.0,
		"ground_speed_max": 140.0,
		"fuel_tank_interval": 5.5,
		"fuel_tank_amount": 22.0,
		"terrain_profile": {
			"base": 0.82,
			"amp": 30.0,
			"fill": Color(0.25, 0.20, 0.14),
			"line": Color(0.45, 0.36, 0.23)
		},
		"ceiling_profile": {
			"base": 0.17,
			"amp": 26.0,
			"fill": Color(0.21, 0.17, 0.12),
			"line": Color(0.39, 0.31, 0.20)
		},
		"sky_palette": {
			"sky": Color(0.47, 0.56, 0.70),
			"haze": Color(0.60, 0.58, 0.50, 0.75),
			"cloud": Color(0.88, 0.84, 0.77, 0.38),
			"far_hill": Color(0.36, 0.33, 0.28),
			"mid_hill": Color(0.29, 0.24, 0.18)
		}
	},
	{
		"segment_name": "Sector 3: Fortress Run",
		"length_px": 3000.0,
		"enemy_spawn_interval": 0.82,
		"enemy_spawn_variance": 0.18,
		"ground_target_chance": 0.55,
		"air_speed_min": 150.0,
		"air_speed_max": 220.0,
		"ground_speed_min": 110.0,
		"ground_speed_max": 150.0,
		"fuel_tank_interval": 4.8,
		"fuel_tank_amount": 20.0,
		"terrain_profile": {
			"base": 0.80,
			"amp": 38.0,
			"fill": Color(0.20, 0.16, 0.22),
			"line": Color(0.36, 0.28, 0.44)
		},
		"ceiling_profile": {
			"base": 0.18,
			"amp": 34.0,
			"fill": Color(0.17, 0.13, 0.21),
			"line": Color(0.31, 0.24, 0.40)
		},
		"sky_palette": {
			"sky": Color(0.30, 0.35, 0.50),
			"haze": Color(0.41, 0.38, 0.45, 0.72),
			"cloud": Color(0.74, 0.72, 0.88, 0.34),
			"far_hill": Color(0.22, 0.19, 0.30),
			"mid_hill": Color(0.16, 0.13, 0.22)
		}
	}
]

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
	return {
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
		"fuel_tank_amount": maxf(_to_float_or(raw_segment.get("fuel_tank_amount"), 20.0), 0.0),
		"terrain_profile": _normalize_profile(raw_segment.get("terrain_profile", {}), DEFAULT_TERRAIN_PROFILE),
		"ceiling_profile": _normalize_profile(raw_segment.get("ceiling_profile", {}), DEFAULT_CEILING_PROFILE),
		"sky_palette": _normalize_palette(raw_segment.get("sky_palette", {}), DEFAULT_SKY_PALETTE)
	}

func _normalize_profile(raw_profile: Dictionary, fallback: Dictionary) -> Dictionary:
	var normalized := fallback.duplicate(true)
	if typeof(raw_profile) != TYPE_DICTIONARY:
		return normalized
	for key in raw_profile.keys():
		normalized[key] = raw_profile[key]
	return normalized

func _normalize_palette(raw_palette: Dictionary, fallback: Dictionary) -> Dictionary:
	var normalized := fallback.duplicate(true)
	if typeof(raw_palette) != TYPE_DICTIONARY:
		return normalized
	for key in raw_palette.keys():
		normalized[key] = raw_palette[key]
	return normalized

func _to_float_or(value: Variant, fallback: float) -> float:
	var value_type := typeof(value)
	if value_type == TYPE_FLOAT or value_type == TYPE_INT:
		return float(value)
	return fallback
