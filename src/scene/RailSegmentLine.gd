extends Line2D
class_name RailSegmentLine

const WIDTH: float = 1

var rail_segment: RailSegment = null
var _cursor_raycasts: Array[RayCast2D] = []

func _ready():
	width = WIDTH

func applyRailSegment(rail: RailSegment, line: RailLine):
	if line != null:
		if line.colour != null:
			default_color = line.colour
	
	for child in get_children():
		child.queue_free()
	
	var points: Array[Vector2] = []
	var min: Vector2 = null
	var max: Vector2 = null
	
	for node in rail.nodes:
		points.append(node.pos * 0.01)
		
		var marker = Sprite2D.new()
		marker.texture = preload("res://icon.svg")
		marker.scale = Vector2.ONE * 0.05
		marker.position = node.pos * 0.01
		marker.z_index = 1
		
		if min == null:
			min = marker.position
			max = marker.position
			continue
		
		if marker.position.x < min.x:
			min.x = marker.position.x
		elif marker.position.x > max.x:
			max.x = marker.position.x
		
		if marker.position.y < min.y:
			min.y = marker.position.y
		elif marker.position.y > max.y:
			max.y = marker.position.y
	
	self.points = points
	
	var visibility_enabler = VisibleOnScreenEnabler2D.new()
	visibility_enabler.rect = Rect2(min, max - min)
	add_child(visibility_enabler)
	
	_addCursorRaycasts()
	
	rail_segment = rail

func getTouchingCursorDistance(cursor_position: Vector2) -> float:
	if process_mode == PROCESS_MODE_DISABLED:
		return null
	
	for ray in _cursor_raycasts:
		if not ray.is_colliding():
			continue
		
		var start = ray.global_position
		var end = ray.global_position + ray.target_position
		
		var line = (end - start)
		var len = line.length()
		line = line.normalized()
		
		var v = cursor_position - start
		var d = v.dot(line)
		d = clamp(d, 0, len)
		
		return (start + line * d).distance_to(cursor_position)
	
	return null

func isTouchingCursor() -> bool:
	if process_mode == PROCESS_MODE_DISABLED:
		return false
	
	for ray in _cursor_raycasts:
		if ray.is_colliding():
			return true
	
	return false

func onCameraZoomLevelChanged(zoom_level: float):
	width = WIDTH * max(0, 1 / zoom_level)

func _addCursorRaycasts():
	var previous_point: Vector2 = null
	
	for point in points:
		if previous_point != null:
			var ray = RayCast2D.new()
			ray.global_position = previous_point
			ray.target_position = point - previous_point
			ray.collision_mask = 1
			
			add_child(ray)
			_cursor_raycasts.append(ray)
		
		previous_point = point
