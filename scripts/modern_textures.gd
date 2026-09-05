extends RefCounted
## Imported artwork: no runtime SVG rasterization or GPU readback.
const RETRO := preload("res://scripts/placeholder_textures.gd")

static func replacements() -> Dictionary:
	return {
		RETRO.ship_texture(): preload("res://assets/modern/actors/ship.svg"),
		RETRO.enemy_air_texture_variant("raider"): preload("res://assets/modern/actors/raider.svg"),
		RETRO.enemy_air_texture_variant("cutter"): preload("res://assets/modern/actors/cutter.svg"),
		RETRO.enemy_air_texture_variant("binder"): preload("res://assets/modern/actors/binder.svg"),
		RETRO.enemy_air_texture_variant("interceptor"): preload("res://assets/modern/actors/interceptor.svg"),
		RETRO.enemy_ground_texture_variant("walker"): preload("res://assets/modern/actors/walker.svg"),
		RETRO.enemy_ground_texture_variant("turret"): preload("res://assets/modern/actors/turret.svg"),
		RETRO.enemy_ground_texture_variant("crawler"): preload("res://assets/modern/actors/crawler.svg"),
		RETRO.fuel_tank_texture(): preload("res://assets/modern/actors/fuel.svg"),
		RETRO.bomb_texture(): preload("res://assets/modern/actors/bomb.svg"),
		RETRO.laser_bolt_texture(): preload("res://assets/modern/actors/laser.svg"),
	}
