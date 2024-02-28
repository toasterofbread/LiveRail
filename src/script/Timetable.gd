class_name TT

class Timetable:
	var stations: Dictionary = {}
	var trains: Array[TrainService] = []
	
	func _to_string():
		return "Timetable(len(stations)=%d, len(trains)=%d)" % [len(stations), len(trains)]

class Station:
	var name: String
	var schedule: Dictionary # [TrainService, Stop]

	func _to_string():
		return "Station(name=%s)" % name

class Stop:
	var arrival: float
	var departure: float
	
	func _to_string():
		return "Stop(arrival=%s, departure=%s)" % [TT.timeToString(arrival), TT.timeToString(departure)]

class TrainService:
	var type: Type
	var train_class: TrainClass
	var stops: Dictionary # [Station, Stop]
	
	func getPosition(time: float) -> TrainPosition:
		return null
	
	enum Type { 
		LOCAL,
		REGIONAL_LOCAL,
		SEMI_EXPRESS,
		EXPRESS,
		COMMUTER_EXPRESS,
		LTD_EXPRESS,
		COMMUTER_LTD_EXPRESS,
		DIRECT_EXPRESS
	}

class TrainPosition:
	var previous: Station
	var next: Station
	var progress: float

class TrainClass:
	var name: String
	var maximum_speed: float
	var acceleration: float
	var deceleration: float

static func loadTimetableFile(file: FileAccess, timetable: Timetable):
	var data: Array = JSON.parse_string(file.get_as_text(true))
	
	for item in data:
		var train: TrainService = TrainService.new()
		timetable.trains.append(train)
		
		match item["train"]["type"]:
			"普通":
				train.type = TrainService.Type.LOCAL
			"区間普通":
				train.type = TrainService.Type.REGIONAL_LOCAL
			"準急", "準特急":
				train.type = TrainService.Type.SEMI_EXPRESS
			"急行":
				train.type = TrainService.Type.EXPRESS
			"通勤急行":
				train.type = TrainService.Type.COMMUTER_EXPRESS
			"特急", "山陽Ｓ特急":
				train.type = TrainService.Type.LTD_EXPRESS
			"通勤特急":
				train.type = TrainService.Type.COMMUTER_LTD_EXPRESS
			"直通特急":
				train.type = TrainService.Type.DIRECT_EXPRESS
			_:
				push_error("Unknown train type: " + item["train"]["type"])
				return null
		
		for stop in item["stops"]:
			var station: Station = timetable.stations.get(stop["station"])
			if station != null:
				continue
			
			station = Station.new()
			station.name = stop["station"]
			timetable.stations[station.name] = station
		
		var stops: Dictionary
		for stop_data in item["stops"]:
			var stop: Stop = Stop.new()
			stop.arrival = stringToTime(stop_data["arr"])
			stop.departure = stringToTime(stop_data["dep"])
			
			var station: Station = timetable.stations[stop_data["station"]]
			stops[station] = stop
		train.stops = stops

static func stringToTime(time: String) -> float:
	if time == null:
		return null
	
	var split: PackedStringArray = time.split(":")
	assert(len(split) == 2, str(split))
	
	var hours: float = split[0].to_float()
	var minutes: float = split[1].to_float()
	
	return ((hours * 60) + minutes) * 60

static func timeToString(time: float) -> String:
	if time == null:
		return null
	
	var hours: int = int(time / 3600)
	var minutes: int = int(time / 60) - (hours * 60)
	
	return "%02d:%02d" % [hours, minutes]
