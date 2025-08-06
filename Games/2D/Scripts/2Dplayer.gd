#extends CharacterBody2D
#
## --------- VARIABLES ---------- #
#
#@export_category("Player Properties") # You can tweak these changes according to your likings
#@export var move_speed : float = 400
#@export var jump_force : float = 1200
#@export var gravity : float = 30
#@export var max_jump_count : int = 2
#var jump_count : int = 2
#
#@export_category("Toggle Functions") # Double jump feature is disable by default (Can be toggled from inspector)
#@export var double_jump : = false
#
#var is_grounded : bool = false
#var movement_enabled : bool = true
#
#@onready var player_sprite = $AnimatedSprite2D
#@onready var spawn_point = %SpawnPoint
#@onready var particle_trails = $ParticleTrails
#@onready var death_particles = $DeathParticles
#
## --------- BUILT-IN FUNCTIONS ---------- #
#
#func _physics_process(_delta):
    #movement()
#
#func _process(_delta):
    #player_animations()
    #flip_player()
    #
## --------- CUSTOM FUNCTIONS ---------- #
#
## <-- Player Movement Code -->
#func movement():
    ## Gravity
    #if !is_on_floor():
        #velocity.y += gravity
    #elif is_on_floor():
        #jump_count = max_jump_count
    #
    #handle_jumping()
    #
    ## Move Player
    #var inputAxis = 0.0
    #if movement_enabled:
        #inputAxis = Input.get_axis("Left", "Right")
    #velocity.x = inputAxis * move_speed
    #move_and_slide()
#
## Handles jumping functionality (double jump or single jump, can be toggled from inspector)
#func handle_jumping():
    #if Input.is_action_just_pressed("Jump") and movement_enabled:
        #if is_on_floor() and !double_jump:
            #jump()
        #elif double_jump and jump_count > 0:
            #jump()
            #jump_count -= 1
#
## Player jump
#func jump():
    #jump_tween()
    #print(AudioManager.jump_sfx)
    #AudioManager.jump_sfx.play()
    #velocity.y = -jump_force
#
## Handle Player Animations
#func player_animations():
    #particle_trails.emitting = false
    #
    #if is_on_floor():
        #if abs(velocity.x) > 0:
            #particle_trails.emitting = true
            #player_sprite.play("Walk", 1.5)
        #else:
            #player_sprite.play("Idle")
    #else:
        #player_sprite.play("Jump")
#
## Flip player sprite based on X velocity
#func flip_player():
    #if velocity.x < 0: 
        #player_sprite.flip_h = true
    #elif velocity.x > 0:
        #player_sprite.flip_h = false
#
## Tween Animations
#func death_tween():
    #movement_enabled = false
    #var tween = create_tween()
    #tween.tween_property(player_sprite, "scale", Vector2.ZERO, 0.15)
    #tween.parallel().tween_property(player_sprite, "position", Vector2.ZERO, 0.15)
    #await tween.finished
    #global_position = spawn_point.global_position
    #await get_tree().create_timer(0.3).timeout
    #movement_enabled = true
    #AudioManager.respawn_sfx.play()
    #respawn_tween()
#
#func respawn_tween():
    #var tween = create_tween()
    #tween.stop(); tween.play()
    #tween.tween_property(player_sprite, "scale", Vector2.ONE, 0.15) 
    #tween.parallel().tween_property(player_sprite, "position", Vector2(0,-48), 0.15)
#
#func jump_tween():
    #var tween = create_tween()
    #tween.tween_property(self, "scale", Vector2(0.7, 1.4), 0.1)
    #tween.tween_property(self, "scale", Vector2.ONE, 0.1)
#
## --------- SIGNALS ---------- #
#
## Reset the player's position to the current level spawn point if collided with any trap
#func _on_collision_body_entered(body):
    #if body.is_in_group("Traps"):
        #AudioManager.death_sfx.play()
        #death_particles.emitting = true
        #death_tween()
    

#Randomreach code


#extends CharacterBody2D
#
## Movement configuration
#@export var movement_smoothing: float = 1.0
#@export var debug_mode: bool = false
#@export var use_scaled_position: bool = false
#
## Movement bounds
#const MIN_BOUNDS = Vector2(44, 40)
#const MAX_BOUNDS = Vector2(1105, 577)
#
## Movement variables
#var network_position = Vector2.ZERO
#var zero_offset = Vector2.ZERO
#
## Node references
#@onready var sprite = $Sprite2D
#
#func _ready() -> void:
    #network_position = Vector2.ZERO
       #
