extends CanvasLayer

const PHAGOCYTOSIS_GENE_THRESHOLD = 0.35
const HEMIBIOTROPH_AGGRESSION_THRESHOLD = 0.4
const FEAR_GENE_THRESHOLD = 0.01
const THRESHOLD_MARKER_WIDTH = 2.0
const THRESHOLD_MARKER_COLOR = Color(1.0, 1.0, 1.0, 0.9)
const SPECIES_REFRESH_INTERVAL = 0.35

class SpeciesPreview:
	extends Control

	const CELL_SHADER = preload("res://shaders/cell.gdshader")

	var species_id = 0
	var species_color: Color = Color.WHITE
	var is_selected = false
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
	var shader_material: ShaderMaterial = null
	var last_time_multiplier := -1.0

	func _ready():
		custom_minimum_size = Vector2(58, 58)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

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
		draw_rect(rect, species_color if is_selected else Color(0.35, 0.42, 0.42, 0.75), false, 2.0)

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
var species_cards = {}
var species_refresh_timer = 0.0
var species_panel_signature = ""
var world_manager: Node = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.hide()
	world_manager = get_tree().current_scene.get_node_or_null("WorldManager")
	_build_fps_label()
	_build_pause_controls()
	_build_species_panel()
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
	get_tree().paused = !get_tree().paused
	_update_time_label()

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

	if is_instance_valid(selected_cell):
		panel.show()
		_update_ui()
	else:
		if panel.visible:
			panel.hide()
		selected_cell = null

func _input(event):
	if event is InputEventKey and event.pressed and !event.echo:
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
	vision_bar.value = (selected_cell.genes.vision_range / 600.0) * 100.0
	vision_text.text = "%d" % int(selected_cell.genes.vision_range)

	# Агрессивность (Биотроф, Гемибиотроф, Некротроф)
	var trophic_type = "БИОТРОФ"
	var diet_color = Color(0.4, 1.0, 0.4)
	if selected_cell.genes.aggressiveness > 0.6:
		trophic_type = "НЕКРОТРОФ"
		diet_color = Color(1.0, 0.4, 0.4)
	elif selected_cell.genes.aggressiveness >= HEMIBIOTROPH_AGGRESSION_THRESHOLD:
		trophic_type = "ГЕМИБИОТРОФ"
		diet_color = Color(1.0, 1.0, 0.4)

	var abilities = []

	var phago_gene = selected_cell.genes.phagocytosis if selected_cell.genes.has("phagocytosis") else 0.0
	var has_phago = phago_gene >= PHAGOCYTOSIS_GENE_THRESHOLD and selected_cell.genes.aggressiveness >= 0.45
	var has_lysis = selected_cell.genes.aggressiveness >= HEMIBIOTROPH_AGGRESSION_THRESHOLD

	if has_lysis:
		abilities.append("Лизис")
	if has_phago:
		abilities.append("Фагоцитоз")

	var fear_gene = selected_cell.genes.fear if selected_cell.genes.has("fear") else 0.0
	if fear_gene > FEAR_GENE_THRESHOLD and selected_cell.genes.aggressiveness < 0.6:
		abilities.append("Страх")

	if abilities.size() > 0:
		diet_label.text = "ТИП: %s (%s)" % [trophic_type, " + ".join(abilities)]
	else:
		diet_label.text = "ТИП: %s" % trophic_type

	diet_label.modulate = diet_color

	var shape_name = "Кокк"
	if selected_cell.has_method("get_shape_name"):
		shape_name = selected_cell.get_shape_name()

	var cell_id = selected_cell.get_instance_id() % 10000
	var species_name = str(selected_cell.get("species_name"))
	if species_name.strip_edges() == "":
		species_name = "Вид %03d" % int(selected_cell.get("species_id"))
	name_label.text = "%s №%04d | %s" % [shape_name, cell_id, species_name]

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
	phago_text.text = "%.2f (порог %.2f) %s" % [phago_gene, PHAGOCYTOSIS_GENE_THRESHOLD, "ГОТОВ" if phago_ready else "НЕТ"]
	_set_gene_threshold_marker(phago_bar, "ActivationThreshold", PHAGOCYTOSIS_GENE_THRESHOLD)

	fear_bar.value = fear_gene * 100.0
	fear_text.text = "%.2f (порог %.2f) %s" % [fear_gene, FEAR_GENE_THRESHOLD, "АКТИВЕН" if fear_active else "НЕТ"]
	_set_gene_threshold_marker(fear_bar, "ActivationThreshold", FEAR_GENE_THRESHOLD)

	if selected_cell.digestion_energy_left > 0.0:
		var duration = max(selected_cell.digestion_duration, 0.1)
		var progress = 1.0 - clamp(selected_cell.digestion_timer / duration, 0.0, 1.0)
		digestion_container.visible = true
		digestion_bar.value = progress * 100.0
		digestion_text.text = "%d%% | запас %.1f" % [int(progress * 100.0), selected_cell.digestion_energy_left]
	else:
		digestion_container.visible = false

