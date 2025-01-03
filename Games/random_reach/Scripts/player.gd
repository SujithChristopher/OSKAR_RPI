extends CharacterBody2D

const SPEED = 100.0

@export var max_score = 500

var network_position = Vector2.ZERO

var apple_present = false
var apple = preload("res://Games/random_reach/scenes/apple.tscn")
@onready var apple_sound = $"../apple_sound"
@onready var score_board = $"../ScoreBoard/Score"
@onready var anim = $Sprite2D
@onready var my_timer = $"../DisplayTimer"
@onready var time_display = $"../Panel/TimeSeconds"
var process
var score = 0
var zero_offset = Vector2.ZERO
var rom_x_top : int
var rom_y_top : int
var rom_x_bot : int
var rom_y_bot : int

var game_over = false
@onready var adapt_toggle:bool = true

func _physics_process(delta):
	if adapt_toggle:
		network_position = GlobalScript.scaled_network_position
	else:
		network_position = GlobalScript.network_position
		
	if network_position != Vector2.ZERO:
		#network_position = network_position - zero_offset  + Vector2(600, 200)  
		network_position = network_position - zero_offset
		position = position.lerp(network_position, 0.8)
		#position = network_position 
		
	if !apple_present and network_position != Vector2.ZERO:
		my_timer.start()
		var _apple = apple.instantiate()
		add_child(_apple)
		_apple.top_level = true
		_apple.position = Vector2(randi_range(200, 900), randi_range(200, 600))
		_apple.tree_exited.connect(apple_function)
		apple_present = true
	if apple_present:
		time_display.text = str(round(my_timer.time_left)) + "s"


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
		pass


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
	get_tree().quit() # Replace with function body.


func _on_logout_pressed() -> void:
	get_tree().change_scene_to_file("res://Main_screen/select_game.tscn")


func _on_adapt_rom_toggled(toggled_on: bool) -> void:
	if toggled_on:
		adapt_toggle = true
	else:
		adapt_toggle = false
		
