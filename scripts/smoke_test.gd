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
	if not _assert_script_instantiable(GAME_STATE_SCRIPT, "game_state.gd"):
		return
	var game_state = GAME_STATE_SCRIPT.new()
	if not (game_state is GameState):
		failures.append("game_state.gd did not instantiate as GameState.")
		return
	var typed_game_state: GameState = game_state
	_assert(not typed_game_state.run_started, "Run should start as not started")
	_assert(not typed_game_state.is_alive, "Player should start dead")
	_assert(typed_game_state.lives == GameState.STARTING_LIVES, "Lives should match starting value")

	typed_game_state.start_run()
	_assert(typed_game_state.run_started, "start_run should set run_started")
	_assert(typed_game_state.is_alive, "start_run should set alive")
	_assert(typed_game_state.fuel == GameState.MAX_FUEL, "start_run should refill fuel")

	typed_game_state.toggle_pause()
	_assert(typed_game_state.is_paused, "toggle_pause should pause run")
	typed_game_state.toggle_pause()
	_assert(not typed_game_state.is_paused, "toggle_pause should unpause run")

	typed_game_state.die()
	_assert(not typed_game_state.is_alive, "die should set alive=false")
	_assert(typed_game_state.lives == GameState.STARTING_LIVES - 1, "die should consume one life")
	typed_game_state.update(typed_game_state.respawn_cooldown + 0.1)
	_assert(typed_game_state.is_alive, "Respawn should occur after cooldown")

	typed_game_state.start_run()
	for life_index in range(GameState.STARTING_LIVES):
		typed_game_state.die()
		if life_index < GameState.STARTING_LIVES - 1:
			typed_game_state.update(typed_game_state.respawn_cooldown + 0.1)
	_assert(typed_game_state.lives == 0, "Final death should reach 0 lives")
	_assert(not typed_game_state.is_alive, "0 lives should remain dead")
	_assert(typed_game_state.status_text() == "Game Over", "0 lives should report Game Over")
	typed_game_state.update(typed_game_state.respawn_cooldown + 0.1)
	_assert(not typed_game_state.is_alive, "0 lives should not respawn")

func _test_enemy_hit_rules() -> void:
	if not _assert_script_instantiable(ENEMY_TARGET_SCRIPT, "enemy_target.gd"):
		return
	var ground_laser_target = ENEMY_TARGET_SCRIPT.new()
	if ground_laser_target == null or not ground_laser_target.has_method("apply_hit"):
		failures.append("enemy_target.gd instance missing apply_hit.")
		return
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

func _assert_script_instantiable(script_resource: Script, script_name: String) -> bool:
	if script_resource == null:
		failures.append("Missing script resource: %s" % script_name)
		return false
	if not script_resource.can_instantiate():
		failures.append("Script failed to compile or instantiate: %s" % script_name)
		return false
	return true
