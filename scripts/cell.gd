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
const PHAGOCYTOSIS_SIZE_ADVANTAGE = 1.04
const VISUAL_SIZE_EXPONENT = 1.28
const MIXED_AGGRESSION = 0.4
const BIOTROPH_MAX_AGGRESSION = 0.4
const PREDATOR_AGGRESSION = 0.6
const PREDATOR_HUNT_ENERGY_RATIO = 0.82
const PREDATOR_REMAINS_SCENT_MAX_RANGE = 1500.0
const PREDATOR_REMAINS_SCENT_MIN_MULTIPLIER = 1.45
const PREDATOR_REMAINS_SCENT_MAX_MULTIPLIER = 2.85
const PREDATOR_HUNGRY_ATTACK_COST_MULTIPLIER = 0.38
const PREDATOR_METABOLISM_MULTIPLIER_FULL = 0.88
const PREDATOR_METABOLISM_MULTIPLIER_HUNGRY = 0.62
const PREDATOR_REMAINS_CHASE_BOOST = 0.46
const SPLIT_BUD_START_DISTANCE = 7.0
const SPLIT_BUD_SPAWN_DISTANCE = 28.0
const SPLIT_NEWBORN_RELEASE_DISTANCE = 14.0
const PERCEPTION_RING_SEGMENTS = 96
const LYSIS_ENERGY_COST = 2.0 # Жесткий налог на выработку ферментов (в секунду)
const LYSIS_GENE_THRESHOLD = 0.35
const LYSIS_AGGRESSION_THRESHOLD = 0.38
const LYSIS_CONTACT_BASE_DAMAGE = 52.0
const LYSIS_CONTACT_COST = 4.5
const LYSIS_ATTACK_BASE_INTERVAL = 0.78
const LYSIS_ATTACK_MIN_INTERVAL = 0.28
const LYSIS_ATTACK_FLASH_DURATION = 0.28
const LYSIS_CYTOPLASM_DROPLET_COUNT = 6
const REMAINS_BASE_ENERGY_PER_SIZE = 112.0
const REMAINS_STORED_ENERGY_RATIO = 0.24
const REMAINS_NUTRITION_MULTIPLIER = 1.28
const PREDATOR_REMAINS_ENERGY_RATIO = 0.98
const SAME_SPECIES_REMAINS_EFFICIENCY = 0.035
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
const CELL_SCENE = preload("res://scenes/cell.tscn")
const FOOD_SCENE = preload("res://scenes/food.tscn")
const WORM_BODY_THRESHOLD = 0.48  # Порог для визуального тела червя
const FLAGELLA_ACTIVATION_THRESHOLD = 0.35  # Порог активации жгутика
const WORM_BODY_SEGMENT_COUNT = 9
const WORM_TRAIL_MIN_DISTANCE = 1.0
const WORM_TRAIL_MAX_POINTS = 72
const OBSTACLE_AVOID_LOOKAHEAD = 240.0
const OBSTACLE_AVOID_MARGIN = 52.0
const FOOD_PICKUP_INTERVAL = 0.075
const FOOD_PICKUP_RADIUS_PADDING = 14.0
const CELL_CONTACT_CHECK_INTERVAL = 0.055
const VISION_UPDATE_INTERVAL_MIN = 0.28
const VISION_UPDATE_INTERVAL_MAX = 0.46
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
	"enzyme_secretion": 0.0,
	"membrane_resistance": 0.2,
	"chemotaxis": 0.0,
	"flagella_power": 0.0,
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
var ai_update_pending = false
var lysis_contact_cooldown = 0.0
var lysis_attack_flash_timer = 0.0
var lysis_attack_flash_target = Vector2.ZERO
var lysis_attack_flash_strength = 0.0
var lysis_hit_flash_timer = 0.0
var lysis_hit_flash_source = Vector2.ZERO
var lysis_hit_flash_strength = 0.0
var lysis_cytoplasm_droplets: Array = []
var lysis_attack_stretch_timer = 0.0
var lysis_attack_stretch_direction = Vector2.RIGHT
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
var food_pickup_timer = 0.0
var cell_contact_check_timer = 0.0
var worm_visual_update_timer = 0.0
var worm_body_visual: Node2D = null
var worm_body_segments: Array[ColorRect] = []
var worm_trail_points: Array[Vector2] = []
var worm_swim_seed = 0.0
var obstacle_avoidance_sides = {}
var cached_size_factor := 1.0
var cached_visual_size_scale := 1.0
var cached_visual_bounds := 1.0
var cached_visual_padding := 1.65
var cached_max_energy := MAX_ENERGY
var cached_lifespan_limit := BASE_LIFESPAN * 4.0
var cached_effective_speed := 400.0
var cached_effective_turn_speed := 15.0
var cached_effective_vision := 400.0
var cached_fear_detection_range := 0.0
var cached_current_force := CURRENT_FORCE
var cached_split_threshold := MAX_ENERGY * 0.95
var cached_split_cost := ENERGY_SPLIT_COST
var cached_worm_strength := 0.0
var cached_flagella_strength := 0.0
var cached_can_eat_floor_food := true
var cached_can_eat_cell_remains := false
var cached_can_lyse_cells := false

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
	food_pickup_timer = randf() * FOOD_PICKUP_INTERVAL
	cell_contact_check_timer = randf() * CELL_CONTACT_CHECK_INTERVAL
	worm_visual_update_timer = randf() * VISUAL_UPDATE_INTERVAL
	if world_manager and world_manager.has_method("register_cell"):
		world_manager.register_cell(self)
		if is_instance_valid(vision_area):
			vision_area.monitoring = false
	tree_exiting.connect(_on_tree_exiting)
	contact_monitor = false
	max_contacts_reported = 0
	linear_damp = 1.5
	angular_damp = 3.0
	body_entered.connect(_on_body_entered)

	if body_visual and body_visual.material:
		body_visual.material = body_visual.material.duplicate()
		body_visual.z_index = 0
	if is_instance_valid(selection_ring):
		selection_ring.z_index = -1
		selection_ring.z_as_relative = true
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
		["enzyme_secretion", 1.0, 1.20],
		["membrane_resistance", 1.0, 0.95],
		["chemotaxis", 1.0, 0.80],
		["flagella_power", 1.0, 1.05],
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
	if aggression >= PREDATOR_AGGRESSION:
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

	var arena = _get_arena_node()
	var audio_pool = arena.get_meta("cell_audio_pool", []) if arena.has_meta("cell_audio_pool") else []
	var player: AudioStreamPlayer2D = null
	for candidate in audio_pool:
		if is_instance_valid(candidate) and !candidate.playing:
			player = candidate
			break
	if player == null:
		player = AudioStreamPlayer2D.new()
		player.finished.connect(func():
			if is_instance_valid(player):
				player.stream = null
		)
		audio_pool.append(player)
		arena.set_meta("cell_audio_pool", audio_pool)
		arena.add_child(player)
	player.stream = pool.pick_random()
	player.global_position = active_position
	var base_volume = -22.0 if kind == "spawn" else -18.0
	player.volume_db = base_volume + linear_to_db(zoom_factor)
	player.pitch_scale = randf_range(0.94, 1.06)
	player.max_distance = SOUND_BASE_MAX_DISTANCE
	player.attenuation = 1.4
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
		abs(float(species_origin_genes.get("shape_spiral", 0.0)) - float(new_genes.get("shape_spiral", 0.0))) +
		abs(float(species_origin_genes.get("flagella_power", 0.0)) - float(new_genes.get("flagella_power", 0.0)))
	) / 9.0

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
	if !genes.has("enzyme_secretion"):
		genes.enzyme_secretion = 0.0
	if !genes.has("membrane_resistance"):
		genes.membrane_resistance = 0.2
	if !genes.has("chemotaxis"):
		genes.chemotaxis = 0.0
	if !genes.has("flagella_power"):
		genes.flagella_power = 0.0
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
	genes.enzyme_secretion = clamp(genes.enzyme_secretion, 0.0, 1.0)
	genes.membrane_resistance = clamp(genes.membrane_resistance, 0.0, 1.0)
	genes.chemotaxis = clamp(genes.chemotaxis, 0.0, 1.0)
	genes.flagella_power = clamp(genes.flagella_power, 0.0, 1.0)
	genes.fear = clamp(genes.fear, 0.0, _get_max_fear_for_aggression())
	genes.shape_elongation = clamp(genes.shape_elongation, 0.0, 1.0)
	genes.shape_spikiness = clamp(genes.shape_spikiness, 0.0, 1.0)
	genes.shape_amoeboid = clamp(genes.shape_amoeboid, 0.0, 1.0)
	genes.shape_tendrils = clamp(genes.shape_tendrils, 0.0, 1.0)
	genes.shape_lobes = clamp(genes.shape_lobes, 0.0, 1.0)
	genes.shape_boxy = clamp(genes.shape_boxy, 0.0, 1.0)
	genes.shape_worm = clamp(genes.shape_worm, 0.0, 1.0)
	genes.shape_spiral = clamp(genes.shape_spiral, 0.0, 1.0)

	_refresh_gene_cache()
	energy = clamp(energy, 0.0, cached_max_energy)
	mass = pow(cached_size_factor, 1.6)

	var vis_scale = cached_visual_size_scale
	var visual_bounds = cached_visual_bounds

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

	vision_shape.shape.radius = cached_effective_vision / vis_scale # Радиус зрения нужно компенсировать
	_update_perception_ring()

	var r = lerp(0.1, 1.0, genes.aggressiveness)
	var g = lerp(0.8, 0.1, genes.aggressiveness)
	var b = lerp(0.2, 0.75, genes.phagocytosis)
	var visual_color = _get_visual_base_color()

	if body_visual and body_visual.material:
		body_visual.material.set_shader_parameter("base_color", visual_color)
		body_visual.material.set_shader_parameter("pulse_speed", 1.0 + (cached_effective_speed / 400.0))
		body_visual.material.set_shader_parameter("deformation", 0.035 + genes.mutation_rate * 0.22)
		body_visual.material.set_shader_parameter("membrane_roughness", genes.membrane_roughness)
		body_visual.material.set_shader_parameter("membrane_asymmetry", genes.membrane_asymmetry)
		body_visual.material.set_shader_parameter("nucleus_size", genes.nucleus_size)
		body_visual.material.set_shader_parameter("bioluminescence", genes.bioluminescence)
		body_visual.material.set_shader_parameter("split_pressure", 0.0)
		body_visual.material.set_shader_parameter("dissolve", 0.0)
		body_visual.material.set_shader_parameter("damage_flash", 0.0)
		body_visual.material.set_shader_parameter("visual_padding", cached_visual_padding)
		body_visual.material.set_shader_parameter("shape_elongation", genes.shape_elongation)
		body_visual.material.set_shader_parameter("shape_spikiness", genes.shape_spikiness)
		body_visual.material.set_shader_parameter("shape_amoeboid", genes.shape_amoeboid)
		body_visual.material.set_shader_parameter("shape_tendrils", genes.shape_tendrils)
		body_visual.material.set_shader_parameter("shape_lobes", genes.shape_lobes)
		body_visual.material.set_shader_parameter("shape_boxy", genes.shape_boxy)
		body_visual.material.set_shader_parameter("shape_worm", genes.shape_worm * 0.18)
		body_visual.material.set_shader_parameter("shape_spiral", genes.shape_spiral * 0.35)

