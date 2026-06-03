extends Node

@export var food_scene: PackedScene = preload("res://scenes/food.tscn")
@export var cell_scene: PackedScene = preload("res://scenes/cell.tscn")
@export var obstacle_scene: PackedScene = preload("res://scenes/drift_obstacle.tscn")
@export var food_grower_scene: PackedScene = preload("res://scenes/food_grower.tscn")

@export var initial_cells = 8
@export var initial_obstacles = 6
@export var initial_food_growers = 2
@export var initial_worm_fraction = 0.08
@export var food_spawn_margin = 80.0
@export var cell_spawn_margin = 120.0
@export var obstacle_spawn_margin = 180.0
@export var food_grower_spawn_margin = 240.0
@export var spatial_cell_size = 384.0
@export var max_dead_species_history = 128
@export var ai_updates_per_physics_frame = 32
@export var max_ai_updates_per_physics_frame = 96
@export var max_food_updates_per_frame = 320

@onready var arena = get_parent()

var food_timer = 0.0
var food_spawn_delay = 0.2 
var next_species_id = 1
var food_count = 0
var food_pool: Array[Node2D] = []
var active_food_nodes: Array[Node2D] = []
var active_food_indices = {}
var food_update_cursor := 0
var all_cells = []
var all_cell_indices = {}
var species_cells = {}
var population_version = 0
var species_stats = {}
var dead_species_stats = {}
var dead_species_order: Array[int] = []
var cell_buckets = {}
var food_buckets = {}
var obstacle_buckets = {}
var object_buckets = {}
var species_stats_version := 0
var dead_species_stats_version := 0
var species_stats_cache := {}
var species_stats_cache_version := -1
var dead_species_stats_cache := {}
var dead_species_stats_cache_version := -1
var relation_cache_version := ""
var relation_all_species_cache := {}
var relation_children_cache := {}
var related_species_cache := {}
var ai_update_queue: Array[Node2D] = []
var ai_queued_cell_ids = {}
var ai_queue_cursor := 0
var cached_camera_position := Vector2.ZERO
var cached_camera_zoom := 1.0
var species_names = [
	"Цита", "Плазма", "Нуклея", "Мембрана", "Гранул", "Лизос", "Рибос", "Митос", "Пероксис", "Эндос", "Экзос", "Фагос", "Пинос", "Рецепторис", "Сигналис", "Протеас", "Хромата", "Генум", "ДНКа", "РНКа", "АТФаза", "Ферментис", "Каталис", "Синтетис", "Делис", "Митозис", "Мейозис", "Дифференцис", "Стволис", "Сома", "Герма", "Бласта", "Морула", "Трофобласта", "Эмбрион", "Апопта", "Некра", "Вита", "Морта", "Спора", "Циста", "Колон", "Агрегат", "Солитум", "Флоатис", "Седентис", "Мобилис", "Фиксум", "Либер", "Адхез", "Дискус", "Сфера", "Эллипсис", "Овалис", "Полигон", "Звездис", "Кристаллис", "Аморф", "Структум", "Органум", "Система", "Компарта", "Камера", "Локулис", "Лакуна", "Синус", "Каналис", "Трубкулум", "Фибрис", "Нитя", "Септа", "Пора", "Морулис", "Папилла", "Криптис", "Фолликулис", "Ацинис", "Гломерулис", "Тубулис", "Медулла", "Кортексис", "Лимбиум", "Маргинис", "Центриум", "Перифериум", "Базалис", "Апикалис", "Латералис", "Медианум", "Полярис", "Экваториум", "Орбис", "Глобус", "Терра"
]
var species_adjectives = [
	"ротундус", "оватус", "планус", "элонгатус", "бревис", "лонгус", "крассус", "тенуис", "моллис", "дурус", "ликвид", "денсус", "лакунозус", "левис", "грумозус", "гиалинус", "нептунус", "луцидус", "фускус", "альбус", "кандиканс", "цинереус", "рубенс", "флавус", "вириденс", "каркулеус", "пупурпуреус", "ауранциакус", "бруннеус", "хомогенус", "хетерогенус", "гранулатус", "ретикулатус", "порозус", "фиброзус", "ламинатус", "кавус", "солидус", "парвус", "магнус", "минутус", "инимкус", "нанус", "медиус", "дискретус", "континуус", "компактус", "рамификус", "симплекс", "ректус", "курвус", "ундалатус", "спиралис", "петельнус", "нодозус", "сегментатус", "интегра", "фрактус", "парибус", "солитариус", "мультиплекс", "аггрегатус", "диффузус", "ординатус", "анархикус", "симметрикус", "асимметрикус", "регулярис", "иррегулярис", "стабилис", "мутабилис", "констанс", "темпералис", "активис", "пассивис", "целерис", "тардус", "мобилис", "стенатус", "натанс", "фиксатус", "либертус", "интернус", "экстернус", "суперфициалис", "продундус", "централис", "периферикус", "супериор", "инфериор", "ляевус", "декстер", "антериор", "постериор", "лонгитудиналис", "трансверсалис", "радиалис", "тангенциалис", "апикус", "базилис"
]

