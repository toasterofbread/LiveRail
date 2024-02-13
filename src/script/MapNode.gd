extends RefCounted
class_name MapNode

var id: int
var pos: Vector2

func _init(id: int, lat: float, lon: float):
	self.id = id
	self.pos = Vector2(
		lat - 340000000,
		lon - 1350000000
	)

func _to_string():
	return "MapNode(id=" + str(id) + ")"

static func parse(parser: XMLParser) -> MapNode:
	return MapNode.new(
		int(parser.get_named_attribute_value("id")),
		float(parser.get_named_attribute_value("lat").replace(".", "")),
		float(parser.get_named_attribute_value("lon").replace(".", ""))
	)
