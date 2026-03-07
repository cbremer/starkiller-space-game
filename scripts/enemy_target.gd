extends Node2D
class_name EnemyTarget

const PLACEHOLDER_TEXTURES := preload("res://scripts/placeholder_textures.gd")

@export var speed := 120.0
@export var hit_radius := 16.0
@export var target_type := "air"
@export var laser_points := 50
@export var bomb_points := 80
@export var air_variant := "raider"
@export var ground_variant := "walker"
@export var is_distant := false
@export_range(0.35, 2.5, 0.05) var air_sprite_scale := 1.18
@export_range(0.8, 1.6, 0.05) var air_sprite_height_scale := 1.1
@export_range(0.35, 2.5, 0.05) var ground_sprite_scale := 1.24

var is_active := true
var _destroyed := false
var _sprite: Sprite2D

func _ready() -> void:
	add_to_group("enemy_targets")
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	_update_visual()

func _process(delta: float) -> void:
	if not is_active:
		return
	position.x -= speed * delta
	if position.x < -48.0:
		queue_free()

func apply_hit(weapon: String) -> int:
	if _destroyed:
		return 0
	if target_type == "ground" and weapon != "bomb":
		return 0
	_destroyed = true
	queue_free()
	if weapon == "bomb":
		return bomb_points
	return laser_points

func _update_visual() -> void:
	if _sprite == null:
		return
	if target_type == "ground":
		_sprite.texture = PLACEHOLDER_TEXTURES.enemy_ground_texture_variant(ground_variant)
		_sprite.scale = Vector2.ONE * ground_sprite_scale
		_sprite.modulate = Color(1.0, 1.0, 1.0, 0.78 if is_distant else 1.0)
		return

	_sprite.texture = PLACEHOLDER_TEXTURES.enemy_air_texture_variant(air_variant)
	var scale_mult := 0.68 if is_distant else 1.0
	_sprite.scale = Vector2(air_sprite_scale, air_sprite_scale * air_sprite_height_scale) * scale_mult
	_sprite.modulate = Color(0.86, 0.92, 1.0, 0.62) if is_distant else Color.WHITE
