extends Control

var game_running : bool
var game_over : bool
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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	score = 0
	scroll = 0
	screen_size = get_window().size
	ground_height = $ground.get_node("Sprite2D").texture.get_height()
	$ground.position.x = screen_size.x /2
	timer.wait_time = TIMER_DELAY/0.5

func _process(delta: float) -> void:
	scroll += SCROLL_SPEED
	#reset scroll
	if scroll >= screen_size.x/5:
		scroll = 0
	#move ground node
	$ground.position.x = -scroll
	#move pipes
	for pipe in pipes:
		pipe.position.x -= SCROLL_SPEED


func _on_pipe_timer_timeout() -> void:
	generate_pipe()

func generate_pipe():
	var pipe = pipe_scene.instantiate()
	pipe.position.x = screen_size.x/1.5 + PIPE_DELAY
	pipe.position.y = (screen_size.y - ground_height) / 4.5  + randi_range(-PIPE_RANGE, PIPE_RANGE)
	add_child(pipe)
	pipes.append(pipe)
	#print('generating')
	


func _on_logout_pressed() -> void:
	get_tree().change_scene_to_file("res://Main_screen/select_game.tscn")
