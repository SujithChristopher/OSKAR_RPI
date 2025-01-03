extends Area2D

signal hit
signal scored

func _on_body_entered(body: Node2D) -> void:
	print(body.name)
	if body.name == "pilot":
		hit.emit()


func _on_score_area_body_entered(body: Node2D) -> void:
	if body.name == "pilot":
		scored.emit()
