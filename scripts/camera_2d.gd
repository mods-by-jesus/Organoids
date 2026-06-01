extends Camera2D

@export var move_speed: float = 1000.0
@export var zoom_speed: float = 1.1

var dragging = false
var grid_material: ShaderMaterial
var ui: CanvasLayer
var last_grid_camera_offset = Vector2(1.0e20, 1.0e20)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	make_current()
	ui = get_tree().current_scene.get_node_or_null("UI")
	var grid_node = get_tree().current_scene.find_child("BackgroundGrid", true)
	if grid_node:
		grid_material = grid_node.material

func _input(event):
	if event is InputEventMouseButton:
		var over_species_panel = ui and ui.has_method("is_pointer_over_species_panel") and ui.is_pointer_over_species_panel()
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if over_species_panel:
				return
			_select_at_mouse()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if ui and ui.has_method("clear_species_selection"):
				ui.clear_species_selection()
			if over_species_panel:
				return
			_deselect()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if over_species_panel:
				return
			_zoom_at_mouse(zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if over_species_panel:
				return
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
	var cells = ui.call("_get_registered_cells") if ui and ui.has_method("_get_registered_cells") else get_tree().get_nodes_in_group("cells")
	var closest = null
	var min_dist_sq = 10000.0
	
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