func _ready():
	# Динамически адаптируем количество еды и клеток под размер арены
	if arena and arena.get("arena_size") != null:
		var size_ratio = arena.arena_size / 2048.0
		var area_factor = size_ratio * size_ratio
		
		# Масштабируем лимиты
		initial_cells = int(initial_cells * area_factor)
		initial_obstacles = int(initial_obstacles * size_ratio * 1.1)
		initial_food_growers = max(2, int(initial_food_growers * size_ratio * 0.75))
		
		# Делаем спавн чуть более разнесенным для больших арен
		food_spawn_margin = 80.0 * clamp(size_ratio, 1.0, 3.0)
		cell_spawn_margin = 120.0 * clamp(size_ratio, 1.0, 3.0)
		obstacle_spawn_margin = 180.0 * clamp(size_ratio, 1.0, 3.0)
		food_grower_spawn_margin = 240.0 * clamp(size_ratio, 1.0, 3.0)
		
	_spawn_initial_population()
	_spawn_initial_obstacles()
	_spawn_initial_food_growers()

func _process(delta):
	_update_camera_cache()
	food_timer += delta
	if food_timer >= food_spawn_delay:
		food_timer = 0.0
		spawn_food()
	_process_food_nodes(delta)

func _update_camera_cache():
	var camera = get_viewport().get_camera_2d()
	if camera:
		cached_camera_position = camera.global_position
		cached_camera_zoom = camera.zoom.x

func get_cached_camera_zoom() -> float:
	return cached_camera_zoom

func get_cached_camera_position() -> Vector2:
	return cached_camera_position

func _physics_process(_delta):
	_process_cell_ai_queue()

func request_cell_ai_update(cell: Node2D) -> bool:
	if !is_instance_valid(cell):
		return false
	var cell_id = cell.get_instance_id()
	if ai_queued_cell_ids.has(cell_id):
		return true
	ai_queued_cell_ids[cell_id] = true
	ai_update_queue.append(cell)
	return true

func _process_cell_ai_queue():
	var processed = 0
	var update_budget = min(max_ai_updates_per_physics_frame, max(ai_updates_per_physics_frame, int(ceil(float(all_cells.size()) / 20.0))))
	while processed < update_budget and ai_queue_cursor < ai_update_queue.size():
		var cell = ai_update_queue[ai_queue_cursor]
		ai_queue_cursor += 1
		if !is_instance_valid(cell):
			continue
		ai_queued_cell_ids.erase(cell.get_instance_id())
		if cell.get("is_dying") or cell.get("pending_death") or cell.get("is_being_digested"):
			continue
		if cell.has_method("_run_scheduled_vision_update"):
			cell._run_scheduled_vision_update()
			processed += 1
	if ai_queue_cursor > 0 and (ai_queue_cursor >= ai_update_queue.size() or ai_queue_cursor > 256):
		ai_update_queue = ai_update_queue.slice(ai_queue_cursor)
		ai_queue_cursor = 0
	
func _spawn_initial_population():
	var guaranteed_worms = max(1, int(round(initial_cells * initial_worm_fraction)))
	for i in range(initial_cells):
		spawn_cell(i < guaranteed_worms)