#
#func _physics_process(_delta):
    #_update_player_position()
    ##_update_sprite_direction()
#
#func _update_player_position() -> void:
    ## Get position from different sources based on mode
    #if debug_mode:
        #network_position = get_global_mouse_position()
    #elif use_scaled_position:
        #network_position = GlobalScript.scaled_network_position
    #else:
        #network_position = GlobalScript.network_position
#
    ## Apply movement if we have valid network position
    #if network_position != Vector2.ZERO:
        ## Apply zero offset calibration
        #network_position = network_position - zero_offset
        #
        ## Smooth movement to target position
        #position = position.lerp(network_position, movement_smoothing)
       #
        #
        ## Clamp position within bounds
        #position.x = clamp(position.x, MIN_BOUNDS.x, MAX_BOUNDS.x)
        #position.y = clamp(position.y, MIN_BOUNDS.y, MAX_BOUNDS.y)
#
## Calibration function - call this to set current position as zero point
#func calibrate_zero_position() -> void:
    #zero_offset = network_position
    #print("Zero position calibrated to: ", zero_offset)
    #



             
#extends CharacterBody2D
#
## --------- SIMPLE NETWORK CONTROL ---------- #
#@export var use_network_control : bool = true
#@export var ground_level : float = 577
#@export var movement_speed : float = 10.0
#@export var jump_height : float = 500.0
#
## Player state
#var network_position = Vector2.ZERO
#var movement_enabled : bool = true
#var network_initialized : bool = false
#
## Node references
#@onready var player_sprite = $AnimatedSprite2D
#@onready var particle_trails = $ParticleTrails
#@onready var death_particles = $DeathParticles
#
#func _ready():
    ## Start at ground level
    #global_position.y = ground_level
    #global_position.x = 100  # Set a default X position
    #
    ## Initialize network position to current position to prevent jumping
    #if use_network_control:
        ## Wait a frame for GlobalScript to be ready
        #await get_tree().process_frame
        #_initialize_network_position()
    #
    #print("Player started at ground level: ", ground_level)
#
#func _physics_process(delta):
    #if not movement_enabled:
        #return
        #
    #if use_network_control:
        #_network_control(delta)
    #else:
        #_keyboard_control(delta)
    #
    #_update_animations()
#
#func _initialize_network_position():
    ## Check if GlobalScript has valid network position
    #if GlobalScript and GlobalScript.has_method("get_network_position2D"):
        #network_position = GlobalScript.get_network_position2D()
    #elif GlobalScript and "network_position2D" in GlobalScript:
        #network_position = GlobalScript.network_position2D
    #else:
        ## If no valid network position, use current player position
        #network_position = global_position
    #
    ## If network position seems invalid (like Vector2.ZERO or extreme values), use ground position
    #if network_position == Vector2.ZERO or abs(network_position.y) > 2000 or abs(network_position.x) > 5000:
        #network_position = Vector2(global_position.x, ground_level)
        #print("Network position invalid, using ground position: ", network_position)
    #
    #network_initialized = true
    #print("Network position initialized: ", network_position)
#
#func _network_control(delta):
    ## Don't move until network is properly initialized
    #if not network_initialized:
        #return
    #
    ## Get network position from GlobalScript's network_position2D
    #var new_network_position = Vector2.ZERO
    #
    #if GlobalScript and GlobalScript.has_method("get_network_position2D"):
        #new_network_position = GlobalScript.get_network_position2D()
    #elif GlobalScript and "network_position2D" in GlobalScript:
        #new_network_position = GlobalScript.network_position2D
    #else:
        #return  # No valid network data
    #
    ## Validate the new network position
    #if new_network_position == Vector2.ZERO or abs(new_network_position.y) > 2000 or abs(new_network_position.x) > 5000:
        #return  # Skip invalid network data
    #
    #network_position = new_network_position
    #
    ## Move to absolute X position using smooth interpolation
    #global_position.x = lerp(global_position.x, network_position.x, movement_speed * delta)
    #
    ## Move to absolute Y position using smooth interpolation
    #global_position.y = lerp(global_position.y, network_position.y, movement_speed * delta)
