extends CanvasLayer

const PHAGOCYTOSIS_GENE_THRESHOLD = 0.35
const HEMIBIOTROPH_AGGRESSION_THRESHOLD = 0.4
const FEAR_GENE_THRESHOLD = 0.01
const THRESHOLD_MARKER_WIDTH = 2.0
const THRESHOLD_MARKER_COLOR = Color(1.0, 1.0, 1.0, 0.9)
const SPECIES_REFRESH_INTERVAL = 0.35
const ICON_SPECIES_ALIVE = preload("res://sprites/ui/icon-species-alive.png")
const ICON_SPECIES_DEAD = preload("res://sprites/ui/icon-species-dead.png")
const ICON_SPECIES_LEDGER = preload("res://sprites/ui/icon-species-ledger.png")

class SpeciesPreview:
	extends Control

	const CELL_SHADER = preload("res://shaders/cell.gdshader")
	const ICON_BIOTROPH = preload("res://sprites/ui/gene-biotroph.png")
	const ICON_HEMIBIOTROPH = preload("res://sprites/ui/gene-hemibiotroph.png")
	const ICON_NECROTROPH = preload("res://sprites/ui/gene-necrotroph.png")
	const ICON_RELATION = preload("res://sprites/ui/icon-species-relation.png")

	var species_id = 0
	var species_color: Color = Color.WHITE
	var is_selected = false
	var is_related = false
	var elongation = 0.0
	var spikiness = 0.0
	var amoeboid = 0.0
	var tendrils = 0.0
	var lobes = 0.0
	var boxy = 0.0
	var worm = 0.0
	var spiral = 0.0
	var roughness = 0.25
	var asymmetry = 0.12
	var nucleus_size = 0.3
	var bioluminescence = 0.0
	var aggressiveness = 0.0
	var shader_material: ShaderMaterial = null
	var last_time_multiplier := -1.0

	func _ready():
		var side = max(custom_minimum_size.x, custom_minimum_size.y, 58.0)
		custom_minimum_size = Vector2(side, side)
		size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true

		var shader_rect = ColorRect.new()
		shader_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shader_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shader_rect.offset_left = 6.0
		shader_rect.offset_top = 6.0
		shader_rect.offset_right = -6.0
		shader_rect.offset_bottom = -6.0

		shader_material = ShaderMaterial.new()
		shader_material.shader = CELL_SHADER
		shader_material.set_shader_parameter("base_color", Vector3(species_color.r, species_color.g, species_color.b))
		shader_material.set_shader_parameter("pulse_speed", 1.35 + float(species_id % 7) * 0.11)
		shader_material.set_shader_parameter("energy_ratio", 0.88)
		shader_material.set_shader_parameter("deformation", 0.045 + roughness * 0.20)
		shader_material.set_shader_parameter("membrane_roughness", roughness)
		shader_material.set_shader_parameter("membrane_asymmetry", asymmetry)
		shader_material.set_shader_parameter("nucleus_size", nucleus_size)
		shader_material.set_shader_parameter("bioluminescence", bioluminescence)
		shader_material.set_shader_parameter("motion_deform", 0.10 + asymmetry * 0.22)
		shader_material.set_shader_parameter("motion_direction", Vector2.RIGHT.rotated(float(species_id % 17) * 0.37))
		shader_material.set_shader_parameter("split_pressure", 0.0)
		shader_material.set_shader_parameter("dissolve", 0.0)
		shader_material.set_shader_parameter("visual_padding", _get_visual_padding())
		shader_material.set_shader_parameter("shape_elongation", elongation)
		shader_material.set_shader_parameter("shape_spikiness", spikiness)
		shader_material.set_shader_parameter("shape_amoeboid", amoeboid)
		shader_material.set_shader_parameter("shape_tendrils", tendrils)
		shader_material.set_shader_parameter("shape_lobes", lobes)
		shader_material.set_shader_parameter("shape_boxy", boxy)
		shader_material.set_shader_parameter("shape_worm", worm)
		shader_material.set_shader_parameter("shape_spiral", spiral)
		_update_preview_time_multiplier(true)
		shader_rect.material = shader_material
		add_child(shader_rect)

		# Иконка трофического типа в правом нижнем углу
		var icon_rect = TextureRect.new()
		icon_rect.name = "TrophicIcon"
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.custom_minimum_size = Vector2(16, 16)
		icon_rect.anchor_left = 1.0
		icon_rect.anchor_top = 1.0
		icon_rect.anchor_right = 1.0
		icon_rect.anchor_bottom = 1.0
		icon_rect.offset_left = -18.0
		icon_rect.offset_top = -18.0
		icon_rect.offset_right = -2.0
		icon_rect.offset_bottom = -2.0
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(icon_rect)

		var relation_rect = TextureRect.new()
		relation_rect.name = "RelationIcon"
		relation_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		relation_rect.custom_minimum_size = Vector2(15, 15)
		relation_rect.anchor_left = 0.0
		relation_rect.anchor_top = 1.0
		relation_rect.anchor_right = 0.0
		relation_rect.anchor_bottom = 1.0
		relation_rect.offset_left = 2.0
		relation_rect.offset_top = -17.0
		relation_rect.offset_right = 17.0
		relation_rect.offset_bottom = -2.0
		relation_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		relation_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		relation_rect.texture = ICON_RELATION
		relation_rect.modulate = Color(0.75, 1.0, 0.92, 0.95)
		relation_rect.visible = false
		add_child(relation_rect)

		# Счетчик представителей в левом верхнем углу
		var count_label = Label.new()
		count_label.name = "CountLabel"
		count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		count_label.add_theme_font_size_override("font_size", 10)
		count_label.add_theme_color_override("font_color", Color(0.92, 0.96, 0.96, 0.95))
		count_label.anchor_left = 0.0
		count_label.anchor_top = 0.0
		count_label.anchor_right = 0.0
		count_label.anchor_bottom = 0.0
		count_label.offset_left = 4.0
		count_label.offset_top = 2.0
		add_child(count_label)

		update_trophic_icon()
		update_relation_icon()

	func update_trophic_icon():
		var icon_rect = get_node_or_null("TrophicIcon")
		if icon_rect:
			var tex = ICON_BIOTROPH
			var color = Color(0.92, 1.0, 0.92) # Слабый оттенок зеленого, почти белый
			if aggressiveness >= 0.6:
				tex = ICON_NECROTROPH
				color = Color(1.0, 0.92, 0.92) # Слабый оттенок красного, почти белый
			elif aggressiveness >= HEMIBIOTROPH_AGGRESSION_THRESHOLD:
				tex = ICON_HEMIBIOTROPH
				color = Color(1.0, 1.0, 0.92) # Слабый оттенок желтого, почти белый
			icon_rect.texture = tex
			icon_rect.modulate = color

	func update_count(count: int):
		var count_label = get_node_or_null("CountLabel")
		if count_label:
			count_label.text = str(count)

	func update_relation_icon():
		var relation_rect = get_node_or_null("RelationIcon")
		if relation_rect:
			relation_rect.visible = is_related and !is_selected

	func _process(_delta):
		_update_preview_time_multiplier()

	func _get_preview_time_multiplier() -> float:
		return 1.0 / max(Engine.time_scale, 0.001)

	func _get_visual_padding() -> float:
		var bounds = 1.0 + worm * 2.6 + spiral * 1.2 + tendrils * 0.55 + lobes * 0.22 + boxy * 0.18 + elongation * 0.65
		return 1.65 * bounds

	func _update_preview_time_multiplier(force: bool = false):
		if !shader_material:
			return

		var value = _get_preview_time_multiplier()
		if force or !is_equal_approx(value, last_time_multiplier):
			last_time_multiplier = value
			shader_material.set_shader_parameter("time_multiplier", value)

	func _draw():
		var rect = Rect2(Vector2.ZERO, size)
		var bg = Color(0.03, 0.04, 0.04, 0.92)
		draw_rect(rect, bg, true)
		if worm > 0.48:
			var body_color = species_color
			body_color.a = 0.55
			var points = []
			var center = size * 0.5
			var length = size.x * clamp(0.34 + worm * 0.10, 0.34, 0.46)
			var tail_start_x = center.x + size.x * 0.14
			for i in range(7):
				var t = float(i) / 6.0
				var x = tail_start_x - length * t
				var y = center.y + sin(t * PI * 2.2 + float(species_id % 17)) * size.y * 0.055 * worm
				x = clamp(x, 7.0, max(size.x - 7.0, 7.0))
				y = clamp(y, 7.0, max(size.y - 7.0, 7.0))
				points.append(Vector2(x, y))
			for i in range(points.size() - 1):
				draw_line(points[i], points[i + 1], body_color, max(3.0, size.y * 0.10 * (1.0 - float(i) / 9.0)), true)
			for i in range(points.size()):
				var t = float(i) / float(max(points.size() - 1, 1))
				draw_circle(points[i], size.y * lerp(0.11, 0.065, t), body_color)
		var border = species_color if is_selected else Color(0.35, 0.42, 0.42, 0.75)
		if is_related and !is_selected:
			border = Color(0.65, 1.0, 0.86, 0.82)
		if is_selected:
			var glow = species_color
			glow.a = 0.22
			draw_rect(rect.grow(-2.0), glow, true)
			draw_rect(rect, species_color, false, 4.0)
			draw_rect(rect.grow(-5.0), Color(1.0, 1.0, 1.0, 0.55), false, 1.0)
		else:
			draw_rect(rect, border, false, 2.0)

@onready var panel = $Control/Panel
@onready var name_label = $Control/Panel/VBox/Header/Name
@onready var energy_bar = $Control/Panel/VBox/EnergyContainer/EnergyBar
@onready var energy_text = $Control/Panel/VBox/EnergyContainer/HBox/EnergyText

# Гены
@onready var speed_bar = $Control/Panel/VBox/Stats/Speed/SpeedBar
@onready var speed_text = $Control/Panel/VBox/Stats/Speed/HBox/Value

@onready var turn_bar = $Control/Panel/VBox/Stats/Turn/TurnBar
@onready var turn_text = $Control/Panel/VBox/Stats/Turn/HBox/Value

