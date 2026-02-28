extends Node2D

const FUEL_DRAIN_PER_SECOND := 11.0
const REFUEL_PER_SECOND := 38.0
const REFUEL_RECT := Rect2(Vector2(15, 170), Vector2(130, 260))
const BOLT_SPAWN_OFFSET := Vector2(22, 0)
const BOMB_COOLDOWN := 1.5
const BOMB_RADIUS := 145.0
const ENEMY_SPAWN_INTERVAL := 1.3
const ENEMY_SPAWN_X := 1060.0
const ENEMY_SPAWN_Y_MIN := 130.0
const ENEMY_SPAWN_Y_MAX := 530.0
const PLAYER_HIT_RADIUS := 16.0
const LASER_BOLT_SCRIPT := preload("res://scripts/laser_bolt.gd")
const BOMB_BLAST_SCRIPT := preload("res://scripts/bomb_blast.gd")
const ENEMY_TARGET_SCRIPT := preload("res://scripts/enemy_target.gd")

@onready var player: PlayerShip = $PlayerShip
@onready var state_label: Label = $CanvasLayer/HUD/StateLabel
@onready var input_label: Label = $CanvasLayer/HUD/InputLabel
@onready var action_label: Label = $CanvasLayer/HUD/ActionLabel
@onready var info_label: Label = $CanvasLayer/HUD/InfoLabel

var game_state := GameState.new()
var last_action_text := "No actions yet"
var bomb_cooldown_remaining := 0.0
var enemy_spawn_remaining := ENEMY_SPAWN_INTERVAL
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	game_state.changed.connect(_update_hud)
	game_state.action_triggered.connect(_on_action_triggered)
	game_state.player_respawned.connect(_on_respawned)
	_update_hud()
	info_label.text = "Enter=start, Esc=pause, Z=fire, X=bomb, R=manual refuel"

func _process(delta: float) -> void:
	bomb_cooldown_remaining = maxf(0.0, bomb_cooldown_remaining - delta)
	_update_info_label()

	if Input.is_action_just_pressed("start"):
		game_state.start_run()
		player.position = Vector2(120, 320)
		_clear_combat_nodes()
		bomb_cooldown_remaining = 0.0
		enemy_spawn_remaining = 0.35

	if Input.is_action_just_pressed("pause"):
		game_state.toggle_pause()

	if game_state.run_started and game_state.is_alive and not game_state.is_paused:
		_update_enemy_spawns(delta)
		if Input.is_action_just_pressed("fire"):
			game_state.register_action("Fire")
			game_state.add_score(10)
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
	var enemy := ENEMY_TARGET_SCRIPT.new()
	enemy.position = Vector2(ENEMY_SPAWN_X, rng.randf_range(ENEMY_SPAWN_Y_MIN, ENEMY_SPAWN_Y_MAX))
	add_child(enemy)

func _update_enemy_spawns(delta: float) -> void:
	enemy_spawn_remaining = maxf(0.0, enemy_spawn_remaining - delta)
	if enemy_spawn_remaining <= 0.0:
		_spawn_enemy()
		enemy_spawn_remaining = ENEMY_SPAWN_INTERVAL

func _try_trigger_bomb() -> void:
	if bomb_cooldown_remaining > 0.0:
		last_action_text = "Bomb cooldown: %.1fs" % bomb_cooldown_remaining
		action_label.text = "Last Action: %s" % last_action_text
		return
	game_state.register_action("Bomb")
	game_state.add_score(25)
	game_state.add_fuel(12.0)
	bomb_cooldown_remaining = BOMB_COOLDOWN
	var blast := BOMB_BLAST_SCRIPT.new()
	blast.position = player.position
	add_child(blast)
	_apply_bomb_hits()

func _apply_bomb_hits() -> void:
	var enemies_hit := 0
	var points_earned := 0
	for enemy_node in get_tree().get_nodes_in_group("enemy_targets"):
		if enemy_node == null or not enemy_node.has_method("apply_hit"):
			continue
		if enemy_node.position.distance_to(player.position) <= BOMB_RADIUS:
			enemies_hit += 1
			points_earned += enemy_node.apply_hit("bomb")
	if points_earned > 0:
		game_state.add_score(points_earned)
		last_action_text = "Bomb hit %d target(s)" % enemies_hit
		action_label.text = "Last Action: %s" % last_action_text

func _update_combat_state() -> void:
	if not game_state.run_started or not game_state.is_alive or game_state.is_paused:
		return

	var enemy_nodes := get_tree().get_nodes_in_group("enemy_targets")
	var bolt_nodes := get_tree().get_nodes_in_group("laser_bolts")

	for enemy_node in enemy_nodes:
		if enemy_node == null or not enemy_node.has_method("apply_hit"):
			continue

		var enemy_hit_radius := float(enemy_node.get("hit_radius"))

		if enemy_node.position.distance_to(player.position) <= (enemy_hit_radius + PLAYER_HIT_RADIUS):
			enemy_node.apply_hit("ship")
			game_state.die()
			last_action_text = "Ship hit by enemy"
			action_label.text = "Last Action: %s" % last_action_text
			return

		for bolt_node in bolt_nodes:
			if bolt_node == null:
				continue
			var bolt_hit_radius := float(bolt_node.get("hit_radius"))
			if bolt_node.position.distance_to(enemy_node.position) <= (bolt_hit_radius + enemy_hit_radius):
				var points := int(enemy_node.apply_hit("laser"))
				if points > 0:
					game_state.add_score(points)
					last_action_text = "Enemy destroyed"
					action_label.text = "Last Action: %s" % last_action_text
				bolt_node.queue_free()
				break

func _set_actor_activity(is_active: bool) -> void:
	for bolt_node in get_tree().get_nodes_in_group("laser_bolts"):
		if bolt_node != null:
			bolt_node.set("is_active", is_active)
	for enemy_node in get_tree().get_nodes_in_group("enemy_targets"):
		if enemy_node != null:
			enemy_node.set("is_active", is_active)

func _clear_combat_nodes() -> void:
	for bolt_node in get_tree().get_nodes_in_group("laser_bolts"):
		bolt_node.queue_free()
	for enemy_node in get_tree().get_nodes_in_group("enemy_targets"):
		enemy_node.queue_free()

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
	info_label.text = "Enter=start, Esc=pause, Z=fire, X=bomb (%.1fs cd), R=manual refuel" % bomb_cooldown_remaining

func _update_input_debug() -> void:
	var pressed_actions: Array[String] = []
	for action in ["move_up", "move_down", "move_left", "move_right", "fire", "bomb", "start", "pause"]:
		if Input.is_action_pressed(action):
			pressed_actions.append(action)
	var pressed_text := "none" if pressed_actions.is_empty() else ", ".join(pressed_actions)
	input_label.text = "Pressed: %s" % pressed_text