func _spawn_initial_obstacles():
	for i in range(initial_obstacles):
		spawn_obstacle()

func _spawn_initial_food_growers():
	spawn_food_grower(true)
	for i in range(max(initial_food_growers - 1, 0)):
		spawn_food_grower(false)

func spawn_food():
	spawn_food_at(_random_position_inside_arena(food_spawn_margin))

func spawn_food_at(position: Vector2, is_cell_remains: bool = false, energy_value: float = 50.0, source_species_id: int = 0) -> Node2D:
	var food = _take_food_from_pool()
	food.is_cell_remains = is_cell_remains
	food.source_species_id = source_species_id
	food.energy_value = energy_value
	food.global_position = position
	if food.is_inside_tree():
		if food.has_method("reactivate_from_pool"):
			food.reactivate_from_pool(position, is_cell_remains, energy_value, source_species_id)
	else:
		get_parent().add_child(food)
	return food

func _take_food_from_pool() -> Node2D:
	while !food_pool.is_empty():
		var food = food_pool.pop_back()
		if is_instance_valid(food):
			return food
	return food_scene.instantiate()

func recycle_food_node(food: Node2D):
	if !is_instance_valid(food):
		return
	if food.has_method("recycle_to_pool"):
		food.recycle_to_pool()
		food_pool.append(food)
	else:
		food.queue_free()

func spawn_obstacle():
	var obstacle = obstacle_scene.instantiate()
	obstacle.position = _random_position_inside_arena(obstacle_spawn_margin)
	get_parent().call_deferred("add_child", obstacle)

func spawn_food_grower(make_giant: bool = false):
	var grower = food_grower_scene.instantiate()
	grower.is_giant = make_giant
	grower.position = _random_position_inside_arena(food_grower_spawn_margin if make_giant else obstacle_spawn_margin)
	get_parent().call_deferred("add_child", grower)

func spawn_cell(force_worm: bool = false):
	var cell = cell_scene.instantiate()
	cell.position = _random_position_inside_arena(cell_spawn_margin)
	cell.species_id = issue_species_id()
	cell.species_name = make_species_name()
	
	cell.genes.speed = randf_range(100, 166)
	cell.genes.turn_speed = randf_range(10, 20)
	cell.genes.vision_range = randf_range(300, 500)
	cell.genes.size = randf_range(0.7, 1.45)
	cell.genes.mutation_rate = randf_range(0.06, 0.16)
	cell.genes.membrane_roughness = randf_range(0.08, 0.55)
	cell.genes.membrane_asymmetry = randf_range(0.0, 0.26)
	cell.genes.nucleus_size = randf_range(0.22, 0.42)
	cell.genes.bioluminescence = randf_range(0.0, 0.35)
	var spawned_predator_profile = false
	if randf() < 0.75:
		cell.genes.aggressiveness = randf_range(0.0, 0.38)
		cell.genes.phagocytosis = randf_range(0.0, 0.22)
		cell.genes.enzyme_secretion = randf_range(0.0, 0.16)
	else:
		spawned_predator_profile = true
		cell.genes.aggressiveness = randf_range(0.55, 0.78)
		cell.genes.phagocytosis = randf_range(0.18, 0.58)
		cell.genes.enzyme_secretion = randf_range(0.18, 0.62)
	if spawned_predator_profile and cell.genes.phagocytosis < 0.35 and cell.genes.enzyme_secretion < 0.35:
		if randf() < 0.5:
			cell.genes.phagocytosis = randf_range(0.36, 0.62)
		else:
			cell.genes.enzyme_secretion = randf_range(0.36, 0.68)
	cell.genes.membrane_resistance = randf_range(0.10, 0.46)
	cell.genes.chemotaxis = randf_range(0.0, 0.45)
	cell.genes.flagella_power = randf_range(0.0, 0.25)
	
	cell.genes.shape_elongation = randf_range(0.0, 1.0)
	cell.genes.shape_spikiness = randf_range(0.0, 1.0)
	cell.genes.shape_amoeboid = randf_range(0.0, 1.0)
	cell.genes.shape_tendrils = randf_range(0.0, 1.0) if randf() < 0.34 else randf_range(0.0, 0.22)
	cell.genes.shape_lobes = randf_range(0.0, 1.0) if randf() < 0.42 else randf_range(0.0, 0.25)
	cell.genes.shape_boxy = randf_range(0.0, 1.0) if randf() < 0.16 else randf_range(0.0, 0.12)
	cell.genes.shape_worm = randf_range(0.62, 1.0) if force_worm or randf() < 0.08 else randf_range(0.0, 0.10)
	if cell.genes.shape_worm > 0.48:
		cell.genes.flagella_power = randf_range(0.35, 0.85)
	cell.genes.shape_spiral = randf_range(0.50, 1.0) if randf() < (0.18 if force_worm else 0.08) else randf_range(0.0, 0.12)
	cell.genes.fear = 0.0
	
	get_parent().call_deferred("add_child", cell)

