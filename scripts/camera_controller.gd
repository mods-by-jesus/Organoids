extends Node3D

@export var speed: float = 20.0
@export var zoom_speed: float = 2.0

func _process(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		global_translate(direction * speed * delta)
	
	if Input.is_action_pressed("zoom_in"):
		global_translate(Vector3(0, -zoom_speed * 10.0 * delta, 0))
	if Input.is_action_pressed("zoom_out"):
		global_translate(Vector3(0, zoom_speed * 10.0 * delta, 0))
