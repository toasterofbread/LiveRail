class_name TrainPreview
extends Node2D

@onready var label: Label = $Label

var _train: TT.TrainService = null

func setTrain(train: TT.TrainService):
	_train = train
	
#	if train.stops[0].departure != ((12 * 60) + 10) * 60:
#		return
	
	label.set("theme_override_colors/font_color", train.line.map_line.colour)
	label.text = str(train)
