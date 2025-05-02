extends Node


var json = JSON.new()
var path = "res://debug.json"
var debug:bool


func _ready():
	debug = json.parse_string(FileAccess.get_file_as_string(path))['debug']

func create_game_log_file(game, p_id):

	if debug:
		p_id = 'vvv'

	if p_id:
		print(GlobalSignals.data_path)
		print(game, p_id)

	if not DirAccess.dir_exists_absolute(GlobalSignals.data_path + '//' + p_id + '//' + 'GameData'):
		DirAccess.make_dir_recursive_absolute(GlobalSignals.data_path + '//' + p_id + '//' + 'GameData')

	var game_path = game + '-' + Time.get_datetime_string_from_system().split('T')[0] + '.csv'

	var game_file_path = GlobalSignals.data_path + '//' + p_id + '//' + 'GameData' + '//' + game_path

	# Check if the file exists
	if FileAccess.file_exists(game_file_path):
		print('File already exists')
		var game_file = FileAccess.open(game_file_path, FileAccess.WRITE_READ)
		return game_file
	else:
		var game_file = FileAccess.open(game_file_path, FileAccess.WRITE)
		return game_file
		

func save_total_time(game: String, p_id: String, total_seconds: float):
	var folder = GlobalSignals.data_path + '//' + p_id + '//' + 'GameData'
	var filename = game + '_time_log.csv'
	var file_path = folder + '//' + filename

	if not DirAccess.dir_exists_absolute(folder):
		DirAccess.make_dir_recursive_absolute(folder)

	var file_exists = FileAccess.file_exists(file_path)
	var file = FileAccess.open(file_path, FileAccess.READ_WRITE)

	if not file_exists:
		file.store_csv_line(PackedStringArray(["date", "time_minutes"]))

	file.store_csv_line(PackedStringArray([
		Time.get_date_string_from_system(),
		str(int(total_seconds / 60.0))
	]))
	file.close()


func save_score(game: String, p_id: String, score: int):
	var folder = GlobalSignals.data_path + '//' + p_id + '//' + 'GameData'
	var file_path = folder + '//' + game + '_scores.csv'

	if not DirAccess.dir_exists_absolute(folder):
		DirAccess.make_dir_recursive_absolute(folder)

	var file_exists = FileAccess.file_exists(file_path)
	var file = FileAccess.open(file_path, FileAccess.READ_WRITE)

	if not file_exists:
		file.store_csv_line(PackedStringArray(["date", "score"]))

	file.store_csv_line(PackedStringArray([
		Time.get_date_string_from_system(),
		str(score)
	]))
	file.close()


func get_top_scores(game: String, p_id: String, top_n := 3) -> Array:
	var file_path = GlobalSignals.data_path + '//' + p_id + '//' + 'GameData' + '//' + game + '_scores.csv'
	var top_scores: Array = []

	if not FileAccess.file_exists(file_path):
		return []

	var file = FileAccess.open(file_path, FileAccess.READ)
	file.get_line() # Skip header

	while not file.eof_reached():
		var line = file.get_line()
		if line.strip_edges() == "":
			continue
		var parts = line.split(",")
		if parts.size() == 2:
			var date = parts[0]
			var score = int(parts[1])
			top_scores.append({ "date": date, "score": score })

	file.close()
	top_scores.sort_custom(func(a, b): return a["score"] > b["score"])
	return top_scores.slice(0, min(top_n, top_scores.size()))
