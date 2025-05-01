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
			hid_label.text = "HID: " + patient["hospital_id"]
			break

	# Load workspace data
	var parser = preload("res://Results/Scripts/parse_files.gd").new()
	parser._ready()
	var workspace_data = parser.get_parsed_data()
	
	if workspace_data.size() == 0:
		print("No data to plot")
		return
		
	for data in workspace_data:
		var session_text = "Date:" + data.date
		session_list.add_item(session_text)
	
	# Prepare data for plotting
	var x_values = range(workspace_data.size())
	var axdir_values = []
	var azdir_values = []
	var txdir_values = []
	var tzdir_values = []
	var date_labels = []
	
	for data in workspace_data:
		axdir_values.append(data.axdir)
		azdir_values.append(data.azdir)
		txdir_values.append(data.txdir)
		tzdir_values.append(data.tzdir)
		date_labels.append(data.date)
	
	# Create functions for each directional value
	var f_axdir = Function.new(
		x_values, axdir_values, "Active Workspace axdir", 
		{
			color = Color("#36a2eb"),
			marker = Function.Marker.CIRCLE,
			type = Function.Type.LINE
		}
	)
	
	var f_azdir = Function.new(
		x_values, azdir_values, "Active Workspace azdir", 
		{
			color = Color("#ff6384"),
			marker = Function.Marker.CROSS,
			type = Function.Type.LINE
		}
	)
	
	var f_txdir = Function.new(
		x_values, txdir_values, "Inflated Workspace txdir", 
		{
			color = Color("#4bc0c0"),
			marker = Function.Marker.SQUARE,
			type = Function.Type.LINE
		}
	)
	
	var f_tzdir = Function.new(
		x_values, tzdir_values, "Inflated Workspace tzdir", 
		{
			color = Color("#ffcd56"),
			marker = Function.Marker.TRIANGLE,
			type = Function.Type.LINE
		}
	)
	
	# Set up chart properties
	var cp = ChartProperties.new()
	cp.colors.frame = Color("#161a1d")
	cp.colors.background = Color.TRANSPARENT
	cp.colors.grid = Color("#283442")
	cp.colors.ticks = Color("#283442")
	cp.colors.text = Color.WHITE_SMOKE
	cp.draw_bounding_box = false
	cp.show_legend = true
	cp.title = "Workspace Directional Values"
	cp.x_label = "Session Date"
	cp.y_label = "Direction Values (degrees)"
	cp.x_scale = 1
	cp.y_scale = 5
	cp.interactive = true
	# cp.x_labels = date_labels
	
	# Plot the data
	chart.plot([f_axdir, f_azdir, f_txdir, f_tzdir], cp)
	
	print("Chart created with " + str(workspace_data.size()) + " data points")

func _on_logout_pressed() -> void:
	get_tree().change_scene_to_file("res://Main_screen/main.tscn")
