extends RigidBody2D

@export var food_scene: PackedScene = preload("res://scenes/food.tscn")
@export var is_giant: bool = false
@export var current_force: float = 4.5
@export var max_drift_speed: float = 10.0
@export var food_push_strength: float = 42.0

var base_radius = 58.0
var radius = 58.0
var branch_count = 10
var branches: Array = []
var core_veins: Array = []
var drift_spin = 0.0
var grow_timer = 0.0
var grow_interval = 1.2
var spatial_update_timer = 0.0
var food_push_timer = 0.0
var base_color = Color(0.20, 0.95, 0.45, 0.18)
var world_manager: Node = null

@onready var collision_shape = $CollisionShape2D

func _ready():
	add_to_group("obstacles")
	add_to_group("food_growers")
	world_manager = get_parent().get_node_or_null("WorldManager")
	if world_manager and world_manager.has_method("register_obstacle"):
		world_manager.register_obstacle(self)
	tree_exiting.connect(_on_tree_exiting)
	can_sleep = false

	base_radius = randf_range(54.0, 92.0)
	branch_count = randi_range(5, 9)
	if is_giant:
		base_radius = randf_range(145.0, 190.0)
		branch_count = randi_range(12, 18)

	var shape = CircleShape2D.new()
	shape.radius = base_radius * 0.98
	collision_shape.shape = shape
	radius = shape.radius
	mass = max(14.0, base_radius * base_radius * 0.035)
	linear_damp = randf_range(2.6, 4.0)
	angular_damp = 0.18
	drift_spin = randf_range(0.006, 0.018) * (-1.0 if randf() < 0.5 else 1.0)
	angular_velocity = drift_spin
	grow_interval = randf_range(1.6, 3.2)
	food_push_timer = randf_range(0.02, 0.20)
	_generate_branches()
	_generate_core_veins()
	queue_redraw()

func _physics_process(delta):
	sleeping = false
	var current = _sample_liquid_current(global_position, Time.get_ticks_msec() * 0.001)
	apply_central_force(current * current_force * mass)
	angular_velocity = move_toward(angular_velocity, drift_spin, 0.06 * delta)
	if linear_velocity.length() > max_drift_speed:
		linear_velocity = linear_velocity.limit_length(max_drift_speed)
	food_push_timer -= delta
	if food_push_timer <= 0.0:
		food_push_timer = randf_range(0.12, 0.20)
		_push_nearby_food()

	spatial_update_timer -= delta
	if spatial_update_timer <= 0.0 and world_manager and world_manager.has_method("update_obstacle_spatial"):
		spatial_update_timer = 0.18
		world_manager.update_obstacle_spatial(self)

	var clamped_position = _clamp_to_arena(global_position, _get_extent_radius() + 12.0)
	if clamped_position != global_position:
		global_position = clamped_position
		linear_velocity *= -0.2

func _process(delta):
	grow_timer -= delta
	if grow_timer <= 0.0:
		grow_timer = grow_interval
		_try_grow_food()

func _generate_branches():
	branches.clear()
	var angle_offset = randf() * TAU
	for i in range(branch_count):
		var angle = angle_offset + TAU * float(i) / float(branch_count) + randf_range(-0.12, 0.12)
		var length = base_radius * randf_range(1.28, 1.55)
		var slot_limit = randi_range(1, 2)
		if is_giant:
			length = base_radius * randf_range(1.22, 1.82)
			slot_limit = randi_range(2, 4)

		var slots = []
		for s in range(slot_limit):
			var min_slot_radius = base_radius + 30.0 + float(slot_limit) * 4.0
			var min_along = clamp(min_slot_radius / max(length, 1.0), 0.70, 0.94)
			var along = lerp(min_along, 1.0, float(s + 1) / float(slot_limit + 1))
			var local_angle = angle + randf_range(-0.18, 0.18)
			var local_pos = Vector2(cos(local_angle), sin(local_angle)) * length * along
			slots.append({
				"pos": local_pos,
				"food": null,
				"cooldown": randf_range(0.5, 6.0)
			})
		branches.append({
			"angle": angle,
			"length": length,
			"slots": slots,
			"start_radius": base_radius * randf_range(0.78, 0.92),
			"thickness": randf_range(4.0, 8.0) * (1.45 if is_giant else 1.0)
		})

func _generate_core_veins():
	core_veins.clear()
	var count = 8 if is_giant else 5
	for i in range(count):
		var angle = randf() * TAU
		core_veins.append({
			"angle": angle,
			"length": base_radius * randf_range(0.38, 0.76),
			"width": randf_range(1.2, 2.8) * (1.35 if is_giant else 1.0),
			"alpha": randf_range(0.035, 0.075)
		})

