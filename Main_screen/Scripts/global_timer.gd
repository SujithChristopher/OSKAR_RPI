extends Node

var total_play_time := 0.0
var timer_running := false
var timer_paused := false

func _process(delta: float) -> void:
	if timer_running and not timer_paused:
		total_play_time += delta

func start_timer() -> void:
	timer_running = true
	timer_paused = false

func stop_timer() -> void:
	timer_running = false
	timer_paused = false
	#Manager.save_total_time("RandomReach", GlobalSignals.current_patient_id, total_play_time)

func pause_timer() -> void:
	if timer_running:
		timer_paused = true

func resume_timer() -> void:
	if timer_running and timer_paused:
		timer_paused = false

func reset_timer() -> void:
	total_play_time = 0.0
	timer_running = false
	timer_paused = false

func get_time() -> float:
	return total_play_time

func save_play_time_csv(game_name: String, patient_id: String) -> void:
	# Save total time in seconds as CSV via Manager.gd
	if total_play_time > 0:
		Manager.save_total_time('RandomReach', patient_id, total_play_time)
		print("✅ Saved playtime to CSV for", patient_id)
	else:
		print("⚠ No playtime to save.")
