#extends CharacterBody2D
#
#@export var max_score = 500
#@onready var debug_mode = DebugSettings.debug_mode
#@onready var apple_sound = $"../apple_sound"
#@onready var score_board = $"../ScoreBoard/Score"
#@onready var anim = $Sprite2D
#@onready var my_timer = $"../DisplayTimer"
#@onready var time_display = $"../Panel/TimeSeconds"
#
#@onready var timer_panel = $"../TileMap/CanvasLayer/TimerSelectorPanel"
#@onready var countdown_display = $"../TileMap/CanvasLayer/CountdownLabel"
#@onready var play_button = $"../TileMap/CanvasLayer/TimerSelectorPanel/VBoxContainer/HBoxContainer/PlayButton"
#@onready var close_button = $"../TileMap/CanvasLayer/TimerSelectorPanel/VBoxContainer/HBoxContainer/CloseButton"
#@onready var countdown_timer = $"../TileMap/CanvasLayer/CountdownTimer"
#@onready var game_over_label = $"../TileMap/CanvasLayer/ColorRect/GameOverLabel"
#@onready var add_one_btn = $"../TileMap/CanvasLayer/TimerSelectorPanel/HBoxContainer/AddOneButton"
#@onready var add_five_btn = $"../TileMap/CanvasLayer/TimerSelectorPanel/HBoxContainer/AddFiveButton"
#@onready var sub_one_btn = $"../TileMap/CanvasLayer/TimerSelectorPanel/HBoxContainer2/SubOneButton"
#@onready var sub_five_btn = $"../TileMap/CanvasLayer/TimerSelectorPanel/HBoxContainer2/SubFiveButton"
#@onready var logout_button = $"../TileMap/CanvasLayer/ColorRect/GameOverLabel/LogoutButton"
#@onready var retry_button = $"../TileMap/CanvasLayer/ColorRect/GameOverLabel/RetryButton"
#@onready var time_label := $"../TileMap/CanvasLayer/TimerSelectorPanel/TimeSelector"
#@onready var top_score_label: Label = $"../TileMap/CanvasLayer/TextureRect/TopScoreLabel"
#@onready var first = $"../TileMap/CanvasLayer/GameOverLabel/TextureRect/First"
#@onready var second = $"../TileMap/CanvasLayer/GameOverLabel/TextureRect/Second"
#@onready var third = $"../TileMap/CanvasLayer/GameOverLabel/TextureRect/Third"
#@onready var color_rect: ColorRect = $"../TileMap/CanvasLayer/ColorRect"
#
#@onready var adapt_toggle:bool = false
#@onready var game_log_file
#@onready var log_timer := Timer.new()
#@onready var pause_button = $"../TileMap/CanvasLayer/PauseButton"
#const MIN_BOUNDS = Vector2(44, 40)
#const MAX_BOUNDS = Vector2(1105, 600)
#
#
#var json = JSON.new()
#var path = "res://debug.json"
#var debug
#
#
#const SPEED = 100.0
#
#var network_position = Vector2.ZERO
#var current_apple: Node = null
#var game_started: bool = false
#
#var apple = preload("res://Games/random_reach/scenes/apple.tscn")
#var apple_position
#var process
#var score = 0
#var zero_offset = Vector2.ZERO
#var rom_x_top : int
#var rom_y_top : int
#var rom_x_bot : int
#var rom_y_bot : int
#var game_over = false
#
#var countdown_time = 0
#var countdown_active = false
#var current_time := 0
#var is_paused = false
#var pause_state = 1
#var total_time = GlobalTimer.get_time() 
#var target_x : float
#var target_y : float
#var target_z : float
#var pos_x : float
#var pos_y : float
#var pos_z : float
#var game_x : float
#var game_y = 0.0
#var game_z : float
#var status := "idle"
#var error_status = "null"
#var packets = "null"
#var patient_id = GlobalSignals.current_patient_id
#var game_name = "RandomReach"
#
#func _ready() -> void:
    #debug = JSON.parse_string(FileAccess.get_file_as_string(path))['debug']
    #
    #var training_hand = GlobalSignals.selected_training_hand
    #if training_hand != "":
        #print("Training for %s hand" % training_hand)