func issue_species_id() -> int:
	var id = next_species_id
	next_species_id += 1
	return id

func make_species_name() -> String:
	return "%s %s" % [species_names.pick_random(), species_adjectives.pick_random()]

func make_related_species_name(base_name: String) -> String:
	var parts = base_name.split(" ", false)
	var noun = parts[0] if parts.size() > 0 else species_names.pick_random()
	var adjective = species_adjectives.pick_random()
	if parts.size() > 1 and species_adjectives.size() > 1:
		var old_adjective = parts[parts.size() - 1]
		var guard = 0
		while adjective == old_adjective and guard < 8:
			adjective = species_adjectives.pick_random()
			guard += 1
	return "%s %s" % [noun, adjective]

func register_food():
	food_count += 1

func unregister_food():
	food_count = max(food_count - 1, 0)

func register_food_node(food: Node2D):
	var food_id = food.get_instance_id()
	if !active_food_indices.has(food_id):
		food_count += 1
		active_food_indices[food_id] = active_food_nodes.size()
		active_food_nodes.append(food)
	_register_spatial(food_buckets, food)

func unregister_food_node(food: Node2D):
	var food_id = food.get_instance_id()
	if active_food_indices.has(food_id):
		food_count = max(food_count - 1, 0)
		var index = int(active_food_indices[food_id])
		var last_index = active_food_nodes.size() - 1
		if index >= 0 and index <= last_index:
			var last_food = active_food_nodes[last_index]
			active_food_nodes[index] = last_food
			if is_instance_valid(last_food):
				active_food_indices[last_food.get_instance_id()] = index
			active_food_nodes.pop_back()
		active_food_indices.erase(food_id)
		if food_update_cursor > active_food_nodes.size():
			food_update_cursor = 0
	_unregister_spatial(food_buckets, food)

func update_food_spatial(food: Node2D):
	_update_spatial(food_buckets, food)

func _process_food_nodes(delta: float):
	var food_total = active_food_nodes.size()
	if food_total <= 0:
		return
	var update_budget = min(food_total, max(max_food_updates_per_frame, 1))
	var scaled_delta = delta * float(food_total) / float(update_budget)
	var processed = 0
	while processed < update_budget and food_total > 0:
		if food_update_cursor >= active_food_nodes.size():
			food_update_cursor = 0
		var food = active_food_nodes[food_update_cursor]
		food_update_cursor += 1
		if !is_instance_valid(food):
			processed += 1
			continue
		if food.has_method("simulation_step"):
			food.simulation_step(scaled_delta)
		processed += 1

func register_obstacle(obstacle: Node2D):
	_register_spatial(obstacle_buckets, obstacle)

func unregister_obstacle(obstacle: Node2D):
	_unregister_spatial(obstacle_buckets, obstacle)

func update_obstacle_spatial(obstacle: Node2D):
	_update_spatial(obstacle_buckets, obstacle)

func register_cell(cell: Node2D):
	var cell_id = cell.get_instance_id()
	if !all_cell_indices.has(cell_id):
		all_cell_indices[cell_id] = all_cells.size()
		all_cells.append(cell)
		var species_id = int(cell.get("species_id"))
		if species_id > 0:
			if !species_cells.has(species_id):
				species_cells[species_id] = []
			species_cells[species_id].append(cell)
		population_version += 1
		_add_species_stats(cell)
	_register_spatial(cell_buckets, cell)

