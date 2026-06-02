extends RigidBody2D

# БАЛАНС 4.0: Микробиология и Круговорот
const MAX_ENERGY = 200.0
const ENERGY_START = 100.0
const METABOLISM_IDLE = 0.5
const ENERGY_SPLIT_COST = 60.0
const ENERGY_FOR_OFFSPRING = 60.0
const BASE_LIFESPAN = 90.0
const CURRENT_FORCE = 55.0
const MIN_SIZE = 0.55
const MAX_SIZE = 2.35
const PHAGOCYTOSIS_MIN_GENE = 0.35
const PHAGOCYTOSIS_MIN_AGGRESSION = 0.45
const PHAGOCYTOSIS_SIZE_ADVANTAGE = 1.12
const VISUAL_SIZE_EXPONENT = 1.28
const MIXED_AGGRESSION = 0.4
const BIOTROPH_MAX_AGGRESSION = 0.4
const PREDATOR_AGGRESSION = 0.6
const PREDATOR_HUNT_ENERGY_RATIO = 0.72
const SPLIT_BUD_START_DISTANCE = 7.0
const SPLIT_BUD_SPAWN_DISTANCE = 28.0
const SPLIT_NEWBORN_RELEASE_DISTANCE = 14.0
const PERCEPTION_RING_SEGMENTS = 96
const LYSIS_ENERGY_COST = 2.0 # Жесткий налог на выработку ферментов (в секунду)
const BASE_FEAR_DETECTION_RANGE = 350.0
const SPECIATION_DISTANCE_THRESHOLD = 0.30
const SPECIATION_STRONG_DISTANCE_THRESHOLD = 0.42
const SPECIATION_DIET_DISTANCE_THRESHOLD = 0.18
const SPECIATION_SHAPE_DISTANCE_THRESHOLD = 0.30
const VISUAL_UPDATE_INTERVAL = 0.033
const SPATIAL_UPDATE_INTERVAL = 0.12
const USE_POINT_LIGHTS = false
const BASE_BODY_VISUAL_SIZE = 64.0
const SOUND_BASE_MAX_DISTANCE = 900.0
const SOUND_MIN_ZOOM_FACTOR = 0.08
const WORM_BODY_THRESHOLD = 0.48
const WORM_BODY_SEGMENT_COUNT = 9
const WORM_TRAIL_MIN_DISTANCE = 1.0
const WORM_TRAIL_MAX_POINTS = 72
const SPAWN_SOUNDS = [
	preload("res://sounds/cell-spawn.wav")
]
const BIOTROPH_EAT_SOUNDS = [
	preload("res://sounds/biotroph-eat1.wav"),
	preload("res://sounds/biotroph-eat2.wav"),
	preload("res://sounds/biotroph-eat3.wav"),
	preload("res://sounds/biotroph-eat4.wav")
]
const NECROTROPH_EAT_SOUNDS = [
	preload("res://sounds/necrotroph-eat1.wav"),
	preload("res://sounds/necrotroph-eat2.wav")
]
const BIOTROPH_ALERT_SOUNDS = [
	preload("res://sounds/biotroph-fear1.wav"),
	preload("res://sounds/biotroph-fear2.wav")
]
const NECROTROPH_ALERT_SOUNDS = [
	preload("res://sounds/necrotroph-spotting1.wav"),
	preload("res://sounds/necrotroph-spotting2.wav")
]
const BIOTROPH_DEATH_SOUNDS = [
	preload("res://sounds/biotroph-death1.wav"),
	preload("res://sounds/biotroph-death2.wav")
]
const NECROTROPH_DEATH_SOUNDS = [
	preload("res://sounds/necrotroph-death1.wav"),
	preload("res://sounds/necrotroph-death2.wav"),
	preload("res://sounds/necrotroph-death3.wav"),
	preload("res://sounds/necrotroph-death4.wav"),
	preload("res://sounds/necrotroph-death5.wav")
]
const SPECIES_PALETTE = [
	Color(0.20, 0.95, 0.55, 1.0),
	Color(1.00, 0.45, 0.35, 1.0),
	Color(0.35, 0.72, 1.00, 1.0),
	Color(1.00, 0.82, 0.28, 1.0),
	Color(0.78, 0.55, 1.00, 1.0),
	Color(0.16, 0.88, 0.86, 1.0),
	Color(1.00, 0.52, 0.82, 1.0),
	Color(0.78, 1.00, 0.38, 1.0)
]

var genes = {
	"speed": 400.0,
	"turn_speed": 15.0,
	"vision_range": 400.0,
	"size": 1.0,
	"mutation_rate": 0.1,
	"membrane_roughness": 0.25,
	"membrane_asymmetry": 0.12,
	"nucleus_size": 0.3,
	"bioluminescence": 0.0,
	"phagocytosis": 0.0,
	"shape_elongation": 0.0,
	"shape_spikiness": 0.0,
	"shape_amoeboid": 0.0,
	"shape_tendrils": 0.0,
	"shape_lobes": 0.0,
	"shape_boxy": 0.0,
	"shape_worm": 0.0,
	"shape_spiral": 0.0,
	"fear": 0.0,
	"aggressiveness": 0.0 # 0.0 - Пассивный, 1.0 - Вырабатывает ферменты для лизиса
}

var energy = ENERGY_START
var age = 0.0
var target: Node2D = null
var fleeing_from_target = false
var vision_timer = 0.0
var is_splitting = false
var is_dying = false
var pending_death = false
var split_bud: ColorRect = null
var split_bud_dir = Vector2.RIGHT
var split_bud_progress = 0.0
var split_spawn_position = Vector2.ZERO
var digestion_visual: Node2D = null
var digestion_visual_base_scale = Vector2.ONE
var digestion_visual_center = Vector2.ZERO
var digestion_visual_start_pos = Vector2.ZERO
var digestion_energy_left = 0.0
var digestion_timer = 0.0
var digestion_duration = 0.0
var is_being_digested = false
var digesting_predator: Node2D = null
var species_id: int = 0
var parent_species_id: int = 0
var species_color: Color = Color(0.0, 0.0, 0.0, 0.0)
var species_name: String = ""
var species_origin_genes: Dictionary = {}
var ui_layer: CanvasLayer = null
var arena_node_cache: Node = null
var world_manager: Node = null
var visual_update_timer = 0.0
var spatial_update_timer = 0.0
var worm_body_visual: Node2D = null
var worm_body_segments: Array[ColorRect] = []
var worm_trail_points: Array[Vector2] = []
var worm_swim_seed = 0.0

@onready var vision_area = $VisionArea
@onready var vision_shape = $VisionArea/CollisionShape2D
@onready var body_visual = $BodyVisual
@onready var core_light = $CoreLight
@onready var selection_ring = $SelectionRing
@onready var perception_ring = $PerceptionRing

func _ready():
	_ensure_species_identity()
	ui_layer = get_tree().current_scene.get_node_or_null("UI")
	world_manager = get_tree().current_scene.get_node_or_null("WorldManager")
	arena_node_cache = _resolve_arena_node()
	visual_update_timer = randf() * VISUAL_UPDATE_INTERVAL
	spatial_update_timer = randf() * SPATIAL_UPDATE_INTERVAL
	if world_manager and world_manager.has_method("register_cell"):
		world_manager.register_cell(self)
		if is_instance_valid(vision_area):
			vision_area.monitoring = false
	tree_exiting.connect(_on_tree_exiting)
	contact_monitor = true
	max_contacts_reported = 4
	linear_damp = 1.5
	angular_damp = 3.0
	body_entered.connect(_on_body_entered)

	if body_visual and body_visual.material:
		body_visual.material = body_visual.material.duplicate()
	worm_swim_seed = randf() * TAU

	_apply_genes()
	_play_cell_sound("spawn")

func _ensure_species_identity():
	if species_id <= 0:
		species_id = int(get_instance_id())
	if species_color.a <= 0.0:
		species_color = _get_species_color(species_id)
	if species_origin_genes.is_empty():
		species_origin_genes = genes.duplicate(true)

func _get_species_color(id: int) -> Color:
	return SPECIES_PALETTE[abs(id) % SPECIES_PALETTE.size()]

func is_same_species(other) -> bool:
	return is_instance_valid(other) and other.is_in_group("cells") and species_id > 0 and other.get("species_id") == species_id

