extends Node2D

const FUEL_DRAIN_PER_SECOND := 9.0
const REFUEL_PER_SECOND := 32.0
const REFUEL_RECT := Rect2(Vector2(15, 170), Vector2(130, 260))
const BOLT_SPAWN_OFFSET := Vector2(22, 0)
const BOMB_DROP_OFFSET := Vector2(8, 12)
const STAGE_SCROLL_SPEED := 190.0
const ENEMY_SPAWN_X := 1060.0
const ENEMY_AIR_Y_MIN := 130.0
const ENEMY_AIR_Y_MAX := 440.0
const ENEMY_GROUND_Y := 548.0
const FUEL_TANK_SPAWN_X := 1060.0
const FUEL_TANK_Y_MIN := 190.0
const FUEL_TANK_Y_MAX := 460.0
const PLAYER_HIT_RADIUS := 16.0
const PLAYER_TERRAIN_CLEARANCE := 12.0
const PLAYER_CEILING_CLEARANCE := 10.0
const TUNNEL_SPAWN_MARGIN := 40.0
const GAME_STATE_SCRIPT := preload("res://scripts/game_state.gd")
const LASER_BOLT_SCRIPT := preload("res://scripts/laser_bolt.gd")
const BOMB_PAYLOAD_SCRIPT := preload("res://scripts/bomb_payload.gd")
const ENEMY_TARGET_SCRIPT := preload("res://scripts/enemy_target.gd")
const FUEL_TANK_SCRIPT := preload("res://scripts/fuel_tank.gd")
const PARALLAX_BACKGROUND_SCRIPT := preload("res://scripts/parallax_background.gd")
const TERRAIN_BAND_SCRIPT := preload("res://scripts/terrain_band.gd")
const CEILING_BAND_SCRIPT := preload("res://scripts/ceiling_band.gd")

@onready var player: Node2D = $PlayerShip
@onready var state_label: Label = $CanvasLayer/HUD/StateLabel
@onready var input_label: Label = $CanvasLayer/HUD/InputLabel
@onready var action_label: Label = $CanvasLayer/HUD/ActionLabel
@onready var info_label: Label = $CanvasLayer/HUD/InfoLabel

var game_state = GAME_STATE_SCRIPT.new()
var last_action_text := "No actions yet"
var enemy_spawn_remaining := 1.0
var fuel_tank_spawn_remaining := 0.0
var stage_segments: Array = []
var current_segment_index := 0
var segment_distance_remaining := 0.0
var run_distance := 0.0
var rng := RandomNumberGenerator.new()
var background_layer = null
var ceiling_layer = null
var terrain_layer = null

func _ready() -> void:
	rng.randomize()
	_create_world_layers()
	_build_stage_segments()
	game_state.changed.connect(_update_hud)
	game_state.action_triggered.connect(_on_action_triggered)
	game_state.player_respawned.connect(_on_respawned)
	_update_hud()
	info_label.text = "Enter=start, Esc=pause, Z=fire, X=drop bomb, R=manual refuel"

func _process(delta: float) -> void:
	_update_info_label()

	if Input.is_action_just_pressed("start"):
		game_state.start_run()
		player.position = Vector2(120, 320)
		_clear_combat_nodes()
		_reset_run_progression()
		enemy_spawn_remaining = 0.35

	if Input.is_action_just_pressed("pause"):
		game_state.toggle_pause()

	if game_state.run_started and game_state.is_alive and not game_state.is_paused:
		_update_stage_progress(delta)
		_update_enemy_spawns(delta)
		_update_fuel_tank_spawns(delta)
		if Input.is_action_just_pressed("fire"):
			game_state.register_action("Fire")
			_spawn_bolt()
		if Input.is_action_just_pressed("bomb"):
			_try_trigger_bomb()

		game_state.drain_fuel(FUEL_DRAIN_PER_SECOND * delta)

		if Input.is_action_pressed("refuel"):
			game_state.add_fuel(REFUEL_PER_SECOND * delta)

		if REFUEL_RECT.has_point(player.position):
			game_state.add_fuel(REFUEL_PER_SECOND * delta)

	_update_combat_state()
	game_state.update(delta)
	_update_world_layers()
	player.visible = game_state.is_alive
	player.set_physics_process(game_state.run_started and game_state.is_alive and not game_state.is_paused)
	_set_actor_activity(game_state.run_started and game_state.is_alive and not game_state.is_paused)
	_update_input_debug()

