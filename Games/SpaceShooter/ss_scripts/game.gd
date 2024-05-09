class_name ClientNode
extends Node2D


@export var enemy_scenes: Array[PackedScene] = []
@onready var player_spawn_pos = $PlayerSpawnPos
@onready var laser_container = $LaserContainer
@onready var timer = $EnemySpawnTimer
@onready var enemy_container = $EnemyContainer
@onready var hud = $UILayer/HUD
@onready var gos = $UILayer/GameOverScreen
@onready var pb = $ParallaxBackground

@onready var laser_sound = $SFX/LaserSound
@onready var hit_sound = $SFX/HitSound
@onready var explode_sound = $SFX/ExplodeSound

var player = null
var score := 0:
	set(value):
		score = value
		hud.score = score
var high_score
var received_message
var scroll_speed = 100
var thread: Thread

var player_position = Vector2(0,0)
var player_current_position = Vector2(0,0)
var player_zero_drift = Vector2(0,0)

var udp := PacketPeerUDP.new()
var connected = false

var DIR = OS.get_executable_path().get_base_dir()
var interpreter_path = DIR.path_join("pyfiles/venv/Scripts/python.exe")
var pyscript_path = DIR.path_join("pyfiles/main.py")


var BUTTON_CLICK = true
var TERMINATE_PROCESS = false


func _ready():
	
	thread = Thread.new()
	udp.connect_to_host("127.0.0.1", 8000)
	if !OS.has_feature("standalone"):
		interpreter_path = ProjectSettings.globalize_path("res://pyfiles/venv/Scripts/python.exe")
		pyscript_path = ProjectSettings.globalize_path("res://pyfiles/main.py")
		
	thread.start(_thread_function)
	
	var save_file = FileAccess.open("user://save.data", FileAccess.READ)
	if save_file!=null:
		high_score = save_file.get_32()
	else:
		high_score = 0
		save_game()
	
	score = 0
	player = get_tree().get_first_node_in_group("player")
	assert(player!=null)
	player.global_position = player_spawn_pos.global_position
	player.laser_shot.connect(_on_player_laser_shot)
	player.killed.connect(_on_player_killed)
	
func _thread_function():
	var output = []
	var err = OS.execute(interpreter_path, [pyscript_path], output)
	print(output)
	print('inside thread function')

func save_game():
	var save_file = FileAccess.open("user://save.data", FileAccess.WRITE)
	save_file.store_32(high_score)

func _process(delta):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	elif Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()
	
	# if timer.wait_time > 0.5:
	# 	timer.wait_time -= delta*0.005
	# elif timer.wait_time < 0.5:
	# 	timer.wait_time = 0.5
	
	pb.scroll_offset.y += delta*scroll_speed
	if pb.scroll_offset.y >= 960:
		pb.scroll_offset.y = 0
		
	if BUTTON_CLICK:
		if !connected:
			udp.put_packet("ping".to_utf8_buffer())
		if udp.get_available_packet_count() > 0:
			received_message = int(udp.get_packet().get_string_from_utf8())
			player_current_position = Vector2(received_message, 0)
			connected = true
		else :
			connected = false
			
	if TERMINATE_PROCESS and BUTTON_CLICK:
		udp.put_packet("stop".to_utf8_buffer())
		
	player.position = player.position + player_current_position*-1 - player_zero_drift

func _on_player_laser_shot(laser_scene, location):
	var laser = laser_scene.instantiate()
	laser.global_position = location
	laser_container.add_child(laser)
	laser_sound.play()

func _on_enemy_spawn_timer_timeout():
	var e = enemy_scenes.pick_random().instantiate()
	e.global_position = Vector2(randf_range(50, 500), -50)
	e.killed.connect(_on_enemy_killed)
	e.hit.connect(_on_enemy_hit)
	enemy_container.add_child(e)

func _on_enemy_killed(points):
	hit_sound.play()
	score += points
	if score > high_score:
		high_score = score

func _on_enemy_hit():
	hit_sound.play()

func _on_player_killed():
	explode_sound.play()
	gos.set_score(score)
	gos.set_high_score(high_score)
	udp.put_packet("stop".to_utf8_buffer())
	save_game()
	await get_tree().create_timer(1.5).timeout
	gos.visible = true
	# thread.disconnect()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		udp.put_packet("stop".to_utf8_buffer())
		get_tree().quit() # default behavior

func _on_button_pressed():
	player_zero_drift = player_current_position

