extends CharacterBody3D

const BASIC_COOLDOWN := 0.35
const BURST_COOLDOWN := 10.0
const BURST_INTERVAL := 0.12
const BURST_SHOTS := 4
const PROJECTILE_SPEED := 22.0
const PROJECTILE_RANGE := 24.0
const WALK_SPEED := 5.0
const RUN_SPEED := 8.0
const JUMP_SPEED := 5.0
const Chest := preload("res://bau.gd")
const GroundItem := preload("res://item_chao.gd")
const INTERACTION_REACH := 2.25
const Items := preload("res://itens.gd")
const Wardrobe := preload("res://vestuario.gd")
const BAG_SIZE := Vector2i(5, 4)
const WEAPON_KEYS := [KEY_1, KEY_2, KEY_3]
const CAST_ANIMATIONS := ["1H_Ranged_Shoot", "1H_Melee_Attack_Chop", "Spellcast_Long"]

var basic_ready_at := 0.0
var burst_ready_at := 0.0
var weapon_slot := -1
var backpack: Array[int] = []
var bag_positions: Dictionary[int, Vector2i] = {}
var bag_rotations: Dictionary[int, bool] = {}
var equipped_gear: Dictionary[int, bool] = {}
var gear_models: Dictionary[int, Mesh] = {}
var wardrobe: Wardrobe
var active_chest: Chest
var casting_until := 0.0
var ground_panel_open := false

@onready var camera_pivot: Node3D = $PivoCamera
@onready var camera: Camera3D = $PivoCamera/Camera3D
@onready var mage: Node3D = $Mago
@onready var mage_weapons: Array[MeshInstance3D] = [
	mage.find_child("1H_Wand", true, false),
	mage.find_child("2H_Staff", true, false),
	mage.find_child("Spellbook_open", true, false),
]
@onready var mage_animations: AnimationPlayer = $Mago/AnimationPlayer
@onready var interaction_label: Label = $"../HUD/Interacao"
@onready var nearby_items_label: Label = $"../HUD/ItensProximos"
@onready var backpack_label: Label = $"../HUD/Mochila"
@onready var inventory_menu: Control = $"../HUD/Inventario"
@onready var cooldowns: Control = $"../HUD/Recargas"

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mage.find_child("Spellbook", true, false).hide()
	mage_weapons[2].reparent(mage_weapons[0].get_parent(), false)
	for item in range(Items.FIRST_GEAR, Items.NAMES.size()):
		gear_models[item] = Items.gear_mesh(item)
	_equip_weapon(-1)
	wardrobe = Wardrobe.new(mage)
	_update_gear_visuals()


func _equip_weapon(slot: int) -> void:
	if slot >= 0 and (slot >= Items.FIRST_GEAR or not backpack.has(slot)):
		return
	weapon_slot = slot
	cooldowns.visible = not inventory_menu.visible and slot >= 0
	for index in range(mage_weapons.size()):
		mage_weapons[index].visible = index == slot
	_update_backpack()


func _nearby_target(group: StringName) -> Node3D:
	var closest: Node3D
	var distance := INTERACTION_REACH
	for target: Node3D in get_tree().get_nodes_in_group(group):
		if target is GroundItem and target.collected:
			continue
		var gap := global_position.distance_to(target.global_position + Vector3.UP * 0.4)
		if gap < distance:
			closest = target
			distance = gap
	return closest


func _interact() -> void:
	var target := _nearby_target(&"interagiveis")
	if target is GroundItem:
		_set_inventory_open(true)
	elif target is Chest:
		_interact_with_chest(target)


func _interact_with_chest(chest: Chest = null) -> void:
	if chest == null:
		chest = _nearby_target(&"baus") as Chest
	if chest == null:
		return
	chest.open()
	active_chest = chest
	_update_chest_preview()
	_set_inventory_open(true)


