extends CharacterBody2D
var network_position = Vector2.ZERO
var zero_offset = Vector2.ZERO

@export var speed = 200

func _physics_process(delta):
	network_position = GlobalScript.network_position
	if network_position != Vector2.ZERO:
		network_position = network_position - zero_offset  + Vector2(600, 200)  
		position = position.lerp(network_position, 0.8)
	
	position.y = 600

func _on_ready():
	pass
	
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:

		print('closed')
		get_tree().quit()

func _on_logout_pressed() -> void:
	get_tree().change_scene_to_file("res://Main_screen/select_game.tscn")