extends Node

var config = ConfigFile.new()
var save_path = "user://config.cfg"

var score = 0
var combo = 0

func _ready():
  if config.load(save_path) != OK:
    print("Failed to load config, creating a new one.")
    config.set_value("stats", "high_score", 0)
    config.save(save_path)

func add_score(value: int = 1) -> void:
  combo += 1
  score += value * combo
  SignalBus.score_updated.emit(score)

func reset_combo() -> void:
  combo = 0

func reset_score() -> void:
  score = 0
  SignalBus.score_updated.emit(score)

func record_score():
  if score > high_score():
    config.set_value("stats", "high_score", score)
    config.save(save_path)
    SignalBus.score_new_record.emit()

func high_score() -> int:
  return config.get_value("stats", "high_score", 0)

func add_coin_score(value: int = 1) -> void:
    score += value
    SignalBus.score_updated.emit(score)