func _set_inventory_open(open: bool) -> void:
	ground_panel_open = open and active_chest == null and not _nearby_ground_items().is_empty()
	inventory_menu.visible = open
	nearby_items_label.visible = not open
	backpack_label.visible = not open
	interaction_label.visible = not open
	cooldowns.visible = not open and weapon_slot >= 0
	if not open:
		active_chest = null
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED
	inventory_menu.queue_redraw()


static func item_size(slot: int, rotated: bool) -> Vector2i:
	var dimensions: Vector2i = Items.SIZES[slot]
	return Vector2i(dimensions.y, dimensions.x) if rotated else dimensions


func _can_place_item(slot: int, cell: Vector2i, from_chest: bool, rotated: bool = false, to_chest: bool = false) -> bool:
	if not inventory_menu.visible or slot < 0 or slot >= Items.SIZES.size():
		return false
	if (from_chest or to_chest) and not is_instance_valid(active_chest):
		return false

	var source := active_chest.item_positions if from_chest else bag_positions
	if not source.has(slot):
		return false
	var destination := active_chest.item_positions if to_chest else bag_positions
	var rotations := active_chest.item_rotations if to_chest else bag_rotations
	var grid_size := Chest.GRID_SIZE if to_chest else BAG_SIZE
	return _fits(slot, cell, rotated, grid_size, destination, rotations)


func _fits(slot: int, cell: Vector2i, rotated: bool, grid_size: Vector2i, destination: Dictionary, rotations: Dictionary) -> bool:
	var footprint := Rect2i(cell, item_size(slot, rotated))
	if not Rect2i(Vector2i.ZERO, grid_size).encloses(footprint):
		return false
	for other in destination:
		if other != slot and footprint.intersects(Rect2i(destination[other], item_size(other, rotations[other]))):
			return false
	return true


func _place_item(slot: int, cell: Vector2i, from_chest: bool, rotated: bool = false, to_chest: bool = false) -> bool:
	if not _can_place_item(slot, cell, from_chest, rotated, to_chest):
		return false
	if from_chest != to_chest:
		if from_chest:
			active_chest.item_positions.erase(slot)
			active_chest.item_rotations.erase(slot)
			backpack.append(slot)
		else:
			_remove_bag_item(slot)
	if to_chest:
		active_chest.item_positions[slot] = cell
		active_chest.item_rotations[slot] = rotated
	else:
		bag_positions[slot] = cell
		bag_rotations[slot] = rotated
	if from_chest or to_chest:
		_update_chest_preview()
	inventory_menu.queue_redraw()
	return true


func _remove_bag_item(item: int) -> void:
	bag_positions.erase(item)
	bag_rotations.erase(item)
	backpack.erase(item)
	if weapon_slot == item:
		_equip_weapon(-1)


func _item_mesh(item: int) -> Mesh:
	return mage_weapons[item].mesh if item < Items.FIRST_GEAR else gear_models[item]


func _can_drop_on_ground(item: int) -> bool:
	return inventory_menu.visible and bag_positions.has(item)


func _drop_on_ground(item: int, rotated: bool) -> bool:
	if not _can_drop_on_ground(item):
		return false
	var spacing := Vector3((item % 3 - 1) * 0.52, 0, -0.75 - floorf(item / 3.0) * 0.42)
	var ahead := to_global(spacing)
	var ground := _raycast(ahead + Vector3.UP, ahead + Vector3.DOWN * 4.0)
	if ground.is_empty():
		return false

	var dropped := GroundItem.new()
	dropped.item = item
	dropped.rotated = rotated
	dropped.add_to_group(&"itens_no_chao")
	dropped.add_to_group(&"interagiveis")
	get_tree().current_scene.add_child(dropped)
	dropped.global_position = ground.position + Vector3.UP * 0.02
	dropped.show_mesh(_item_mesh(item))
	var marker := TorusMesh.new()
	marker.inner_radius = 0.24
	marker.outer_radius = 0.28
	dropped.add_child(_effect_mesh(marker, Items.COLORS[item]))
	_remove_bag_item(item)
	if active_chest == null:
		ground_panel_open = true
	inventory_menu.queue_redraw()
	return true