#
    #network_position = Vector2.ZERO
    #log_timer.wait_time = 0.02 
    #log_timer.autostart = true 
    ##log_timer.timeout.connect(_on_log_timer_timeout)
    #add_child(log_timer)
    #print("Timer Panel Found:", timer_panel)
    #update_label()
    #timer_panel.visible = true
    #color_rect.visible = false
    #game_over_label.visible = false
    #play_button.pressed.connect(_on_play_pressed)
    #countdown_timer.timeout.connect(_on_CountdownTimer_timeout)
    #close_button.pressed.connect(_on_close_pressed)
    #add_one_btn.pressed.connect(_on_add_one_pressed)
    #add_five_btn.pressed.connect(_on_add_five_pressed)
    #sub_one_btn.pressed.connect(_on_sub_one_pressed)
    #sub_five_btn.pressed.connect(_on_sub_five_pressed)
    #logout_button.pressed.connect(_on_logout_button_pressed)
    #retry_button.pressed.connect(_on_retry_button_pressed)
    #pause_button.pressed.connect(_on_PauseButton_pressed)
    #game_over_label.hide()
    #color_rect.hide()
    #var top_score = ScoreManager.get_top_score(patient_id, game_name)
    #top_score_label.text = str("HIGH SCORE : ",top_score)
    #GlobalScript.start_new_session_if_needed()
    #
    #
    #
#func _physics_process(delta):
    #if not game_started:
        #return
    #if debug_mode:
        #network_position = get_global_mouse_position()
    #elif adapt_toggle:
        #network_position = GlobalScript.scaled_network_position
    #else:
        #network_position = GlobalScript.network_position
#
    #if network_position != Vector2.ZERO:
        #network_position = network_position - zero_offset
        ##network_position.clamp(Vector2.ZERO, Vector2(DisplayServer.window_get_size()) - Vector2(50, 50))
        #position = position.lerp(network_position, 0.8)
        #position.x = clamp(position.x, MIN_BOUNDS.x, MAX_BOUNDS.x)
        #position.y = clamp(position.y, MIN_BOUNDS.y, MAX_BOUNDS.y)
        #pos_x = GlobalScript.raw_x
        #pos_y = GlobalScript.raw_y
        #pos_z = GlobalScript.raw_z
        #if not adapt_toggle:
            #game_x = (position.x - GlobalScript.X_SCREEN_OFFSET) / GlobalScript.PLAYER_POS_SCALER_X
            #game_z = (position.y - GlobalScript.Y_SCREEN_OFFSET) / GlobalScript.PLAYER_POS_SCALER_Y
        #else:
            #game_x  = (position.x - GlobalScript.X_SCREEN_OFFSET) / (GlobalScript.PLAYER_POS_SCALER_X * GlobalSignals.global_scalar_x)
            #game_z = (position.y - GlobalScript.Y_SCREEN_OFFSET) / (GlobalScript.PLAYER_POS_SCALER_Y * GlobalSignals.global_scalar_y)
            #
    #
        #
    #if current_apple != null:
        #var direction = current_apple.position.x - position.x
        #anim.flip_h = direction < 0  # Flip if apple is to the left
        #
    ##if current_apple == null and network_position != Vector2.ZERO:
    #if current_apple == null and (debug_mode or network_position != Vector2.ZERO):
        #my_timer.start()
        #current_apple = apple.instantiate()
        #add_child(current_apple)
        #current_apple.top_level = true
        #status = ""
#
        ## Connect apple signals
        #current_apple.apple_eaten.connect(_on_apple_eaten)
        #current_apple.tree_exited.connect(_on_apple_removed)
