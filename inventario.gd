extends Control

const Player := preload("res://personagem.gd")
const Chest := preload("res://bau.gd")
const GroundItem := preload("res://item_chao.gd")
const Items := preload("res://itens.gd")
const Wardrobe := preload("res://vestuario.gd")
const PANEL := Color("#18212b")
const CELL := Color("#242f3c")
const TEXT := Color("#e5eef4")
const MUTED := Color("#9caec0")
const MAGE := preload("res://assets/mago.glb")
# Chapéu, anel, manto, botas, calças e colar, na ordem do catálogo.
const BODY_ROWS := [0, 3, 2, 5, 4, 1]
const BODY_POINTS := [
	Vector2(0.92, 0.42), Vector2(1.57, 2.75), Vector2(1.24, 2.29),
	Vector2(1.05, 3.72), Vector2(1.04, 3.25), Vector2(0.91, 2.17),
]

var drag_preview: Control
var mage_preview: SubViewport
var preview_wardrobe: Wardrobe

@onready var player: Player = $"../../Personagem"

func _ready() -> void:
	resized.connect(queue_redraw)
	visibility_changed.connect(_refresh_preview)
	_create_mage_preview()
	_refresh_preview()


func _create_mage_preview() -> void:
	mage_preview = SubViewport.new()
	mage_preview.size = Vector2i(226, 520)
	mage_preview.own_world_3d = true
	mage_preview.transparent_bg = true
	add_child(mage_preview)

	var model := MAGE.instantiate()
	mage_preview.add_child(model)
	for accessory in ["1H_Wand", "2H_Staff", "Spellbook", "Spellbook_open"]:
		model.find_child(accessory, true, false).hide()
	preview_wardrobe = Wardrobe.new(model)
	var animations := model.get_node("AnimationPlayer") as AnimationPlayer
	animations.play("Idle")
	animations.advance(0.15)
	animations.pause()

	var view := Camera3D.new()
	view.projection = Camera3D.PROJECTION_ORTHOGONAL
	view.size = 3.05
	view.position = Vector3(0, 1.36, 5)
	var ambient := Environment.new()
	ambient.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambient.ambient_light_color = Color(0.8, 0.84, 1.0)
	ambient.ambient_light_energy = 0.58
	view.environment = ambient
	mage_preview.add_child(view)
	view.make_current()

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-25, -25, 0)
	mage_preview.add_child(light)


func _refresh_preview() -> void:
	mage_preview.render_target_update_mode = SubViewport.UPDATE_ONCE if visible else SubViewport.UPDATE_DISABLED
	queue_redraw()


func _cell_size() -> float:
	return floorf(minf(58.0, minf(size.x / 15.4, size.y / 7.0)))


func _has_chest() -> bool:
	return is_instance_valid(player.active_chest)


func _has_side_panel() -> bool:
	return _has_chest() or player.ground_panel_open


func _ground_drop_area() -> Rect2:
	var cell := _cell_size()
	var right := _loot_origin() + Vector2(Chest.GRID_SIZE.x * cell, 0) if _has_side_panel() else _bag_origin() + Vector2(Player.BAG_SIZE.x * cell, 0)
	return Rect2(right + Vector2(-2.7 * cell, 4 * cell + 17), Vector2(2.7 * cell, 28))


func _bag_origin() -> Vector2:
	var cell := _cell_size()
	return Vector2(size.x / 2.0 - (3.0 if _has_side_panel() else 0.45) * cell, size.y / 2.0 - 1.65 * cell)


func _loot_origin() -> Vector2:
	return _bag_origin() + Vector2(5.8 * _cell_size(), 0)


func _gear_origin() -> Vector2:
	return _bag_origin() - Vector2(4.1 * _cell_size(), 0)


func _gear_slot(item: int) -> Rect2:
	var row: int = BODY_ROWS[item - Items.FIRST_GEAR]
	var cell := _cell_size()
	return Rect2(_gear_origin() + Vector2(1.76, row * 0.66) * cell, Vector2(1.61, 0.58) * cell)


func _gear_at(position: Vector2) -> int:
	for item in range(Items.FIRST_GEAR, Items.NAMES.size()):
		if _gear_slot(item).has_point(position):
			return item
	return -1


