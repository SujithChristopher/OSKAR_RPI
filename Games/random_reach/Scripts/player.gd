extends CharacterBody2D

const SPEED = 100.0

@export var max_score = 500

var network_position = Vector2.ZERO

var apple_present = false
var apple = preload("res://Games/random_reach/scenes/apple.tscn")
var apple_position

@onready var apple_sound = $"../apple_sound"
@onready var score_board = $"../ScoreBoard/Score"
@onready var anim = $Sprite2D
@onready var my_timer = $"../DisplayTimer"
@onready var time_display = $"../Panel/TimeSeconds"

@onready var timer_panel = $"../TileMap/CanvasLayer/TimerSelectorPanel"
@onready var countdown_display = $"../TileMap/CanvasLayer/CountdownLabel"
@onready var play_button = $"../TileMap/CanvasLayer/TimerSelectorPanel/VBoxContainer/HBoxContainer/PlayButton"
@onready var close_button = $"../TileMap/CanvasLayer/TimerSelectorPanel/VBoxContainer/HBoxContainer/CloseButton"
@onready var countdown_timer = $"../TileMap/CanvasLayer/CountdownTimer"
@onready var game_over_label = $"../TileMap/CanvasLayer/GameOverLabel"
@onready var add_one_btn = $"../TileMap/CanvasLayer/TimerSelectorPanel/HBoxContainer/AddOneButton"
@onready var add_five_btn = $"../TileMap/CanvasLayer/TimerSelectorPanel/HBoxContainer/AddFiveButton"
@onready var sub_one_btn = $"../TileMap/CanvasLayer/TimerSelectorPanel/HBoxContainer2/SubOneButton"
@onready var sub_five_btn = $"../TileMap/CanvasLayer/TimerSelectorPanel/HBoxContainer2/SubFiveButton"
@onready var logout_button = $"../TileMap/CanvasLayer/GameOverLabel/LogoutButton"
@onready var retry_button = $"../TileMap/CanvasLayer/GameOverLabel/RetryButton"
@onready var time_label := $"../TileMap/CanvasLayer/TimerSelectorPanel/TimeSelector"


var process
var score = 0
var zero_offset = Vector2.ZERO
var rom_x_top : int
var rom_y_top : int
var rom_x_bot : int
var rom_y_bot : int
var game_over = false

var countdown_time = 0
var countdown_active = false
var current_time := 0

@onready var adapt_toggle:bool = false
@onready var game_log_file
@onready var log_timer := Timer.new()

func _ready() -> void:
	network_position = Vector2.ZERO
	game_log_file = Manager.create_game_log_file('RandomReach', GlobalSignals.current_patient_id)
	game_log_file.store_csv_line(PackedStringArray(['time','position_x', 'position_y', 'network_position_x', 'network_position_y', 'scaled_network_position_x', 'scaled_network_position_y']))
	log_timer.wait_time = 0.02 
	log_timer.autostart = true 
	log_timer.timeout.connect(_on_log_timer_timeout)
	add_child(log_timer)
	print("Timer Panel Found:", timer_panel)
	update_label()
	timer_panel.visible = true
	game_over_label.visible = false
	play_button.pressed.connect(_on_play_pressed)
	countdown_timer.timeout.connect(_on_CountdownTimer_timeout)
	close_button.pressed.connect(_on_close_pressed)
	add_one_btn.pressed.connect(_on_add_one_pressed)
	add_five_btn.pressed.connect(_on_add_five_pressed)
	sub_one_btn.pressed.connect(_on_sub_one_pressed)
	sub_five_btn.pressed.connect(_on_sub_five_pressed)
	logout_button.pressed.connect(_on_logout_button_pressed)
	retry_button.pressed.connect(_on_retry_button_pressed)
	game_over_label.hide()
	
	
func update_label():
	time_label.text = str(current_time) + " sec"
	var minutes = countdown_time / 60
	var seconds = countdown_time % 60
	time_label.text = "%2d m" % [minutes]

func _on_add_one_pressed():
	if countdown_time + 60 <= 2700:
		countdown_time += 60
	else:
		countdown_time = 2700
	_update_time_display()
	countdown_display.visible = true
	update_label()

func _on_add_five_pressed():
	if countdown_time + 300 <= 2700:
		countdown_time += 300
	else:
		countdown_time = 2700
	_update_time_display()
	countdown_display.visible = true
	update_label()

func _on_sub_one_pressed():
	if countdown_time >= 60:
		countdown_time -= 60
	else:
		countdown_time = 0
	_update_time_display()
	update_label()

func _on_sub_five_pressed():
	if countdown_time >= 300:
		countdown_time -= 300
	else:
		countdown_time = 0
	_update_time_display()
	update_label()
	