func _refresh_gene_cache():
	cached_size_factor = clamp(genes.size, MIN_SIZE, MAX_SIZE)
	cached_visual_size_scale = pow(cached_size_factor, VISUAL_SIZE_EXPONENT)
	cached_visual_bounds = _get_visual_bounds_multiplier()
	cached_visual_padding = 1.65 * cached_visual_bounds
	cached_max_energy = MAX_ENERGY * pow(cached_size_factor, 1.25)
	cached_lifespan_limit = BASE_LIFESPAN * 4.0 * pow(cached_size_factor, 0.85)
	cached_effective_vision = genes.vision_range * (1.0 + genes.get("shape_spikiness", 0.0) * 0.25 + genes.get("chemotaxis", 0.0) * 0.18) * pow(cached_size_factor, 0.4)
	cached_fear_detection_range = min(cached_effective_vision, 1000.0 * genes.fear)
	cached_effective_speed = genes.speed / pow(cached_size_factor, 0.45)
	cached_effective_speed *= 1.0 + genes.get("shape_elongation", 0.0) * 0.25
	cached_worm_strength = clamp(inverse_lerp(WORM_BODY_THRESHOLD, 1.0, genes.get("shape_worm", 0.0)), 0.0, 1.0)
	cached_flagella_strength = clamp(genes.get("flagella_power", 0.0), 0.0, 1.0)  # Не зависит от shape_worm
	cached_effective_speed *= 1.0 + genes.get("shape_worm", 0.0) * 0.12 + cached_flagella_strength * 0.35 + genes.get("shape_spiral", 0.0) * 0.08 - genes.get("shape_boxy", 0.0) * 0.10
	cached_effective_turn_speed = genes.turn_speed / pow(cached_size_factor, 0.65)
	cached_effective_turn_speed *= 1.0 + genes.get("shape_amoeboid", 0.0) * 0.30
	cached_effective_turn_speed *= 1.0 + genes.get("shape_worm", 0.0) * 0.06 - cached_flagella_strength * 0.18 + genes.get("shape_spiral", 0.0) * 0.18 - genes.get("shape_boxy", 0.0) * 0.12
	cached_effective_turn_speed *= 1.0 - genes.get("shape_elongation", 0.0) * 0.15
	cached_current_force = CURRENT_FORCE * pow(cached_size_factor, 0.35)
	var threshold_pct = lerp(0.95, 0.55, inverse_lerp(MIN_SIZE, MAX_SIZE, cached_size_factor))
	if genes.aggressiveness >= MIXED_AGGRESSION:
		threshold_pct *= lerp(0.94, 0.88, inverse_lerp(MIXED_AGGRESSION, 1.0, genes.aggressiveness))
	cached_split_threshold = cached_max_energy * threshold_pct
	cached_split_cost = ENERGY_SPLIT_COST * pow(cached_size_factor, 0.9)
	if genes.aggressiveness >= MIXED_AGGRESSION:
		cached_split_cost *= 0.48
	cached_can_eat_floor_food = genes.aggressiveness < PREDATOR_AGGRESSION
	var has_lysis = _has_lysis_genes()
	var has_phagocytosis = genes.phagocytosis >= PHAGOCYTOSIS_MIN_GENE and genes.aggressiveness >= PHAGOCYTOSIS_MIN_AGGRESSION
	cached_can_eat_cell_remains = genes.aggressiveness >= MIXED_AGGRESSION
	cached_can_lyse_cells = has_lysis

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
	return cached_size_factor

func _get_visual_size_scale(size_value: float = -1.0) -> float:
	if size_value < 0.0:
		return cached_visual_size_scale
	return pow(clamp(size_value, MIN_SIZE, MAX_SIZE), VISUAL_SIZE_EXPONENT)

