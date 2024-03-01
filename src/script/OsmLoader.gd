extends RefCounted
class_name OsmLoader

var map: Map = Map.new()

func parseNode(parser: XMLParser):
	var node: Map.MapNode = Map.MapNode.parse(parser)
	map.nodes[node.id] = node

func parseWay(parser: XMLParser):
	var names: Dictionary = {}
	var railway: String = null
	var rail_nodes: Array[int] = []
	var id: int = int(parser.get_named_attribute_value("id"))
	
	while parser.read() != ERR_FILE_EOF:
		match parser.get_node_type():
			XMLParser.NODE_ELEMENT_END:
				break
			XMLParser.NODE_ELEMENT:
				pass
			_:
				continue
		
		var subnode_name: String = parser.get_node_name()
		if subnode_name == "nd":
			rail_nodes.append(int(parser.get_named_attribute_value("ref")))
			continue
		
		if subnode_name != "tag" || parser.get_node_type() != XMLParser.NODE_ELEMENT:
			continue
		
		var key: String = parser.get_named_attribute_value_safe("k")
		var value: String = parser.get_named_attribute_value_safe("v")
		
		if key.begins_with("name:"):
			names[key.substr(5)] = value
			continue
		
		match key:
			"railway":
				railway = value
	
	if railway != null:
		map.rail_segments[id] = RailSegment.new(id, names, rail_nodes)

func parseRelation(parser: XMLParser):
	var rail_line: RailLine = RailLine.new()
	var is_railway: bool = false
	
	while parser.read() != ERR_FILE_EOF:
		match parser.get_node_type():
			XMLParser.NODE_ELEMENT_END:
				break
			XMLParser.NODE_ELEMENT:
				pass
			_:
				continue
		
		var subnode_name: String = parser.get_node_name()
		if subnode_name == "member":
			var member_type: String = parser.get_named_attribute_value("type")
			var member_ref: int = int(parser.get_named_attribute_value("ref"))
			
			match member_type:
				"node":
					if parser.get_named_attribute_value("role") == "stop":
						rail_line.station_refs.append(member_ref)
				"way":
					rail_line.segment_refs.append(member_ref)
		
		elif subnode_name == "tag":
			var key: String = parser.get_named_attribute_value_safe("k")
			var value: String = parser.get_named_attribute_value_safe("v")
			
			if key.begins_with("name:"):
				rail_line.names[key.substr(5)] = value
				continue
			elif key.begins_with("operator:"):
				rail_line.operator_names[key.substr(9)] = value
			elif key == "wikipedia":
				rail_line.wikipedia_ref = value
			elif key == "colour":
				rail_line.colour = Color.from_string(value, Color.RED)
			elif key == "route":
				if value == "train":
					is_railway = true
	
	if not is_railway:
		return
	
	map.rail_lines.append(rail_line)

func loadOsmFile(file_path: String):
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	
	var parser = XMLParser.new()
	parser.open(file_path)
	
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() != XMLParser.NODE_ELEMENT:
			continue
		
		match parser.get_node_name():
			"node":
				parseNode(parser)
			"way":
				parseWay(parser)
			"relation":
				parseRelation(parser)
	
	for segment in map.rail_segments.values():
		for node in segment.node_refs:
			segment.nodes.append(map.nodes[node])
	
	for line in map.rail_lines:
		for segment in line.segment_refs:
			if segment in map.rail_segments:
				line.segments.append(map.rail_segments[segment])
		
		for station in line.station_refs:
			if station in map.nodes:
				line.stations.append(map.nodes[station])
