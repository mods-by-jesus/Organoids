extends Node

func generate_sphere_normal_map(size: int = 256) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var radius = size / 2.0
	
	for y in range(size):
		for x in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			
			if dist <= radius:
				# Вычисляем Z-координату для полусферы
				var z = sqrt(radius * radius - dist * dist)
				# Нормализуем вектор (x, y, z)
				var normal = Vector3(pos.x - center.x, pos.y - center.y, z).normalized()
				
				# Преобразуем нормаль [-1, 1] в цвет [0, 1]
				# Godot ожидает нормали в формате (R=X, G=Y, B=Z)
				var r = (normal.x + 1.0) / 2.0
				var g = (normal.y + 1.0) / 2.0
				var b = (normal.z + 1.0) / 2.0
				
				# Сглаживание края
				var alpha = smoothstep(radius, radius - 2.0, dist)
				image.set_pixel(x, y, Color(r, g, b, alpha))
			else:
				# Плоская нормаль для фона (смотрит прямо на нас)
				image.set_pixel(x, y, Color(0.5, 0.5, 1.0, 0.0))
				
	return ImageTexture.create_from_image(image)

func generate_cell_diffuse(size: int = 256) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var radius = size / 2.0
	
	for y in range(size):
		for x in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			
			if dist <= radius:
				var alpha = smoothstep(radius, radius - 2.0, dist)
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
			else:
				image.set_pixel(x, y, Color(1, 1, 1, 0))
				
	return ImageTexture.create_from_image(image)