func _get_visual_base_color(source_genes: Dictionary = genes) -> Color:
	var r = lerp(0.1, 1.0, source_genes.get("aggressiveness", 0.0))
	var g = lerp(0.8, 0.1, source_genes.get("aggressiveness", 0.0))
	var b = lerp(0.2, 0.75, source_genes.get("phagocytosis", 0.0))
	var enzyme = source_genes.get("enzyme_secretion", 0.0)
	var resistance = source_genes.get("membrane_resistance", 0.2)
	r = clamp(r + enzyme * 0.18, 0.0, 1.0)
	g = clamp(g - enzyme * 0.10 + resistance * 0.08, 0.0, 1.0)
	b = clamp(b - enzyme * 0.08 + resistance * 0.10, 0.0, 1.0)
	return Color(r, g, b, 1.0)

func _get_visual_bounds_multiplier(source_genes: Dictionary = genes) -> float:
	return 1.0 + source_genes.get("shape_worm", 0.0) * 2.6 + source_genes.get("shape_spiral", 0.0) * 1.2 + source_genes.get("shape_tendrils", 0.0) * 0.55 + source_genes.get("shape_lobes", 0.0) * 0.22 + source_genes.get("shape_boxy", 0.0) * 0.18 + source_genes.get("shape_elongation", 0.0) * 0.65

func _get_visual_padding(source_genes: Dictionary = genes) -> float:
	if source_genes == genes:
		return cached_visual_padding
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
	return cached_effective_vision

func _get_fear_detection_range() -> float:
	return cached_fear_detection_range

func _is_threatening_cell(other) -> bool:
	if !is_instance_valid(other) or !other.is_in_group("cells") or other == self:
		return false
	var other_genes = other.get("genes")
	if typeof(other_genes) != TYPE_DICTIONARY:
		return false
	var has_lysis = other_genes.get("enzyme_secretion", 0.0) >= LYSIS_GENE_THRESHOLD and other_genes.get("aggressiveness", 0.0) >= LYSIS_AGGRESSION_THRESHOLD
	var has_phago = other_genes.get("phagocytosis", 0.0) >= PHAGOCYTOSIS_MIN_GENE and other_genes.get("aggressiveness", 0.0) >= PHAGOCYTOSIS_MIN_AGGRESSION
	return has_lysis or has_phago or other_genes.get("aggressiveness", 0.0) >= MIXED_AGGRESSION

func _can_hunt_cells() -> bool:
	return genes.aggressiveness >= BIOTROPH_MAX_AGGRESSION and _is_hungry_predator()

func _has_lysis_genes() -> bool:
	return genes.get("enzyme_secretion", 0.0) >= LYSIS_GENE_THRESHOLD and genes.aggressiveness >= LYSIS_AGGRESSION_THRESHOLD

func _can_lyse_cells() -> bool:
	return cached_can_lyse_cells and _is_hungry_predator()

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
	return cached_max_energy

func _get_lifespan_limit() -> float:
	return cached_lifespan_limit

func _get_remains_energy_value() -> float:
	var structural_energy = REMAINS_BASE_ENERGY_PER_SIZE * pow(_size_factor(), 1.15)
	var stored_energy = max(energy, 0.0) * REMAINS_STORED_ENERGY_RATIO
	var upper_bound = _get_max_energy() * 0.88
	return clamp(structural_energy + stored_energy, 2.0, upper_bound)

func _get_effective_speed() -> float:
	# Снижаем штраф скорости за размер (0.45 вместо 0.85), чтобы крупные клетки выживали
	return cached_effective_speed

func _get_effective_turn_speed() -> float:
	# Снижаем штраф маневренности за размер (0.65 вместо 1.15)
	return cached_effective_turn_speed

func _get_worm_strength() -> float:
	# Сила жгутика для визуала — зависит от flagella_power, не от shape_worm
	return cached_flagella_strength

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
	worm_body_visual.z_index = 0
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

func _prime_worm_trail(forward_dir: Vector2):
	if _get_worm_strength() <= 0.0:
		return
	var dir = forward_dir.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT.rotated(rotation)
	worm_trail_points.clear()
	var vis_scale = _get_visual_size_scale()
	var body_length = 38.0 * vis_scale * (1.0 + genes.get("shape_worm", 0.0) * 1.25 + genes.get("shape_spiral", 0.0) * 0.30)
	for i in range(WORM_TRAIL_MAX_POINTS):
		var t = float(i) / float(max(WORM_TRAIL_MAX_POINTS - 1, 1))
		worm_trail_points.append(global_position - dir * body_length * t)

func _update_worm_body_visual(_delta: float):
	var worm_strength = _get_worm_strength()
	# Жгутик показывается только когда flagella_power > 0.35
	if genes.get("flagella_power", 0.0) <= FLAGELLA_ACTIVATION_THRESHOLD or is_dying or is_being_digested:
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

func _bend_worm_trail_from_impact(impact_position: Vector2, impact_velocity: Vector2 = Vector2.ZERO):
	var worm_strength = _get_worm_strength()
	if worm_strength <= 0.0 or worm_trail_points.size() < 3:
		return

	var push_dir = global_position - impact_position
	if push_dir == Vector2.ZERO:
		push_dir = impact_velocity.normalized()
	if push_dir == Vector2.ZERO:
		push_dir = Vector2.RIGHT.rotated(rotation)
	push_dir = push_dir.normalized()

	for i in range(1, worm_trail_points.size()):
		var t = float(i) / float(max(worm_trail_points.size() - 1, 1))
		var distance = worm_trail_points[i].distance_to(impact_position)
		var falloff = clamp(1.0 - distance / 140.0, 0.0, 1.0)
		var tail_weight = sin(t * PI)
		worm_trail_points[i] += push_dir * falloff * tail_weight * lerp(8.0, 22.0, worm_strength)
		if impact_velocity != Vector2.ZERO:
			worm_trail_points[i] += impact_velocity.normalized() * falloff * tail_weight * 6.0

func _get_obstacle_avoidance(base_dir: Vector2) -> Vector2:
	var forward = base_dir.normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.RIGHT.rotated(rotation)

	var side = Vector2(-forward.y, forward.x)
	var avoidance = Vector2.ZERO
	var lookahead = OBSTACLE_AVOID_LOOKAHEAD * (0.75 + clamp(linear_velocity.length() / max(_get_effective_speed(), 1.0), 0.0, 1.0))

	var obstacles = []
	if world_manager and world_manager.has_method("get_obstacles_near"):
		obstacles = world_manager.get_obstacles_near(global_position, lookahead + OBSTACLE_AVOID_MARGIN * 3.0)
	else:
		obstacles = get_tree().get_nodes_in_group("obstacles")

	for obstacle in obstacles:
		if !is_instance_valid(obstacle):
			continue
		var to_obstacle = obstacle.global_position - global_position
		var ahead = to_obstacle.dot(forward)
		var obstacle_radius = float(obstacle.get("radius")) if obstacle.get("radius") != null else 48.0
		var avoid_radius = obstacle_radius + OBSTACLE_AVOID_MARGIN * _get_visual_size_scale()
		var target_anchor = target.get("growth_anchor") if is_instance_valid(target) and target.get("growth_anchor") != null else null
		var obstacle_is_target_anchor = is_instance_valid(target_anchor) and target_anchor == obstacle
		if obstacle_is_target_anchor:
			avoid_radius = obstacle_radius + max(18.0, 12.0 * _get_visual_size_scale())

		if ahead < -avoid_radius or ahead > lookahead + avoid_radius:
			continue

		var lateral = to_obstacle.dot(side)
		var abs_lateral = abs(lateral)
		if abs_lateral > avoid_radius:
			continue

		var side_sign = _get_stable_obstacle_side(obstacle, lateral)
		var path_weight = 1.0 - clamp(abs_lateral / avoid_radius, 0.0, 1.0)
		var ahead_weight = 1.0 - clamp(max(ahead, 0.0) / max(lookahead, 1.0), 0.0, 1.0) * 0.45
		var steer_strength = 1.55 if obstacle_is_target_anchor else 2.8
		avoidance += side * side_sign * path_weight * ahead_weight * steer_strength

		var distance = max(to_obstacle.length(), 0.001)
		if distance < avoid_radius:
			avoidance -= to_obstacle / distance * (1.0 - distance / avoid_radius) * 3.5

	return avoidance

