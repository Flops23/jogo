extends RefCounted

const NAMES := ["Varinha", "Cajado", "Grimório", "Chapéu", "Anel", "Manto", "Botas", "Calças", "Colar"]
const FIRST_GEAR := 3
const SIZES := [
	Vector2i(1, 2), Vector2i(1, 3), Vector2i(2, 2),
	Vector2i(2, 1), Vector2i.ONE, Vector2i(2, 2),
	Vector2i(2, 1), Vector2i(1, 2), Vector2i.ONE,
]
const ATTRIBUTES := ["Mana", "Poder", "Defesa", "Velocidade", "Vida", "Mana"]
const BONUSES := [15.0, 8.0, 10.0, 1.0, 20.0, 10.0]
const COLORS := [
	Color("#65b9ee"), Color("#70d9a3"), Color("#bd9af4"),
	Color("#a293ff"), Color("#f4c76c"), Color("#e584c0"),
	Color("#80d9bb"), Color("#91b5e6"), Color("#ffad83"),
]


static func gear_mesh(item: int) -> ArrayMesh:
	var model := ArrayMesh.new()
	var color: Color = COLORS[item]
	match item:
		3:
			var brim := CylinderMesh.new()
			brim.top_radius = 0.37
			brim.bottom_radius = 0.37
			brim.height = 0.06
			_piece(model, brim, Vector3.ZERO, color.darkened(0.35))
			var cone := CylinderMesh.new()
			cone.top_radius = 0.025
			cone.bottom_radius = 0.22
			cone.height = 0.49
			_piece(model, cone, Vector3.UP * 0.25, color)
		4, 8:
			var loop := TorusMesh.new()
			loop.inner_radius = 0.15 if item == 4 else 0.24
			loop.outer_radius = 0.21 if item == 4 else 0.28
			_piece(model, loop, Vector3.ZERO, Color("#cf963d"), Vector3(PI / 2.0, 0, 0))
			var gem := SphereMesh.new()
			gem.radius = 0.085
			gem.height = 0.17
			_piece(model, gem, Vector3.UP * (0.19 if item == 4 else -0.25), color)
		5:
			var cape := PrismMesh.new()
			cape.size = Vector3(0.55, 0.66, 0.08)
			_piece(model, cape, Vector3.ZERO, color.darkened(0.24))
			_box(model, Vector3(0.26, 0.08, 0.12), Vector3.UP * 0.26, Color("#dcaa61"))
		6:
			for side in [-1.0, 1.0]:
				_box(model, Vector3(0.19, 0.29, 0.20), Vector3(side * 0.13, 0.10, 0), color.darkened(0.3))
				_box(model, Vector3(0.20, 0.11, 0.35), Vector3(side * 0.13, -0.05, -0.07), color)
		7:
			_box(model, Vector3(0.42, 0.18, 0.22), Vector3.UP * 0.18, color)
			for side in [-1.0, 1.0]:
				_box(model, Vector3(0.18, 0.38, 0.19), Vector3(side * 0.12, -0.07, 0), color.darkened(0.22))
	return model


static func _box(model: ArrayMesh, size: Vector3, at: Vector3, color: Color) -> void:
	var box := BoxMesh.new()
	box.size = size
	_piece(model, box, at, color)


static func _piece(model: ArrayMesh, shape: PrimitiveMesh, at: Vector3, color: Color, rotation := Vector3.ZERO) -> void:
	var surface := SurfaceTool.new()
	surface.append_from(shape, 0, Transform3D(Basis.from_euler(rotation), at))
	surface.commit(model)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	model.surface_set_material(model.get_surface_count() - 1, material)
