extends Node

var client = HTTPRequest.new()

class Response extends Reference:
	var result: int
	var code: int
	var headers: PoolStringArray
	var body: String
	var body_obj: Dictionary
	
	func _init(data: Array):
		result = data[0]
		code = data[1]
		headers = data[2]
		body = data[3].get_string_from_utf8()
		body_obj = parse_json(body)["response"]

func performRequest(url: String):
	client.request(url)
	return Response.new(yield(client, "request_completed"))

func _ready():
	add_child(client)

func getAreas():
	var response = yield(performRequest("http://express.heartrails.com/api/json?method=getAreas"), "completed")
	return response.body_obj["area"]

func getPrefectures(area: String = ""):
	var url = "http://express.heartrails.com/api/json?method=getPrefectures"
	if area != "":
		url += "&area=" + area
	var response = yield(performRequest(url), "completed")
	return response.body_obj["prefecture"]

func getLines(area: String = "", prefecture: String = ""):
	assert(area != "" or prefecture != "")
	
	var url = "http://express.heartrails.com/api/json?method=getLines"
	if area != "":
		url += "&area=" + area
	if prefecture != "":
		url += "&prefecture=" + prefecture
	var response = yield(performRequest(url), "completed")
	return response.body_obj["line"]

class LineCollector extends Reference:
	signal request_completed
	var lines = PoolStringArray()
	
	func collect():
		
		var prefectures: Array = yield(RailApi.getPrefectures(), "completed")
		
		var requests = Node.new()
		RailApi.add_child(requests)
		
		for pref in prefectures:
			# If the amount of running requests is at the limit, wait for one to complete
			while requests.get_child_count() >= IP.RESOLVER_MAX_QUERIES:
				yield(self, "request_completed")
			
			var request = HTTPRequest.new()
			requests.add_child(request)
			request.use_threads = true
			request.connect("request_completed", self, "onRequestCompleted", [requests, request])
			request.request("http://express.heartrails.com/api/json?method=getLines&prefecture=" + pref)
		
		while requests.get_child_count() > 0:
			yield(self, "request_completed")
		
		requests.queue_free()
		
		return lines
	
	func onRequestCompleted(_result, _code, _headers, body: PoolByteArray, requests: Node, request: HTTPRequest):
		for line in parse_json(body.get_string_from_utf8())["response"]["line"]:
			if not line in lines:
				lines.append(line)
		requests.remove_child(request)
		emit_signal("request_completed")

class StationCollector extends Reference:
	signal request_completed
	var stations: Dictionary = {}
	
	func collect() -> Dictionary:
		
		var collector = LineCollector.new()
		var lines = yield(collector.collect(), "completed")
		
		var requests = Node.new()
		RailApi.add_child(requests)
		
		for line in lines:
			# If the amount of running requests is at the limit, wait for one to complete
			while requests.get_child_count() >= IP.RESOLVER_MAX_QUERIES:
				yield(self, "request_completed")
			
			var request = HTTPRequest.new()
			requests.add_child(request)
			request.use_threads = true
			request.connect("request_completed", self, "onRequestCompleted", [requests, request, line])
			request.request("http://express.heartrails.com/api/json?method=getStations&line=" + line)
		
		while requests.get_child_count() > 0:
			yield(self, "request_completed")
		
		requests.queue_free()
		
		return stations
	
	func onRequestCompleted(_result, _code, _headers, body: PoolByteArray, requests: Node, request: HTTPRequest, line: String):
		stations[line] = parse_json(body.get_string_from_utf8())["response"]["station"]
		for station in stations[line]:
			station.erase("line")
		requests.remove_child(request)
		emit_signal("request_completed")

func getAllLines() -> PoolStringArray:
	var collector = LineCollector.new()
	return yield(collector.collect(), "completed")

func getStations(line: String = "", name: String = "", prefecture: String = ""):
	assert(line != "" or name != "")
	
	var url = "http://express.heartrails.com/api/json?method=getStations"
	if line != "":
		url += "&line=" + line
	if name != "":
		url += "&name=" + name
	if prefecture != "":
		url += "&prefecture=" + prefecture
	var response = yield(performRequest(url), "completed")
	return response.body_obj["station"]

func getAllStations() -> Dictionary:
	var collector = StationCollector.new()
	return yield(collector.collect(), "completed")
