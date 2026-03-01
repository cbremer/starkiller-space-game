extends Node2D

const FUEL_DRAIN_PER_SECOND := 9.0
const REFUEL_PER_SECOND := 32.0
const REFUEL_RECT := Rect2(Vector2(15, 170), Vector2(130, 260))
const BOLT_SPAWN_OFFSET := Vector2(22, 0)
const BOMB_DROP_OFFSET := Vector2(8, 12)
const STAGE_SCROLL_SPEED := 190.0
const ENEMY_AIR_Y_MIN := 130.0
const ENEMY_AIR_Y_MAX := 440.0
const ENEMY_GROUND_Y := 548.0
const SPAWN_MARGIN_X := 36.0
const FUEL_TANK_Y_MIN := 190.0
const FUEL_TANK_Y_MAX := 460.0
const PLAYER_HIT_RADIUS := 16.0
const PLAYER_TERRAIN_CLEARANCE := 12.0
const PLAYER_CEILING_CLEARANCE := 10.0
const TUNNEL_SPAWN_MARGIN := 40.0
const GAME_STATE_SCRIPT := preload("res://scripts/game_state.gd")
const LASER_BOLT_SCRIPT := preload("res://scripts/laser_bolt.gd")
const BOMB_PAYLOAD_SCRIPT := preload("res://scripts/bomb_payload.gd")
const BOMB_BLAST_SCRIPT := preload("res://scripts/bomb_blast.gd")
const ENEMY_TARGET_SCRIPT := preload("res://scripts/enemy_target.gd")
const FUEL_TANK_SCRIPT := preload("res://scripts/fuel_tank.gd")
const PARALLAX_BACKGROUND_SCRIPT := preload("res://scripts/parallax_background.gd")
const TERRAIN_BAND_SCRIPT := preload("res://scripts/terrain_band.gd")
const CEILING_BAND_SCRIPT := preload("res://scripts/ceiling_band.gd")
const BOMB_GROUND_BLAST_RADIUS := 92.0
const REMAP_ACTIONS: Array[String] = [
	"move_up",
	"move_down",
	"move_left",
	"move_right",
	"fire",
	"bomb",
	"start",
	"pause"
]
const ACTION_LABELS := {
	"move_up": "Move Up",
	"move_down": "Move Down",
	"move_left": "Move Left",
	"move_right": "Move Right",
	"fire": "Fire",
	"bomb": "Bomb",
	"start": "Start / Retry",
	"pause": "Pause / Resume"
}
const DEFAULT_KEY_BINDINGS := {
	"move_up": KEY_UP,
	"move_down": KEY_DOWN,
	"move_left": KEY_LEFT,
	"move_right": KEY_RIGHT,
	"fire": KEY_Z,
	"bomb": KEY_X,
	"start": KEY_ENTER,
	"pause": KEY_ESCAPE
}
const INPUT_BINDINGS_SETTINGS_PATH := "user://settings.cfg"
const INPUT_BINDINGS_SECTION := "input_bindings"

@onready var player: Node2D = $PlayerShip
@onready var state_label: Label = $CanvasLayer/HUD/StateLabel
@onready var input_label: Label = $CanvasLayer/HUD/InputLabel
@onready var action_label: Label = $CanvasLayer/HUD/ActionLabel
@onready var info_label: Label = $CanvasLayer/HUD/InfoLabel
@onready var pause_menu: PanelContainer = $CanvasLayer/PauseMenu
@onready var pause_options_label: Label = $CanvasLayer/PauseMenu/VBox/PauseOptions
@onready var remap_panel: PanelContainer = $CanvasLayer/RemapPanel
@onready var remap_status_label: Label = $CanvasLayer/RemapPanel/VBox/RemapStatus
@onready var remap_list_label: Label = $CanvasLayer/RemapPanel/VBox/RemapList

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
var remap_selected_index := 0
var is_remap_menu_open := false
var awaiting_rebind := false
var remap_status_text := "Use Up/Down to pick an action, Enter to rebind."
var _suppress_pause_this_frame := false

