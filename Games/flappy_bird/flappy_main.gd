extends Control

var game_running : bool = true
var game_over : bool
signal game_over_signal
signal flash_animation
signal plane_crashed
signal game_started

var scroll
var score
var screen_size : Vector2i
var ground_height : int
var pipes : Array

const SCROLL_SPEED : float = 4
const PIPE_DELAY : int = 50
const PIPE_RANGE : int = 180
const TIMER_DELAY: int = 2

@onready var pipe_scene = preload("res://Games/flappy_bird/flappy_scenes/pipe.tscn")
@onready var timer = $PipeTimer
@onready var player = $pilot
@onready var score_label: Label = $ScoreBoard/Score

@onready var heart_array = [$Health/heart1, $Health/heart2, $Health/heart3]
@onready var health = 2
@onready var game_over_scene: CanvasLayer = $GameOver

@onready var game_log_file
@onready var log_timer := Timer.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	score = 0
	scroll = 0
	screen_size = get_window().size
	ground_height = $ground.get_node("Sprite2D").texture.get_height()
	$ground.position.x = screen_size.x /2
	timer.wait_time = TIMER_DELAY/0.5
	game_over_scene.restart_games.connect(restart_game)

	game_log_file = Manager.create_game_log_file('FlyThrough', GlobalSignals.current_patient_id)

	# add header to log file
	game_log_file.store_csv_line(PackedStringArray(['position_x', 'position_y', 'network_position_x', 'network_position_y', 'scaled_network_position_x', 'scaled_network_position_y']))

	log_timer.wait_time = 0.02 # 1 second
	log_timer.autostart = true # start timer when added to a scene
	log_timer.timeout.connect(_on_log_timer_timeout)
	add_child(log_timer)

func _process(delta: float) -> void:
	
	if game_running:
		scroll += SCROLL_SPEED
		#reset scroll
		if scroll >= screen_size.x/5:
			scroll = 0
		$ground.position.x = -scroll
		#move pipes
		for pipe in pipes:
			pipe.position.x -= SCROLL_SPEED
	
	
func stop_game():
	timer.stop()
	$GameOver.show()
	game_running = false
	game_over = true

func _on_pipe_timer_timeout() -> void:
	generate_pipe()

func generate_pipe():
	var pipe = pipe_scene.instantiate()
	pipe.position.x = screen_size.x/1.5 + PIPE_DELAY
	pipe.position.y = (screen_size.y - ground_height) / 2  + randi_range(-PIPE_RANGE, PIPE_RANGE)
	pipe.hit.connect(pipe_hit)
	pipe.scored.connect(scored)
	add_child(pipe)
	pipes.append(pipe)

func restart_game():
	game_running = true
	game_over = false
	timer.start()
	for _h in heart_array:
		_h.animation = "default"
	game_started.emit()
	score = 0
	health = 2
	
func pipe_hit():
	if not health == 0 and health > -1:
		heart_array[health].animation = "Dead"
		flash_animation.emit()
	if health == 0:
		
		heart_array[health].animation = "Dead"
		game_over_signal.emit()
		plane_crashed.emit()
		
		stop_game()
	health -=1

func scored():
	score+= 1
	score_label.text = str(score)

func _on_logout_pressed() -> void:
	get_tree().change_scene_to_file("res://Main_screen/select_game.tscn")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		game_log_file.close()

	
func _on_log_timer_timeout():
	if game_log_file:
		game_log_file.store_csv_line(PackedStringArray([str(position.x), str(position.y), str(GlobalScript.scaled_network_position.x), str(GlobalScript.scaled_network_position.y)]))