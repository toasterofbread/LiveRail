extends RefCounted
class_name RailSegment

var id: int
var names: Dictionary
var nodes: Array[Map.MapNode]
var node_refs: Array[int]

func _init(id: int, names: Dictionary, node_refs: Array[int] = []):
	self.id = id
	self.names = names
	self.node_refs = node_refs

func _to_string():
	return "RailSegment(names=" + str(names) + ")"
