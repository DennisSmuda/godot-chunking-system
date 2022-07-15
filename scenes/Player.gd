extends RigidBody2D

var move_speed = 256

var new_body_velocity: Vector2 = Vector2(0, 0)
var direction_vector := Vector2(0, 0)


func _ready():
	Events.emit_signal("player_move", global_position)
	
	print("Player INIT!", Events)


func _input(_event):
	if Input.is_action_pressed("left"):
		direction_vector = Vector2(-1, 0)
	if Input.is_action_pressed("right"):
		direction_vector = Vector2(1, 0)
	if Input.is_action_pressed("up"):
		direction_vector = Vector2(0, -1)
	if Input.is_action_pressed("down"):
		direction_vector = Vector2(0, 1)
	if Input.is_action_pressed("ui_cancel"):
		direction_vector = Vector2(0, 0)


func _physics_process(_delta):
	new_body_velocity = Vector2(0, 0)
	var body_velocity = linear_velocity

	new_body_velocity += direction_vector * move_speed

	var newVelocity = body_velocity.linear_interpolate(new_body_velocity, 0.2)
	linear_velocity = newVelocity
	if linear_velocity.length() > 0.5:
		Events.emit_signal("player_move", global_position)