#
#func _keyboard_control(delta):
    ## Traditional platformer controls - using absolute positioning instead of velocity
    #var input = Input.get_axis("Left", "Right")
    #
    ## Move using absolute position changes
    #if input != 0:
        #global_position.x += input * 400 * delta
    #
    ## Handle jumping with absolute positioning
    #if Input.is_action_just_pressed("Jump"):
        #global_position.y -= jump_height
    #
    ## Apply gravity manually by moving position down
    #if global_position.y < ground_level:
        #global_position.y += 30 * delta  # Gravity effect
    #else:
        #global_position.y = ground_level  # Snap to ground
#
## Remove the _do_jump() function since we're not using it anymore
#
#func _update_animations():
    ## Get movement state based on position changes instead of velocity
    #var is_moving = false
    #var movement_direction = 0
    #
    #if use_network_control:
        ## Check if network position is different from current position
        #var x_diff = network_position.x - global_position.x
        #is_moving = abs(x_diff) > 10
        #movement_direction = sign(x_diff)
    #else:
        ## For keyboard control, check if input is being pressed
        #var input = Input.get_axis("Left", "Right")
        #is_moving = abs(input) > 0.1
        #movement_direction = sign(input)
    #
    ## Animation logic - check if player is above ground level
    #if global_position.y < ground_level - 10:
        #player_sprite.play("Jump")
        #particle_trails.emitting = false
    #elif is_moving:
        #player_sprite.play("Walk")
        #particle_trails.emitting = true
    #else:
        #player_sprite.play("Idle")
        #particle_trails.emitting = false
    #
    ## Flip sprite based on movement direction
    #if abs(movement_direction) > 0:
        #if movement_direction < 0:
            #player_sprite.flip_h = true
        #elif movement_direction > 0:
            #player_sprite.flip_h = false
#
## --------- COLLISION HANDLING ---------- #
#func _on_collision_body_entered(body):
    #if body.is_in_group("Traps"):
        #_die()
#
#func _die():
    #movement_enabled = false
    #death_particles.emitting = true
    #
    #if AudioManager and AudioManager.death_sfx:
        #AudioManager.death_sfx.play()
    #
    ## Simple death animation
    #var tween = create_tween()
    #tween.tween_property(player_sprite, "scale", Vector2.ZERO, 0.2)
    #await tween.finished
    #
    ## Respawn at absolute position
    #global_position.y = ground_level
    #global_position.x = 100  # Reset X position
    #
    ## Respawn animation
    #tween = create_tween()
    #tween.tween_property(player_sprite, "scale", Vector2.ONE, 0.2)
    #
    #await get_tree().create_timer(0.3).timeout
    #movement_enabled = true
#
## --------- INPUT EVENTS ---------- #
#func _input(event):
    #if event.is_action_pressed("ui_accept"):  # Space key
        #use_network_control = !use_network_control
        #print("Control mode: ", "Network" if use_network_control else "Keyboard")
        
        
#New code


#extends CharacterBody2D
#
## Movement configuration
#@export var movement_smoothing: float = 1.0
#@export var debug_mode: bool = false
#@export var use_scaled_position: bool = false
#@export var ground_level: float = 577
#
## Movement bounds
#const MIN_BOUNDS = Vector2(44, 40)
#const MAX_BOUNDS = Vector2(1105, 577)
#
## Movement variables
#var network_position = Vector2.ZERO
#var zero_offset = Vector2.ZERO
#var previous_position = Vector2.ZERO
#
## Node references
#@onready var sprite = $Sprite2D
#@onready var player_sprite = $AnimatedSprite2D
#@onready var particle_trails = $ParticleTrails
#
#func _ready() -> void:
    #network_position = Vector2.ZERO
    #previous_position = position
       #
#func _physics_process(_delta):
    #_update_player_position()
    #_update_animations()
#
#func _update_player_position() -> void:
    ## Store previous position for animation calculations
    #previous_position = position
    #
    ## Get position from different sources based on mode
    #if debug_mode:
        #network_position = get_global_mouse_position()
    #elif use_scaled_position:
        #network_position = GlobalScript.scaled_network_position
    #else:
        #network_position = GlobalScript.network_position
    #
    ## Apply movement if we have valid network position
    #if network_position != Vector2.ZERO:
        ## Apply zero offset calibration
        #network_position = network_position - zero_offset
        #
        ## Smooth movement to target position
        #position = position.lerp(network_position, movement_smoothing)
        #
        ## Clamp position within bounds
        #position.x = clamp(position.x, MIN_BOUNDS.x, MAX_BOUNDS.x)
        #position.y = clamp(position.y, MIN_BOUNDS.y, MAX_BOUNDS.y)
