extends Node

var total_play_time := 0.0
var timer_running := false
var timer_paused := false

const SAVE_PATH := "user://playtime_data.json"

func _process(delta: float) -> void:
	if timer_running and not timer_paused:
		total_play_time += delta

func start_timer() -> void:
	timer_running = true
	timer_paused = false

func stop_timer() -> void:
	timer_running = false
	timer_paused = false

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

func save_play_time(patient_id: String) -> void:
	var data := {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	
	if file:
		var content := file.get_as_text()
		if content.length() > 0:
			data = JSON.parse_string(content)
		file.close()
	
	# Add new playtime for today
	var date := Time.get_date_string_from_system()  # e.g., "2025-05-02"
	if not data.has(patient_id):
		data[patient_id] = []
	
	data[patient_id].append({
		"date": date,
		"time_played": int(total_play_time / 60.0 )  # save in minutes
	})

	file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("✔ Saved total playtime for", patient_id)
	else:
		print("❌ Failed to write file.")
