extends Node

signal SignalBus

@export var selected_training_hand: String = ""
@export var affected_hand: String = ""
@export var global_scalar_x:float = 1.0
@export var global_scalar_y:float = 1.0

@export var inflated_workspace: PackedVector2Array

@export var current_patient_id:String = ""
@export var data_path:String = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + "//NOARK//data"


@export var ball_position: Vector2

func enable_game_buttons(enable: bool) -> void:
	for button in get_tree().get_nodes_in_group("GameButtons"):
		button.disabled = not enable
