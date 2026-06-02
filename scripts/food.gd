extends Area2D

@export var energy_value: float = 50.0
@export var is_cell_remains: bool = false

@onready var visual = $Visual

var rotation_speed: float = 0.0
var current_speed: float = 0.0
var external_velocity = Vector2.ZERO
var world_manager: Node = null
var spatial_update_timer = 0.0
<<<<<<< Updated upstream
=======
var growth_anchor: Node2D = null
var growth_anchor_local_position = Vector2.ZERO
var is_growth_attached = false
>>>>>>> Stashed changes

func _ready():
	add_to_group("food")
	world_manager = get_parent().get_node_or_null("WorldManager")
	if world_manager and world_manager.has_method("register_food_node"):
		world_manager.register_food_node(self)
	tree_exiting.connect(_on_tree_exiting)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Случайная скорость вращения, скорость течения и размер
	rotation_speed = randf_range(-1.6, 1.6)
	current_speed = randf_range(6.0, 15.0)
	spatial_update_timer = randf() * 0.2
	scale = Vector2.ONE * randf_range(0.75, 1.28)
	
	# Настройка индивидуального оттенка зеленого и уникальной формы в шейдере
	if visual and visual.material:
		visual.material = visual.material.duplicate()
		var r_val = randf_range(0.72, 0.98) if is_cell_remains else randf_range(0.12, 0.35)
		var g_val = randf_range(0.12, 0.28) if is_cell_remains else randf_range(0.72, 0.96)
		var b_val = randf_range(0.10, 0.22) if is_cell_remains else randf_range(0.18, 0.42)
		visual.material.set_shader_parameter("base_color", Color(r_val, g_val, b_val))
		visual.material.set_shader_parameter("shape_lobes", float(randi_range(3, 7)))
		visual.material.set_shader_parameter("shape_roughness", randf_range(0.06, 0.16))

func _process(delta):
	# Вращение еды
	rotation += rotation_speed * delta

	if is_growth_attached:
		if is_instance_valid(growth_anchor):
			global_position = growth_anchor.to_global(growth_anchor_local_position)
			spatial_update_timer -= delta
			if spatial_update_timer <= 0.0 and world_manager and world_manager.has_method("update_food_spatial"):
				spatial_update_timer = 0.2
				world_manager.update_food_spatial(self)
		else:
			is_growth_attached = false
		return
	
	# Мягкое плавание по течению жидкости
	var current = _sample_liquid_current(global_position, Time.get_ticks_msec() * 0.001)
<<<<<<< Updated upstream
	global_position = _clamp_to_arena(global_position + current * current_speed * delta, 12.0)
=======
	global_position = _clamp_to_arena(global_position + (current * current_speed + external_velocity) * delta, 12.0)
	external_velocity = external_velocity.move_toward(Vector2.ZERO, 45.0 * delta)
>>>>>>> Stashed changes
	spatial_update_timer -= delta
	if spatial_update_timer <= 0.0 and world_manager and world_manager.has_method("update_food_spatial"):
		spatial_update_timer = 0.2
		world_manager.update_food_spatial(self)

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

func _on_body_entered(body):
	if body.is_in_group("cells") and body.has_method("eat"):
		if !can_be_eaten_by(body):
			return
		var was_eaten = false
		if is_cell_remains and body.has_method("eat_cell_remains"):
			was_eaten = body.eat_cell_remains(energy_value)
		else:
			was_eaten = body.eat(energy_value)
		if was_eaten:
			queue_free()

func _on_area_entered(area):
	pass

<<<<<<< Updated upstream
=======
func push_from_obstacle(obstacle_position: Vector2, obstacle_radius: float, obstacle_velocity: Vector2, strength: float):
	if is_growth_attached:
		return
	var away = global_position - obstacle_position
	var distance = max(away.length(), 0.001)
	var push_range = obstacle_radius + 22.0 * max(scale.x, scale.y)
	if distance > push_range:
		return
	var overlap = 1.0 - clamp(distance / push_range, 0.0, 1.0)
	var push_dir = away / distance
	external_velocity += push_dir * strength * overlap
	external_velocity += obstacle_velocity * 0.55 * overlap
	external_velocity = external_velocity.limit_length(125.0)

func set_growth_anchor(anchor: Node2D, local_position: Vector2):
	growth_anchor = anchor
	growth_anchor_local_position = local_position
	is_growth_attached = true
	current_speed = 0.0
	external_velocity = Vector2.ZERO

>>>>>>> Stashed changes
func can_be_eaten_by(body) -> bool:
	if !is_instance_valid(body):
		return false
	if is_cell_remains:
		return body.has_method("can_eat_cell_remains") and body.can_eat_cell_remains()
	return !body.has_method("can_eat_floor_food") or body.can_eat_floor_food()

func _on_tree_exiting():
	if world_manager and world_manager.has_method("unregister_food_node"):
		world_manager.unregister_food_node(self)