func _on_action_triggered(action_name: String) -> void:
	last_action_text = "%s @ %.2fs" % [action_name, Time.get_ticks_msec() / 1000.0]
	action_label.text = "Last Action: %s" % last_action_text

func _spawn_bolt() -> void:
	var bolt := LASER_BOLT_SCRIPT.new()
	bolt.position = player.position + BOLT_SPAWN_OFFSET
	add_child(bolt)

func _spawn_enemy() -> void:
	var segment = _current_segment()
	var enemy := ENEMY_TARGET_SCRIPT.new()
	var spawn_ground := rng.randf() <= float(segment["ground_target_chance"])
	var ground_spawn_y := _terrain_height_at(ENEMY_SPAWN_X) - 12.0
	if spawn_ground:
		enemy.position = Vector2(ENEMY_SPAWN_X, ground_spawn_y)
		enemy.set("speed", rng.randf_range(float(segment["ground_speed_min"]), float(segment["ground_speed_max"])))
		enemy.set("target_type", "ground")
	else:
		var tunnel_top := _ceiling_height_at(ENEMY_SPAWN_X) + TUNNEL_SPAWN_MARGIN
		var tunnel_bottom := _terrain_height_at(ENEMY_SPAWN_X) - TUNNEL_SPAWN_MARGIN
		var air_min := maxf(ENEMY_AIR_Y_MIN, tunnel_top)
		var air_max := minf(ENEMY_AIR_Y_MAX, tunnel_bottom)
		if air_max <= air_min:
			air_max = air_min + 8.0
		enemy.position = Vector2(ENEMY_SPAWN_X, rng.randf_range(air_min, air_max))
		enemy.set("speed", rng.randf_range(float(segment["air_speed_min"]), float(segment["air_speed_max"])))
		enemy.set("target_type", "air")
	add_child(enemy)

func _update_enemy_spawns(delta: float) -> void:
	var segment = _current_segment()
	enemy_spawn_remaining = maxf(0.0, enemy_spawn_remaining - delta)
	if enemy_spawn_remaining <= 0.0:
		_spawn_enemy()
		enemy_spawn_remaining = float(segment["enemy_spawn_interval"]) + rng.randf_range(
			-float(segment["enemy_spawn_variance"]),
			float(segment["enemy_spawn_variance"])
		)

func _try_trigger_bomb() -> void:
	game_state.register_action("Bomb")
	_drop_bomb()

func _drop_bomb() -> void:
	var payload := BOMB_PAYLOAD_SCRIPT.new()
	payload.position = player.position + BOMB_DROP_OFFSET
	add_child(payload)

func _spawn_fuel_tank() -> void:
	var tank := FUEL_TANK_SCRIPT.new()
	var terrain_y := _terrain_height_at(FUEL_TANK_SPAWN_X)
	var ceiling_y := _ceiling_height_at(FUEL_TANK_SPAWN_X)
	var y_min := maxf(FUEL_TANK_Y_MIN, ceiling_y + 55.0)
	var y_max := minf(FUEL_TANK_Y_MAX, terrain_y - 58.0)
	if y_max <= y_min:
		y_max = y_min + 8.0
	tank.position = Vector2(FUEL_TANK_SPAWN_X, rng.randf_range(y_min, y_max))
	var segment = _current_segment()
	tank.set("fuel_amount", float(segment["fuel_tank_amount"]))
	add_child(tank)

func _update_fuel_tank_spawns(delta: float) -> void:
	var segment = _current_segment()
	var tank_interval := float(segment["fuel_tank_interval"])
	if tank_interval <= 0.0:
		return
	fuel_tank_spawn_remaining = maxf(0.0, fuel_tank_spawn_remaining - delta)
	if fuel_tank_spawn_remaining <= 0.0:
		_spawn_fuel_tank()
		fuel_tank_spawn_remaining = tank_interval