func _on_play_pressed():
	GlobalTimer.start_timer()
	timer_panel.visible = false
	add_one_btn.hide()
	add_five_btn.hide()
	sub_one_btn.hide()
	sub_five_btn.hide()
	start_game_with_timer()

func _on_close_pressed():
	timer_panel.visible = false
	add_one_btn.hide()
	add_five_btn.hide()
	sub_one_btn.hide()
	sub_five_btn.hide()    
	countdown_display.hide()
	start_game_without_timer()

func start_game_with_timer():
	countdown_active = true
	countdown_timer.wait_time = 1.0 # tick every second
	countdown_timer.start()
	_update_time_display()

func _on_CountdownTimer_timeout():
	if countdown_active:
		countdown_time -= 1
		countdown_display.text = "%02d:%02d" % [countdown_time / 60, countdown_time % 60]
		_update_time_display()
		if countdown_time <= 0:
			countdown_active = false
			countdown_timer.stop()
			show_game_over()

func _update_time_display():
	var minutes = countdown_time / 60
	var seconds = countdown_time % 60
	countdown_display.text = "Time Left: %02d:%02d" % [minutes, seconds]
	
func show_game_over():
	print("Game Over!")
	GlobalTimer.stop_timer()
	game_over_label.visible = true
	
func start_game_without_timer():
	countdown_active = false
	GlobalTimer.start_timer()
	
func _on_logout_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Main_screen/select_game.tscn")

func _on_retry_button_pressed():
	get_tree().paused = false
	game_over_label.hide()
	timer_panel.show()
	add_one_btn.show()
	add_five_btn.show()
	sub_one_btn.show()
	sub_five_btn.show()

func _physics_process(delta):
	if adapt_toggle:
		network_position = GlobalScript.scaled_network_position
	else:
		network_position = GlobalScript.network_position
		
		
	if network_position != Vector2.ZERO:
		network_position = network_position - zero_offset  + Vector2(100, 50) 
		#network_position = network_position - zero_offset - Vector2(500, 200)
		network_position.clamp(Vector2.ZERO, Vector2(DisplayServer.window_get_size()) - Vector2(50, 50))
		position = position.lerp(network_position, 0.8)
		#position = network_position 
		
	if !apple_present and network_position != Vector2.ZERO:
		my_timer.start()
		var _apple = apple.instantiate()
		add_child(_apple)
		_apple.top_level = true
		
		#Spawning based on polygon
		if adapt_toggle:
			while true:
				apple_position = Vector2(randi_range(200, 900), randi_range(200, 600))
				if Geometry2D.is_point_in_polygon(apple_position, GlobalSignals.inflated_workspace):
					break
			_apple.position = apple_position
		else:
			_apple.position = Vector2(randi_range(200, 900), randi_range(200, 600))
		
		_apple.tree_exited.connect(apple_function)
		apple_present = true
	if apple_present:
		time_display.text = str(round(my_timer.time_left)) + "s"
	
		

func _on_log_timer_timeout():
	if game_log_file:
		game_log_file.store_csv_line(PackedStringArray([Time.get_unix_time_from_system(),str(position.x), str(position.y), str(network_position.x), str(network_position.y), str(GlobalScript.scaled_network_position.x), str(GlobalScript.scaled_network_position.y)]))

func _on_reach_game_ready():
	rom_x_top = 20
	rom_y_top = 20
	rom_x_bot = 1100
	rom_y_bot = 600

	if rom_y_bot > 600:
		rom_y_bot = 600

	if rom_x_bot > 1100:
		rom_x_bot = 1100
		

func apple_function():
	if score <= max_score:
		if not apple_sound == null:
			#apple_sound.play()
			score += 1
			score_board.text = str(score)
			apple_present = false

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		game_log_file.close()


func _on_apple_apple_eaten(value:Variant):
	apple_present = false
	score += 1
	score_board.text(str(score))

func _on_reach_game_tree_exiting():
	pass

func _on_udp_timer_timeout():
	pass

func _on_dummy_timeout():
	pass

func _on_area_2d_area_entered(area):
	anim.animation = "sheep"
	await anim.animation_finished

func _on_area_2d_area_exited(area):
	anim.animation = "sheep"


func _on_zero_pressed() -> void:
	zero_offset = network_position

func _on_button_pressed() -> void:
	get_tree().quit() 


func _on_logout_pressed() -> void:
	GlobalTimer.stop_timer()
	get_tree().change_scene_to_file("res://Main_screen/select_game.tscn")


func _on_adapt_rom_toggled(toggled_on: bool) -> void:
	if toggled_on:
		adapt_toggle = true
	else:
		adapt_toggle = false
		
