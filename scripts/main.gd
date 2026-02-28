extends Node2D

const FUEL_DRAIN_PER_SECOND := 11.0
const REFUEL_PER_SECOND := 38.0
const REFUEL_RECT := Rect2(Vector2(15, 170), Vector2(130, 260))

@onready var player: PlayerShip = $PlayerShip
@onready var state_label: Label = $CanvasLayer/HUD/StateLabel
@onready var input_label: Label = $CanvasLayer/HUD/InputLabel
@onready var action_label: Label = $CanvasLayer/HUD/ActionLabel
@onready var info_label: Label = $CanvasLayer/HUD/InfoLabel

var game_state := GameState.new()
var last_action_text := "No actions yet"

func _ready() -> void:
	game_state.changed.connect(_update_hud)
	game_state.action_triggered.connect(_on_action_triggered)
	game_state.player_respawned.connect(_on_respawned)
	_update_hud()
	info_label.text = "Enter=start, Esc=pause, Z=fire, X=bomb, R=manual refuel"

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("start"):
		game_state.start_run()
		player.position = Vector2(120, 320)

	if Input.is_action_just_pressed("pause"):
		game_state.toggle_pause()

	if game_state.run_started and game_state.is_alive and not game_state.is_paused:
		if Input.is_action_just_pressed("fire"):
			game_state.register_action("Fire")
			game_state.add_score(10)
		if Input.is_action_just_pressed("bomb"):
			game_state.register_action("Bomb")
			game_state.add_score(25)

		game_state.drain_fuel(FUEL_DRAIN_PER_SECOND * delta)

		if Input.is_action_pressed("refuel"):
			game_state.add_fuel(REFUEL_PER_SECOND * delta)

		if REFUEL_RECT.has_point(player.position):
			game_state.add_fuel(REFUEL_PER_SECOND * delta)

	game_state.update(delta)
	player.visible = game_state.is_alive
	player.set_physics_process(game_state.run_started and game_state.is_alive and not game_state.is_paused)
	_update_input_debug()

func _on_action_triggered(action_name: String) -> void:
	last_action_text = "%s @ %.2fs" % [action_name, Time.get_ticks_msec() / 1000.0]
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

func _update_input_debug() -> void:
	var pressed_actions: Array[String] = []
	for action in ["move_up", "move_down", "move_left", "move_right", "fire", "bomb", "start", "pause"]:
		if Input.is_action_pressed(action):
			pressed_actions.append(action)
	input_label.text = "Pressed: %s" % (["none"] if pressed_actions.is_empty() else pressed_actions).join(", ")
