extends CharacterBody2D
var network_position = Vector2.ZERO
var zero_offset = Vector2.ZERO

var countdown_time = 0
var countdown_active = false
var current_time := 0
var game_started := false
var is_paused = false
var pause_state = 1


@export var speed = 200
@onready var adapt_toggle:bool = false
@onready var game_log_file
@onready var log_timer := Timer.new()
@onready var ball = $"../Ball"
@onready var timer_panel = $"../CanvasLayer/TimerSelectorPanel"
@onready var countdown_display = $"../CanvasLayer/CountdownLabel"
@onready var play_button = $"../CanvasLayer/TimerSelectorPanel/VBoxContainer/HBoxContainer/PlayButton"
@onready var close_button = $"../CanvasLayer/TimerSelectorPanel/VBoxContainer/HBoxContainer/CloseButton"
@onready var countdown_timer = $"../CanvasLayer/CountdownTimer"
@onready var game_over_label = $"../CanvasLayer/GameOverLabel"
@onready var add_one_btn =$"../CanvasLayer/TimerSelectorPanel/HBoxContainer/AddOneButton"
@onready var add_five_btn =$"../CanvasLayer/TimerSelectorPanel/HBoxContainer/AddFiveButton"
@onready var sub_one_btn = $"../CanvasLayer/TimerSelectorPanel/HBoxContainer2/SubOneButton"
@onready var sub_five_btn =$"../CanvasLayer/TimerSelectorPanel/HBoxContainer2/SubFiveButton"
@onready var logout_button = $"../CanvasLayer/GameOverLabel/LogoutButton"
@onready var retry_button = $"../CanvasLayer/GameOverLabel/RetryButton"
@onready var time_label := $"../CanvasLayer/TimeSelector"
@onready var pause_button = $"../CanvasLayer/PauseButton"
@onready var top_score_label = $"../CanvasLayer/TextureRect/TopScoreLabel"


func _physics_process(delta):
	
	if not game_started:
		return
	if adapt_toggle:
		network_position = GlobalScript.scaled_network_position
	else:
		network_position = GlobalScript.network_position

	if network_position != Vector2.ZERO:
		network_position = network_position - zero_offset  + Vector2(600, 200)  
		position = position.lerp(network_position, 0.8)
	
	position.y = 600

func _on_ready():
	
	game_log_file = Manager.create_game_log_file('PingPong', GlobalSignals.current_patient_id)
	game_log_file.store_csv_line(PackedStringArray(['score','Epochtime','ball_x','ball_y','position_x', 'position_y', 'network_position_x', 'network_position_y', 'scaled_network_position_x', 'scaled_network_position_y']))
	log_timer.wait_time = 0.02 # 1 second
	log_timer.autostart = true # start timer when added to a scene
	log_timer.timeout.connect(_on_log_timer_timeout)
	add_child(log_timer)
	update_label()
	game_started = true
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
	pause_button.pressed.connect(_on_PauseButton_pressed)
	game_over_label.hide()
	countdown_display.hide()
	var top = GlobalScript.get_top_score_for_game("PingPong", GlobalSignals.current_patient_id)
	top_score_label.text = str(top)
	

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
	ball.game_started = true
	add_one_btn.hide()
	add_five_btn.hide()
	sub_one_btn.hide()
	sub_five_btn.hide()
	start_game_with_timer()
	time_label.hide()

func _on_close_pressed():
	timer_panel.visible = false
	ball.game_started = true
	add_one_btn.hide()
	add_five_btn.hide()
	sub_one_btn.hide()
	sub_five_btn.hide()    
	countdown_display.hide()
	start_game_without_timer()
	time_label.hide()

func start_game_with_timer():
	countdown_active = true
	countdown_timer.wait_time = 1.0 
	countdown_timer.start()
	_update_time_display()
	
func start_game_without_timer():
	game_started = true
	countdown_active = false
	GlobalTimer.start_timer()
	
func _on_PauseButton_pressed():
	if is_paused:
		GlobalTimer.resume_timer()
		countdown_timer.start()
		ball.game_started = true
		pause_button.text = "Pause"
		pause_state = 1
	else:
		GlobalTimer.pause_timer()
		countdown_timer.stop()
		ball.game_started = false
		pause_button.text = "Resume"
		pause_state = 0
	is_paused = !is_paused

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
	ball.game_started = false
	GlobalTimer.stop_timer()
	game_over_label.visible = true
	

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
	game_started = false
	
func save_final_score_to_log(player_score: int):
	if game_log_file:
		game_log_file.store_line("Final Score: " + str(player_score))
		game_log_file.flush() 

func _on_log_timer_timeout() -> void:
	if game_log_file:
		game_log_file.store_csv_line(PackedStringArray([ball.player_score,Time.get_unix_time_from_system(),str(GlobalSignals.ball_position.x), str(GlobalSignals.ball_position.y),str(position.x), str(position.y), str(network_position.x), str(network_position.y), str(GlobalScript.scaled_network_position.x), str(GlobalScript.scaled_network_position.y)]))

	
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:

		print('closed')
		get_tree().quit()

func _on_logout_pressed() -> void:
	GlobalTimer.stop_timer()
	get_tree().change_scene_to_file("res://Main_screen/select_game.tscn")


func _on_adapt_rom_toggled(toggled_on: bool) -> void:
	if toggled_on:
		adapt_toggle = true
	else:
		adapt_toggle = false