func _draw_gear() -> void:
	var cell := _cell_size()
	var origin := _gear_origin()
	draw_rect(Rect2(origin - Vector2(10, 35), Vector2(3.37 * cell + 20, 4 * cell + 45)), PANEL)
	_write("EQUIPAMENTO", origin - Vector2(0, 12), 16, TEXT)
	if is_instance_valid(mage_preview):
		if preview_wardrobe.sync(player.equipped_gear):
			mage_preview.render_target_update_mode = SubViewport.UPDATE_ONCE
		draw_texture_rect(mage_preview.get_texture(), Rect2(origin, Vector2(1.74, 3.96) * cell), false)

	for item in range(Items.FIRST_GEAR, Items.NAMES.size()):
		var index := item - Items.FIRST_GEAR
		var rect := _gear_slot(item)
		var equipped := player.equipped_gear.has(item)
		var color: Color = Items.COLORS[item]
		var connector: Color = color if equipped else MUTED.darkened(0.30)
		var body_point: Vector2 = BODY_POINTS[index]
		if item == 3 and not equipped:
			body_point.y = 0.96
		var point := origin + body_point * cell
		var edge := Vector2(rect.position.x, rect.get_center().y)
		draw_line(point, edge - Vector2(cell * 0.14, 0), connector, 1.0, true)
		draw_line(edge - Vector2(cell * 0.14, 0), edge, connector, 1.0, true)
		draw_circle(point, 2.0, connector, true, -1.0, true)
		draw_rect(rect, color.darkened(0.77) if equipped else CELL)
		draw_rect(rect, connector, false, 1.0)
		var text_scale := clampf(cell / 58.0, 0.65, 1.0)
		_write(Items.NAMES[item], rect.position + Vector2(6, 14) * text_scale, roundi(12 * text_scale), color if equipped else TEXT)
		var bonus := "+%d %s" % [Items.BONUSES[index], Items.ATTRIBUTES[index]]
		_write(bonus if equipped else "Vazio", rect.position + Vector2(6, 27) * text_scale, roundi(10 * text_scale), color if equipped else MUTED)
		_draw_gear_icon(item, rect.end - Vector2(cell * 0.18, rect.size.y / 2), cell / 58.0, connector)


func _draw_gear_icon(item: int, at: Vector2, scale_factor: float, color: Color) -> void:
	match item:
		3:
			draw_colored_polygon(PackedVector2Array([at + Vector2(-7, 3) * scale_factor, at + Vector2(0, -8) * scale_factor, at + Vector2(6, 3) * scale_factor]), color)
			draw_line(at + Vector2(-9, 4) * scale_factor, at + Vector2(9, 4) * scale_factor, color, 2.0, true)
		4, 8:
			var radius := (5.0 if item == 4 else 7.0) * scale_factor
			draw_arc(at, radius, 0, TAU, 24, color, 1.5, true)
			draw_circle(at + Vector2(0, -radius if item == 4 else radius), 2.5 * scale_factor, color, true, -1.0, true)
		5:
			draw_colored_polygon(PackedVector2Array([at + Vector2(-3, -7) * scale_factor, at + Vector2(3, -7) * scale_factor, at + Vector2(8, 7) * scale_factor, at + Vector2(-8, 7) * scale_factor]), color)
		6, 7:
			for side in [-1.0, 1.0]:
				var part := at + Vector2(side * 4, 0) * scale_factor
				draw_rect(Rect2(part - Vector2(2.4, 7) * scale_factor, Vector2(4.8, 13) * scale_factor), color)
				if item == 6:
					draw_rect(Rect2(part + Vector2(-2.4, 3) * scale_factor, Vector2(6.4, 3.5) * scale_factor), color)


