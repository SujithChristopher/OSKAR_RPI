#extends Control
#
#
#@onready var patient_db: PatientDetails = load("res://Main_screen/patient_register.tres")
#@onready var patient_list = $TextureRect/PatientList
#@onready var auth_window = $TextureRect/Auth
#@onready var patient_display = $TextureRect/Patient_display
#@onready var invalid_details = $TextureRect/InvalidDetails
#@onready var login_to_patient = $TextureRect/LoginSelectPatient
#@onready var patient_name_label: Label = $TextureRect/LoginSelectPatient/PatientName
#
#
#var patient_selected: int
#var allpatients
#var path = OS.get_system_dir(2)+"//NOARK//data.json"
#var json = JSON.new()
#
#func _ready() -> void:
    #allpatients = patient_db.list_all_patients()
    #_update_plist()
    #
#func _update_plist() -> void:
    #patient_list.clear()
    #allpatients = patient_db.list_all_patients()
    #var _h_id = []
    #for _p in allpatients:
        #_h_id.append(_p['hospital_id'] +" "+ _p['name'])
        #patient_list.add_item(_p['hospital_id'] +" "+ _p['name'])
#
#func _on_back_button_pressed() -> void:
    #get_tree().change_scene_to_file("res://Main_screen/Scenes/main.tscn")
#
#
#func _on_exit_button_pressed() -> void:
    #GlobalScript.handle_quit_request()
    #get_tree().quit()
#
#func save_json(content):
    #var file = FileAccess.open(path, FileAccess.WRITE)
    #print(path)
    #file.store_string(JSON.stringify(content.list_all_patients()))
    #file.close()
    #GlobalScript._path_checker()
    #
#func _on_register_patient_pressed() -> void:
    #var patient_name = $TextureRect/PatientName.text
    #var age = $TextureRect/Age.text
    #var hosp_id = $TextureRect/HospID.text
    #var gender_id = $TextureRect/Gender.selected
    #var stroke_time = int($TextureRect/StrokeTime.text)
    #var gender:String
    #
    #match gender_id:
        #0:
            #gender = "Male"
        #1:
            #gender = "Female"
        #2:
            #gender = "Others"
        #-1:
            #gender = "Unspecified"
    #
    #var dominant_hand:String
    #match $TextureRect/DominantHand.selected:
        #0:
            #dominant_hand = "Left"
        #1:
            #dominant_hand = "Right"
        #2:
            #dominant_hand = "Ambidextrous"
        #-1:
            #dominant_hand = "Unspecified"
            #
    #var affected_hand:String
    #match $TextureRect/AffectedHand.selected:
        #0:
            #affected_hand = "Left"
        #1:
            #affected_hand = "Right"
        #2:
            #affected_hand = "Both"
        #-1:
            #affected_hand = "Unspecified"
    #
    #var comments = $TextureRect/AdditionalComments.text
#
    #if patient_name != "" and hosp_id != "" and age !="":
        #
        #patient_db.add_patient(hosp_id, patient_name, int(age), gender, stroke_time, dominant_hand, affected_hand, comments)
        #save_json(patient_db)
        #ResourceSaver.save(patient_db, "res://Main_screen/patient_register.tres")
        #_update_plist()
    #else:
        #invalid_details.show()
        #print('enter details correctly')
#
#
#func _on_patient_list_item_selected(index: int) -> void:
    #patient_selected = index
    #var current_patient = patient_db.list_all_patients()[patient_selected]
    #print(current_patient)
    #var text_display = "Hosp ID: " + current_patient['hospital_id'] +"\n" + \
                        #"Name: " +current_patient['name'] + "\n" + \
                        #"Age: " + str(current_patient['age']) + "\n" + \
                        #"Gender: " + current_patient['gender'] + "\n" + \
                        #"Diag time: " + str(current_patient['stroke_time']) + "\n" + \
                        #"Dominant hand: " + current_patient['dominant_hand'] + "\n" + \
                        #"Affected hand: " + current_patient['affected_hand'] + "\n" + \
                        #"Comments: " + "\n" + \
                        #current_patient['comments']
                        #
    #if current_patient["affected_hand"] == "Left" or current_patient["affected_hand"] == "Right":
        #GlobalSignals.selected_training_hand = current_patient["affected_hand"]
        #
#
    #elif current_patient["affected_hand"] == "Both":
        #pass
        #GlobalSignals.selected_training_hand = ""  
        #
    #
    #patient_display.clear()
    #patient_display.add_text(text_display)
#
#
#func _on_delete_pressed() -> void:
    #auth_window.show()