func _update_combat_state() -> void:
	if not game_state.run_started or not game_state.is_alive or game_state.is_paused:
		return

	var enemy_nodes := get_tree().get_nodes_in_group("enemy_targets")
	var bolt_nodes := get_tree().get_nodes_in_group("laser_bolts")
	var bomb_nodes := get_tree().get_nodes_in_group("bomb_payloads")
	var fuel_tank_nodes := get_tree().get_nodes_in_group("fuel_tanks")
	var ceiling_height := _ceiling_height_at(player.position.x)
	var terrain_height := _terrain_height_at(player.position.x)

	if player.position.y - PLAYER_CEILING_CLEARANCE <= ceiling_height:
		game_state.die()
		last_action_text = "Crashed into ceiling"
		action_label.text = "Last Action: %s" % last_action_text
		return

	if player.position.y + PLAYER_TERRAIN_CLEARANCE >= terrain_height:
		game_state.die()
		last_action_text = "Crashed into terrain"
		action_label.text = "Last Action: %s" % last_action_text
		return

	for enemy_node in enemy_nodes:
		if enemy_node == null or not enemy_node.has_method("apply_hit"):
			continue

		var enemy_type := String(enemy_node.get("target_type"))
		var enemy_hit_radius := float(enemy_node.get("hit_radius"))

		if enemy_type == "air" and enemy_node.position.distance_to(player.position) <= (enemy_hit_radius + PLAYER_HIT_RADIUS):
			enemy_node.apply_hit("ship")
			game_state.die()
			last_action_text = "Ship hit by enemy"
			action_label.text = "Last Action: %s" % last_action_text
			return

		if enemy_type == "air":
			for bolt_node in bolt_nodes:
				if bolt_node == null:
					continue
				var bolt_hit_radius := float(bolt_node.get("hit_radius"))
				if bolt_node.position.distance_to(enemy_node.position) <= (bolt_hit_radius + enemy_hit_radius):
					var air_points := int(enemy_node.apply_hit("laser"))
					if air_points > 0:
						game_state.add_score(air_points)
						last_action_text = "Air target destroyed"
						action_label.text = "Last Action: %s" % last_action_text
					bolt_node.queue_free()
					break

		if enemy_type == "ground":
			for bomb_node in bomb_nodes:
				if bomb_node == null:
					continue
				var bomb_hit_radius := float(bomb_node.get("hit_radius"))
				if bomb_node.position.distance_to(enemy_node.position) <= (bomb_hit_radius + enemy_hit_radius):
					var ground_points := int(enemy_node.apply_hit("bomb"))
					if ground_points > 0:
						game_state.add_score(ground_points)
						last_action_text = "Ground target bombed"
						action_label.text = "Last Action: %s" % last_action_text
					bomb_node.queue_free()
					break

	for fuel_tank_node in fuel_tank_nodes:
		if fuel_tank_node == null:
			continue
		var tank_radius := float(fuel_tank_node.get("hit_radius"))
		if fuel_tank_node.position.distance_to(player.position) <= (tank_radius + PLAYER_HIT_RADIUS):
			var fuel_gain := float(fuel_tank_node.get("fuel_amount"))
			game_state.add_fuel(fuel_gain)
			last_action_text = "Fuel tank collected (+%d)" % int(fuel_gain)
			action_label.text = "Last Action: %s" % last_action_text
			fuel_tank_node.queue_free()

func _set_actor_activity(is_active: bool) -> void:
	for bolt_node in get_tree().get_nodes_in_group("laser_bolts"):
		if bolt_node != null:
			bolt_node.set("is_active", is_active)
	for bomb_node in get_tree().get_nodes_in_group("bomb_payloads"):
		if bomb_node != null:
			bomb_node.set("is_active", is_active)
	for fuel_tank_node in get_tree().get_nodes_in_group("fuel_tanks"):
		if fuel_tank_node != null:
			fuel_tank_node.set("is_active", is_active)
	for enemy_node in get_tree().get_nodes_in_group("enemy_targets"):
		if enemy_node != null:
			enemy_node.set("is_active", is_active)

func _clear_combat_nodes() -> void:
	for bolt_node in get_tree().get_nodes_in_group("laser_bolts"):
		bolt_node.queue_free()
	for bomb_node in get_tree().get_nodes_in_group("bomb_payloads"):
		bomb_node.queue_free()
	for fuel_tank_node in get_tree().get_nodes_in_group("fuel_tanks"):
		fuel_tank_node.queue_free()
	for enemy_node in get_tree().get_nodes_in_group("enemy_targets"):
		enemy_node.queue_free()

