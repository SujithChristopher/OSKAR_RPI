extends CharacterBody2D
var network_position = Vector2.ZERO
var zero_offset = Vector2.ZERO

@export var speed = 200
@onready var adapt_toggle:bool = false

@onready var game_log_file
@onready var log_timer := Timer.new()

func _physics_process(delta):
	if adapt_toggle:
		network_position = GlobalScript.scaled_network_position
	else:
		network_position = GlobalScript.network_position

	if network_position != Vector2.ZERO:
		network_position = network_position - zero_offset  + Vector2(600, 200)  
		position = position.lerp(network_position, 0.8)
	
	position.y = 600

func _on_ready():
	GlobalTimer.start_timer()
	game_log_file = Manager.create_game_log_file('RandomReach', GlobalSignals.current_patient_id)
	game_log_file.store_csv_line(PackedStringArray(['time','ball_x','ball_y','position_x', 'position_y', 'network_position_x', 'network_position_y', 'scaled_network_position_x', 'scaled_network_position_y']))
	log_timer.wait_time = 0.02 # 1 second
	log_timer.autostart = true # start timer when added to a scene
	log_timer.timeout.connect(_on_log_timer_timeout)
	add_child(log_timer)

func _on_log_timer_timeout() -> void:
	if game_log_file:
		game_log_file.store_csv_line(PackedStringArray([str(GlobalSignals.ball_position.x), str(GlobalSignals.ball_position.y),str(position.x), str(position.y), str(network_position.x), str(network_position.y), str(GlobalScript.scaled_network_position.x), str(GlobalScript.scaled_network_position.y)]))

	
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
