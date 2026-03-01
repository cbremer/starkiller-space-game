extends RefCounted
class_name PlaceholderTextures

static var _ship_texture: Texture2D
static var _enemy_air_texture: Texture2D
static var _enemy_ground_texture: Texture2D
static var _fuel_tank_texture: Texture2D
static var _bomb_texture: Texture2D
static var _laser_bolt_texture: Texture2D

static func ship_texture() -> Texture2D:
	if _ship_texture == null:
		_ship_texture = _build_ship_texture()
	return _ship_texture

static func enemy_air_texture() -> Texture2D:
	if _enemy_air_texture == null:
		_enemy_air_texture = _build_enemy_air_texture()
	return _enemy_air_texture

static func enemy_ground_texture() -> Texture2D:
	if _enemy_ground_texture == null:
		_enemy_ground_texture = _build_enemy_ground_texture()
	return _enemy_ground_texture

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

static func _build_enemy_air_texture() -> Texture2D:
	var image := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))

	var body_color := Color(0.95, 0.25, 0.23)
	for x in range(6, 43):
		var half_height: int = 18 - int(abs(x - 24))
		if half_height < 0:
			continue
		for y in range(24 - half_height, 25 + half_height):
			image.set_pixel(x, y, body_color)

	_fill_circle(image, Vector2i(24, 24), 7, Color(1.0, 0.86, 0.36))
	image.fill_rect(Rect2i(19, 11, 10, 4), Color(0.78, 0.14, 0.14))
	return ImageTexture.create_from_image(image)

static func _build_enemy_ground_texture() -> Texture2D:
	var image := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))

	image.fill_rect(Rect2i(8, 22, 32, 16), Color(0.35, 0.44, 0.56))
	image.fill_rect(Rect2i(14, 14, 20, 10), Color(0.89, 0.34, 0.22))
	for i in range(11):
		image.set_pixel(24 + i, 13 - int(round(float(i) * 0.5)), Color(1.0, 0.84, 0.32))
	return ImageTexture.create_from_image(image)

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