func unregister_cell(cell: Node2D):
	var cell_id = cell.get_instance_id()
	ai_queued_cell_ids.erase(cell_id)
	if all_cell_indices.has(cell_id):
		population_version += 1
		var index = int(all_cell_indices[cell_id])
		var last_index = all_cells.size() - 1
		if index >= 0 and index <= last_index:
			var last_cell = all_cells[last_index]
			all_cells[index] = last_cell
			all_cell_indices[last_cell.get_instance_id()] = index
			all_cells.pop_back()
		all_cell_indices.erase(cell_id)
		var species_id = int(cell.get("species_id"))
		if species_cells.has(species_id):
			species_cells[species_id].erase(cell)
			if species_cells[species_id].is_empty():
				species_cells.erase(species_id)
		_remove_species_stats(cell)
	_unregister_spatial(cell_buckets, cell)

func update_cell_spatial(cell: Node2D):
	_update_spatial(cell_buckets, cell)

func get_food_near(position: Vector2, radius: float) -> Array:
	return _query_spatial(food_buckets, position, radius)

func get_cells_near(position: Vector2, radius: float) -> Array:
	return _query_spatial(cell_buckets, position, radius)

func get_obstacles_near(position: Vector2, radius: float) -> Array:
	return _query_spatial(obstacle_buckets, position, radius)

func get_all_cells() -> Array:
	return all_cells

func get_cell_count() -> int:
	return all_cells.size()

func get_cells_for_species(species_id: int) -> Array:
	return species_cells.get(species_id, [])

func get_live_species_count() -> int:
	return species_stats.size()

func get_population_version() -> int:
	return population_version

func get_species_stats_version() -> int:
	return species_stats_version

func get_dead_species_stats_version() -> int:
	return dead_species_stats_version

func get_species_stats() -> Dictionary:
	if species_stats_cache_version != species_stats_version:
		species_stats_cache.clear()
		for id in species_stats.keys():
			species_stats_cache[id] = species_stats[id].duplicate(false)
		species_stats_cache_version = species_stats_version
	return species_stats_cache

func get_dead_species_stats() -> Dictionary:
	if dead_species_stats_cache_version != dead_species_stats_version:
		dead_species_stats_cache.clear()
		for id in dead_species_stats.keys():
			dead_species_stats_cache[id] = dead_species_stats[id].duplicate(false)
		dead_species_stats_cache_version = dead_species_stats_version
	return dead_species_stats_cache

func get_species_ledger_stats() -> Dictionary:
	return {
		"alive": get_species_stats(),
		"dead": get_dead_species_stats(),
		"alive_species_count": get_live_species_count(),
		"cell_count": get_cell_count()
	}

func get_related_species_ids(species_id: int) -> Array:
	_ensure_relation_cache()
	if species_id <= 0 or !relation_all_species_cache.has(species_id):
		return []
	if related_species_cache.has(species_id):
		return related_species_cache[species_id].duplicate(false)
	var related = []
	var frontier = [species_id]
	var frontier_index = 0
	var seen = {}
	seen[species_id] = true
	while frontier_index < frontier.size():
		var current_id = int(frontier[frontier_index])
		frontier_index += 1
		var current_parent = int(relation_all_species_cache[current_id].get("parent_id", 0)) if relation_all_species_cache.has(current_id) else 0
		if current_parent > 0 and !seen.has(current_parent) and relation_all_species_cache.has(current_parent):
			seen[current_parent] = true
			frontier.append(current_parent)
		for id in relation_children_cache.get(current_id, []):
			var candidate_id = int(id)
			if !seen.has(candidate_id):
				seen[candidate_id] = true
				frontier.append(candidate_id)
	for id in seen.keys():
		if int(id) != species_id:
			related.append(int(id))
	related.sort()
	related_species_cache[species_id] = related
	return related.duplicate(false)