#
#func _on_delete_login_pressed() -> void:
    #if $TextureRect/Auth/password.text == "CMC":
        #if len(patient_db.list_all_patients()) != 0:
            #patient_db.remove_patient(allpatients[patient_selected]['hospital_id'])
            #save_json(patient_db)
            #ResourceSaver.save(patient_db, "res://Main_screen/patient_register.tres")
            #patient_list.clear()
            #_update_plist()
            #auth_window.hide()
    #else:
        #auth_window.hide()
#
#
#func _on_auth_close_requested() -> void:
    #auth_window.hide()
#
#
#func _on_close_button_pressed() -> void:
    #invalid_details.hide()
    #login_to_patient.hide()
#
#
#func _on_patient_list_item_activated(index: int) -> void:
    #patient_selected = index
    #login_to_patient.show()
    #var selected_text = patient_list.get_item_text(index)
    #patient_name_label.text = selected_text
    #patient_name_label.visible = true
    #
#func _on_login_button_pressed() -> void:
    #var current_patient = allpatients[patient_selected]
    #patient_db.current_patient_id = allpatients[patient_selected]['hospital_id']
    #GlobalScript.change_patient()
    #GlobalSignals.current_patient_id = allpatients[patient_selected]['hospital_id']
    #GlobalSignals.affected_hand = current_patient["affected_hand"] 
    #save_json(patient_db)
    #
    #ResourceSaver.save(patient_db, "res://Main_screen/patient_register.tres")
    #get_tree().change_scene_to_file("res://Main_screen/Scenes/select_game.tscn")
    

extends Control

# Constants
const ADMIN_PASSWORD = "CMC"
const PATIENT_REGISTER_PATH = "res://Main_screen/patient_register.tres"
const MAIN_SCENE_PATH = "res://Main_screen/Scenes/main.tscn"
const SELECT_GAME_SCENE_PATH = "res://Main_screen/Scenes/select_game.tscn"

# Enums for better type safety
enum Gender { MALE, FEMALE, OTHERS, UNSPECIFIED = -1 }
enum Hand { LEFT, RIGHT, AMBIDEXTROUS, UNSPECIFIED = -1 }
enum AffectedHand { LEFT, RIGHT, BOTH, UNSPECIFIED = -1 }

# Node references - cached for performance
@onready var patient_db: PatientDetails = load(PATIENT_REGISTER_PATH)
@onready var patient_list = $TextureRect/PatientList
@onready var auth_window = $TextureRect/Auth
@onready var patient_display = $TextureRect/Patient_display
@onready var invalid_details = $TextureRect/InvalidDetails
@onready var login_to_patient = $TextureRect/LoginSelectPatient
@onready var patient_name_label: Label = $TextureRect/LoginSelectPatient/PatientName

# Form field references
@onready var patient_name_field = $TextureRect/PatientName
@onready var age_field = $TextureRect/Age
@onready var hosp_id_field = $TextureRect/HospID
@onready var gender_field = $TextureRect/Gender
@onready var stroke_time_field = $TextureRect/StrokeTime
@onready var dominant_hand_field = $TextureRect/DominantHand
@onready var affected_hand_field = $TextureRect/AffectedHand
@onready var comments_field = $TextureRect/AdditionalComments
@onready var password_field = $TextureRect/Auth/password

# State variables
var patient_selected: int = -1
var cached_patients: Array = []
var json_path: String

func _ready() -> void:
    json_path = OS.get_system_dir(2) + "//NOARK//data.json"
    _refresh_patient_data()

func _refresh_patient_data() -> void:
    cached_patients = patient_db.list_all_patients()
    _update_patient_list()

func _update_patient_list() -> void:
    patient_list.clear()
    
    for patient in cached_patients:
        var display_text = "%s %s" % [patient['hospital_id'], patient['name']]
        patient_list.add_item(display_text)

# Utility functions
func _get_gender_string(gender_id: int) -> String:
    match gender_id:
        Gender.MALE: return "Male"
        Gender.FEMALE: return "Female"
        Gender.OTHERS: return "Others"
        _: return "Unspecified"

func _get_hand_string(hand_id: int) -> String:
    match hand_id:
        Hand.LEFT: return "Left"
        Hand.RIGHT: return "Right"
        Hand.AMBIDEXTROUS: return "Ambidextrous"
        _: return "Unspecified"

func _get_affected_hand_string(hand_id: int) -> String:
    match hand_id:
        AffectedHand.LEFT: return "Left"
        AffectedHand.RIGHT: return "Right"
        AffectedHand.BOTH: return "Both"
        _: return "Unspecified"

func _validate_patient_input() -> bool:
    return (patient_name_field.text.strip_edges() != "" and 
            hosp_id_field.text.strip_edges() != "" and 
            age_field.text.strip_edges() != "")