#
        ## Spawn position
        #if adapt_toggle:
            #while true:
                ##apple_position = Vector2(randi_range(200, 900), randi_range(200, 600))
                #if debug_mode:
                    #apple_position = get_global_mouse_position()
                #else:
                    #apple_position = Vector2(randi_range(200, 900), randi_range(200, 600))
                #if Geometry2D.is_point_in_polygon(apple_position, GlobalSignals.inflated_workspace):
                    #break
            #current_apple.position = apple_position
        #else:
            #current_apple.position = Vector2(randi_range(200, 900), randi_range(200, 600))
            #target_x = (current_apple.position.x - GlobalScript.X_SCREEN_OFFSET) / GlobalScript.PLAYER_POS_SCALER_X
            #target_y = (current_apple.position.y - GlobalScript. Y_SCREEN_OFFSET) / GlobalScript.PLAYER_POS_SCALER_Y
            #target_z = 0
            #
    #if current_apple != null:
        #var remaining_time = round(my_timer.time_left)
        #time_display.text = str(remaining_time) + "s"
        #
        #if remaining_time > 0:
            #if status != "captured":
                #status = "moving"
        #else:
            #if status != "captured":
                #status = "missed"
        #
    #
    #
#func update_label():
    #time_label.text = str(current_time) + " sec"
    #var minutes = countdown_time / 60
    #var seconds = countdown_time % 60
    #time_label.text = "%2d m" % [minutes]
#
#func _on_add_one_pressed():
    #if countdown_time + 60 <= 2700:
        #countdown_time += 60
    #else:
        #countdown_time = 2700
    #_update_time_display()
    #countdown_display.visible = true
    #update_label()
#
#func _on_add_five_pressed():
    #if countdown_time + 300 <= 2700:
        #countdown_time += 300
    #else:
        #countdown_time = 2700
    #_update_time_display()
    #countdown_display.visible = true
    #update_label()
#
#func _on_sub_one_pressed():
    #if countdown_time >= 60:
        #countdown_time -= 60
    #else:
        #countdown_time = 0
    #_update_time_display()
    #update_label()
#
#func _on_sub_five_pressed():
    #if countdown_time >= 300:
        #countdown_time -= 300
    #else:
        #countdown_time = 0
    #_update_time_display()
    #update_label()
    #
#
#func _on_play_pressed():
    #GlobalTimer.start_timer()
    #timer_panel.visible = false
    #game_started = true
    #add_one_btn.hide()
    #add_five_btn.hide()
    #sub_one_btn.hide()
    #sub_five_btn.hide()
    #start_game_with_timer()
    #log_timer.timeout.connect(_on_log_timer_timeout)
    #game_log_file = Manager.create_game_log_file('RandomReach', GlobalSignals.current_patient_id)
    #game_log_file.store_csv_line(PackedStringArray(['epochtime','score','status','error_status','packets','device_x', 'device_y','device_z', 'target_x','target_y','target_z','player_x','player_y','player_z','pause_state']))
    #
#func _on_close_pressed():
    #timer_panel.visible = false
    #add_one_btn.hide()
    #game_started = true
    #add_five_btn.hide()
    #sub_one_btn.hide()
    #sub_five_btn.hide()    
    #countdown_display.hide()
    #start_game_without_timer()
    #log_timer.timeout.connect(_on_log_timer_timeout)
    #game_log_file = Manager.create_game_log_file('RandomReach', GlobalSignals.current_patient_id)
    #game_log_file.store_csv_line(PackedStringArray(['epochtime','score','status','error_status','packets','device_x', 'device_y','device_z', 'target_x','target_y','target_z','player_x','player_y','player_z','pause_state']))
    #
    #
#func _on_PauseButton_pressed():
    #if is_paused:
        #GlobalTimer.resume_timer()
        #countdown_timer.start()
        #pause_button.text = "Pause"
        #game_started = true
        #pause_state = 1
    #else:
        #GlobalTimer.pause_timer()
        #countdown_timer.stop()
        #pause_button.text = "Resume"
        #game_started = false
        #pause_state = 0
    #is_paused = !is_paused
    #
#func start_game_with_timer():
    #countdown_active = true
    #countdown_timer.wait_time = 1.0 
    #countdown_timer.start()
    #_update_time_display()
    #
#func start_game_without_timer():
    #countdown_active = false
    #GlobalTimer.start_timer()