func _ensure_relation_cache():
	var version = "%d:%d" % [species_stats_version, dead_species_stats_version]
	if relation_cache_version == version:
		return
	relation_all_species_cache.clear()
	relation_children_cache.clear()
	related_species_cache.clear()
	for id in dead_species_stats.keys():
		relation_all_species_cache[id] = dead_species_stats[id]
	for id in species_stats.keys():
		relation_all_species_cache[id] = species_stats[id]
	for id in relation_all_species_cache.keys():
		var parent_id = int(relation_all_species_cache[id].get("parent_id", 0))
		if parent_id <= 0:
			continue
		if !relation_children_cache.has(parent_id):
			relation_children_cache[parent_id] = []
		relation_children_cache[parent_id].append(int(id))
	relation_cache_version = version

func _add_species_stats(cell: Node2D):
	if !is_instance_valid(cell):
		return
	var id = int(cell.get("species_id"))
	if id <= 0:
		return
	if !species_stats.has(id):
		species_stats[id] = _make_empty_species_stats(cell)
	if dead_species_stats.has(id):
		dead_species_stats.erase(id)
		dead_species_order.erase(id)
		dead_species_stats_version += 1
	var stats = species_stats[id]
	stats["count"] += 1
	_accumulate_species_genes(stats, cell, 1.0)
	species_stats_version += 1

func _remove_species_stats(cell: Node2D):
	if !is_instance_valid(cell):
		return
	var id = int(cell.get("species_id"))
	if id <= 0 or !species_stats.has(id):
		return
	var stats = species_stats[id]
	var last_snapshot = _make_species_snapshot(cell)
	stats["count"] -= 1
	_accumulate_species_genes(stats, cell, -1.0)
	species_stats_version += 1
	if stats["count"] <= 0:
		last_snapshot["count"] = 0
		last_snapshot["alive"] = false
		dead_species_stats[id] = last_snapshot
		dead_species_order.erase(id)
		dead_species_order.append(id)
		_trim_dead_species_history()
		species_stats.erase(id)
		dead_species_stats_version += 1

func _make_empty_species_stats(cell: Node2D) -> Dictionary:
	var parent_id = 0
	if cell.get("species_origin_genes") != null and !cell.species_origin_genes.is_empty():
		parent_id = int(cell.get("species_id")) # default fallback or tracking logic

	var new_stats = {
		"count": 0,
		"color": cell.get("species_color"),
		"visual_color": cell._get_visual_base_color() if cell.has_method("_get_visual_base_color") else cell.get("species_color"),
		"name": cell.get("species_name"),
		"parent_id": cell.get("parent_species_id") if cell.get("parent_species_id") != null else 0,
		"speed": 0.0,
		"turn_speed": 0.0,
		"vision_range": 0.0,
		"size": 0.0,
		"mutation_rate": 0.0,
		"phagocytosis": 0.0,
		"enzyme_secretion": 0.0,
		"membrane_resistance": 0.0,
		"chemotaxis": 0.0,
		"flagella_power": 0.0,
		"fear": 0.0,
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
		"aggressiveness": 0.0
	}
	return new_stats

func _make_species_snapshot(cell: Node2D) -> Dictionary:
	var stats = _make_empty_species_stats(cell)
	stats["count"] = 1
	stats["alive"] = true
	_accumulate_species_genes(stats, cell, 1.0)
	return stats

func _trim_dead_species_history():
	while dead_species_order.size() > max_dead_species_history:
		var old_id = dead_species_order.pop_front()
		dead_species_stats.erase(old_id)
		dead_species_stats_version += 1

