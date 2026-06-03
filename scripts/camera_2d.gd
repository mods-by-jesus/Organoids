extends Camera2D

@export var move_speed: float = 1000.0
@export var zoom_speed: float = 1.1

var dragging = false
var grid_material: ShaderMaterial
var ui: CanvasLayer
var world_manager: Node
var last_grid_camera_offset = Vector2(1.0e20, 1.0e20)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	make_current()
	ui = get_tree().current_scene.get_node_or_null("UI")
	world_manager = get_tree().current_scene.get_node_or_null("WorldManager")
	var grid_node = get_tree().current_scene.find_child("BackgroundGrid", true)
	if grid_node:
		grid_material = grid_node.material

func _input(event):
	if event is InputEventMouseButton:
		var over_species_panel = ui and ui.has_method("is_pointer_over_species_panel") and ui.is_pointer_over_species_panel()
		var over_draggable = ui and ui.has_method("is_pointer_over_draggable_panel") and ui.is_pointer_over_draggable_panel()
		var over_species_ledger = ui and ui.has_method("is_pointer_over_species_ledger") and ui.is_pointer_over_species_ledger()
		
		# Полная блокировка только для species ledger (модальное окно)
		if over_species_ledger:
			return
			
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Блокируем выбор клетки если клик на UI элементах
			if over_species_panel or over_draggable:
				return
			_select_at_mouse()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if ui and ui.has_method("clear_species_selection"):
				ui.clear_species_selection()
			# Блокируем снятие выделения если клик на UI
			if over_species_panel or over_draggable:
				return
			_deselect()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			# Зум работает всегда, даже над панелями
			_zoom_at_mouse(zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# Зум работает всегда, даже над панелями
			_zoom_at_mouse(1.0 / zoom_speed)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed

	if event is InputEventMouseMotion and dragging:
		global_position -= event.relative / zoom

func _process(delta):
	var dir = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A): dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D): dir.x += 1
	if Input.is_physical_key_pressed(KEY_W): dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S): dir.y += 1
	
	if dir != Vector2.ZERO:
		var unscaled_delta = delta / Engine.time_scale if Engine.time_scale > 0.0 else 0.0
		global_position += dir.normalized() * (move_speed / zoom.x) * unscaled_delta
	
	if grid_material:
		var camera_offset = -global_position * zoom.x
		if camera_offset != last_grid_camera_offset:
			last_grid_camera_offset = camera_offset
			grid_material.set_shader_parameter("camera_offset", camera_offset)

func _select_at_mouse():
	var mouse_pos = get_global_mouse_position()
	var pick_radius = 100.0
	var cells = []
	if is_instance_valid(world_manager) and world_manager.has_method("get_cells_near"):
		cells = world_manager.get_cells_near(mouse_pos, pick_radius)
	else:
		cells = ui.call("_get_registered_cells") if ui and ui.has_method("_get_registered_cells") else get_tree().get_nodes_in_group("cells")
	var closest = null
	var min_dist_sq = pick_radius * pick_radius
	
	for cell in cells:
		if !is_instance_valid(cell) or cell.get("is_dying") or cell.get("pending_death"):
			continue
		var dist_sq = mouse_pos.distance_squared_to(cell.global_position)
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			closest = cell
	
	if ui:
		ui.select_cell(closest)

func _deselect():
	if ui:
		ui.select_cell(null)

func _zoom_at_mouse(factor):
	var mouse_pos = get_global_mouse_position()
	var next_zoom = clamp(zoom.x * factor, 0.01, 50.0)
	
	if next_zoom != zoom.x:
		zoom = Vector2(next_zoom, next_zoom)
		var new_mouse_pos = get_global_mouse_position()
		global_position += (mouse_pos - new_mouse_pos)
		if ui and ui.has_method("_redraw_cells"):
			ui._redraw_cells()

func pan_to_position(target_pos: Vector2, duration: float = 0.6):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", target_pos, duration)