func _get_gene_distance(a: Dictionary, b: Dictionary) -> float:
	var specs = [
		["speed", 240.0, 0.85],
		["turn_speed", 18.0, 0.65],
		["vision_range", 360.0, 0.75],
		["size", MAX_SIZE - MIN_SIZE, 1.25],
		["mutation_rate", 0.5, 0.55],
		["membrane_roughness", 1.0, 0.65],
		["membrane_asymmetry", 1.0, 0.55],
		["nucleus_size", 1.0, 0.45],
		["bioluminescence", 1.0, 0.45],
		["phagocytosis", 1.0, 1.15],
		["fear", 1.0, 0.65],
		["aggressiveness", 1.0, 1.45],
		["shape_elongation", 1.0, 1.20],
		["shape_spikiness", 1.0, 1.20],
		["shape_amoeboid", 1.0, 1.20],
		["shape_tendrils", 1.0, 1.25],
		["shape_lobes", 1.0, 1.05],
		["shape_boxy", 1.0, 1.10],
		["shape_worm", 1.0, 1.35],
		["shape_spiral", 1.0, 1.20]
	]

	var weighted_sum = 0.0
	var weight_total = 0.0
	for spec in specs:
		var key = spec[0]
		var scale = max(float(spec[1]), 0.001)
		var weight = float(spec[2])
		var delta = (float(a.get(key, 0.0)) - float(b.get(key, 0.0))) / scale
		weighted_sum += delta * delta * weight
		weight_total += weight

	return sqrt(weighted_sum / max(weight_total, 0.001))

func _get_trophic_class(source_genes: Dictionary) -> int:
	var aggression = float(source_genes.get("aggressiveness", 0.0))
	if aggression > PREDATOR_AGGRESSION:
		return 2
	if aggression >= MIXED_AGGRESSION:
		return 1
	return 0

func _get_trophic_sound_group(source_genes: Dictionary) -> String:
	match _get_trophic_class(source_genes):
		2:
			return "necrotroph"
		1:
			return "hemibiotroph"
		_:
			return "biotroph"

func _get_trophic_sound_pool(kind: String, source_genes: Dictionary) -> Array:
	if kind == "spawn":
		return SPAWN_SOUNDS

	var group = _get_trophic_sound_group(source_genes)
	if kind == "eat":
		if group == "necrotroph":
			return NECROTROPH_EAT_SOUNDS
		if group == "hemibiotroph":
			return BIOTROPH_EAT_SOUNDS + NECROTROPH_EAT_SOUNDS
		return BIOTROPH_EAT_SOUNDS

	if kind == "alert":
		if group == "necrotroph":
			return NECROTROPH_ALERT_SOUNDS
		if group == "hemibiotroph":
			return BIOTROPH_ALERT_SOUNDS + NECROTROPH_ALERT_SOUNDS
		return BIOTROPH_ALERT_SOUNDS

	if kind == "death":
		if group == "necrotroph":
			return NECROTROPH_DEATH_SOUNDS
		if group == "hemibiotroph":
			return BIOTROPH_DEATH_SOUNDS + NECROTROPH_DEATH_SOUNDS
		return BIOTROPH_DEATH_SOUNDS

	return []

func _play_cell_sound(kind: String, sound_position = null, source_genes: Dictionary = {}):
	var active_genes = genes if source_genes.is_empty() else source_genes
	var active_position = global_position if sound_position == null else sound_position
	var pool = _get_trophic_sound_pool(kind, active_genes)
	if pool.is_empty():
		return

	var camera = get_viewport().get_camera_2d()
	var zoom_factor = 1.0
	if camera:
		zoom_factor = clamp(camera.zoom.x, SOUND_MIN_ZOOM_FACTOR, 1.0)

	var player = AudioStreamPlayer2D.new()
	player.stream = pool.pick_random()
	player.global_position = active_position
	var base_volume = -22.0 if kind == "spawn" else -18.0
	player.volume_db = base_volume + linear_to_db(zoom_factor)
	player.pitch_scale = randf_range(0.94, 1.06)
	player.max_distance = SOUND_BASE_MAX_DISTANCE
	player.attenuation = 1.4
	player.finished.connect(player.queue_free)
	_get_arena_node().add_child(player)
	player.play()

func _try_play_alert_sound():
	_play_cell_sound("alert")

func _should_form_new_species(new_genes: Dictionary) -> bool:
	if species_origin_genes.is_empty():
		return false

	var diet_changed = _get_trophic_class(species_origin_genes) != _get_trophic_class(new_genes)
	if diet_changed:
		return true

	var distance = _get_gene_distance(species_origin_genes, new_genes)
	if distance >= SPECIATION_STRONG_DISTANCE_THRESHOLD:
		return true

	var shape_distance = (
		abs(float(species_origin_genes.get("shape_elongation", 0.0)) - float(new_genes.get("shape_elongation", 0.0))) +
		abs(float(species_origin_genes.get("shape_spikiness", 0.0)) - float(new_genes.get("shape_spikiness", 0.0))) +
		abs(float(species_origin_genes.get("shape_amoeboid", 0.0)) - float(new_genes.get("shape_amoeboid", 0.0))) +
		abs(float(species_origin_genes.get("shape_tendrils", 0.0)) - float(new_genes.get("shape_tendrils", 0.0))) +
		abs(float(species_origin_genes.get("shape_lobes", 0.0)) - float(new_genes.get("shape_lobes", 0.0))) +
		abs(float(species_origin_genes.get("shape_boxy", 0.0)) - float(new_genes.get("shape_boxy", 0.0))) +
		abs(float(species_origin_genes.get("shape_worm", 0.0)) - float(new_genes.get("shape_worm", 0.0))) +
		abs(float(species_origin_genes.get("shape_spiral", 0.0)) - float(new_genes.get("shape_spiral", 0.0)))
	) / 8.0

	if shape_distance >= SPECIATION_SHAPE_DISTANCE_THRESHOLD:
		return true
	return distance >= SPECIATION_DISTANCE_THRESHOLD

func get_shape_name() -> String:
	var elong = genes.get("shape_elongation", 0.0)
	var spiky = genes.get("shape_spikiness", 0.0)
	var ameb = genes.get("shape_amoeboid", 0.0)
	var tendrils = genes.get("shape_tendrils", 0.0)
	var lobes = genes.get("shape_lobes", 0.0)
	var boxy = genes.get("shape_boxy", 0.0)
	var worm = genes.get("shape_worm", 0.0)
	var spiral = genes.get("shape_spiral", 0.0)

	if worm > 0.50:
		return "Нематода" if spiral < 0.45 else "Спиронема"
	if spiral > 0.58:
		return "Спирилла"
	if boxy > 0.58:
		return "Кубоид" if elong < 0.45 else "Призматум"
	if tendrils > 0.52:
		return "Лучевик" if spiky > 0.35 else "Филамент"
	if lobes > 0.55:
		return "Лобатум" if ameb > 0.3 else "Диплококк"
	if elong < 0.15 and spiky < 0.15 and ameb < 0.15:
		return "Кокк"

	if elong >= spiky and elong >= ameb:
		if spiky > 0.35:
			return "Веретено"
		elif ameb > 0.35:
			return "Спирилла"
		else:
			return "Бацилла"
	elif spiky >= elong and spiky >= ameb:
		if elong > 0.35:
			return "Веретено"
		else:
			return "Астроцит"
	else:
		if elong > 0.35:
			return "Спирилла"
		else:
			return "Амеба"