#
#func _update_animations():
    ## Calculate movement based on position changes
    #var position_diff = position - previous_position
    #var is_moving = position_diff.length() > 0.5  # Threshold for detecting movement
    #var movement_direction = sign(position_diff.x)
    #
    ## Animation logic - check if player is above ground level
    #if position.y < ground_level - 10:
        #if player_sprite:
            #player_sprite.play("Jump")
        #if particle_trails:
            #particle_trails.emitting = false
    #elif is_moving:
        #if player_sprite:
            #player_sprite.play("Walk")
        #if particle_trails:
            #particle_trails.emitting = true
    #else:
        #if player_sprite:
            #player_sprite.play("Idle")
        #if particle_trails:
            #particle_trails.emitting = false
    #
    ## Flip sprite based on movement direction
    #if abs(movement_direction) > 0 and player_sprite:
        #if movement_direction < 0:
            #player_sprite.flip_h = true
        #elif movement_direction > 0:
            #player_sprite.flip_h = false
#
## Calibration function - call this to set current position as zero point
#func calibrate_zero_position() -> void:
    #zero_offset = network_position
    #print("Zero position calibrated to: ", zero_offset)



#tyuyju


extends CharacterBody2D

# Movement configuration
@export var movement_smoothing: float = 1.0
@export var debug_mode: bool = false
@export var use_scaled_position: bool = false
@export var ground_level: float = 577

# Movement bounds
const MIN_BOUNDS = Vector2(44, 40)
const MAX_BOUNDS = Vector2(1105, 577)

# Movement variables
var network_position = Vector2.ZERO
var zero_offset = Vector2.ZERO
var previous_position = Vector2.ZERO
var last_movement_direction = 0  # Store the last significant movement direction

# Node references
@onready var sprite = $Sprite2D
@onready var player_sprite = $AnimatedSprite2D
@onready var particle_trails = $ParticleTrails

func _ready() -> void:
    network_position = Vector2.ZERO
    previous_position = position
       
func _physics_process(_delta):
    _update_player_position()
    _update_animations()

func _update_player_position() -> void:
    # Store previous position for animation calculations
    previous_position = position
    
    # Get position from different sources based on mode
    if debug_mode:
        network_position = get_global_mouse_position()
    elif use_scaled_position:
        network_position = GlobalScript.scaled_network_position
    else:
        network_position = GlobalScript.network_position
    
    # Apply movement if we have valid network position
    if network_position != Vector2.ZERO:
        # Apply zero offset calibration
        network_position = network_position - zero_offset
        
        # Smooth movement to target position
        position = position.lerp(network_position, movement_smoothing)
        
        # Clamp position within bounds
        position.x = clamp(position.x, MIN_BOUNDS.x, MAX_BOUNDS.x)
        position.y = clamp(position.y, MIN_BOUNDS.y, MAX_BOUNDS.y)

func _update_animations():
    # Calculate movement based on position changes
    var position_diff = position - previous_position
    var is_moving = position_diff.length() > 2.0  # Increased threshold to prevent jittering
    
    # Only update direction if movement is significant enough
    if abs(position_diff.x) > 3.0:  # Only change direction for meaningful horizontal movement
        last_movement_direction = sign(position_diff.x)
    
    # Animation logic - check if player is above ground level
    if position.y < ground_level - 10:
        if player_sprite:
            player_sprite.play("Jump")
        if particle_trails:
            particle_trails.emitting = false
    elif is_moving:
        if player_sprite:
            player_sprite.play("Walk")
        if particle_trails:
            particle_trails.emitting = true
    else:
        if player_sprite:
            player_sprite.play("Idle")
        if particle_trails:
            particle_trails.emitting = false
    
    # Flip sprite based on last significant movement direction (prevents constant flipping)
    if abs(last_movement_direction) > 0 and player_sprite:
        if last_movement_direction < 0:
            player_sprite.flip_h = true
        elif last_movement_direction > 0:
            player_sprite.flip_h = false

# Calibration function - call this to set current position as zero point
func calibrate_zero_position() -> void:
    zero_offset = network_position
    print("Zero position calibrated to: ", zero_offset)
