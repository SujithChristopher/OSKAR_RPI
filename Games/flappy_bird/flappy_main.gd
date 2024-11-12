extends Control

var game_running : bool
var game_over : bool
var scroll = -1000
var score
const SCROLL_SPEED : int = 1
var screen_size : Vector2i
var ground_height : int


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_window().size
	ground_height = $ground.get_node("Sprite2D").texture.get_height()
	$ground.position.x = screen_size.x
	scroll = int(-screen_size.x/2)



func _process(delta: float) -> void:
	
	scroll += SCROLL_SPEED
	#reset scroll
	if scroll >= screen_size.x:
		scroll = 0
	#move ground node
	$ground.position.x = -scroll
