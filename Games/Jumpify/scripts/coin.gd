extends Area3D

# Simple coin script that works with the main level system
@export var rotation_speed = 2.0
#@export var bob_height = 0.2
#@export var bob_speed = 3.0

# Movement properties (similar to enemy)
@export_group("Movement")
@export var min_speed = 2.0
@export var max_speed = 4.0

@onready var coin_sound: AudioStreamPlayer3D = $CoinSound

var initial_y_position: float
var time_passed = 0.0
var collected = false
var velocity: Vector3

func _ready():
    # Store initial Y position for bobbing animation
    initial_y_position = global_position.y
    
    # Set up collision layers - coins should not collide with enemies
    set_collision_layer_value(1, false)  # Don't collide with other objects
    set_collision_layer_value(2, false)  # Don't collide with enemies
    set_collision_mask_value(1, true)    # Detect player on layer 1
    set_collision_mask_value(2, false)   # Don't detect enemies

func _process(delta):
    if collected:
        return
    
    # Move the coin forward (like enemies do)
    global_position += velocity * delta
        
    # Rotate the coin
    rotate_y(rotation_speed * delta)
    
    # Add bobbing motion
    time_passed += delta
    #var bob_offset = sin(time_passed * bob_speed) * bob_height
    #global_position.y = initial_y_position + bob_offset

func initialize(start_position: Vector3) -> void:
    # Similar to enemy initialization but simpler
    var target = Vector3.BACK
    look_at_from_position(start_position, start_position + target, Vector3.UP)
    
    var random_speed = randf_range(min_speed, max_speed)
    velocity = Vector3.FORWARD * random_speed
    velocity = velocity.rotated(Vector3.UP, rotation.y)
    
    # Update initial Y position after setting position
    initial_y_position = global_position.y

func _on_body_entered(body):
    if collected:
        return
    
    # Check if it's the player
    if body.has_method("is_player") or body.name == "Player":
        collected = true
        SignalBus.coin_collected.emit()  # Signal the main game
        play_collection_effect()

func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
    queue_free()

func play_collection_effect():
    # Simple scale animation
    coin_sound.play()
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector3(1.5, 1.5, 1.5), 0.1)
    tween.tween_property(self, "scale", Vector3.ZERO, 0.2)
    
    # Disable collision to prevent multiple collections
    set_collision_layer_value(1, false)
    set_collision_mask_value(1, false)
    
    # Remove the coin after animation
    tween.tween_callback(queue_free)