func _ready() -> void:
	rng.randomize()
	_create_world_layers()
	_build_stage_segments()
	_ensure_fullscreen_input_action()
	_load_input_bindings()
	game_state.changed.connect(_update_hud)
	game_state.action_triggered.connect(_on_action_triggered)
	game_state.player_respawned.connect(_on_respawned)
	_update_hud()
	_set_pause_ui_visibility()
	_update_pause_menu()
	_update_remap_panel()

func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	_handle_key_event(key_event)

func _handle_key_event(event: InputEventKey) -> void:
	if awaiting_rebind:
		if event.keycode == KEY_ESCAPE:
			awaiting_rebind = false
			remap_status_text = "Rebind canceled."
			_suppress_pause_this_frame = true
		else:
			_rebind_action(_selected_remap_action(), event)
			awaiting_rebind = false
		_update_remap_panel()
		_consume_input_event()
		return

	if event.keycode == KEY_F11:
		_toggle_fullscreen()
		_consume_input_event()
		return

	if not game_state.run_started or not game_state.is_paused:
		return

	match event.keycode:
		KEY_1:
			game_state.toggle_pause()
			_set_pause_ui_visibility()
			_update_pause_menu()
			_consume_input_event()
		KEY_2:
			_start_run()
			last_action_text = "Run restarted from pause menu"
			action_label.text = "Last Action: %s" % last_action_text
			_consume_input_event()
		KEY_3:
			_toggle_fullscreen()
			_consume_input_event()
		KEY_4:
			is_remap_menu_open = not is_remap_menu_open
			awaiting_rebind = false
			remap_status_text = "Use Up/Down to pick an action, Enter to rebind."
			_set_pause_ui_visibility()
			_update_remap_panel()
			_consume_input_event()
		KEY_UP:
			if is_remap_menu_open:
				remap_selected_index = wrapi(remap_selected_index - 1, 0, REMAP_ACTIONS.size())
				_update_remap_panel()
				_consume_input_event()
		KEY_DOWN:
			if is_remap_menu_open:
				remap_selected_index = wrapi(remap_selected_index + 1, 0, REMAP_ACTIONS.size())
				_update_remap_panel()
				_consume_input_event()
		KEY_ENTER, KEY_KP_ENTER:
			if is_remap_menu_open:
				awaiting_rebind = true
				remap_status_text = "Press a key for %s (Esc to cancel)." % _action_label(_selected_remap_action())
				_update_remap_panel()
				_consume_input_event()
		KEY_BACKSPACE:
			if is_remap_menu_open:
				_reset_action_binding(_selected_remap_action())
				_update_remap_panel()
				_consume_input_event()

func _process(delta: float) -> void:
	_update_info_label()

	if Input.is_action_just_pressed("start"):
		if not game_state.run_started:
			_start_run()
		elif game_state.is_paused and not is_remap_menu_open and not awaiting_rebind:
			_start_run()

	if Input.is_action_just_pressed("pause"):
		if _suppress_pause_this_frame:
			_suppress_pause_this_frame = false
		elif awaiting_rebind:
			awaiting_rebind = false
			remap_status_text = "Rebind canceled."
			_update_remap_panel()
		elif game_state.run_started:
			if game_state.is_paused and is_remap_menu_open:
				is_remap_menu_open = false
				_set_pause_ui_visibility()
				_update_remap_panel()
			else:
				game_state.toggle_pause()

	if Input.is_action_just_pressed("toggle_fullscreen"):
		_toggle_fullscreen()

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

func _start_run() -> void:
	game_state.start_run()
	player.position = Vector2(120, 320)
	_clear_combat_nodes()
	_reset_run_progression()
	enemy_spawn_remaining = 0.35
	is_remap_menu_open = false
	awaiting_rebind = false
	remap_status_text = "Use Up/Down to pick an action, Enter to rebind."
	_set_pause_ui_visibility()
	_update_pause_menu()
	_update_remap_panel()