func _nearby_ground_items() -> Array[GroundItem]:
	var items: Array[GroundItem] = []
	for dropped: GroundItem in get_tree().get_nodes_in_group(&"itens_no_chao"):
		if _ground_item_in_reach(dropped):
			items.append(dropped)
	return items


func _ground_item_in_reach(dropped: GroundItem) -> bool:
	return is_instance_valid(dropped) and not dropped.collected and global_position.distance_to(dropped.global_position + Vector3.UP * 0.4) < INTERACTION_REACH


func _can_pick_up_ground_item(dropped: GroundItem, cell: Vector2i, rotated: bool) -> bool:
	return ground_panel_open and _ground_item_in_reach(dropped) and not backpack.has(dropped.item) and not equipped_gear.has(dropped.item) and _fits(dropped.item, cell, rotated, BAG_SIZE, bag_positions, bag_rotations)


func _place_ground_item(dropped: GroundItem, cell: Vector2i, rotated: bool) -> bool:
	if not _can_pick_up_ground_item(dropped, cell, rotated):
		return false
	backpack.append(dropped.item)
	bag_positions[dropped.item] = cell
	bag_rotations[dropped.item] = rotated
	dropped.collected = true
	dropped.queue_free()
	inventory_menu.queue_redraw()
	return true


func _pick_up_ground_item(dropped: GroundItem) -> bool:
	if not _ground_item_in_reach(dropped):
		return false
	for row in range(BAG_SIZE.y):
		for column in range(BAG_SIZE.x):
			if _place_ground_item(dropped, Vector2i(column, row), dropped.rotated):
				return true
	return false


func _update_chest_preview() -> void:
	var meshes: Array[Mesh] = []
	for item in active_chest.item_positions:
		meshes.append(_item_mesh(item))
	active_chest.set_loot_meshes(meshes)


func _can_equip_gear(item: int, from_chest: bool = false) -> bool:
	if not inventory_menu.visible or item < Items.FIRST_GEAR or item >= Items.NAMES.size() or equipped_gear.has(item):
		return false
	if from_chest:
		return is_instance_valid(active_chest) and active_chest.item_positions.has(item)
	return bag_positions.has(item)


func _equip_gear(item: int, from_chest: bool = false) -> bool:
	if not _can_equip_gear(item, from_chest):
		return false
	var positions := active_chest.item_positions if from_chest else bag_positions
	var rotations := active_chest.item_rotations if from_chest else bag_rotations
	equipped_gear[item] = rotations[item]
	positions.erase(item)
	rotations.erase(item)
	if from_chest:
		_update_chest_preview()
	else:
		backpack.erase(item)
	_update_gear_visuals()
	inventory_menu.queue_redraw()
	return true


func _unequip_gear(item: int) -> bool:
	if not inventory_menu.visible or not equipped_gear.has(item):
		return false
	var rotated := equipped_gear[item]
	for row in range(BAG_SIZE.y):
		for column in range(BAG_SIZE.x):
			var cell := Vector2i(column, row)
			if not _fits(item, cell, rotated, BAG_SIZE, bag_positions, bag_rotations):
				continue
			bag_positions[item] = cell
			bag_rotations[item] = rotated
			backpack.append(item)
			equipped_gear.erase(item)
			_update_gear_visuals()
			inventory_menu.queue_redraw()
			return true
	return false


func attribute(attribute_name: String) -> float:
	var total := 0.0
	for item in equipped_gear:
		var index := item - Items.FIRST_GEAR
		if Items.ATTRIBUTES[index] == attribute_name:
			total += Items.BONUSES[index]
	return total


func _update_gear_visuals() -> void:
	wardrobe.sync(equipped_gear)


