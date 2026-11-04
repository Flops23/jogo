extends Node3D

var item := -1
var rotated := false
var collected := false


func show_mesh(mesh: Mesh) -> void:
	var model := MeshInstance3D.new()
	model.mesh = mesh
	model.scale = Vector3.ONE * 0.48
	model.position.y = 0.07 - mesh.get_aabb().position.y * 0.48
	add_child(model)