func _get_stable_obstacle_side(obstacle: Node2D, lateral: float) -> float:
	var obstacle_id = obstacle.get_instance_id()
	if abs(lateral) > 8.0:
		var side_sign = -1.0 if lateral > 0.0 else 1.0
		obstacle_avoidance_sides[obstacle_id] = side_sign
		return side_sign
	if obstacle_avoidance_sides.has(obstacle_id):
		return float(obstacle_avoidance_sides[obstacle_id])
	var target_side = 0.0
	if is_instance_valid(target):
		var to_obstacle = obstacle.global_position - global_position
		var to_target = target.global_position - global_position
		target_side = sign(to_obstacle.cross(to_target))
	var fallback = 1.0 if sin(age + float(obstacle_id % 13)) >= 0.0 else -1.0
	var side = -target_side if target_side != 0.0 else fallback
	obstacle_avoidance_sides[obstacle_id] = side
	return side

func _get_effective_current_force() -> float:
	return cached_current_force

func _get_split_threshold() -> float:
	# Крупным клеткам нужно заполнить меньший процент бака энергии для деления (от 95% для мелких до 55% для гигантов)
	return cached_split_threshold

func _get_split_cost() -> float:
	return cached_split_cost

func _get_offspring_start_energy(new_genes: Dictionary) -> float:
	var offspring_max_energy = MAX_ENERGY * pow(clamp(new_genes.size, MIN_SIZE, MAX_SIZE), 1.25)
	# Даем больше стартовой энергии потомкам крупных клеток (1.1 вместо 0.8)
	var start_energy = ENERGY_FOR_OFFSPRING * pow(clamp(new_genes.size, MIN_SIZE, MAX_SIZE), 1.1)
	if new_genes.get("aggressiveness", 0.0) >= MIXED_AGGRESSION:
		start_energy *= 1.12
	return min(start_energy, offspring_max_energy * 0.50)

func _physics_process(delta):
	if is_dying or is_being_digested:
		return

	var scheduler_delta = delta / max(Engine.time_scale, 0.001)
	var spatial_scheduler_delta = max(scheduler_delta, delta * 0.35)

	spatial_update_timer -= spatial_scheduler_delta
	if spatial_update_timer <= 0.0:
		spatial_update_timer = SPATIAL_UPDATE_INTERVAL
		if world_manager and world_manager.has_method("update_cell_spatial"):
			world_manager.update_cell_spatial(self)

	age += delta
	vision_timer -= scheduler_delta
	lysis_contact_cooldown = max(lysis_contact_cooldown - delta, 0.0)

	# 1. МЕТАБОЛИЗМ + НАЛОГ НА АГРЕССИЮ
	var aging_factor = 1.0 + (age / BASE_LIFESPAN) * 0.5
	var effective_speed = _get_effective_speed()
	var effective_turn_speed = _get_effective_turn_speed()
	var mobility_cost = (effective_speed * 0.002) + (effective_turn_speed * 0.1)
	var energy_ratio = clamp(energy / max(_get_max_energy(), 1.0), 0.0, 1.0)

	# Выработка растворяющих ферментов требует колоссальной энергии
	var aggression_cost = (genes.enzyme_secretion * genes.aggressiveness * LYSIS_ENERGY_COST) + genes.phagocytosis * 0.65 + genes.fear * 0.18
	if cached_can_eat_cell_remains:
		aggression_cost *= lerp(PREDATOR_HUNGRY_ATTACK_COST_MULTIPLIER, 1.0, energy_ratio)
	var flagella_cost = cached_flagella_strength * 0.42
	var membrane_cost = genes.membrane_resistance * 0.18

	# Закон Клайбера: крупные клетки гораздо более энергоэффективны на единицу массы (pow 0.4 вместо 0.85)
	var metabolism = (METABOLISM_IDLE + mobility_cost + aggression_cost + flagella_cost + membrane_cost + (_get_effective_vision() * 0.001)) * pow(_size_factor(), 0.4) * aging_factor
	if cached_can_eat_cell_remains:
		metabolism *= lerp(PREDATOR_METABOLISM_MULTIPLIER_HUNGRY, PREDATOR_METABOLISM_MULTIPLIER_FULL, energy_ratio)

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

	_process_contact_lysis()
	_process_food_pickup(scheduler_delta)
	_process_cell_contact_checks(scheduler_delta)

	if is_splitting:
		linear_velocity *= 0.96
		angular_velocity *= 0.9
		return

	# 2. Деление (Митоз)
	if energy >= _get_split_threshold():
		split()

	# 3. Оптимизированное Зрение
	if vision_timer <= 0.0:
		_request_vision_update()

	# 4. Движение
	var current = _sample_liquid_current(global_position, Time.get_ticks_msec() * 0.001)
	apply_central_force(current * _get_effective_current_force() * genes.size)

	var current_dir = Vector2.RIGHT.rotated(rotation)
	var desired_dir = current_dir
	var is_active_steering = false
	var fear_boost = 1.0

	if is_instance_valid(target):
		var target_position = target.global_position
		if !fleeing_from_target and target.has_method("get_navigation_position_for"):
			target_position = target.get_navigation_position_for(self)
		desired_dir = (global_position - target_position).normalized() if fleeing_from_target else (target_position - global_position).normalized()
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

	var obstacle_avoid_dir = _get_obstacle_avoidance(desired_dir)
	if obstacle_avoid_dir != Vector2.ZERO:
		is_active_steering = true
		desired_dir = (desired_dir + obstacle_avoid_dir).normalized()

	var worm_strength = _get_worm_strength()
	if worm_strength > 0.0:
		desired_dir = _get_worm_swim_direction(desired_dir, current_dir, is_active_steering)
		if !is_active_steering and worm_strength > 0.35:
			is_active_steering = true

	if is_active_steering:
		var angle_to = current_dir.angle_to(desired_dir)
		apply_torque(angle_to * effective_turn_speed * 200.0 * fear_boost * mass)
		var alignment_bonus = lerp(1.0, 1.35, cached_flagella_strength) if abs(angle_to) < 0.35 else lerp(0.2, 0.12, cached_flagella_strength)
		var remains_chase_boost = _get_remains_chase_boost() if _is_cell_remains_food(target) else 1.0
		var speed_mult = alignment_bonus * fear_boost * remains_chase_boost
		apply_central_force(current_dir * effective_speed * speed_mult * mass * 1.5)
	else:
		apply_torque(randf_range(-1, 1) * effective_turn_speed * 20.0 * mass)
		apply_central_force(current_dir * 50.0 / pow(_size_factor(), 0.55) * mass * 1.5)

	# Мягкое ограничение максимальной скорости, чтобы физика не ломалась при долгих погонях
	var max_vel = effective_speed * (2.2 if fleeing_from_target else 1.6)
	if linear_velocity.length() > max_vel:
		linear_velocity = linear_velocity.limit_length(lerp(linear_velocity.length(), max_vel, delta * 8.0))

# ФАГОЦИТОЗ / ЛИЗИС
func _request_vision_update():
	if ai_update_pending:
		return
	var wm = _get_world_manager()
	if wm and wm.has_method("request_cell_ai_update"):
		ai_update_pending = wm.request_cell_ai_update(self)
		if ai_update_pending:
			return
	_run_scheduled_vision_update()

