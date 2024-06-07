extends CharacterBody2D

const SPEED = 100.0

@export var max_score = 5

var received_message
var thread: Thread
var thread2: Thread
var the_message : String

var network_position = Vector2.ZERO
var udp := PacketPeerUDP.new()
var connected = false
var DIR = OS.get_executable_path().get_base_dir()
var interpreter_path = "/home/sujith/Documents/programs/pyenv/bin/python"
var pyscript_path = DIR.path_join("pyfiles/main.py")
var udp_terminated = false
var _temp_message
var _split_message
var t_x
var t_y
var apple_present = false
var apple = preload("res://Assessment/assess_game/scenes/apple.tscn")
@onready var apple_sound = $"../apple_sound"
@onready var score_board = $"../ScoreBoard/Score"
@onready var anim = $Sprite2D
@onready var my_timer = $"../DisplayTimer"
@onready var time_display = $"../Panel/TimeSeconds"
var process
var score = 0

var rom_x_top : int
var rom_y_top : int
var rom_x_bot : int
var rom_y_bot : int

var game_over = false

func _physics_process(delta):
	if network_position != Vector2.ZERO:
		position = position.lerp(network_position, 0.2)
		# position = network_position

func udp_thread():
	
	while true:
		if udp.get_available_packet_count() > 0:
			_temp_message = udp.get_packet().get_string_from_utf8()
			udp.put_packet('connected'.to_utf8_buffer())
			if _temp_message == "stop":
				udp_terminated = true
			elif _temp_message == "none":
				pass
			else:
				_split_message = _temp_message.split(",")
				var net_x = float(_split_message[0])
				var net_y = float(_split_message[1])
				if net_x+600 < 10:
					net_x = 10
				if net_y+400 < 10:
					net_y = 10

				if net_y > 620:
					net_y = 620
				if net_x > 1120:
					net_x = 1120
				network_position = Vector2(net_x, net_y) + Vector2(600, 400)  
				connected = true

		if !apple_present and network_position != Vector2.ZERO:
			my_timer.start()
			var _apple = apple.instantiate()
			add_child(_apple)
			_apple.top_level = true
			_apple.position = Vector2(randi_range(200, 900), randi_range(200, 600))
			# _apple.position = Vector2(randi_range(rom_x_top, rom_x_bot), randi_range(rom_y_top, rom_y_bot))
			_apple.tree_exited.connect(apple_function)
			apple_present = true
		if apple_present:
			time_display.text = str(round(my_timer.time_left)) + "s"
		# move_and_slide()
		if score >= max_score:
			udp.put_packet("stop".to_utf8_buffer())
			game_over = true
				
		if udp_terminated:
			get_tree().change_scene_to_file("res://Assessment/assess_game/results.tscn")
		
func hey_there():
	print('just printing')

func _on_reach_game_ready():
	# var output2 = []
	# var rom_py_pth = r"D:\CMC\ArmBo_games\OSKAR_GAME_v3\pyfiles\rom_assessment.py"
	# interpreter_path = r"D:\CMC\py_env\venv\Scripts\python.exe"

	# OS.execute(interpreter_path, [rom_py_pth], output2)
	# var temp = output2[0].split(",")
	# print(temp)
	# rom_x_top = int(temp[0])
	# rom_y_top = int(temp[1])
	# rom_x_bot = int(temp[2])
	# rom_y_bot = int(temp[3])
	rom_x_top = 20
	rom_y_top = 20
	rom_x_bot = 1100
	rom_y_bot = 600

	if rom_y_bot > 600:
		rom_y_bot = 600

	if rom_x_bot > 1100:
		rom_x_bot = 1100

	thread = Thread.new()
	udp.connect_to_host("127.0.0.1", 8000)
	pyscript_path = "/home/sujith/Documents/programs/webcamera.py"
	thread.start(_thread_function)
	thread2 = Thread.new()
	thread2.start(udp_thread)

func apple_function():
	if score <= max_score:
		if not apple_sound == null:
			apple_sound.play()
			score += 1
			score_board.text = str(score)
			apple_present = false

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		udp.put_packet("stop".to_utf8_buffer())
		# udp.close()
		get_tree().quit() 

func _thread_function():
	var output = []
	process = OS.execute(interpreter_path, [pyscript_path], output)
	print(output)

func _on_apple_apple_eaten(value:Variant):
	apple_present = false
	score += 1
	score_board.text(str(score))

func _on_reach_game_tree_exiting():
	udp.put_packet("stop".to_utf8_buffer())
	# udp.close()
	# thread.wait_to_finish()

func _on_udp_timer_timeout():
	if !connected and !udp_terminated:
		udp.put_packet("ping".to_utf8_buffer()) 

func _on_dummy_timeout():
	if connected:
		udp.put_packet('dummy'.to_utf8_buffer())

func _on_area_2d_area_entered(area):
	anim.animation = "strike_down"
	await anim.animation_finished

func _on_area_2d_area_exited(area):
	anim.animation = "default"