func _clear_form_fields() -> void:
    patient_name_field.text = ""
    age_field.text = ""
    hosp_id_field.text = ""
    gender_field.selected = -1
    stroke_time_field.text = ""
    dominant_hand_field.selected = -1
    affected_hand_field.selected = -1
    comments_field.text = ""

func _save_patient_data() -> void:
    # Save JSON backup
    var file = FileAccess.open(json_path, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(cached_patients))
        file.close()
    else:
        push_error("Failed to save JSON file at: " + json_path)
    
    # Save resource file
    var save_result = ResourceSaver.save(patient_db, PATIENT_REGISTER_PATH)
    if save_result != OK:
        push_error("Failed to save patient database resource")
    
    GlobalScript._path_checker()

func _create_patient_display_text(patient: Dictionary) -> String:
    return "Hosp ID: %s\nName: %s\nAge: %d\nGender: %s\nDiag time: %d\nDominant hand: %s\nAffected hand: %s\nComments:\n%s" % [
        patient['hospital_id'],
        patient['name'],
        patient['age'],
        patient['gender'],
        patient['stroke_time'],
        patient['dominant_hand'],
        patient['affected_hand'],
        patient['comments']
    ]

func _set_training_hand(affected_hand: String) -> void:
    if affected_hand in ["Left", "Right"]:
        GlobalSignals.selected_training_hand = affected_hand
    else:
        GlobalSignals.selected_training_hand = ""

# Event handlers
func _on_back_button_pressed() -> void:
    get_tree().change_scene_to_file(MAIN_SCENE_PATH)

func _on_exit_button_pressed() -> void:
    GlobalScript.handle_quit_request()
    get_tree().quit()

func _on_register_patient_pressed() -> void:
    if not _validate_patient_input():
        invalid_details.show()
        push_warning("Invalid patient details entered")
        return
    
    var stroke_time_text = stroke_time_field.text.strip_edges()
    var stroke_time = int(stroke_time_text) if stroke_time_text.is_valid_int() else 0
    
    var patient_data = {
        'hospital_id': hosp_id_field.text.strip_edges(),
        'name': patient_name_field.text.strip_edges(),
        'age': int(age_field.text.strip_edges()),
        'gender': _get_gender_string(gender_field.selected),
        'stroke_time': stroke_time,
        'dominant_hand': _get_hand_string(dominant_hand_field.selected),
        'affected_hand': _get_affected_hand_string(affected_hand_field.selected),
        'comments': comments_field.text.strip_edges()
    }
    
    patient_db.add_patient(
        patient_data['hospital_id'],
        patient_data['name'],
        patient_data['age'],
        patient_data['gender'],
        patient_data['stroke_time'],
        patient_data['dominant_hand'],
        patient_data['affected_hand'],
        patient_data['comments']
    )
    
    _save_patient_data()
    _refresh_patient_data()
    _clear_form_fields()

func _on_patient_list_item_selected(index: int) -> void:
    if index < 0 or index >= cached_patients.size():
        return
        
    patient_selected = index
    var current_patient = cached_patients[patient_selected]
    
    _set_training_hand(current_patient['affected_hand'])
    
    patient_display.clear()
    patient_display.add_text(_create_patient_display_text(current_patient))

func _on_patient_list_item_activated(index: int) -> void:
    if index < 0 or index >= cached_patients.size():
        return
        
    patient_selected = index
    login_to_patient.show()
    patient_name_label.text = patient_list.get_item_text(index)
    patient_name_label.visible = true

func _on_delete_pressed() -> void:
    if patient_selected >= 0:
        auth_window.show()
        password_field.clear()
        password_field.grab_focus()

func _on_delete_login_pressed() -> void:
    if password_field.text != ADMIN_PASSWORD:
        auth_window.hide()
        return
    
    if cached_patients.is_empty() or patient_selected < 0:
        auth_window.hide()
        return
    
    var patient_to_remove = cached_patients[patient_selected]
    patient_db.remove_patient(patient_to_remove['hospital_id'])
    
    _save_patient_data()
    _refresh_patient_data()
    
    patient_selected = -1
    patient_display.clear()
    auth_window.hide()

func _on_login_button_pressed() -> void:
    if patient_selected < 0 or patient_selected >= cached_patients.size():
        return
        
    var current_patient = cached_patients[patient_selected]
    
    # Set global state
    patient_db.current_patient_id = current_patient['hospital_id']
    GlobalScript.change_patient()
    GlobalSignals.current_patient_id = current_patient['hospital_id']
    GlobalSignals.affected_hand = current_patient['affected_hand']
    
    _save_patient_data()
    get_tree().change_scene_to_file(SELECT_GAME_SCENE_PATH)

# Window management
func _on_auth_close_requested() -> void:
    auth_window.hide()

func _on_close_button_pressed() -> void:
    invalid_details.hide()
    login_to_patient.hide()