func _on_action_triggered(action_name: String) -> void:
	last_action_text = "%s @ %.2fs" % [action_name, Time.get_ticks_msec() / 1000.0]
	action_label.text = "Last Action: %s" % last_action_text

func _spawn_bolt() -> void:
	var bolt := LASER_BOLT_SCRIPT.new()
	bolt.position = player.position + BOLT_SPAWN_OFFSET
	add_child(bolt)

func _spawn_enemy() -> void:
	var segment = _current_segment()
	var spawn_x := _spawn_x()
	var enemy := ENEMY_TARGET_SCRIPT.new()
	var spawn_ground := rng.randf() <= float(segment["ground_target_chance"])
	var ground_spawn_y := _terrain_height_at(spawn_x) - 12.0
	if spawn_ground:
		enemy.position = Vector2(spawn_x, ground_spawn_y)
		enemy.set("speed", rng.randf_range(float(segment["ground_speed_min"]), float(segment["ground_speed_max"])))
		enemy.set("target_type", "ground")
	else:
		var tunnel_top := _ceiling_height_at(spawn_x) + TUNNEL_SPAWN_MARGIN
		var tunnel_bottom := _terrain_height_at(spawn_x) - TUNNEL_SPAWN_MARGIN
		var air_min := maxf(ENEMY_AIR_Y_MIN, tunnel_top)
		var air_max := minf(ENEMY_AIR_Y_MAX, tunnel_bottom)
		if air_max <= air_min:
			air_max = air_min + 8.0
		enemy.position = Vector2(spawn_x, rng.randf_range(air_min, air_max))
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
	var spawn_x := _spawn_x()
	var tank := FUEL_TANK_SCRIPT.new()
	var terrain_y := _terrain_height_at(spawn_x)
	var ceiling_y := _ceiling_height_at(spawn_x)
	var y_min := maxf(FUEL_TANK_Y_MIN, ceiling_y + 55.0)
	var y_max := minf(FUEL_TANK_Y_MAX, terrain_y - 58.0)
	if y_max <= y_min:
		y_max = y_min + 8.0
	tank.position = Vector2(spawn_x, rng.randf_range(y_min, y_max))
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
		if enemy_node == null or enemy_node.is_queued_for_deletion() or not enemy_node.has_method("apply_hit"):
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
				if bolt_node == null or bolt_node.is_queued_for_deletion():
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

		for bomb_node in bomb_nodes:
			if bomb_node == null or bomb_node.is_queued_for_deletion():
				continue
			var bomb_hit_radius := float(bomb_node.get("hit_radius"))
			if bomb_node.position.distance_to(enemy_node.position) <= (bomb_hit_radius + enemy_hit_radius):
				var bomb_points := int(enemy_node.apply_hit("bomb"))
				if bomb_points > 0:
					game_state.add_score(bomb_points)
					last_action_text = "Target bombed"
					action_label.text = "Last Action: %s" % last_action_text
				bomb_node.queue_free()
				break

	_process_bomb_ground_impacts(enemy_nodes, bomb_nodes)

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

func _process_bomb_ground_impacts(enemy_nodes: Array, bomb_nodes: Array) -> void:
	for bomb_node in bomb_nodes:
		if bomb_node == null or bomb_node.is_queued_for_deletion():
			continue
		var terrain_y := _terrain_height_at(bomb_node.position.x)
		if bomb_node.position.y < terrain_y - 4.0:
			continue
		var impact_position := Vector2(bomb_node.position.x, terrain_y - 2.0)
		_detonate_bomb_on_ground(impact_position, enemy_nodes)
		bomb_node.queue_free()

