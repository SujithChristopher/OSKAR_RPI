extends CharacterBody2D

var network_position = Vector2.ZERO
var zero_offset = Vector2.ZERO
@onready var adapt_toggle:bool = false

func _physics_process(delta: float) -> void:
	if adapt_toggle:
		network_position = GlobalScript.scaled_network_position
	else:
		network_position = GlobalScript.network_position
		
	if network_position != Vector2.ZERO:
		network_position = network_position - zero_offset  + Vector2(600, 100)  
		position = position.lerp(network_position, 0.8)
	position.x = 100


func _on_adapt_rom_toggled(toggled_on: bool) -> void:
	if toggled_on:
		adapt_toggle = true
	else:
		adapt_toggle = false
