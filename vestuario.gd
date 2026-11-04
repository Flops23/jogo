extends RefCounted

const Items := preload("res://itens.gd")
const BASIC_CLOTH := preload("res://roupa_basica.gdshader")

var layers: Dictionary[int, Array] = {}
var rig: Skeleton3D


func _init(model: Node3D) -> void:
	rig = model.get_node("Rig/Skeleton3D")
	_apply_basic_cloth(model)
	layers[3] = [model.find_child("Mage_Hat", true, false)]
	layers[5] = [model.find_child("Mage_Cape", true, false)]
	layers[4] = [_attach("hand.l", _ring(), Vector3(0.868, 1.11, 0.01), Vector3(0, 0, PI / 2.0))]
	layers[8] = [_attach("chest", Items.gear_mesh(8), Vector3(0, 1.10, 0.385), Vector3.ZERO, 0.54)]
	layers[6] = []
	layers[7] = []
	for side in ["l", "r"]:
		var x := 0.17 if side == "l" else -0.17
		layers[6].append(_attach("foot." + side, _boot(), Vector3(x, 0.09, 0.06)))
		layers[7].append(_attach("upperleg." + side, _trouser_leg(0.26, 0.136, 0.15), Vector3(x, 0.406, 0.0)))
		layers[7].append(_attach("lowerleg." + side, _trouser_leg(0.14, 0.125, 0.13), Vector3(x, 0.238, 0.0)))
	sync({})


func sync(equipment: Dictionary) -> bool:
	var changed := false
	for item in layers:
		var equipped := equipment.has(item)
		for mesh in layers[item]:
			if mesh.visible != equipped:
				mesh.visible = equipped
				changed = true
	return changed


func _apply_basic_cloth(model: Node3D) -> void:
	var body := model.find_child("Mage_Body", true, false) as MeshInstance3D
	var original := body.mesh.surface_get_material(0) as StandardMaterial3D
	var cloth := ShaderMaterial.new()
	cloth.shader = BASIC_CLOTH
	cloth.set_shader_parameter("atlas", original.albedo_texture)
	for part in ["Mage_Body", "Mage_ArmRight", "Mage_ArmLeft", "Mage_LegRight", "Mage_LegLeft"]:
		var mesh := model.find_child(part, true, false) as MeshInstance3D
		mesh.material_override = cloth


func _attach(bone: String, mesh: Mesh, rest_position: Vector3, angles := Vector3.ZERO, size_factor := 1.0) -> MeshInstance3D:
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = bone
	rig.add_child(attachment)
	var piece := MeshInstance3D.new()
	piece.mesh = mesh
	var basis := Basis.from_euler(angles).scaled(Vector3.ONE * size_factor)
	var rest := rig.get_bone_global_rest(rig.find_bone(bone))
	attachment.add_child(piece)
	piece.transform = rest.affine_inverse() * Transform3D(basis, rest_position)
	return piece


func _ring() -> TorusMesh:
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.049
	mesh.outer_radius = 0.065
	mesh.material = _material(Color("#daa949"))
	return mesh


func _boot() -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.255, 0.18, 0.42)
	mesh.material = _material(Color("#395a48"))
	return mesh


func _trouser_leg(height: float, top: float, bottom: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.radial_segments = 6
	mesh.rings = 1
	mesh.height = height
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.material = _material(Color("#3d5d82"))
	return mesh


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	return material
