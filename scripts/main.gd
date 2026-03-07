extends Node2D

const FUEL_DRAIN_PER_SECOND := 0.05
const REFUEL_PER_SECOND := 32.0
const REFUEL_RECT := Rect2(Vector2(15, 170), Vector2(130, 260))
const BOLT_SPAWN_OFFSET := Vector2(22, 0)
const BOMB_DROP_OFFSET := Vector2(8, 12)
const STAGE_SCROLL_SPEED := 190.0
const ENEMY_AIR_Y_MIN := 130.0
const ENEMY_GROUND_Y := 548.0
const SPAWN_MARGIN_X := 36.0
const FUEL_TANK_Y_MIN := 190.0
const FUEL_TANK_Y_MAX := 460.0
const GROUND_UNIT_CLEARANCE := 12.0
const PLAYER_HIT_RADIUS := 16.0
const PLAYER_TERRAIN_CLEARANCE := 12.0
const PLAYER_CEILING_CLEARANCE := 10.0
const TUNNEL_SPAWN_MARGIN := 40.0
const AIR_SPAWN_REFERENCE_X_RATIO := 0.78
const STAGE_TRANSITION_DURATION := 1.6
const STAGE_CLEAR_BONUS := 500
const GAME_STATE_SCRIPT := preload("res://scripts/game_state.gd")
const LASER_BOLT_SCRIPT := preload("res://scripts/laser_bolt.gd")
const BOMB_PAYLOAD_SCRIPT := preload("res://scripts/bomb_payload.gd")
const BOMB_BLAST_SCRIPT := preload("res://scripts/bomb_blast.gd")
const IMPACT_FLASH_SCRIPT := preload("res://scripts/impact_flash.gd")
const EXPLOSION_PARTICLES_SCRIPT := preload("res://scripts/explosion_particles.gd")
const ENEMY_TARGET_SCRIPT := preload("res://scripts/enemy_target.gd")
const FUEL_TANK_SCRIPT := preload("res://scripts/fuel_tank.gd")
const SFX_SYNTH_SCRIPT := preload("res://scripts/sfx_synth.gd")
const PARALLAX_BACKGROUND_SCRIPT := preload("res://scripts/parallax_background.gd")
const TERRAIN_BAND_SCRIPT := preload("res://scripts/terrain_band.gd")
const CEILING_BAND_SCRIPT := preload("res://scripts/ceiling_band.gd")
const STAGE_SEGMENT_SETTINGS_SCRIPT := preload("res://scripts/stage_segment_settings.gd")
const STAGE_SEGMENTS_RESOURCE_PATH := "res://assets/data/stage_segments.tres"
const STARTUP_LANDSCAPE_PATH := "res://assets/ui/startup/starkiller_landscape.png"
const STARTUP_SHIP_PATH := "res://assets/ui/startup/starkiller_ship.png"
const BOMB_GROUND_BLAST_RADIUS := 92.0
const MAJOR_SHAKE_STRENGTH := 8.0
const MINOR_SHAKE_STRENGTH := 4.0
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
const START_SUBMENU_OPTIONS := ["start", "controls", "window_mode", "back"]

@onready var player: Node2D = $PlayerShip
@onready var hud: Control = $CanvasLayer/HUD
@onready var state_label: Label = $CanvasLayer/HUD/StateLabel
@onready var fuel_bar: ProgressBar = $CanvasLayer/HUD/FuelBar
@onready var fuel_value_label: Label = $CanvasLayer/HUD/FuelValue
@onready var input_label: Label = $CanvasLayer/HUD/InputLabel
@onready var action_label: Label = $CanvasLayer/HUD/ActionLabel
@onready var info_label: Label = $CanvasLayer/HUD/InfoLabel
@onready var pause_menu: PanelContainer = $CanvasLayer/PauseMenu
@onready var start_screen: Control = $CanvasLayer/StartScreen
@onready var start_landscape: TextureRect = $CanvasLayer/StartScreen/Landscape
@onready var start_ship: TextureRect = $CanvasLayer/StartScreen/Ship
@onready var game_over_title_label: Label = $CanvasLayer/StartScreen/GameOverTitle
@onready var game_over_message_label: Label = $CanvasLayer/StartScreen/GameOverMessage
@onready var start_prompt_label: Label = $CanvasLayer/StartScreen/StartPanel/VBox/StartPrompt
@onready var start_options_label: Label = $CanvasLayer/StartScreen/StartPanel/VBox/StartOptions
@onready var start_hint_label: Label = $CanvasLayer/StartScreen/StartPanel/VBox/StartHint
@onready var pause_options_label: Label = $CanvasLayer/PauseMenu/VBox/PauseOptions
@onready var remap_panel: PanelContainer = $CanvasLayer/RemapPanel
@onready var remap_status_label: Label = $CanvasLayer/RemapPanel/VBox/RemapStatus
@onready var remap_list_label: Label = $CanvasLayer/RemapPanel/VBox/RemapList
@onready var stage_banner: Label = $CanvasLayer/StageBanner

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
var screen_shake_strength := 0.0
var screen_shake_remaining := 0.0
var _last_visual_segment_index := -1
var stage_transition_remaining := 0.0
var current_enemy_style: Dictionary = {}
var start_menu_selected_index := 0
var is_start_menu_details_open := false
var start_submenu_selected_index := 0
var is_start_controls_open := false
var _last_input_debug_text := ""
var _last_player_top_margin := -1.0

