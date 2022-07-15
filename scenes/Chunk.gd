extends Node2D

const _Water = preload("res://scenes/tiles/Water.tscn")
const _Grass = preload("res://scenes/tiles/Grass.tscn")

var chunk_size := 32.0
var noise = null

var chunk_x = 0
var chunk_y = 0

var should_remove := false

var water_tiles := []

var size_rect: Rect2
var grid = []


##
# Initializes the whole 2d chunk and
# spawns grass/water tiles based on noise value
##
func _ready():
	size_rect = Rect2(
		Vector2(chunk_x * 16, (chunk_y - chunk_size / 2) * 16),
		Vector2(chunk_size * 16, chunk_size * 16)
	)

	for x in range(chunk_x, chunk_x + chunk_size):
		for y in range(chunk_y, chunk_y + chunk_size):
			var value = noise.get_noise_2d(x, y)
			if value > 0.39:
				var new_grass = _Grass.instance()
				new_grass.position = Vector2(x * 16, y * 16)
				add_child(new_grass)
			elif value > 0.33:
				var new_sand = _Grass.instance()  # TODO: Make Sand
				new_sand.position = Vector2(x * 16, y * 16)
				add_child(new_sand)
			else:
				var new_water = _Water.instance()
				new_water.position = Vector2(x * 16, y * 16)
				add_child(new_water)
				water_tiles.append(new_water)
