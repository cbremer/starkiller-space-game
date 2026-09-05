extends SceneTree
## Real scene coverage. Optional -- --capture-dir=/absolute/path saves GPU frames.
var failures := 0
var game

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.modern_visuals.settings_path = OS.get_cache_dir().path_join("starkiller-visual-test-%d.cfg" % OS.get_process_id())
	game.modern_visuals.set_enabled(false, false)
	game._start_run()
	game.player.set_physics_process(false)
	game.rng.seed = 42
	game._spawn_enemy()
	game._spawn_fuel_tank()
	await process_frame
	game._enemy_nodes[0].position.x = 1350.0
	game._fuel_tank_nodes[0].position.x = 1050.0
	game._fuel_tank_nodes[0].is_active = false
	for enemy in game._enemy_nodes:
		enemy.is_active = false
	var original = game.player._sprite.texture
	var original_scale = game.player._sprite.scale
	var before = [game.game_state.fuel, game.game_state.score, game.game_state.lives, game.run_distance, game.rng.state, game.player.position]
	var terrain_height = game._terrain_height_at(500.0)
	await capture("retro")
	game.modern_visuals.set_enabled(true, false)
	await process_frame
	check(game.player._sprite.texture != original, "Modern replaces ship texture")
	check(game.player._sprite.texture.get_size() == original.get_size(), "Logical sprite size preserved")
	check(game.player._sprite.scale == original_scale, "Sprite scale preserved")
	check(before == [game.game_state.fuel, game.game_state.score, game.game_state.lives, game.run_distance, game.rng.state, game.player.position], "Switch preserves gameplay and RNG")
	check(game._terrain_height_at(500.0) == terrain_height, "Terrain collision remains identical")
	await capture("modern")
	game._spawn_bolt()
	await process_frame
	await process_frame
	var bolt = game._laser_bolt_nodes.back()
	check(bolt._sprite.has_meta("retro_texture"), "New spawns use selected mode")
	game.modern_visuals.set_enabled(false, false)
	check(game.player._sprite.texture == original, "Retro texture restored exactly")
	check(game.player._sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Retro filter restored")
	game.game_state.add_score(1000)
	var near_enemy = game.ENEMY_TARGET_SCRIPT.new()
	near_enemy.position = game.player.position + Vector2(80, 0)
	near_enemy.target_type = "ground"
	game.add_child(near_enemy)
	game._track_spawned_node(near_enemy, game.TrackedNodeList.ENEMIES)
	var far_enemy = game.ENEMY_TARGET_SCRIPT.new()
	far_enemy.position = game.player.position + Vector2(600, 0)
	game.add_child(far_enemy)
	game._track_spawned_node(far_enemy, game.TrackedNodeList.ENEMIES)
	game.stage_transition_remaining = 1.0
	game._try_trigger_nova()
	check(game.game_state.nova_charge == 100.0, "Transition blocks Nova without spending")
	game.stage_transition_remaining = 0.0
	game._try_trigger_nova()
	check(near_enemy.is_queued_for_deletion(), "Nova destroys nearby ground target")
	check(not far_enemy.is_queued_for_deletion(), "Nova preserves distant target")
	check(game.game_state.nova_charge == 0.0, "Nova consumes charge without kill feedback charging")
	game.game_state.toggle_pause()
	var event := InputEventKey.new()
	event.keycode = KEY_5
	event.pressed = true
	game._handle_key_event(event)
	check(game.modern_visuals.enabled, "Pause graphics menu toggles mode")
	check(game.game_state.is_paused, "Graphics menu preserves pause")
	var cfg := ConfigFile.new()
	check(cfg.load(game.modern_visuals.settings_path) == OK, "Mode saved")
	check(cfg.get_value("visuals", "mode", "") == "modern", "Saved mode correct")
	game.is_remap_menu_open = true
	game._handle_key_event(event)
	check(game.modern_visuals.enabled, "Graphics shortcut does not interrupt remap menu")
	game.is_remap_menu_open = false
	game.input_bindings_settings_path = game.modern_visuals.settings_path + ".input"
	var input_cfg := ConfigFile.new()
	input_cfg.set_value("audio", "volume", 0.4)
	input_cfg.save(game.input_bindings_settings_path)
	game._set_single_key_binding("ultimate", KEY_V)
	game._save_input_bindings()
	game._set_single_key_binding("ultimate", KEY_C)
	game._load_input_bindings()
	check(game._primary_action_keycode("ultimate") == KEY_V, "Nova remap survives reload")
	input_cfg.load(game.input_bindings_settings_path)
	check(input_cfg.get_value("audio", "volume", 0.0) == 0.4, "Binding save preserves unrelated settings")
	DirAccess.remove_absolute(game.input_bindings_settings_path)
	DirAccess.remove_absolute(game.modern_visuals.settings_path)
	game.queue_free()
	await process_frame
	print("Presentation integration: %d failures" % failures)
	quit(0 if failures == 0 else 1)

func capture(label: String) -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			await RenderingServer.frame_post_draw
			var folder := arg.trim_prefix("--capture-dir=")
			DirAccess.make_dir_recursive_absolute(folder)
			root.get_texture().get_image().save_png(folder.path_join(label + ".png"))
