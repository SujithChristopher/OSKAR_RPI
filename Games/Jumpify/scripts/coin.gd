extends Area3D

# Simple coin script that works with the main level system
@export var rotation_speed = 2.0
@export var bob_height = 0.2
@export var bob_speed = 3.0
@onready var coin_sound: AudioStreamPlayer3D = $CoinSound

var initial_y_position: float
var time_passed = 0.0
var collected = false

func _ready():
    # Store initial Y position for bobbing animation
    initial_y_position = global_position.y
    
    # Make sure collision is set up properly
    set_collision_layer_value(1, false)  # Don't collide with other objects
    set_collision_mask_value(1, true)    # Detect player on layer 1

func _process(delta):
    if collected:
        return
        
    # Rotate the coin
    rotate_y(rotation_speed * delta)
    
    # Add bobbing motion
    time_passed += delta
    var bob_offset = sin(time_passed * bob_speed) * bob_height
    global_position.y = initial_y_position + bob_offset

func _on_body_entered(body):
    if collected:
        return
        
    collected = true
   
    play_collection_effect()

func play_collection_effect():
    # Simple scale animation
    coin_sound.play()
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector3(1.5, 1.5, 1.5), 0.1)
    tween.tween_property(self, "scale", Vector3.ZERO, 0.2)
    
    # Disable collision to prevent multiple collections
    set_collision_layer_value(1, false)
    set_collision_mask_value(1, false)
