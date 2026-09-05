extends Node
## Presentation only: no gameplay RNG, hitboxes, movement, or spawn changes.
signal style_changed

const TEXTURES := preload("res://scripts/modern_textures.gd")
var settings_path := "user://visual_settings.cfg"
var enabled := false
var replacements: Dictionary = {}
var world: Node2D
var atmosphere: ColorRect
var _last_size := Vector2.ZERO
var _last_travel := -1.0
var _last_sector := -1

func setup(game: Node2D) -> void:
	world = game
	replacements = TEXTURES.replacements()
	atmosphere = ColorRect.new()
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := preload("res://assets/modern/atmosphere.gdshader")
	var mat := ShaderMaterial.new()
	mat.shader = shader
	atmosphere.material = mat
	world.add_child(atmosphere)
	world.move_child(atmosphere, 1)
	get_tree().node_added.connect(_node_added)
	var config := ConfigFile.new()
	if config.load(settings_path) == OK:
		enabled = config.get_value("visuals", "mode", "retro") == "modern"
	set_enabled(enabled, false)

func _process(_delta: float) -> void:
	_sync_environment()

func _sync_environment() -> void:
	var size := world.get_viewport_rect().size
	if size != _last_size:
		_last_size = size
		atmosphere.size = size
		atmosphere.material.set_shader_parameter("aspect", size.x / maxf(size.y, 1.0))
	if world.run_distance != _last_travel:
		_last_travel = world.run_distance
		atmosphere.material.set_shader_parameter("travel", _last_travel)
	if world.current_segment_index != _last_sector:
		_last_sector = world.current_segment_index
		atmosphere.material.set_shader_parameter("sector", float(_last_sector))

func set_enabled(value: bool, persist := true) -> void:
	enabled = value
	if world == null:
		return
	atmosphere.visible = enabled
	set_process(enabled)
	_sync_environment()
	_apply_tree(world)
	style_changed.emit()
	if persist:
		var config := ConfigFile.new()
		config.load(settings_path)
		config.set_value("visuals", "mode", "modern" if enabled else "retro")
		if config.save(settings_path) != OK:
			push_warning("Could not save visual mode; it remains active for this session.")

func _node_added(node: Node) -> void:
	if node is Sprite2D or node.has_method("set_modern_style"):
		_apply_node.call_deferred(weakref(node))

func _apply_tree(node: Node) -> void:
	_apply_node(weakref(node))
	for child in node.get_children():
		_apply_tree(child)

func _apply_node(reference: WeakRef) -> void:
	var node = reference.get_ref()
	if node == null or not world.is_ancestor_of(node):
		return
	if node.has_method("set_modern_style"):
		node.set_modern_style(enabled)
	if not node is Sprite2D:
		return
	var sprite: Sprite2D = node
	if not sprite.has_meta("retro_texture"):
		if not replacements.has(sprite.texture):
			return
		sprite.set_meta("retro_texture", sprite.texture)
		sprite.set_meta("retro_filter", sprite.texture_filter)
		sprite.set_meta("retro_scale", sprite.scale)
	var original: Texture2D = sprite.get_meta("retro_texture")
	sprite.texture = replacements[original] if enabled else original
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if enabled else sprite.get_meta("retro_filter")
	sprite.scale = sprite.get_meta("retro_scale") * (original.get_size() / sprite.texture.get_size())
