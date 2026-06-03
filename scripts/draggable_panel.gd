extends PanelContainer
class_name DraggablePanel

## Панель, которую можно перетаскивать мышью
## Сохраняет позицию между сессиями

@export var save_key: String = ""  # Уникальный ключ для сохранения позиции
@export var drag_handle_height: float = 24.0  # Высота зоны для захвата

var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _initial_position: Vector2 = Vector2.ZERO

func _ready():
	mouse_enter.connect(_on_mouse_enter)
	mouse_exit.connect(_on_mouse_exit)
	gui_input.connect(_on_gui_input)
	
	# Загружаем сохранённую позицию
	if save_key != "":
		_load_position()

func _on_mouse_enter():
	# Меняем курсор на grab при наведении
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _on_mouse_exit():
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Начинаем перетаскивание
				_is_dragging = true
				_drag_offset = get_global_mouse_position() - global_position
				_initial_position = global_position
				Input.set_default_cursor_shape(Input.CURSOR_MOVE)
			else:
				# Завершаем перетаскивание
				if _is_dragging:
					_is_dragging = false
					Input.set_default_cursor_shape(Input.CURSOR_ARROW)
					# Сохраняем позицию при отпускании
					if save_key != "":
						_save_position()
	
	elif event is InputEventMouseMotion and _is_dragging:
		# Перемещаем панель
		global_position = get_global_mouse_position() - _drag_offset

func _save_position():
	# Сохраняем позицию в ProjectSettings
	var key = "ui/panels/" + save_key
	ProjectSettings.set_setting(key + "/x", global_position.x)
	ProjectSettings.set_setting(key + "/y", global_position.y)
	ProjectSettings.set_setting(key + "/visible", visible)
	ProjectSettings.save()

func _load_position():
	var key = "ui/panels/" + save_key
	if ProjectSettings.has_setting(key + "/x"):
		var x = ProjectSettings.get_setting(key + "/x")
		var y = ProjectSettings.get_setting(key + "/y")
		global_position = Vector2(x, y)
		
		# Восстанавливаем видимость
		if ProjectSettings.has_setting(key + "/visible"):
			visible = ProjectSettings.get_setting(key + "/visible", true)

func show_panel():
	visible = true
	if save_key != "":
		_save_position()

func hide_panel():
	visible = false
	if save_key != "":
		_save_position()