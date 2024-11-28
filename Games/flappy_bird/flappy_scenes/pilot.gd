extends CharacterBody2D

var network_position = Vector2.ZERO
var zero_offset = Vector2.ZERO


func _physics_process(delta: float) -> void:
	network_position = GlobalScript.network_position
	if network_position != Vector2.ZERO:
		network_position = network_position - zero_offset  + Vector2(600, 200)  
		position = position.lerp(network_position, 0.8)