#
#func _on_CountdownTimer_timeout():
    #if countdown_active:
        #countdown_time -= 1
        #countdown_display.text = "%02d:%02d" % [countdown_time / 60, countdown_time % 60]
        #_update_time_display()
        #if countdown_time <= 0:
            #countdown_active = false
            #countdown_timer.stop()
            #show_game_over()
#
#func _update_time_display():
    #var minutes = countdown_time / 60
    #var seconds = countdown_time % 60
    #countdown_display.text = "Time Left: %02d:%02d" % [minutes, seconds]
    #
#func show_game_over():
    #GlobalTimer.stop_timer()
    #game_started = false
    #save_final_score_to_log(GlobalScript.current_score)
    #game_over_label.visible = true
    #color_rect.visible = true
    #
#func _on_logout_button_pressed():
    #get_tree().paused = false
    #get_tree().change_scene_to_file("res://Main_screen/select_game.tscn")
#
#func _on_retry_button_pressed():
    #get_tree().paused = false
    #game_over_label.hide()
    #timer_panel.show()
    #add_one_btn.show()
    #add_five_btn.show()
    #sub_one_btn.show()
    #sub_five_btn.show()
#
#func save_final_score_to_log(score: int):
    #if game_log_file:
        #game_log_file.store_line("Final Score: " + str(score))
        #game_log_file.flush()  
        #
        #
#func _on_log_timer_timeout():
    #if game_log_file and not debug:
        #game_log_file.store_csv_line(PackedStringArray([Time.get_unix_time_from_system(),score,status,error_status,packets,str(pos_x), str(pos_y), str(pos_z), str(target_x), str(target_y), str(target_z),str(game_x),str(game_y),str(game_z),str(pause_state)]))
        #
#func _on_reach_game_ready():
    #rom_x_top = 20
    #rom_y_top = 20
    #rom_x_bot = 1100
    #rom_y_bot = 600
#
    #if rom_y_bot > 600:
        #rom_y_bot = 600
#
    #if rom_x_bot > 1100:
        #rom_x_bot = 1100
        #
#func _on_apple_removed():
    #current_apple = null
    #
#func _on_apple_eaten():
    #if score < max_score:
        #score += 1
        #score_board.text = str(score)
        #if apple_sound:
            #apple_sound.play()
    #ScoreManager.update_top_score(patient_id, game_name, score)
    #var top_score = ScoreManager.get_top_score(patient_id, game_name)
    #top_score_label.text = str("HIGH SCORE : ",top_score)
    #
#
    #status = "captured"
    #
#func apple_function():
    #if score <= max_score:
        #if not apple_sound == null:
            #score += 1
            #score_board.text = str(score)
            #
#
#func _notification(what):
    #if what == NOTIFICATION_WM_CLOSE_REQUEST:
        #game_log_file.close()
#
#func _on_reach_game_tree_exiting():
    #pass
#
#func _on_udp_timer_timeout():
    #pass
#
#func _on_dummy_timeout():
    #pass
#
#func _on_area_2d_area_entered(area):
    #anim.animation = "sheep"
    #await anim.animation_finished
#
#func _on_area_2d_area_exited(area):
    #anim.animation = "sheep"
#
#
#func _on_zero_pressed() -> void:
    #zero_offset = network_position
#
#func _on_button_pressed() -> void:
    #get_tree().quit() 
#
#
#func _on_logout_pressed() -> void:
    #GlobalTimer.stop_timer()
    #GlobalSignals.enable_game_buttons(true)
    #get_tree().change_scene_to_file("res://Main_screen/select_game.tscn")
#
#
#func _on_adapt_rom_toggled(toggled_on: bool) -> void:
    #if toggled_on:
        #adapt_toggle = true
    #else:
        #adapt_toggle = false
        

extends CharacterBody2D

# Exported variables
@export var max_score = 500
@onready var debug_mode = DebugSettings.debug_mode

# Constants
const SPEED = 100.0
const MIN_BOUNDS = Vector2(44, 40)
const MAX_BOUNDS = Vector2(1105, 600)
const LOG_INTERVAL = 0.02
const MAX_COUNTDOWN_TIME = 2700
const ONE_MINUTE = 60
const FIVE_MINUTES = 300

