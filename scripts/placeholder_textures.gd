extends RefCounted
class_name PlaceholderTextures

static var _ship_texture: Texture2D
static var _enemy_air_texture: Texture2D
static var _enemy_ground_texture: Texture2D
static var _enemy_air_variants: Dictionary = {}
static var _enemy_ground_variants: Dictionary = {}
static var _fuel_tank_texture: Texture2D
static var _bomb_texture: Texture2D
static var _laser_bolt_texture: Texture2D

static func ship_texture() -> Texture2D:
	if _ship_texture == null:
		_ship_texture = _build_ship_texture()
	return _ship_texture

static func enemy_air_texture() -> Texture2D:
	return enemy_air_texture_variant("raider")

static func enemy_air_texture_variant(variant: String) -> Texture2D:
	var key := variant.to_lower()
	if _enemy_air_variants.has(key):
		return _enemy_air_variants[key]
	var texture := _build_enemy_air_texture(key)
	_enemy_air_variants[key] = texture
	return texture

static func enemy_ground_texture() -> Texture2D:
	return enemy_ground_texture_variant("walker")

static func enemy_ground_texture_variant(variant: String) -> Texture2D:
	var key := variant.to_lower()
	if _enemy_ground_variants.has(key):
		return _enemy_ground_variants[key]
	var texture := _build_enemy_ground_texture(key)
	_enemy_ground_variants[key] = texture
	return texture

static func fuel_tank_texture() -> Texture2D:
	if _fuel_tank_texture == null:
		_fuel_tank_texture = _build_fuel_tank_texture()
	return _fuel_tank_texture

static func bomb_texture() -> Texture2D:
	if _bomb_texture == null:
		_bomb_texture = _build_bomb_texture()
	return _bomb_texture

static func laser_bolt_texture() -> Texture2D:
	if _laser_bolt_texture == null:
		_laser_bolt_texture = _build_laser_bolt_texture()
	return _laser_bolt_texture

static func _build_ship_texture() -> Texture2D:
	var image := Image.create(64, 40, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))

	var hull_color := Color(0.22, 0.86, 0.98)
	for x in range(12, 55):
		var t := float(x - 12) / 43.0
		var half_height := int(round(12.0 * (1.0 - t)))
		for y in range(20 - half_height, 21 + half_height):
			image.set_pixel(x, y, hull_color)

	image.fill_rect(Rect2i(8, 18, 8, 4), Color(1.0, 0.62, 0.24))
	image.fill_rect(Rect2i(18, 19, 22, 2), Color(0.05, 0.3, 0.42))
	_fill_circle(image, Vector2i(36, 20), 4, Color(0.7, 0.97, 1.0))
	return ImageTexture.create_from_image(image)

