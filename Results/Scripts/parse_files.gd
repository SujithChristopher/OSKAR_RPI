extends Node

var path = GlobalSignals.data_path + "//sujith"

func _ready() -> void:
	print("Parsing files in: " + path)
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() and file_name.ends_with(".json"):
				parse_workspace_file(path + "/" + file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

func parse_workspace_file(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(content)
		
		if error == OK:
			var data = json.get_data()
			print("File: " + file_path.get_file())
			
			if data.has("active_workspace") and data.has("axdir") and data.has("azdir") and \
			   data.has("inflated_workspace") and data.has("txdir") and data.has("tzdir"):
				
				print("  Active workspace:")
				print("    axdir: " + str(data["axdir"]))
				print("    azdir: " + str(data["azdir"]))
				
				print("  Inflated workspace:")
				print("    txdir: " + str(data["txdir"]))
				print("    tzdir: " + str(data["tzdir"]))
				
				# Optional: Parse the polygon string to Vector2 array if needed
				var active_poly = parse_polygon_string(data["active_workspace"])
				var inflated_poly = parse_polygon_string(data["inflated_workspace"])
				
				# Do something with the parsed polygons if needed
			else:
				print("  Missing required workspace data")
		else:
			print("  JSON Parse Error: " + str(error) + " at line " + str(json.get_error_line()))
	else:
		print("  Failed to open file: " + file_path)

func parse_polygon_string(polygon_string: String) -> Array[Vector2]:
	var result: Array[Vector2] = []
	
	# Remove the brackets and split by commas
	polygon_string = polygon_string.trim_prefix("[").trim_suffix("]")
	var points = polygon_string.split("), (")
	
	for point in points:
		# Clean up the string
		point = point.replace("(", "").replace(")", "")
		var coords = point.split(", ")
		
		if coords.size() == 2:
			var x = float(coords[0])
			var y = float(coords[1])
			result.append(Vector2(x, y))
	
	return result
