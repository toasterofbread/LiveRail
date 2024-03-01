extends Control

@onready var label: Label = $Label

func _ready():
	setTime(0)

"""
Updates label to display the passed time
"""
func setTime(time_s: float):
	label.text = secondsToText(time_s)

"""
Takes a time in seconds and returns a time string in the format "HH:mm:ss.SS"
"""
func secondsToText(time_s: float):
	if time_s == null:
		return "??:??"
	
	var hours: int = int(time_s / 3600)
	var minutes: int = int(time_s / 60) - (hours * 60)
	var seconds: int = int(time_s) % 60
	var centiseconds: int = int((time_s - int(time_s)) * 100)
	
	return "%02d:%02d:%02d.%02d" % [hours, minutes, seconds, centiseconds]