static func _build_enemy_air_texture(variant: String) -> Texture2D:
	var image := Image.create(56, 40, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	match variant:
		"cutter":
			_draw_cutter(image)
		"binder":
			_draw_binder(image)
		"interceptor":
			_draw_interceptor(image)
		_:
			_draw_raider(image)
	return ImageTexture.create_from_image(image)

static func _draw_raider(image: Image) -> void:
	var c := Color(0.93, 0.24, 0.24)
	for x in range(8, 49):
		var half_h := maxi(1, 13 - abs(x - 26) / 2)
		for y in range(20 - half_h, 20 + half_h):
			image.set_pixel(x, y, c)
	image.fill_rect(Rect2i(24, 10, 8, 6), Color(0.98, 0.80, 0.32))

static func _draw_cutter(image: Image) -> void:
	var body := Color(0.77, 0.85, 0.92)
	image.fill_rect(Rect2i(10, 16, 34, 9), body)
	image.fill_rect(Rect2i(6, 19, 8, 3), body)
	image.fill_rect(Rect2i(42, 19, 8, 3), body)
	image.fill_rect(Rect2i(20, 12, 14, 4), Color(0.45, 0.78, 0.98))

static func _draw_binder(image: Image) -> void:
	var purple := Color(0.76, 0.45, 0.92)
	_fill_circle(image, Vector2i(18, 20), 8, purple)
	_fill_circle(image, Vector2i(37, 20), 8, purple)
	image.fill_rect(Rect2i(18, 18, 20, 4), Color(0.96, 0.78, 0.34))

static func _draw_interceptor(image: Image) -> void:
	var steel := Color(0.58, 0.66, 0.74)
	for i in range(18):
		image.fill_rect(Rect2i(10 + i, 20 - i / 2, 1, i), steel)
		image.fill_rect(Rect2i(46 - i, 20 - i / 2, 1, i), steel)
	image.fill_rect(Rect2i(24, 8, 8, 8), Color(1.0, 0.36, 0.26))

static func _build_enemy_ground_texture(variant: String) -> Texture2D:
	var image := Image.create(52, 40, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	match variant:
		"turret":
			_draw_ground_turret(image)
		"crawler":
			_draw_ground_crawler(image)
		_:
			_draw_ground_walker(image)
	return ImageTexture.create_from_image(image)

static func _draw_ground_walker(image: Image) -> void:
	image.fill_rect(Rect2i(9, 18, 34, 13), Color(0.36, 0.44, 0.56))
	image.fill_rect(Rect2i(15, 10, 22, 9), Color(0.92, 0.33, 0.21))
	image.fill_rect(Rect2i(23, 6, 12, 4), Color(0.98, 0.84, 0.32))

static func _draw_ground_turret(image: Image) -> void:
	image.fill_rect(Rect2i(10, 22, 32, 11), Color(0.34, 0.38, 0.44))
	_fill_circle(image, Vector2i(26, 19), 7, Color(0.68, 0.72, 0.76))
	image.fill_rect(Rect2i(26, 14, 18, 3), Color(0.92, 0.51, 0.24))

static func _draw_ground_crawler(image: Image) -> void:
	image.fill_rect(Rect2i(8, 20, 36, 8), Color(0.24, 0.54, 0.48))
	for x in range(10, 41, 6):
		image.fill_rect(Rect2i(x, 29, 3, 5), Color(0.74, 0.82, 0.86))
	image.fill_rect(Rect2i(14, 14, 20, 6), Color(0.95, 0.68, 0.32))

static func _build_fuel_tank_texture() -> Texture2D:
	var image := Image.create(32, 48, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))

	image.fill_rect(Rect2i(6, 9, 20, 34), Color(0.86, 0.91, 0.83))
	image.fill_rect(Rect2i(10, 3, 12, 8), Color(0.3, 0.72, 0.36))
	image.fill_rect(Rect2i(11, 19, 10, 3), Color(0.17, 0.26, 0.18))
	return ImageTexture.create_from_image(image)

static func _build_bomb_texture() -> Texture2D:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	_fill_circle(image, Vector2i(8, 8), 6, Color(0.98, 0.82, 0.18))
	_fill_circle(image, Vector2i(8, 8), 3, Color(0.38, 0.14, 0.08))
	return ImageTexture.create_from_image(image)

static func _build_laser_bolt_texture() -> Texture2D:
	var image := Image.create(32, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	image.fill_rect(Rect2i(2, 1, 28, 6), Color(1.0, 0.94, 0.42))
	image.fill_rect(Rect2i(6, 2, 18, 4), Color(1.0, 0.48, 0.16))
	return ImageTexture.create_from_image(image)

static func _fill_circle(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	var radius_squared := radius * radius
	for x in range(center.x - radius, center.x + radius + 1):
		if x < 0 or x >= image.get_width():
			continue
		for y in range(center.y - radius, center.y + radius + 1):
			if y < 0 or y >= image.get_height():
				continue
			var dx := x - center.x
			var dy := y - center.y
			if dx * dx + dy * dy <= radius_squared:
				image.set_pixel(x, y, color)
