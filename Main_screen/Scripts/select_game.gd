extends Control

@onready var patient_db: PatientDetails = load("res://Main_screen/patient_register.tres")
@onready var logged_in_as = $LoggedInAs
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	logged_in_as.text = "Patient: " + patient_db.current_patient_id

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_game_reach_pressed() -> void:
	get_tree().change_scene_to_file("res://Games/random_reach/random_reach.tscn") # Replace with function body.


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_logout_pressed() -> void:
	get_tree().change_scene_to_file("res://Main_screen/main.tscn") # Replace with function body.


func _on_game_flappy_pressed() -> void:
	get_tree().change_scene_to_file("res://Games/flappy_bird/flappy_main.tscn")


func _on_game_pingpong_pressed() -> void:
	get_tree().change_scene_to_file("res://Games/ping_pong/PingPong.tscn")


func _on_game_spaceshooter_pressed() -> void:
	get_tree().change_scene_to_file("res://Games/space_shooter/ss_scenes/game.tscn")