func _quick_loot(slot: int) -> void:
	if not is_instance_valid(active_chest) or not active_chest.item_positions.has(slot):
		return
	for row in range(BAG_SIZE.y):
		for column in range(BAG_SIZE.x):
			if _place_item(slot, Vector2i(column, row), true, active_chest.item_rotations[slot]):
				return


func _update_backpack() -> void:
	var equipped: String = "Sem arma" if weapon_slot < 0 else Items.NAMES[weapon_slot]
	backpack_label.text = "Mochila [B]  •  " + equipped
	inventory_menu.queue_redraw()


func _update_interaction_prompt() -> void:
	var target := _nearby_target(&"interagiveis")
	interaction_label.text = ""
	if target is GroundItem:
		interaction_label.text = "[E] Ver itens no chão"
	elif target is Chest:
		interaction_label.text = "[E] Vasculhar baú" if target.opened else "[E] Abrir baú"

	if inventory_menu.visible:
		return
	var items := _nearby_ground_items()
	nearby_items_label.text = ""
	if not items.is_empty():
		var lines := PackedStringArray(["ITENS NO CHÃO", "[B] Abrir mochila"])
		for index in range(mini(items.size(), 5)):
			lines.append("• " + Items.NAMES[items[index].item])
		if items.size() > 5:
			lines.append("+ %d itens" % (items.size() - 5))
		nearby_items_label.text = "\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	if inventory_menu.visible:
		if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_ESCAPE, KEY_B, KEY_E]:
			_set_inventory_open(false)
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var slot := WEAPON_KEYS.find(event.physical_keycode)
		if slot >= 0:
			_equip_weapon(slot)
		if event.physical_keycode == KEY_E:
			_interact()
		if event.physical_keycode == KEY_B:
			_set_inventory_open(true)
		if event.physical_keycode == KEY_SPACE and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and is_on_floor():
			velocity.y = JUMP_SPEED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_fire_basic()
			MOUSE_BUTTON_RIGHT:
				_fire_burst()
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * 0.0025)
		camera_pivot.rotation.x = clampf(camera_pivot.rotation.x - event.relative.y * 0.0025, -0.8, 0.25)

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	if not inventory_menu.visible and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		direction.x = int(Input.is_physical_key_pressed(KEY_D)) - int(Input.is_physical_key_pressed(KEY_A))
		direction.y = int(Input.is_physical_key_pressed(KEY_S)) - int(Input.is_physical_key_pressed(KEY_W))
		direction = direction.limit_length()
	var running := Input.is_physical_key_pressed(KEY_SHIFT)
	var speed := (RUN_SPEED if running else WALK_SPEED) + attribute("Velocidade")
	var movement := transform.basis * Vector3(direction.x, 0, direction.y) * speed
	velocity.x = movement.x
	velocity.z = movement.z
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()
	_update_interaction_prompt()
	if Time.get_ticks_msec() / 1000.0 >= casting_until:
		var animation := "Idle"
		if not is_on_floor():
			animation = "Jump_Idle"
		elif not direction.is_zero_approx():
			if direction.y > 0.5:
				animation = "Walking_Backwards"
			elif running:
				animation = "Running_A"
			else:
				animation = "Walking_A"
		if mage_animations.current_animation != animation:
			mage_animations.play(animation, 0.12)


func _play_cast(duration: float) -> void:
	var animation: String = CAST_ANIMATIONS[weapon_slot]
	var clip := mage_animations.get_animation(animation)
	casting_until = Time.get_ticks_msec() / 1000.0 + duration
	mage_animations.play(animation, 0.06, clip.length / duration)
	mage_animations.seek(0.0)


func _fire_basic() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if inventory_menu.visible or weapon_slot < 0 or now < basic_ready_at:
		return
	basic_ready_at = now + BASIC_COOLDOWN
	_play_cast(0.28)
	match weapon_slot:
		0:
			_launch_magic(Color(0.2, 0.85, 1.0), 0.045)
		1:
			_create_zone(0.9, 0.65, Color(0.25, 0.95, 0.55, 0.36))
		2:
			var stone := PrismMesh.new()
			stone.size = Vector3(0.24, 0.28, 0.22)
			_launch_projectile(mage_weapons[2], stone, Color(0.76, 0.54, 1.0), 15.0)


