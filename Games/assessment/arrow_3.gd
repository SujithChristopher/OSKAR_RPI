extends Node2D
@onready var path_follow_2d: PathFollow2D = $Path2D/PathFollow2D

@export var speed = 0.5

func _process(delta: float) -> void:
	path_follow_2d.progress += speed