@onready var vision_bar = $Control/Panel/VBox/Stats/Vision/VisionBar
@onready var vision_text = $Control/Panel/VBox/Stats/Vision/HBox/Value

@onready var size_bar = $Control/Panel/VBox/Stats/Size/SizeBar
@onready var size_text = $Control/Panel/VBox/Stats/Size/HBox/Value

@onready var lifespan_bar = $Control/Panel/VBox/Stats/Lifespan/LifespanBar
@onready var lifespan_text = $Control/Panel/VBox/Stats/Lifespan/HBox/Value

@onready var phago_bar = $Control/Panel/VBox/Stats/Phagocytosis/PhagocytosisBar
@onready var phago_text = $Control/Panel/VBox/Stats/Phagocytosis/HBox/Value
var lysis_bar: ProgressBar = null
var lysis_text: Label = null
var flagella_bar: ProgressBar = null
var flagella_text: Label = null
var aggression_bar: ProgressBar = null
var aggression_text: Label = null
var mutation_bar: ProgressBar = null
var mutation_text: Label = null
var membrane_bar: ProgressBar = null
var membrane_text: Label = null
var chemotaxis_bar: ProgressBar = null
var chemotaxis_text: Label = null

@onready var fear_bar = $Control/Panel/VBox/Stats/Fear/FearBar
@onready var fear_text = $Control/Panel/VBox/Stats/Fear/HBox/Value

@onready var digestion_container = $Control/Panel/VBox/Stats/Digestion
@onready var digestion_bar = $Control/Panel/VBox/Stats/Digestion/DigestionBar
@onready var digestion_text = $Control/Panel/VBox/Stats/Digestion/HBox/Value

@onready var diet_label = $Control/Panel/VBox/Stats/Diet/Label

@onready var time_slider = $Control/TimePanel/VBox/TimeSlider
@onready var time_label = $Control/TimePanel/VBox/Label
@onready var btn_05 = $Control/TimePanel/VBox/SpeedButtons/Btn0_5x
@onready var btn_1 = $Control/TimePanel/VBox/SpeedButtons/Btn1x
@onready var btn_2 = $Control/TimePanel/VBox/SpeedButtons/Btn2x
@onready var btn_5 = $Control/TimePanel/VBox/SpeedButtons/Btn5x
@onready var btn_10 = $Control/TimePanel/VBox/SpeedButtons/Btn10x

var selected_cell: Node2D = null
var selected_species_id: int = 0
var fps_label: Label = null
var pause_button: Button = null
var pause_label: Label = null
var species_panel: PanelContainer = null
var species_scroll: ScrollContainer = null
var species_list: GridContainer = null
var species_ledger_overlay: PanelContainer = null
var species_ledger_alive_grid: GridContainer = null
var species_ledger_dead_grid: GridContainer = null
var species_ledger_summary_label: Label = null
var species_ledger_detail_label: Label = null
var species_cards = {}
var species_refresh_timer = 0.0
var species_panel_signature = ""
var species_ledger_signature = ""
var highlighted_species_redraw_ids = {}
var world_manager: Node = null
var _scroll_target: float = 0.0
var _scroll_speed: float = 5.0
var related_species_ids: Array = []
var selected_species_snapshot: Dictionary = {}
var selected_species_snapshot_alive := false
var world_shader_time_offset := 0.0
var world_shader_frozen_time := 0.0

# Drag state
var _drag_info = {
	"panel": {"dragging": false, "offset": Vector2.ZERO, "initial": Vector2.ZERO},
	"time_panel": {"dragging": false, "offset": Vector2.ZERO, "initial": Vector2.ZERO},
	"species_panel": {"dragging": false, "offset": Vector2.ZERO, "initial": Vector2.ZERO},
	"species_ledger": {"dragging": false, "offset": Vector2.ZERO, "initial": Vector2.ZERO}
}

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.hide()
	world_manager = get_tree().current_scene.get_node_or_null("WorldManager")
	_build_fps_label()
	_build_pause_controls()
	_build_extra_gene_rows()
	_build_species_panel()
	_build_species_ledger_overlay()
	
	# Сделать панели draggable
	_make_panel_draggable($Control/Panel, "panel")
	_make_panel_draggable($Control/TimePanel, "time_panel")
	
	if diet_label:
		diet_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		diet_label.add_theme_font_size_override("font_size", 13)
	if time_slider:
		time_slider.value_changed.connect(_on_time_changed)
		btn_05.pressed.connect(func(): time_slider.value = 0.5)
		btn_1.pressed.connect(func(): time_slider.value = 1.0)
		btn_2.pressed.connect(func(): time_slider.value = 2.0)
		btn_5.pressed.connect(func(): time_slider.value = 5.0)
		btn_10.pressed.connect(func(): time_slider.value = 10.0)

		time_slider.value = Engine.time_scale
		_on_time_changed(Engine.time_scale)

func _on_time_changed(value):
	Engine.time_scale = value
	_update_time_label()

func _toggle_pause():
	var next_paused = !get_tree().paused
	if next_paused:
		world_shader_frozen_time = _get_shader_clock() + world_shader_time_offset
	else:
		world_shader_time_offset = world_shader_frozen_time - _get_shader_clock()
	get_tree().paused = next_paused
	_set_world_visual_pause(next_paused)
	_update_time_label()

func _set_world_visual_pause(paused: bool):
	var multiplier = 0.0 if paused else 1.0
	var offset = world_shader_frozen_time if paused else world_shader_time_offset
	for cell in _get_registered_cells():
		if is_instance_valid(cell) and cell.has_method("set_world_visual_time_state"):
			cell.set_world_visual_time_state(multiplier, offset)
		elif is_instance_valid(cell) and cell.has_method("set_world_visual_time_multiplier"):
			cell.set_world_visual_time_multiplier(multiplier)
	for food in get_tree().get_nodes_in_group("food"):
		if is_instance_valid(food) and food.has_method("set_world_visual_time_state"):
			food.set_world_visual_time_state(multiplier, offset)
		elif is_instance_valid(food) and food.has_method("set_world_visual_time_multiplier"):
			food.set_world_visual_time_multiplier(multiplier)
	var liquid = get_tree().current_scene.get_node_or_null("LiquidMedium")
	if liquid and liquid.material:
		liquid.material.set_shader_parameter("time_multiplier", multiplier)
		liquid.material.set_shader_parameter("time_offset", offset)
	var bubbles = get_tree().current_scene.get_node_or_null("BackgroundBubbles")
	if bubbles and bubbles is GPUParticles2D:
		bubbles.emitting = !paused

func _get_shader_clock() -> float:
	return Time.get_ticks_msec() * 0.001

func _update_time_label():
	if time_label:
		var prefix = "ПАУЗА | " if get_tree().paused else ""
		time_label.text = "%sСКОРОСТЬ ВРЕМЕНИ: %.1fx" % [prefix, Engine.time_scale]
	if pause_button:
		pause_button.text = ">" if get_tree().paused else "II"
	if pause_label:
		pause_label.visible = get_tree().paused

func _process(_delta):
	if fps_label:
		fps_label.text = str(Engine.get_frames_per_second())

	var unscaled_delta = _delta / max(Engine.time_scale, 0.001)
	species_refresh_timer -= unscaled_delta
	if species_refresh_timer <= 0.0:
		species_refresh_timer = SPECIES_REFRESH_INTERVAL
		_update_species_panel_v2()
		if is_instance_valid(species_ledger_overlay) and species_ledger_overlay.visible:
			_populate_species_ledger()

	if is_instance_valid(selected_cell):
		selected_species_snapshot.clear()
		panel.show()
		_update_ui()
	elif !selected_species_snapshot.is_empty():
		panel.show()
		_update_ui_from_species_snapshot()
	else:
		if panel.visible:
			panel.hide()
		selected_cell = null

	# Плавный скролл
	if is_instance_valid(species_scroll):
		var current := float(species_scroll.scroll_vertical)
		var diff := _scroll_target - current
		if abs(diff) > 0.5:
			species_scroll.scroll_vertical = int(current + diff * min(_scroll_speed * _delta, 1.0))
		else:
			species_scroll.scroll_vertical = int(_scroll_target)

func _build_extra_gene_rows():
	var stats = $Control/Panel/VBox/Stats
	if !stats or lysis_bar:
		return
	var phago_row = $Control/Panel/VBox/Stats/Phagocytosis
	var insert_index = phago_row.get_index() + 1 if phago_row else stats.get_child_count()
	var lysis_row = _make_gene_stat_row("Lysis", "ЛИЗИС")
	stats.add_child(lysis_row)
	stats.move_child(lysis_row, insert_index)
	lysis_text = lysis_row.get_node("HBox/Value")
	lysis_bar = lysis_row.get_node("Bar")

	var flagella_row = _make_gene_stat_row("Flagella", "ЖГУТИК")
	stats.add_child(flagella_row)
	stats.move_child(flagella_row, insert_index + 1)
	flagella_text = flagella_row.get_node("HBox/Value")
	flagella_bar = flagella_row.get_node("Bar")

	var aggression_row = _make_gene_stat_row("Aggression", "АГРЕССИЯ")
	stats.add_child(aggression_row)
	stats.move_child(aggression_row, insert_index + 2)
	aggression_text = aggression_row.get_node("HBox/Value")
	aggression_bar = aggression_row.get_node("Bar")

	var mutation_row = _make_gene_stat_row("Mutation", "МУТАЦИИ")
	stats.add_child(mutation_row)
	stats.move_child(mutation_row, insert_index + 3)
	mutation_text = mutation_row.get_node("HBox/Value")
	mutation_bar = mutation_row.get_node("Bar")

	var membrane_row = _make_gene_stat_row("Membrane", "МЕМБРАНА")
	stats.add_child(membrane_row)
	stats.move_child(membrane_row, insert_index + 4)
	membrane_text = membrane_row.get_node("HBox/Value")
	membrane_bar = membrane_row.get_node("Bar")

	var chemotaxis_row = _make_gene_stat_row("Chemotaxis", "ХЕМОТАКСИС")
	stats.add_child(chemotaxis_row)
	stats.move_child(chemotaxis_row, insert_index + 5)
	chemotaxis_text = chemotaxis_row.get_node("HBox/Value")
	chemotaxis_bar = chemotaxis_row.get_node("Bar")