func _ready() -> void:
	rng.randomize()
	_load_startup_art()
	_create_world_layers()
	_load_stage_segments()
	_ensure_fullscreen_input_action()
	_load_input_bindings()
	game_state.changed.connect(_update_hud)
	game_state.action_triggered.connect(_on_action_triggered)
	game_state.player_died.connect(_on_player_died)
	game_state.player_respawned.connect(_on_respawned)
	_update_hud()
	_sync_player_playfield_bounds()
	_set_pause_ui_visibility()
	_update_pause_menu()
	_update_remap_panel()
	_update_start_screen_ui()

func _sync_player_playfield_bounds() -> void:
	if player == null or hud == null:
		return
	var hud_bottom := hud.get_global_rect().end.y
	var target_top_margin := hud_bottom + 34.0
	if is_equal_approx(target_top_margin, _last_player_top_margin):
		return
	_last_player_top_margin = target_top_margin
	player.set("top_margin", target_top_margin)

func _load_startup_art() -> void:
	_assign_texture_from_image(start_landscape, STARTUP_LANDSCAPE_PATH)
	_assign_texture_from_image(start_ship, STARTUP_SHIP_PATH)

func _assign_texture_from_image(target: TextureRect, image_path: String) -> void:
	if target == null:
		return
	var image := Image.load_from_file(image_path)
	if image == null or image.is_empty():
		push_warning("Failed to load startup art: %s" % image_path)
		return
	target.texture = ImageTexture.create_from_image(image)

func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	_handle_key_event(key_event)

func _handle_key_event(event: InputEventKey) -> void:
	if _is_title_overlay_visible():
		_handle_start_screen_key_event(event)
		return

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

	if not game_state.is_paused:
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

func _is_game_over() -> bool:
	return game_state.run_started and game_state.lives <= 0

func _is_title_overlay_visible() -> bool:
	return not game_state.run_started or _is_game_over()

func _handle_start_screen_key_event(event: InputEventKey) -> void:
	if is_start_controls_open:
		if awaiting_rebind:
			if event.keycode == KEY_ESCAPE:
				awaiting_rebind = false
				remap_status_text = "Rebind canceled."
			else:
				_rebind_action(_selected_remap_action(), event)
				awaiting_rebind = false
			_update_start_screen_ui()
			_consume_input_event()
			return

		match event.keycode:
			KEY_ESCAPE:
				is_start_controls_open = false
				remap_status_text = "Use Up/Down to pick an action, Enter to rebind."
				_update_start_screen_ui()
				_consume_input_event()
			KEY_UP:
				remap_selected_index = wrapi(remap_selected_index - 1, 0, REMAP_ACTIONS.size())
				_update_start_screen_ui()
				_consume_input_event()
			KEY_DOWN:
				remap_selected_index = wrapi(remap_selected_index + 1, 0, REMAP_ACTIONS.size())
				_update_start_screen_ui()
				_consume_input_event()
			KEY_ENTER, KEY_KP_ENTER:
				awaiting_rebind = true
				remap_status_text = "Press a key for %s (Esc to cancel)." % _action_label(_selected_remap_action())
				_update_start_screen_ui()
				_consume_input_event()
			KEY_BACKSPACE:
				_reset_action_binding(_selected_remap_action())
				_update_start_screen_ui()
				_consume_input_event()
		return

	if is_start_menu_details_open:
		match event.keycode:
			KEY_ESCAPE, KEY_BACKSPACE:
				is_start_menu_details_open = false
				start_submenu_selected_index = 0
				_update_start_screen_ui()
				_consume_input_event()
			KEY_UP:
				start_submenu_selected_index = wrapi(start_submenu_selected_index - 1, 0, START_SUBMENU_OPTIONS.size())
				_update_start_screen_ui()
				_consume_input_event()
			KEY_DOWN:
				start_submenu_selected_index = wrapi(start_submenu_selected_index + 1, 0, START_SUBMENU_OPTIONS.size())
				_update_start_screen_ui()
				_consume_input_event()
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_activate_start_submenu_option()
				_consume_input_event()
		return

	match event.keycode:
		KEY_UP, KEY_DOWN:
			start_menu_selected_index = 1 - start_menu_selected_index
			_update_start_screen_ui()
			_consume_input_event()
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			if start_menu_selected_index == 0:
				var from_game_over := _is_game_over()
				_start_run()
				last_action_text = "Run restarted from game over" if from_game_over else "Run started from title screen"
				action_label.text = "Last Action: %s" % last_action_text
			else:
				is_start_menu_details_open = true
				start_submenu_selected_index = 0
				_update_start_screen_ui()
			_consume_input_event()

