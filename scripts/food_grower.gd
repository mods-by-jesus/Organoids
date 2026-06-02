extends RigidBody2D

@export var food_scene: PackedScene = preload("res://scenes/food.tscn")
@export var is_giant: bool = false
@export var current_force: float = 7.5
@export var max_drift_speed: float = 18.0

var base_radius = 58.0
var branch_count = 10
var branches: Array = []
var drift_spin = 0.0
var grow_timer = 0.0
var grow_interval = 1.2
var base_color = Color(0.18, 1.0, 0.15, 0.34)
var world_manager: Node = null

@onready var collision_shape = $CollisionShape2D

func _ready():
	add_to_group("obstacles")
	add_to_group("food_growers")
	world_manager = get_parent().get_node_or_null("WorldManager")
	can_sleep = false

	base_radius = randf_range(46.0, 82.0)
	branch_count = randi_range(7, 14)
	if is_giant:
		base_radius = randf_range(130.0, 170.0)
		branch_count = randi_range(18, 28)

	var shape = CircleShape2D.new()
	shape.radius = base_radius * 0.72
	collision_shape.shape = shape
	mass = max(8.0, base_radius * base_radius * 0.025)
	linear_damp = randf_range(1.8, 2.8)
	angular_damp = 0.08
	drift_spin = randf_range(0.012, 0.034) * (-1.0 if randf() < 0.5 else 1.0)
	angular_velocity = drift_spin
	grow_interval = randf_range(0.8, 1.9)
	_generate_branches()
	queue_redraw()

func _physics_process(delta):
	sleeping = false
	var current = _sample_liquid_current(global_position, Time.get_ticks_msec() * 0.001)
	apply_central_force(current * current_force * mass)
	angular_velocity = move_toward(angular_velocity, drift_spin, 0.06 * delta)
	if linear_velocity.length() > max_drift_speed:
		linear_velocity = linear_velocity.limit_length(max_drift_speed)

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
		var length = base_radius * randf_range(0.78, 1.55)
		var slot_limit = randi_range(1, 3)
		if is_giant:
			length = base_radius * randf_range(0.95, 1.95)
			slot_limit = randi_range(2, 5)

		var slots = []
		for s in range(slot_limit):
			var along = lerp(0.55, 1.0, float(s + 1) / float(slot_limit + 1))
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
			"thickness": randf_range(4.0, 8.0) * (1.45 if is_giant else 1.0)
		})

func _try_grow_food():
	var candidates = []
	for branch_index in range(branches.size()):
		var slots = branches[branch_index]["slots"]
		for slot_index in range(slots.size()):
			var food = slots[slot_index]["food"]
			if food != null and food.get_ref() != null:
				continue
			slots[slot_index]["cooldown"] -= grow_interval
			if slots[slot_index]["cooldown"] <= 0.0:
				candidates.append(Vector2i(branch_index, slot_index))

	if candidates.is_empty():
		return

	var selected = candidates.pick_random()
	var slot = branches[selected.x]["slots"][selected.y]
	var food = food_scene.instantiate()
	food.energy_value = randf_range(35.0, 65.0) * (1.35 if is_giant else 1.0)
	food.global_position = to_global(slot["pos"])
	get_parent().add_child(food)
	food.set_growth_anchor(self, slot["pos"])
	food.global_position = to_global(slot["pos"])
	slot["food"] = weakref(food)
	slot["cooldown"] = randf_range(5.0, 15.0) * (0.75 if is_giant else 1.0)
	queue_redraw()

func _draw():
	var glow = Color(0.28, 1.0, 0.16, 0.16)
	var core = Color(0.15, 0.95, 0.10, 0.34)
	var rim = Color(0.68, 1.0, 0.28, 0.30)
	draw_circle(Vector2.ZERO, base_radius, glow)
	draw_circle(Vector2.ZERO, base_radius * 0.58, core)
	draw_arc(Vector2.ZERO, base_radius * 0.72, 0.0, TAU, 64, rim, 2.0, true)

	for branch in branches:
		var dir = Vector2(cos(branch["angle"]), sin(branch["angle"]))
		var start = dir * base_radius * 0.35
		var end = dir * branch["length"]
		draw_line(start, end, Color(0.25, 1.0, 0.15, 0.28), branch["thickness"], true)
		draw_circle(end, branch["thickness"] * 1.4, Color(0.42, 1.0, 0.16, 0.20))
		for slot in branch["slots"]:
			var pos = slot["pos"]
			var has_food = slot["food"] != null and slot["food"].get_ref() != null
			var slot_color = Color(0.40, 1.0, 0.10, 0.22 if has_food else 0.10)
			draw_circle(pos, branch["thickness"] * (1.8 if has_food else 1.1), slot_color)

	for i in range(18 if is_giant else 9):
		var a = TAU * float(i) / float(18 if is_giant else 9) + sin(float(i) * 1.7) * 0.12
		var p = Vector2(cos(a), sin(a)) * base_radius * randf_range(0.18, 0.52)
		draw_circle(p, randf_range(3.0, 8.0) * (1.5 if is_giant else 1.0), Color(0.62, 1.0, 0.20, 0.18))

func _get_extent_radius() -> float:
	var extent = base_radius
	for branch in branches:
		extent = max(extent, branch["length"])
	return extent

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
