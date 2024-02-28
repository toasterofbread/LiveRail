extends Node2D

const MAP_FILE = "res://map.osm"
const TIMETABLE_FILES: Array[String] = ["res://data/19500.json", "res://data/19800.json", "res://data/20000.json"]

var loader: OsmLoader = OsmLoader.new()
var timetable: TT.Timetable = TT.Timetable.new()

var rail_segment_lines: Array[RailSegmentLine] = []

func _ready():
	for file in TIMETABLE_FILES:
		TT.loadTimetableFile(
			FileAccess.open(file, FileAccess.READ), 
			timetable
		)
	loader.loadOsmFile(MAP_FILE)
	
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
			
			var timetable_station: TT.Station = null
			for name in [station.name] + station.names.values():
				for st in timetable.stations:
					if st in name or name in st:
						timetable_station = timetable.stations[st]
						break
				if timetable_station != null:
					break
			
			if timetable_station == null:
				push_error("No timetable station found for ", station)
				return
			
			print(station, ": ", timetable_station)
	
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
