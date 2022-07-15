extends Node

const _Chunk = preload("res://scenes/Chunk.tscn")
onready var noise = OpenSimplexNoise.new()

var player_pos
var last_player_pos = Vector2.ZERO

var chunk_size := 16.0

var chunks := {}
var unready_chunks = {}
var chunk_radius = 2

var spawn_thread
var kill_thread
var update_timer


##
# World.gd is a global script that loads/unloads chunks of tiles
# depending on the player's position
##
func _ready():
	spawn_thread = Thread.new()
	kill_thread = Thread.new()

	# noise generation
	randomize()
	noise.seed = randi()
	noise.period = 32.0
	noise.octaves = 3.0
	noise.persistence = 0.8

	# connect to player_move event
	Events.connect("player_move", self, "on_player_move")

	# update update_timer
	update_timer = Timer.new()
	update_timer.connect("timeout", self, "_on_update_timer_timeout")
	update_timer.set_wait_time(0.125)
	add_child(update_timer)
	update_timer.start()


##
# add a chunk at pos(x, y)
##
func add_chunk(x, y):
	var key = str(x) + "," + str(y)

	# return if chunk exists
	if chunks.has(key) or unready_chunks.has(key):
		return

	# start loading a new chunk if a spawn_thread is available
	if not spawn_thread.is_active():
		spawn_thread.start(self, "load_chunk", [spawn_thread, x, y])
		unready_chunks[key] = 1


# load a new chunk in a spawn_thread
func load_chunk(arr):
	var _thread = arr[0]
	var x = arr[1]
	var y = arr[2]

	var new_chunk = create_chunk(x, y)

	call_deferred("load_done", x, y, new_chunk, _thread)


func load_done(x, y, chunk, _thread):
	var key = str(x) + "," + str(y)
	add_child(chunk)
	chunks[key] = chunk
	unready_chunks.erase(key)
	_thread.wait_to_finish()


# update player pos internal variable
func on_player_move(_position):
	player_pos = _position


# can also be in update -> watch for performance
func _on_update_timer_timeout():
	set_all_chunks_to_remove()
	determine_chunks_to_keep()
	clean_up_chunks()


func determine_chunks_to_keep():
	if not player_pos:
		return
	var p_x = floor(player_pos.x / 16 / chunk_size)
	var p_y = floor(player_pos.y / 16 / chunk_size)

	for x in range(p_x - chunk_radius, p_x + chunk_radius + 1):
		for y in range(p_y - chunk_radius, p_y + chunk_radius + 1):
			add_chunk(x * chunk_size, y * chunk_size)
			var chunk = get_chunk(x * 16, y * 16)
			if chunk != null:
				chunk.should_remove = false


# Look for a chunk to remove and start a kill_thread to free it
func clean_up_chunks():
	for key in chunks:
		var chunk = chunks[key]
		if chunk.should_remove:
			if not kill_thread.is_active():
				chunk.visible = false
				kill_thread.start(self, "free_chunk", [chunk, key, kill_thread])


# free chunk inside a thread
func free_chunk(args):
	var _chunk = args[0]
	var _key = args[1]
	var _thread = args[2]

	chunks.erase(_key)
	_chunk.queue_free()

	call_deferred("on_free_chunk", _chunk, _key, _thread)


# thread wait to finish function -> if some work needs to happen after chunk deletion
func on_free_chunk(_chunk, _key, _thread):
	_thread.wait_to_finish()


# create chunk at x,y position
func create_chunk(x, y):
	var new_chunk = _Chunk.instance()
	new_chunk.noise = noise
	new_chunk.chunk_size = chunk_size
	new_chunk.chunk_x = x
	new_chunk.chunk_y = y
	return new_chunk


# get chunk at x,y position
func get_chunk(x, y):
	var key = str(x) + "," + str(y)
	if chunks.has(key):
		return chunks.get(key)

	return null


# set all chunks to should_remove=true
func set_all_chunks_to_remove():
	for key in chunks:
		chunks[key].should_remove = true
