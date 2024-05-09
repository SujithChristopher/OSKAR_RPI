extends Button
@export var flappy: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_pressed():
	get_tree().change_scene_to_file("res://Games/PingPongGame/PingPong.tscn") # Replace with function body.


func _on_game_reach_pressed():
	get_tree().change_scene_to_file("res://Assessment/assess_game/reach.tscn") 


func _on_floppy_bird_pressed():
	
	#get_tree().current_scene.queue_free() # Instead of free()
	#var instanced_scene := flappy.instantiate()
	#get_tree().root.add_child(instanced_scene)
	#get_tree().current_scene = instanced_scene
	#get_tree().change_scene_to_packed(flappy)
	
	get_tree().change_scene_to_file.bind("res://Games/FlappyBird/game.tscn").call_deferred()
