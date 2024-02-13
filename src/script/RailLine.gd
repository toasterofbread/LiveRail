extends RefCounted
class_name RailLine

var names: Dictionary = {}
var operator_names: Dictionary = {}
var colour: Color = null
var wikipedia_ref: String

var segment_refs: Array[int] = []
var segments: Array[RailSegment] = []

var station_refs: Array[int] = []
var stations: Array[MapNode] = []