func _make_gene_stat_row(row_name: String, label_text_value: String) -> VBoxContainer:
	var row = VBoxContainer.new()
	row.name = row_name
	row.layout_mode = 2
	row.add_theme_constant_override("separation", 4)

	var hbox = HBoxContainer.new()
	hbox.name = "HBox"
	hbox.layout_mode = 2
	row.add_child(hbox)

	var label = Label.new()
	label.name = "Label"
	label.layout_mode = 2
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
	label.add_theme_font_size_override("font_size", 14)
	label.text = label_text_value
	hbox.add_child(label)

	var value = Label.new()
	value.name = "Value"
	value.layout_mode = 2
	value.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0, 1.0))
	value.add_theme_font_size_override("font_size", 14)
	value.text = "0.00"
	hbox.add_child(value)

	var bar = ProgressBar.new()
	bar.name = "Bar"
	bar.custom_minimum_size = Vector2(0, 8)
	bar.layout_mode = 2
	bar.show_percentage = false
	if phago_bar:
		var bg = phago_bar.get_theme_stylebox("background")
		var fill = phago_bar.get_theme_stylebox("fill")
		if bg:
			bar.add_theme_stylebox_override("background", bg)
		if fill:
			bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)
	return row

func _input(event):
	if event is InputEventKey and event.pressed and !event.echo:
		if event.keycode == KEY_ESCAPE and is_instance_valid(species_ledger_overlay) and species_ledger_overlay.visible:
			_close_species_ledger()
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode == KEY_SPACE or event.physical_keycode == KEY_P:
			_toggle_pause()
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseButton and is_pointer_over_species_panel():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_scroll_species_list(-1)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_scroll_species_list(1)
			get_viewport().set_input_as_handled()

func _update_ui():
	if !is_instance_valid(selected_cell): return

	# Энергия
	var max_energy = selected_cell._get_max_energy() if selected_cell.has_method("_get_max_energy") else 200.0
	var lifespan_limit = selected_cell._get_lifespan_limit() if selected_cell.has_method("_get_lifespan_limit") else 360.0
	energy_bar.max_value = max_energy
	energy_bar.value = selected_cell.energy
	energy_text.text = "%d / %d" % [int(selected_cell.energy), int(max_energy)]

	# Подвижность (max ~800)
	var effective_speed = selected_cell._get_effective_speed() if selected_cell.has_method("_get_effective_speed") else selected_cell.genes.speed
	speed_bar.value = (effective_speed / 800.0) * 100.0
	speed_text.text = "%d" % int(effective_speed)

	# Поворотливость (max ~30)
	var effective_turn = selected_cell._get_effective_turn_speed() if selected_cell.has_method("_get_effective_turn_speed") else selected_cell.genes.turn_speed
	turn_bar.value = (effective_turn / 30.0) * 100.0
	turn_text.text = "%.1f" % effective_turn

	_update_extra_gene_ui(max_energy, lifespan_limit, effective_speed, effective_turn)

	# Восприятие (max ~600)
	var effective_vision = selected_cell._get_effective_vision() if selected_cell.has_method("_get_effective_vision") else selected_cell.genes.vision_range
	vision_bar.value = (effective_vision / 600.0) * 100.0
	vision_text.text = "%d" % int(effective_vision)

	# Агрессивность (Биотроф, Гемибиотроф, Некротроф)
	var trophic_info = _get_trophic_info(selected_cell.genes)
	var trophic_type = trophic_info["type"]
	var diet_color = trophic_info["color"]
	var abilities = _get_gene_abilities(selected_cell.genes)
	var ability_text = "нет выраженных" if abilities.is_empty() else ", ".join(abilities)
	diet_label.text = "ТИП: %s\nОСОБЕННОСТИ: %s" % [trophic_type, ability_text]
	diet_label.tooltip_text = "СТРАТЕГИЯ: %s" % _infer_strategy_from_genes(selected_cell.genes)
	diet_label.modulate = diet_color
	var shape_name = "Кокк"
	if selected_cell.has_method("get_shape_name"):
		shape_name = selected_cell.get_shape_name()

	var cell_id = selected_cell.get_instance_id() % 10000
	var species_name = str(selected_cell.get("species_name"))
	if species_name.strip_edges() == "":
		species_name = "Вид %03d" % int(selected_cell.get("species_id"))
	name_label.text = "%s №%04d | %s" % [shape_name, cell_id, species_name]

func _update_ui_from_species_snapshot():
	var data = selected_species_snapshot
	var sample_count = max(int(data.get("count", 1)), 1)
	var genes = _make_average_genes(data, sample_count)
	var size_value = clamp(genes.size, 0.55, 2.35)
	var max_energy = 200.0 * pow(size_value, 1.25)
	var lifespan_limit = 90.0 * pow(size_value, 0.35)
	var effective_speed = genes.speed / pow(size_value, 0.85)
	var effective_turn = genes.turn_speed / pow(size_value, 0.35)

	energy_bar.max_value = max_energy
	energy_bar.value = max_energy
	energy_text.text = "%d / %d" % [int(max_energy), int(max_energy)]
	speed_bar.value = (effective_speed / 800.0) * 100.0
	speed_text.text = "%d" % int(effective_speed)
	turn_bar.value = (effective_turn / 30.0) * 100.0
	turn_text.text = "%.1f" % effective_turn
	var effective_vision = genes.vision_range * (1.0 + genes.get("shape_spikiness", genes.get("spikiness", 0.0)) * 0.25 + genes.get("chemotaxis", 0.0) * 0.18) * pow(size_value, 0.4)
	vision_bar.value = (effective_vision / 600.0) * 100.0
	vision_text.text = "%d" % int(effective_vision)

	size_bar.value = inverse_lerp(0.55, 2.35, size_value) * 100.0
	size_text.text = "%.2f | скорость %.2f | поворот %.2f" % [size_value, effective_speed / max(genes.speed, 1.0), effective_turn / max(genes.turn_speed, 1.0)]
	lifespan_bar.value = 100.0 if !selected_species_snapshot_alive else 0.0
	lifespan_text.text = "последний представитель" if !selected_species_snapshot_alive else "среднее по виду"

	phago_bar.value = genes.phagocytosis * 100.0
	phago_text.text = "%.2f" % genes.phagocytosis
	_set_gene_threshold_marker(phago_bar, "ActivationThreshold", PHAGOCYTOSIS_GENE_THRESHOLD)
	_update_lysis_flagella_rows(genes)
	_update_behavior_gene_rows(genes)
	fear_bar.value = genes.fear * 100.0
	fear_text.text = "%.2f" % genes.fear
	_set_gene_threshold_marker(fear_bar, "ActivationThreshold", FEAR_GENE_THRESHOLD)
	digestion_container.visible = false

	var trophic_info = _get_trophic_info(genes)
	var trophic_type = trophic_info["type"]
	var diet_color = trophic_info["color"]
	var abilities = _get_gene_abilities(genes)
	var ability_text = "нет выраженных" if abilities.is_empty() else ", ".join(abilities)
	diet_label.text = "ТИП: %s\nОСОБЕННОСТИ: %s" % [trophic_type, ability_text]
	diet_label.tooltip_text = "СТРАТЕГИЯ: %s" % _infer_strategy_from_genes(genes)
	diet_label.modulate = diet_color
	var status = "среднее живого вида" if selected_species_snapshot_alive else "последний вымерший"
	name_label.text = "%s | %s" % [_get_species_display_name(int(data.get("id", 0)), data), status]

func _make_average_genes(data: Dictionary, sample_count: int) -> Dictionary:
	return {
		"speed": data.get("speed", 0.0) / sample_count,
		"turn_speed": data.get("turn_speed", 0.0) / sample_count,
		"vision_range": data.get("vision_range", 0.0) / sample_count,
		"size": data.get("size", 1.0) / sample_count,
		"mutation_rate": data.get("mutation_rate", 0.0) / sample_count,
		"phagocytosis": data.get("phagocytosis", 0.0) / sample_count,
		"enzyme_secretion": data.get("enzyme_secretion", 0.0) / sample_count,
		"membrane_resistance": data.get("membrane_resistance", 0.0) / sample_count,
		"chemotaxis": data.get("chemotaxis", 0.0) / sample_count,
		"flagella_power": data.get("flagella_power", 0.0) / sample_count,
		"fear": data.get("fear", 0.0) / sample_count,
		"aggressiveness": data.get("aggressiveness", 0.0) / sample_count,
		"membrane_roughness": data.get("roughness", 0.0) / sample_count,
		"membrane_asymmetry": data.get("asymmetry", 0.0) / sample_count,
		"nucleus_size": data.get("nucleus_size", 0.0) / sample_count,
		"bioluminescence": data.get("bioluminescence", 0.0) / sample_count,
		"shape_elongation": data.get("elongation", 0.0) / sample_count,
		"shape_spikiness": data.get("spikiness", 0.0) / sample_count,
		"shape_amoeboid": data.get("amoeboid", 0.0) / sample_count,
		"shape_tendrils": data.get("tendrils", 0.0) / sample_count,
		"shape_lobes": data.get("lobes", 0.0) / sample_count,
		"shape_boxy": data.get("boxy", 0.0) / sample_count,
		"shape_worm": data.get("worm", 0.0) / sample_count,
		"shape_spiral": data.get("spiral", 0.0) / sample_count,
		"amoeboid": data.get("amoeboid", 0.0) / sample_count,
		"worm": data.get("worm", 0.0) / sample_count
	}

func _get_trophic_info(genes: Dictionary) -> Dictionary:
	if genes.get("aggressiveness", 0.0) >= 0.6:
		return {"type": "НЕКРОТРОФ", "color": Color(1.0, 0.4, 0.4)}
	if genes.get("aggressiveness", 0.0) >= HEMIBIOTROPH_AGGRESSION_THRESHOLD:
		return {"type": "ГЕМИБИОТРОФ", "color": Color(1.0, 1.0, 0.4)}
	return {"type": "БИОТРОФ", "color": Color(0.4, 1.0, 0.4)}

