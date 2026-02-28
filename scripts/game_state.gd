extends RefCounted
class_name GameState

signal changed
signal action_triggered(action_name: String)
signal player_died
signal player_respawned

const STARTING_LIVES := 3
const MAX_FUEL := 100.0

var score: int = 0
var lives: int = STARTING_LIVES
var fuel: float = MAX_FUEL
var stage_id: int = 1
var is_alive: bool = false
var is_paused: bool = false
var run_started: bool = false

var respawn_cooldown := 1.5
var _respawn_remaining := 0.0

func start_run() -> void:
	score = 0
	lives = STARTING_LIVES
	fuel = MAX_FUEL
	stage_id = 1
	is_alive = true
	is_paused = false
	run_started = true
	_respawn_remaining = 0.0
	changed.emit()

func toggle_pause() -> void:
	if not run_started:
		return
	is_paused = not is_paused
	changed.emit()

func register_action(action_name: String) -> void:
	action_triggered.emit(action_name)

func add_score(points: int) -> void:
	score += points
	changed.emit()

func add_fuel(amount: float) -> void:
	fuel = clamp(fuel + amount, 0.0, MAX_FUEL)
	changed.emit()

func set_stage(new_stage_id: int) -> void:
	stage_id = max(new_stage_id, 1)
	changed.emit()

func drain_fuel(amount: float) -> void:
	if not run_started or is_paused or not is_alive:
		return
	fuel = maxf(0.0, fuel - amount)
	if fuel <= 0.0:
		die()
	else:
		changed.emit()

func die() -> void:
	if not is_alive:
		return
	is_alive = false
	lives -= 1
	_respawn_remaining = respawn_cooldown
	player_died.emit()
	changed.emit()

func update(delta: float) -> void:
	if not run_started or is_paused:
		return
	if not is_alive and lives > 0:
		_respawn_remaining = maxf(0.0, _respawn_remaining - delta)
		if _respawn_remaining <= 0.0:
			respawn()

func respawn() -> void:
	if lives < 0:
		return
	is_alive = true
	fuel = MAX_FUEL
	player_respawned.emit()
	changed.emit()

func status_text() -> String:
	if not run_started:
		return "Waiting for start"
	if lives < 0:
		return "Game Over"
	if is_alive:
		return "Alive"
	return "Respawning in %.1fs" % _respawn_remaining