func _activate_start_submenu_option() -> void:
	var selected_option := String(START_SUBMENU_OPTIONS[start_submenu_selected_index])
	match selected_option:
		"start":
			var from_game_over := _is_game_over()
			_start_run()
			last_action_text = "Run restarted from game over" if from_game_over else "Run started from title screen"
			action_label.text = "Last Action: %s" % last_action_text
		"controls":
			is_start_controls_open = true
			awaiting_rebind = false
			remap_status_text = "Use Up/Down to pick an action, Enter to rebind."
			_update_start_screen_ui()
		"window_mode":
			_toggle_fullscreen()
			_update_start_screen_ui()
		"back":
			is_start_menu_details_open = false
			start_submenu_selected_index = 0
			_update_start_screen_ui()

func _update_start_screen_ui() -> void:
	if start_screen == null:
		return

	var show_title_overlay := _is_title_overlay_visible()
	start_screen.visible = show_title_overlay
	hud.visible = not show_title_overlay
	if show_title_overlay:
		_set_stage_banner_visible(false)

	var is_game_over_overlay := _is_game_over()
	var is_nested_title_screen := is_start_menu_details_open or is_start_controls_open
	game_over_title_label.visible = is_game_over_overlay and not is_nested_title_screen
	game_over_message_label.visible = is_game_over_overlay and not is_nested_title_screen
	if is_game_over_overlay:
		game_over_message_label.text = "Final score %d  Stage %d  Press Enter to retry." % [
			game_state.score,
			game_state.stage_id
		]

	if is_start_controls_open:
		start_prompt_label.text = "CONTROLS" if not is_game_over_overlay else "GAME OVER CONTROLS"
		start_options_label.text = "%s\n\n%s" % [remap_status_text, _remap_list_text()]
		start_hint_label.text = "Use Up/Down, Enter to rebind, Backspace to reset, Esc to return."
		return

	if is_start_menu_details_open:
		start_prompt_label.text = "MENU" if not is_game_over_overlay else "GAME OVER MENU"
		var run_label := "RETRY RUN" if is_game_over_overlay else "START RUN"
		var mode_label := "Fullscreen"
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
			mode_label = "Windowed"
		var submenu_lines := [
			_start_menu_option_line(0, run_label),
			_start_menu_option_line(1, "CONTROLS"),
			_start_menu_option_line(2, "WINDOW MODE: %s" % mode_label),
			_start_menu_option_line(3, "BACK")
		]
		start_options_label.text = "\n".join(submenu_lines)
		start_hint_label.text = "Use Up/Down, Enter to confirm, Esc to return."
		return

	start_prompt_label.text = "GAME OVER" if is_game_over_overlay else "Select Option"
	var start_marker := ">" if start_menu_selected_index == 0 else " "
	var menu_marker := ">" if start_menu_selected_index == 1 else " "
	var start_label := "RETRY RUN" if is_game_over_overlay else "START RUN"
	start_options_label.text = "%s %s\n%s MENU" % [start_marker, start_label, menu_marker]
	start_hint_label.text = "Use Up/Down, Enter to confirm."

