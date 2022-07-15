extends Node

const _Chunk = preload("res://scenes/Chunk.tscn")
onready var noise = OpenSimplexNoise.new()

var player_pos
var last_player_pos = Vector2.ZERO

var chunk_size := 16.0

var chunks := {}
var unready_chunks = {}
var current_chunk = null
var chunk_radius = 2

var thread
var kill_thread
var timer

# Called when the node enters the scene tree for the first time.
func _ready():
	thread = Thread.new()
	kill_thread = Thread.new()
	randomize()
	noise.seed = randi()
	noise.period = 32.0
	noise.octaves = 3.0
	noise.persistence = 0.8
	print("World INIT!", Events)

	Events.connect("player_move", self, "on_player_move")
	
	timer = Timer.new()
	timer.connect("timeout",self,"update_timer")
	timer.set_wait_time(0.125)
	add_child(timer)
	timer.start()

##
# Add a chunk 
##
func add_chunk(x, y):
	var key = str(x) + "," + str(y)
	
	# return if chunk exists
	if chunks.has(key) or unready_chunks.has(key): return

	if not thread.is_active():
		# print("Loading New Chunk: ", str(x), ", ", str(y))
		thread.start(self, "load_chunk", [thread, x, y])
		unready_chunks[key] = 1


func load_chunk(arr):
	var _thread = arr[0]
	var x = arr[1]
	var y = arr[2]

	var new_chunk = create_chunk(x, y)

	call_deferred("load_done", x, y, new_chunk, _thread)


func load_done(x, y, chunk, _thread):
	add_child(chunk)
	var key = str(x) + "," + str(y)
	chunks[key] = chunk
	unready_chunks.erase(key)
	_thread.wait_to_finish()
	print("Load DONE: ", key)


func create_chunk(x, y):
	var new_chunk = _Chunk.instance()
	new_chunk.noise = noise
	new_chunk.chunk_size = chunk_size
	new_chunk.chunk_x = x
	new_chunk.chunk_y = y
	return new_chunk


func on_player_move(_position):
	player_pos = _position
	
	if not last_player_pos:
		last_player_pos = player_pos
		update_player_pos()

	if (last_player_pos - player_pos).length() > 64:
		last_player_pos = player_pos
		update_player_pos()


# can also be in update -> watch for performance
func update_timer():
	set_all_chunks_to_remove()
	determine_chunks_to_keep()
	clean_up_chunks()

func update_player_pos():
	set_all_chunks_to_remove()
	determine_chunks_to_keep()
	#clean_up_chunks()


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


func get_chunk(x, y):
	var key = str(x) + "," + str(y)
	if chunks.has(key):
		return chunks.get(key)

	return null


func set_all_chunks_to_remove():
	for key in chunks:
		chunks[key].should_remove = true


# Look for a chunk to remove and start a thread to free it
func clean_up_chunks():
	for key in chunks:
		var chunk = chunks[key]
		if chunk.should_remove:
			if not kill_thread.is_active():
				chunk.visible = false
				kill_thread.start(self, "free_chunk", [chunk, key, kill_thread])


func free_chunk(arg):
	print("Free CHUNK!")
	var _chunk = arg[0]
	var _key = arg[1]
	var _thread = arg[2]

	call_deferred("kill_chunk", _chunk, _key, _thread)


func kill_chunk(_chunk, _key, _thread):
	print("kIllChunk: ", _chunk.get_child_count())
	#_chunk.visible = false
	chunks.erase(_key)
	_thread.wait_to_finish()
	_chunk.queue_free()
