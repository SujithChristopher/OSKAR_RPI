extends Label

func _ready() -> void:
  _hide()

  SignalBus.score_updated.connect(_hide.bind())
  SignalBus.score_new_record.connect(_show.bind())

func _hide(_score: int = 0) -> void:
  visible = false

func _show() -> void:
  visible = true
