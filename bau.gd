extends StaticBody3D

const GRID_SIZE := Vector2i(4, 4)

@export_range(0, 2) var weapon_slot := 0
@export var gear_items: Array[int] = []

var opened := false
var item_positions: Dictionary[int, Vector2i] = {}
var item_rotations: Dictionary[int, bool] = {}

func _ready() -> void:
	item_positions[weapon_slot] = Vector2i.ZERO
	item_rotations[weapon_slot] = false
	for index in range(gear_items.size()):
		var item := gear_items[index]
		item_positions[item] = Vector2i(2, index * 2)
		item_rotations[item] = false


func open() -> void:
	if opened:
		return
	opened = true
	var motion := create_tween()
	motion.tween_property($Tampa, "rotation:x", -1.65, 0.28).set_trans(Tween.TRANS_QUAD)


func set_loot_meshes(meshes: Array[Mesh]) -> void:
	var preview := $Saque as Node3D
	for child in preview.get_children():
		preview.remove_child(child)
		child.queue_free()
	for index in range(meshes.size()):
		var model := MeshInstance3D.new()
		model.mesh = meshes[index]
		preview.add_child(model)
		model.position.x = (index - (meshes.size() - 1) / 2.0) * 0.72
