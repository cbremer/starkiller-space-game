extends RefCounted
class_name VfxMaterials

static var _additive_material: CanvasItemMaterial

static func additive_material() -> CanvasItemMaterial:
	if _additive_material == null:
		_additive_material = CanvasItemMaterial.new()
		_additive_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _additive_material