# Node references - grouped by functionality
@onready var _audio_nodes = {
    "apple_sound": $"../apple_sound"
}

@onready var _ui_nodes = {
    "score_board": $"../ScoreBoard/Score",
    "time_display": $"../Panel/TimeSeconds",
    "countdown_display": $"../TileMap/CanvasLayer/CountdownLabel",
    "game_over_label": $"../TileMap/CanvasLayer/ColorRect/GameOverLabel",
    "time_label": $"../TileMap/CanvasLayer/TimerSelectorPanel/TimeSelector",
    "top_score_label": $"../TileMap/CanvasLayer/TextureRect/TopScoreLabel",
    "color_rect": $"../TileMap/CanvasLayer/ColorRect",
    "debug_mode": $"../Users/yuvaneshs/Documents/Games/OSKAR_RPI/debug.json"
}

@onready var _timer_nodes = {
    "my_timer": $"../DisplayTimer",
    "countdown_timer": $"../TileMap/CanvasLayer/CountdownTimer"
}

@onready var _panel_nodes = {
    "timer_panel": $"../TileMap/CanvasLayer/TimerSelectorPanel",
    "pause_button": $"../TileMap/CanvasLayer/PauseButton"
}

@onready var _button_nodes = {
    "play_button": $"../TileMap/CanvasLayer/TimerSelectorPanel/VBoxContainer/HBoxContainer/PlayButton",
    "close_button": $"../TileMap/CanvasLayer/TimerSelectorPanel/VBoxContainer/HBoxContainer/CloseButton",
    "logout_button": $"../TileMap/CanvasLayer/ColorRect/GameOverLabel/LogoutButton",
    "retry_button": $"../TileMap/CanvasLayer/ColorRect/GameOverLabel/RetryButton",
    "add_one_btn": $"../TileMap/CanvasLayer/TimerSelectorPanel/HBoxContainer/AddOneButton",
    "add_five_btn": $"../TileMap/CanvasLayer/TimerSelectorPanel/HBoxContainer/AddFiveButton",
    "sub_one_btn": $"../TileMap/CanvasLayer/TimerSelectorPanel/HBoxContainer2/SubOneButton",
    "sub_five_btn": $"../TileMap/CanvasLayer/TimerSelectorPanel/HBoxContainer2/SubFiveButton"
}

@onready var _sprite_nodes = {
    "anim": $Sprite2D,
    "first": $"../TileMap/CanvasLayer/GameOverLabel/TextureRect/First",
    "second": $"../TileMap/CanvasLayer/GameOverLabel/TextureRect/Second",
    "third": $"../TileMap/CanvasLayer/GameOverLabel/TextureRect/Third"
}

# Game state variables
var network_position = Vector2.ZERO
var current_apple: Node = null
var game_started: bool = false
var score = 0
var zero_offset = Vector2.ZERO
var game_over = false
var countdown_time = 0
var countdown_active = false
var current_time := 0
var is_paused = false
var pause_state = 1
var adapt_toggle: bool = false

# Position tracking variables
var target_x: float
var target_y: float
var target_z: float
var pos_x: float
var pos_y: float
var pos_z: float
var game_x: float
var game_y = 0.0
var game_z: float

# Game logging variables
var status := "idle"
var error_status = "null"
var packets = "null"
var patient_id = GlobalSignals.current_patient_id
var game_name = "RandomReach"
var game_log_file
var log_timer := Timer.new()

# ROM bounds
var rom_x_top: int
var rom_y_top: int
var rom_x_bot: int
var rom_y_bot: int

# Preloaded resources
var apple = preload("res://Games/random_reach/scenes/apple.tscn")

# Debug and config
var json = JSON.new()
var path = "res://debug.json"
var debug

func _ready() -> void:
    _load_debug_config()
    _setup_training_hand()
    _setup_timers()
    _setup_ui()
    _connect_signals()
    _initialize_game_state()
    _setup_logging()

func _load_debug_config() -> void:
    debug = JSON.parse_string(FileAccess.get_file_as_string(path))['debug']

func _setup_training_hand() -> void:
    var training_hand = GlobalSignals.selected_training_hand
    if training_hand != "":
        print("Training for %s hand" % training_hand)

