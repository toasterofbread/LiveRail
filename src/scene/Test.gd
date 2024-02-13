extends Node2D

const FILE = "res://map.osm"
var loader: OsmLoader

var rail_segment_lines: Array[RailSegmentLine] = []

func _ready():
	loader = OsmLoader.new()
	loader.loadOsmFile(FILE)
	
	for rail_line in loader.rail_lines:
		for rail_segment in rail_line.segments:
			if rail_segment.names.is_empty():
				continue
			
			var line = RailSegmentLine.new()
			line.applyRailSegment(rail_segment, rail_line)
			
			rail_segment_lines.append(line)
			add_child(line)
		
		for station in rail_line.stations:
			var sprite = Sprite2D.new()
			sprite.texture = preload("res://icon.svg")
			sprite.global_position = station.pos * 0.01
			sprite.scale = Vector2.ONE * 0.05
			add_child(sprite)
	
	add_child(CursorCollisionBody.new())
	
	$Camera2D.ZoomLevelChanged.connect(onCameraZoomLevelChanged)

func _process(_delta: float):
	if Input.is_action_just_pressed("click"):
		var mouse_position: Vector2 = get_global_mouse_position()
		
		var touching: Array[RailSegmentLine] = []
		for line in rail_segment_lines:
			if line.isTouchingCursor():
				touching.append(line)
		
		if touching.is_empty():
			return
		if touching.size() == 1:
			onRailSegmentLineClicked(touching[0])
			return
		
		var closest: RailSegmentLine = null
		var closest_distance: float = null
		
		for line in touching:
			var distance = line.getTouchingCursorDistance(mouse_position)
			
			if closest == null || distance < closest_distance:
				closest = line
				closest_distance = distance
		
		onRailSegmentLineClicked(closest)

func onRailSegmentLineClicked(rail_segment_line: RailSegmentLine):
	print(rail_segment_line.rail_segment.names)

func onCameraZoomLevelChanged(zoom_level: float):
	for line in rail_segment_lines:
		line.onCameraZoomLevelChanged(zoom_level)
