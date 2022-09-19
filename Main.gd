extends Node2D

var stations: Dictionary = {}
const STATION_DATA_PATH: String = "res://res/station_data.json"

const CAMERA_MOVE_SPEED: float = 1000.0
const CAMERA_ZOOM_SPEED: float = 0.2
const LABEL_SIZE: float = 0.85

onready var camera: Camera2D = $Camera2D
var camera_zoom: float = 1.0

var map: Map

class Map extends Node2D:
	
	class Borders extends Node2D:
		const BORDER_DATA_PATH: String = "res://res/japan.json"
		
		var lines: Array = []
		
		func _init(scale: float):
			var file = File.new()
			file.open(BORDER_DATA_PATH, File.READ)
			var data: Array = parse_json(file.get_as_text())
			file.close()
			
			for region in data:
				var line_points = PoolVector2Array()
				for line in region:
					for point in line:
						line_points.append(Vector2(point[0], -point[1]) * scale)
				lines.append(line_points)
		
		func _draw():
			for line in lines:
				draw_polyline(line, Color.pink, 1.0)
	
	var stations: Dictionary
	var station_offset: Vector2
	var map_scale: float
	
	var camera: Camera2D
	var borders: Borders
	
	var line_points: Dictionary = {}
	var line_labels: Dictionary = {}
	
	func _init(_stations: Dictionary, _camera: Camera2D):
		stations = _stations
		
		var sum = Vector2.ZERO
		var total = 0
		for line in stations:
			var points = PoolVector2Array()
			for station in stations[line]:
				points.append(Vector2(station["x"], -station["y"]))
				
				sum.x += station["x"]
				sum.y -= station["y"]
				total += 1
			line_points[line] = points
		station_offset = sum / total

		camera = _camera
		
		for line in stations:
			var node: Node2D = Node2D.new()
			add_child(node)
			line_labels[line] = node
			
			var label: Label = Label.new()
			node.add_child(label)
			label.text = line
			
			var font: Font = DynamicFont.new()
			font.font_data = load("res://res/DefaultFont.otf")
			font.size = 16
			label.set("custom_fonts/font", font)
			
			var rect = ColorRect.new()
			rect.rect_size = Vector2.ONE * 10.0
			rect.color = Color.red
			label.add_child(rect)
	
	func _ready():
		# TODO | Update borders on map_scale change
		borders = Borders.new(map_scale)
		borders.position = Vector2(-2738.171, 715.645)
		add_child(borders)
	
	func _process(_delta):
		update()
	
	func _draw():
		var camera_center: Vector2 = to_local(camera.get_camera_screen_center())
		var camera_size = camera.get_viewport_rect().size * camera.zoom
		var camera_rect: Rect2 = Rect2(camera_center - camera_size / 2.0, camera_size)
		
		var m = Vector2(-1, -1)
		for line in stations:
			var points = PoolVector2Array()
			
			var line_visible: bool = false
			for point in (line_points[line] + PoolVector2Array([line_points[line][0]])) if isLineLoop(line) else line_points[line]:
				var draw_point = (point - station_offset) * map_scale
				if not line_visible:
					line_visible = camera_rect.has_point(draw_point)
				points.append(draw_point)
			
			var label_node: Node2D = line_labels[line]
			
			if not line_visible:
				label_node.visible = false
				continue
			
			draw_polyline(points, getLineColour(line), 1.0, true)
			
			if camera.zoom.x > 0.1:
				label_node.visible = false
				continue
			
			label_node.position = getCenteredVisiblePoint(points, camera_center)
			label_node.scale = Vector2.ONE * min(0.003, camera.zoom.x * LABEL_SIZE)
			label_node.visible = true
	
	func getClosestPointOnLine(A: Vector2, B: Vector2, P: Vector2):
		var AB = B - A
		var distance = (P - A).dot(AB) / AB.length_squared()
		if distance < 0:
			return A
		elif distance > 1:
			return B
		else:
			return A + AB * distance
	
	func getCenteredVisiblePoint(points: PoolVector2Array, camera_center: Vector2) -> Vector2:
		var ret: Vector2
		var closest_distance: float = -1.0
		
		for i in len(points):
			if i + 1 == len(points):
				break
			
			var closest = getClosestPointOnLine(points[i], points[i + 1], camera_center)
			var distance = closest.distance_squared_to(camera_center)
			if closest_distance == -1.0 or distance < closest_distance:
				closest_distance = distance
				ret = closest
		
		return ret
	
	func isLineLoop(line: String) -> bool:
		match line:
			"JR大阪環状線": return true
		return false
	
	func getLineColour(line: String) -> Color:
		match line:
			
			# 大阪府
			"JR大阪環状線": return Color.orangered
			"JR東西線": return Color.blue
			"JR桜島線": return Color.pink
			"JR神戸線": return Color.blue
			"JR福知山線": return Color.blue
			"JR関西空港線": return Color.blue
			"JR阪和線": return Color.blue
			"おおさか東線": return Color.green
			"京阪中之島線": return Color.yellow
			"京阪交野線": return Color.yellow
			"京阪本線": return Color.yellow
			"北大阪急行": return Color.red
			"南海多奈川線": return Color.purple
			"南海本線": return Color.purple
			"南海汐見橋線": return Color.purple
			"南海空港線": return Color.purple
			"南海高師浜線": return Color.purple
			"南海高野線": return Color.purple
			"大阪モノレール": return Color.black
			"大阪モノレール彩都線": return Color.black
			"大阪中央線": return Color.darkgreen
			"大阪今里筋線": return Color.orange
			"大阪千日前線": return Color.pink
			"大阪南港ポートタウン線": return Color.black
			"大阪四つ橋線": return Color.blue
			"大阪堺筋線": return Color.brown
			"大阪御堂筋線": return Color.red
			"大阪谷町線": return Color.magenta
			"大阪長堀鶴見緑地線": return Color.lightgreen
			"水間鉄道": return Color.black
			"泉北高速鉄道": return Color.black
			"近鉄けいはんな線": return Color.orange
			"近鉄信貴線": return Color.orange
			"近鉄南大阪線": return Color.orange
			"近鉄大阪線": return Color.orange
			"近鉄奈良線": return Color.orange
			"近鉄西信貴ケーブル線": return Color.orange
			"近鉄道明寺線": return Color.orange
			"近鉄長野線": return Color.orange
			"阪堺電軌上町線": return Color.brown
			"阪堺電軌阪堺線": return Color.brown
			"阪急京都本線": return Color.maroon
			"阪急千里線": return Color.maroon
			"阪急宝塚本線": return Color.maroon
			"阪急神戸本線": return Color.maroon
			"阪急箕面線": return Color.maroon
			
			# 新幹線
			"東海道新幹線": return Color.orange
			"山陽新幹線": return Color.blue
			"北陸新幹線": return Color.yellow
			"東北新幹線": return Color.green
			"秋田新幹線": return Color.red
			"山形新幹線": return Color.lightgreen
			"上越新幹線": return Color.lightgreen
		
		return Color.darkgray

