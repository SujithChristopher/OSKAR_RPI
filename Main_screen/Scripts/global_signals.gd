extends Node

signal SignalBus

@export var global_scalar_x:float = 1.0
@export var global_scalar_y:float = 1.0

@export var inflated_workspace: PackedVector2Array

@export var current_patient_id:String = ""
@export var data_path:String = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + "//NOARK//data"


@export var ball_position: Vector2

#@export var game_data_path:String = data_path + '//' + current_patient_id + '//' + 'GameData'
