extends Area3D

# Simple coin script that works with the main level system
@export var rotation_speed = 2.0
@export var bob_height = 0.2
@export var bob_speed = 3.0

# Movement properties (similar to enemy)
@export_group("Movement")
@export var min_speed = 0.5
@export var max_speed = 1.0

@onready var coin_sound: AudioStreamPlayer3D = $CoinSound

var initial_y_position: float
var time_passed = 0.0
var collected = false
var velocity: Vector3

func _ready():
    # Store initial Y position for bobbing animation
    add_to_group("coins")
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
    var bob_offset = sin(time_passed * bob_speed) * bob_height
    global_position.y = initial_y_position + bob_offset

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
        #SignalBus.coin_collected.emit()  # Signal the main game
        play_collection_effect()

func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
    queue_free()

func play_collection_effect():
    
    SignalBus.coin_collected.emit()
    coin_sound.play()

    var tween = create_tween()
    tween.tween_property(self, "scale", Vector3(1.5, 1.5, 1.5), 0.1)
    tween.tween_property(self, "scale", Vector3.ZERO, 0.2)

    # Disable collision to prevent multiple collections
    set_collision_layer_value(1, false)
    set_collision_mask_value(1, false)

    await tween.finished  # <--- This line is critical
    queue_free()
    
    
    
#anim


#extends Area3D
## Improved coin script with fixed collision detection and proper initialization
#
#@export var rotation_speed = 2.0
#@export var bob_height = 0.2
#@export var bob_speed = 3.0
#
## Movement properties
#@export_group("Movement")
#@export var min_speed = 0.5
#@export var max_speed = 1.0
#
#@onready var coin_sound: AudioStreamPlayer3D = $CoinSound
#@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
#@onready var collision_shape: CollisionShape3D = $CollisionShape3D
#
#var initial_y_position: float
#var time_passed = 0.0
#var collected = false
#var velocity: Vector3
#var original_material: Material
#var is_initialized = false
#
#func _ready():
    #print("=== COIN READY ===")
    #
    ## Add to coins group
    #add_to_group("coins")
    #
    ## Set up collision layers and masks properly
    ## Layer 3 for coins, mask 1 for player detection
    #collision_layer = 4  # Binary: 100 (layer 3)
    #collision_mask = 1   # Binary: 001 (layer 1 - player layer)
    #
    ## Ensure Area3D is set up correctly
    #monitoring = true
    #monitorable = true
    #
    ## Verify collision shape exists
    #if not collision_shape:
        #print("WARNING: No CollisionShape3D found! Coin won't detect collisions.")
        ## Try to find it in children
        #for child in get_children():
            #if child is CollisionShape3D:
                #collision_shape = child
                #print("Found CollisionShape3D in children")
                #break
    #
    ## Store original material for fading
    #setup_original_material()
    #
    ## Connect signals properly
    #setup_signals()
    #
    ## Remove the test timer - this was causing premature collection
    ## create_timer_test()
#
#func setup_original_material():
    #if not mesh_instance:
        #print("WARNING: No MeshInstance3D found!")
        #return
        #
    #if mesh_instance.material_override:
        #original_material = mesh_instance.material_override
    #elif mesh_instance.get_surface_override_material(0):
        #original_material = mesh_instance.get_surface_override_material(0)
    #else:
        ## Create a default material if none exists
        #original_material = StandardMaterial3D.new()
        #original_material.albedo_color = Color.GOLD
#
#func setup_signals():
    ## Connect collision signal
    #if not body_entered.is_connected(_on_body_entered):
        #body_entered.connect(_on_body_entered)
        #print("Connected body_entered signal")
    #
    ## Also connect area_entered for Area3D-based players
    #if not area_entered.is_connected(_on_area_entered):
        #area_entered.connect(_on_area_entered)
        #print("Connected area_entered signal")
#
#func create_timer_test():
    ## Temporary test function - REMOVED to prevent auto-collection
    ## Only uncomment for debugging purposes
    #pass
#
#func _physics_process(delta):
    #if collected or not is_initialized:
        #return
    #
    ## Move the coin forward
    #global_position += velocity * delta
        #
    ## Rotate the coin
    #rotate_y(rotation_speed * delta)
    #
    ## Add bobbing motion
    #time_passed += delta
    #var bob_offset = sin(time_passed * bob_speed) * bob_height
    #global_position.y = initial_y_position + bob_offset
#
#func initialize(start_position: Vector3) -> void:
    #print("Initializing coin at position: ", start_position)
    #
    ## Set position first
    #global_position = start_position
    #initial_y_position = start_position.y
    #
    ## Set up movement direction
    #var target = Vector3.BACK
    #look_at(global_position + target, Vector3.UP)
    #
    ## Set random speed
    #var random_speed = randf_range(min_speed, max_speed)
    #velocity = -global_transform.basis.z * random_speed  # Use transform basis for direction
    #
    #is_initialized = true
    #print("Coin initialized with velocity: ", velocity)