func _apply_genes():
	genes.size = clamp(genes.size, MIN_SIZE, MAX_SIZE)
	if !genes.has("phagocytosis"):
		genes.phagocytosis = 0.0
	if !genes.has("fear"):
		genes.fear = 0.0
	if !genes.has("shape_elongation"):
		genes.shape_elongation = 0.0
	if !genes.has("shape_spikiness"):
		genes.shape_spikiness = 0.0
	if !genes.has("shape_amoeboid"):
		genes.shape_amoeboid = 0.0
	if !genes.has("shape_tendrils"):
		genes.shape_tendrils = 0.0
	if !genes.has("shape_lobes"):
		genes.shape_lobes = 0.0
	if !genes.has("shape_boxy"):
		genes.shape_boxy = 0.0
	if !genes.has("shape_worm"):
		genes.shape_worm = 0.0
	if !genes.has("shape_spiral"):
		genes.shape_spiral = 0.0

	genes.aggressiveness = clamp(genes.aggressiveness, 0.0, 1.0)
	genes.phagocytosis = clamp(genes.phagocytosis, 0.0, 1.0)
	genes.fear = clamp(genes.fear, 0.0, _get_max_fear_for_aggression())
	genes.shape_elongation = clamp(genes.shape_elongation, 0.0, 1.0)
	genes.shape_spikiness = clamp(genes.shape_spikiness, 0.0, 1.0)
	genes.shape_amoeboid = clamp(genes.shape_amoeboid, 0.0, 1.0)
	genes.shape_tendrils = clamp(genes.shape_tendrils, 0.0, 1.0)
	genes.shape_lobes = clamp(genes.shape_lobes, 0.0, 1.0)
	genes.shape_boxy = clamp(genes.shape_boxy, 0.0, 1.0)
	genes.shape_worm = clamp(genes.shape_worm, 0.0, 1.0)
	genes.shape_spiral = clamp(genes.shape_spiral, 0.0, 1.0)

	energy = clamp(energy, 0.0, _get_max_energy())
	mass = pow(genes.size, 1.6)

	var vis_scale = _get_visual_size_scale()
	var visual_bounds = _get_visual_bounds_multiplier()

	_apply_collision_shape(vis_scale)

	if is_instance_valid(body_visual):
		_apply_visual_bounds(body_visual, visual_bounds, vis_scale)
	if is_instance_valid(core_light):
		core_light.visible = USE_POINT_LIGHTS
		core_light.scale = Vector2.ONE * vis_scale
		core_light.position = Vector2.ZERO # Свет в центре
	if is_instance_valid(selection_ring):
		selection_ring.scale = Vector2.ONE * vis_scale
		selection_ring.position = Vector2.ZERO # Кольцо в центре

	vision_shape.shape.radius = _get_effective_vision() / vis_scale # Радиус зрения нужно компенсировать
	_update_perception_ring()

	var r = lerp(0.1, 1.0, genes.aggressiveness)
	var g = lerp(0.8, 0.1, genes.aggressiveness)
	var b = lerp(0.2, 0.75, genes.phagocytosis)
	var visual_color = _get_visual_base_color()

	if body_visual and body_visual.material:
		body_visual.material.set_shader_parameter("base_color", visual_color)
		body_visual.material.set_shader_parameter("pulse_speed", 1.0 + (_get_effective_speed() / 400.0))
		body_visual.material.set_shader_parameter("deformation", 0.035 + genes.mutation_rate * 0.22)
		body_visual.material.set_shader_parameter("membrane_roughness", genes.membrane_roughness)
		body_visual.material.set_shader_parameter("membrane_asymmetry", genes.membrane_asymmetry)
		body_visual.material.set_shader_parameter("nucleus_size", genes.nucleus_size)
		body_visual.material.set_shader_parameter("bioluminescence", genes.bioluminescence)
		body_visual.material.set_shader_parameter("split_pressure", 0.0)
		body_visual.material.set_shader_parameter("dissolve", 0.0)
		body_visual.material.set_shader_parameter("visual_padding", _get_visual_padding())
		body_visual.material.set_shader_parameter("shape_elongation", genes.shape_elongation)
		body_visual.material.set_shader_parameter("shape_spikiness", genes.shape_spikiness)
		body_visual.material.set_shader_parameter("shape_amoeboid", genes.shape_amoeboid)
		body_visual.material.set_shader_parameter("shape_tendrils", genes.shape_tendrils)
		body_visual.material.set_shader_parameter("shape_lobes", genes.shape_lobes)
		body_visual.material.set_shader_parameter("shape_boxy", genes.shape_boxy)
		body_visual.material.set_shader_parameter("shape_worm", genes.shape_worm * 0.08)
		body_visual.material.set_shader_parameter("shape_spiral", genes.shape_spiral * 0.35)

func _apply_collision_shape(vis_scale: float):
	var collision_shape = $CollisionShape2D
	var elong = genes.get("shape_elongation", 0.0)
	var tendrils = genes.get("shape_tendrils", 0.0)
	var lobes = genes.get("shape_lobes", 0.0)
	var spiky = genes.get("shape_spikiness", 0.0)
	var ameb = genes.get("shape_amoeboid", 0.0)
	var boxy = genes.get("shape_boxy", 0.0)
	var worm = genes.get("shape_worm", 0.0)
	var spiral = genes.get("shape_spiral", 0.0)

	if boxy > 0.55 and worm < 0.45:
		var rectangle = RectangleShape2D.new()
		rectangle.size = Vector2(
			30.0 * (1.0 + elong * 0.55 + spiral * 0.20),
			30.0 * (1.0 + lobes * 0.25 + spiky * 0.14)
		)
		collision_shape.shape = rectangle
		collision_shape.rotation = 0.0
	elif elong > 0.42 or worm > 0.35 or spiral > 0.48:
		var capsule = CapsuleShape2D.new()
		capsule.radius = 11.0 * (1.0 - elong * 0.18 + lobes * 0.10 + worm * 0.06)
		capsule.height = 32.0 * (1.0 + elong * 1.20 + worm * 1.85 + spiral * 0.75)
		collision_shape.shape = capsule
		collision_shape.rotation = PI * 0.5
	else:
		var circle = CircleShape2D.new()
		circle.radius = 16.0 * (1.0 + spiky * 0.18 + tendrils * 0.36 + lobes * 0.16 + ameb * 0.10 + boxy * 0.08)
		collision_shape.shape = circle
		collision_shape.rotation = 0.0
	collision_shape.scale = Vector2.ONE * vis_scale

func _size_factor() -> float:
	return clamp(genes.size, MIN_SIZE, MAX_SIZE)

func _get_visual_size_scale(size_value: float = -1.0) -> float:
	if size_value < 0.0:
		size_value = genes.size
	return pow(clamp(size_value, MIN_SIZE, MAX_SIZE), VISUAL_SIZE_EXPONENT)

func _get_visual_base_color(source_genes: Dictionary = genes) -> Color:
	var r = lerp(0.1, 1.0, source_genes.get("aggressiveness", 0.0))
	var g = lerp(0.8, 0.1, source_genes.get("aggressiveness", 0.0))
	var b = lerp(0.2, 0.75, source_genes.get("phagocytosis", 0.0))
	return Color(r, g, b, 1.0)

func _get_visual_bounds_multiplier(source_genes: Dictionary = genes) -> float:
	return 1.0 + source_genes.get("shape_worm", 0.0) * 2.6 + source_genes.get("shape_spiral", 0.0) * 1.2 + source_genes.get("shape_tendrils", 0.0) * 0.55 + source_genes.get("shape_lobes", 0.0) * 0.22 + source_genes.get("shape_boxy", 0.0) * 0.18 + source_genes.get("shape_elongation", 0.0) * 0.65

func _get_visual_padding(source_genes: Dictionary = genes) -> float:
	return 1.65 * _get_visual_bounds_multiplier(source_genes)

func _apply_visual_bounds(visual: ColorRect, bounds_multiplier: float, render_scale: float = 1.0):
	var visual_size = BASE_BODY_VISUAL_SIZE * max(bounds_multiplier, 1.0) * max(render_scale, 0.001)
	visual.size = Vector2.ONE * visual_size
	visual.pivot_offset = visual.size * 0.5
	visual.scale = Vector2.ONE
	visual.position = -visual.size * 0.5

func _get_max_fear_for_aggression(aggression_value: float = -1.0) -> float:
	if aggression_value < 0.0:
		aggression_value = genes.aggressiveness
	return 1.0 if aggression_value < PREDATOR_AGGRESSION else 0.0

func _can_feel_fear() -> bool:
	return genes.fear > 0.01 and genes.aggressiveness < PREDATOR_AGGRESSION

func _get_effective_vision() -> float:
	# Игольчатость увеличивает зрение, а также крупный размер физически дает больший обзор
	return genes.vision_range * (1.0 + genes.get("shape_spikiness", 0.0) * 0.25) * pow(_size_factor(), 0.4)

func _get_fear_detection_range() -> float:
	return min(_get_effective_vision(), 1000.0 * genes.fear)

func _is_threatening_cell(other) -> bool:
	return is_instance_valid(other) and other.is_in_group("cells") and other != self and other.genes.aggressiveness >= MIXED_AGGRESSION

func _can_hunt_cells() -> bool:
	return genes.aggressiveness >= BIOTROPH_MAX_AGGRESSION and _is_hungry_predator()

func _update_perception_ring():
	if !is_instance_valid(perception_ring):
		return

	var points = PackedVector2Array()
	var ev = _get_effective_vision()
	for i in range(PERCEPTION_RING_SEGMENTS + 1):
		var angle = TAU * float(i) / float(PERCEPTION_RING_SEGMENTS)
		points.append(Vector2(cos(angle), sin(angle)) * ev)
	perception_ring.points = points

func _get_max_energy() -> float:
	return MAX_ENERGY * pow(_size_factor(), 1.25)

func _get_lifespan_limit() -> float:
	return BASE_LIFESPAN * 4.0 * pow(_size_factor(), 0.85)