func _setup_timers() -> void:
    log_timer.wait_time = LOG_INTERVAL
    log_timer.autostart = true
    add_child(log_timer)

func _setup_ui() -> void:
    _panel_nodes.timer_panel.visible = true
    _ui_nodes.color_rect.visible = false
    _ui_nodes.game_over_label.visible = false
    _ui_nodes.game_over_label.hide()
    _ui_nodes.color_rect.hide()
    _update_top_score_display()
    update_label()

func _connect_signals() -> void:
    # Button connections
    _button_nodes.play_button.pressed.connect(_on_play_pressed)
    _button_nodes.close_button.pressed.connect(_on_close_pressed)
    _button_nodes.add_one_btn.pressed.connect(_on_add_one_pressed)
    _button_nodes.add_five_btn.pressed.connect(_on_add_five_pressed)
    _button_nodes.sub_one_btn.pressed.connect(_on_sub_one_pressed)
    _button_nodes.sub_five_btn.pressed.connect(_on_sub_five_pressed)
    _button_nodes.logout_button.pressed.connect(_on_logout_button_pressed)
    _button_nodes.retry_button.pressed.connect(_on_retry_button_pressed)
    _panel_nodes.pause_button.pressed.connect(_on_PauseButton_pressed)
    
    # Timer connections
    _timer_nodes.countdown_timer.timeout.connect(_on_CountdownTimer_timeout)

func _initialize_game_state() -> void:
    network_position = Vector2.ZERO
    GlobalScript.start_new_session_if_needed()
    
func _setup_logging() -> void:
    # Logging setup will be done when game starts
    pass

func _update_top_score_display() -> void:
    var top_score = ScoreManager.get_top_score(patient_id, game_name)
    _ui_nodes.top_score_label.text = "HIGH SCORE : " + str(top_score)

func _physics_process(delta):
    if not game_started:
        return
    
    _update_player_position()
    _update_sprite_direction()
    _handle_apple_spawning()
    _update_timer_display()

func _update_player_position() -> void:
    if debug_mode:
        network_position = get_global_mouse_position()
    elif adapt_toggle:
        network_position = GlobalScript.scaled_network_position
    else:
        network_position = GlobalScript.network_position

    if network_position != Vector2.ZERO:
        network_position = network_position - zero_offset
        position = position.lerp(network_position, 0.8)
        position.x = clamp(position.x, MIN_BOUNDS.x, MAX_BOUNDS.x)
        position.y = clamp(position.y, MIN_BOUNDS.y, MAX_BOUNDS.y)
        
        _update_position_tracking()

func _update_position_tracking() -> void:
    pos_x = GlobalScript.raw_x
    pos_y = GlobalScript.raw_y
    pos_z = GlobalScript.raw_z
    
    if not adapt_toggle:
        game_x = (position.x - GlobalScript.X_SCREEN_OFFSET) / GlobalScript.PLAYER_POS_SCALER_X
        game_z = (position.y - GlobalScript.Y_SCREEN_OFFSET) / GlobalScript.PLAYER_POS_SCALER_Y
    else:
        game_x = (position.x - GlobalScript.X_SCREEN_OFFSET) / (GlobalScript.PLAYER_POS_SCALER_X * GlobalSignals.global_scalar_x)
        game_z = (position.y - GlobalScript.Y_SCREEN_OFFSET) / (GlobalScript.PLAYER_POS_SCALER_Y * GlobalSignals.global_scalar_y)

func _update_sprite_direction() -> void:
    if current_apple != null:
        var direction = current_apple.position.x - position.x
        _sprite_nodes.anim.flip_h = direction < 0

func _handle_apple_spawning() -> void:
    if current_apple == null and (debug_mode or network_position != Vector2.ZERO):
        _spawn_new_apple()

func _spawn_new_apple() -> void:
    _timer_nodes.my_timer.start()
    current_apple = apple.instantiate()
    add_child(current_apple)
    current_apple.top_level = true
    status = ""

    # Connect apple signals
    current_apple.apple_eaten.connect(_on_apple_eaten)
    current_apple.tree_exited.connect(_on_apple_removed)

    # Set apple position
    _set_apple_position()