func _run_scheduled_vision_update():
	if is_dying or pending_death or is_being_digested:
		ai_update_pending = false
		return

	ai_update_pending = false
	vision_timer = randf_range(VISION_UPDATE_INTERVAL_MIN, VISION_UPDATE_INTERVAL_MAX)
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
		if dist > _get_target_keep_range(target):
			target = null
		elif _should_prefer_remains_now():
			var remains_target = _find_nearest_remains_target()
			if is_instance_valid(remains_target) and remains_target != target:
				target = remains_target

	if !is_instance_valid(target):
		fleeing_from_target = false
		target = _find_nearest_target()
		if is_instance_valid(target) and target.is_in_group("cells"):
			_try_play_alert_sound()

func _process_food_pickup(delta: float):
	if !can_eat_floor_food() and !can_eat_cell_remains():
		return
	if _try_consume_target_food():
		return
	food_pickup_timer -= delta
	if food_pickup_timer > 0.0:
		return
	food_pickup_timer = FOOD_PICKUP_INTERVAL + randf() * FOOD_PICKUP_INTERVAL * 0.45
	_try_consume_nearby_food()

func _get_food_pickup_radius() -> float:
	return 16.0 * _get_visual_size_scale() + FOOD_PICKUP_RADIUS_PADDING

func _try_consume_target_food() -> bool:
	if !_is_cell_remains_food(target) and !(is_instance_valid(target) and target.is_in_group("food")):
		return false
	var pickup_radius = _get_food_pickup_radius() + 10.0 * max(target.scale.x, target.scale.y)
	if global_position.distance_squared_to(target.global_position) > pickup_radius * pickup_radius:
		return false
	return _try_consume_food_node(target)

func _try_consume_nearby_food() -> bool:
	var wm = _get_world_manager()
	if !wm or !wm.has_method("get_food_near"):
		return false
	var pickup_radius = _get_food_pickup_radius()
	var candidates = wm.get_food_near(global_position, pickup_radius + 14.0)
	var closest = null
	var closest_dist = INF
	for food in candidates:
		if !is_instance_valid(food) or !food.is_in_group("food"):
			continue
		if food.has_method("can_be_eaten_by") and !food.can_be_eaten_by(self):
			continue
		var scaled_radius = pickup_radius + 10.0 * max(food.scale.x, food.scale.y)
		var d = global_position.distance_squared_to(food.global_position)
		if d <= scaled_radius * scaled_radius and d < closest_dist:
			closest_dist = d
			closest = food
	if is_instance_valid(closest):
		return _try_consume_food_node(closest)
	return false

func _try_consume_food_node(food) -> bool:
	if !is_instance_valid(food) or !food.has_method("try_consume_by"):
		return false
	return food.try_consume_by(self)

func _process_cell_contact_checks(delta: float):
	var needs_cell_contact = _can_hunt_cells() or _can_lyse_cells() or genes.get("flagella_power", 0.0) > FLAGELLA_ACTIVATION_THRESHOLD
	if !needs_cell_contact:
		return
	cell_contact_check_timer -= delta
	if cell_contact_check_timer > 0.0:
		return
	cell_contact_check_timer = CELL_CONTACT_CHECK_INTERVAL + randf() * CELL_CONTACT_CHECK_INTERVAL * 0.35
	_try_process_nearby_cell_contacts()
	_try_process_nearby_obstacle_impacts()

func _get_cell_contact_range(other = null) -> float:
	var range = 24.0 + 20.0 * _get_visual_size_scale()
	if is_instance_valid(other) and other.has_method("_get_visual_size_scale"):
		range += other._get_visual_size_scale() * 18.0
	else:
		range += 18.0
	return range

func _try_process_nearby_cell_contacts():
	var wm = _get_world_manager()
	if !wm or !wm.has_method("get_cells_near"):
		return
	var query_radius = _get_cell_contact_range() + 42.0
	var bodies = wm.get_cells_near(global_position, query_radius)
	for body in bodies:
		if !is_instance_valid(body) or body == self or !body.is_in_group("cells"):
			continue
		if body.get("is_dying") or body.get("pending_death") or body.get("is_being_digested"):
			continue
		var contact_range = _get_cell_contact_range(body)
		if global_position.distance_squared_to(body.global_position) > contact_range * contact_range:
			continue
		if genes.get("flagella_power", 0.0) > FLAGELLA_ACTIVATION_THRESHOLD:
			var impact_velocity = body.linear_velocity if body is RigidBody2D else Vector2.ZERO
			_bend_worm_trail_from_impact(body.global_position, impact_velocity)
		if is_same_species(body):
			continue
		if _can_phagocytose(body):
			body.is_being_digested = true
			call_deferred("_begin_phagocytosis", body)
			return
		if _can_lyse_cells():
			if _try_contact_lysis(body):
				return

func _try_process_nearby_obstacle_impacts():
	if genes.get("flagella_power", 0.0) <= FLAGELLA_ACTIVATION_THRESHOLD:
		return
	var wm = _get_world_manager()
	if !wm or !wm.has_method("get_obstacles_near"):
		return
	var query_radius = _get_cell_contact_range() + 60.0
	var obstacles = wm.get_obstacles_near(global_position, query_radius)
	for obstacle in obstacles:
		if !is_instance_valid(obstacle):
			continue
		var obstacle_radius = float(obstacle.get("radius")) if obstacle.get("radius") != null else 40.0
		var contact_range = _get_cell_contact_range() + obstacle_radius
		if global_position.distance_squared_to(obstacle.global_position) <= contact_range * contact_range:
			var impact_velocity = obstacle.linear_velocity if obstacle is RigidBody2D else Vector2.ZERO
			_bend_worm_trail_from_impact(obstacle.global_position, impact_velocity)
			return

func _process_contact_lysis():
	if lysis_contact_cooldown > 0.0 or !_can_lyse_cells():
		return
	if !is_instance_valid(target) or !target.is_in_group("cells") or is_same_species(target):
		return
	var contact_range = 50.0
	if target.has_method("_get_visual_size_scale"):
		contact_range = 24.0 + 20.0 * _get_visual_size_scale() + target._get_visual_size_scale() * 18.0
	if global_position.distance_squared_to(target.global_position) > contact_range * contact_range:
		return
	_try_contact_lysis(target)

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
	if is_instance_valid(body) and (body.is_in_group("cells") or body.is_in_group("obstacles")):
		var impact_velocity = body.linear_velocity if body is RigidBody2D else Vector2.ZERO
		_bend_worm_trail_from_impact(body.global_position, impact_velocity)
	if body.is_in_group("cells") and body != self:
		if body.is_dying or body.pending_death or body.is_being_digested:
			return
		if is_same_species(body):
			return
		if _can_phagocytose(body):
			body.is_being_digested = true
			call_deferred("_begin_phagocytosis", body)
			return
		if _can_lyse_cells():
			_try_contact_lysis(body)

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

	var required_advantage = 0.04
	# Колючесть жертвы мешает её проглотить
	required_advantage += victim.genes.get("shape_spikiness", 0.0) * 0.14
	# Идеально круглые кокки (все гены формы низкие) имеют защиту
	if victim.genes.get("shape_elongation", 0.0) < 0.15 and victim.genes.get("shape_spikiness", 0.0) < 0.15 and victim.genes.get("shape_amoeboid", 0.0) < 0.15:
		required_advantage += 0.08

	return genes.aggressiveness > victim.genes.aggressiveness + required_advantage

