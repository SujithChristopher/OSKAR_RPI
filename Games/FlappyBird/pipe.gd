extends Area2D
signal hit
signal scored

func _on_body_entered(body):
	hit.emit() # Replace with function body.


func _on_score_area_area_entered(area):
	scored.emit() # Replace with function body.
