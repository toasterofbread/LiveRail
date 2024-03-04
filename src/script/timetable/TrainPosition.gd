class_name TrainPosition

var prev: TT.Stop
var next: TT.Stop
var progress: float
var direction: bool

func _to_string():
	return "TrainPosition(prev=%s, next=%s, progress=%s" % [prev, next, progress]

"""
Returns a TrainPosition for the passed train at the passed time
Returns null if the train is out of service or moving to/from an ignored stop
"""
static func calculateTrainPosition(
	train: TT.TrainService, 
	time_s: float,
	shouldIgnoreStop: Callable = func(it): false
) -> TrainPosition:
	if train.stops.is_empty():
		return null
	
	if train.type != TT.TrainService.Type.LOCAL:
		return null
	
	var position: TrainPosition = TrainPosition.new()
	position.direction = train.stops[-1].station == train.line.base_station
	
	for i in range(0, len(train.stops) - 1):
		var prev: TT.Stop = train.stops[i]
		if shouldIgnoreStop.call(prev):
			continue
		
		# Check for null (first stop) arrival time
		if prev.arrival == null:
			if time_s < prev.departure:
				continue
		# Skip if train hasn't reached prev yet
		elif time_s < prev.arrival:
			continue
		
		var next: TT.Stop = train.stops[i + 1]
		if shouldIgnoreStop.call(next):
			continue
		
		# Check if train is currently stopped at prev
		if time_s < prev.departure:
			position.prev = prev
			position.next = next
			
			# Train is stopped at prev, so progress is zero
			position.progress = 0
			return position
		
		# Check if train is already at/past next
		if time_s >= next.arrival:
			continue
		
		position.prev = prev
		position.next = next
		
		# Set progress to the fraction of time passed since departure until next arrival
		position.progress = (time_s - prev.departure) / (next.arrival - prev.departure)
		
		return position
	
	return null

"""
Returns a dictionary of TT.TrainServices to Vector2 positions for the passed time and data
`timetable_stations` must be a dictionary of TT.Stations to dictionaries of { true: <up train>, false: <down train> }
"""
static func calculateMapTrainPositions(
	time_s: float, 
	map: Map,
	timetable: TT.Timetable,
	timetable_stations: Dictionary
) -> Dictionary:
	var positions: Dictionary = {}
	
	timetable.forEachTrain(func(train):
		var position: TrainPosition = calculateTrainPosition(
			train,
			time_s, 
			func shouldIgnoreStop(stop): 
				# Ignore stop if it's not in timetable_stations
				return not timetable_stations.has(stop.station)
		)
		
		if position == null:
			return
		
		var prev: Map.MapNode = timetable_stations[position.prev.station][position.direction]
		var next: Map.MapNode = timetable_stations[position.next.station][position.direction]
		
		var nodes: Array[Map.MapNode] = map.getNodesBetweenNodes(prev, next)
		assert(nodes != null)
		
		# Calculate total distance of nodes and cache distances between each node
		var total_distance: float = 0
		var distances: Array[float] = []
		for i in range(0, len(nodes) - 1):
			distances.append(nodes[i].distanceTo(nodes[i + 1]))
			total_distance += distances[i]
	
		# Initialise to the total distance travelled
		var remaining_distance: float = total_distance * position.progress
		
		# Iterate over distances until the current section is found
		for i in range(len(distances)):
			var distance: float = distances[i]
			
			# Train is not in this section
			if distance < remaining_distance:
				remaining_distance -= distance
				continue
			
			# The fraction of progress travelled between these two nodes
			var progress: float = remaining_distance / distance
			
			# The in-engine position of the train
			var train_position: Vector2 = nodes[i].pos + ((nodes[i + 1].pos - nodes[i].pos) * progress)
			positions[train] = train_position
			
			break
	)
	
	return positions
