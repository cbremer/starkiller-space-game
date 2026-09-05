extends SceneTree
## Success means the button exits the real process before the failure timer.
var activated := false
var frames_after_activation := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	if not game.quit_button.is_visible_in_tree():
		push_error("Quit button is not visible on title")
		quit(1)
		return
	if "--paused" in OS.get_cmdline_user_args():
		game._start_run()
		game.game_state.toggle_pause()
		if not game.quit_button.is_visible_in_tree():
			push_error("Quit button is not visible while paused")
			quit(1)
			return
	print("Activating Quit Game")
	activated = true
	game.quit_button.pressed.emit()

func _process(_delta: float) -> bool:
	if activated:
		frames_after_activation += 1
		if frames_after_activation > 10:
			push_error("Quit Game did not exit the process")
			quit(1)
	return false