func _try_contact_lysis(victim) -> bool:
	if !is_instance_valid(victim) or victim.is_dying or victim.pending_death or victim.is_being_digested:
		return false
	if is_same_species(victim) or !_can_lyse_cells():
		return false
	if lysis_contact_cooldown > 0.0:
		return false
	if energy <= LYSIS_CONTACT_COST:
		return false

	lysis_contact_cooldown = _get_lysis_attack_interval()

	var victim_size = max(victim.genes.get("size", 1.0), 0.1)
	var attacker_size = max(genes.size, 0.1)
	var size_ratio = clamp(attacker_size / victim_size, 0.45, 1.65)
	var size_factor = lerp(0.62, 1.34, inverse_lerp(0.55, 1.45, size_ratio))
	var vitality = 0.5
	if victim.has_method("_get_max_energy"):
		vitality = clamp(victim.energy / max(victim._get_max_energy(), 1.0), 0.0, 1.0)

	var victim_resistance = victim.genes.get("membrane_resistance", 0.2) * 0.72
	victim_resistance += victim.genes.get("shape_spikiness", 0.0) * 0.18
	victim_resistance += victim.genes.get("shape_boxy", 0.0) * 0.12
	victim_resistance += clamp(victim_size - attacker_size, 0.0, 2.0) * 0.10
	victim_resistance += vitality * 0.16

	var enzyme_pressure = genes.enzyme_secretion * 0.92 + genes.aggressiveness * 0.34
	var tendril_bonus = genes.get("shape_tendrils", 0.0) * 0.16
	var damage_factor = max(0.16, enzyme_pressure + size_factor * 0.24 + tendril_bonus - victim_resistance * 0.62)
	var damage = LYSIS_CONTACT_BASE_DAMAGE * damage_factor
	var cost = LYSIS_CONTACT_COST * lerp(1.15, 0.72, genes.enzyme_secretion)
	energy = max(energy - cost, 0.0)
	victim.energy -= damage
	target = victim
	_start_lysis_attack_visual(victim, damage_factor)
	if victim.has_method("_receive_lysis_hit_visual"):
		victim._receive_lysis_hit_visual(global_position, damage_factor)
	_apply_lysis_impulse(victim, damage_factor)

	if victim.energy <= 0.0:
		target = null
		victim.die(false)
		return true
	return false

func _get_lysis_attack_interval() -> float:
	var enzyme = genes.get("enzyme_secretion", 0.0)
	var tendrils = genes.get("shape_tendrils", 0.0)
	var interval = lerp(LYSIS_ATTACK_BASE_INTERVAL, LYSIS_ATTACK_MIN_INTERVAL, enzyme)
	return interval * lerp(1.0, 0.82, tendrils)

func _start_lysis_attack_visual(victim, strength: float):
	lysis_attack_flash_timer = LYSIS_ATTACK_FLASH_DURATION
	lysis_attack_flash_target = victim.global_position
	lysis_attack_flash_strength = clamp(strength, 0.0, 1.6)
	if body_visual and !is_splitting:
		var attack_dir = (victim.global_position - global_position).normalized()
		if attack_dir == Vector2.ZERO:
			attack_dir = Vector2.RIGHT.rotated(rotation)
		lysis_attack_stretch_timer = 0.22
		lysis_attack_stretch_direction = _world_to_local_dir(attack_dir)
		if body_visual.material:
			body_visual.material.set_shader_parameter("motion_direction", lysis_attack_stretch_direction)
			body_visual.material.set_shader_parameter("motion_deform", min(1.15, 0.70 + strength * 0.22))
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(body_visual, "scale", Vector2(1.20, 0.86), 0.11)
		tween.tween_property(body_visual, "scale", Vector2.ONE, 0.18)
	queue_redraw()

func _receive_lysis_hit_visual(source_pos: Vector2, strength: float):
	lysis_hit_flash_timer = LYSIS_ATTACK_FLASH_DURATION
	lysis_hit_flash_source = source_pos
	lysis_hit_flash_strength = clamp(strength, 0.0, 1.6)
	_spawn_lysis_cytoplasm_droplets(source_pos, strength)
	if body_visual and body_visual.material:
		body_visual.material.set_shader_parameter("damage_flash", min(0.55, 0.22 + strength * 0.16))
	queue_redraw()

func _spawn_lysis_cytoplasm_droplets(source_pos: Vector2, strength: float):
	lysis_cytoplasm_droplets.clear()
	var away_world = (global_position - source_pos).normalized()
	if away_world == Vector2.ZERO:
		away_world = Vector2.RIGHT.rotated(rotation)
	var away = away_world.rotated(-global_rotation)
	var base_radius = 14.0 * _get_visual_size_scale()
	var count = LYSIS_CYTOPLASM_DROPLET_COUNT + int(clamp(strength, 0.0, 1.0) * 3.0)
	var cell_color = _get_visual_base_color()
	for i in range(count):
		var spread = randf_range(-0.9, 0.9)
		var dir = away.rotated(spread)
		var start = dir * randf_range(base_radius * 0.82, base_radius * 1.08)
		var drift = dir * randf_range(10.0, 24.0) * (0.65 + clamp(strength, 0.0, 1.2) * 0.25)
		lysis_cytoplasm_droplets.append({
			"start": start,
			"drift": drift,
			"radius": randf_range(1.5, 3.4) * _get_visual_size_scale(),
			"phase": randf() * TAU,
			"color": cell_color
		})