func _get_effective_speed() -> float:
	# Снижаем штраф скорости за размер (0.45 вместо 0.85), чтобы крупные клетки выживали
	var base_speed = genes.speed / pow(_size_factor(), 0.45)
	# Вытянутость (shape_elongation) дает бонус к скорости до +25%
	base_speed *= (1.0 + genes.get("shape_elongation", 0.0) * 0.25)
	# Червеобразные клетки получают небольшой бонус за волнообразное движение, но кубические хуже плывут
	base_speed *= (1.0 + genes.get("shape_worm", 0.0) * 0.18 + genes.get("shape_spiral", 0.0) * 0.08 - genes.get("shape_boxy", 0.0) * 0.10)
	return base_speed

func _get_effective_turn_speed() -> float:
	# Снижаем штраф маневренности за размер (0.65 вместо 1.15)
	var base_turn = genes.turn_speed / pow(_size_factor(), 0.65)
	# Амёбовидность/пластичность (shape_amoeboid) дает бонус к маневренности до +30%
	base_turn *= (1.0 + genes.get("shape_amoeboid", 0.0) * 0.30)
	base_turn *= (1.0 + genes.get("shape_worm", 0.0) * 0.12 + genes.get("shape_spiral", 0.0) * 0.18 - genes.get("shape_boxy", 0.0) * 0.12)
	# Вытянутость (shape_elongation) снижает маневренность до -15%
	base_turn *= (1.0 - genes.get("shape_elongation", 0.0) * 0.15)
	return base_turn

func _get_worm_strength() -> float:
	return clamp(inverse_lerp(WORM_BODY_THRESHOLD, 1.0, genes.get("shape_worm", 0.0)), 0.0, 1.0)

func _get_worm_swim_direction(base_dir: Vector2, current_dir: Vector2, active_steering: bool) -> Vector2:
	var worm_strength = _get_worm_strength()
	if worm_strength <= 0.0:
		return base_dir

	var forward = base_dir.normalized()
	if forward == Vector2.ZERO:
		forward = current_dir.normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.RIGHT.rotated(rotation)

	var side = Vector2(-forward.y, forward.x)
	var speed_phase = linear_velocity.length() / max(_get_effective_speed(), 1.0)
	var frequency = lerp(1.15, 2.25, worm_strength) + speed_phase * 0.65
	var wave = sin(age * frequency + worm_swim_seed)
	var amplitude = lerp(0.14, 0.38, worm_strength)
	if active_steering:
		amplitude *= 0.82
	return (forward + side * wave * amplitude).normalized()

func _ensure_worm_body_visual():
	if is_instance_valid(worm_body_visual):
		return
	worm_body_visual = Node2D.new()
	worm_body_visual.name = "WormBodyVisual"
	worm_body_visual.z_index = -1
	worm_body_visual.z_as_relative = true
	add_child(worm_body_visual)
	move_child(worm_body_visual, 0)
	worm_body_segments.clear()
	for i in range(WORM_BODY_SEGMENT_COUNT):
		var segment = ColorRect.new()
		segment.name = "Segment%02d" % i
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		segment.material = body_visual.material.duplicate() if body_visual and body_visual.material else null
		if segment.material:
			segment.material.set_shader_parameter("shape_worm", 0.0)
			segment.material.set_shader_parameter("shape_spiral", 0.0)
			segment.material.set_shader_parameter("shape_elongation", 0.0)
			segment.material.set_shader_parameter("shape_spikiness", 0.0)
			segment.material.set_shader_parameter("shape_tendrils", 0.0)
			segment.material.set_shader_parameter("shape_lobes", 0.0)
			segment.material.set_shader_parameter("shape_boxy", 0.0)
			segment.material.set_shader_parameter("visual_padding", 1.22)
			segment.material.set_shader_parameter("nucleus_size", -1.0)
			segment.material.set_shader_parameter("bioluminescence", 0.0)
		worm_body_visual.add_child(segment)
		worm_body_segments.append(segment)

func _clear_worm_body_visual():
	if is_instance_valid(worm_body_visual):
		worm_body_visual.queue_free()
	worm_body_visual = null
	worm_body_segments.clear()
	worm_trail_points.clear()

func _update_worm_body_visual(_delta: float):
	var worm_strength = _get_worm_strength()
	if worm_strength <= 0.0 or is_splitting or is_dying or is_being_digested:
		_clear_worm_body_visual()
		return

	_ensure_worm_body_visual()
	if worm_trail_points.is_empty():
		worm_trail_points.push_front(global_position)
	elif worm_trail_points[0].distance_to(global_position) >= WORM_TRAIL_MIN_DISTANCE:
		worm_trail_points.push_front(global_position)
	else:
		worm_trail_points[0] = global_position
	while worm_trail_points.size() > WORM_TRAIL_MAX_POINTS:
		worm_trail_points.pop_back()

	var vis_scale = _get_visual_size_scale()
	var forward_dir = linear_velocity.normalized()
	if forward_dir == Vector2.ZERO:
		forward_dir = Vector2.RIGHT.rotated(rotation)
	var body_length = 38.0 * vis_scale * (1.0 + genes.get("shape_worm", 0.0) * 1.25 + genes.get("shape_spiral", 0.0) * 0.30)
	var head_width = 32.0 * vis_scale * lerp(0.92, 1.03, worm_strength)
	var sampled_points = _sample_worm_trail(body_length, WORM_BODY_SEGMENT_COUNT)
	if sampled_points.is_empty():
		return

	var color = _get_visual_base_color()
	for i in range(worm_body_segments.size()):
		var segment = worm_body_segments[i]
		if !is_instance_valid(segment):
			continue
		var t = float(i) / float(max(worm_body_segments.size() - 1, 1))
		var diameter = head_width * lerp(0.95, 0.68, t)
		var length_scale = lerp(1.32, 1.08, t)
		segment.size = Vector2(diameter * length_scale, diameter)
		segment.pivot_offset = segment.size * 0.5
		var point = sampled_points[min(i, sampled_points.size() - 1)]
		var prev_point = sampled_points[max(i - 1, 0)]
		var next_point = sampled_points[min(i + 1, sampled_points.size() - 1)]
		var tangent = (prev_point - next_point).normalized()
		if tangent == Vector2.ZERO:
			tangent = forward_dir
		var local_point = to_local(point)
		segment.position = local_point - segment.pivot_offset
		segment.rotation = tangent.angle() - rotation
		segment.color = color
		segment.modulate.a = 1.0
		if segment.material:
			segment.material.set_shader_parameter("base_color", color)
			segment.material.set_shader_parameter("energy_ratio", clamp(energy / _get_max_energy(), 0.0, 1.0))
			segment.material.set_shader_parameter("motion_deform", 0.0)

