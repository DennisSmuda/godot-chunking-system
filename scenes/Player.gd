extends RigidBody2D

var move_speed = 256

var new_body_velocity: Vector2 = Vector2(0, 0)
var direction_vector: Vector2 = Vector2(0, 0)


# ready function
func _ready() -> void:
	Events.emit_signal("player_move", global_position)


# movement inputs
func _input(_event: InputEvent) -> void:
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


# process
func _physics_process(_delta: float) -> void:
	linear_velocity = direction_vector * move_speed

	if linear_velocity.length() > 0.5:
		Events.emit_signal("player_move", global_position)
