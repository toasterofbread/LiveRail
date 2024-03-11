class_name TT

class Timetable:
	var companies: Dictionary = {} # [ String, RailwayCompany ]
	
	func forEachTrain(action: Callable):
		for company in companies.values():
			for line in company.lines.values():
				for train in line.trains:
					action.call(train)
	
	func _to_string():
		return "Timetable(len(companies)=%d)" % len(companies)

class RailwayCompany:
	var name: String
	var lines: Dictionary = {} # [ String, RailwayLine ]
	
	func _to_string():
		return "RailwayCompany(name=%s, len(lines)=%d)" % [name, len(lines)]

class RailwayLine:
	var name: String
	var stations: Dictionary = {} # [ String, Station ]
	var trains: Array[TrainService] = []
	var company: RailwayCompany
	var base_station: Station
	var map_line: RailLine = null
	
	func _to_string():
		return "RailwayLine(name=%s, len(stations)=%d, len(trains)=%s, base_station=%s)" % [name, len(stations), len(trains), str(base_station.name)]

class Station:
	var name: String
	var schedule: Dictionary # [TrainService, Stop]
	var line: RailwayLine
	
	func getUid() -> String:
		return line.name + name
	
	func _to_string():
		return "Station(name=%s, line=%s)" % [name, line]

class Stop:
	var station: Station
	var arrival: float
	var departure: float
	
	func _to_string():
		return "Stop(arrival=%s, departure=%s, station=%s)" % [TT.secondsToText(arrival), TT.secondsToText(departure), station.name]

class TrainService:
	var type: Type
	var train_class: TrainClass
	var stops: Array[Stop]
	var line: RailwayLine
	
	func getPosition(time_s: float, shouldIgnoreStop: Callable = func(it): false) -> TrainPosition:
		return TrainPosition.calculateTrainPosition(self, time_s, shouldIgnoreStop)
	
	func _to_string():
		return "TrainService(len(stops)=%d)" % len(stops)
	
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

class TrainClass:
	var name: String
	var maximum_speed: float
	var acceleration: float
	var deceleration: float

static func loadTimetableFile(
	file: FileAccess,
	timetable: Timetable
):
	var data: Dictionary = JSON.parse_string(file.get_as_text(true))
	
	var company_name: String = data["company_name"]
	var company: RailwayCompany = timetable.companies.get(company_name)
	if company == null:
		company = RailwayCompany.new()
		company.name = company_name
		timetable.companies[company_name] = company
	
	var line_name: String = data["line_name"]
	var line: RailwayLine = company.lines.get(line_name)
	if line == null:
		line = RailwayLine.new()
		line.name = line_name
		line.company = company
		company.lines[line_name] = line
	
	for item in data["trains"]:
		var train: TrainService = TrainService.new()
		train.line = line
		line.trains.append(train)
		
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
			var station: Station = line.stations.get(stop["station"])
			if station != null:
				continue
			
			station = Station.new()
			station.name = stop["station"]
			station.line = line
			line.stations[station.name] = station
		
		var stops: Array[Stop]
		for stop_data in item["stops"]:
			var stop: Stop = Stop.new()
			stop.arrival = textToSeconds(stop_data["arr"])
			stop.departure = textToSeconds(stop_data["dep"])
			stop.station = line.stations[stop_data["station"]]
			
			stops.append(stop)
		train.stops = stops
	
	line.base_station = line.stations[data["base_station"]]

"""
Takes a time string in the format "HH:mm" and returns the represented time in seconds
"""
static func textToSeconds(string: String) -> float:
	if string == null:
		return null
	
	var split: PackedStringArray = string.split(":")
	assert(len(split) == 2, str(split))
	
	var hours: float = split[0].to_float()
	var minutes: float = split[1].to_float()
	
	return ((hours * 60) + minutes) * 60

"""
Takes a time in seconds and returns a time string in the format "HH:mm"
"""
static func secondsToText(time: float) -> String:
	if time == null:
		return null
	
	var hours: int = int(time / 3600)
	var minutes: int = int(time / 60) - (hours * 60)
	
	return "%02d:%02d" % [hours, minutes]
