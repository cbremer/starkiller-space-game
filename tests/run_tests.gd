extends SceneTree

const GameStateScript := preload("res://scripts/game_state.gd")
const StageSegmentSettingsScript := preload("res://scripts/stage_segment_settings.gd")

var _passes := 0
var _failures := 0

func _init() -> void:
	_run_all()
	print("")
	print("Result: %d passed, %d failed" % [_passes, _failures])
	quit(0 if _failures == 0 else 1)

func _run_all() -> void:
	_run_test("start_run initializes state", _test_start_run_initializes_state)
	_run_test("pause toggles only after run start", _test_pause_toggle_behavior)
	_run_test("fuel drain causes death", _test_fuel_drain_causes_death)
	_run_test("respawn triggers after cooldown when lives remain", _test_respawn_after_cooldown)
	_run_test("game over at zero lives does not respawn", _test_game_over_at_zero_lives)
	_run_test("fuel clamped to max", _test_fuel_clamped)
	_run_test("stage segment settings fallback to defaults", _test_stage_segment_settings_fallback_to_defaults)
	_run_test("stage segment settings normalize bad values", _test_stage_segment_settings_normalize_bad_values)
	_run_test("stage segment settings normalize palette overrides", _test_stage_segment_settings_normalize_palette_overrides)
	_run_test("scenario: full lifecycle to game over", _scenario_full_lifecycle_to_game_over)
	_run_test("scenario: pause freezes fuel drain and then resumes", _scenario_pause_freeze_and_resume)

func _run_test(name: String, body: Callable) -> void:
	var failures_before := _failures
	body.call()
	if _failures == failures_before:
		_passes += 1
		print("PASS: %s" % name)
	else:
		print("FAIL: %s" % name)

