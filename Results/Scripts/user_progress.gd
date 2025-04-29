#extends Control
#
#@onready var chart: Chart = $Chart
#@onready var registry = $"."
#@onready var pname_label: Label = $PName
#@onready var hid_label =$HID
#@onready var patient_db: PatientDetails = load("res://Main_screen/patient_register.tres")
#@onready var session_list: ItemList = $SessionList
#
#
#func _ready():
	#
	#var current_id = GlobalSignals.current_patient_id
	#var all_patients = patient_db.list_all_patients()
	#
	#for patient in all_patients:
		#if patient["hospital_id"] == current_id:
			#pname_label.text = "Patient: " + patient["name"]
			#hid_label.text = "ID: " + patient["hospital_id"]
			#break
	#
#
	#var parser = preload("res://Results/Scripts/parse_files.gd").new()
	#parser._ready()
	#var workspace_data = parser.get_parsed_data()
	#for data in workspace_data:
		#var session_text = "Date: " + data.date
		#session_list.add_item(session_text)
	#if workspace_data.size() == 0:
		#print("No data to plot")
		#return
		#
	#chart.plot_workspace_data(workspace_data)
#
		#
	#
	## Prepare data for plotting
	#var x_values = range(workspace_data.size())
	#var axdir_values = []
	#var azdir_values = []
	#var txdir_values = []
	#var tzdir_values = []
	#var date_labels = []
	#
	#for data in workspace_data:
		#axdir_values.append(data.axdir)
		#azdir_values.append(data.azdir)
		#txdir_values.append(data.txdir)
		#tzdir_values.append(data.tzdir)
		#date_labels.append(data.date)
	#
	## Create functions for each directional value
	#var f_axdir = Function.new(
		#x_values, axdir_values, "Active Workspace axdir", 
		#{
			#color = Color("#36a2eb"),
			#marker = Function.Marker.CIRCLE,
			#type = Function.Type.LINE
		#}
	#)
	#
	#var f_azdir = Function.new(
		#x_values, azdir_values, "Active Workspace azdir", 
		#{
			#color = Color("#ff6384"),
			#marker = Function.Marker.CROSS,
			#type = Function.Type.LINE
		#}
	#)
	#
	#var f_txdir = Function.new(
		#x_values, txdir_values, "Inflated Workspace txdir", 
		#{
			#color = Color("#4bc0c0"),
			#marker = Function.Marker.SQUARE,
			#type = Function.Type.LINE
		#}
	#)
	#
	#var f_tzdir = Function.new(
		#x_values, tzdir_values, "Inflated Workspace tzdir", 
		#{
			#color = Color("#ffcd56"),
			#marker = Function.Marker.TRIANGLE,
			#type = Function.Type.LINE
		#}
	#)
	#
	## Set up chart properties
	#var cp = ChartProperties.new()
	#cp.colors.frame = Color("#161a1d")
	#cp.colors.background = Color.TRANSPARENT
	#cp.colors.grid = Color("#283442")
	#cp.colors.ticks = Color("#283442")
	#cp.colors.text = Color.WHITE_SMOKE
	#cp.draw_bounding_box = false
	#cp.show_legend = true
	#cp.title = "Workspace Directional Values"
	#cp.x_label = "Session Date"
	#cp.y_label = "Direction Values (degrees)"
	#cp.x_scale = 1
	#cp.y_scale = 5
	#cp.interactive = true
	## cp.x_labels = date_labels
	#
	## Plot the data
	#chart.plot([f_axdir, f_azdir, f_txdir, f_tzdir], cp)
	#
	#print("Chart created with " + str(workspace_data.size()) + " data points")
#
#func _on_logout_pressed() -> void:
	#get_tree().change_scene_to_file("res://Main_screen/main.tscn")
	
	
	
	
extends Control

@onready var chart: Chart = $Chart
@onready var pname_label: Label = $PName
@onready var hid_label: Label = $HID
@onready var session_list: ItemList = $SessionList
@onready var patient_db: PatientDetails = load("res://Main_screen/patient_register.tres")

var workspace_data = []

func _ready():
	# Get patient details
	var current_id = GlobalSignals.current_patient_id
	var all_patients = patient_db.list_all_patients()
	
	for patient in all_patients:
		if patient["hospital_id"] == current_id:
			pname_label.text = "Patient: " + patient["name"]
			hid_label.text = "ID: " + patient["hospital_id"]
			break

	# Load workspace data
	var parser = preload("res://Results/Scripts/parse_files.gd").new()
	parser._ready()
	workspace_data = parser.get_parsed_data()
	
	if workspace_data.size() == 0:
		print("No data to plot")
		return
	
	# Fill session list
	for data in workspace_data:
		var session_text = "Date: " + data.date + " | Time: " + data.time
		session_list.add_item(session_text)

	# Now plot
	plot_workspace_chart()

func plot_workspace_chart():
	var x_values = range(workspace_data.size())
	var axdir_values = []
	var txdir_values = []
	var area_polygon_values = []
	
	for data in workspace_data:
		axdir_values.append(data.axdir)
		txdir_values.append(data.txdir)
		area_polygon_values.append(data.area) # assuming you have 'area' field in your JSON

	var f_axdir = Function.new(
		x_values, axdir_values, "Active Workspace", 
		{
			color = Color("#36a2eb"),
			marker = Function.Marker.CIRCLE,
			type = Function.Type.LINE
		}
	)
	
	var f_txdir = Function.new(
		x_values, txdir_values, "Training Workspace", 
		{
			color = Color("#ff6384"),
			marker = Function.Marker.SQUARE,
			type = Function.Type.LINE
		}
	)
	
	var f_area = Function.new(
		x_values, area_polygon_values, "Area of Polygon", 
		{
			color = Color("#4bc0c0"),
			marker = Function.Marker.TRIANGLE,
			type = Function.Type.LINE
		}
	)

	var cp = ChartProperties.new()
	cp.colors.frame = Color("#161a1d")
	cp.colors.background = Color.TRANSPARENT
	cp.colors.grid = Color("#283442")
	cp.colors.ticks = Color("#283442")
	cp.colors.text = Color.WHITE_SMOKE
	cp.draw_bounding_box = false
	cp.show_legend = true
	cp.title = "Patient Progress Chart"
	cp.x_label = "Sessions"
	cp.y_label = "Values"
	cp.x_scale = 1
	cp.y_scale = 5
	cp.interactive = true
	
	chart.plot([f_axdir, f_txdir, f_area], cp)

func _on_logout_pressed() -> void:
	get_tree().change_scene_to_file("res://Main_screen/main.tscn")