func _try_grow_food():
	var candidates = []
	for branch_index in range(branches.size()):
		var slots = branches[branch_index]["slots"]
		for slot_index in range(slots.size()):
			var food = slots[slot_index]["food"]
			if food != null and food.get_ref() != null:
				continue
			if slots[slot_index]["pos"].length() <= base_radius + 24.0:
				continue
			slots[slot_index]["cooldown"] -= grow_interval
			if slots[slot_index]["cooldown"] <= 0.0:
				candidates.append(Vector2i(branch_index, slot_index))

	if candidates.is_empty():
		return

	var selected = candidates.pick_random()
	var slot = branches[selected.x]["slots"][selected.y]
	var food_position = to_global(slot["pos"])
	var food_value = randf_range(35.0, 65.0) * (1.35 if is_giant else 1.0)
	var food = null
	if world_manager and world_manager.has_method("spawn_food_at"):
		food = world_manager.spawn_food_at(food_position, false, food_value, 0)
	else:
		food = food_scene.instantiate()
		food.energy_value = food_value
		food.global_position = food_position
		get_parent().add_child(food)
	food.set_growth_anchor(self, slot["pos"])
	food.global_position = food_position
	slot["food"] = weakref(food)
	slot["cooldown"] = randf_range(5.0, 15.0) * (0.75 if is_giant else 1.0)
	queue_redraw()

func _draw():
	var outer_glow = Color(0.22, 0.95, 0.34, 0.055)
	var membrane = Color(0.33, 1.0, 0.44, 0.12)
	var core = Color(0.14, 0.72, 0.30, 0.12)
	var inner = Color(0.58, 1.0, 0.42, 0.065)
	var rim = Color(0.70, 1.0, 0.64, 0.13)

	# Branches stay behind the core so the base reads as one physical body.
	for branch in branches:
		var dir = Vector2(cos(branch["angle"]), sin(branch["angle"]))
		var start = dir * branch.get("start_radius", base_radius * 0.84)
		var end = dir * branch["length"]
		draw_line(start, end, Color(0.34, 1.0, 0.48, 0.105), branch["thickness"], true)
		draw_line(start, end, Color(0.78, 1.0, 0.58, 0.045), max(1.0, branch["thickness"] * 0.32), true)
		draw_circle(end, branch["thickness"] * 1.10, Color(0.58, 1.0, 0.42, 0.075))
		for slot in branch["slots"]:
			var pos = slot["pos"]
			var has_food = slot["food"] != null and slot["food"].get_ref() != null
			var slot_color = Color(0.56, 1.0, 0.36, 0.09 if has_food else 0.032)
			draw_circle(pos, branch["thickness"] * (1.25 if has_food else 0.70), slot_color)

	draw_circle(Vector2.ZERO, base_radius * 1.05, outer_glow)
	draw_circle(Vector2.ZERO, base_radius * 0.94, membrane)
	draw_circle(Vector2.ZERO, base_radius * 0.68, core)
	draw_circle(Vector2.ZERO, base_radius * 0.30, inner)
	draw_arc(Vector2.ZERO, base_radius * 0.96, 0.0, TAU, 72, rim, 1.4, true)
	draw_arc(Vector2.ZERO, base_radius * 0.64, 0.0, TAU, 60, Color(0.78, 1.0, 0.66, 0.055), 1.0, true)

	for vein in core_veins:
		var dir = Vector2(cos(vein["angle"]), sin(vein["angle"]))
		var start = dir * base_radius * 0.18
		var end = dir * vein["length"]
		draw_line(start, end, Color(0.70, 1.0, 0.48, vein["alpha"]), vein["width"], true)

func _get_extent_radius() -> float:
	var extent = base_radius
	for branch in branches:
		extent = max(extent, branch["length"])
	return extent

func _push_nearby_food():
	var push_radius = base_radius * 1.12 + 20.0
	var foods = []
	if world_manager and world_manager.has_method("get_food_near"):
		foods = world_manager.get_food_near(global_position, push_radius)
	else:
		foods = get_tree().get_nodes_in_group("food")

	for food in foods:
		if !is_instance_valid(food) or !food.is_in_group("food"):
			continue
		if food.has_method("push_from_obstacle"):
			food.push_from_obstacle(global_position, base_radius, linear_velocity, food_push_strength)

func _sample_liquid_current(pos: Vector2, time: float) -> Vector2:
	var slow = Vector2(
		sin(pos.y * 0.004 + time * 0.35),
		cos(pos.x * 0.0035 - time * 0.28)
	)
	var swirl = Vector2(
		cos((pos.x + pos.y) * 0.002 + time * 0.22),
		sin((pos.x - pos.y) * 0.002 - time * 0.18)
	)
	return (slow * 0.65 + swirl * 0.35).normalized()

func _clamp_to_arena(pos: Vector2, margin: float) -> Vector2:
	var arena_node = get_parent()
	if arena_node and arena_node.get("arena_size") != null:
		var half = arena_node.get("arena_size") / 2.0 - margin
		return Vector2(clamp(pos.x, -half, half), clamp(pos.y, -half, half))
	return pos

func _on_tree_exiting():
	if world_manager and world_manager.has_method("unregister_obstacle"):
		world_manager.unregister_obstacle(self)