func _process(delta: float) -> void:
	_sync_player_playfield_bounds()

	if Input.is_action_just_pressed("start"):
		if game_state.run_started and game_state.is_paused and not is_remap_menu_open and not awaiting_rebind:
			_start_run()

	if Input.is_action_just_pressed("pause"):
		if _suppress_pause_this_frame:
			_suppress_pause_this_frame = false
		elif awaiting_rebind:
			awaiting_rebind = false
			remap_status_text = "Rebind canceled."
			_update_remap_panel()
		elif game_state.run_started and not _is_game_over():
			if game_state.is_paused and is_remap_menu_open:
				is_remap_menu_open = false
				_set_pause_ui_visibility()
				_update_remap_panel()
			else:
				game_state.toggle_pause()

	if Input.is_action_just_pressed("toggle_fullscreen"):
		_toggle_fullscreen()

	if game_state.run_started and game_state.is_alive and not game_state.is_paused:
		if stage_transition_remaining > 0.0:
			_update_stage_transition(delta)
		else:
			_update_stage_progress(delta)
			_update_enemy_spawns(delta)
			_update_fuel_tank_spawns(delta)
		if Input.is_action_just_pressed("fire"):
			game_state.register_action("Fire")
			_spawn_bolt()
		if Input.is_action_just_pressed("bomb"):
			_try_trigger_bomb()

		if stage_transition_remaining <= 0.0:
			game_state.drain_fuel(FUEL_DRAIN_PER_SECOND * delta)

		if Input.is_action_pressed("refuel"):
			game_state.add_fuel(REFUEL_PER_SECOND * delta)

		if REFUEL_RECT.has_point(player.position):
			game_state.add_fuel(REFUEL_PER_SECOND * delta)

		_update_combat_state()
		game_state.update(delta)
		_update_world_layers()
		_update_ground_enemy_attachment()
		player.visible = game_state.is_alive
	player.set_physics_process(game_state.run_started and game_state.is_alive and not game_state.is_paused)
	_set_actor_activity(game_state.run_started and game_state.is_alive and not game_state.is_paused)
	_update_input_debug()
	_update_screen_shake(delta)

func _start_run() -> void:
	game_state.start_run()
	player.position = Vector2(120, 320)
	position = Vector2.ZERO
	screen_shake_strength = 0.0
	screen_shake_remaining = 0.0
	_clear_combat_nodes()
	_reset_run_progression()
	enemy_spawn_remaining = 0.35
	is_remap_menu_open = false
	awaiting_rebind = false
	remap_status_text = "Use Up/Down to pick an action, Enter to rebind."
	is_start_menu_details_open = false
	start_menu_selected_index = 0
	start_submenu_selected_index = 0
	is_start_controls_open = false
	_set_pause_ui_visibility()
	_update_pause_menu()
	_update_remap_panel()
	_update_start_screen_ui()

func _start_menu_option_line(index: int, label: String) -> String:
	var marker := ">" if start_submenu_selected_index == index else " "
	return "%s %s" % [marker, label]

func _on_action_triggered(action_name: String) -> void:
	last_action_text = "%s @ %.2fs" % [action_name, Time.get_ticks_msec() / 1000.0]
	action_label.text = "Last Action: %s" % last_action_text

func _on_player_died() -> void:
	_play_sfx("death", -4.0, 0.04)
	_spawn_explosion(player.position, true)
	_trigger_screen_shake(MAJOR_SHAKE_STRENGTH, 0.22)

func _play_sfx(cue_name: String, volume_db := -8.0, pitch_jitter := 0.06) -> void:
	var stream: AudioStreamWAV = SFX_SYNTH_SCRIPT.stream_for(cue_name)
	if stream == null:
		return
	var sfx_player := AudioStreamPlayer.new()
	sfx_player.stream = stream
	sfx_player.volume_db = volume_db
	if pitch_jitter > 0.0:
		sfx_player.pitch_scale = rng.randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	add_child(sfx_player)
	sfx_player.finished.connect(sfx_player.queue_free)
	sfx_player.play()

func _spawn_impact_flash(world_position: Vector2, radius := 24.0, color := Color(1.0, 0.92, 0.58, 0.8)) -> void:
	var flash := IMPACT_FLASH_SCRIPT.new()
	flash.position = world_position
	flash.set("end_radius", radius)
	flash.set("fill_color", color)
	add_child(flash)

func _spawn_explosion(world_position: Vector2, major := false) -> void:
	var explosion := EXPLOSION_PARTICLES_SCRIPT.new()
	explosion.position = world_position
	if major:
		explosion.set("particle_count", 32)
		explosion.set("speed_max", 320.0)
		explosion.set("lifetime", 0.48)
	add_child(explosion)

func _trigger_screen_shake(strength: float, duration: float) -> void:
	screen_shake_strength = maxf(screen_shake_strength, strength)
	screen_shake_remaining = maxf(screen_shake_remaining, duration)

