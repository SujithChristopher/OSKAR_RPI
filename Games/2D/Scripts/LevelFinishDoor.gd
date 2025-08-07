extends Area2D

# Define the next scene to load in the inspector
@export var next_scene : PackedScene
var SELECTGAME = preload("res://Main_screen/Scenes/select_game.tscn")

# Load next level scene when player collide with level finish door.
func _on_body_entered(body):
    if body.is_in_group("Player2D"):
        get_tree().call_group("Player2D", "death_tween") # death_tween is called here just to give the feeling of player entering the door.
        AudioManager.level_complete_sfx.play()
        SceneTransition.load_scene(next_scene)


func _on_logout_button_pressed() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_packed(SELECTGAME)
