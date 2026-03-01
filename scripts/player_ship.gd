extends Node2D
class_name PlayerShip

const PLACEHOLDER_TEXTURES := preload("res://scripts/placeholder_textures.gd")

@export var speed := 300.0
@export var horizontal_margin := 40.0
@export var top_margin := 52.0
@export var bottom_margin := 28.0
@export_range(0.5, 2.5, 0.05) var sprite_scale := 1.25

var input_vector := Vector2.ZERO
var _sprite: Sprite2D

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = PLACEHOLDER_TEXTURES.ship_texture()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2.ONE * sprite_scale
	add_child(_sprite)

func _physics_process(delta: float) -> void:
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()
	position += input_vector * speed * delta

	var viewport_size := get_viewport_rect().size
	var min_x := horizontal_margin
	var max_x := maxf(min_x, viewport_size.x - horizontal_margin)
	var min_y := top_margin
	var max_y := maxf(min_y, viewport_size.y - bottom_margin)

	position = Vector2(
		clampf(position.x, min_x, max_x),
		clampf(position.y, min_y, max_y)
	)
