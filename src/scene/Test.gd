extends Node2D

const MAP_FILE: String = "res://map.osm"
const TIMETABLE_FILES: Array[String] = ["res://data/19500.json", "res://data/19800.json", "res://data/20000.json"]
const MAX_TIME: float = 24 * 60 * 60

@onready var time_display = $CanvasLayer/Control/TimeDisplay
@onready var map_display = $MapDisplay

var loader: OsmLoader = OsmLoader.new()
var timetable: TT.Timetable = TT.Timetable.new()
var time_s: float = (12 * 60 + 10) * 60
var paused: bool = false

func _ready():
	for file in TIMETABLE_FILES:
		TT.loadTimetableFile(
			FileAccess.open(file, FileAccess.READ), 
			timetable
		)
	
	loader.loadOsmFile(MAP_FILE)
	$MapDisplay.setMap(loader.map)
	$MapDisplay.setTimetable(timetable)
	
	add_child(CursorCollisionBody.new())

func _process(delta: float):
	if Input.is_action_just_pressed("toggle_pause"):
		paused = !paused
	
	if paused:
		return
	
	time_s = time_s + (delta * 10)
	
	time_display.setTime(time_s)
	map_display.setTime(time_s)