func loadStationData():
	var file = File.new()
	if Directory.new().file_exists(STATION_DATA_PATH):
		file.open(STATION_DATA_PATH, File.READ)
		stations = parse_json(file.get_as_text())
	else:
		stations = yield(RailApi.getAllStations(), "completed")
		file.open("res://station_data.json", File.WRITE)
		file.store_string(to_json(stations))
	file.close()

func _ready():
	loadStationData()
	
	map = Map.new(stations, camera)
	map.map_scale = 20
	add_child(map)
	
	camera.current = true
	camera.zoom = Vector2.ONE / 1

func _process(delta: float):

	if Input.is_action_pressed("camera_move_up"):
		camera.position.y -= CAMERA_MOVE_SPEED * delta * camera.zoom.y
	if Input.is_action_pressed("camera_move_down"):
		camera.position.y += CAMERA_MOVE_SPEED * delta * camera.zoom.y
	if Input.is_action_pressed("camera_move_left"):
		camera.position.x -= CAMERA_MOVE_SPEED * delta * camera.zoom.x
	if Input.is_action_pressed("camera_move_right"):
		camera.position.x += CAMERA_MOVE_SPEED * delta * camera.zoom.x
	
	if Input.is_action_just_released("camera_zoom_in"):
		camera.zoom *= 1.0 - CAMERA_ZOOM_SPEED
#		map.update()
	if Input.is_action_just_released("camera_zoom_out"):
		camera.zoom *= 1.0 + CAMERA_ZOOM_SPEED
#		map.update()