func _set_apple_position() -> void:
    var apple_position: Vector2
    
    if adapt_toggle:
        apple_position = _get_valid_apple_position()
    else:
        apple_position = Vector2(randi_range(200, 900), randi_range(200, 600))
        _update_target_position(apple_position)
    
    current_apple.position = apple_position

func _get_valid_apple_position() -> Vector2:
    var apple_position: Vector2
    while true:
        if debug_mode:
            apple_position = get_global_mouse_position()
        else:
            apple_position = Vector2(randi_range(200, 900), randi_range(200, 600))
        
        if Geometry2D.is_point_in_polygon(apple_position, GlobalSignals.inflated_workspace):
            break
    
    return apple_position

func _update_target_position(apple_position: Vector2) -> void:
    target_x = (apple_position.x - GlobalScript.X_SCREEN_OFFSET) / GlobalScript.PLAYER_POS_SCALER_X
    target_y = (apple_position.y - GlobalScript.Y_SCREEN_OFFSET) / GlobalScript.PLAYER_POS_SCALER_Y
    target_z = 0

func _update_timer_display() -> void:
    if current_apple != null:
        var remaining_time = round(_timer_nodes.my_timer.time_left)
        _ui_nodes.time_display.text = str(remaining_time) + "s"
        
        if remaining_time > 0:
            if status != "captured":
                status = "moving"
        else:
            if status != "captured":
                status = "missed"

func update_label() -> void:
    _ui_nodes.time_label.text = str(current_time) + " sec"
    var minutes = countdown_time / 60
    _ui_nodes.time_label.text = "%2d m" % [minutes]

func _modify_countdown_time(amount: int) -> void:
    countdown_time = clamp(countdown_time + amount, 0, MAX_COUNTDOWN_TIME)
    _update_time_display()
    _ui_nodes.countdown_display.visible = true
    update_label()

func _on_add_one_pressed() -> void:
    _modify_countdown_time(ONE_MINUTE)

func _on_add_five_pressed() -> void:
    _modify_countdown_time(FIVE_MINUTES)

func _on_sub_one_pressed() -> void:
    _modify_countdown_time(-ONE_MINUTE)

func _on_sub_five_pressed() -> void:
    _modify_countdown_time(-FIVE_MINUTES)

func _on_play_pressed() -> void:
    GlobalTimer.start_timer()
    _panel_nodes.timer_panel.visible = false
    game_started = true
    _hide_timer_buttons()
    start_game_with_timer()
    _setup_game_logging()

func _on_close_pressed() -> void:
    _panel_nodes.timer_panel.visible = false
    _hide_timer_buttons()
    game_started = true
    _ui_nodes.countdown_display.hide()
    start_game_without_timer()
    _setup_game_logging()

func _hide_timer_buttons() -> void:
    for button_name in ["add_one_btn", "add_five_btn", "sub_one_btn", "sub_five_btn"]:
        _button_nodes[button_name].hide()

func _show_timer_buttons() -> void:
    for button_name in ["add_one_btn", "add_five_btn", "sub_one_btn", "sub_five_btn"]:
        _button_nodes[button_name].show()

func _setup_game_logging() -> void:
    log_timer.timeout.connect(_on_log_timer_timeout)
    game_log_file = Manager.create_game_log_file('RandomReach', GlobalSignals.current_patient_id)
    game_log_file.store_csv_line(PackedStringArray([
        'epochtime', 'score', 'status', 'error_status', 'packets', 
        'device_x', 'device_y', 'device_z', 'target_x', 'target_y', 'target_z',
        'player_x', 'player_y', 'player_z', 'pause_state'
    ]))

func _on_PauseButton_pressed() -> void:
    if is_paused:
        _resume_game()
    else:
        _pause_game()
    is_paused = !is_paused

func _pause_game() -> void:
    GlobalTimer.pause_timer()
    _timer_nodes.countdown_timer.stop()
    _panel_nodes.pause_button.text = "Resume"
    game_started = false
    pause_state = 0

