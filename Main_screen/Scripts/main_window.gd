extends Button

@onready var patient_name: String = ""
@onready var hosp_id: String = ""
@onready var popup = $"../Window"
@onready var patient_notfound = $"../patient_notfound"

var patient_db: PatientDetails = load("res://Main_screen/patient_register.tres")

func _on_exit_button_pressed():
	GlobalSignals.SignalBus.emit()
	#get_tree().quit()
	
func _on_pressed():
	hosp_id = $"../TextureRect/HospID".text
	if patient_name == "" and hosp_id == "":
		popup.show()
	else:
		if patient_db.get_patient(hosp_id):
			patient_db.current_patient_id = hosp_id
			ResourceSaver.save(patient_db, "res://Main_screen/patient_register.tres")			
			get_tree().change_scene_to_file("res://Main_screen/select_game.tscn") # Replace with function body.\
		else:
			patient_notfound.show()


func _on_window_close_requested() -> void:
	popup.hide()

func _on_new_patient_pressed() -> void:
	get_tree().change_scene_to_file("res://Main_screen/registry.tscn") # Replace with function body.


func _on_assess_button_pressed() -> void:
	ResourceSaver.save(patient_db, "res://Main_screen/patient_register.tres")


func _on_patient_nf_ok_pressed() -> void:
	patient_notfound.hide()


func _on_hosp_id_text_submitted(new_text: String) -> void:
	hosp_id = $"../TextureRect/HospID".text
	if patient_name == "" and hosp_id == "":
		popup.show()
	else:
		if patient_db.get_patient(hosp_id):
			patient_db.current_patient_id = hosp_id
			ResourceSaver.save(patient_db, "res://Main_screen/patient_register.tres")			
			get_tree().change_scene_to_file("res://Main_screen/select_game.tscn") # Replace with function body.\
		else:
			patient_notfound.show()
