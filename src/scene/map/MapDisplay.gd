extends Node2D
class_name MapDisplay

const SCALE: float = 0.01
const TRAIN_SCENE: PackedScene = preload("res://src/scene/train/TrainPreview.tscn")

@onready var map_node: Node = $Map
@onready var trains_node: Node = $Trains

var map: Map = null
var rail_segment_lines: Array[RailSegmentLine] = []

var timetable: TT.Timetable = null
var timetable_stations: Dictionary = null # [ String, Dictionary[ bool, MapNode ] ]

var time_thread: Thread = null
var time_s: float = null

var train_positions_mutex: Mutex = Mutex.new()
var train_positions: Array[TrainPosition] = []

"""
Sets the time used by the update thread and updates train nodes
The update thread is started if not already running
"""
func setTime(time_s: float):
	if self.time_s == null:
		self.time_s = time_s
		
		time_thread = Thread.new()
		time_thread.start(_trainPositionUpdateLoop)
	else:
		self.time_s = time_s
	
	updateTrainNodes()

"""
Adds RailSegmentLines and station previews matching the passed map
Nodes previously added by this function are removed
"""
func setMap(map: Map):
	self.map = map
	
	rail_segment_lines.clear()
	for child in map_node.get_children():
		child.queue_free()
	
	if map == null:
		return
	
	for rail_line in map.rail_lines:
		for rail_segment in rail_line.segments:
			if rail_segment.names.is_empty():
				continue
			
			var line: RailSegmentLine = RailSegmentLine.new()
			line.applyRailSegment(rail_segment, rail_line)
			
			rail_segment_lines.append(line)
			map_node.add_child(line)
		
		for station in rail_line.stations:
			var sprite = Sprite2D.new()
			sprite.texture = preload("res://icon.svg")
			sprite.global_position = station.pos * 0.01
			sprite.scale = Vector2.ONE * 0.05
			map_node.add_child(sprite)

func _formatStationName(name: String) -> String:
	var bracket_index: int = name.find("(")
	if bracket_index != -1:
		return name.substr(0, bracket_index)
	return name

func _timetableStationToMapStation(station: TT.Station) -> Array: # 0: Map.MapNode, 1: RailLine
	var station_name: String = _formatStationName(station.name)
	
	for rail_line in map.rail_lines:
		if rail_line.info == null:
			continue
		
		if rail_line.info.timetable_line_name != station.line.name:
			continue
		
		for map_station in rail_line.stations:
			for name in [map_station.name] + map_station.names.values():
				var formatted_name: String = _formatStationName(name)
				if station_name in formatted_name or formatted_name in station_name:
					return [map_station, rail_line]
	
	return null

func _getTimetableStationOfMapStation(station: Map.MapNode, line: RailLine, timetable: TT.Timetable) -> TT.Station:
	var station_names: Array = [station.name] + station.names.values()
	for i in range(len(station_names)):
		station_names[i] = _formatStationName(station_names[i])
	
	for company in timetable.companies.values():
		for tt_line in company.lines.values():
			if tt_line.name != line.info.timetable_line_name:
				continue
			
			for tt_station in tt_line.stations.values():
				var formatted_name: String = _formatStationName(tt_station.name)
				for name in station_names:
					if name in formatted_name or formatted_name in name:
						return tt_station
	
	return null

"""
Sets the timetable to be used by the train position update thread
Must be called after setMap
"""
func setTimetable(timetable: TT.Timetable):
	self.timetable = timetable
	if timetable == null:
		timetable_stations = null
		return
	
	assert(map != null)
	
	timetable_stations = {}
	
	for line in map.rail_lines:
		if line.info == null:
			continue
		
		for station in line.stations:
			var tt_station: TT.Station = _getTimetableStationOfMapStation(station, line, timetable)
			
			tt_station.line.map_line = line
			
			var existing: Dictionary = timetable_stations.get(tt_station.getUid())
			if existing == null:
				timetable_stations[tt_station.getUid()] = {line.info.direction: station}
			else:
				existing[line.info.direction] = station

func _ready():
	$Camera2D.ZoomLevelChanged.connect(onCameraZoomLevelChanged)

func _exit_tree():
	if time_thread != null:
		time_s = null
		time_thread.wait_to_finish()
		time_thread = null

func _process(delta: float):
	if Input.is_action_just_pressed("click"):
		_onClick()

func onCameraZoomLevelChanged(zoom_level: float):
	for line in rail_segment_lines:
		line.onCameraZoomLevelChanged(zoom_level)

func updateTrainNodes():
	if not train_positions_mutex.try_lock():
		return
	var positions: Array[TrainPosition] = train_positions
	train_positions_mutex.unlock()
	
	var nodes: Array[Node] = trains_node.get_children()
	
	for i in range(0, len(positions)):
		var position: TrainPosition = positions[i]

		var train: TrainPreview
		if i < len(nodes):
			train = nodes[i]
			train.visible = true
		else:
			train = TRAIN_SCENE.instantiate()
			nodes.append(train)
			trains_node.add_child(train)
		
		train.position = position.position * MapDisplay.SCALE
		train.setTrain(position.train)
	
	for i in range(len(positions), max(len(positions), len(nodes))):
		nodes[i].visible = false

func _onClick():
	var mouse_position: Vector2 = get_global_mouse_position()
	
	var touching: Array[RailSegmentLine] = []
	for line in rail_segment_lines:
		if line.isTouchingCursor():
			touching.append(line)
	
	if touching.is_empty():
		return
	if touching.size() == 1:
		_onRailSegmentLineClicked(touching[0])
		return
	
	var closest: RailSegmentLine = null
	var closest_distance: float = null
	
	for line in touching:
		var distance = line.getTouchingCursorDistance(mouse_position)
		
		if closest == null || distance < closest_distance:
			closest = line
			closest_distance = distance
	
	_onRailSegmentLineClicked(closest)

func _onRailSegmentLineClicked(rail_segment_line: RailSegmentLine):
	print(rail_segment_line.rail_segment.names)

func _trainPositionUpdateLoop(single: bool = false):
	while true:
		var time_s: float = self.time_s
		if time_s == null:
			break
		
		var positions: Array[TrainPosition] = TrainPosition.calculateMapTrainPositions(
			time_s, map, timetable, timetable_stations
		)
		
		train_positions_mutex.lock()
		self.train_positions = positions
		train_positions_mutex.unlock()
		
		if single:
			return