func _resume_game() -> void:
    GlobalTimer.resume_timer()
    _timer_nodes.countdown_timer.start()
    _panel_nodes.pause_button.text = "Pause"
    game_started = true
    pause_state = 1

func start_game_with_timer() -> void:
    countdown_active = true
    _timer_nodes.countdown_timer.wait_time = 1.0
    _timer_nodes.countdown_timer.start()
    _update_time_display()
    
func start_game_without_timer() -> void:
    countdown_active = false
    GlobalTimer.start_timer()

func _on_CountdownTimer_timeout() -> void:
    if countdown_active:
        countdown_time -= 1
        _ui_nodes.countdown_display.text = "%02d:%02d" % [countdown_time / 60, countdown_time % 60]
        _update_time_display()
        if countdown_time <= 0:
            countdown_active = false
            _timer_nodes.countdown_timer.stop()
            show_game_over()

func _update_time_display() -> void:
    var minutes = countdown_time / 60
    var seconds = countdown_time % 60
    _ui_nodes.countdown_display.text = "Time Left: %02d:%02d" % [minutes, seconds]
    
func show_game_over() -> void:
    GlobalTimer.stop_timer()
    game_started = false
    save_final_score_to_log(GlobalScript.current_score)
    _ui_nodes.game_over_label.visible = true
    _ui_nodes.color_rect.visible = true
    
func _on_logout_button_pressed() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_file("res://Main_screen/Scenes/select_game.tscn")

func _on_retry_button_pressed() -> void:
    get_tree().paused = false
    _ui_nodes.color_rect.visible = false
    _ui_nodes.game_over_label.hide()
    _panel_nodes.timer_panel.show()
    
    _show_timer_buttons()

func save_final_score_to_log(score: int) -> void:
    if game_log_file:
        game_log_file.store_line("Final Score: " + str(score))
        game_log_file.flush()

func _on_log_timer_timeout() -> void:
    if game_log_file and not debug:
        game_log_file.store_csv_line(PackedStringArray([
            Time.get_unix_time_from_system(), score, status, error_status, packets,
            str(pos_x), str(pos_y), str(pos_z), str(target_x), str(target_y), str(target_z),
            str(game_x), str(game_y), str(game_z), str(pause_state)
        ]))
        
func _on_reach_game_ready() -> void:
    rom_x_top = 20
    rom_y_top = 20
    rom_x_bot = 1100
    rom_y_bot = 600
    rom_y_bot = min(rom_y_bot, 600)
    rom_x_bot = min(rom_x_bot, 1100)
        
func _on_apple_removed() -> void:
    current_apple = null
    
func _on_apple_eaten() -> void:
    if score < max_score:
        score += 1
        _ui_nodes.score_board.text = str(score)
        if _audio_nodes.apple_sound:
            _audio_nodes.apple_sound.play()
    
    ScoreManager.update_top_score(patient_id, game_name, score)
    _update_top_score_display()
    status = "captured"

func _notification(what) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        if game_log_file:
            game_log_file.close()

func _on_area_2d_area_entered(area) -> void:
    _sprite_nodes.anim.animation = "sheep"
    await _sprite_nodes.anim.animation_finished

func _on_area_2d_area_exited(area) -> void:
    _sprite_nodes.anim.animation = "sheep"

func _on_zero_pressed() -> void:
    zero_offset = network_position

func _on_button_pressed() -> void:
    get_tree().quit()

func _on_logout_pressed() -> void:
    GlobalTimer.stop_timer()
    GlobalSignals.enable_game_buttons(true)
    get_tree().change_scene_to_file("res://Main_screen/Scenes/select_game.tscn")

func _on_adapt_rom_toggled(toggled_on: bool) -> void:
    adapt_toggle = toggled_on

# Legacy functions maintained for compatibility
func apple_function() -> void:
    if score <= max_score:
        if _audio_nodes.apple_sound != null:
            score += 1
            _ui_nodes.score_board.text = str(score)

func _on_reach_game_tree_exiting() -> void:
    pass

func _on_udp_timer_timeout() -> void:
    pass

func _on_dummy_timeout() -> void:
    pass