func _sample_worm_trail(length: float, count: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if worm_trail_points.is_empty():
		result.append(global_position)
		return result

	var fallback_dir = linear_velocity.normalized()
	if fallback_dir == Vector2.ZERO:
		fallback_dir = Vector2.RIGHT.rotated(rotation)

	for i in range(count):
		var target_distance = length * float(i) / float(max(count - 1, 1))
		result.append(_sample_worm_trail_at_distance(target_distance, fallback_dir))
	return result

func _sample_worm_trail_at_distance(target_distance: float, fallback_dir: Vector2) -> Vector2:
	if target_distance <= 0.0:
		return global_position
	if worm_trail_points.size() <= 1:
		return global_position - fallback_dir * target_distance

	var walked = 0.0
	for i in range(worm_trail_points.size() - 1):
		var a = worm_trail_points[i]
		var b = worm_trail_points[i + 1]
		var segment_length = a.distance_to(b)
		if walked + segment_length >= target_distance:
			var segment_t = (target_distance - walked) / max(segment_length, 0.001)
			return a.lerp(b, segment_t)
		walked += segment_length

	return worm_trail_points[worm_trail_points.size() - 1] - fallback_dir * (target_distance - walked)

func _get_effective_current_force() -> float:
	return CURRENT_FORCE * pow(_size_factor(), 0.35)

func _get_split_threshold() -> float:
	# Крупным клеткам нужно заполнить меньший процент бака энергии для деления (от 95% для мелких до 55% для гигантов)
	var threshold_pct = lerp(0.95, 0.55, inverse_lerp(MIN_SIZE, MAX_SIZE, clamp(genes.size, MIN_SIZE, MAX_SIZE)))
	return _get_max_energy() * threshold_pct

func _get_split_cost() -> float:
	return ENERGY_SPLIT_COST * pow(_size_factor(), 0.9)

func _get_offspring_start_energy(new_genes: Dictionary) -> float:
	var offspring_max_energy = MAX_ENERGY * pow(clamp(new_genes.size, MIN_SIZE, MAX_SIZE), 1.25)
	# Даем больше стартовой энергии потомкам крупных клеток (1.1 вместо 0.8)
	return min(ENERGY_FOR_OFFSPRING * pow(clamp(new_genes.size, MIN_SIZE, MAX_SIZE), 1.1), offspring_max_energy * 0.45)

func _physics_process(delta):
	if is_dying or is_being_digested:
		return

	spatial_update_timer -= delta
	if spatial_update_timer <= 0.0:
		spatial_update_timer = SPATIAL_UPDATE_INTERVAL
		if world_manager and world_manager.has_method("update_cell_spatial"):
			world_manager.update_cell_spatial(self)

	age += delta
	vision_timer -= delta

	# 1. МЕТАБОЛИЗМ + НАЛОГ НА АГРЕССИЮ
	var aging_factor = 1.0 + (age / BASE_LIFESPAN) * 0.5
	var effective_speed = _get_effective_speed()
	var effective_turn_speed = _get_effective_turn_speed()
	var mobility_cost = (effective_speed * 0.002) + (effective_turn_speed * 0.1)

	# Выработка растворяющих ферментов требует колоссальной энергии
	var aggression_cost = (genes.aggressiveness * LYSIS_ENERGY_COST) + genes.phagocytosis * 0.65 + genes.fear * 0.18

	# Закон Клайбера: крупные клетки гораздо более энергоэффективны на единицу массы (pow 0.4 вместо 0.85)
	var metabolism = (METABOLISM_IDLE + mobility_cost + aggression_cost + (_get_effective_vision() * 0.001)) * pow(_size_factor(), 0.4) * aging_factor

	energy -= metabolism * delta
	_process_digestion(delta)

	if energy <= 0 or (age > _get_lifespan_limit()):
		die()
		return

	if digestion_energy_left > 0.0:
		# Переваривание на месте: блокируем AI и плавно останавливаем движение клетки
		linear_velocity = linear_velocity.lerp(Vector2.ZERO, delta * 6.5)
		angular_velocity = lerp(angular_velocity, 0.0, delta * 6.5)
		return

	if is_splitting:
		linear_velocity *= 0.96
		angular_velocity *= 0.9
		return

	# 2. Деление (Митоз)
	if energy >= _get_split_threshold():
		split()

	# 3. Оптимизированное Зрение
	if vision_timer <= 0.0:
		vision_timer = 0.2 + randf() * 0.1
		if _can_feel_fear():
			var threat = _find_nearest_threat()
			if is_instance_valid(threat):
				if target != threat:
					_try_play_alert_sound()
				target = threat
				fleeing_from_target = true
			elif fleeing_from_target:
				target = null
				fleeing_from_target = false
		if is_instance_valid(target) and not fleeing_from_target:
			var dist = global_position.distance_to(target.global_position)
			if dist > genes.vision_range:
				target = null

		if !is_instance_valid(target):
			fleeing_from_target = false
			target = _find_nearest_target()
			if is_instance_valid(target) and target.is_in_group("cells"):
				_try_play_alert_sound()

	# 4. Движение
	var current = _sample_liquid_current(global_position, Time.get_ticks_msec() * 0.001)
	apply_central_force(current * _get_effective_current_force() * genes.size)

	var current_dir = Vector2.RIGHT.rotated(rotation)
	var desired_dir = current_dir
	var is_active_steering = false
	var fear_boost = 1.0

	if is_instance_valid(target):
		desired_dir = (global_position - target.global_position).normalized() if fleeing_from_target else (target.global_position - global_position).normalized()
		is_active_steering = true
		if fleeing_from_target:
			fear_boost = 1.0 + genes.fear * 0.65

	var avoid_dir = Vector2.ZERO
	var arena_node = _get_arena_node()
	if arena_node and arena_node.get("arena_size") != null:
		var half_size = arena_node.arena_size / 2.0
		var margin = 150.0 # Мягкая зона уклонения

		var dist_x_neg = global_position.x - (-half_size)
		var dist_x_pos = half_size - global_position.x
		var dist_y_neg = global_position.y - (-half_size)
		var dist_y_pos = half_size - global_position.y

		# Экспоненциальное нарастание силы отталкивания
		if dist_x_neg < margin: avoid_dir.x += pow(1.0 - (dist_x_neg / margin), 2.0)
		if dist_x_pos < margin: avoid_dir.x -= pow(1.0 - (dist_x_pos / margin), 2.0)
		if dist_y_neg < margin: avoid_dir.y += pow(1.0 - (dist_y_neg / margin), 2.0)
		if dist_y_pos < margin: avoid_dir.y -= pow(1.0 - (dist_y_pos / margin), 2.0)

	if avoid_dir != Vector2.ZERO:
		is_active_steering = true
		if is_instance_valid(target) and not fleeing_from_target:
			# Если охотимся/кушаем, стена отталкивает слабее, чтобы не мешать подбирать еду у краев
			desired_dir = (desired_dir + avoid_dir * 0.4).normalized()
		else:
			# Сильное отталкивание при блуждании или побеге (чтобы скользить по стене, а не биться в нее)
			desired_dir = (desired_dir + avoid_dir * 2.5).normalized()

	var worm_strength = _get_worm_strength()
	if worm_strength > 0.0:
		desired_dir = _get_worm_swim_direction(desired_dir, current_dir, is_active_steering)
		if !is_active_steering and worm_strength > 0.35:
			is_active_steering = true

	if is_active_steering:
		var angle_to = current_dir.angle_to(desired_dir)
		apply_torque(angle_to * effective_turn_speed * 200.0 * fear_boost * mass)
		var speed_mult = (1.0 if abs(angle_to) < 0.5 else 0.2) * fear_boost
		apply_central_force(current_dir * effective_speed * speed_mult * mass * 1.5)
	else:
		apply_torque(randf_range(-1, 1) * effective_turn_speed * 20.0 * mass)
		apply_central_force(current_dir * 50.0 / pow(_size_factor(), 0.55) * mass * 1.5)

	# Мягкое ограничение максимальной скорости, чтобы физика не ломалась при долгих погонях
	var max_vel = effective_speed * (2.2 if fleeing_from_target else 1.6)
	if linear_velocity.length() > max_vel:
		linear_velocity = linear_velocity.limit_length(lerp(linear_velocity.length(), max_vel, delta * 8.0))

# ФАГОЦИТОЗ / ЛИЗИС
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

func _on_body_entered(body):
	if is_dying or pending_death or is_being_digested:
		return
	if body.is_in_group("cells") and body != self:
		if body.is_dying or body.pending_death or body.is_being_digested:
			return
		if is_same_species(body):
			return
		if _can_phagocytose(body):
			body.is_being_digested = true
			call_deferred("_begin_phagocytosis", body)
			return
		# Агрессивная клетка растворяет пассивную (Лизис)
		var required_advantage = 0.2
		# Колючие клетки сложнее растворить (shape_spikiness защищает)
		required_advantage += body.genes.get("shape_spikiness", 0.0) * 0.20
		# Круглые кокки (все гены формы низкие) имеют базовую защиту
		if body.genes.get("shape_elongation", 0.0) < 0.15 and body.genes.get("shape_spikiness", 0.0) < 0.15 and body.genes.get("shape_amoeboid", 0.0) < 0.15:
			required_advantage += 0.15

		if _can_hunt_cells() and genes.aggressiveness > body.genes.aggressiveness + required_advantage:
			# Всасываем цитоплазму (чем мы агрессивнее, тем эффективнее)
			eat(body.energy, true)
			# Жертва "лопается", остатки становятся питательной средой
			body.die(true)

func _can_phagocytose(victim) -> bool:
	if digestion_energy_left > 0.0 or is_being_digested or !is_instance_valid(victim) or victim.is_dying or victim.is_being_digested:
		return false
	if is_same_species(victim):
		return false
	if !_can_hunt_cells():
		return false

	# Амёбовидность (shape_amoeboid) дает преимущества для фагоцитоза
	var shape_ameb = genes.get("shape_amoeboid", 0.0)
	var min_phago = PHAGOCYTOSIS_MIN_GENE - 0.1 * shape_ameb
	var min_agg = PHAGOCYTOSIS_MIN_AGGRESSION - 0.1 * shape_ameb
	var size_advantage = PHAGOCYTOSIS_SIZE_ADVANTAGE - 0.12 * shape_ameb

	if genes.phagocytosis < min_phago or genes.aggressiveness < min_agg:
		return false
	if genes.size < victim.genes.size * size_advantage:
		return false

	var required_advantage = 0.1
	# Колючесть жертвы мешает её проглотить
	required_advantage += victim.genes.get("shape_spikiness", 0.0) * 0.20
	# Идеально круглые кокки (все гены формы низкие) имеют защиту
	if victim.genes.get("shape_elongation", 0.0) < 0.15 and victim.genes.get("shape_spikiness", 0.0) < 0.15 and victim.genes.get("shape_amoeboid", 0.0) < 0.15:
		required_advantage += 0.15

	return genes.aggressiveness > victim.genes.aggressiveness + required_advantage

func _begin_phagocytosis(victim):
	if !is_instance_valid(victim):
		return

	target = null
	digestion_energy_left = max(victim.energy, 8.0) * lerp(0.85, 1.8, genes.phagocytosis)
	digestion_duration = lerp(10.0, 3.5, genes.phagocytosis) * clamp(victim.genes.size / max(genes.size, 0.1), 0.45, 1.35)
	digestion_timer = digestion_duration
	_create_digestion_visual(victim)

func _create_digestion_visual(victim):
	_clear_digestion_visual()
	if !is_instance_valid(victim):
		return

	# Захватываем реальную жертву — но НЕ перепривязываем! Оставляем на арене.
	digestion_visual = victim
	digestion_visual.is_being_digested = true
	digestion_visual.digesting_predator = self

	# Отключаем физику и коллизии, замораживаем на месте
	digestion_visual.set_deferred("collision_layer", 0)
	digestion_visual.set_deferred("collision_mask", 0)
	digestion_visual.set_deferred("freeze", true)
	digestion_visual.linear_velocity = Vector2.ZERO
	digestion_visual.angular_velocity = 0.0

	# Запоминаем начальную глобальную позицию жертвы (для анимации засасывания)
	digestion_visual_start_pos = victim.global_position
	digestion_visual_center = digestion_visual_start_pos

	# Запоминаем начальный масштаб жертвы
	digestion_visual_base_scale = victim.scale

	# Жертва изначально снаружи, поэтому она почти непрозрачна
	digestion_visual.modulate = Color(0.9, 0.9, 0.9, 0.85)

	if digestion_visual.body_visual and digestion_visual.body_visual.material:
		digestion_visual.body_visual.material = digestion_visual.body_visual.material.duplicate()
		digestion_visual.body_visual.material.set_shader_parameter("dissolve", 0.02)
		digestion_visual.body_visual.material.set_shader_parameter("energy_ratio", 0.35)

func _process_digestion(delta: float):
	if digestion_energy_left <= 0.0:
		return

	var duration = max(digestion_duration, 0.1)
	var consumed = min(digestion_energy_left, digestion_energy_left / max(digestion_timer, 0.1) * delta)
	digestion_energy_left -= consumed
	digestion_timer = max(digestion_timer - delta, 0.0)
	energy = min(energy + consumed, _get_max_energy())

	if is_instance_valid(digestion_visual):
		# Отнимаем энергию у жертвы в реальном времени
		digestion_visual.energy = max(digestion_visual.energy - consumed, 0.0)

		var progress = 1.0 - clamp(digestion_timer / duration, 0.0, 1.0)

		# Засасывание: жертва движется к ГЛОБАЛЬНОЙ позиции хищника за первые 35%
		var suck_progress = clamp(progress / 0.35, 0.0, 1.0)
		var ease_progress = 1.0 - pow(1.0 - suck_progress, 3.0)

		# Микроколебания внутри тела хищника
		var swirly_offset = Vector2(sin(progress * 7.0), cos(progress * 5.0)) * 3.0

		# Жертва затягивается от своей начальной позиции к центру хищника
		digestion_visual.global_position = digestion_visual_start_pos.lerp(global_position + swirly_offset, ease_progress)

		# Сжатие: жертва уменьшается при затягивании и распадается
		var compress = lerp(1.0, 0.45, ease_progress)
		var collapse = smoothstep(0.4, 1.0, progress)
		var target_scale = digestion_visual_base_scale * compress * lerp(1.0, 0.12, collapse)
		digestion_visual.scale = target_scale

		# Угасание прозрачности
		digestion_visual.modulate.a = lerp(0.85, 0.03, progress)

		if digestion_visual.body_visual and digestion_visual.body_visual.material:
			digestion_visual.body_visual.material.set_shader_parameter("dissolve", lerp(0.02, 1.0, progress))
			digestion_visual.body_visual.material.set_shader_parameter("energy_ratio", lerp(0.35, 0.0, progress))

	if digestion_timer <= 0.0 or digestion_energy_left <= 0.01:
		digestion_energy_left = 0.0
		digestion_timer = 0.0
		_clear_digestion_visual()

func _clear_digestion_visual():
	if is_instance_valid(digestion_visual):
		digestion_visual.queue_free()
	digestion_visual = null
	digestion_visual_base_scale = Vector2.ONE
	digestion_visual_center = Vector2.ZERO

func _find_nearest_target():
	var closest = null
	var min_dist_sq = INF
	var wm = _get_world_manager()
	var vision_range = _get_effective_vision()
	var vision_range_sq = vision_range * vision_range

	# Пассивные ищут минералы/растения
	if can_eat_floor_food():
		var areas = wm.get_food_near(global_position, vision_range) if wm and wm.has_method("get_food_near") else vision_area.get_overlapping_areas()
		for a in areas:
			if is_instance_valid(a) and a.is_in_group("food"):
				if a.has_method("can_be_eaten_by") and !a.can_be_eaten_by(self):
					continue
				var d = global_position.distance_squared_to(a.global_position)
				if d <= vision_range_sq and d < min_dist_sq:
					min_dist_sq = d
					closest = a

	if can_eat_cell_remains() and !can_eat_floor_food():
		var remains_areas = wm.get_food_near(global_position, vision_range) if wm and wm.has_method("get_food_near") else vision_area.get_overlapping_areas()
		for a in remains_areas:
			if is_instance_valid(a) and a.is_in_group("food"):
				if a.has_method("can_be_eaten_by") and !a.can_be_eaten_by(self):
					continue
				var d = global_position.distance_squared_to(a.global_position)
				if d <= vision_range_sq and d < min_dist_sq:
					min_dist_sq = d
					closest = a

	# Геми-/некротрофы ищут чужие мембраны. Биотрофы не охотятся на клетки.
	if _can_hunt_cells():
		var bodies = wm.get_cells_near(global_position, vision_range) if wm and wm.has_method("get_cells_near") else vision_area.get_overlapping_bodies()
		for b in bodies:
			if is_instance_valid(b) and b.is_in_group("cells") and b != self and !is_same_species(b) and (genes.aggressiveness > b.genes.aggressiveness + 0.2 or _can_phagocytose(b)):
				var d = global_position.distance_squared_to(b.global_position)
				if d <= vision_range_sq and d < min_dist_sq:
					min_dist_sq = d
					closest = b
	return closest

func _find_nearest_threat():
	var closest = null
	var min_dist_sq = INF
	var wm = _get_world_manager()
	var fear_range = _get_fear_detection_range()
	var fear_range_sq = fear_range * fear_range
	var bodies = wm.get_cells_near(global_position, fear_range) if wm and wm.has_method("get_cells_near") else vision_area.get_overlapping_bodies()
	for b in bodies:
		if is_instance_valid(b) and _is_threatening_cell(b):
			var d = global_position.distance_squared_to(b.global_position)
			if d < fear_range_sq and d < min_dist_sq:
				min_dist_sq = d
				closest = b
	return closest

func can_eat_floor_food() -> bool:
	return genes.aggressiveness < PREDATOR_AGGRESSION

func can_eat_cell_remains() -> bool:
	var has_lysis = genes.aggressiveness >= MIXED_AGGRESSION
	var has_phagocytosis = genes.phagocytosis >= PHAGOCYTOSIS_MIN_GENE and genes.aggressiveness >= PHAGOCYTOSIS_MIN_AGGRESSION
	return has_lysis or has_phagocytosis

func _is_hungry_predator() -> bool:
	return energy < _get_max_energy() * PREDATOR_HUNT_ENERGY_RATIO

func eat(amount, is_lysis=false) -> bool:
	if !is_lysis and !can_eat_floor_food():
		return false
	# Эффективность зависит от типа питания
	var efficiency = genes.aggressiveness if is_lysis else (1.0 - genes.aggressiveness)
	var nutrition = amount * efficiency * 2.0

	energy = min(energy + nutrition, _get_max_energy())
	target = null
	if nutrition > 0.0:
		_play_cell_sound("eat")
	return nutrition > 0.0

func eat_cell_remains(amount) -> bool:
	if !can_eat_cell_remains():
		return false
	var efficiency = max(genes.aggressiveness, genes.phagocytosis)
	var nutrition = amount * max(efficiency, 0.35) * 2.0
	energy = min(energy + nutrition, _get_max_energy())
	target = null
	if nutrition > 0.0:
		_play_cell_sound("eat")
	return nutrition > 0.0

func split():
	if is_splitting or is_dying:
		return

	is_splitting = true
	energy -= _get_split_cost()
	split_bud_dir = Vector2.RIGHT.rotated(randf() * TAU).normalized()
	split_spawn_position = _get_current_split_spawn_position()
	split_bud_progress = 0.0
	var new_genes = genes.duplicate()

	for key in new_genes:
		if randf() < genes.mutation_rate * 3.0:
			if key == "aggressiveness":
				new_genes[key] += randf_range(-0.2, 0.2)
				new_genes[key] = clamp(new_genes[key], 0.0, 1.0)
			elif key == "mutation_rate":
				new_genes[key] += randf_range(-0.05, 0.05)
				new_genes[key] = clamp(new_genes[key], 0.01, 0.5)
			elif key == "size":
				new_genes[key] += randf_range(-0.16, 0.16)
				new_genes[key] = clamp(new_genes[key], MIN_SIZE, MAX_SIZE)
			elif key == "fear":
				new_genes[key] += randf_range(-0.1, 0.1)
				new_genes[key] = clamp(new_genes[key], 0.0, _get_max_fear_for_aggression(new_genes.aggressiveness))
			elif key in ["membrane_roughness", "membrane_asymmetry", "nucleus_size", "bioluminescence", "phagocytosis", "shape_elongation", "shape_spikiness", "shape_amoeboid", "shape_tendrils", "shape_lobes", "shape_boxy", "shape_worm", "shape_spiral"]:
				new_genes[key] += randf_range(-0.08, 0.08)
				new_genes[key] = clamp(new_genes[key], 0.0, 1.0)
			else:
				var m = new_genes["mutation_rate"]
				new_genes[key] += randf_range(-m * new_genes[key], m * new_genes[key])

	_create_split_bud(new_genes)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_method(_set_split_pressure, 0.0, 0.62, 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_set_split_bud_progress, 0.0, 1.0, 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if body_visual and body_visual.material:
		body_visual.material.set_shader_parameter("motion_direction", _world_to_local_dir(split_bud_dir))
		tween.tween_property(body_visual, "scale", Vector2(1.08, 0.96), 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(false)
	tween.tween_interval(0.08)
	tween.tween_callback(func(): _finish_split(new_genes))

func _set_split_pressure(value: float):
	if body_visual and body_visual.material:
		body_visual.material.set_shader_parameter("split_pressure", value)

func _create_split_bud(new_genes: Dictionary):
	if !body_visual:
		return

	split_bud = body_visual.duplicate()
	split_bud.name = "SplitBud"
	split_bud.set_meta("gene_size", new_genes.size)
	split_bud.set_meta("visual_bounds", _get_visual_bounds_multiplier(new_genes))
	split_bud.visible = true
	_apply_visual_bounds(split_bud, split_bud.get_meta("visual_bounds", 1.0))
	split_bud.scale = Vector2.ONE * 0.08
	split_bud.rotation = 0.0
	_get_arena_node().add_child(split_bud)
	_set_split_bud_center(global_position + split_bud_dir * SPLIT_BUD_START_DISTANCE)
	if split_bud.material:
		split_bud.material = split_bud.material.duplicate()
		var effective_new_speed = new_genes.speed / pow(clamp(new_genes.size, MIN_SIZE, MAX_SIZE), 0.85)
		split_bud.material.set_shader_parameter("base_color", _get_visual_base_color(new_genes))
		split_bud.material.set_shader_parameter("pulse_speed", 1.0 + (effective_new_speed / 400.0))
		split_bud.material.set_shader_parameter("deformation", 0.035 + new_genes.mutation_rate * 0.22)
		split_bud.material.set_shader_parameter("membrane_roughness", new_genes.membrane_roughness)
		split_bud.material.set_shader_parameter("membrane_asymmetry", new_genes.membrane_asymmetry)
		split_bud.material.set_shader_parameter("nucleus_size", new_genes.nucleus_size)
		split_bud.material.set_shader_parameter("bioluminescence", new_genes.bioluminescence)
		split_bud.material.set_shader_parameter("energy_ratio", 0.65)
		split_bud.material.set_shader_parameter("motion_direction", split_bud_dir)
		split_bud.material.set_shader_parameter("split_pressure", 0.0)
		split_bud.material.set_shader_parameter("dissolve", 0.0)
		split_bud.material.set_shader_parameter("visual_padding", _get_visual_padding(new_genes))
		split_bud.material.set_shader_parameter("shape_elongation", new_genes.get("shape_elongation", 0.0))
		split_bud.material.set_shader_parameter("shape_spikiness", new_genes.get("shape_spikiness", 0.0))
		split_bud.material.set_shader_parameter("shape_amoeboid", new_genes.get("shape_amoeboid", 0.0))
		split_bud.material.set_shader_parameter("shape_tendrils", new_genes.get("shape_tendrils", 0.0))
		split_bud.material.set_shader_parameter("shape_lobes", new_genes.get("shape_lobes", 0.0))
		split_bud.material.set_shader_parameter("shape_boxy", new_genes.get("shape_boxy", 0.0))
		split_bud.material.set_shader_parameter("shape_worm", new_genes.get("shape_worm", 0.0) * 0.08)
		split_bud.material.set_shader_parameter("shape_spiral", new_genes.get("shape_spiral", 0.0) * 0.35)

func _set_split_bud_progress(value: float):
	if !is_instance_valid(split_bud):
		return

	split_bud_progress = value
	var eased_value = smoothstep(0.0, 1.0, value)
	var start_position = global_position + split_bud_dir * SPLIT_BUD_START_DISTANCE
	split_spawn_position = _get_current_split_spawn_position()
	var bud_target_scale = _get_visual_size_scale(split_bud.get_meta("gene_size", genes.size)) * 0.82
	split_bud.scale = Vector2.ONE * lerp(0.08, bud_target_scale, eased_value)
	_set_split_bud_center(start_position.lerp(split_spawn_position, eased_value))
	if split_bud.material:
		split_bud.material.set_shader_parameter("energy_ratio", lerp(0.35, 1.0, eased_value))
		split_bud.material.set_shader_parameter("motion_direction", split_bud_dir)
	if body_visual and body_visual.material:
		body_visual.material.set_shader_parameter("motion_direction", _world_to_local_dir(split_bud_dir))

func _world_to_local_dir(world_dir: Vector2) -> Vector2:
	return world_dir.rotated(-global_rotation).normalized()

func _set_split_bud_center(center: Vector2):
	if is_instance_valid(split_bud):
		split_bud.global_position = center - split_bud.size * split_bud.scale * 0.5

func _get_split_bud_center() -> Vector2:
	if is_instance_valid(split_bud):
		return split_bud.global_position + split_bud.size * split_bud.scale * 0.5
	return _get_current_split_spawn_position()

func _get_current_split_spawn_position() -> Vector2:
	return _clamp_to_arena(global_position + split_bud_dir * SPLIT_BUD_SPAWN_DISTANCE, 48.0)

func _get_offspring_species_data(new_genes: Dictionary) -> Dictionary:
	if !_should_form_new_species(new_genes):
		return {
			"id": species_id,
			"color": species_color,
			"name": species_name,
			"origin_genes": species_origin_genes.duplicate(true)
		}

	var new_species_id = int(get_instance_id())
	var new_species_name = ""
	var wm = _get_world_manager()
	if wm:
		if wm.has_method("issue_species_id"):
			new_species_id = wm.issue_species_id()
		if wm.has_method("make_species_name"):
			new_species_name = wm.make_species_name()

	if new_species_name.strip_edges() == "":
		new_species_name = "Вид %03d" % new_species_id

	return {
		"id": new_species_id,
		"color": _get_species_color(new_species_id),
		"name": new_species_name,
		"origin_genes": new_genes.duplicate(true)
	}

func _finish_split(new_genes: Dictionary):
	if is_dying or !is_inside_tree():
		return

	_set_split_bud_progress(1.0)
	var offspring = load("res://scenes/cell.tscn").instantiate()
	offspring.genes = new_genes
	var offspring_species = _get_offspring_species_data(new_genes)
	offspring.species_id = offspring_species["id"]
	offspring.species_color = offspring_species["color"]
	offspring.species_name = offspring_species["name"]
	offspring.species_origin_genes = offspring_species["origin_genes"]
	offspring.energy = _get_offspring_start_energy(new_genes)
	var clamped_spawn_position = _get_split_spawn_position()
	var release_dir = (clamped_spawn_position - global_position).normalized()
	if release_dir == Vector2.ZERO:
		release_dir = split_bud_dir
	_get_arena_node().add_child(offspring)
	offspring.global_position = clamped_spawn_position
	offspring.linear_velocity = Vector2.ZERO
	offspring.angular_velocity = 0.0
	offspring.set_deferred("collision_layer", 0)
	offspring.set_deferred("collision_mask", 0)
	offspring.set_deferred("freeze", true)
	offspring.scale = Vector2.ONE
	_detach_split_bud()
	_animate_newborn(offspring, release_dir)
	energy -= offspring.energy

	if body_visual:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_method(_set_split_pressure, 0.62, 0.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(body_visual, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.set_parallel(false)
		tween.tween_callback(_finish_split_animation)
	else:
		_finish_split_animation()

func _detach_split_bud():
	if is_instance_valid(split_bud):
		split_bud.queue_free()
	split_bud = null
	split_bud_progress = 0.0

func _get_split_spawn_position() -> Vector2:
	if is_instance_valid(split_bud):
		return _get_split_bud_center()
	return _get_current_split_spawn_position()

func _animate_newborn(offspring: Node2D, split_dir: Vector2):
	if !is_instance_valid(offspring):
		return

	var final_position = _clamp_to_arena(offspring.global_position + split_dir.normalized() * SPLIT_NEWBORN_RELEASE_DISTANCE, 48.0)
	var tween = offspring.create_tween()
	tween.tween_property(offspring, "global_position", final_position, 0.62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(Callable(offspring, "_release_newborn_from_tween").bind(split_dir, linear_velocity, angular_velocity))

func _release_newborn_from_tween(split_dir: Vector2, inherited_velocity: Vector2, inherited_angular_velocity: float):
	set_deferred("freeze", false)
	set_deferred("collision_layer", 2)
	set_deferred("collision_mask", 3)
	linear_velocity = inherited_velocity * 0.25 + split_dir * 1.5
	angular_velocity = inherited_angular_velocity * 0.2

func _finish_split_animation():
	_detach_split_bud()
	is_splitting = false

func die(eaten = false):
	if is_dying or pending_death:
		return

	pending_death = true
	call_deferred("_begin_death", eaten)

func _begin_death(eaten = false):
	if is_dying or !is_inside_tree():
		return

	pending_death = false
	is_dying = true
	_play_cell_sound("death")
	_detach_split_bud()
	_clear_worm_body_visual()
	_clear_digestion_visual()
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	set_deferred("freeze", true)
	# КРУГОВОРОТ ЭНЕРГИИ (Распад мембраны)
	if not eaten:
		var food_count = int(genes.size * 3)
		var food_scene = load("res://scenes/food.tscn")

		for i in range(food_count):
			var food = food_scene.instantiate()
			food.is_cell_remains = true
			food.energy_value = 35.0 * genes.size
			food.global_position = _clamp_to_arena(global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20)), 24.0)
			_get_arena_node().call_deferred("add_child", food)

	if body_visual and body_visual.material:
		var duration = 0.22 if eaten else 0.55
		var target_scale = Vector2(0.35, 0.35) if eaten else Vector2(1.35, 1.35)
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_method(_set_dissolve, 0.0, 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(body_visual, "scale", target_scale, duration)
		if USE_POINT_LIGHTS and core_light:
			tween.tween_property(core_light, "energy", 0.0, duration)
		tween.set_parallel(false)
		tween.tween_callback(queue_free)
	else:
		queue_free()

func _set_dissolve(value: float):
	if body_visual and body_visual.material:
		body_visual.material.set_shader_parameter("dissolve", value)

func _process(_delta):
	if is_dying:
		return

	if is_being_digested:
		_clear_worm_body_visual()
		# Во время переваривания обновляем только рамку выделения
		if is_instance_valid(selection_ring):
			var ui = _get_ui_layer()
			selection_ring.visible = (ui and ui.selected_cell == self)
			if is_instance_valid(perception_ring):
				perception_ring.visible = false
		return

	_update_worm_body_visual(_delta)

	visual_update_timer -= _delta
	if visual_update_timer <= 0.0 and body_visual and body_visual.material and !is_splitting:
		visual_update_timer = VISUAL_UPDATE_INTERVAL
		var speed_ratio = clamp(linear_velocity.length() / max(_get_effective_speed(), 1.0), 0.0, 1.0)
		var local_dir = linear_velocity.normalized().rotated(-global_rotation) if linear_velocity.length() > 1.0 else Vector2.RIGHT
		var mat = body_visual.material
		var energy_ratio = clamp(energy / _get_max_energy(), 0.0, 1.0)
		mat.set_shader_parameter("energy_ratio", energy_ratio)
		mat.set_shader_parameter("motion_deform", speed_ratio)
		mat.set_shader_parameter("motion_direction", local_dir)
		if USE_POINT_LIGHTS and core_light:
			core_light.energy = 0.35 + genes.bioluminescence * 0.9 + energy_ratio * 0.25

	if is_instance_valid(selection_ring):
		var ui = _get_ui_layer()
		var is_selected = (ui and ui.selected_cell == self)
		var is_species_highlighted = (ui and ui.get("selected_species_id") == species_id)
		selection_ring.visible = is_selected
		if is_instance_valid(perception_ring):
			perception_ring.visible = is_selected

		# Запрос перерисовки для обновления линии цели
		if is_selected or is_species_highlighted:
			queue_redraw()

func _draw():
	var ui = _get_ui_layer()
	var is_selected = (ui and ui.selected_cell == self)
	var is_species_highlighted = (ui and ui.get("selected_species_id") == species_id)

	if is_species_highlighted:
		var camera = get_viewport().get_camera_2d()
		var zoom_value = camera.zoom.x if camera else 1.0
		var zoom_factor = clamp(inverse_lerp(0.02, 8.0, zoom_value), 0.0, 1.0)
		var fill_alpha = lerp(0.55, 0.15, zoom_factor)
		var ring_alpha = lerp(0.95, 0.38, zoom_factor)
		var glow_color = species_color
		glow_color.a = fill_alpha
		draw_circle(Vector2.ZERO, 24.0 * _get_visual_size_scale(), glow_color)
		var highlight_color = species_color
		highlight_color.a = ring_alpha
		draw_arc(Vector2.ZERO, 32.0 * _get_visual_size_scale(), 0.0, TAU, 48, highlight_color, 3.0, true)

	# Отрисовка оранжевого кольца радиуса страха
	if is_selected and _can_feel_fear():
		var fear_range = _get_fear_detection_range()
		var ring_color = Color(1.0, 0.48, 0.12, 0.35) # Тонкое оранжевое кольцо
		draw_arc(Vector2.ZERO, fear_range, 0.0, TAU, 48, ring_color, 1.5, true)

	if is_selected and is_instance_valid(target) and target.is_inside_tree():
		var local_target_pos = to_local(target.global_position)
		var line_color = Color(0.4, 1.0, 0.4, 0.45) # Зеленый для еды

		if fleeing_from_target:
			line_color = Color(1.0, 0.35, 0.15, 0.6) # Оранжево-красный для угрозы
		elif target.is_in_group("cells"):
			line_color = Color(1.0, 0.2, 0.2, 0.6) # Ярко-красный для атаки/преследования

		# Рисуем линию от центра клетки к цели
		draw_line(Vector2.ZERO, local_target_pos, line_color, 2.0, true)

		# Рисуем кольцо вокруг цели
		draw_arc(local_target_pos, 15.0, 0.0, TAU, 24, line_color, 1.5, true)

func _clamp_to_arena(pos: Vector2, margin: float) -> Vector2:
	var arena_node = _get_arena_node()
	if arena_node and arena_node.get("arena_size") != null:
		var half = arena_node.get("arena_size") / 2.0 - margin
		return Vector2(clamp(pos.x, -half, half), clamp(pos.y, -half, half))
	return pos

func _get_arena_node() -> Node:
	if is_instance_valid(arena_node_cache):
		return arena_node_cache
	arena_node_cache = _resolve_arena_node()
	return arena_node_cache

func _resolve_arena_node() -> Node:
	var p = get_parent()
	while p and p.is_in_group("cells"):
		p = p.get_parent()
	return p if p else get_tree().current_scene

func _get_ui_layer() -> CanvasLayer:
	if is_instance_valid(ui_layer):
		return ui_layer
	ui_layer = get_tree().current_scene.get_node_or_null("UI")
	return ui_layer

func _get_world_manager() -> Node:
	if is_instance_valid(world_manager):
		return world_manager
	world_manager = get_tree().current_scene.get_node_or_null("WorldManager")
	return world_manager

func _on_tree_exiting():
	_clear_worm_body_visual()
	var wm = _get_world_manager()
	if wm and wm.has_method("unregister_cell"):
		wm.unregister_cell(self)
