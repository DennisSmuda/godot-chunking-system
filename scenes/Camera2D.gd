extends Camera2D

var target_zoom: Vector2 = Vector2(1.0, 1.0)
var zoom_factor: float = 0.25


# zoom with up/down keys
func _input(_ev: InputEvent) -> void:
	if Input.is_action_pressed("ui_up") and target_zoom.x > 0.5:
		target_zoom.x -= zoom_factor
		target_zoom.y -= zoom_factor

	if Input.is_action_pressed("ui_down"):
		target_zoom.x += zoom_factor
		target_zoom.y += zoom_factor


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	zoom = lerp(zoom, target_zoom, 0.4)
