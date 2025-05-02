extends Node

var SCORE_FILE_PATH := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + "/NOARK/gamedata/scores.json"

func save_score(game_name: String, score: int, patient_id: String) -> void:
	var data := load_scores()

	if not data.has(game_name):
		data[game_name] = []

	data[game_name].append({
		"score": score,
		"timestamp": Time.get_datetime_string_from_system(),
		"patient_id": patient_id
	})

	var file = FileAccess.open(SCORE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.new().stringify(data, "\t"))
		file.close()
	else:
		push_error("❌ Failed to write to score file: " + SCORE_FILE_PATH)


func load_scores() -> Dictionary:
	if not FileAccess.file_exists(SCORE_FILE_PATH):
		return {}  # If file doesn't exist, return empty dict

	var file = FileAccess.open(SCORE_FILE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()

		var json = JSON.new()
		var err = json.parse(content)
		if err == OK:
			return json.get_data()
		else:
			push_error("❌ Failed to parse JSON: " + str(json.get_error_message()))
			return {}
	else:
		push_error("❌ Failed to open score file.")
		return {}


func get_top_scores(game_name: String, top_count: int = 3, for_patient_id: String = "") -> Array:
	var scores = load_scores().get(game_name, [])

	if for_patient_id != "":
		scores = scores.filter(func(entry): return entry.patient_id == for_patient_id)

	scores.sort_custom(func(a, b): return a.score > b.score)

	return scores.slice(0, min(top_count, scores.size()))
