extends SceneTree

const GAME_STATE_SCRIPT := preload("res://scripts/game_state.gd")
const ENEMY_TARGET_SCRIPT := preload("res://scripts/enemy_target.gd")
const REQUIRED_ACTIONS: Array[String] = [
	"move_up",
	"move_down",
	"move_left",
	"move_right",
	"fire",
	"bomb",
	"start",
	"pause",
	"refuel"
]

var failures: Array[String] = []

func _initialize() -> void:
	_test_input_actions()
	_test_game_state_transitions()
	_test_enemy_hit_rules()

	if failures.is_empty():
		print("Smoke tests passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)

func _test_input_actions() -> void:
	for action_name in REQUIRED_ACTIONS:
		if not InputMap.has_action(action_name):
			failures.append("Missing required input action: %s" % action_name)

func _test_game_state_transitions() -> void:
	var game_state: GameState = GAME_STATE_SCRIPT.new()
	_assert(not game_state.run_started, "Run should start as not started")
	_assert(not game_state.is_alive, "Player should start dead")
	_assert(game_state.lives == GameState.STARTING_LIVES, "Lives should match starting value")

	game_state.start_run()
	_assert(game_state.run_started, "start_run should set run_started")
	_assert(game_state.is_alive, "start_run should set alive")
	_assert(game_state.fuel == GameState.MAX_FUEL, "start_run should refill fuel")

	game_state.toggle_pause()
	_assert(game_state.is_paused, "toggle_pause should pause run")
	game_state.toggle_pause()
	_assert(not game_state.is_paused, "toggle_pause should unpause run")

	game_state.die()
	_assert(not game_state.is_alive, "die should set alive=false")
	_assert(game_state.lives == GameState.STARTING_LIVES - 1, "die should consume one life")
	game_state.update(game_state.respawn_cooldown + 0.1)
	_assert(game_state.is_alive, "Respawn should occur after cooldown")

func _test_enemy_hit_rules() -> void:
	var ground_laser_target = ENEMY_TARGET_SCRIPT.new()
	ground_laser_target.target_type = "ground"
	_assert(ground_laser_target.apply_hit("laser") == 0, "Ground target should ignore laser")

	var ground_bomb_target = ENEMY_TARGET_SCRIPT.new()
	ground_bomb_target.target_type = "ground"
	ground_bomb_target.bomb_points = 70
	_assert(ground_bomb_target.apply_hit("bomb") == 70, "Ground target should accept bomb hits")

	var air_laser_target = ENEMY_TARGET_SCRIPT.new()
	air_laser_target.target_type = "air"
	air_laser_target.laser_points = 55
	_assert(air_laser_target.apply_hit("laser") == 55, "Air target should accept laser hits")

	var air_bomb_target = ENEMY_TARGET_SCRIPT.new()
	air_bomb_target.target_type = "air"
	air_bomb_target.bomb_points = 95
	_assert(air_bomb_target.apply_hit("bomb") == 95, "Air target should accept bomb hits")

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