func _get_gene_abilities(genes: Dictionary) -> Array:
	var abilities = []
	if genes.get("enzyme_secretion", 0.0) >= 0.35 and genes.get("aggressiveness", 0.0) >= 0.38:
		abilities.append("лизис")
	if genes.get("phagocytosis", 0.0) >= PHAGOCYTOSIS_GENE_THRESHOLD and genes.get("aggressiveness", 0.0) >= 0.45:
		abilities.append("фагоцитоз")
	if genes.get("fear", 0.0) > FEAR_GENE_THRESHOLD and genes.get("aggressiveness", 0.0) < 0.6:
		abilities.append("страх")
	if genes.get("flagella_power", 0.0) > 0.35:
		abilities.append("жгутик")
	if genes.get("chemotaxis", 0.0) > 0.35:
		abilities.append("хемотаксис")
	if genes.get("membrane_resistance", 0.2) > 0.55:
		abilities.append("плотная мембрана")
	return abilities

func _infer_strategy_from_genes(genes: Dictionary) -> String:
	var aggression = genes.get("aggressiveness", 0.0)
	var phago = genes.get("phagocytosis", 0.0)
	var enzyme = genes.get("enzyme_secretion", 0.0)
	var membrane = genes.get("membrane_resistance", 0.2)
	var chemotaxis = genes.get("chemotaxis", 0.0)
	var flagella = genes.get("flagella_power", 0.0)
	var worm = genes.get("shape_worm", genes.get("worm", 0.0))
	var amoeboid = genes.get("shape_amoeboid", genes.get("amoeboid", 0.0))
	var size = genes.get("size", 1.0)

	if enzyme >= 0.35 and aggression >= 0.38:
		return "ферментный хищник"
	if phago >= PHAGOCYTOSIS_GENE_THRESHOLD and aggression >= 0.45 and amoeboid > 0.28:
		return "амебоидный фагоцит"
	if flagella > 0.35 and chemotaxis > 0.25:
		return "жгутиковый искатель"
	if membrane > 0.58 and size > 1.15:
		return "защищенный дрейфующий"
	if chemotaxis > 0.40 and aggression < 0.4:
		return "собиратель"
	if aggression >= 0.45:
		return "контактный охотник"
	return "биотроф"

func _update_extra_gene_ui(max_energy: float, lifespan_limit: float, effective_speed: float, effective_turn: float):
	var raw_speed = max(selected_cell.genes.speed, 1.0)
	var raw_turn = max(selected_cell.genes.turn_speed, 1.0)
	var speed_factor = effective_speed / raw_speed
	var turn_factor = effective_turn / raw_turn
	var phago_gene = selected_cell.genes.phagocytosis if selected_cell.genes.has("phagocytosis") else 0.0
	var phago_ready = phago_gene >= PHAGOCYTOSIS_GENE_THRESHOLD and selected_cell.genes.aggressiveness >= 0.45
	var fear_gene = selected_cell.genes.fear if selected_cell.genes.has("fear") else 0.0
	var fear_active = fear_gene > FEAR_GENE_THRESHOLD and selected_cell.genes.aggressiveness < 0.6

	size_bar.value = inverse_lerp(0.55, 2.35, selected_cell.genes.size) * 100.0
	size_text.text = "%.2f | скорость %.2f | поворот %.2f" % [selected_cell.genes.size, speed_factor, turn_factor]

	lifespan_bar.value = clamp(selected_cell.age / max(lifespan_limit, 0.1), 0.0, 1.0) * 100.0
	lifespan_text.text = "%d / %d" % [int(selected_cell.age), int(lifespan_limit)]

	phago_bar.value = phago_gene * 100.0
	phago_text.text = "%.2f%s" % [phago_gene, " готов" if phago_ready else ""]
	phago_text.tooltip_text = "Фагоцитоз: %s\nПроглатывает только подходящую по размеру жертву." % ("готов" if phago_ready else "не готов")
	_set_gene_threshold_marker(phago_bar, "ActivationThreshold", PHAGOCYTOSIS_GENE_THRESHOLD)
	_update_lysis_flagella_rows(selected_cell.genes)
	_update_behavior_gene_rows(selected_cell.genes)

	fear_bar.value = fear_gene * 100.0
	fear_text.text = "%.2f%s" % [fear_gene, " активен" if fear_active else ""]
	fear_text.tooltip_text = "Мембрана: %.2f\nХемотаксис: %.2f\nЖгутик: %.2f" % [
		selected_cell.genes.get("membrane_resistance", 0.2),
		selected_cell.genes.get("chemotaxis", 0.0),
		selected_cell.genes.get("flagella_power", 0.0)
	]
	_set_gene_threshold_marker(fear_bar, "ActivationThreshold", FEAR_GENE_THRESHOLD)

	if selected_cell.digestion_energy_left > 0.0:
		var duration = max(selected_cell.digestion_duration, 0.1)
		var progress = 1.0 - clamp(selected_cell.digestion_timer / duration, 0.0, 1.0)
		digestion_container.visible = true
		digestion_bar.value = progress * 100.0
		digestion_text.text = "%d%% | запас %.1f" % [int(progress * 100.0), selected_cell.digestion_energy_left]
	else:
		digestion_container.visible = false

func _update_lysis_flagella_rows(genes: Dictionary):
	if lysis_bar and lysis_text:
		var enzyme_gene = genes.get("enzyme_secretion", 0.0)
		var lysis_ready = enzyme_gene >= 0.35 and genes.get("aggressiveness", 0.0) >= 0.38
		lysis_bar.value = enzyme_gene * 100.0
		lysis_text.text = "%.2f%s" % [enzyme_gene, " готов" if lysis_ready else ""]
		lysis_text.tooltip_text = "Ферментная атака рядом с целью. Скорость атаки растет от развития лизиса."
		_set_gene_threshold_marker(lysis_bar, "ActivationThreshold", 0.35)

	if flagella_bar and flagella_text:
		var flagella_gene = genes.get("flagella_power", 0.0)
		var worm_gene = genes.get("shape_worm", genes.get("worm", 0.0))
		var flagella_ready = flagella_gene > 0.35
		flagella_bar.value = flagella_gene * 100.0
		flagella_text.text = "%.2f%s" % [flagella_gene, " активен" if flagella_ready else ""]
		flagella_text.tooltip_text = "Жгутик работает как развитие хвоста: ускоряет движение вперед, если форма достаточно червеобразная."
		_set_gene_threshold_marker(flagella_bar, "ActivationThreshold", 0.35)

func _update_behavior_gene_rows(genes: Dictionary):
	if aggression_bar and aggression_text:
		var aggression = genes.get("aggressiveness", 0.0)
		aggression_bar.value = aggression * 100.0
		aggression_text.text = "%.2f" % aggression
		aggression_text.tooltip_text = "Определяет трофику: ниже 0.40 биотроф, 0.40-0.60 гемибиотроф, выше 0.60 некротроф."
		_set_gene_threshold_marker(aggression_bar, "MixedThreshold", HEMIBIOTROPH_AGGRESSION_THRESHOLD)
		_set_gene_threshold_marker(aggression_bar, "PredatorThreshold", 0.60)

	if mutation_bar and mutation_text:
		var mutation = genes.get("mutation_rate", 0.0)
		mutation_bar.value = clamp(mutation / 0.5, 0.0, 1.0) * 100.0
		mutation_text.text = "%.3f" % mutation
		mutation_text.tooltip_text = "Шанс и сила изменений генов при делении."

	if membrane_bar and membrane_text:
		var membrane = genes.get("membrane_resistance", 0.2)
		membrane_bar.value = membrane * 100.0
		membrane_text.text = "%.2f" % membrane
		membrane_text.tooltip_text = "Защита от ферментного урона лизиса."
		_set_gene_threshold_marker(membrane_bar, "DenseThreshold", 0.55)

	if chemotaxis_bar and chemotaxis_text:
		var chemotaxis = genes.get("chemotaxis", 0.0)
		chemotaxis_bar.value = chemotaxis * 100.0
		chemotaxis_text.text = "%.2f" % chemotaxis
		chemotaxis_text.tooltip_text = "Улучшает эффективный поиск целей и еды."

func select_cell(cell):
	var previous_cell = selected_cell
	selected_cell = cell
	selected_species_snapshot.clear()
	if is_instance_valid(previous_cell) and previous_cell != cell:
		previous_cell.queue_redraw()
	if is_instance_valid(cell):
		cell.queue_redraw()
	if !cell:
		panel.hide()
	else:
		var cell_species_id = int(cell.get("species_id"))
		if selected_species_id != cell_species_id:
			selected_species_id = cell_species_id
			_refresh_related_species_ids()
			species_panel_signature = "" # Сбрасываем подпись панели, чтобы форсировать обновление стилей/масштаба карточек
			_update_species_panel_v2(true)
			_redraw_cells()

func _build_fps_label():
	fps_label = Label.new()
	fps_label.name = "FPS"
	fps_label.layout_mode = 1
	fps_label.offset_left = 6.0
	fps_label.offset_top = 4.0
	fps_label.offset_right = 50.0
	fps_label.offset_bottom = 20.0
	fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fps_label.add_theme_font_size_override("font_size", 10)
	fps_label.add_theme_color_override("font_color", Color(0.75, 0.85, 0.82, 0.75))
	fps_label.text = "0"
	$Control.add_child(fps_label)

func _build_pause_controls():
	if btn_05 and btn_05.get_parent():
		pause_button = Button.new()
		pause_button.name = "PauseButton"
		pause_button.text = "II"
		pause_button.focus_mode = Control.FOCUS_NONE
		pause_button.custom_minimum_size = Vector2(34, 26)
		pause_button.pressed.connect(_toggle_pause)
		btn_05.get_parent().add_child(pause_button)
		btn_05.get_parent().move_child(pause_button, 0)

	pause_label = Label.new()
	pause_label.name = "PauseLabel"
	pause_label.layout_mode = 1
	pause_label.anchor_left = 0.5
	pause_label.anchor_right = 0.5
	pause_label.offset_left = -42.0
	pause_label.offset_top = 6.0
	pause_label.offset_right = 42.0
	pause_label.offset_bottom = 30.0
	pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_label.add_theme_font_size_override("font_size", 14)
	pause_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.58, 0.95))
	pause_label.text = "ПАУЗА"
	pause_label.visible = false
	$Control.add_child(pause_label)

