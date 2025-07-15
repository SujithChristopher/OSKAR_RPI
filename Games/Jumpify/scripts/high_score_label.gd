extends Label

var high_score_text = "High Score: %d"

func _ready() -> void:
    # Optional: For translations (if needed)
    high_score_text = tr(high_score_text)
    SignalBus.score_new_record.connect(_on_new_record.bind())
    _update_text()

func _on_new_record() -> void:
    _update_text()

func _update_text() -> void:
    self.text = high_score_text % Scoreboard.high_score()
    self.visible = Scoreboard.high_score() > 0