func _draw() -> void:
	var cell := _cell_size()
	var bag := _bag_origin()
	var loot := _loot_origin()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.08, 0.83))
	_draw_gear()
	var used_cells := 0
	for slot in player.bag_positions:
		var footprint: Vector2i = Items.SIZES[slot]
		used_cells += footprint.x * footprint.y
	_draw_panel(bag, Player.BAG_SIZE, "MOCHILA   %d / %d" % [used_cells, Player.BAG_SIZE.x * Player.BAG_SIZE.y])
	if _has_chest():
		_draw_panel(loot, Chest.GRID_SIZE, "SAQUE")
	for slot in player.bag_positions:
		var position := bag + Vector2(player.bag_positions[slot]) * cell
		_draw_item(self, slot, position, slot == player.weapon_slot, player.bag_rotations[slot])

	var chest := player.active_chest
	if is_instance_valid(chest) and not chest.item_positions.is_empty():
		for slot in chest.item_positions:
			var position := loot + Vector2(chest.item_positions[slot]) * cell
			_draw_item(self, slot, position, false, chest.item_rotations[slot])
	elif _has_chest():
		_write("Baú vazio", loot + Vector2(10, 24), 14, MUTED)
	elif player.ground_panel_open:
		_draw_ground_list(loot)

	var ground := _ground_drop_area()
	draw_rect(ground, PANEL)
	draw_rect(ground, Color("#b88a61"), false, 1.0)
	_write("SOLTAR NO CHÃO", ground.position + Vector2(8, 18), 11, Color("#e2b68e"))

	var stats := "Vida +%d   Mana +%d   Poder +%d   Defesa +%d   Velocidade +%.0f m/s" % [
		player.attribute("Vida"), player.attribute("Mana"), player.attribute("Poder"),
		player.attribute("Defesa"), player.attribute("Velocidade"),
	]
	_write(stats, _gear_origin() + Vector2(0, 4 * cell + 28), 12, MUTED)
	_write("Arraste ou dê duplo clique para equipar  •  Rodinha gira  •  Esc fecha",
		_gear_origin() + Vector2(0, 4 * cell + 61), 13, TEXT)


func _ground_row(index: int) -> Rect2:
	var cell := _cell_size()
	var height := cell * 4.0 / 9.0
	return Rect2(_loot_origin() + Vector2(0, height * index), Vector2(Chest.GRID_SIZE.x * cell, height - 2.0))


func _ground_item_at(position: Vector2) -> GroundItem:
	if not player.ground_panel_open:
		return null
	var items := player._nearby_ground_items()
	for index in range(items.size()):
		if _ground_row(index).has_point(position):
			return items[index]
	return null


func _draw_ground_list(origin: Vector2) -> void:
	var cell := _cell_size()
	draw_rect(Rect2(origin - Vector2(10, 35), Vector2(Chest.GRID_SIZE.x * cell + 20, 4 * cell + 45)), PANEL)
	_write("ITENS NO CHÃO", origin - Vector2(0, 12), 16, TEXT)
	var items := player._nearby_ground_items()
	if items.is_empty():
		_write("Nenhum item por perto", origin + Vector2(10, 24), 14, MUTED)
	for index in range(items.size()):
		var dropped := items[index]
		var row := _ground_row(index)
		var color: Color = Items.COLORS[dropped.item]
		var footprint := Player.item_size(dropped.item, dropped.rotated)
		draw_rect(row, CELL)
		draw_rect(Rect2(row.position, Vector2(3, row.size.y)), color)
		_write(Items.NAMES[dropped.item], row.position + Vector2(10, row.size.y * 0.72), 13, color)
		_write("%d × %d" % [footprint.x, footprint.y], row.end + Vector2(-40, -row.size.y * 0.28), 11, MUTED)


func _draw_panel(origin: Vector2, dimensions: Vector2i, title: String) -> void:
	var cell := _cell_size()
	var area := Vector2(dimensions) * cell
	draw_rect(Rect2(origin - Vector2(10, 35), area + Vector2(20, 45)), PANEL)
	_write(title, origin - Vector2(0, 12), 16, TEXT)
	for row in range(dimensions.y):
		for column in range(dimensions.x):
			var position := origin + Vector2(column, row) * cell
			draw_rect(Rect2(position + Vector2.ONE, Vector2.ONE * (cell - 2.0)), CELL)