func _build_species_panel():
	var root = $Control
	species_panel = PanelContainer.new()
	species_panel.name = "SpeciesPanel"
	species_panel.layout_mode = 1
	species_panel.anchor_left = 1.0
	species_panel.anchor_top = 1.0
	species_panel.anchor_right = 1.0
	species_panel.anchor_bottom = 1.0
	species_panel.offset_left = -300.0
	species_panel.offset_top = -410.0
	species_panel.offset_right = -30.0
	species_panel.offset_bottom = -90.0
	species_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	species_panel.gui_input.connect(Callable(self, "_on_species_panel_gui_input"))
	species_panel.add_theme_stylebox_override("panel", _make_panel_style())
	root.add_child(species_panel)
	
	# Делаем панель видов draggable
	_make_panel_draggable(species_panel, "species_panel")

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	species_panel.add_child(vbox)

	var title_row = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 6)
	vbox.add_child(title_row)

	var title = Label.new()
	title.text = "ВИДЫ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.92, 0.95, 0.95, 1.0))
	title_row.add_child(title)
	var ledger_button = Button.new()
	ledger_button.name = "SpeciesLedgerButton"
	ledger_button.icon = ICON_SPECIES_LEDGER
	ledger_button.expand_icon = true
	ledger_button.tooltip_text = "Р–СѓСЂРЅР°Р» РІРёРґРѕРІ"
	ledger_button.focus_mode = Control.FOCUS_NONE
	ledger_button.tooltip_text = "Журнал видов"
	ledger_button.custom_minimum_size = Vector2(38, 34)
	ledger_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	ledger_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ledger_button.pressed.connect(_open_species_ledger)
	title_row.add_child(ledger_button)

	var clear_button = Button.new()
	clear_button.text = "Сбросить подсветку"
	clear_button.focus_mode = Control.FOCUS_NONE
	clear_button.pressed.connect(Callable(self, "_clear_species_selection"))
	vbox.add_child(clear_button)
	clear_button.visible = false

	species_scroll = ScrollContainer.new()
	species_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	species_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	species_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	species_scroll.gui_input.connect(Callable(self, "_on_species_panel_gui_input"))
	vbox.add_child(species_scroll)

	# MarginContainer даёт отступ по краям, чтобы масштабированные карточки не обрезались внутри видимой области
	var margin_wrap = MarginContainer.new()
	margin_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin_wrap.add_theme_constant_override("margin_left", 6)
	margin_wrap.add_theme_constant_override("margin_right", 6)
	margin_wrap.add_theme_constant_override("margin_top", 6)
	margin_wrap.add_theme_constant_override("margin_bottom", 6)
	species_scroll.add_child(margin_wrap)

	species_list = GridContainer.new()
	species_list.columns = 3
	species_list.add_theme_constant_override("h_separation", 8)
	species_list.add_theme_constant_override("v_separation", 8)
	species_list.mouse_filter = Control.MOUSE_FILTER_STOP
	species_list.gui_input.connect(Callable(self, "_on_species_panel_gui_input"))
	margin_wrap.add_child(species_list)

func _make_panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.05, 0.88)
	style.border_color = Color(0.45, 0.55, 0.58, 0.5)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 12.0
	style.content_margin_top = 10.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 10.0
	return style

func _build_species_ledger_overlay():
	var root = $Control
	species_ledger_overlay = PanelContainer.new()
	species_ledger_overlay.name = "SpeciesLedgerOverlay"
	species_ledger_overlay.layout_mode = 1
	species_ledger_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	species_ledger_overlay.offset_left = 28.0
	species_ledger_overlay.offset_top = 28.0
	species_ledger_overlay.offset_right = -28.0
	species_ledger_overlay.offset_bottom = -28.0
	species_ledger_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	species_ledger_overlay.gui_input.connect(_on_species_ledger_gui_input)
	species_ledger_overlay.add_theme_stylebox_override("panel", _make_panel_style())
	species_ledger_overlay.visible = false
	root.add_child(species_ledger_overlay)
	
	# Делаем журнал видов draggable
	_make_panel_draggable(species_ledger_overlay, "species_ledger")

	var outer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	species_ledger_overlay.add_child(outer)

	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	outer.add_child(header)

	var icon = TextureRect.new()
	icon.texture = ICON_SPECIES_LEDGER
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(icon)

	var title = Label.new()
	title.text = "Р–РЈР РќРђР› Р’РР”РћР’"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.text = "SPECIES LEDGER"
	title.text = "ЖУРНАЛ ВИДОВ"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.92, 0.97, 0.96, 1.0))
	header.add_child(title)

	var close_button = Button.new()
	close_button.text = "X"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.custom_minimum_size = Vector2(34, 28)
	close_button.pressed.connect(_close_species_ledger)
	header.add_child(close_button)

	species_ledger_summary_label = Label.new()
	species_ledger_summary_label.text = "Сейчас в мире: живых видов 0 | клеток 0"
	species_ledger_summary_label.add_theme_font_size_override("font_size", 13)
	species_ledger_summary_label.add_theme_color_override("font_color", Color(0.72, 0.86, 0.84, 0.95))
	species_ledger_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(species_ledger_summary_label)

	var body = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	outer.add_child(body)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)

	var list_box = VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 12)
	scroll.add_child(list_box)

	var alive_title = _make_ledger_section_title("Р–РР’Р«Р• Р’РР”Р«", ICON_SPECIES_ALIVE)
	_set_ledger_section_title_text(alive_title, "ALIVE SPECIES")
	_set_ledger_section_title_text(alive_title, "ЖИВЫЕ ВИДЫ")
	list_box.add_child(alive_title)
	species_ledger_alive_grid = GridContainer.new()
	species_ledger_alive_grid.columns = 5
	species_ledger_alive_grid.add_theme_constant_override("h_separation", 12)
	species_ledger_alive_grid.add_theme_constant_override("v_separation", 12)
	list_box.add_child(species_ledger_alive_grid)

	var dead_title = _make_ledger_section_title("РњР•Р РўР’Р«Р• Р’РР”Р«", ICON_SPECIES_DEAD)
	_set_ledger_section_title_text(dead_title, "DEAD SPECIES")
	_set_ledger_section_title_text(dead_title, "МЕРТВЫЕ ВИДЫ")
	list_box.add_child(dead_title)
	species_ledger_dead_grid = GridContainer.new()
	species_ledger_dead_grid.columns = 5
	species_ledger_dead_grid.add_theme_constant_override("h_separation", 12)
	species_ledger_dead_grid.add_theme_constant_override("v_separation", 12)
	list_box.add_child(species_ledger_dead_grid)

	species_ledger_detail_label = Label.new()
	species_ledger_detail_label.custom_minimum_size = Vector2(270, 0)
	species_ledger_detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	species_ledger_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	species_ledger_detail_label.add_theme_font_size_override("font_size", 12)
	species_ledger_detail_label.add_theme_color_override("font_color", Color(0.86, 0.94, 0.92, 1.0))
	species_ledger_detail_label.text = "Р’С‹Р±РµСЂРё РјРёРЅРёР°С‚СЋСЂСѓ РІРёРґР°"
	species_ledger_detail_label.text = "Выбери миниатюру вида"
	species_ledger_detail_label.visible = false

func _make_ledger_section_title(text: String, texture: Texture2D) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var icon = TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(18, 18)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.88, 0.96, 0.92, 0.95))
	row.add_child(label)
	return row

func _set_ledger_section_title_text(row: HBoxContainer, text: String):
	if row.get_child_count() >= 2:
		var label = row.get_child(1)
		if label is Label:
			label.text = text

func _open_species_ledger():
	if !is_instance_valid(species_ledger_overlay):
		_build_species_ledger_overlay()
	_populate_species_ledger()
	species_ledger_overlay.visible = true

func _close_species_ledger():
	if is_instance_valid(species_ledger_overlay):
		species_ledger_overlay.visible = false

func _on_species_ledger_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			get_viewport().set_input_as_handled()

func _populate_species_ledger():
	if !is_instance_valid(species_ledger_alive_grid) or !is_instance_valid(species_ledger_dead_grid):
		return
	var ledger = {"alive": _get_species_stats(), "dead": {}}
	if is_instance_valid(world_manager) and world_manager.has_method("get_species_ledger_stats"):
		ledger = world_manager.get_species_ledger_stats()
	var alive = ledger.get("alive", {})
	var dead = ledger.get("dead", {})
	var alive_species_count = int(ledger["alive_species_count"]) if ledger.has("alive_species_count") else alive.size()
	var cell_count = int(ledger["cell_count"]) if ledger.has("cell_count") else _count_cells_in_species_stats(alive)
	_update_species_ledger_summary(alive_species_count, cell_count)
	var alive_ids = alive.keys()
	alive_ids.sort_custom(func(a, b):
		return alive[a].get("count", 0) > alive[b].get("count", 0)
	)
	var dead_ids = dead.keys()
	dead_ids.sort()
	var next_signature = "%d|%s|%s|%d|%d" % [
		selected_species_id,
		str(related_species_ids),
		str(alive_ids),
		_get_species_stats_version(),
		_get_dead_species_stats_version()
	]
	if next_signature == species_ledger_signature:
		return
	species_ledger_signature = next_signature
	_clear_children(species_ledger_alive_grid)
	_clear_children(species_ledger_dead_grid)
	for id in alive_ids:
		species_ledger_alive_grid.add_child(_make_species_ledger_card(int(id), alive[id], true))
	for id in dead_ids:
		species_ledger_dead_grid.add_child(_make_species_ledger_card(int(id), dead[id], false))

func _update_species_ledger_summary(alive_species_count: int, cell_count: int):
	if !is_instance_valid(species_ledger_summary_label):
		return
	species_ledger_summary_label.text = "Сейчас в мире: живых видов %d | клеток %d" % [alive_species_count, cell_count]

