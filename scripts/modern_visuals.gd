extends Node
## Presentation only: no gameplay RNG, hitboxes, movement, or spawn changes.
const RETRO := preload("res://scripts/placeholder_textures.gd")
var settings_path := "user://visual_settings.cfg"
var enabled := false
var replacements: Dictionary = {}
var world: Node2D
var atmosphere: ColorRect
var terrain_material: ShaderMaterial
var original_materials: Dictionary = {}

func setup(game: Node2D) -> void:
	world = game
	_build_textures()
	terrain_material = ShaderMaterial.new()
	terrain_material.shader = preload("res://assets/modern/terrain.gdshader")
	for layer in [world.terrain_layer, world.ceiling_layer]:
		original_materials[layer] = layer.material
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
	if atmosphere != null and enabled:
		atmosphere.size = world.get_viewport_rect().size
		atmosphere.material.set_shader_parameter("travel", world.run_distance)
		atmosphere.material.set_shader_parameter("sector", float(world.current_segment_index))

func set_enabled(value: bool, persist := true) -> void:
	enabled = value
	if world == null:
		return
	atmosphere.visible = enabled
	atmosphere.size = world.get_viewport_rect().size
	_apply_tree(world)
	for layer in original_materials:
		layer.material = terrain_material if enabled else original_materials[layer]
	if persist:
		var config := ConfigFile.new()
		config.set_value("visuals", "mode", "modern" if enabled else "retro")
		if config.save(settings_path) != OK:
			push_warning("Could not save visual mode; it remains active for this session.")

func _node_added(node: Node) -> void:
	if node is Sprite2D:
		_apply_sprite.call_deferred(weakref(node))

func _apply_tree(node: Node) -> void:
	if node is Sprite2D:
		_apply_sprite(weakref(node))
	for child in node.get_children():
		_apply_tree(child)

func _apply_sprite(reference: WeakRef) -> void:
	var sprite = reference.get_ref()
	if sprite == null or not world.is_ancestor_of(sprite):
		return
	if not sprite.has_meta("retro_texture"):
		if not replacements.has(sprite.texture):
			return
		sprite.set_meta("retro_texture", sprite.texture)
		sprite.set_meta("retro_filter", sprite.texture_filter)
	var original: Texture2D = sprite.get_meta("retro_texture")
	sprite.texture = replacements[original] if enabled else original
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if enabled else sprite.get_meta("retro_filter")

func _register(original: Texture2D, body: String, color: String) -> void:
	var size := original.get_size()
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d"><defs><linearGradient id="h" x2="0.2" y2="1"><stop stop-color="#ecf8ff"/><stop offset=".35" stop-color="%s"/><stop offset=".55" stop-color="#344b65"/><stop offset=".8" stop-color="#182236"/><stop offset="1" stop-color="#7291ac"/></linearGradient><radialGradient id="g" cx=".35" cy=".25"><stop stop-color="#ffffff"/><stop offset=".35" stop-color="%s"/><stop offset="1" stop-color="#12233d"/></radialGradient></defs>%s</svg>' % [size.x * 4, size.y * 4, size.x, size.y, color, color, body]
	var image := Image.new()
	if image.load_svg_from_string(svg) != OK:
		push_error("Modern texture generation failed")
		return
	var texture := ImageTexture.create_from_image(image)
	texture.set_size_override(Vector2i(size))
	replacements[original] = texture

func _build_textures() -> void:
	_register(RETRO.ship_texture(), '<path d="M9 19 L22 15 L19 7 L35 15 L55 20 L35 25 L19 33 L22 25 L9 22Z" fill="url(#h)" stroke="#90ddff" stroke-width=".6"/><path d="M18 20 L43 20 L28 23Z" fill="#0a243e"/><ellipse cx="33" cy="18" rx="6" ry="2.5" fill="url(#g)"/><path d="M9 19 L3 20 L9 22Z" fill="#67e8ff"/><path d="M22 10 L27 16 M22 29 L27 24" stroke="#e7faff" stroke-width=".6"/>', '#48c4ed')
	var shapes := {
		"raider": 'M8 20 L25 8 L47 20 L26 32Z',
		"cutter": 'M6 20 L20 13 L37 13 L50 20 L38 25 L17 25Z',
		"binder": 'M8 20 L16 11 L24 17 L34 17 L41 11 L47 20 L40 29 L33 23 L24 23 L16 29Z',
		"interceptor": 'M10 12 L26 19 L27 8 L32 8 L33 19 L46 12 L37 29 L20 29Z'
	}
	var colors := {"raider": "#ff795d", "cutter": "#9bddff", "binder": "#cb89ff", "interceptor": "#ef9973"}
	for variant in shapes:
		_register(RETRO.enemy_air_texture_variant(variant), '<path d="%s" fill="url(#h)" stroke="%s" stroke-width=".6"/><ellipse cx="28" cy="18" rx="5" ry="3" fill="url(#g)"/><path d="M17 23 L26 25 L37 22" fill="none" stroke="#fbb270" stroke-width=".6"/>' % [shapes[variant], colors[variant]], colors[variant])
	for variant in ["walker", "turret", "crawler"]:
		var body := '<rect x="9" y="22" width="34" height="10" rx="3" fill="url(#h)"/><path d="M15 23 L18 13 L35 13 L38 23Z" fill="url(#h)"/><rect x="25" y="12" width="19" height="3" rx="1" fill="#dae6e9"/><circle cx="25" cy="18" r="3" fill="url(#g)"/>'
		if variant == "crawler":
			body += '<path d="M12 28 L9 34 M21 28 L18 34 M32 28 L35 34 M40 28 L44 34" stroke="#b0d7d0" stroke-width="2"/>'
		elif variant == "walker":
			body += '<path d="M14 28 L12 34 L18 34 M37 28 L40 34 L34 34" fill="none" stroke="#a8b9cd" stroke-width="2"/>'
		_register(RETRO.enemy_ground_texture_variant(variant), body, '#d19467' if variant != 'crawler' else '#6abca6')
	_register(RETRO.fuel_tank_texture(), '<rect x="6" y="9" width="20" height="34" rx="5" fill="url(#h)"/><rect x="10" y="3" width="12" height="8" rx="2" fill="url(#g)"/><rect x="11" y="17" width="10" height="17" rx="2" fill="#0c392e"/><path d="M16 19 L13 26 L17 26 L15 32 L21 23 L17 23Z" fill="#8fffc2"/>', '#99e6ba')
	_register(RETRO.bomb_texture(), '<circle cx="8" cy="8" r="6" fill="url(#g)"/><path d="M3 8 L13 8" stroke="#ffdc74" stroke-width="1"/>', '#f7b94c')
	_register(RETRO.laser_bolt_texture(), '<rect x="2" y="1" width="28" height="6" rx="3" fill="url(#g)"/><path d="M5 4 L28 4" stroke="#fff7d4" stroke-width="1.5"/>', '#ffb95d')