func _update_screen_shake(delta: float) -> void:
	if screen_shake_remaining <= 0.0 or screen_shake_strength <= 0.0:
		if position != Vector2.ZERO:
			position = Vector2.ZERO
		screen_shake_strength = 0.0
		screen_shake_remaining = 0.0
		return

	screen_shake_remaining = maxf(0.0, screen_shake_remaining - delta)
	screen_shake_strength = maxf(0.0, screen_shake_strength - delta * 28.0)
	position = Vector2(
		rng.randf_range(-screen_shake_strength, screen_shake_strength),
		rng.randf_range(-screen_shake_strength, screen_shake_strength)
	)

func _handle_player_death(reason_text: String) -> void:
	game_state.die()
	last_action_text = reason_text
	action_label.text = "Last Action: %s" % last_action_text

func _spawn_bolt() -> void:
	var bolt := LASER_BOLT_SCRIPT.new()
	bolt.position = player.position + BOLT_SPAWN_OFFSET
	add_child(bolt)
	_play_sfx("fire", -12.0, 0.08)
	_spawn_impact_flash(bolt.position + Vector2(-8.0, 0.0), 16.0, Color(0.95, 0.98, 0.72, 0.7))

func _spawn_enemy() -> void:
	var segment = _current_segment()
	var style: Dictionary = segment.get("enemy_style", {})
	var spawn_x := _spawn_x()
	var enemy := ENEMY_TARGET_SCRIPT.new()
	var spawn_ground := rng.randf() <= float(segment["ground_target_chance"])
	var ground_spawn_y := _terrain_height_at(spawn_x) - GROUND_UNIT_CLEARANCE
	if spawn_ground:
		enemy.position = Vector2(spawn_x, ground_spawn_y)
		enemy.set("speed", STAGE_SCROLL_SPEED)
		enemy.set("target_type", "ground")
		enemy.set("ground_variant", String(style.get("ground_variant", "walker")))
	else:
		var air_spawn_reference_x := get_viewport_rect().size.x * AIR_SPAWN_REFERENCE_X_RATIO
		enemy.position = Vector2(spawn_x, _air_spawn_y_at(air_spawn_reference_x))
		enemy.set("speed", rng.randf_range(float(segment["air_speed_min"]), float(segment["air_speed_max"])))
		enemy.set("target_type", "air")
		enemy.set("air_variant", String(style.get("air_variant", "raider")))
		var distant_chance := clampf(float(style.get("distant_flyby_chance", 0.0)), 0.0, 0.95)
		if rng.randf() < distant_chance:
			enemy.set("is_distant", true)
	add_child(enemy)