func _count_cells_in_species_stats(species: Dictionary) -> int:
	var total = 0
	for id in species.keys():
		total += int(species[id].get("count", 0))
	return total

func _clear_children(node: Node):
	for child in node.get_children():
		child.queue_free()

func _make_species_ledger_card(id: int, data: Dictionary, alive: bool) -> Button:
	var visual_color = data.get("visual_color", data.get("color", Color.WHITE))
	var sample_count = max(int(data.get("count", 1)), 1)
	var button = Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(116, 152)
	var is_selected_entry = id == selected_species_id
	var is_related_entry = related_species_ids.has(id)
	if is_selected_entry:
		button.add_theme_stylebox_override("normal", _make_species_button_style(visual_color, 0.26))
	elif is_related_entry:
		button.add_theme_stylebox_override("normal", _make_species_button_style(Color(0.65, 1.0, 0.86, 1.0), 0.13))
	else:
		button.add_theme_stylebox_override("normal", _make_species_button_style(visual_color if alive else Color(0.65, 0.70, 0.72, 1.0), 0.08 if alive else 0.035))
	button.add_theme_stylebox_override("hover", _make_species_button_style(visual_color, 0.16))
	button.pressed.connect(Callable(self, "_select_species_ledger_entry").bind(id, data, alive))
	button.gui_input.connect(Callable(self, "_on_species_ledger_card_gui_input").bind(id, data, alive))

	var box = VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 3)
	button.add_child(box)

	var preview = SpeciesPreview.new()
	preview.custom_minimum_size = Vector2(88, 88)
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview.species_id = id
	preview.species_color = visual_color
	preview.is_selected = is_selected_entry
	preview.is_related = is_related_entry
	preview.elongation = data.get("elongation", 0.0) / sample_count
	preview.spikiness = data.get("spikiness", 0.0) / sample_count
	preview.amoeboid = data.get("amoeboid", 0.0) / sample_count
	preview.tendrils = data.get("tendrils", 0.0) / sample_count
	preview.lobes = data.get("lobes", 0.0) / sample_count
	preview.boxy = data.get("boxy", 0.0) / sample_count
	preview.worm = data.get("worm", 0.0) / sample_count
	preview.spiral = data.get("spiral", 0.0) / sample_count
	preview.roughness = data.get("roughness", 0.25) / sample_count
	preview.asymmetry = data.get("asymmetry", 0.12) / sample_count
	preview.nucleus_size = data.get("nucleus_size", 0.3) / sample_count
	preview.bioluminescence = data.get("bioluminescence", 0.0) / sample_count
	preview.aggressiveness = data.get("aggressiveness", 0.0) / sample_count
	box.add_child(preview)
	preview.update_count(int(data.get("count", 0)))

	if !alive:
		var status = TextureRect.new()
		status.texture = ICON_SPECIES_DEAD
		status.custom_minimum_size = Vector2(16, 16)
		status.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		status.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(status)

	var label = Label.new()
	label.text = _get_species_display_name(id, data)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.9, 0.94, 0.94, 1.0))
	box.add_child(label)
	return button

func _on_species_ledger_card_gui_input(event, id: int, data: Dictionary, alive: bool):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		_select_species_ledger_entry(id, data, alive)
		_pan_to_random_representative(id)
		get_viewport().set_input_as_handled()

func _select_species_ledger_entry(id: int, data: Dictionary, alive: bool):
	selected_cell = null
	selected_species_snapshot = data.duplicate(true)
	selected_species_snapshot["id"] = id
	selected_species_snapshot_alive = alive
	selected_species_id = id
	_refresh_related_species_ids()
	species_panel_signature = ""
	panel.show()
	if panel.get_parent():
		panel.get_parent().move_child(panel, panel.get_parent().get_child_count() - 1)
	_update_ui_from_species_snapshot()
	_update_species_panel_v2(true)
	_redraw_cells()
	_populate_species_ledger()

func _show_species_ledger_details(id: int, data: Dictionary, alive: bool):
	if !is_instance_valid(species_ledger_detail_label):
		return
	var sample_count = max(int(data.get("count", 1)), 1)
	var status = "Р–РР’РћР™" if alive else "Р’Р«РњР•Р "
	var mode = "РЎСЂРµРґРЅРёРµ РїРѕ РІСЃРµРј РїСЂРµРґСЃС‚Р°РІРёС‚РµР»СЏРј" if alive else "РџРѕСЃР»РµРґРЅРёР№ РїСЂРµРґСЃС‚Р°РІРёС‚РµР»СЊ"
	var lines = [
		"%s\n%s\n%s" % [_get_species_display_name(id, data), status, mode],
		"Р§РёСЃР»РµРЅРЅРѕСЃС‚СЊ: %d" % int(data.get("count", 0)),
		"РЎРєРѕСЂРѕСЃС‚СЊ: %.1f" % (data.get("speed", 0.0) / sample_count),
		"РџРѕРІРѕСЂРѕС‚: %.1f" % (data.get("turn_speed", 0.0) / sample_count),
		"Р—СЂРµРЅРёРµ: %.1f" % (data.get("vision_range", 0.0) / sample_count),
		"Р Р°Р·РјРµСЂ: %.2f" % (data.get("size", 0.0) / sample_count),
		"РњСѓС‚Р°С†РёРё: %.3f" % (data.get("mutation_rate", 0.0) / sample_count),
		"РђРіСЂРµСЃСЃРёСЏ: %.2f" % (data.get("aggressiveness", 0.0) / sample_count),
		"Р¤Р°РіРѕС†РёС‚РѕР·: %.2f" % (data.get("phagocytosis", 0.0) / sample_count),
		"Ферменты: %.2f" % (data.get("enzyme_secretion", 0.0) / sample_count),
		"Мембрана: %.2f" % (data.get("membrane_resistance", 0.0) / sample_count),
		"Хемотаксис: %.2f" % (data.get("chemotaxis", 0.0) / sample_count),
		"Жгутик: %.2f" % (data.get("flagella_power", 0.0) / sample_count),
		"РЎС‚СЂР°С…: %.2f" % (data.get("fear", 0.0) / sample_count),
		"Р¤РѕСЂРјР°: elong %.2f / tendrils %.2f / worm %.2f / spiral %.2f" % [
			data.get("elongation", 0.0) / sample_count,
			data.get("tendrils", 0.0) / sample_count,
			data.get("worm", 0.0) / sample_count,
			data.get("spiral", 0.0) / sample_count
		]
	]
	species_ledger_detail_label.text = "\n".join(lines)

func _update_species_panel():
	if !is_instance_valid(species_list):
		return

	var species = {}
	for cell in _get_registered_cells():
		if !is_instance_valid(cell) or cell.get("is_dying") or cell.get("pending_death"):
			continue
		var id = int(cell.get("species_id"))
		if id <= 0:
			continue
		if !species.has(id):
			species[id] = {
				"count": 0,
				"color": cell.get("species_color"),
				"visual_color": cell._get_visual_base_color() if cell.has_method("_get_visual_base_color") else cell.get("species_color")
			}
		species[id]["count"] += 1

	if selected_species_id > 0 and !species.has(selected_species_id) and !(is_instance_valid(species_ledger_overlay) and species_ledger_overlay.visible):
		selected_species_id = 0
		related_species_ids.clear()
	elif selected_species_id > 0:
		_refresh_related_species_ids()

	var ids = species.keys()
	ids.sort()
	for id in ids:
		var data = species[id]
		var button = Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = "■ Вид %03d    %d" % [id, data["count"]]
		button.tooltip_text = "Подсветить представителей вида"
		var visual_color = data.get("visual_color", data["color"])
		button.add_theme_color_override("font_color", visual_color)
		if id == selected_species_id:
			button.add_theme_stylebox_override("normal", _make_species_button_style(visual_color, 0.28))
			button.add_theme_stylebox_override("hover", _make_species_button_style(visual_color, 0.36))
		else:
			button.add_theme_stylebox_override("normal", _make_species_button_style(Color(0.8, 0.9, 0.9, 1.0), 0.08))
			button.add_theme_stylebox_override("hover", _make_species_button_style(visual_color, 0.18))
		button.pressed.connect(Callable(self, "_on_species_button_pressed").bind(id))
		species_list.add_child(button)

func _make_species_button_style(color: Color, alpha: float) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, alpha)
	style.border_color = Color(color.r, color.g, color.b, min(alpha + 0.25, 0.85))
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 5
	style.content_margin_left = 8.0
	style.content_margin_top = 5.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 5.0
	return style

func _update_species_panel_v2(force_rebuild: bool = false):
	if !is_instance_valid(species_list):
		return

	var species = _get_species_stats()

	if selected_species_id > 0 and !species.has(selected_species_id) and !(is_instance_valid(species_ledger_overlay) and species_ledger_overlay.visible):
		selected_species_id = 0
		related_species_ids.clear()
	elif selected_species_id > 0:
		_refresh_related_species_ids()

	var ids = species.keys()
	ids.sort_custom(func(a, b):
		if species[a]["count"] == species[b]["count"]:
			return a < b
		return species[a]["count"] > species[b]["count"]
	)

	var next_signature = str(selected_species_id)
	next_signature += "|rel:%s" % str(related_species_ids)
	next_signature += "|stats:%d" % _get_species_stats_version()
	for id in ids:
		next_signature += "|%s" % id

	if !force_rebuild and next_signature == species_panel_signature:
		return

	_sync_species_cards(ids, species, true)
	species_panel_signature = next_signature

func _sync_species_cards(ids: Array, species: Dictionary, structure_changed: bool):
	for existing_id in species_cards.keys():
		if !species.has(existing_id):
			var old_card = species_cards[existing_id]
			if is_instance_valid(old_card):
				old_card.queue_free()
			species_cards.erase(existing_id)

	for id in ids:
		var card = species_cards.get(id, null)
		if !is_instance_valid(card):
			card = _add_species_card(id, species[id])
			species_cards[id] = card
		_update_species_card(card, id, species[id])

	if structure_changed:
		for index in range(ids.size()):
			var card = species_cards.get(ids[index], null)
			if is_instance_valid(card) and card.get_index() != index:
				species_list.move_child(card, index)

