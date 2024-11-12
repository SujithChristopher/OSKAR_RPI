extends Node2D

signal thread_id
@onready var _lines := $Lines

var received_message
var thread: Thread
var the_message : String
var network_position = Vector2.ZERO
var udp := PacketPeerUDP.new()
var connected = false
var DIR = OS.get_executable_path().get_base_dir()
var interpreter_path = DIR.path_join("pyfiles/venv/Scripts/python.exe")
var pyscript_path = DIR.path_join("pyfiles/main.py")
var udp_terminated = false
var _temp_message
var _split_message
var t_x
var t_y
var process
var _presssed = false
var _current_line : Line2D
var start_drawing : bool

var message = 'connected'

func _process(delta):

	if udp.get_available_packet_count() > 0:
		_temp_message = udp.get_packet().get_string_from_utf8()
		udp.put_packet(message.to_utf8_buffer())

		if _presssed:
			message = 'close'

		if _temp_message == 'saved':
			message = 'connect'

		if _temp_message == "starting":
			start_drawing = true

		if _temp_message == "stop":
			udp_terminated = true

		elif _temp_message == "none":
			pass

		elif _temp_message == "close":
			thread_id.emit(thread.get_id())
			get_tree().change_scene_to_file("res://Games/assess_game/reach.tscn")

		else:
			_split_message = _temp_message.split(",")
			var net_x = float(_split_message[0])
			var net_y = float(_split_message[1])
			network_position = Vector2(net_x, net_y) + Vector2(600, 400)  
			connected = true
			
	if network_position != Vector2.ZERO and start_drawing:
		_current_line.width = 5
		_current_line.default_color = Color.RED
		_current_line.add_point(network_position)


func _on_ready():
	_current_line = Line2D.new()
	_current_line.add_point(Vector2(600, 400))

	_lines.add_child(_current_line)

	thread = Thread.new()
	udp.connect_to_host("127.0.0.1", 8000)
	pyscript_path = r"D:\CMC\ArmBo_games\OSKAR_GAME_v3\pyfiles\rom_getdata.py"
	interpreter_path = r"D:\CMC\py_env\venv\Scripts\python.exe"
	thread.start(_thread_function)
	

func _thread_function():
	var output = []
	process = OS.execute(interpreter_path, [pyscript_path], output)
	print(output)
	

func _on_udp_timer_timeout():
	if !connected and !udp_terminated:
		udp.put_packet("ping".to_utf8_buffer()) 

func _on_dummy_timer_timeout():
	if connected:
		udp.put_packet('dummy'.to_utf8_buffer())

func _on_button_pressed():
	_presssed = true


func _on_set_orgin_pressed():
	message = 'set_orgin'

func _on_start_pressed():
	message = 'start'
