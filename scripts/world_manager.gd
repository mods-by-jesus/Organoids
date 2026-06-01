extends Node

@export var food_scene: PackedScene = preload("res://scenes/food.tscn")
@export var cell_scene: PackedScene = preload("res://scenes/cell.tscn")

@export var max_food = 50
@export var initial_cells = 8
@export var food_spawn_margin = 80.0
@export var cell_spawn_margin = 120.0
@export var spatial_cell_size = 384.0

@onready var arena = get_parent()

var food_timer = 0.0
var food_spawn_delay = 0.2 
var next_species_id = 1
var food_count = 0
var all_cells = []
var cell_buckets = {}
var food_buckets = {}
var object_buckets = {}
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
		max_food = int(max_food * area_factor)
		initial_cells = int(initial_cells * area_factor)
		
		# Делаем спавн чуть более разнесенным для больших арен
		food_spawn_margin = 80.0 * clamp(size_ratio, 1.0, 3.0)
		cell_spawn_margin = 120.0 * clamp(size_ratio, 1.0, 3.0)
		
	_spawn_initial_population()

func _process(delta):
	food_timer += delta
	if food_timer >= food_spawn_delay:
		food_timer = 0.0
		if food_count < max_food:
			spawn_food()
	
func _spawn_initial_population():
	for i in range(initial_cells):
		spawn_cell()

func spawn_food():
	var food = food_scene.instantiate()
	food.position = _random_position_inside_arena(food_spawn_margin)
	get_parent().call_deferred("add_child", food)

func spawn_cell():
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
	if randf() < 0.75:
		cell.genes.aggressiveness = randf_range(0.0, 0.38)
		cell.genes.phagocytosis = randf_range(0.0, 0.22)
	else:
		cell.genes.aggressiveness = randf_range(0.55, 0.78)
		cell.genes.phagocytosis = randf_range(0.18, 0.58)
	
	cell.genes.shape_elongation = randf_range(0.0, 1.0)
	cell.genes.shape_spikiness = randf_range(0.0, 1.0)
	cell.genes.shape_amoeboid = randf_range(0.0, 1.0)
	cell.genes.fear = 0.0
	
	get_parent().call_deferred("add_child", cell)

func issue_species_id() -> int:
	var id = next_species_id
	next_species_id += 1
	return id

func make_species_name() -> String:
	return "%s %s" % [species_names.pick_random(), species_adjectives.pick_random()]

func register_food():
	food_count += 1
	_register_spatial(food_buckets, null)

func unregister_food():
	food_count = max(food_count - 1, 0)

func register_food_node(food: Node2D):
	food_count += 1
	_register_spatial(food_buckets, food)

func unregister_food_node(food: Node2D):
	food_count = max(food_count - 1, 0)
	_unregister_spatial(food_buckets, food)

func update_food_spatial(food: Node2D):
	_update_spatial(food_buckets, food)

func register_cell(cell: Node2D):
	if !all_cells.has(cell):
		all_cells.append(cell)
	_register_spatial(cell_buckets, cell)

func unregister_cell(cell: Node2D):
	all_cells.erase(cell)
	_unregister_spatial(cell_buckets, cell)

func update_cell_spatial(cell: Node2D):
	_update_spatial(cell_buckets, cell)

func get_food_near(position: Vector2, radius: float) -> Array:
	return _query_spatial(food_buckets, position, radius)

func get_cells_near(position: Vector2, radius: float) -> Array:
	return _query_spatial(cell_buckets, position, radius)

func get_all_cells() -> Array:
	return all_cells

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
			if !buckets.has(key):
				continue
			for object in buckets[key]:
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