func _add_species_card(id: int, data: Dictionary):
	var visual_color = data.get("visual_color", data["color"])
	var is_selected = id == selected_species_id
	var button = Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(78, 100)
	button.pivot_offset = Vector2(39, 50)
	button.text = ""
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.gui_input.connect(Callable(self, "_on_species_card_gui_input").bind(id))
	species_list.add_child(button)

	var item_box = VBoxContainer.new()
	item_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	item_box.add_theme_constant_override("separation", 3)
	button.add_child(item_box)

	var preview = SpeciesPreview.new()
	preview.species_id = id
	preview.species_color = visual_color
	preview.is_selected = is_selected
	preview.is_related = related_species_ids.has(id)
	preview.elongation = data["elongation"] / max(data["count"], 1)
	preview.spikiness = data["spikiness"] / max(data["count"], 1)
	preview.amoeboid = data["amoeboid"] / max(data["count"], 1)
	preview.tendrils = data.get("tendrils", 0.0) / max(data["count"], 1)
	preview.lobes = data.get("lobes", 0.0) / max(data["count"], 1)
	preview.boxy = data.get("boxy", 0.0) / max(data["count"], 1)
	preview.worm = data.get("worm", 0.0) / max(data["count"], 1)
	preview.spiral = data.get("spiral", 0.0) / max(data["count"], 1)
	preview.roughness = data["roughness"] / max(data["count"], 1)
	preview.asymmetry = data["asymmetry"] / max(data["count"], 1)
	preview.nucleus_size = data["nucleus_size"] / max(data["count"], 1)
	preview.bioluminescence = data["bioluminescence"] / max(data["count"], 1)
	preview.aggressiveness = data.get("aggressiveness", 0.0) / max(data["count"], 1)
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	item_box.add_child(preview)

	var label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.9, 0.94, 0.94, 1.0))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_box.add_child(label)

	button.set_meta("species_preview", preview)
	button.set_meta("species_label", label)
	
	# Обновляем значения
	label.text = _get_species_display_name(id, data)
	preview.update_count(data["count"])
	preview.update_trophic_icon()
	preview.update_relation_icon()

	# Инициализация поворота и z_index
	button.rotation = 0.0
	button.z_index = 0

	return button

func _update_species_card(button: Button, id: int, data: Dictionary):
	var count = max(int(data["count"]), 1)
	var is_selected = id == selected_species_id
	var is_related = related_species_ids.has(id)
	var visual_color = data.get("visual_color", data["color"])
	var signature = _make_species_card_signature(id, data, count, is_selected, is_related, visual_color)
	if button.get_meta("species_signature", "") == signature:
		return
	button.set_meta("species_signature", signature)
	button.tooltip_text = "%s: %d" % [_get_species_display_name(id, data), count]
	
	# Применяем z_index и стиль при выборе
	button.custom_minimum_size = Vector2(78, 100)
	button.pivot_offset = Vector2(39, 50)
	button.scale = Vector2(1.0, 1.0)
	button.rotation = 0.0
	
	if is_selected:
		button.z_index = 1
		button.add_theme_stylebox_override("normal", _make_species_button_style(visual_color, 0.16))
		button.add_theme_stylebox_override("hover", _make_species_button_style(visual_color, 0.22))
	elif is_related:
		button.z_index = 0
		button.add_theme_stylebox_override("normal", _make_species_button_style(Color(0.65, 1.0, 0.86, 1.0), 0.10))
		button.add_theme_stylebox_override("hover", _make_species_button_style(visual_color, 0.14))
	else:
		button.z_index = 0
		button.add_theme_stylebox_override("normal", _make_species_button_style(Color(0.8, 0.9, 0.9, 1.0), 0.02))
		button.add_theme_stylebox_override("hover", _make_species_button_style(visual_color, 0.10))

	var label = button.get_meta("species_label", null)
	if is_instance_valid(label):
		label.text = _get_species_display_name(id, data)

	var preview = button.get_meta("species_preview", null)
	if is_instance_valid(preview):
		preview.species_id = id
		preview.species_color = visual_color
		preview.is_selected = is_selected
		preview.is_related = is_related
		preview.elongation = data["elongation"] / count
		preview.spikiness = data["spikiness"] / count
		preview.amoeboid = data["amoeboid"] / count
		preview.tendrils = data.get("tendrils", 0.0) / count
		preview.lobes = data.get("lobes", 0.0) / count
		preview.boxy = data.get("boxy", 0.0) / count
		preview.worm = data.get("worm", 0.0) / count
		preview.spiral = data.get("spiral", 0.0) / count
		preview.roughness = data["roughness"] / count
		preview.asymmetry = data["asymmetry"] / count
		preview.nucleus_size = data["nucleus_size"] / count
		preview.bioluminescence = data["bioluminescence"] / count
		preview.aggressiveness = data.get("aggressiveness", 0.0) / count
		if preview.shader_material:
			preview.shader_material.set_shader_parameter("base_color", Vector3(visual_color.r, visual_color.g, visual_color.b))
			preview.shader_material.set_shader_parameter("deformation", 0.045 + preview.roughness * 0.20)
			preview.shader_material.set_shader_parameter("membrane_roughness", preview.roughness)
			preview.shader_material.set_shader_parameter("membrane_asymmetry", preview.asymmetry)
			preview.shader_material.set_shader_parameter("nucleus_size", preview.nucleus_size)
			preview.shader_material.set_shader_parameter("bioluminescence", preview.bioluminescence)
			preview.shader_material.set_shader_parameter("motion_deform", 0.10 + preview.asymmetry * 0.22)
			preview.shader_material.set_shader_parameter("visual_padding", preview._get_visual_padding())
			preview.shader_material.set_shader_parameter("shape_elongation", preview.elongation)
			preview.shader_material.set_shader_parameter("shape_spikiness", preview.spikiness)
			preview.shader_material.set_shader_parameter("shape_amoeboid", preview.amoeboid)
			preview.shader_material.set_shader_parameter("shape_tendrils", preview.tendrils)
			preview.shader_material.set_shader_parameter("shape_lobes", preview.lobes)
			preview.shader_material.set_shader_parameter("shape_boxy", preview.boxy)
			preview.shader_material.set_shader_parameter("shape_worm", preview.worm)
			preview.shader_material.set_shader_parameter("shape_spiral", preview.spiral)
		preview.update_trophic_icon()
		preview.update_relation_icon()
		preview.update_count(data["count"])
		preview.queue_redraw()

func _make_species_card_signature(id: int, data: Dictionary, count: int, is_selected: bool, is_related: bool, visual_color: Color) -> String:
	return str([
		id,
		count,
		is_selected,
		is_related,
		visual_color,
		data.get("name", ""),
		data.get("elongation", 0.0),
		data.get("spikiness", 0.0),
		data.get("amoeboid", 0.0),
		data.get("tendrils", 0.0),
		data.get("lobes", 0.0),
		data.get("boxy", 0.0),
		data.get("worm", 0.0),
		data.get("spiral", 0.0),
		data.get("roughness", 0.25),
		data.get("asymmetry", 0.12),
		data.get("nucleus_size", 0.3),
		data.get("bioluminescence", 0.0),
		data.get("phagocytosis", 0.0),
		data.get("enzyme_secretion", 0.0),
		data.get("membrane_resistance", 0.0),
		data.get("chemotaxis", 0.0),
		data.get("flagella_power", 0.0),
		data.get("fear", 0.0),
		data.get("aggressiveness", 0.0)
	])

func _get_species_stats_version() -> int:
	if is_instance_valid(world_manager) and world_manager.has_method("get_species_stats_version"):
		return int(world_manager.get_species_stats_version())
	if is_instance_valid(world_manager) and world_manager.has_method("get_population_version"):
		return int(world_manager.get_population_version())
	world_manager = get_tree().current_scene.get_node_or_null("WorldManager")
	if is_instance_valid(world_manager) and world_manager.has_method("get_species_stats_version"):
		return int(world_manager.get_species_stats_version())
	if is_instance_valid(world_manager) and world_manager.has_method("get_population_version"):
		return int(world_manager.get_population_version())
	return -1

func _get_dead_species_stats_version() -> int:
	if is_instance_valid(world_manager) and world_manager.has_method("get_dead_species_stats_version"):
		return int(world_manager.get_dead_species_stats_version())
	world_manager = get_tree().current_scene.get_node_or_null("WorldManager")
	if is_instance_valid(world_manager) and world_manager.has_method("get_dead_species_stats_version"):
		return int(world_manager.get_dead_species_stats_version())
	return -1

