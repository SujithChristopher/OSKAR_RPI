extends Control

var game_running : bool
var game_over : bool
var scroll = 0
var score = 0
const SCROLL_SPEED : int = 2
var screen_size : Vector2i
var ground_height : int
var pipes : Array
const PIPE_DELAY : int = 100
const PIPE_RANGE : int = 200

var received_message
var thread: Thread

var network_position = Vector2.ZERO
var udp := PacketPeerUDP.new()
var connected = false
var DIR = OS.get_executable_path().get_base_dir()
var interpreter_path = DIR.path_join("pyfiles/venv/Scripts/python.exe")
var pyscript_path = DIR.path_join("pyfiles/yolo_3marker.py")
var udp_terminated:bool = false
var _temp_message
var _split_message
var t_x
var t_y
@onready var player = $Bird
@export var pipe_scene : PackedScene
@onready var score_label = $ScoreLabel
# Called when the node enters the scene tree for the first time.

func _ready():
	screen_size = get_window().size
	ground_height = $ground.get_node("Sprite2D").texture.get_height()
	$PipeTimer.start()
	thread = Thread.new()
	udp.connect_to_host("127.0.0.1", 8000)
	#if !OS.has_feature("standalone"):
		#pyscript_path = ProjectSettings.globalize_path("res://pyfiles/yolo_3marker.py")		
	pyscript_path = r"D:\CMC\ArmBo_games\OSKAR_GAME_v3\pyfiles\yolo_3marker.py"
	interpreter_path = r"D:\CMC\py_env\venv\Scripts\python.exe"
	thread.start(_thread_function)


func _process(delta):
	scroll += SCROLL_SPEED
	if scroll >= screen_size.x:
		scroll = 0
	$ground.position.x = -scroll + 1152
	for pipe in pipes:
		pipe.position.x -= SCROLL_SPEED
		
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
			network_position = Vector2(0, net_y) * 25 + Vector2(200, 400)  
			connected = true
			
	if network_position != Vector2.ZERO:
		player.position = player.position.lerp(network_position, 0.2)
	
func generate_pipes():
	var pipe = pipe_scene.instantiate()
	pipe.position.x = screen_size.x + PIPE_DELAY
	pipe.position.y = (screen_size.y - ground_height) / 2  + randi_range(-PIPE_RANGE, PIPE_RANGE)
	pipe.scored.connect(scored)
	add_child(pipe)
	pipes.append(pipe)

func scored():
	score += 1
	score_label.text = "Score "+ str(score)

func _on_pipe_timer_timeout():
	generate_pipes() # Replace with function body.
	
func _thread_function():
	var output = []
	OS.execute(interpreter_path, [pyscript_path], output)
	print(output)

func _on_timer_timeout():
	if !connected and !udp_terminated:
		udp.put_packet("ping".to_utf8_buffer()) 

func _on_dummy_timeout():
	if connected:
		udp.put_packet('dummy'.to_utf8_buffer())
