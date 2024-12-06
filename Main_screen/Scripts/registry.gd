extends Control

@onready var patient_db: PatientDetails = load("res://Main_screen/patient_register.tres")
@onready var patient_list = $TextureRect/PatientList
@onready var auth_window = $TextureRect/Auth
@onready var patient_display = $TextureRect/Patient_display
@onready var invalid_details = $TextureRect/InvalidDetails
@onready var login_to_patient = $TextureRect/LoginSelectPatient
var patient_selected: int
var allpatients
var path = "res://data.json"
var json = JSON.new()

func _ready() -> void:
	allpatients = patient_db.list_all_patients()
	_update_plist()
	
func _update_plist() -> void:
	patient_list.clear()
	allpatients = patient_db.list_all_patients()
	var _h_id = []
	for _p in allpatients:
		_h_id.append(_p['hospital_id'] +" "+ _p['name'])
		patient_list.add_item(_p['hospital_id'] +" "+ _p['name'])

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Main_screen/main.tscn")


func _on_exit_button_pressed() -> void:
	get_tree().quit()

func save_json(content):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(json.stringify(content.list_all_patients()))
	file.close()

func _on_register_patient_pressed() -> void:
	var patient_name = $TextureRect/PatientName.text
	var age = $TextureRect/Age.text
	var hosp_id = $TextureRect/HospID.text
	var gender_id = $TextureRect/Gender.selected
	var stroke_time = int($TextureRect/StrokeTime.text)
	var gender:String
	
	match gender_id:
		0:
			gender = "male"
		1:
			gender = "female"
		2:
			gender = "others"
		-1:
			gender = "unspecified"
	
	var dominant_hand:String
	match $TextureRect/DominantHand.selected:
		0:
			dominant_hand = "left"
		1:
			dominant_hand = "right"
		2:
			dominant_hand = "ambidextrous"
		-1:
			dominant_hand = "unspecified"
			
	var affected_hand:String
	match $TextureRect/AffectedHand.selected:
		0:
			affected_hand = "left"
		1:
			affected_hand = "right"
		2:
			affected_hand = "both"
		-1:
			affected_hand = "unspecified"
	
	var comments = $TextureRect/AdditionalComments.text

	if patient_name != "" and hosp_id != "" and age !="":
		
		patient_db.add_patient(hosp_id, patient_name, int(age), gender, stroke_time, dominant_hand, affected_hand, comments)
		save_json(patient_db)
		ResourceSaver.save(patient_db, "res://Main_screen/patient_register.tres")
		_update_plist()
	else:
		invalid_details.show()
		print('enter details correctly')


func _on_patient_list_item_selected(index: int) -> void:
	patient_selected = index
	var current_patient = patient_db.list_all_patients()[patient_selected]
	print(current_patient)
	var text_display = "Hosp ID: " + current_patient['hospital_id'] +"\n" + \
						"Name: " +current_patient['name'] + "\n" + \
						"Age: " + str(current_patient['age']) + "\n" + \
						"Gender: " + current_patient['gender'] + "\n" + \
						"Diag time: " + str(current_patient['stroke_time']) + "\n" + \
						"Dominant hand: " + current_patient['dominant_hand'] + "\n" + \
						"Affected hand: " + current_patient['affected_hand'] + "\n" + \
						"Comments: " + "\n" + \
						current_patient['comments']
	
	patient_display.clear()
	patient_display.add_text(text_display)


func _on_delete_pressed() -> void:
	auth_window.show()

func _on_delete_login_pressed() -> void:
	if $TextureRect/Auth/password.text == "CMC":
		if len(patient_db.list_all_patients()) != 0:
			patient_db.remove_patient(allpatients[patient_selected]['hospital_id'])
			save_json(patient_db)
			ResourceSaver.save(patient_db, "res://Main_screen/patient_register.tres")
			patient_list.clear()
			_update_plist()
			auth_window.hide()
	else:
		auth_window.hide()


func _on_auth_close_requested() -> void:
	auth_window.hide()


func _on_close_button_pressed() -> void:
	invalid_details.hide()
	login_to_patient.hide()


func _on_patient_list_item_activated(index: int) -> void:
	patient_selected = index
	login_to_patient.show()


func _on_login_button_pressed() -> void:
	patient_db.current_patient_id = allpatients[patient_selected]['hospital_id']
	save_json(patient_db)

	ResourceSaver.save(patient_db, "res://Main_screen/patient_register.tres")
	get_tree().change_scene_to_file("res://Main_screen/select_game.tscn")