func _fire_burst() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if inventory_menu.visible or weapon_slot < 0 or now < burst_ready_at:
		return
	burst_ready_at = INF
	_play_cast(0.55)
	match weapon_slot:
		0:
			for shot in range(BURST_SHOTS):
				if shot > 0:
					await get_tree().create_timer(BURST_INTERVAL, false, true).timeout
				_launch_magic(Color(0.85, 0.35, 1.0), 0.075)
		1:
			_create_zone(2.1, 2.5, Color(0.28, 0.8, 1.0, 0.42))
		2:
			_swing_hammer()
	burst_ready_at = Time.get_ticks_msec() / 1000.0 + BURST_COOLDOWN


func _launch_magic(color: Color, radius: float) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	_launch_projectile(mage_weapons[0], sphere, color, PROJECTILE_SPEED)


func _launch_projectile(weapon: MeshInstance3D, mesh: PrimitiveMesh, color: Color, speed: float) -> void:
	var origin := weapon.to_global(Vector3.UP * weapon.get_aabb().end.y)
	var aim := _aim_point(PROJECTILE_RANGE)
	var hit := _raycast(origin, aim)
	var end: Vector3 = hit.get("position", aim)

	var projectile := _effect_mesh(mesh, color)
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = origin
	var flight := projectile.create_tween()
	flight.tween_property(projectile, "global_position", end, origin.distance_to(end) / speed)
	flight.tween_callback(projectile.queue_free)


func _create_zone(radius: float, duration: float, color: Color) -> void:
	var aim := _aim_point(12.0)
	var ground := _raycast(aim + Vector3.UP * 1.5, aim + Vector3.DOWN * 12.0)
	if ground.is_empty():
		return

	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.016
	var zone := _effect_mesh(disc, color)
	get_tree().current_scene.add_child(zone)
	zone.global_position = ground.position + Vector3.UP * 0.025

	var ring := TorusMesh.new()
	ring.inner_radius = radius - 0.04
	ring.outer_radius = radius
	zone.add_child(_effect_mesh(ring, Color(color, 1.0)))

	var lifetime := zone.create_tween()
	lifetime.tween_interval(duration)
	lifetime.tween_callback(zone.queue_free)


func _swing_hammer() -> void:
	var hammer := Node3D.new()
	get_tree().current_scene.add_child(hammer)
	hammer.global_transform = global_transform
	hammer.translate(Vector3(0.55, 0.46, -0.42))

	var shaft := BoxMesh.new()
	shaft.size = Vector3(0.08, 1.0, 0.08)
	var grip := _effect_mesh(shaft, Color(0.47, 0.27, 0.75))
	hammer.add_child(grip)
	grip.position.y = 0.47

	var block := BoxMesh.new()
	block.size = Vector3(0.64, 0.34, 0.32)
	var head := _effect_mesh(block, Color(0.82, 0.61, 1.0))
	hammer.add_child(head)
	head.position.y = 1.02

	hammer.rotation.x = 0.65
	var swing := hammer.create_tween()
	swing.tween_property(hammer, "rotation:x", -2.2, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	swing.tween_interval(0.18)
	swing.tween_callback(hammer.queue_free)


func _aim_point(distance: float) -> Vector3:
	var start := camera.global_position
	var end := start - camera.global_basis.z * distance
	return _raycast(start, end).get("position", end)


func _raycast(start: Vector3, end: Vector3) -> Dictionary:
	var ray := PhysicsRayQueryParameters3D.create(start, end, 1, [get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(ray)


func _effect_mesh(mesh: PrimitiveMesh, color: Color) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = material
	var effect := MeshInstance3D.new()
	effect.mesh = mesh
	effect.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return effect