func _get_species_stats() -> Dictionary:
	if is_instance_valid(world_manager) and world_manager.has_method("get_species_stats"):
		return world_manager.get_species_stats()
	world_manager = get_tree().current_scene.get_node_or_null("WorldManager")
	if is_instance_valid(world_manager) and world_manager.has_method("get_species_stats"):
		return world_manager.get_species_stats()

	var species = {}
	for cell in _get_registered_cells():
		if !is_instance_valid(cell) or cell.get("is_dying") or cell.get("pending_death"):
			continue
		var id = int(cell.get("species_id"))
		if id <= 0:
			continue
		if !species.has(id):
			species[id] = {
				"count": 0,
				"color": cell.get("species_color"),
				"visual_color": cell._get_visual_base_color() if cell.has_method("_get_visual_base_color") else cell.get("species_color"),
				"name": cell.get("species_name"),
				"parent_id": cell.get("parent_species_id") if cell.get("parent_species_id") != null else 0,
				"elongation": 0.0,
				"spikiness": 0.0,
				"amoeboid": 0.0,
				"tendrils": 0.0,
				"lobes": 0.0,
				"boxy": 0.0,
				"worm": 0.0,
				"spiral": 0.0,
				"roughness": 0.0,
				"asymmetry": 0.0,
				"nucleus_size": 0.0,
				"bioluminescence": 0.0,
				"phagocytosis": 0.0,
				"enzyme_secretion": 0.0,
				"membrane_resistance": 0.0,
				"chemotaxis": 0.0,
				"flagella_power": 0.0,
				"fear": 0.0,
				"aggressiveness": 0.0
			}
		species[id]["count"] += 1
		species[id]["elongation"] += cell.genes.get("shape_elongation", 0.0)
		species[id]["spikiness"] += cell.genes.get("shape_spikiness", 0.0)
		species[id]["amoeboid"] += cell.genes.get("shape_amoeboid", 0.0)
		species[id]["tendrils"] += cell.genes.get("shape_tendrils", 0.0)
		species[id]["lobes"] += cell.genes.get("shape_lobes", 0.0)
		species[id]["boxy"] += cell.genes.get("shape_boxy", 0.0)
		species[id]["worm"] += cell.genes.get("shape_worm", 0.0)
		species[id]["spiral"] += cell.genes.get("shape_spiral", 0.0)
		species[id]["roughness"] += cell.genes.get("membrane_roughness", 0.25)
		species[id]["asymmetry"] += cell.genes.get("membrane_asymmetry", 0.12)
		species[id]["nucleus_size"] += cell.genes.get("nucleus_size", 0.3)
		species[id]["bioluminescence"] += cell.genes.get("bioluminescence", 0.0)
		species[id]["phagocytosis"] += cell.genes.get("phagocytosis", 0.0)
		species[id]["enzyme_secretion"] += cell.genes.get("enzyme_secretion", 0.0)
		species[id]["membrane_resistance"] += cell.genes.get("membrane_resistance", 0.2)
		species[id]["chemotaxis"] += cell.genes.get("chemotaxis", 0.0)
		species[id]["flagella_power"] += cell.genes.get("flagella_power", 0.0)
		species[id]["fear"] += cell.genes.get("fear", 0.0)
		species[id]["aggressiveness"] += cell.genes.get("aggressiveness", 0.0)
	return species

func _get_species_display_name(id: int, data: Dictionary) -> String:
	var display_name = str(data.get("name", ""))
	if display_name.strip_edges() == "":
		return "Вид %03d" % id
	return display_name

func _on_species_button_pressed(id: int):
	selected_species_id = 0 if selected_species_id == id else id
	_refresh_related_species_ids()
	species_panel_signature = "" # Сбрасываем подпись панели, чтобы форсировать обновление стилей/масштаба карточек
	_update_species_panel_v2(true)
	_redraw_cells()

func _on_species_card_gui_input(event, id: int):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.double_click:
				_pan_to_random_representative(id)
			else:
				_on_species_button_pressed(id)
			get_viewport().set_input_as_handled()
		else:
			_on_species_panel_gui_input(event)

func _pan_to_random_representative(id: int):
	var representatives = []
	if is_instance_valid(world_manager) and world_manager.has_method("get_cells_for_species"):
		representatives = world_manager.get_cells_for_species(id)
	else:
		for cell in _get_registered_cells():
			if is_instance_valid(cell) and not cell.get("is_dying") and not cell.get("pending_death"):
				if int(cell.get("species_id")) == id:
					representatives.append(cell)
	
	var valid_representatives = []
	for cell in representatives:
		if is_instance_valid(cell) and not cell.get("is_dying") and not cell.get("pending_death"):
			valid_representatives.append(cell)

	if valid_representatives.size() > 0:
		var target_cell = valid_representatives.pick_random()
		select_cell(target_cell)
		
		var cam = get_viewport().get_camera_2d()
		if cam and cam.has_method("pan_to_position"):
			cam.pan_to_position(target_cell.global_position)

func _clear_species_selection():
	selected_species_id = 0
	related_species_ids.clear()
	species_panel_signature = "" # Сбрасываем подпись панели
	_update_species_panel_v2(true)
	_redraw_cells()

func _refresh_related_species_ids():
	related_species_ids.clear()
	if selected_species_id <= 0:
		return
	if is_instance_valid(world_manager) and world_manager.has_method("get_related_species_ids"):
		related_species_ids = world_manager.get_related_species_ids(selected_species_id)
		related_species_ids.sort()
		return
	world_manager = get_tree().current_scene.get_node_or_null("WorldManager")
	if is_instance_valid(world_manager) and world_manager.has_method("get_related_species_ids"):
		related_species_ids = world_manager.get_related_species_ids(selected_species_id)
		related_species_ids.sort()

func is_species_related_to_selection(species_id: int) -> bool:
	return selected_species_id > 0 and related_species_ids.has(species_id)

func clear_species_selection():
	_clear_species_selection()

func is_pointer_over_species_panel() -> bool:
	if !is_instance_valid(species_panel):
		return false
	return species_panel.get_global_rect().has_point(get_viewport().get_mouse_position())

func is_pointer_over_species_ledger() -> bool:
	if !is_instance_valid(species_ledger_overlay) or !species_ledger_overlay.visible:
		return false
	return species_ledger_overlay.get_global_rect().has_point(get_viewport().get_mouse_position())

func _on_species_panel_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_clear_species_selection()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_scroll_species_list(-1)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_scroll_species_list(1)
			get_viewport().set_input_as_handled()

func _scroll_species_list(direction: int):
	if !is_instance_valid(species_scroll):
		return
	var step = 88
	var max_scroll = max(species_scroll.get_v_scroll_bar().max_value, 0)
	_scroll_target = clamp(_scroll_target + direction * step, 0.0, max_scroll)

func _redraw_cells():
	var next_ids = {}
	if selected_species_id > 0:
		next_ids[selected_species_id] = true
	for id in related_species_ids:
		next_ids[int(id)] = true

	var redraw_ids = next_ids.duplicate(false)
	for id in highlighted_species_redraw_ids.keys():
		redraw_ids[int(id)] = true
	highlighted_species_redraw_ids = next_ids

	if redraw_ids.is_empty():
		return

	if is_instance_valid(world_manager) and world_manager.has_method("get_cells_for_species"):
		for id in redraw_ids.keys():
			for cell in world_manager.get_cells_for_species(int(id)):
				if is_instance_valid(cell):
					cell.queue_redraw()
		return

	for cell in _get_registered_cells():
		if is_instance_valid(cell) and redraw_ids.has(int(cell.get("species_id"))):
			cell.queue_redraw()

func _get_registered_cells() -> Array:
	if is_instance_valid(world_manager) and world_manager.has_method("get_all_cells"):
		return world_manager.get_all_cells()
	world_manager = get_tree().current_scene.get_node_or_null("WorldManager")
	if is_instance_valid(world_manager) and world_manager.has_method("get_all_cells"):
		return world_manager.get_all_cells()
	return get_tree().get_nodes_in_group("cells")

func _set_gene_threshold_marker(bar: ProgressBar, marker_name: String, threshold: float):
	if !is_instance_valid(bar):
		return

	var marker = bar.get_node_or_null(marker_name) as ColorRect
	if marker == null:
		marker = ColorRect.new()
		marker.name = marker_name
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.color = THRESHOLD_MARKER_COLOR
		marker.z_index = 10
		bar.add_child(marker)

	var marker_height = max(bar.size.y, bar.custom_minimum_size.y, 8.0)
	var marker_x = clamp(bar.size.x * threshold - THRESHOLD_MARKER_WIDTH * 0.5, 0.0, max(bar.size.x - THRESHOLD_MARKER_WIDTH, 0.0))
	marker.position = Vector2(marker_x, 0.0)
	marker.size = Vector2(THRESHOLD_MARKER_WIDTH, marker_height)
# ========== DRAGGABLE PANELS ==========

func _make_panel_draggable(panel: Control, key: String):
	if not is_instance_valid(panel):
		return
	# Загружаем сохранённую позицию
	_load_panel_position(panel, key)
	# Подключаем обработку ввода для перетаскивания
	panel.gui_input.connect(_on_panel_drag_input.bind(key))

func _on_panel_drag_input(event: InputEvent, key: String):
	# Используем текущий ключ для доступа к _drag_info
	if not _drag_info.has(key):
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var panel = _get_panel_by_key(key)
			if event.pressed and is_instance_valid(panel):
				_drag_info[key]["dragging"] = true
				_drag_info[key]["offset"] = event.global_position - panel.global_position
				_drag_info[key]["initial"] = panel.global_position
				get_viewport().set_input_as_handled()  # Не даём клику распространяться
			else:
				if _drag_info[key]["dragging"]:
					_drag_info[key]["dragging"] = false
					_save_panel_position(key)
	elif event is InputEventMouseMotion and _drag_info[key].get("dragging", false):
		get_viewport().set_input_as_handled()
		var panel = _get_panel_by_key(key)
		if is_instance_valid(panel):
			panel.global_position = event.global_position - _drag_info[key]["offset"]

func _get_panel_by_key(key: String) -> Control:
	match key:
		"panel":
			return $Control/Panel
		"time_panel":
			return $Control/TimePanel
		"species_panel":
			return species_panel
		"species_ledger":
			return species_ledger_overlay
	return null

func _save_panel_position(key: String):
	var panel = _get_panel_by_key(key)
	if not is_instance_valid(panel):
		return
	var settings_key = "ui/panels/" + key
	ProjectSettings.set_setting(settings_key + "/x", panel.global_position.x)
	ProjectSettings.set_setting(settings_key + "/y", panel.global_position.y)
	ProjectSettings.save()

func _load_panel_position(panel: Control, key: String):
	if not is_instance_valid(panel):
		return
	var settings_key = "ui/panels/" + key
	if ProjectSettings.has_setting(settings_key + "/x"):
		var x = ProjectSettings.get_setting(settings_key + "/x")
		var y = ProjectSettings.get_setting(settings_key + "/y")
		panel.global_position = Vector2(x, y)

func is_pointer_over_draggable_panel() -> bool:
	# Возвращает true если мышь над любой ВИДИМОЙ draggable панелью
	var mouse_pos = get_viewport().get_mouse_position()
	var control = $Control
	if not is_instance_valid(control):
		return false
	
	var panels = [
		control.get_node_or_null("Panel"),
		control.get_node_or_null("TimePanel"),
		species_panel,
		species_ledger_overlay
	]
	
	for node in panels:
		if is_instance_valid(node) and node.visible:
			var rect = node.get_global_rect()
			if rect.has_point(mouse_pos):
				return true
	return false