func _apply_lysis_impulse(victim, strength: float):
	if not (victim is RigidBody2D):
		return
	var dir = (victim.global_position - global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT.rotated(rotation)
	var impulse = dir * (28.0 + 34.0 * clamp(strength, 0.0, 1.2)) * max(genes.size, 0.5)
	victim.apply_central_impulse(impulse)

func _begin_phagocytosis(victim):
	if !is_instance_valid(victim):
		return

	target = null
	var digestible_energy = max(victim.energy, 8.0)
	if victim.has_method("_get_remains_energy_value"):
		digestible_energy = max(digestible_energy, victim._get_remains_energy_value())
	digestion_energy_left = digestible_energy * lerp(0.95, 1.95, genes.phagocytosis)
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
		# FIX: Вызываем die(true) вместо queue_free() чтобы жертва правильно обработала смерть
		# (eaten=true означает что клетка была съедена, поэтому не спавнится еда из останков)
		var victim = digestion_visual
		digestion_visual = null  # Сбрасываем ссылку перед вызовом die()
		if is_instance_valid(victim):
			victim.die(true)  # Правильная смерть вместо просто queue_free()
	digestion_visual = null
	digestion_visual_base_scale = Vector2.ONE
	digestion_visual_center = Vector2.ZERO

func _is_cell_remains_food(node) -> bool:
	return is_instance_valid(node) and node.is_in_group("food") and bool(node.get("is_cell_remains"))

func _get_energy_ratio() -> float:
	return clamp(energy / max(_get_max_energy(), 1.0), 0.0, 1.0)

func _get_remains_scan_range() -> float:
	var hunger = 1.0 - _get_energy_ratio()
	var scent_multiplier = lerp(PREDATOR_REMAINS_SCENT_MIN_MULTIPLIER, PREDATOR_REMAINS_SCENT_MAX_MULTIPLIER, hunger)
	scent_multiplier += genes.get("chemotaxis", 0.0) * 0.45
	return min(_get_effective_vision() * scent_multiplier, PREDATOR_REMAINS_SCENT_MAX_RANGE)

func _get_target_keep_range(target_node) -> float:
	if _is_cell_remains_food(target_node):
		return max(_get_effective_vision(), _get_remains_scan_range())
	return _get_effective_vision()

func _get_remains_target_score(food_node, distance_sq: float) -> float:
	var hunger = 1.0 - _get_energy_ratio()
	var score = distance_sq * lerp(0.55, 0.16, hunger)
	var source_id = 0
	if food_node.get("source_species_id") != null:
		source_id = int(food_node.get("source_species_id"))
	if source_id == species_id:
		score *= 4.5
	return score

func _get_remains_chase_boost() -> float:
	var hunger = 1.0 - _get_energy_ratio()
	return 1.0 + PREDATOR_REMAINS_CHASE_BOOST * hunger + genes.get("chemotaxis", 0.0) * 0.18

func _should_prefer_remains_now() -> bool:
	return can_eat_cell_remains() and energy < _get_max_energy() * 0.95

func _find_nearest_remains_target():
	if !can_eat_cell_remains():
		return null
	var wm = _get_world_manager()
	var scan_range = _get_remains_scan_range()
	var scan_range_sq = scan_range * scan_range
	var areas = wm.get_food_near(global_position, scan_range) if wm and wm.has_method("get_food_near") else vision_area.get_overlapping_areas()
	var closest = null
	var best_score = INF
	for a in areas:
		if !_is_cell_remains_food(a):
			continue
		if a.has_method("can_be_eaten_by") and !a.can_be_eaten_by(self):
			continue
		var d = global_position.distance_squared_to(a.global_position)
		if d > scan_range_sq:
			continue
		var score = _get_remains_target_score(a, d)
		if score < best_score:
			best_score = score
			closest = a
	return closest

func _find_nearest_target():
	var closest = null
	var best_score = INF
	var wm = _get_world_manager()
	var vision_range = _get_effective_vision()
	var vision_range_sq = vision_range * vision_range

	if _should_prefer_remains_now():
		closest = _find_nearest_remains_target()
		if is_instance_valid(closest):
			best_score = _get_remains_target_score(closest, global_position.distance_squared_to(closest.global_position))
	var hungry_remains_found = _should_prefer_remains_now() and _is_cell_remains_food(closest)

	# Пассивные ищут минералы/растения
	if can_eat_floor_food() and !hungry_remains_found:
		var areas = wm.get_food_near(global_position, vision_range) if wm and wm.has_method("get_food_near") else vision_area.get_overlapping_areas()
		for a in areas:
			if is_instance_valid(a) and a.is_in_group("food"):
				if _is_cell_remains_food(a):
					continue
				if a.has_method("can_be_eaten_by") and !a.can_be_eaten_by(self):
					continue
				var d = global_position.distance_squared_to(a.global_position)
				if d <= vision_range_sq and d < best_score:
					best_score = d
					closest = a

	if can_eat_cell_remains() and !_should_prefer_remains_now():
		var remains_target = _find_nearest_remains_target()
		if is_instance_valid(remains_target):
			var score = _get_remains_target_score(remains_target, global_position.distance_squared_to(remains_target.global_position))
			if score < best_score:
				best_score = score
				closest = remains_target

	# Геми-/некротрофы ищут чужие мембраны. Биотрофы не охотятся на клетки.
	if !hungry_remains_found and (_can_hunt_cells() or _can_lyse_cells()):
		var bodies = wm.get_cells_near(global_position, vision_range) if wm and wm.has_method("get_cells_near") else vision_area.get_overlapping_bodies()
		for b in bodies:
			if !is_instance_valid(b) or !b.is_in_group("cells") or b == self or is_same_species(b):
				continue
			var can_attack = genes.aggressiveness > b.genes.aggressiveness + 0.2 or _can_phagocytose(b) or _can_lyse_cells()
			if can_attack:
				var d = global_position.distance_squared_to(b.global_position)
				if d <= vision_range_sq and d < best_score:
					best_score = d
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
	return cached_can_eat_floor_food

func can_eat_cell_remains() -> bool:
	return cached_can_eat_cell_remains and _is_hungry_for_remains()

func _is_hungry_predator() -> bool:
	return energy < _get_max_energy() * PREDATOR_HUNT_ENERGY_RATIO

func _is_hungry_for_remains() -> bool:
	return energy < _get_max_energy() * PREDATOR_REMAINS_ENERGY_RATIO

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

func eat_cell_remains(amount, source_species_id: int = 0) -> bool:
	if !can_eat_cell_remains():
		return false
	var efficiency = max(genes.aggressiveness, max(genes.phagocytosis, genes.get("enzyme_secretion", 0.0)))
	efficiency = max(efficiency, 0.35)
	if source_species_id > 0 and source_species_id == species_id:
		efficiency *= SAME_SPECIES_REMAINS_EFFICIENCY
	var nutrition = amount * efficiency * REMAINS_NUTRITION_MULTIPLIER
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
			elif key in ["membrane_roughness", "membrane_asymmetry", "nucleus_size", "bioluminescence", "phagocytosis", "enzyme_secretion", "membrane_resistance", "chemotaxis", "flagella_power", "shape_elongation", "shape_spikiness", "shape_amoeboid", "shape_tendrils", "shape_lobes", "shape_boxy", "shape_worm", "shape_spiral"]:
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
		split_bud.material.set_shader_parameter("shape_worm", new_genes.get("shape_worm", 0.0) * 0.18)
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
			"origin_genes": species_origin_genes.duplicate(true),
			"parent_id": parent_species_id
		}

	var new_species_id = int(get_instance_id())
	var new_species_name = ""
	var diet_changed = _get_trophic_class(species_origin_genes) != _get_trophic_class(new_genes)
	var wm = _get_world_manager()
	if wm:
		if wm.has_method("issue_species_id"):
			new_species_id = wm.issue_species_id()
		if diet_changed and wm.has_method("make_related_species_name"):
			new_species_name = wm.make_related_species_name(species_name)
		elif wm.has_method("make_species_name"):
			new_species_name = wm.make_species_name()

	if new_species_name.strip_edges() == "":
		new_species_name = "Вид %03d" % new_species_id

	return {
		"id": new_species_id,
		"color": _get_species_color(new_species_id),
		"name": new_species_name,
		"origin_genes": new_genes.duplicate(true),
		"parent_id": species_id
	}

func _finish_split(new_genes: Dictionary):
	if is_dying or !is_inside_tree():
		return

	_set_split_bud_progress(1.0)
	var offspring = CELL_SCENE.instantiate()
	offspring.genes = new_genes
	var offspring_species = _get_offspring_species_data(new_genes)
	offspring.species_id = offspring_species["id"]
	offspring.species_color = offspring_species["color"]
	offspring.species_name = offspring_species["name"]
	offspring.species_origin_genes = offspring_species["origin_genes"]
	offspring.parent_species_id = int(offspring_species.get("parent_id", 0))
	offspring.energy = _get_offspring_start_energy(new_genes)
	var clamped_spawn_position = _get_split_spawn_position()
	var release_dir = (clamped_spawn_position - global_position).normalized()
	if release_dir == Vector2.ZERO:
		release_dir = split_bud_dir
	_get_arena_node().add_child(offspring)
	offspring.global_position = clamped_spawn_position
	if offspring.has_method("_prime_worm_trail"):
		offspring._prime_worm_trail(release_dir)
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
		var food_count = max(1, int(genes.size * 3))
		var remains_energy = _get_remains_energy_value()
		var energy_per_piece = remains_energy / float(food_count)
		for i in range(food_count):
			var food_position = _clamp_to_arena(global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20)), 24.0)
			var wm = _get_world_manager()
			if wm and wm.has_method("spawn_food_at"):
				wm.spawn_food_at(food_position, true, energy_per_piece, species_id)
			else:
				var food = FOOD_SCENE.instantiate()
				food.is_cell_remains = true
				food.source_species_id = species_id
				food.energy_value = energy_per_piece
				food.global_position = food_position
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

