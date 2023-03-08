extends Node

const _Chunk = preload("res://scenes/Chunk.tscn")

var spawn_thread: Thread
var kill_thread: Thread
var update_timer: Timer

var player_pos: Vector2
var last_player_pos: Vector2 = Vector2.ZERO

var chunk_size: int = 16

var chunks: Dictionary = {}
var unready_chunks: Dictionary = {}
var chunk_radius: int = 2

@onready var noise = FastNoiseLite.new()


##
# World.gd is a global script that loads/unloads chunks of tiles
# depending on the player's position
##
func _ready() -> void:
	spawn_thread = Thread.new()
	kill_thread = Thread.new()

	# noise generation
	randomize()
	noise.seed = randi()
	noise.fractal_octaves = 3

	#noise.period = 32.0
	#noise.octaves = 3.0
	#noise.persistence = 0.8

	# connect to player_move event
	#Events.connect("player_move", self, "on_player_move")
	Events.player_move.connect(on_player_move)

	# update update_timer
	update_timer = Timer.new()
	update_timer.timeout.connect(_on_update_timer_timeout)
	update_timer.set_wait_time(0.125)
	add_child(update_timer)
	#update_timer.start()


##
# add a chunk at pos(x, y)
##
func add_chunk(x: int, y: int) -> void:
	var key: String = str(x) + "," + str(y)

	# return if chunk exists
	if chunks.has(key) or unready_chunks.has(key):
		return

	# start loading a new chunk if a spawn_thread is available
	if not spawn_thread.is_started():
		unready_chunks[key] = 1
		#spawn_thread.start(load_chunk, [spawn_thread, x, y])
		spawn_thread.start(load_chunk.bind([spawn_thread, x, y]))


# load a new chunk in a spawn_thread
func load_chunk(args: Array) -> void:
	print("Load Chunk")
	var _thread = args[0]
	var x = args[1]
	var y = args[2]

	var new_chunk = create_chunk(x, y)
	print("New chunk", new_chunk)
	call_deferred("load_done", x, y, new_chunk, _thread)


func load_done(x: int, y: int, chunk: Chunk, _thread: Thread) -> void:
	var key = str(x) + "," + str(y)
	print("Add chunk", chunk)
	add_child(chunk)
	chunks[key] = chunk
	unready_chunks.erase(key)
	_thread.wait_to_finish()


# update player pos internal variable
func on_player_move(_position: Vector2) -> void:
	print("Player move", _position)
	player_pos = _position
	_on_update_timer_timeout()


# can also be in update -> watch for performance
func _on_update_timer_timeout() -> void:
	print("Timer Update")
	set_all_chunks_to_remove()
	determine_chunks_to_keep()
	clean_up_chunks()


func determine_chunks_to_keep() -> void:
	if not player_pos.x:
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
func clean_up_chunks() -> void:
	for key in chunks:
		var chunk = chunks[key]
		if chunk.should_remove:
			if not kill_thread.is_started():
				chunk.visible = false
				kill_thread.start(free_chunk.bind([chunk, key, kill_thread]))


# free chunk inside a thread
func free_chunk(args) -> void:
	var _chunk = args[0]
	var _key = args[1]
	var _thread = args[2]

	chunks.erase(_key)
	_chunk.queue_free()

	#_thread.wait_to_finish()
	call_deferred("on_free_chunk", _chunk, _key, _thread)


# thread wait to finish function -> if some work needs to happen after chunk deletion
func on_free_chunk(_chunk: Chunk, _key: String, _thread: Thread) -> void:
	_thread.wait_to_finish()


# create chunk at x,y position
func create_chunk(x, y) -> Chunk:
	var new_chunk = _Chunk.instantiate()
	new_chunk.noise = noise
	new_chunk.chunk_size = chunk_size
	new_chunk.chunk_x = x
	new_chunk.chunk_y = y
	
	return new_chunk


# get chunk at x,y position
func get_chunk(x, y) -> Chunk:
	var key = str(x) + "," + str(y)
	if chunks.has(key):
		return chunks.get(key)

	return null


# set all chunks to should_remove=true
func set_all_chunks_to_remove() -> void:
	for key in chunks:
		chunks[key].should_remove = true
