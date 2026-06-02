extends RigidBody2D

@export var min_radius: float = 14.0
@export var max_radius: float = 118.0
@export var current_force: float = 9.0
@export var max_drift_speed: float = 22.0
@export var food_push_strength: float = 58.0

var radius = 40.0
var rim_points = 36
var spoke_count = 28
var ring_count = 3
var wobble_seed = 0.0
var drift_spin = 0.0
var base_color = Color(0.58, 0.72, 0.95, 0.34)
var world_manager: Node = null

@onready var collision_shape = $CollisionShape2D
@onready var food_push_area = $FoodPushArea
@onready var food_push_shape = $FoodPushArea/CollisionShape2D

func _ready():
	add_to_group("obstacles")
	world_manager = get_parent().get_node_or_null("WorldManager")
	can_sleep = false
	radius = lerp(min_radius, max_radius, pow(randf(), 1.55))
	rim_points = randi_range(30, 48)
	spoke_count = randi_range(18, 34)
	ring_count = randi_range(2, 4)
	wobble_seed = randf() * TAU
	base_color = Color(
		randf_range(0.48, 0.70),
		randf_range(0.62, 0.82),
		randf_range(0.88, 1.0),
		randf_range(0.055, 0.13)
	)

	var shape = CircleShape2D.new()
	shape.radius = radius * 0.92
	collision_shape.shape = shape
	var push_shape = CircleShape2D.new()
	push_shape.radius = radius * 1.06
	food_push_shape.shape = push_shape
	mass = max(1.0, radius * radius * 0.018)
	linear_damp = randf_range(1.5, 2.4)
	angular_damp = 0.05
	drift_spin = randf_range(0.035, 0.085) * (-1.0 if randf() < 0.5 else 1.0)
	angular_velocity = drift_spin
	queue_redraw()

func _physics_process(delta):
	sleeping = false
	var current = _sample_liquid_current(global_position, Time.get_ticks_msec() * 0.001 + wobble_seed)
	apply_central_force(current * current_force * mass)
	angular_velocity = move_toward(angular_velocity, drift_spin, 0.08 * delta)

	if linear_velocity.length() > max_drift_speed:
		linear_velocity = linear_velocity.limit_length(max_drift_speed)
	_push_nearby_food()

	var clamped_position = _clamp_to_arena(global_position, radius + 8.0)
	if clamped_position != global_position:
		global_position = clamped_position
		linear_velocity *= -0.25

func _draw():
	var fill = base_color
	var rim = Color(0.80, 0.90, 1.0, 0.22)
	var inner = Color(0.88, 0.94, 1.0, 0.15)
	var shadow = Color(0.18, 0.26, 0.36, 0.075)

	draw_circle(Vector2.ZERO, radius, fill)
	draw_arc(Vector2.ZERO, radius * 0.98, 0.0, TAU, rim_points, rim, 2.0, true)
	draw_arc(Vector2.ZERO, radius * 0.78, 0.0, TAU, rim_points, inner, 1.2, true)
	draw_arc(Vector2.ZERO, radius * 0.42, 0.0, TAU, rim_points, inner, 1.3, true)
	draw_circle(Vector2.ZERO, radius * 0.28, Color(0.82, 0.88, 1.0, 0.08))

	for i in range(spoke_count):
		var angle = TAU * float(i) / float(spoke_count)
		var dir = Vector2(cos(angle), sin(angle))
		var start = dir * radius * randf_range(0.30, 0.38)
		var end = dir * radius * randf_range(0.78, 0.93)
		draw_line(start, end, Color(0.88, 0.94, 1.0, 0.13), 1.0, true)

	for ring in range(ring_count):
		var ring_radius = radius * lerp(0.50, 0.88, float(ring) / float(max(ring_count - 1, 1)))
		var teeth = spoke_count
		for i in range(teeth):
			if i % 2 == 0:
				var a0 = TAU * float(i) / float(teeth)
				var a1 = TAU * float(i + 1) / float(teeth)
				draw_arc(Vector2.ZERO, ring_radius, a0, a1, 3, shadow, 1.0, true)

	for i in range(rim_points):
		if i % 3 == 0:
			var angle = TAU * float(i) / float(rim_points)
			var dir = Vector2(cos(angle), sin(angle))
			draw_line(dir * radius * 0.95, dir * radius * 1.06, rim, 1.4, true)

func _push_nearby_food():
	var push_radius = radius * 1.15 + 22.0
	var foods = []
	if world_manager and world_manager.has_method("get_food_near"):
		foods = world_manager.get_food_near(global_position, push_radius)
	else:
		foods = get_tree().get_nodes_in_group("food")

	for food in foods:
		if !is_instance_valid(food) or !food.is_in_group("food"):
			continue
		if food.has_method("push_from_obstacle"):
			food.push_from_obstacle(global_position, radius, linear_velocity, food_push_strength)

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