func _accumulate_species_genes(stats: Dictionary, cell: Node2D, sign: float):
	var cell_genes = cell.get("genes")
	if typeof(cell_genes) != TYPE_DICTIONARY:
		return
	stats["speed"] += cell_genes.get("speed", 0.0) * sign
	stats["turn_speed"] += cell_genes.get("turn_speed", 0.0) * sign
	stats["vision_range"] += cell_genes.get("vision_range", 0.0) * sign
	stats["size"] += cell_genes.get("size", 0.0) * sign
	stats["mutation_rate"] += cell_genes.get("mutation_rate", 0.0) * sign
	stats["phagocytosis"] += cell_genes.get("phagocytosis", 0.0) * sign
	stats["enzyme_secretion"] += cell_genes.get("enzyme_secretion", 0.0) * sign
	stats["membrane_resistance"] += cell_genes.get("membrane_resistance", 0.2) * sign
	stats["chemotaxis"] += cell_genes.get("chemotaxis", 0.0) * sign
	stats["flagella_power"] += cell_genes.get("flagella_power", 0.0) * sign
	stats["fear"] += cell_genes.get("fear", 0.0) * sign
	stats["elongation"] += cell_genes.get("shape_elongation", 0.0) * sign
	stats["spikiness"] += cell_genes.get("shape_spikiness", 0.0) * sign
	stats["amoeboid"] += cell_genes.get("shape_amoeboid", 0.0) * sign
	stats["tendrils"] += cell_genes.get("shape_tendrils", 0.0) * sign
	stats["lobes"] += cell_genes.get("shape_lobes", 0.0) * sign
	stats["boxy"] += cell_genes.get("shape_boxy", 0.0) * sign
	stats["worm"] += cell_genes.get("shape_worm", 0.0) * sign
	stats["spiral"] += cell_genes.get("shape_spiral", 0.0) * sign
	stats["roughness"] += cell_genes.get("membrane_roughness", 0.25) * sign
	stats["asymmetry"] += cell_genes.get("membrane_asymmetry", 0.12) * sign
	stats["nucleus_size"] += cell_genes.get("nucleus_size", 0.3) * sign
	stats["bioluminescence"] += cell_genes.get("bioluminescence", 0.0) * sign
	stats["aggressiveness"] += cell_genes.get("aggressiveness", 0.0) * sign
	if sign > 0.0 and cell.has_method("_get_visual_base_color"):
		stats["visual_color"] = cell._get_visual_base_color()

func _register_spatial(buckets: Dictionary, object: Node2D):
	if !is_instance_valid(object):
		return
	var key = _bucket_key(object.global_position)
	if !buckets.has(key):
		buckets[key] = []
	buckets[key].append(object)
	object_buckets[object.get_instance_id()] = key

func _unregister_spatial(buckets: Dictionary, object: Node2D):
	if !is_instance_valid(object):
		return
	var object_id = object.get_instance_id()
	if !object_buckets.has(object_id):
		return
	var key = object_buckets[object_id]
	object_buckets.erase(object_id)
	if buckets.has(key):
		buckets[key].erase(object)
		if buckets[key].is_empty():
			buckets.erase(key)

func _update_spatial(buckets: Dictionary, object: Node2D):
	if !is_instance_valid(object):
		return
	var object_id = object.get_instance_id()
	var next_key = _bucket_key(object.global_position)
	var prev_key = object_buckets.get(object_id, null)
	if prev_key == next_key:
		return
	if prev_key != null and buckets.has(prev_key):
		buckets[prev_key].erase(object)
		if buckets[prev_key].is_empty():
			buckets.erase(prev_key)
	if !buckets.has(next_key):
		buckets[next_key] = []
	buckets[next_key].append(object)
	object_buckets[object_id] = next_key

func _query_spatial(buckets: Dictionary, position: Vector2, radius: float) -> Array:
	var result = []
	var min_key = _bucket_key(position - Vector2.ONE * radius)
	var max_key = _bucket_key(position + Vector2.ONE * radius)
	for x in range(min_key.x, max_key.x + 1):
		for y in range(min_key.y, max_key.y + 1):
			var key = Vector2i(x, y)
			var bucket = buckets.get(key, null)
			if bucket == null:
				continue
			for object in bucket:
				if is_instance_valid(object):
					result.append(object)
	return result

func _bucket_key(position: Vector2) -> Vector2i:
	return Vector2i(floori(position.x / spatial_cell_size), floori(position.y / spatial_cell_size))

func _random_position_inside_arena(margin: float) -> Vector2:
	var safe_margin = margin
	var border_thickness = arena.get("border_thickness")
	if border_thickness != null:
		safe_margin += border_thickness
	var half = max(arena.get("arena_size") / 2.0 - safe_margin, 0.0)
	return Vector2(randf_range(-half, half), randf_range(-half, half))
