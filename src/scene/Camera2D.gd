extends Camera2D

const SPEED = 1000

signal ZoomLevelChanged(float)

func _getMovementSpeed() -> float:
	return SPEED / zoom.x

func _process(delta: float):
	if Input.is_action_pressed("camera_up"):
		position.y -= _getMovementSpeed() * delta
	if Input.is_action_pressed("camera_down"):
		position.y += _getMovementSpeed() * delta
	if Input.is_action_pressed("camera_left"):
		position.x -= _getMovementSpeed() * delta
	if Input.is_action_pressed("camera_right"):
		position.x += _getMovementSpeed() * delta
	
	if Input.is_action_just_pressed("camera_zoom_in"):
		zoom.x *= 1.1
		zoom.y *= 1.1
		
		ZoomLevelChanged.emit(zoom.x)
	
	if Input.is_action_just_pressed("camera_zoom_out"):
		zoom.x *= 0.9
		zoom.y *= 0.9
		
		ZoomLevelChanged.emit(zoom.x)
