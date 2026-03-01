extends Node2D
class_name LaserBolt

const PLACEHOLDER_TEXTURES := preload("res://scripts/placeholder_textures.gd")

@export var speed := 680.0
@export var hit_radius := 10.0
@export var sprite_scale := Vector2(1.28, 1.1)

var is_active := true
var _sprite: Sprite2D

func _ready() -> void:
	add_to_group("laser_bolts")
	_sprite = Sprite2D.new()
	_sprite.texture = PLACEHOLDER_TEXTURES.laser_bolt_texture()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = sprite_scale
	add_child(_sprite)

func _process(delta: float) -> void:
	if not is_active:
		return
	position.x += speed * delta
	if position.x > get_viewport_rect().size.x + 8.0:
		queue_free()
