class_name MapTimetableBridge

class LineInfo:
	var timetable_line_name: String
	var direction: bool
	
	func _init(timetable_line_name: String, direction: bool):
		self.timetable_line_name = timetable_line_name
		self.direction = direction

	func _to_string():
		return "LineInfo(timetable_line_name=%s, direction=%s)" % [timetable_line_name, str(direction)]

static var JA_LINE_NAMES: Dictionary = {
	"阪急電鉄神戸本線 (神戸三宮=>大阪梅田)": LineInfo.new("阪急神戸線", true),
	"阪急電鉄神戸本線 (大阪梅田=>神戸三宮)": LineInfo.new("阪急神戸線", false),
	
	"阪急電鉄宝塚本線 (宝塚=>大阪梅田)": LineInfo.new("阪急宝塚線", true),
	"阪急電鉄宝塚本線 (大阪梅田=>宝塚)": LineInfo.new("阪急宝塚線", false),
	
	"阪急電鉄京都線 (京都河原町=>大阪梅田)": LineInfo.new("阪急京都線", true),
	"阪急電鉄京都線 (大阪梅田=>京都川原町)": LineInfo.new("阪急京都線", false)
}

static func getMapLineInfo(line: RailLine) -> LineInfo:
	var ja_name: String = line.names.get("ja")
	if ja_name == null:
		return null
	
	return JA_LINE_NAMES.get(ja_name)