func _expect_true(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		printerr("  - %s" % message)

func _expect_eq(actual, expected, message: String) -> void:
	if actual != expected:
		_failures += 1
		printerr("  - %s (actual=%s expected=%s)" % [message, str(actual), str(expected)])

func _test_start_run_initializes_state() -> void:
	var state = GameStateScript.new()
	state.start_run()
	_expect_true(state.run_started, "run should be marked started")
	_expect_true(state.is_alive, "player should be alive after start")
	_expect_eq(state.lives, state.STARTING_LIVES, "lives should reset at run start")
	_expect_eq(state.fuel, state.MAX_FUEL, "fuel should reset at run start")
	_expect_eq(state.score, 0, "score should reset at run start")

func _test_pause_toggle_behavior() -> void:
	var state = GameStateScript.new()
	state.toggle_pause()
	_expect_true(not state.is_paused, "pause should do nothing before run starts")
	state.start_run()
	state.toggle_pause()
	_expect_true(state.is_paused, "pause should toggle on after start")
	state.toggle_pause()
	_expect_true(not state.is_paused, "pause should toggle off on second press")

func _test_fuel_drain_causes_death() -> void:
	var state = GameStateScript.new()
	state.start_run()
	state.drain_fuel(state.MAX_FUEL)
	_expect_true(not state.is_alive, "player should die when fuel reaches zero")
	_expect_eq(state.lives, state.STARTING_LIVES - 1, "death should consume one life")

func _test_respawn_after_cooldown() -> void:
	var state = GameStateScript.new()
	state.start_run()
	state.die()
	_expect_true(not state.is_alive, "player should be dead immediately after die()")
	state.update(state.respawn_cooldown + 0.01)
	_expect_true(state.is_alive, "player should respawn after cooldown when lives remain")
	_expect_eq(state.fuel, state.MAX_FUEL, "respawn should reset fuel to max")

func _test_game_over_at_zero_lives() -> void:
	var state = GameStateScript.new()
	state.start_run()
	state.lives = 1
	state.die()
	_expect_eq(state.lives, 0, "lives should reach zero on final death")
	state.update(state.respawn_cooldown + 0.01)
	_expect_true(not state.is_alive, "player should not respawn at zero lives")
	_expect_eq(state.status_text(), "Game Over", "status should report game over at zero lives")

func _test_fuel_clamped() -> void:
	var state = GameStateScript.new()
	state.start_run()
	state.add_fuel(9999.0)
	_expect_eq(state.fuel, state.MAX_FUEL, "fuel should not exceed max")

func _test_stage_segment_settings_fallback_to_defaults() -> void:
	var settings = StageSegmentSettingsScript.new()
	var empty_segments: Array[Dictionary] = []
	settings.segments = empty_segments
	var segments: Array = settings.normalized_segments_or_default()
	var defaults: Array = StageSegmentSettingsScript.default_segments()
	_expect_true(not segments.is_empty(), "fallback should produce default stage segments")
	_expect_eq(segments.size(), defaults.size(), "fallback should match default segment count")
	_expect_eq(String(segments[0]["segment_name"]), String(defaults[0]["segment_name"]), "fallback should keep default first segment")

func _test_stage_segment_settings_normalize_bad_values() -> void:
	var settings = StageSegmentSettingsScript.new()
	var malformed_segments: Array[Dictionary] = [{
		"segment_name": "Stress Segment",
		"length_px": -5.0,
		"enemy_spawn_interval": 0.0,
		"enemy_spawn_variance": -2.0,
		"ground_target_chance": 3.0,
		"air_speed_min": "invalid",
		"air_speed_max": 5.0,
		"ground_speed_min": -2.0,
		"ground_speed_max": 1.0,
		"fuel_tank_interval": -0.5,
		"fuel_tank_amount": -8.0
	}]
	settings.segments = malformed_segments
	var segments: Array = settings.normalized_segments()
	_expect_eq(segments.size(), 1, "normalization should keep valid dictionary entries")
	var segment: Dictionary = segments[0]
	_expect_eq(String(segment["segment_name"]), "Stress Segment", "segment name should be preserved")
	_expect_true(float(segment["length_px"]) >= 100.0, "length should clamp to a positive minimum")
	_expect_true(float(segment["enemy_spawn_interval"]) >= 0.1, "spawn interval should clamp to a safe minimum")
	_expect_true(float(segment["enemy_spawn_variance"]) >= 0.0, "spawn variance should not be negative")
	_expect_true(float(segment["ground_target_chance"]) <= 1.0 and float(segment["ground_target_chance"]) >= 0.0, "ground chance should clamp to [0,1]")
	_expect_true(float(segment["air_speed_min"]) >= 10.0, "air speed minimum should be sanitized")
	_expect_true(float(segment["air_speed_max"]) >= 10.0, "air speed maximum should be sanitized")
	_expect_true(float(segment["ground_speed_min"]) >= 10.0, "ground speed minimum should be sanitized")
	_expect_true(float(segment["ground_speed_max"]) >= 10.0, "ground speed maximum should be sanitized")
	_expect_eq(float(segment["fuel_tank_interval"]), 0.0, "fuel tank interval should clamp to zero minimum")
	_expect_eq(float(segment["fuel_tank_amount"]), 0.0, "fuel amount should clamp to zero minimum")

func _test_stage_segment_settings_normalize_palette_overrides() -> void:
	var settings = StageSegmentSettingsScript.new()
	var custom_segments: Array[Dictionary] = [{
		"segment_name": "Palette Segment",
		"terrain_profile": {
			"base": 0.4,
			"amp": "bad",
			"fill": "nope",
			"line": Color(0.5, 0.6, 0.7)
		},
		"ceiling_profile": {
			"base": 0.5,
			"amp": 2000.0,
			"fill": Color(0.2, 0.2, 0.2)
		},
		"sky_palette": {
			"sky": Color(0.1, 0.2, 0.3),
			"cloud": "bad"
		}
	}]
	settings.segments = custom_segments
	var segments: Array = settings.normalized_segments()
	_expect_eq(segments.size(), 1, "palette normalization should keep segment")
	var segment: Dictionary = segments[0]
	var terrain_profile: Dictionary = segment.get("terrain_profile", {})
	_expect_true(terrain_profile.has("base"), "terrain profile base should be preserved")
	_expect_true(float(terrain_profile.get("base", 0.0)) >= 0.62, "terrain base should clamp to minimum")
	_expect_true(not terrain_profile.has("amp"), "invalid terrain amp should be ignored")
	_expect_true(not terrain_profile.has("fill"), "invalid terrain fill should be ignored")
	_expect_true(terrain_profile.has("line"), "valid terrain line should be kept")
	var ceiling_profile: Dictionary = segment.get("ceiling_profile", {})
	_expect_true(float(ceiling_profile.get("base", 1.0)) <= 0.35, "ceiling base should clamp to maximum")
	_expect_true(float(ceiling_profile.get("amp", 0.0)) <= 120.0, "ceiling amp should clamp to maximum")
	var sky_palette: Dictionary = segment.get("sky_palette", {})
	_expect_true(sky_palette.has("sky"), "sky palette should keep valid sky color")
	_expect_true(not sky_palette.has("cloud"), "invalid sky palette color should be ignored")

func _scenario_full_lifecycle_to_game_over() -> void:
	var state = GameStateScript.new()
	state.start_run()
	_expect_eq(state.status_text(), "Alive", "status should be alive after start")

	state.drain_fuel(state.MAX_FUEL)
	_expect_true(not state.is_alive, "state should transition to dead when fuel depletes")
	_expect_true(state.status_text().begins_with("Respawning in"), "status should report respawn timer")

	state.update(state.respawn_cooldown + 0.01)
	_expect_true(state.is_alive, "state should respawn while lives remain")
	_expect_eq(state.status_text(), "Alive", "status should return to alive after respawn")

	state.lives = 1
	state.die()
	state.update(state.respawn_cooldown + 0.01)
	_expect_true(not state.is_alive, "state should stay dead after final life is consumed")
	_expect_eq(state.status_text(), "Game Over", "status should report game over after final death")

func _scenario_pause_freeze_and_resume() -> void:
	var state = GameStateScript.new()
	state.start_run()
	var fuel_before_pause: float = state.fuel
	state.toggle_pause()
	_expect_true(state.is_paused, "pause should be enabled")

	state.drain_fuel(25.0)
	state.update(2.0)
	_expect_eq(state.fuel, fuel_before_pause, "fuel should not drain while paused")
	_expect_true(state.is_alive, "player should remain alive while paused")

	state.toggle_pause()
	_expect_true(not state.is_paused, "pause should disable on second toggle")
	state.drain_fuel(25.0)
	_expect_true(state.fuel < fuel_before_pause, "fuel should drain again after unpausing")
