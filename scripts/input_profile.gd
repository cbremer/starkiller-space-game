extends RefCounted
## Key profile and validation, independent of menu state and persistence.
const REMAP_ACTIONS: Array[String] = [
	"move_up",
	"move_down",
	"move_left",
	"move_right",
	"fire",
	"bomb",
	"ultimate",
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
	"ultimate": "Nova Burst",
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
	"ultimate": KEY_C,
	"start": KEY_ENTER,
	"pause": KEY_ESCAPE
}

static func _primary_action_keycode(action_name: String) -> int:
	for action_event in InputMap.action_get_events(action_name):
		var key_event := action_event as InputEventKey
		if key_event == null:
			continue
		var keycode := _event_keycode(key_event)
		if _is_supported_binding_keycode(keycode):
			return keycode
	return int(DEFAULT_KEY_BINDINGS.get(action_name, 0))

static func _set_single_key_binding(action_name: String, keycode: int) -> void:
	var safe_keycode := int(keycode)
	if not _is_supported_binding_keycode(safe_keycode):
		return
	InputMap.action_erase_events(action_name)
	var key_event := InputEventKey.new()
	key_event.keycode = safe_keycode
	key_event.physical_keycode = safe_keycode
	InputMap.action_add_event(action_name, key_event)

static func _ensure_safe_remap_bindings() -> void:
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

static func _is_supported_binding_keycode(keycode: int) -> bool:
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

static func _event_keycode(key_event: InputEventKey) -> int:
	if key_event.keycode != 0:
		return key_event.keycode
	return key_event.physical_keycode

static func _keycode_label(keycode: int) -> String:
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
