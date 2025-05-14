extends Node

# Constants for screen bounds and scaling
var current_date: String = ""
var session_id: int = 1
var trial_counts := {} 
var X_SCREEN_OFFSET: int
var Y_SCREEN_OFFSET: int

var current_score: int = 0
var json = JSON.new()
var path = "res://debug.json"

@export var PLAYER_POS_SCALER_X: int = 15 * 100
@export var PLAYER_POS_SCALER_Y: int = 15 * 100

var screen_size = DisplayServer.screen_get_size()
var MIN_X: int = 10
var MAX_X: int = int(screen_size.x - screen_size.x * .15)
var MIN_Y: int = 10
var MAX_Y: int = int(screen_size.y - screen_size.y * .15)

var clamp_vector_x = Vector2(MIN_X, MIN_Y)
var clamp_vector_y = Vector2(MAX_X, MAX_Y)

# UDP and threading
@onready var udp: PacketPeerUDP = PacketPeerUDP.new()
@onready var thread_network = Thread.new()
@onready var thread_python = Thread.new()
@onready var thread_path_check = Thread.new()

@onready var connected: bool = false
@onready var disconnected: bool = false
@onready var reset_position: bool = false

# Paths and platform-specific variables
@onready var interpreter_path: String
@onready var pyscript_path: String
@onready var pypath_checker_path : String
@export var endgame:bool = false

# Networked position
var net_x: float
var net_y: float
var net_z: float
var network_position: Vector2 = Vector2.ZERO

# scaled position
var scaled_x: float
var scaled_y: float
var scaled_z: float
var scaled_network_position: Vector2 = Vector2.ZERO

var quit_request:bool = false
@export var delay_time = 0.1
@onready var message_timer:Timer = Timer.new()
var _outgoing_message = "CONNECTED"
var _incoming_message: float

var patient_db: PatientDetails = load("res://Main_screen/patient_register.tres")
@onready var debug:bool

func _ready():
	
	debug = JSON.parse_string(FileAccess.get_file_as_string(path))['debug']
	
	udp.connect_to_host("127.0.0.1", 8000)
	thread_python.start(python_thread, Thread.PRIORITY_HIGH)
	thread_network.start(network_thread)
	

	print(MAX_X, " " + str(MAX_Y))
	X_SCREEN_OFFSET = int(screen_size.x/4)
	Y_SCREEN_OFFSET = int(screen_size.y/4)
	
	message_timer.autostart = true
	message_timer.wait_time = delay_time
	message_timer.one_shot = false
	message_timer.timeout.connect(send_dummy_packet)
	add_child(message_timer)
	GlobalSignals.SignalBus.connect(handle_quit_request)
	get_tree().set_auto_accept_quit(false)
	
	if OS.get_name() == "Windows":
		pyscript_path = "E:\\CMC\\pyprojects\\programs_rpi\\rpi_python\\stream_optimize.py"
		pypath_checker_path = "E:\\CMC\\pyprojects\\programs_rpi\\rpi_python\\file_integrity.py"
		interpreter_path = "E:\\CMC\\py_env\\venv\\Scripts\\python.exe"
	else:
		pyscript_path = "/home/sujith/Documents/programs/stream_optimize.py"
		pypath_checker_path = "/home/sujith/Documents/programs/file_integrity.py"
		interpreter_path = "/home/sujith/Documents/programs/venv/bin/python"
	
func _process(_delta: float) -> void:
	if not thread_python.is_alive() and not endgame and not debug:
		thread_python = Thread.new()
		thread_python.start(python_thread, Thread.PRIORITY_HIGH)
		
	match _incoming_message:
		-99.0:
			disconnected = true
			endgame = true
			thread_network.wait_to_finish()
			thread_python.wait_to_finish()
			get_tree().quit()
		2.0:
			connected = true
		5.0:
			reset_position = true

func _path_checker():
	var output = []
	OS.execute(interpreter_path, [pypath_checker_path], output)
	print(output)

func network_thread():
	while true:
		if udp.get_available_packet_count() > 0:
			handle_udp_packet()
		if disconnected:
			break
func handle_quit_request():
	_outgoing_message = "STOP"
	udp.put_packet(_outgoing_message.to_utf8_buffer())

func handle_udp_packet():
	var packet = udp.get_packet()
	var my_floats = PackedByteArray(packet).to_float32_array()

	udp.put_packet(_outgoing_message.to_utf8_buffer())

	_incoming_message = my_floats[0]
	
	net_x = my_floats[1]*PLAYER_POS_SCALER_X + X_SCREEN_OFFSET
	net_y = my_floats[2]*PLAYER_POS_SCALER_Y + Y_SCREEN_OFFSET
	net_z = my_floats[3]*PLAYER_POS_SCALER_Y + Y_SCREEN_OFFSET
	network_position = Vector2(net_x, net_z)
	
	scaled_x = my_floats[1]*PLAYER_POS_SCALER_X * GlobalSignals.global_scalar_x + X_SCREEN_OFFSET
	scaled_y = my_floats[2]*PLAYER_POS_SCALER_Y * GlobalSignals.global_scalar_y + Y_SCREEN_OFFSET
	scaled_z = my_floats[3]*PLAYER_POS_SCALER_Y * GlobalSignals.global_scalar_y + Y_SCREEN_OFFSET
	scaled_network_position = Vector2(scaled_x, scaled_z)
	
func change_patient():
	_outgoing_message = 'USER:' + patient_db.current_patient_id

func send_dummy_packet():
	udp.put_packet(_outgoing_message.to_utf8_buffer())

func python_thread():
	if not debug:
		var output = []
		print("Python thread started.")
		OS.execute(interpreter_path, [pyscript_path], output)
		print(output)
	if debug:
		print("Debugging...")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		endgame = true
		handle_quit_request()
		thread_python.wait_to_finish()
		get_tree().quit()
		
func get_date_string() -> String:
	var time = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [time.year, time.month, time.day]

func start_new_session():
	var today = get_date_string()
	if today != current_date:
		current_date = today
		session_id = 1
	else:
		session_id += 1
	trial_counts.clear()

func get_next_trial_id(game_name: String) -> int:
	if not trial_counts.has(game_name):
		trial_counts[game_name] = 1
	else:
		trial_counts[game_name] += 1
	return trial_counts[game_name]


#TODO: change this to file sorting functions and use for loops for finishing the job
func get_top_score_for_game(game_name: String, p_id: String) -> int:
	var top_score := 0
	var file_path = GlobalSignals.data_path + "/" + p_id + "/GameData/" + game_name + "_scores.csv"

	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		for i in range(10000):  # limit to prevent infinite loop
			if file.eof_reached():
				break
			var line = file.get_line()
			if line.is_valid_int():
				var score = int(line)
				if score > top_score:
					top_score = score
		file.close()

	return top_score