func _air_spawn_y_at(screen_x: float) -> float:
	var viewport_size := get_viewport_rect().size
	var player_top_margin := 52.0
	var player_bottom_margin := 28.0
	if player != null:
		player_top_margin = float(player.get("top_margin"))
		player_bottom_margin = float(player.get("bottom_margin"))

	var player_lane_top := player_top_margin + 8.0
	var player_lane_bottom := viewport_size.y - player_bottom_margin - 18.0
	var tunnel_top := _ceiling_height_at(screen_x) + TUNNEL_SPAWN_MARGIN * 0.65
	var tunnel_bottom := _terrain_height_at(screen_x) - TUNNEL_SPAWN_MARGIN * 0.45
	var air_min := maxf(maxf(player_lane_top, tunnel_top), ENEMY_AIR_Y_MIN)
	var air_max := minf(player_lane_bottom, tunnel_bottom)
	if air_max <= air_min:
		return clampf((air_min + air_max) * 0.5, player_lane_top, player_lane_bottom)

	var corridor_height := air_max - air_min
	var lower_band_min := air_min + corridor_height * 0.42
	var lower_band_max := air_min + corridor_height * 0.88
	var sampled_y := rng.randf_range(lower_band_min, lower_band_max)
	if rng.randf() < 0.35:
		sampled_y = rng.randf_range(air_min, air_max)
	return clampf(sampled_y, air_min, air_max)

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
	_play_sfx("bomb_drop", -10.0, 0.04)

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
		_handle_player_death("Crashed into ceiling")
		return

	if player.position.y + PLAYER_TERRAIN_CLEARANCE >= terrain_height:
		_handle_player_death("Crashed into terrain")
		return

	for enemy_node in enemy_nodes:
		if enemy_node == null or enemy_node.is_queued_for_deletion() or not enemy_node.has_method("apply_hit"):
			continue

		var enemy_type := String(enemy_node.get("target_type"))
		var enemy_hit_radius := float(enemy_node.get("hit_radius"))

		if enemy_type == "air" and enemy_node.position.distance_to(player.position) <= (enemy_hit_radius + PLAYER_HIT_RADIUS):
			enemy_node.apply_hit("ship")
			_handle_player_death("Ship hit by enemy")
			return

		if enemy_type == "air":
			for bolt_node in bolt_nodes:
				if bolt_node == null or bolt_node.is_queued_for_deletion():
					continue
				var bolt_hit_radius := float(bolt_node.get("hit_radius"))
				if bolt_node.position.distance_to(enemy_node.position) <= (bolt_hit_radius + enemy_hit_radius):
					var impact_position := Vector2(enemy_node.position)
					var air_points := int(enemy_node.apply_hit("laser"))
					if air_points > 0:
						game_state.add_score(air_points)
						last_action_text = "Air target destroyed"
						action_label.text = "Last Action: %s" % last_action_text
						_play_sfx("enemy_destroy", -8.0, 0.12)
						_spawn_impact_flash(impact_position, 24.0, Color(1.0, 0.9, 0.44, 0.8))
						_spawn_explosion(impact_position, false)
					bolt_node.queue_free()
					break

		for bomb_node in bomb_nodes:
			if bomb_node == null or bomb_node.is_queued_for_deletion():
				continue
			var bomb_hit_radius := float(bomb_node.get("hit_radius"))
			if bomb_node.position.distance_to(enemy_node.position) <= (bomb_hit_radius + enemy_hit_radius):
				var impact_position := Vector2(enemy_node.position)
				var bomb_points := int(enemy_node.apply_hit("bomb"))
				if bomb_points > 0:
					game_state.add_score(bomb_points)
					last_action_text = "Target bombed"
					action_label.text = "Last Action: %s" % last_action_text
					_play_sfx("enemy_destroy", -6.5, 0.14)
					_spawn_impact_flash(impact_position, 30.0, Color(1.0, 0.7, 0.35, 0.85))
					_spawn_explosion(impact_position, false)
					_trigger_screen_shake(MINOR_SHAKE_STRENGTH, 0.1)
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
			_play_sfx("fuel_pickup", -7.5, 0.07)
			_spawn_impact_flash(fuel_tank_node.position, 20.0, Color(0.68, 0.96, 0.6, 0.78))
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
	_play_sfx("impact", -5.8, 0.05)
	_spawn_impact_flash(impact_position, 40.0, Color(1.0, 0.78, 0.45, 0.82))
	_spawn_explosion(impact_position, true)
	_trigger_screen_shake(MAJOR_SHAKE_STRENGTH, 0.16)

	var kills := 0
	for enemy_node in enemy_nodes:
		if enemy_node == null or enemy_node.is_queued_for_deletion() or not enemy_node.has_method("apply_hit"):
			continue
		var enemy_hit_radius := float(enemy_node.get("hit_radius"))
		if enemy_node.position.distance_to(impact_position) > (BOMB_GROUND_BLAST_RADIUS + enemy_hit_radius):
			continue
		var enemy_position := Vector2(enemy_node.position)
		var points := int(enemy_node.apply_hit("bomb"))
		if points <= 0:
			continue
		game_state.add_score(points)
		kills += 1
		_spawn_impact_flash(enemy_position, 24.0, Color(1.0, 0.84, 0.45, 0.72))
		_spawn_explosion(enemy_position, false)

	if kills > 0:
		last_action_text = "Bomb strike (%d)" % kills
		_play_sfx("enemy_destroy", -5.0, 0.1)
	else:
		last_action_text = "Bomb impact"
	action_label.text = "Last Action: %s" % last_action_text

func _update_ground_enemy_attachment() -> void:
	for enemy_node in get_tree().get_nodes_in_group("enemy_targets"):
		if enemy_node == null or enemy_node.is_queued_for_deletion():
			continue
		if String(enemy_node.get("target_type")) != "ground":
			continue
		enemy_node.position.y = _terrain_height_at(enemy_node.position.x) - GROUND_UNIT_CLEARANCE

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
	for vfx_node in get_tree().get_nodes_in_group("combat_vfx"):
		vfx_node.queue_free()
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
	if current_segment_index != _last_visual_segment_index:
		_apply_segment_visuals()
		_last_visual_segment_index = current_segment_index