func set_world_visual_time_state(multiplier: float, offset: float):
	if body_visual and body_visual.material:
		body_visual.material.set_shader_parameter("time_multiplier", multiplier)
		body_visual.material.set_shader_parameter("time_offset", offset)
	if split_bud and split_bud.material:
		split_bud.material.set_shader_parameter("time_multiplier", multiplier)
		split_bud.material.set_shader_parameter("time_offset", offset)
	for segment in worm_body_segments:
		if is_instance_valid(segment) and segment.material:
			segment.material.set_shader_parameter("time_multiplier", multiplier)
			segment.material.set_shader_parameter("time_offset", offset)

func set_world_visual_time_multiplier(value: float):
	set_world_visual_time_state(value, 0.0)

func _get_visual_update_interval(is_selected: bool = false) -> float:
	if is_selected or is_splitting or lysis_attack_flash_timer > 0.0 or lysis_hit_flash_timer > 0.0:
		return VISUAL_UPDATE_INTERVAL
	var zoom_value = _get_cached_camera_zoom_value()
	var zoomed_out = clamp(inverse_lerp(0.65, 0.06, zoom_value), 0.0, 1.0)
	var interval = lerp(VISUAL_UPDATE_INTERVAL, 0.18, zoomed_out)
	if genes.get("flagella_power", 0.0) > FLAGELLA_ACTIVATION_THRESHOLD:
		interval = min(interval, 0.11)
	return interval

func _get_cached_camera_zoom_value() -> float:
	var wm = _get_world_manager()
	if wm and wm.has_method("get_cached_camera_zoom"):
		return wm.get_cached_camera_zoom()
	return 1.0

func _should_update_worm_visual(is_selected: bool) -> bool:
	if is_selected or is_splitting:
		return true
	return _get_cached_camera_zoom_value() >= 0.18

func _process(_delta):
	if is_dying:
		return
	var scheduler_delta = _delta / max(Engine.time_scale, 0.001)

	if is_being_digested:
		_clear_worm_body_visual()
		# Во время переваривания обновляем только рамку выделения
		if is_instance_valid(selection_ring):
			var ui = _get_ui_layer()
			selection_ring.visible = (ui and ui.selected_cell == self)
			if is_instance_valid(perception_ring):
				perception_ring.visible = false
		# FIX: Проверяем смерть жертвы при достижении 0 энергии
		if energy <= 0.0:
			die(true)
			return
		# FIX: Проверяем что хищник ещё жив (защита от "осиротевшей" жертвы)
		if digesting_predator != null and !is_instance_valid(digesting_predator):
			# Хищник исчез — сбрасываем состояние переваривания
			is_being_digested = false
			digesting_predator = null
		return

	var ui = _get_ui_layer()
	var is_selected = (ui and ui.selected_cell == self)
	var visual_interval = _get_visual_update_interval(is_selected)
	# Показываем жгутик когда flagella_power > 0.35
	if genes.get("flagella_power", 0.0) > FLAGELLA_ACTIVATION_THRESHOLD:
		if _should_update_worm_visual(is_selected):
			if is_instance_valid(worm_body_visual):
				worm_body_visual.visible = true
			worm_visual_update_timer -= scheduler_delta
			if worm_visual_update_timer <= 0.0:
				worm_visual_update_timer = visual_interval + randf() * visual_interval * 0.25
				_update_worm_body_visual(_delta)
		elif is_instance_valid(worm_body_visual):
			worm_body_visual.visible = false
	elif is_instance_valid(worm_body_visual):
		_clear_worm_body_visual()

	if lysis_attack_flash_timer > 0.0:
		lysis_attack_flash_timer = max(lysis_attack_flash_timer - scheduler_delta, 0.0)
		queue_redraw()
	if lysis_hit_flash_timer > 0.0:
		lysis_hit_flash_timer = max(lysis_hit_flash_timer - scheduler_delta, 0.0)
		if body_visual and body_visual.material:
			var flash_progress = lysis_hit_flash_timer / LYSIS_ATTACK_FLASH_DURATION
			body_visual.material.set_shader_parameter("damage_flash", min(0.55, 0.22 + lysis_hit_flash_strength * 0.16) * flash_progress)
		queue_redraw()
	elif body_visual and body_visual.material:
		body_visual.material.set_shader_parameter("damage_flash", 0.0)
	if lysis_attack_stretch_timer > 0.0:
		lysis_attack_stretch_timer = max(lysis_attack_stretch_timer - scheduler_delta, 0.0)

	visual_update_timer -= scheduler_delta
	if visual_update_timer <= 0.0 and body_visual and body_visual.material and !is_splitting:
		visual_update_timer = visual_interval + randf() * visual_interval * 0.18
		var speed_ratio = clamp(linear_velocity.length() / max(_get_effective_speed(), 1.0), 0.0, 1.0)
		var local_dir = linear_velocity.normalized().rotated(-global_rotation) if linear_velocity.length() > 1.0 else Vector2.RIGHT
		var attack_deform = 0.0
		if lysis_attack_stretch_timer > 0.0:
			attack_deform = sin((lysis_attack_stretch_timer / 0.22) * PI) * 1.05
			local_dir = lysis_attack_stretch_direction
		var mat = body_visual.material
		var energy_ratio = clamp(energy / _get_max_energy(), 0.0, 1.0)
		mat.set_shader_parameter("energy_ratio", energy_ratio)
		mat.set_shader_parameter("motion_deform", max(speed_ratio, attack_deform))
		mat.set_shader_parameter("motion_direction", local_dir)
		if USE_POINT_LIGHTS and core_light:
			core_light.energy = 0.35 + genes.bioluminescence * 0.9 + energy_ratio * 0.25

	if is_instance_valid(selection_ring):
		selection_ring.visible = is_selected
		if is_instance_valid(perception_ring):
			perception_ring.visible = is_selected

		# Запрос перерисовки нужен каждый кадр только выбранной клетке: у нее двигается линия цели.
		if is_selected:
			queue_redraw()

func _draw():
	var ui = _get_ui_layer()
	var is_selected = (ui and ui.selected_cell == self)
	var is_species_highlighted = (ui and ui.get("selected_species_id") == species_id)
	var is_related_highlighted = (ui and ui.has_method("is_species_related_to_selection") and ui.is_species_related_to_selection(species_id))
	_draw_lysis_flash()

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
	elif is_related_highlighted:
		var camera = get_viewport().get_camera_2d()
		var zoom_value = camera.zoom.x if camera else 1.0
		var zoom_factor = clamp(inverse_lerp(0.02, 8.0, zoom_value), 0.0, 1.0)
		var relation_color = Color(0.65, 1.0, 0.86, lerp(0.62, 0.20, zoom_factor))
		draw_arc(Vector2.ZERO, 35.0 * _get_visual_size_scale(), 0.0, TAU, 42, relation_color, 2.0, true)

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

func _draw_lysis_flash():
	if lysis_hit_flash_timer > 0.0:
		var progress = 1.0 - lysis_hit_flash_timer / LYSIS_ATTACK_FLASH_DURATION
		for droplet in lysis_cytoplasm_droplets:
			var start = droplet.get("start", Vector2.ZERO)
			var drift = droplet.get("drift", Vector2.ZERO)
			var wobble = Vector2.UP.rotated(droplet.get("phase", 0.0)) * sin(progress * PI) * 2.0
			var pos = start + drift * progress + wobble
			var droplet_alpha = pow(1.0 - progress, 1.9) * 0.50
			var droplet_color = droplet.get("color", _get_visual_base_color())
			droplet_color.a = droplet_alpha
			draw_circle(pos, droplet.get("radius", 2.0) * lerp(1.0, 0.45, progress), droplet_color)

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
