class_name Chunk
extends Node2D

const _Water = preload("res://scenes/tiles/Water.tscn")
const _Sand = preload("res://scenes/tiles/Sand.tscn")
const _Grass = preload("res://scenes/tiles/Grass.tscn")

var chunk_size: float = 32.0
var noise: OpenSimplexNoise = null

var chunk_x: int = 0
var chunk_y: int = 0

var should_remove := false


##
# Initializes the whole 2d chunk and
# spawns grass/water tiles based on noise value
##
func _ready() -> void:
	for x in range(chunk_x, chunk_x + chunk_size):
		for y in range(chunk_y, chunk_y + chunk_size):
			var value = noise.get_noise_2d(x, y)
			if value > 0.39:
				var new_grass = _Grass.instance()
				new_grass.position = Vector2(x * 16, y * 16)
				add_child(new_grass)
			elif value > 0.33:
				var new_sand = _Sand.instance()
				new_sand.position = Vector2(x * 16, y * 16)
				add_child(new_sand)

			### little heavy on performance, should probably use tilemaps instead to display more sprites at once
			# else:
			# 	var new_water = _Water.instance()
			# 	new_water.position = Vector2(x * 16, y * 16)
			# 	add_child(new_water)
