extends Node2D
class_name LaserBolt

const PLACEHOLDER_TEXTURES := preload("res://scripts/placeholder_textures.gd")
const PLASMA_BEAM_TEXTURE := preload("res://assets/concept_samples/vfx/plasma_beam_strip.svg")
const VFX_MATERIALS := preload("res://scripts/vfx_materials.gd")

@export var speed := 680.0
@export var hit_radius := 10.0
@export var sprite_scale := Vector2(1.28, 1.05)
@export var glow_scale := Vector2(0.078, 0.046)

var is_active := true
var _glow: Sprite2D
var _sprite: Sprite2D

func _ready() -> void:
	add_to_group("laser_bolts")
	_glow = Sprite2D.new()
	_glow.texture = PLASMA_BEAM_TEXTURE
	_glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_glow.material = VFX_MATERIALS.additive_material()
	_glow.scale = glow_scale
	_glow.modulate = Color(1.0, 1.0, 1.0, 0.18)
	add_child(_glow)

	_sprite = Sprite2D.new()
	_sprite.texture = PLACEHOLDER_TEXTURES.laser_bolt_texture()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = sprite_scale
	_sprite.modulate = Color(0.94, 0.98, 1.0, 0.95)
	add_child(_sprite)

func _process(delta: float) -> void:
	if not is_active:
		return
	position.x += speed * delta
	if position.x > get_viewport_rect().size.x + 8.0:
		queue_free()
