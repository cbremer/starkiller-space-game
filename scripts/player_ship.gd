extends Node2D
class_name PlayerShip

const PLACEHOLDER_TEXTURES := preload("res://scripts/placeholder_textures.gd")
const ENGINE_BLOOM_TEXTURE := preload("res://assets/concept_samples/vfx/engine_bloom.svg")
const ADDITIVE_CANVAS_MATERIAL := preload("res://scripts/vfx_materials.gd")

@export var speed := 300.0
@export var horizontal_margin := 40.0
@export var top_margin := 116.0
@export var bottom_margin := 28.0
@export_range(0.5, 2.5, 0.05) var sprite_scale := 1.25

var input_vector := Vector2.ZERO
var _engine_bloom: Sprite2D
var _sprite: Sprite2D

func _ready() -> void:
	_engine_bloom = Sprite2D.new()
	_engine_bloom.texture = ENGINE_BLOOM_TEXTURE
	_engine_bloom.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_engine_bloom.material = ADDITIVE_CANVAS_MATERIAL.additive_material()
	_engine_bloom.position = Vector2(-18.0, 0.0)
	_engine_bloom.scale = Vector2(0.062, 0.046)
	_engine_bloom.modulate = Color(0.64, 0.9, 1.0, 0.18)
	add_child(_engine_bloom)

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
	_update_engine_bloom(delta)

func _update_engine_bloom(delta: float) -> void:
	if _engine_bloom == null:
		return
	var thrust := clampf(input_vector.length(), 0.0, 1.0)
	var pulse := 0.92 + 0.08 * sin(Time.get_ticks_msec() / 90.0)
	var target_alpha := 0.10 + thrust * 0.12
	var target_scale := Vector2(0.054 + thrust * 0.012, 0.040 + thrust * 0.010) * pulse
	_engine_bloom.modulate.a = move_toward(_engine_bloom.modulate.a, target_alpha, delta * 2.8)
	_engine_bloom.scale = _engine_bloom.scale.lerp(target_scale, clampf(delta * 8.0, 0.0, 1.0))