func _draw_item(canvas: CanvasItem, slot: int, origin: Vector2, equipped: bool, rotated: bool) -> void:
	var area := Vector2(Player.item_size(slot, rotated)) * _cell_size()
	var rect := Rect2(origin + Vector2(2, 2), area - Vector2(4, 4))
	var color: Color = Items.COLORS[slot]
	canvas.draw_rect(rect, color.darkened(0.72))
	canvas.draw_rect(rect, color, false, 2.0 if equipped else 1.0)
	var icon := rect.get_center()
	if slot >= Items.FIRST_GEAR:
		var index := slot - Items.FIRST_GEAR
		var stat := "+%d %s" % [Items.BONUSES[index], Items.ATTRIBUTES[index]]
		canvas.draw_string(ThemeDB.fallback_font, rect.position + Vector2(4, 32), stat, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 6.0, 9, color)
	elif slot == 2:
		var half_size := Vector2(10, 15) if rotated else Vector2(15, 10)
		var spine := Vector2(10, 0) if rotated else Vector2(0, 10)
		canvas.draw_rect(Rect2(icon - half_size, half_size * 2), color, false, 2.0)
		canvas.draw_line(icon - spine, icon + spine, color, 2.0, true)
	else:
		var axis := Vector2(19, 9) if rotated else Vector2(9, -19)
		var tip := icon + axis
		canvas.draw_line(icon - axis, tip, color, 3.0 if slot == 0 else 5.0, true)
		canvas.draw_circle(tip, 3.5 if slot == 0 else 6.0, color, true, -1.0, true)
	canvas.draw_string(ThemeDB.fallback_font, rect.position + Vector2(4, 15), Items.NAMES[slot], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)
	if equipped:
		canvas.draw_string(ThemeDB.fallback_font, rect.end - Vector2(rect.size.x - 5, 8), "EM USO", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)


func _write(content: String, at: Vector2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, at, content, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _cell_at(position: Vector2, origin: Vector2) -> Vector2i:
	return Vector2i(((position - origin) / _cell_size()).floor())


func _bag_item_at(cell: Vector2i) -> int:
	for slot in player.bag_positions:
		if Rect2i(player.bag_positions[slot], Player.item_size(slot, player.bag_rotations[slot])).has_point(cell):
			return slot
	return -1


func _loot_item_at(position: Vector2) -> int:
	var chest := player.active_chest
	if is_instance_valid(chest):
		var cell := _cell_at(position, _loot_origin())
		for slot in chest.item_positions:
			if Rect2i(chest.item_positions[slot], Player.item_size(slot, chest.item_rotations[slot])).has_point(cell):
				return slot
	return -1


func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventMouseButton:
		return
	var data: Variant = get_viewport().gui_get_drag_data()
	if not data is Dictionary or not data.has("rotated"):
		return
	if _is_scroll(event):
		_rotate_drag(data)
		get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		# Use the release position so a rotation can be dropped without another mouse motion.
		var local_position: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		_drop_data(local_position, data)


func _is_scroll(event: InputEventMouseButton) -> bool:
	return event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]


func _rotate_drag(data: Dictionary) -> void:
	var footprint := Player.item_size(data.slot, data.rotated)
	var grab: Vector2i = data.grab
	data.grab = Vector2i(footprint.y - 1 - grab.y, grab.x)
	data.rotated = not data.rotated
	if is_instance_valid(drag_preview):
		drag_preview.queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var dropped := _ground_item_at(event.position)
		if dropped != null and _is_scroll(event):
			dropped.rotated = not dropped.rotated
			queue_redraw()
			accept_event()
			return
		if dropped != null and (event.button_index == MOUSE_BUTTON_RIGHT or (event.button_index == MOUSE_BUTTON_LEFT and event.double_click)):
			player._pick_up_ground_item(dropped)
			accept_event()
			return
		if _is_scroll(event):
			var loot_slot := _loot_item_at(event.position)
			if loot_slot >= 0:
				var chest := player.active_chest
				player._place_item(loot_slot, chest.item_positions[loot_slot], true, not chest.item_rotations[loot_slot], true)
			else:
				var slot := _bag_item_at(_cell_at(event.position, _bag_origin()))
				if slot >= 0:
					player._place_item(slot, player.bag_positions[slot], false, not player.bag_rotations[slot])
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT and _loot_item_at(event.position) >= 0:
			player._quick_loot(_loot_item_at(event.position))
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			var gear := _gear_at(event.position)
			if gear >= 0 and player.equipped_gear.has(gear):
				player._unequip_gear(gear)
				accept_event()
				return
			var slot := _bag_item_at(_cell_at(event.position, _bag_origin()))
			if slot >= Items.FIRST_GEAR:
				player._equip_gear(slot)
				accept_event()
			elif slot >= 0:
				player._equip_weapon(slot)
				accept_event()