func _apply_segment_visuals() -> void:
	var segment = _current_segment()
	var terrain_profile: Dictionary = segment.get("terrain_profile", {})
	var ceiling_profile: Dictionary = segment.get("ceiling_profile", {})
	var sky_palette: Dictionary = segment.get("sky_palette", {})
	var background_style: Dictionary = segment.get("background_style", {})
	current_enemy_style = segment.get("enemy_style", {})
	if background_layer != null and background_layer.has_method("set_palette_override"):
		background_layer.call("set_palette_override", sky_palette)
	if background_layer != null and background_layer.has_method("set_style_override"):
		background_layer.call("set_style_override", background_style)
	if ceiling_layer != null and ceiling_layer.has_method("set_profile_override"):
		ceiling_layer.call("set_profile_override", ceiling_profile)
	if terrain_layer != null and terrain_layer.has_method("set_profile_override"):
		terrain_layer.call("set_profile_override", terrain_profile)

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

func _load_stage_segments() -> void:
	stage_segments.clear()

	var loaded_resource := ResourceLoader.load(STAGE_SEGMENTS_RESOURCE_PATH)
	if loaded_resource != null and loaded_resource.has_method("normalized_segments_or_default"):
		stage_segments = loaded_resource.call("normalized_segments_or_default")

	if stage_segments.is_empty():
		stage_segments = STAGE_SEGMENT_SETTINGS_SCRIPT.default_segments()

func _reset_run_progression() -> void:
	current_segment_index = 0
	_last_visual_segment_index = -1
	stage_transition_remaining = 0.0
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
		_load_stage_segments()
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
	stage_transition_remaining = STAGE_TRANSITION_DURATION
	game_state.add_score(STAGE_CLEAR_BONUS)
	last_action_text = "Stage Clear - entering %s" % String(segment["segment_name"])
	action_label.text = "Last Action: %s" % last_action_text
	_set_stage_banner_text("STAGE CLEAR")
	_set_stage_banner_visible(true)
	_play_sfx("stage_clear", -6.0, 0.03)

func _update_stage_transition(delta: float) -> void:
	stage_transition_remaining = maxf(0.0, stage_transition_remaining - delta)
	run_distance += STAGE_SCROLL_SPEED * delta
	var progress := 1.0 - (stage_transition_remaining / STAGE_TRANSITION_DURATION)
	_update_stage_banner(progress)
	if stage_transition_remaining <= 0.0:
		_set_stage_banner_visible(false)
		var segment = _current_segment()
		last_action_text = "Entered %s" % String(segment["segment_name"])
		action_label.text = "Last Action: %s" % last_action_text

func _update_stage_banner(progress: float) -> void:
	if stage_banner == null:
		return
	var phase_text := "STAGE CLEAR" if progress < 0.5 else "ENTERING %s" % String(_current_segment()["segment_name"])
	stage_banner.text = phase_text
	var pulse := 0.55 + 0.45 * sin(progress * PI)
	stage_banner.modulate = Color(1, 1, 1, clampf(pulse, 0.0, 1.0))
	stage_banner.scale = Vector2.ONE * (1.0 + 0.08 * sin(progress * TAU))

func _set_stage_banner_text(text: String) -> void:
	if stage_banner != null:
		stage_banner.text = text

func _set_stage_banner_visible(visible: bool) -> void:
	if stage_banner != null:
		stage_banner.visible = visible

func _on_respawned() -> void:
	player.position = Vector2(120, 320)
	position = Vector2.ZERO
	screen_shake_strength = 0.0
	screen_shake_remaining = 0.0
	last_action_text = "Respawned"

func _update_hud() -> void:
	state_label.text = "SCR %05d    LIV %d    STG %d    %s" % [
		game_state.score,
		max(game_state.lives, 0),
		game_state.stage_id,
		game_state.status_text()
	]
	fuel_bar.value = game_state.fuel
	fuel_value_label.text = "%05.1f%%" % game_state.fuel
	action_label.text = "LOG  %s" % String(last_action_text)
	_update_info_label()
	_set_pause_ui_visibility()
	_update_pause_menu()
	_update_remap_panel()
	_update_start_screen_ui()

func _update_info_label() -> void:
	var segment = _current_segment()
	var base_text := "SEC %d  %s    %s START    %s PAUSE    %s FIRE    %s BOMB    R REFUEL" % [
		game_state.stage_id,
		String(segment["segment_name"]),
		_action_binding_text("start"),
		_action_binding_text("pause"),
		_action_binding_text("fire"),
		_action_binding_text("bomb")
	]
	if game_state.run_started and game_state.is_paused:
		info_label.text = "%s    1 RESUME  2 RETRY  3 WINDOW  4 REMAP" % base_text
	else:
		info_label.text = base_text

