extends Node

# Constants for screen bounds and scaling

var X_SCREEN_OFFSET: int
var Y_SCREEN_OFFSET: int
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
var udp: PacketPeerUDP = PacketPeerUDP.new()
var thread_network = Thread.new()
var thread_python = Thread.new()
var thread_path_check = Thread.new()


@onready var connected: bool = false
@onready var disconnected: bool = false
@onready var reset_position: bool = false

# Paths and platform-specific variables
var interpreter_path: String
var pyscript_path: String
var pypath_checker_path : String

# Networked position
var net_x: float
var net_y: float
var net_z: float
var network_position: Vector2 = Vector2.ZERO

var quit_request:bool = false
@export var delay_time = 0.2
@onready var message_timer:Timer = Timer.new()
var _outgoing_message = "CONNECTED"
var _incoming_message: float

var patient_db: PatientDetails = load("res://Main_screen/patient_register.tres")

func _ready():
	udp.connect_to_host("127.0.0.1", 8000)
	thread_network.start(network_thread)
	thread_python.start(python_thread)

	print(MAX_X, " " + str(MAX_Y))
	X_SCREEN_OFFSET = int(screen_size.x/4)
	Y_SCREEN_OFFSET = int(screen_size.y/4)
	
	message_timer.autostart = true
	message_timer.wait_time = delay_time
	message_timer.one_shot = false
	message_timer.timeout.connect(send_dummy_packet)
	add_child(message_timer)
	GlobalSignals.SignalBus.connect(handle_quit_request)
	
	if OS.get_name() == "Windows":
		pyscript_path = "E:\\CMC\\pyprojects\\programs_rpi\\rpi_python\\stream_optimize.py"
		pypath_checker_path = "E:\\CMC\\pyprojects\\programs_rpi\\rpi_python\\file_integrity.py"
		interpreter_path = "E:\\CMC\\py_env\\venv\\Scripts\\python.exe"
	else:
		pyscript_path = "/home/sujith/Documents/programs/stream_optimize.py"
		pypath_checker_path = "/home/sujith/Documents/programs/file_integrity.py"
		interpreter_path = "/home/sujith/Documents/programs/venv/bin/python"
	
func _process(delta: float) -> void:
	match _incoming_message:
		-99.0:
			disconnected = true
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
	print(network_position)

	
func change_patient():
	_outgoing_message = 'USER:' + patient_db.current_patient_id

func send_dummy_packet():
	udp.put_packet(_outgoing_message.to_utf8_buffer())

func python_thread():
	var output = []
	print("Python thread started.")
	#OS.execute(interpreter_path, [pyscript_path], output)
	print(output)
