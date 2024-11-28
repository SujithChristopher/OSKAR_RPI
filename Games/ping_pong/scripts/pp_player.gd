extends CharacterBody2D
const SPEED = 100.0
var thread: Thread
var udp_terminated: bool = false
var player_position = Vector2(0,0)
var player_current_position = Vector2(0,0)
var player_zero_drift = Vector2(0,0)
var _temp_message
var _split_message
var network_position = Vector2.ZERO


@export var speed = 200

func _physics_process(delta):
		
	position.y = 600
	move_and_slide()

func _on_ready():
	pass
	
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:

		print('closed')
		get_tree().quit()

func _on_logout_pressed() -> void:
	get_tree().change_scene_to_file("res://Main_screen/select_game.tscn")