func _update_input_debug() -> void:
	if input_label == null or not input_label.visible:
		return
	var pressed_actions: Array[String] = []
	for action in ["move_up", "move_down", "move_left", "move_right", "fire", "bomb", "start", "pause", "toggle_fullscreen"]:
		if Input.is_action_pressed(action):
			pressed_actions.append(action)
	var pressed_text := "none" if pressed_actions.is_empty() else ", ".join(pressed_actions)
	var next_text := "IN: %s" % pressed_text
	if next_text == _last_input_debug_text:
		return
	_last_input_debug_text = next_text
	input_label.text = next_text

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
	var pause_visible: bool = game_state.run_started and game_state.is_paused and not _is_game_over()
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
	remap_list_label.text = _remap_list_text() + "\nBackspace resets selected action."

func _selected_remap_action() -> String:
	return REMAP_ACTIONS[clampi(remap_selected_index, 0, REMAP_ACTIONS.size() - 1)]

func _remap_list_text() -> String:
	var lines: Array[String] = []
	for index in range(REMAP_ACTIONS.size()):
		var action_name := REMAP_ACTIONS[index]
		var marker := ">" if index == remap_selected_index else " "
		lines.append("%s %s: %s" % [marker, _action_label(action_name), _action_binding_text(action_name)])
	return "\n".join(lines)

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
	var rebound_keycode := _event_keycode(source_event)
	if not _is_supported_binding_keycode(rebound_keycode):
		remap_status_text = "Unsupported key. Use arrows, letters, numbers, Enter/Esc, or F-keys."
		return
	InputMap.action_erase_events(action_name)
	var rebound_event := InputEventKey.new()
	rebound_event.keycode = rebound_keycode
	rebound_event.physical_keycode = source_event.physical_keycode if source_event.physical_keycode != 0 else rebound_keycode
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
	if load_error == OK:
		for action_name in REMAP_ACTIONS:
			var saved_keycode := int(settings.get_value(INPUT_BINDINGS_SECTION, action_name, 0))
			if not _is_supported_binding_keycode(saved_keycode):
				continue
			_set_single_key_binding(action_name, saved_keycode)
	elif load_error != ERR_FILE_NOT_FOUND:
		push_warning("Failed to load input bindings (%d)." % load_error)

	_ensure_safe_remap_bindings()

func _save_input_bindings() -> void:
	var settings := ConfigFile.new()
	for action_name in REMAP_ACTIONS:
		settings.set_value(INPUT_BINDINGS_SECTION, action_name, _primary_action_keycode(action_name))
	var save_error := settings.save(INPUT_BINDINGS_SETTINGS_PATH)
	if save_error != OK:
		push_warning("Failed to save input bindings (%d)." % save_error)
		remap_status_text = "Failed to save bindings (error %d)." % save_error

func _primary_action_keycode(action_name: String) -> int:
	for action_event in InputMap.action_get_events(action_name):
		var key_event := action_event as InputEventKey
		if key_event == null:
			continue
		var keycode := _event_keycode(key_event)
		if _is_supported_binding_keycode(keycode):
			return keycode
	return int(DEFAULT_KEY_BINDINGS.get(action_name, 0))

func _set_single_key_binding(action_name: String, keycode: int) -> void:
	var safe_keycode := int(keycode)
	if not _is_supported_binding_keycode(safe_keycode):
		return
	InputMap.action_erase_events(action_name)
	var key_event := InputEventKey.new()
	key_event.keycode = safe_keycode
	key_event.physical_keycode = safe_keycode
	InputMap.action_add_event(action_name, key_event)

func _ensure_safe_remap_bindings() -> void:
	for action_name in REMAP_ACTIONS:
		var has_valid_binding := false
		for action_event in InputMap.action_get_events(action_name):
			var key_event := action_event as InputEventKey
			if key_event == null:
				continue
			if _is_supported_binding_keycode(_event_keycode(key_event)):
				has_valid_binding = true
				break
		if has_valid_binding:
			continue
		var default_keycode := int(DEFAULT_KEY_BINDINGS.get(action_name, 0))
		_set_single_key_binding(action_name, default_keycode)

func _is_supported_binding_keycode(keycode: int) -> bool:
	if keycode <= 0:
		return false
	match keycode:
		KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE, KEY_TAB, KEY_BACKSPACE, KEY_SPACE:
			return true
	if keycode >= KEY_F1 and keycode <= KEY_F12:
		return true
	if keycode >= KEY_A and keycode <= KEY_Z:
		return true
	if keycode >= KEY_0 and keycode <= KEY_9:
		return true
	return false

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