func _create_world_layers() -> void:
	if background_layer == null:
		background_layer = PARALLAX_BACKGROUND_SCRIPT.new()
		add_child(background_layer)
		move_child(background_layer, 0)
	if ceiling_layer == null:
		ceiling_layer = CEILING_BAND_SCRIPT.new()
		add_child(ceiling_layer)
		move_child(ceiling_layer, 1)
	if terrain_layer == null:
		terrain_layer = TERRAIN_BAND_SCRIPT.new()
		add_child(terrain_layer)
		move_child(terrain_layer, 2)
	_update_world_layers()

func _update_world_layers() -> void:
	if background_layer != null:
		background_layer.call("set_scroll_distance", run_distance)
		background_layer.call("set_segment_index", current_segment_index)
	if ceiling_layer != null:
		ceiling_layer.call("set_scroll_distance", run_distance)
		ceiling_layer.call("set_segment_index", current_segment_index)
	if terrain_layer != null:
		terrain_layer.call("set_scroll_distance", run_distance)
		terrain_layer.call("set_segment_index", current_segment_index)

func _ceiling_height_at(screen_x: float) -> float:
	if ceiling_layer != null and ceiling_layer.has_method("ceiling_height_at_screen_x"):
		return float(ceiling_layer.call("ceiling_height_at_screen_x", screen_x))
	return 80.0

func _terrain_height_at(screen_x: float) -> float:
	if terrain_layer != null and terrain_layer.has_method("ground_height_at_screen_x"):
		return float(terrain_layer.call("ground_height_at_screen_x", screen_x))
	return ENEMY_GROUND_Y

func _build_stage_segments() -> void:
	stage_segments = [
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
			"fuel_tank_amount": 24.0
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
			"fuel_tank_amount": 22.0
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
			"fuel_tank_amount": 20.0
		}
	]

func _reset_run_progression() -> void:
	current_segment_index = 0
	run_distance = 0.0
	var segment = _current_segment()
	segment_distance_remaining = float(segment["length_px"])
	enemy_spawn_remaining = float(segment["enemy_spawn_interval"])
	fuel_tank_spawn_remaining = float(segment["fuel_tank_interval"])
	game_state.set_stage(1)
	last_action_text = "Entered %s" % String(segment["segment_name"])
	action_label.text = "Last Action: %s" % last_action_text

func _current_segment():
	if stage_segments.is_empty():
		_build_stage_segments()
	return stage_segments[min(current_segment_index, stage_segments.size() - 1)]

func _update_stage_progress(delta: float) -> void:
	var progress := STAGE_SCROLL_SPEED * delta
	run_distance += progress
	segment_distance_remaining = maxf(0.0, segment_distance_remaining - progress)
	if segment_distance_remaining <= 0.0:
		_advance_segment()

func _advance_segment() -> void:
	current_segment_index = min(current_segment_index + 1, stage_segments.size() - 1)
	var segment = _current_segment()
	segment_distance_remaining = float(segment["length_px"])
	enemy_spawn_remaining = minf(enemy_spawn_remaining, float(segment["enemy_spawn_interval"]))
	fuel_tank_spawn_remaining = minf(fuel_tank_spawn_remaining, float(segment["fuel_tank_interval"]))
	game_state.set_stage(current_segment_index + 1)
	last_action_text = "Entered %s" % String(segment["segment_name"])
	action_label.text = "Last Action: %s" % last_action_text

func _on_respawned() -> void:
	player.position = Vector2(120, 320)
	last_action_text = "Respawned"

func _update_hud() -> void:
	state_label.text = "Score: %d  Lives: %d  Fuel: %03.1f  Stage: %d\nPaused: %s  Status: %s" % [
		game_state.score,
		max(game_state.lives, 0),
		game_state.fuel,
		game_state.stage_id,
		str(game_state.is_paused),
		game_state.status_text()
	]
	action_label.text = "Last Action: %s" % last_action_text
	_update_info_label()

func _update_info_label() -> void:
	var segment = _current_segment()
	info_label.text = "Stage %d - %s | Enter=start, Esc=pause, Z=fire (air), X=drop bomb (ground), R=manual refuel" % [
		game_state.stage_id,
		String(segment["segment_name"])
	]

func _update_input_debug() -> void:
	var pressed_actions: Array[String] = []
	for action in ["move_up", "move_down", "move_left", "move_right", "fire", "bomb", "start", "pause"]:
		if Input.is_action_pressed(action):
			pressed_actions.append(action)
	var pressed_text := "none" if pressed_actions.is_empty() else ", ".join(pressed_actions)
	input_label.text = "Pressed: %s" % pressed_text