func select_cell(cell):
	selected_cell = cell
	if !cell:
		panel.hide()

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

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	species_panel.add_child(vbox)

	var title = Label.new()
	title.text = "ВИДЫ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.92, 0.95, 0.95, 1.0))
	vbox.add_child(title)

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

	species_list = GridContainer.new()
	species_list.columns = 3
	species_list.add_theme_constant_override("h_separation", 8)
	species_list.add_theme_constant_override("v_separation", 8)
	species_list.mouse_filter = Control.MOUSE_FILTER_STOP
	species_list.gui_input.connect(Callable(self, "_on_species_panel_gui_input"))
	species_scroll.add_child(species_list)

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

	if selected_species_id > 0 and !species.has(selected_species_id):
		selected_species_id = 0

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

	if selected_species_id > 0 and !species.has(selected_species_id):
		selected_species_id = 0

	var ids = species.keys()
	ids.sort_custom(func(a, b):
		if species[a]["count"] == species[b]["count"]:
			return a < b
		return species[a]["count"] > species[b]["count"]
	)

	var next_signature = str(selected_species_id)
	for id in ids:
		next_signature += "|%s" % id

	_sync_species_cards(ids, species, force_rebuild or next_signature != species_panel_signature)
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
	var button = Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(78, 100)
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
	preview.is_selected = id == selected_species_id
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
	return button

func _update_species_card(button: Button, id: int, data: Dictionary):
	var count = max(int(data["count"]), 1)
	var is_selected = id == selected_species_id
	var visual_color = data.get("visual_color", data["color"])
	button.tooltip_text = "%s: %d" % [_get_species_display_name(id, data), count]
	if is_selected:
		button.add_theme_stylebox_override("normal", _make_species_button_style(visual_color, 0.16))
		button.add_theme_stylebox_override("hover", _make_species_button_style(visual_color, 0.22))
	else:
		button.add_theme_stylebox_override("normal", _make_species_button_style(Color(0.8, 0.9, 0.9, 1.0), 0.02))
		button.add_theme_stylebox_override("hover", _make_species_button_style(visual_color, 0.10))

	var label = button.get_meta("species_label", null)
	if is_instance_valid(label):
		label.text = "%s\n%d" % [_get_species_display_name(id, data), count]

	var preview = button.get_meta("species_preview", null)
	if is_instance_valid(preview):
		preview.species_id = id
		preview.species_color = visual_color
		preview.is_selected = is_selected
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
		preview.queue_redraw()

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
				"bioluminescence": 0.0
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
	return species

func _get_species_display_name(id: int, data: Dictionary) -> String:
	var display_name = str(data.get("name", ""))
	if display_name.strip_edges() == "":
		return "Вид %03d" % id
	return display_name

func _on_species_button_pressed(id: int):
	selected_species_id = 0 if selected_species_id == id else id
	_update_species_panel_v2(true)
	_redraw_cells()

func _on_species_card_gui_input(event, id: int):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_species_button_pressed(id)
			get_viewport().set_input_as_handled()
		else:
			_on_species_panel_gui_input(event)

func _clear_species_selection():
	selected_species_id = 0
	_update_species_panel_v2(true)
	_redraw_cells()

func clear_species_selection():
	_clear_species_selection()

func is_pointer_over_species_panel() -> bool:
	if !is_instance_valid(species_panel):
		return false
	return species_panel.get_global_rect().has_point(get_viewport().get_mouse_position())

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
	var step = 72
	species_scroll.scroll_vertical = max(species_scroll.scroll_vertical + direction * step, 0)

func _redraw_cells():
	for cell in _get_registered_cells():
		if is_instance_valid(cell):
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
