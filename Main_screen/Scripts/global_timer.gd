extends Node

var total_play_time := 0.0
var timer_running := false


func _process(delta: float) -> void:
	if timer_running:
		total_play_time += delta

func start_timer() -> void:
	timer_running = true

func stop_timer() -> void:
	timer_running = false

func resume_timer() -> void:
	timer_running = true 

func reset_timer() -> void:
	total_play_time = 0.0
	timer_running = false

func get_time() -> float:
	return total_play_time
