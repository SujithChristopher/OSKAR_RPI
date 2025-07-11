#extends Node
#
#var high_score_text = ""
#
#func _ready() -> void:
  #high_score_text = tr(self.text)
  #print(high_score_text)
  #SignalBus.score_new_record.connect(_on_new_record.bind())
  #_update_text()
#
#func _on_new_record() -> void:
  #_update_text()
#
#func _update_text() -> void:
  #self.text = high_score_text % Scoreboard.high_score()
#
  #if Scoreboard.high_score() > 0:
    #self.visible = true
  #else:
    #self.visible = false

extends Label

var high_score_text = "High Score: %d"

func _ready() -> void:
    # Optional: For translations (if needed)
    high_score_text = tr(self.text)
    SignalBus.score_new_record.connect(_on_new_record.bind())
    _update_text()

func _on_new_record() -> void:
    _update_text()

func _update_text() -> void:
    self.text = high_score_text % Scoreboard.high_score()
    self.visible = Scoreboard.high_score() > 0