func _detonate_bomb_on_ground(impact_position: Vector2, enemy_nodes: Array) -> void:
	var blast := BOMB_BLAST_SCRIPT.new()
	blast.position = impact_position
	add_child(blast)

	var kills := 0
	for enemy_node in enemy_nodes:
		if enemy_node == null or enemy_node.is_queued_for_deletion() or not enemy_node.has_method("apply_hit"):
			continue
		var enemy_hit_radius := float(enemy_node.get("hit_radius"))
		if enemy_node.position.distance_to(impact_position) > (BOMB_GROUND_BLAST_RADIUS + enemy_hit_radius):
			continue
		var points := int(enemy_node.apply_hit("bomb"))
		if points <= 0:
			continue
		game_state.add_score(points)
		kills += 1

	if kills > 0:
		last_action_text = "Bomb strike (%d)" % kills
	else:
		last_action_text = "Bomb impact"
	action_label.text = "Last Action: %s" % last_action_text

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
	for blast_node in get_tree().get_nodes_in_group("bomb_blasts"):
		blast_node.queue_free()
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

func _spawn_x() -> float:
	return get_viewport_rect().size.x + SPAWN_MARGIN_X

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
	_set_pause_ui_visibility()
	_update_pause_menu()
	_update_remap_panel()

func _update_info_label() -> void:
	var segment = _current_segment()
	var base_text := "Stage %d - %s | %s=start, %s=pause, F11=fullscreen, %s=fire (air), %s=bomb (ground), R=manual refuel" % [
		game_state.stage_id,
		String(segment["segment_name"]),
		_action_binding_text("start"),
		_action_binding_text("pause"),
		_action_binding_text("fire"),
		_action_binding_text("bomb")
	]
	if game_state.run_started and game_state.is_paused:
		info_label.text = "%s | Pause Menu: 1=resume, 2=retry, 3=window mode, 4=remap" % base_text
	else:
		info_label.text = base_text

func _update_input_debug() -> void:
	var pressed_actions: Array[String] = []
	for action in ["move_up", "move_down", "move_left", "move_right", "fire", "bomb", "start", "pause", "toggle_fullscreen"]:
		if Input.is_action_pressed(action):
			pressed_actions.append(action)
	var pressed_text := "none" if pressed_actions.is_empty() else ", ".join(pressed_actions)
	input_label.text = "Pressed: %s" % pressed_text

func _ensure_fullscreen_input_action() -> void:
	if not InputMap.has_action("toggle_fullscreen"):
		InputMap.add_action("toggle_fullscreen")
	var has_f11_binding := false
	for action_event in InputMap.action_get_events("toggle_fullscreen"):
		var key_event := action_event as InputEventKey
		if key_event == null:
			continue
		if _event_keycode(key_event) == KEY_F11:
			has_f11_binding = true
			break
	if not has_f11_binding:
		var fullscreen_event := InputEventKey.new()
		fullscreen_event.keycode = KEY_F11
		InputMap.action_add_event("toggle_fullscreen", fullscreen_event)

func _toggle_fullscreen() -> void:
	var current_mode := DisplayServer.window_get_mode()
	var is_fullscreen_mode := current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if is_fullscreen_mode:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	var mode_label := "Windowed" if is_fullscreen_mode else "Fullscreen"
	last_action_text = "Display mode switched to %s" % mode_label
	action_label.text = "Last Action: %s" % last_action_text
	_update_pause_menu()

func _set_pause_ui_visibility() -> void:
	var pause_visible := game_state.run_started and game_state.is_paused
	pause_menu.visible = pause_visible
	remap_panel.visible = pause_visible and is_remap_menu_open

func _update_pause_menu() -> void:
	var current_mode := DisplayServer.window_get_mode()
	var mode_name := "Fullscreen"
	if current_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		mode_name = "Windowed"
	pause_options_label.text = "1 Resume\n2 Retry Run\n3 Toggle Window Mode (%s)\n4 Input Remap" % mode_name

func _update_remap_panel() -> void:
	remap_status_label.text = remap_status_text
	var lines: Array[String] = []
	for index in range(REMAP_ACTIONS.size()):
		var action_name := REMAP_ACTIONS[index]
		var marker := ">" if index == remap_selected_index else " "
		lines.append("%s %s: %s" % [marker, _action_label(action_name), _action_binding_text(action_name)])
	remap_list_label.text = "\n".join(lines) + "\nBackspace resets selected action."

func _selected_remap_action() -> String:
	return REMAP_ACTIONS[clampi(remap_selected_index, 0, REMAP_ACTIONS.size() - 1)]

