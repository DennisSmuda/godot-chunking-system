extends Camera2D

var target_zoom = Vector2(2.5, 2.5)


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _input(_ev):
	if Input.is_action_pressed("ui_up"):
		target_zoom.x -= 0.5
		target_zoom.y -= 0.5

	if Input.is_action_pressed("ui_down"):
		target_zoom.x += 0.5
		target_zoom.y += 0.5


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	zoom = lerp(zoom, target_zoom, 0.4)
