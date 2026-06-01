@tool
extends Node2D

@export_group("Arena Settings")
@export var arena_size: float = 2048.0:
	set(value):
		arena_size = value
		update_arena()

@export var border_thickness: float = 40.0:
	set(value):
		border_thickness = value
		update_arena()

@onready var grid = $BackgroundGrid
@onready var walls = $World/Walls
@onready var visual_border = $World/VisualBorder

func _ready():
	update_arena()

func update_arena():
	if !is_inside_tree(): return
	
	var half = arena_size / 2.0
	
	# Обновляем сетку
	var grid_node = grid if grid else get_node_or_null("BackgroundGrid")
	if grid_node:
		grid_node.offset_left = -half
		grid_node.offset_top = -half
		grid_node.offset_right = half
		grid_node.offset_bottom = half
		
	# Обновляем жидкую среду (шейдер)
	var liquid_node = get_node_or_null("LiquidMedium")
	if liquid_node:
		liquid_node.offset_left = -half
		liquid_node.offset_top = -half
		liquid_node.offset_right = half
		liquid_node.offset_bottom = half
		
	# Обновляем пузырьки на заднем фоне
	var bubbles_node = get_node_or_null("BackgroundBubbles")
	if bubbles_node:
		bubbles_node.visibility_rect = Rect2(-half, -half, arena_size, arena_size)
		if bubbles_node.process_material is ParticleProcessMaterial:
			# Дублируем материал в редакторе, чтобы не загрязнить оригинальный ресурс
			if Engine.is_editor_hint():
				bubbles_node.process_material = bubbles_node.process_material.duplicate()
			bubbles_node.process_material.emission_box_extents = Vector3(half, half, 1.0)
			
			# Масштабируем количество пузырьков в зависимости от площади арены
			# Базовое количество — 400 для размера 2048
			var size_ratio = arena_size / 2048.0
			bubbles_node.amount = int(400 * size_ratio * size_ratio)
	
	# Обновляем коллизии
	var walls_node = walls if walls else get_node_or_null("World/Walls")
	if walls_node:
		_set_pos(walls_node, "Collision_Top", Vector2(0, -half))
		_set_pos(walls_node, "Collision_Bottom", Vector2(0, half))
		_set_pos(walls_node, "Collision_Left", Vector2(-half, 0))
		_set_pos(walls_node, "Collision_Right", Vector2(half, 0))
		
	# Обновляем визуальные границы
	var visual_border_node = visual_border if visual_border else get_node_or_null("World/VisualBorder")
	if visual_border_node:
		var t = border_thickness
		_setup_rect(visual_border_node.get_node("Line_Top"), -half - t, -half - t, arena_size + t*2, t)
		_setup_rect(visual_border_node.get_node("Line_Bottom"), -half - t, half, arena_size + t*2, t)
		_setup_rect(visual_border_node.get_node("Line_Left"), -half - t, -half, t, arena_size)
		_setup_rect(visual_border_node.get_node("Line_Right"), half, -half, t, arena_size)

func _set_pos(parent, node_name, pos):
	var n = parent.get_node_or_null(node_name)
	if n: n.position = pos

func _setup_rect(node, x, y, w, h):
	if node:
		node.offset_left = x
		node.offset_top = y
		node.offset_right = x + w
		node.offset_bottom = y + h
