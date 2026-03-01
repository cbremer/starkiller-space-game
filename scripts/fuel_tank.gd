extends Node2D
class_name FuelTank

const PLACEHOLDER_TEXTURES := preload("res://scripts/placeholder_textures.gd")

@export var speed := 120.0
@export var hit_radius := 14.0
@export var fuel_amount := 26.0
@export_range(0.5, 2.5, 0.05) var sprite_scale := 1.22

var is_active := true
var _sprite: Sprite2D

func _ready() -> void:
	add_to_group("fuel_tanks")
	_sprite = Sprite2D.new()
	_sprite.texture = PLACEHOLDER_TEXTURES.fuel_tank_texture()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2.ONE * sprite_scale
	add_child(_sprite)

func _process(delta: float) -> void:
	if not is_active:
		return
	position.x -= speed * delta
	if position.x < -30.0:
		queue_free()
