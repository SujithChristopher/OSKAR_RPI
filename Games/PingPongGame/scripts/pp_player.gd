extends CharacterBody2D
const SPEED = 100.0
var thread: Thread
var udp_terminated: bool = false
var player_position = Vector2(0,0)
var player_current_position = Vector2(0,0)
var player_zero_drift = Vector2(0,0)
var _temp_message
var _split_message
var network_position = Vector2.ZERO
var net_x = 0
var udp := PacketPeerUDP.new()
var connected = false
var DIR = OS.get_executable_path().get_base_dir()
var interpreter_path = DIR.path_join("pyfiles/venv/Scripts/python.exe")
var pyscript_path = DIR.path_join("pyfiles/main.py")


@export var speed = 200

func _physics_process(delta):
	if udp.get_available_packet_count() > 0:
		_temp_message = udp.get_packet().get_string_from_utf8()
		udp.put_packet('connected'.to_utf8_buffer())
		if _temp_message == "stop":
			udp_terminated = true
		elif _temp_message == "none":
			pass
		else:
			_split_message = _temp_message.split(",")
			var net_x = int(_split_message[0])
			var net_y = int(_split_message[1])
			network_position = Vector2(net_x, 0) * 25 + Vector2(200, 500)  
			connected = true
			
	if network_position != Vector2.ZERO:
		position = position.lerp(network_position, 0.2)
		
	position.y = 600
	move_and_slide()

func _on_ready():
	thread = Thread.new()
	udp.connect_to_host("127.0.0.1", 8000)
	if !OS.has_feature("standalone"):
		interpreter_path = r"D:\CMC\py_env\venv\Scripts\python.exe"
		pyscript_path = ProjectSettings.globalize_path("res://pyfiles/yolo_3marker.py")		
	interpreter_path = r"D:\CMC\py_env\venv\Scripts\python.exe"
	thread.start(_thread_function)
	
func _thread_function():
	var output = []
	OS.execute(interpreter_path, [pyscript_path], output)
	print(output)
	
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		udp.put_packet("stop".to_utf8_buffer())
		udp.close()
		print('closed')
		get_tree().quit() 

func _on_timer_timeout():
	if !connected and !udp_terminated:
		udp.put_packet("ping".to_utf8_buffer()) 

func _on_dummy_timeout():
	if connected:
		udp.put_packet('dummy'.to_utf8_buffer())
