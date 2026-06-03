extends Area2D

@export var energy_value: float = 50.0
@export var is_cell_remains: bool = false
var source_species_id: int = 0

@onready var visual = $Visual

var rotation_speed: float = 0.0
var current_speed: float = 0.0
var external_velocity = Vector2.ZERO
var world_manager: Node = null
var spatial_update_timer = 0.0
var growth_anchor: Node2D = null
var growth_anchor_local_position = Vector2.ZERO
var is_growth_attached = false
var is_active = true

func _ready():
	add_to_group("food")
	world_manager = get_parent().get_node_or_null("WorldManager")
	monitoring = false
	monitorable = false
	collision_layer = 0
	collision_mask = 0
	set_process(false)
	if world_manager and world_manager.has_method("register_food_node"):
		world_manager.register_food_node(self)
	tree_exiting.connect(_on_tree_exiting)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	_randomize_food_state()

func _randomize_food_state():
	rotation_speed = randf_range(-1.6, 1.6)
	current_speed = randf_range(6.0, 15.0)
	spatial_update_timer = randf() * 0.2
	scale = Vector2.ONE * randf_range(0.75, 1.28)
	
	# Настройка индивидуального оттенка зеленого и уникальной формы в шейдере
	if visual:
		var r_val = randf_range(0.72, 0.98) if is_cell_remains else randf_range(0.12, 0.35)
		var g_val = randf_range(0.12, 0.28) if is_cell_remains else randf_range(0.72, 0.96)
		var b_val = randf_range(0.10, 0.22) if is_cell_remains else randf_range(0.18, 0.42)
		visual.color = Color(r_val, g_val, b_val, 1.0)

func _process(delta):
	simulation_step(delta)

func simulation_step(delta):
	if !is_active:
		return
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
	global_position = _clamp_to_arena(global_position + (current * current_speed + external_velocity) * delta, 12.0)
	external_velocity = external_velocity.move_toward(Vector2.ZERO, 45.0 * delta)
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
	if !is_active:
		return
	try_consume_by(body)

func _on_area_entered(area):
	pass

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
	rotation_speed *= 0.18
	scale *= 0.88
	if visual:
		visual.color = Color(randf_range(0.30, 0.48), randf_range(0.88, 1.0), randf_range(0.18, 0.34), 1.0)

func get_navigation_position_for(body: Node2D) -> Vector2:
	if is_growth_attached and is_instance_valid(growth_anchor):
		var away = global_position - growth_anchor.global_position
		if away == Vector2.ZERO and is_instance_valid(body):
			away = global_position - body.global_position
		if away == Vector2.ZERO:
			away = Vector2.RIGHT
		var anchor_radius = float(growth_anchor.get("radius")) if growth_anchor.get("radius") != null else 48.0
		var safe_distance = anchor_radius + 18.0
		var desired = growth_anchor.global_position + away.normalized() * max(away.length(), safe_distance)
		return desired
	return global_position

func reactivate_from_pool(spawn_position: Vector2, remains: bool, value: float, source_id: int):
	is_active = true
	visible = true
	monitoring = false
	monitorable = false
	collision_layer = 0
	collision_mask = 0
	set_process(false)
	is_cell_remains = remains
	energy_value = value
	source_species_id = source_id
	global_position = spawn_position
	growth_anchor = null
	growth_anchor_local_position = Vector2.ZERO
	is_growth_attached = false
	external_velocity = Vector2.ZERO
	if !is_in_group("food"):
		add_to_group("food")
	_randomize_food_state()
	if world_manager and world_manager.has_method("register_food_node"):
		world_manager.register_food_node(self)

func recycle_to_pool():
	if !is_active:
		return
	if world_manager and world_manager.has_method("unregister_food_node"):
		world_manager.unregister_food_node(self)
	is_active = false
	visible = false
	monitoring = false
	monitorable = false
	collision_layer = 0
	collision_mask = 0
	set_process(false)
	growth_anchor = null
	is_growth_attached = false
	external_velocity = Vector2.ZERO
	remove_from_group("food")

func _release_food():
	if is_growth_attached:
		queue_free()
		return
	if world_manager and world_manager.has_method("recycle_food_node"):
		world_manager.recycle_food_node(self)
	else:
		queue_free()

func try_consume_by(body) -> bool:
	if !is_active:
		return false
	if !is_instance_valid(body) or !body.is_in_group("cells") or !body.has_method("eat"):
		return false
	if !can_be_eaten_by(body):
		return false
	var was_eaten = false
	if is_cell_remains and body.has_method("eat_cell_remains"):
		was_eaten = body.eat_cell_remains(energy_value, source_species_id)
	else:
		was_eaten = body.eat(energy_value)
	if was_eaten:
		_release_food()
	return was_eaten

func set_world_visual_time_state(multiplier: float, offset: float):
	if visual and visual.material:
		visual.material.set_shader_parameter("time_multiplier", multiplier)
		visual.material.set_shader_parameter("time_offset", offset)

func set_world_visual_time_multiplier(value: float):
	set_world_visual_time_state(value, 0.0)

func can_be_eaten_by(body) -> bool:
	if !is_instance_valid(body):
		return false
	if is_cell_remains:
		return body.has_method("can_eat_cell_remains") and body.can_eat_cell_remains()
	return !body.has_method("can_eat_floor_food") or body.can_eat_floor_food()

func _on_tree_exiting():
	if is_active and world_manager and world_manager.has_method("unregister_food_node"):
		world_manager.unregister_food_node(self)
