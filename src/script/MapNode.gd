extends RefCounted
class_name MapNode

var id: int
var pos: Vector2
var name: String = null
var names: Dictionary = {}

func _init(id: int, lat: float, lon: float):
	self.id = id
	self.pos = Vector2(
		lat - 340000000,
		lon - 1350000000
	)

func _to_string():
	return "MapNode(id=%d, name=%s)" % [id, name]

static func parse(parser: XMLParser) -> MapNode:
	var node: MapNode = MapNode.new(
		int(parser.get_named_attribute_value("id")),
		float(parser.get_named_attribute_value("lat").replace(".", "")),
		float(parser.get_named_attribute_value("lon").replace(".", ""))
	)
	
	var prev_offset: int = parser.get_node_offset()
	while parser.read() != ERR_FILE_EOF:
		match parser.get_node_type():
			XMLParser.NODE_ELEMENT_END:
				break
			XMLParser.NODE_ELEMENT:
				pass
			_:
				continue
		
		if parser.get_node_name() != "tag":
			break
		
		prev_offset = parser.get_node_offset()
		
		var key: String = parser.get_named_attribute_value("k")
		var value: String = parser.get_named_attribute_value("v")
		
		match key:
			"name":
				node.name = value
			_:
				if key.begins_with("name:"):
					node.names[key.substr(5)] = value
	
	parser.seek(prev_offset)
	return node
