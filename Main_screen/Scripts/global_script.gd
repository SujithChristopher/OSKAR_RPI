extends Node

# Constants for screen bounds and scaling

var X_SCREEN_OFFSET: int
var Y_SCREEN_OFFSET: int
@export var PLAYER_POS_SCALER: int = 15 * 100

var MIN_X: int = 10
var MAX_X: int
var MIN_Y: int = 10
var MAX_Y: int

var screen_size: Vector2i

# UDP and threading
var udp: PacketPeerUDP = PacketPeerUDP.new()
var thread_network = Thread.new()
var thread_python = Thread.new()
var connected: bool = false

# Paths and platform-specific variables
var interpreter_path: String
var pyscript_path: String

# Networked position
var net_x: float
var net_y: float
var net_z: float
var network_position: Vector2 = Vector2.ZERO

func _ready():
	udp.connect_to_host("127.0.0.1", 8000)
	thread_network.start(network_thread)
	thread_python.start(python_thread)
	
	screen_size = get_window().size
	MAX_X = int(screen_size.x - screen_size.x * .15)
	MAX_Y = int(screen_size.y - screen_size.y * .15)
	X_SCREEN_OFFSET = int(screen_size.x/2)
	Y_SCREEN_OFFSET = int(screen_size.y/2)

func network_thread():
	while true:
		if udp.get_available_packet_count() > 0:
			handle_udp_packet()
		else:
			send_dummy_packet()

func handle_udp_packet():
	var packet = udp.get_packet()
	var my_floats = PackedByteArray(packet).to_float32_array()
	udp.put_packet("connected".to_utf8_buffer())

	net_x = clamp(my_floats[1]*PLAYER_POS_SCALER + X_SCREEN_OFFSET, MIN_X, MAX_X)
	net_y = clamp(my_floats[2]*PLAYER_POS_SCALER + Y_SCREEN_OFFSET, MIN_Y, MAX_Y)
	net_z = my_floats[3]

	network_position = Vector2(net_x, net_y)
	connected = true

func send_dummy_packet():
	udp.put_packet("dummy".to_utf8_buffer())

func python_thread():
	var output = []
	print("Python thread started.")
	if OS.get_name() == "Windows":
		pyscript_path = "E:\\CMC\\pyprojects\\programs_rpi\\rpi_python\\stream_optimize.py"
		interpreter_path = "E:\\CMC\\py_env\\venv\\Scripts\\python.exe"
	else:
		pyscript_path = "/home/sujith/Documents/programs/stream_optimize.py"
		interpreter_path = "/home/sujith/Documents/programs/venv/bin/python"

	OS.execute(interpreter_path, [pyscript_path], output)
	print(output)
