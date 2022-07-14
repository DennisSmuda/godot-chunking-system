extends Node

const _Chunk = preload("res://scenes/Chunk.tscn")
onready var noise = OpenSimplexNoise.new()


var player_pos
var last_player_pos = Vector2.ZERO

var chunk_size := 16.0

var chunks := {}
var unready_chunks = {}
var chunks_to_delete = []
var current_chunk = null
var chunk_radius = 2

var thread


# Called when the node enters the scene tree for the first time.
func _ready():
	thread = Thread.new()
	randomize()
	noise.seed = randi()
	noise.period = 32.0
	noise.octaves = 3.0
	noise.persistence = 0.8

	Events.connect("player_move", self, "on_player_move")


func add_chunk(x, y):
	# print("Adding Chunk: ", x, ",", y)
	var key = str(x) + "," + str(y)
	if chunks.has(key) or unready_chunks.has(key):
		# print("Chunk already exists")
		return

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
	chunks[str(x) + "," + str(y)] = new_chunk
	current_chunk = new_chunk
	return new_chunk



func on_player_move(_position):
	player_pos = _position
	if not last_player_pos:
		last_player_pos = player_pos
		update_player_pos()

	if (last_player_pos - player_pos).length() > 64:
		last_player_pos = player_pos
		update_player_pos()


func _process(_delta):
	reset_chunks()
	update_chunks()
	clean_up_chunks()


func update_player_pos():
	print("Update Map")
	reset_chunks()
	update_chunks()
	clean_up_chunks()
	delete_chunks()


func update_chunks():
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


func reset_chunks():
	for key in chunks:
		chunks[key].should_remove = true
		pass


func clean_up_chunks():
	for key in chunks:
		var chunk = chunks[key]
		if chunk.should_remove:
			#print("Killing Chunk", key)
			if not thread.is_active():
				thread.start(self, "free_chunk", [chunk, key, thread])
		# print("Loading New Chunk: ", str(x), ", ", str(y))

		# chunk.queue_free()
		#chunks.erase(key)


func free_chunk(arg):
	print("Free CHUNK!")
	var _chunk = arg[0]
	var _key = arg[1]
	var _thread = arg[2]

	# _chunk.visible = false
	_chunk.clear_chunk()

	print("Clear Chunk", _key)
	call_deferred("kill_chunk", _chunk, _key, _thread)


func kill_chunk(_chunk, _key, _thread):
	print("kIllChunk: ", _chunk.get_child_count())
	# _chunk.queue_free()
	# if _chunk.get_child_count() == 0:
	_chunk.visible = false
	# _chunk.queue_free()
	chunks.erase(_key)
	_thread.wait_to_finish()


func delete_chunks():
	for key in chunks_to_delete:
		var chunk = chunks[key]
		if not chunk.visible:
			print("DELETEE THTIS CHUNK!! ", key)
			# if not thread.is_active():
			# chunk.queue_free()
			# thread.start(self, "free_chunk", [chunk, key, thread])
		# print("Loading New Chunk: ", str(x), ", ", str(y))
