class_name Map

var nodes: Dictionary = {}
var rail_segments: Dictionary = {}
var rail_lines: Array[RailLine] = []

func getNodesBetweenNodes(a: MapNode, b: MapNode) -> Array[MapNode]:
	var between: Array[Map.MapNode] = []
	var reverse: bool = null
	var finished: bool = false
	
	for line in rail_lines:
		for segment in line.segments:
			for node in segment.nodes:
				if node.matches(a) or node.matches(b):
					between.append(node)
					if reverse != null:
						finished = true
						break
					
					# If we reach node b first, between must be reversed
					reverse = node.matches(b)
				elif reverse != null:
					between.append(node)
			
			if finished:
				break
		
		if finished:
			break
		
		# Line doesn't have all stations, clear state and try next
		if reverse != null:
			reverse = null
			between.clear()
	
	if not finished:
		return null
	
	if reverse:
		between.reverse()
	
	return between

class MapNode extends RefCounted:
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
	
	func matches(other: MapNode) -> bool:
		if self == other:
			return true
		if pos != null and pos == other.pos:
			return true
		
		if name == null || other.name == null:
			return false
		
		return name == other.name
	
	func _to_string():
		return "MapNode(id=%d, name=%s)" % [id, name]
	
	func distanceTo(other: MapNode) -> float:
		return pos.distance_to(other.pos)
	
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