func _action_label(action_name: String) -> String:
	return String(ACTION_LABELS.get(action_name, action_name))

func _action_binding_text(action_name: String) -> String:
	for action_event in InputMap.action_get_events(action_name):
		var key_event := action_event as InputEventKey
		if key_event == null:
			continue
		return _keycode_label(_event_keycode(key_event))
	return "Unbound"

func _rebind_action(action_name: String, source_event: InputEventKey) -> void:
	InputMap.action_erase_events(action_name)
	var rebound_event := InputEventKey.new()
	rebound_event.keycode = _event_keycode(source_event)
	rebound_event.physical_keycode = source_event.physical_keycode
	rebound_event.shift_pressed = source_event.shift_pressed
	rebound_event.ctrl_pressed = source_event.ctrl_pressed
	rebound_event.alt_pressed = source_event.alt_pressed
	rebound_event.meta_pressed = source_event.meta_pressed
	InputMap.action_add_event(action_name, rebound_event)
	remap_status_text = "%s mapped to %s." % [_action_label(action_name), _action_binding_text(action_name)]
	_save_input_bindings()

func _reset_action_binding(action_name: String) -> void:
	InputMap.action_erase_events(action_name)
	var default_keycode := int(DEFAULT_KEY_BINDINGS.get(action_name, 0))
	if default_keycode != 0:
		var default_event := InputEventKey.new()
		default_event.keycode = default_keycode
		default_event.physical_keycode = default_keycode
		InputMap.action_add_event(action_name, default_event)
	remap_status_text = "%s reset to %s." % [_action_label(action_name), _action_binding_text(action_name)]
	_save_input_bindings()

func _load_input_bindings() -> void:
	var settings := ConfigFile.new()
	var load_error := settings.load(INPUT_BINDINGS_SETTINGS_PATH)
	if load_error != OK:
		return

	for action_name in REMAP_ACTIONS:
		var saved_keycode := int(settings.get_value(INPUT_BINDINGS_SECTION, action_name, 0))
		if saved_keycode <= 0:
			continue
		InputMap.action_erase_events(action_name)
		var key_event := InputEventKey.new()
		key_event.keycode = saved_keycode
		key_event.physical_keycode = saved_keycode
		InputMap.action_add_event(action_name, key_event)

func _save_input_bindings() -> void:
	var settings := ConfigFile.new()
	for action_name in REMAP_ACTIONS:
		settings.set_value(INPUT_BINDINGS_SECTION, action_name, _primary_action_keycode(action_name))
	settings.save(INPUT_BINDINGS_SETTINGS_PATH)

func _primary_action_keycode(action_name: String) -> int:
	for action_event in InputMap.action_get_events(action_name):
		var key_event := action_event as InputEventKey
		if key_event == null:
			continue
		return _event_keycode(key_event)
	return int(DEFAULT_KEY_BINDINGS.get(action_name, 0))

func _consume_input_event() -> void:
	get_viewport().set_input_as_handled()

func _event_keycode(key_event: InputEventKey) -> int:
	if key_event.keycode != 0:
		return key_event.keycode
	return key_event.physical_keycode

func _keycode_label(keycode: int) -> String:
	match keycode:
		KEY_UP:
			return "Up"
		KEY_DOWN:
			return "Down"
		KEY_LEFT:
			return "Left"
		KEY_RIGHT:
			return "Right"
		KEY_ENTER, KEY_KP_ENTER:
			return "Enter"
		KEY_ESCAPE:
			return "Esc"
		KEY_TAB:
			return "Tab"
		KEY_BACKSPACE:
			return "Backspace"
		KEY_SPACE:
			return "Space"
		KEY_F11:
			return "F11"
	if keycode >= KEY_F1 and keycode <= KEY_F12:
		return "F%d" % int(keycode - KEY_F1 + 1)
	if keycode >= KEY_A and keycode <= KEY_Z:
		return char(keycode)
	if keycode >= KEY_0 and keycode <= KEY_9:
		return char(keycode)
	return "Key %d" % keycode
