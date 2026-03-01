extends Node2D
class_name BombPayload

const PLACEHOLDER_TEXTURES := preload("res://scripts/placeholder_textures.gd")

@export var velocity := Vector2(145.0, 80.0)
@export var gravity := 620.0
@export var hit_radius := 12.0
@export_range(0.5, 2.5, 0.05) var sprite_scale := 1.28

var is_active := true
var _sprite: Sprite2D

func _ready() -> void:
	add_to_group("bomb_payloads")
	_sprite = Sprite2D.new()
	_sprite.texture = PLACEHOLDER_TEXTURES.bomb_texture()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2.ONE * sprite_scale
	add_child(_sprite)

func _process(delta: float) -> void:
	if not is_active:
		return
	velocity.y += gravity * delta
	position += velocity * delta
	if position.x > get_viewport_rect().size.x + 20.0 or position.x < -40.0 or position.y > get_viewport_rect().size.y + 40.0:
		queue_free()
