extends Node


var json = JSON.new()
var path = "res://debug.json"
var debug:bool


func _ready():
	debug = JSON.parse_string(FileAccess.get_file_as_string(path))['debug']

func create_game_log_file(game, p_id):

	if debug:
		p_id = 'vvv'

	if p_id:
		print(GlobalSignals.data_path)
		print(game, p_id)

	if not DirAccess.dir_exists_absolute(GlobalSignals.data_path + '//' + p_id + '//' + 'GameData'):
		DirAccess.make_dir_recursive_absolute(GlobalSignals.data_path + '//' + p_id + '//' + 'GameData')

	var session_id = GlobalScript.session_id
	var trial_id = GlobalScript.get_next_trial_id(game)
	
	var date = Time.get_date_string_from_system()
	var game_path = "%s_S%d_T%d_%s.csv" % [game, session_id, trial_id, date]
	var game_file_path = GlobalSignals.data_path + '//' + p_id + '//' + 'GameData' + '//' + game_path

	# Check if the file exists
	if FileAccess.file_exists(game_file_path):
		print('File already exists')
		var game_file = FileAccess.open(game_file_path, FileAccess.WRITE_READ)
		return game_file
	else:
		var game_file = FileAccess.open(game_file_path, FileAccess.WRITE)
		return game_file
		
func save_score_only(game_name: String, p_id: String, score: int) -> void:
	var scores_path = GlobalSignals.data_path + "/" + p_id + "/GameData"
	if not DirAccess.dir_exists_absolute(scores_path):
		DirAccess.make_dir_recursive_absolute(scores_path)

	var score_file = scores_path + "/" + game_name + "_scores.csv"

	var file = FileAccess.open(score_file, FileAccess.WRITE_READ)
	if file:
		file.seek_end()  # Move to end to append
		file.store_line(str(score))
		file.flush()
		file.close()
	
