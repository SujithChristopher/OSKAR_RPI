extends Label

var score_text = "Score: %d" # This is where you define the format

func _ready() -> void:
    # If you're translating text, make sure the translation includes `%d`
    score_text = tr(score_text)
    _update_text(0)

    SignalBus.score_updated.connect(_on_enemy_squashed.bind())

func _on_enemy_squashed(score: int) -> void:
    _update_text(score)

func _update_text(score: int) -> void:
    text = score_text % score