func _get_drag_data(at_position: Vector2) -> Variant:
	var dropped := _ground_item_at(at_position)
	if dropped != null:
		return _start_item_drag({
			"slot": dropped.item, "from_chest": false, "ground": dropped,
			"grab": Vector2i.ZERO, "rotated": dropped.rotated,
		})
	var slot := _loot_item_at(at_position)
	var from_chest := slot >= 0
	var cell := _cell_at(at_position, _loot_origin() if from_chest else _bag_origin())
	if not from_chest:
		slot = _bag_item_at(cell)
		if slot < 0:
			return null
	var positions := player.active_chest.item_positions if from_chest else player.bag_positions
	var rotations := player.active_chest.item_rotations if from_chest else player.bag_rotations
	return _start_item_drag({"slot": slot, "from_chest": from_chest, "grab": cell - positions[slot], "rotated": rotations[slot]})


func _start_item_drag(data: Dictionary) -> Dictionary:
	drag_preview = Control.new()
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.modulate.a = 0.92
	drag_preview.draw.connect(_draw_drag_preview.bind(drag_preview, data))
	set_drag_preview(drag_preview)
	return data


func _draw_drag_preview(preview: Control, data: Dictionary) -> void:
	var origin := -(Vector2(data.grab) + Vector2(0.5, 0.5)) * _cell_size()
	_draw_item(preview, data.slot, origin, false, data.rotated)


func _is_chest_drop(at_position: Vector2) -> bool:
	return _has_chest() and Rect2i(Vector2i.ZERO, Chest.GRID_SIZE).has_point(_cell_at(at_position, _loot_origin()))


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary or not data.has_all(["slot", "from_chest", "grab"]) or data.get("placed", false):
		return false
	if data.has("ground"):
		var hover := _cell_at(at_position, _bag_origin())
		return Rect2i(Vector2i.ZERO, Player.BAG_SIZE).has_point(hover) and player._can_pick_up_ground_item(data.ground, hover - data.grab, data.get("rotated", false))
	if _ground_drop_area().has_point(at_position):
		return not data.from_chest and player._can_drop_on_ground(data.slot)
	var gear := _gear_at(at_position)
	if gear >= 0:
		return gear == data.slot and player._can_equip_gear(data.slot, data.from_chest)
	var to_chest := _is_chest_drop(at_position)
	var origin := _loot_origin() if to_chest else _bag_origin()
	var grid := Chest.GRID_SIZE if to_chest else Player.BAG_SIZE
	var hover := _cell_at(at_position, origin)
	if not Rect2i(Vector2i.ZERO, grid).has_point(hover):
		return false
	var cell: Vector2i = hover - data.grab
	return player._can_place_item(data.slot, cell, data.from_chest, data.get("rotated", false), to_chest)


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(at_position, data):
		return
	if data.has("ground"):
		var cell: Vector2i = _cell_at(at_position, _bag_origin()) - data.grab
		data["placed"] = player._place_ground_item(data.ground, cell, data.get("rotated", false))
		return
	if _ground_drop_area().has_point(at_position):
		data["placed"] = player._drop_on_ground(data.slot, data.get("rotated", false))
		return
	var gear := _gear_at(at_position)
	if gear >= 0:
		data["placed"] = player._equip_gear(data.slot, data.from_chest)
		return
	var to_chest := _is_chest_drop(at_position)
	var origin := _loot_origin() if to_chest else _bag_origin()
	var cell: Vector2i = _cell_at(at_position, origin) - data.grab
	data["placed"] = player._place_item(data.slot, cell, data.from_chest, data.get("rotated", false), to_chest)
