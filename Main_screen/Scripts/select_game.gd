extends Control

@onready var patient_db: PatientDetails = load("res://Main_screen/patient_register.tres")
@onready var logged_in_as = $LoggedInAs

# Preload all scenes at start (loads into memory for faster switching)
var random_reach_scene = preload("res://Games/random_reach/random_reach.tscn")
var flappy_scene = preload("res://Games/flappy_bird/flappy_main.tscn")
var pingpong_scene = preload("res://Games/ping_pong/PingPong.tscn")
var space_shooter_scene = preload("res://Games/space_shooter/ss_scenes/game.tscn")
var assessment_scene = preload("res://Games/assessment/workspace.tscn")
var results_scene = preload("res://Results/user_progress.tscn")
var main_menu_scene = preload("res://Main_screen/main.tscn")

func _ready() -> void:
	logged_in_as.text = "Patient: " + patient_db.current_patient_id
	
	
func _process(delta: float) -> void:
	pass


func _on_game_reach_pressed() -> void:
	get_tree().change_scene_to_packed(random_reach_scene)

func _on_game_flappy_pressed() -> void:
	get_tree().change_scene_to_packed(flappy_scene)

func _on_game_pingpong_pressed() -> void:
	get_tree().change_scene_to_packed(pingpong_scene)

func _on_game_spaceshooter_pressed() -> void:
	get_tree().change_scene_to_packed(space_shooter_scene)

func _on_assessment_pressed() -> void:
	get_tree().change_scene_to_packed(assessment_scene)

func _on_results_pressed() -> void:
	get_tree().change_scene_to_packed(results_scene)

func _on_logout_pressed() -> void:
	#GlobalTimer.save_play_time(GlobalSignals.current_patient_id)
	get_tree().change_scene_to_packed(main_menu_scene)
	

func _on_exit_button_pressed() -> void:
	#GlobalTimer.save_play_time(GlobalSignals.current_patient_id)
	get_tree().quit()
