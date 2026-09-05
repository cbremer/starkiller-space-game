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
	game.visual_settings_path = OS.get_cache_dir().path_join("starkiller-visual-test-%d.cfg" % OS.get_process_id())
	game.input_bindings_settings_path = game.visual_settings_path + ".input"
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.modern_visuals.set_enabled(false, false)
	check(not game.graphics_button.is_visible_in_tree(), "Graphics switch hidden outside Settings")
	await click_menu_button(game.settings_button)
	check(game.graphics_settings.visible, "Settings opens from title")
	await click_graphics_button()
	check(game.modern_visuals.enabled, "Mouse button switches title screen to modern")
	check(game.graphics_button.text == "Switch to Retro", "Button label offers the other look")
	await capture("modern-title")
	await click_graphics_button()
	check(not game.modern_visuals.enabled, "Mouse button switches back to retro")
	check(game.graphics_button.focus_mode == Control.FOCUS_NONE, "Button leaves keyboard controls available")
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
	check(game.player._sprite.texture.get_size() * game.player._sprite.scale == original.get_size() * original_scale, "Rendered sprite dimensions preserved")
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
	var switch_event := InputEventKey.new()
	switch_event.keycode = KEY_F8
	switch_event.physical_keycode = KEY_F8
	switch_event.pressed = true
	game._handle_key_event(switch_event)
	check(not game.modern_visuals.enabled, "F8 no longer switches graphics during play")
	check(not game.menu_buttons.visible and not game.graphics_settings.visible, "Gameplay has no menu overlay")
	for _iteration in range(20):
		game.modern_visuals.set_enabled(true, false)
		game.modern_visuals.set_enabled(false, false)
	check(game.player._sprite.scale == original_scale, "Repeated switches do not accumulate scale")
	check(game.player._sprite.rotation == 0.0, "Retro restores unbanked ship")
	check(not game.terrain_layer.modern_style, "Retro restores terrain rendering")
	check(not game.modern_visuals.is_processing(), "Retro disables modern environment updates")
	for original_texture in game.modern_visuals.replacements:
		var specimen := Sprite2D.new()
		specimen.texture = original_texture
		specimen.scale = Vector2(1.2, 0.8)
		specimen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		game.add_child(specimen)
		game.modern_visuals.set_enabled(true, false)
		check(specimen.texture.get_size() * specimen.scale == original_texture.get_size() * Vector2(1.2, 0.8), "All actor variants preserve rendered bounds")
		game.modern_visuals.set_enabled(false, false)
		check(specimen.texture == original_texture and specimen.scale == Vector2(1.2, 0.8), "All actor variants restore exactly")
		specimen.queue_free()
	for sector in range(game.stage_segments.size()):
		game.current_segment_index = sector
		game._apply_segment_visuals()
		var profile := []
		for x in [120.0, 500.0, 1000.0, 1800.0]:
			profile.append(Vector2(game._terrain_height_at(x), game._ceiling_height_at(x)))
		game.modern_visuals.set_enabled(true, false)
		for index in range(profile.size()):
			var x: float = [120.0, 500.0, 1000.0, 1800.0][index]
			check(profile[index] == Vector2(game._terrain_height_at(x), game._ceiling_height_at(x)), "Every biome preserves ceiling and terrain collision")
		game.modern_visuals.set_enabled(false, false)
	game.current_segment_index = 0
	game._apply_segment_visuals()
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
	check(game.is_pause_settings_open, "Pause option opens Settings")
	await click_graphics_button()
	check(game.modern_visuals.enabled, "Settings button changes mode while paused")
	await click_menu_button(game.settings_back)
	check(not game.graphics_settings.visible, "Back closes Settings")
	check(game.game_state.is_paused, "Graphics menu preserves pause")
	var cfg := ConfigFile.new()
	check(cfg.load(game.modern_visuals.settings_path) == OK, "Mode saved")
	check(cfg.get_value("visuals", "mode", "") == "modern", "Saved mode correct")
	var reloaded = load("res://scenes/Main.tscn").instantiate()
	reloaded.visual_settings_path = game.visual_settings_path
	reloaded.input_bindings_settings_path = game.input_bindings_settings_path
	root.add_child(reloaded)
	check(reloaded.modern_visuals.enabled, "Modern preference restores in a fresh game scene")
	reloaded.queue_free()
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
	# Allow the audio mixer to release stopped playback references before shutdown.
	await create_timer(0.1).timeout
	print("Presentation integration: %d failures" % failures)
	quit(0 if failures == 0 else 1)

func capture(label: String) -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			await RenderingServer.frame_post_draw
			var folder := arg.trim_prefix("--capture-dir=")
			DirAccess.make_dir_recursive_absolute(folder)
			root.get_texture().get_image().save_png(folder.path_join(label + ".png"))

func click_graphics_button() -> void:
	await click_menu_button(game.graphics_button)

func click_menu_button(button: Button) -> void:
	# Headless windows do not route pointer hits; GPU runs exercise real mouse input.
	if DisplayServer.get_name() == "headless":
		button.pressed.emit()
		await process_frame
		return
	var center: Vector2 = button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = center
	root.push_input(motion)
	for down in [true, false]:
		var click := InputEventMouseButton.new()
		click.position = center
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		root.push_input(click)
		await process_frame