#
#func _on_body_entered(body: Node3D) -> void:
    #print("BODY COLLISION DETECTED with: ", body.name, " (type: ", body.get_class(), ")")
    #handle_player_collision(body)
#
#func _on_area_entered(area: Area3D) -> void:
    #print("AREA COLLISION DETECTED with: ", area.name, " (type: ", area.get_class(), ")")
    #handle_player_collision(area)
#
#func handle_player_collision(collider: Node) -> void:
    #if collected:
        #print("Coin already collected, ignoring collision")
        #return
    #
    ## Multiple ways to detect player
    #var is_player = false
    #
    ## Check if it has player method
    #if collider.has_method("is_player"):
        #is_player = collider.is_player()
    ## Check name
    #elif collider.name.to_lower().contains("player"):
        #is_player = true
    ## Check group membership
    #elif collider.is_in_group("player"):
        #is_player = true
    ## Check parent if this is a child node
    #elif collider.get_parent() and collider.get_parent().name.to_lower().contains("player"):
        #is_player = true
    #elif collider.get_parent() and collider.get_parent().is_in_group("player"):
        #is_player = true
    #
    #if is_player:
        #print("PLAYER DETECTED - COLLECTING COIN")
        #collect_coin()
    #else:
        #print("Non-player collision ignored: ", collider.name)
#
#func collect_coin() -> void:
    #if collected:
        #return
        #
    #collected = true
    #print("=== COIN COLLECTED ===")
    #play_collection_effect()
#
#func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
    #if not collected:
        #print("Coin exited screen, cleaning up")
        #queue_free()
#
#func play_collection_effect() -> void:
    #print("=== PLAYING COLLECTION EFFECT ===")
    #
    ## Emit signal first
    #if SignalBus:
        #SignalBus.coin_collected.emit()
        #print("Coin collected signal emitted")
    #else:
        #print("WARNING: SignalBus not found!")
    #
    ## Play sound
    #if coin_sound:
        #coin_sound.play()
        #print("Coin sound played")
    #
    ## Disable collision detection
    #monitoring = false
    #monitorable = false
    #collision_mask = 0
    #collision_layer = 0
    #
    ## Stop movement
    #velocity = Vector3.ZERO
    #
    ## Create visual effects
    #create_plus_one_popup()
    #start_collection_animation()
#
#func create_plus_one_popup():
    #print("Creating +1 popup")
    #
    ## Create a 3D label for +1 effect
    #var label_3d = Label3D.new()
    #label_3d.text = "+1"
    #label_3d.font_size = 32
    #label_3d.modulate = Color.YELLOW
    #label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    #
    ## Position it above the coin
    #var parent_node = get_parent()
    #if parent_node:
        #parent_node.add_child(label_3d)
        #label_3d.global_position = global_position + Vector3(0, 1, 0)
        #
        ## Animate the +1 popup
        #var popup_tween = create_tween()
        #popup_tween.set_parallel(true)
        #
        ## Move up and fade out
        #popup_tween.tween_property(label_3d, "global_position", 
            #label_3d.global_position + Vector3(0, 2, 0), 1.5)
        #popup_tween.tween_property(label_3d, "modulate:a", 0.0, 1.5)
        #
        ## Clean up the label
        #popup_tween.finished.connect(func(): 
            #if is_instance_valid(label_3d):
                #label_3d.queue_free()
        #)
#
#func start_collection_animation():
    #print("Starting coin disappear animation")
    #
    #if not mesh_instance:
        #print("No mesh instance found, skipping animation")
        #queue_free()
        #return
    #
    ## Create a material for fading
    #var fade_material: StandardMaterial3D
    #
    #if original_material and original_material is StandardMaterial3D:
        #fade_material = original_material.duplicate()
    #else:
        #fade_material = StandardMaterial3D.new()
        #fade_material.albedo_color = Color.GOLD
    #
    ## Enable transparency
    #fade_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    #mesh_instance.material_override = fade_material
    #
    ## Create the animation tween
    #var tween = create_tween()
    #tween.set_parallel(true)
    #
    ## Fade out
    #tween.tween_method(update_coin_alpha, 1.0, 0.0, 1.0)
    #
    ## Scale up slightly
    #tween.tween_property(self, "scale", Vector3(1.2, 1.2, 1.2), 0.5)
    #
    ## Float up
    #tween.tween_property(self, "global_position", 
        #global_position + Vector3(0, 0.5, 0), 1.0)
    #
    ## Clean up after animation - NO AWAIT HERE!
    #tween.finished.connect(cleanup_coin)
#
#func cleanup_coin():
    #print("Coin collection animation complete")
    #if is_instance_valid(self):
        #queue_free()
#
#func update_coin_alpha(alpha: float):
    #if mesh_instance and mesh_instance.material_override:
        #var material = mesh_instance.material_override as StandardMaterial3D
        #if material:
            #material.albedo_color.a = alpha
            #
            
            
