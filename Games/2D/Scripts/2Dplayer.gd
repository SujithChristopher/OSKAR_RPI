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


#Workingg

extends CharacterBody2D

# --------- VARIABLES ---------- #
@export_category("Player Properties")
@export var jump_force : float = 1200
@export var gravity : float = 30
@export var max_jump_count : int = 2
var jump_count : int = 2

@export_category("Toggle Functions")
@export var double_jump : = false
@export var use_network_input : bool = true  # Toggle between network and keyboard input

@export_category("Network Settings")
@export var position_smoothing : float = 0.1       # Smoothing factor for position updates
@export var jump_threshold_y : float = -1.0       # Y movement threshold to trigger jump
@export var network_scale_x : float = 1.0          # Scale factor for X position
@export var network_scale_y : float = 1.0          # Scale factor for Y position
@export var position_offset : Vector2 = Vector2.ZERO # Offset to apply to network position

@export_category("Keyboard Fallback")
@export var move_speed : float = 400                # Only used for keyboard input

var is_grounded : bool = false
var movement_enabled : bool = true
var target_position: Vector2
var last_network_y: float = 0.0
var network_jump_cooldown: float = 0.0
var keyboard_velocity: float = 0.0  # For keyboard fallback only

@onready var player_sprite = $AnimatedSprite2D
@onready var spawn_point = %SpawnPoint
@onready var particle_trails = $ParticleTrails
@onready var death_particles = $DeathParticles

# --------- BUILT-IN FUNCTIONS ---------- #
func _ready():
    # GlobalScript is autoloaded, so we can access it directly
    target_position = global_position
    if GlobalScript:
        last_network_y = GlobalScript.network_position2D.y
    else:
        print("Warning: GlobalScript autoload not found, falling back to keyboard input")
        use_network_input = false

func _physics_process(delta):
    if network_jump_cooldown > 0:
        network_jump_cooldown -= delta
    movement()

func _process(delta):
    player_animations()
    flip_player()

# --------- CUSTOM FUNCTIONS ---------- #
# <-- Player Movement Code -->
func movement():
    if use_network_input and GlobalScript and GlobalScript.connected:
        network_absolute_movement()
    else:
        keyboard_movement()
    
    move_and_slide()

func network_absolute_movement():
    if not movement_enabled:
        return
    
    var network_pos = GlobalScript.network_position2D
    
    # Scale and offset the network position
    var scaled_network_pos = Vector2(
        network_pos.x * network_scale_x + position_offset.x,
        network_pos.y * network_scale_y + position_offset.y
    )
    
    # Update target position for X axis (absolute positioning)
    target_position.x = scaled_network_pos.x
    
    # Smooth movement to target position for X axis
    global_position.x = lerp(global_position.x, target_position.x, position_smoothing)
    
    # Handle Y-axis movement for jumping (detect upward motion)
    var y_delta = network_pos.y - last_network_y
    if y_delta < jump_threshold_y and network_jump_cooldown <= 0:
        handle_network_jumping()
        network_jump_cooldown = 0.3  # Prevent rapid jumping
    
    # Apply gravity for Y axis (keep physics for vertical movement)
    if !is_on_floor():
        velocity.y += gravity
    elif is_on_floor():
        jump_count = max_jump_count
        velocity.y = 0
    
    # Set X velocity to 0 since we're using absolute positioning
    velocity.x = 0
    
    last_network_y = network_pos.y

func keyboard_movement():
    if not movement_enabled:
        return
    
    # Gravity
    if !is_on_floor():
        velocity.y += gravity
    elif is_on_floor():
        jump_count = max_jump_count
        
    handle_jumping()
    
    # Keyboard movement (velocity-based for fallback)
    var inputAxis = Input.get_axis("Left", "Right")
    velocity.x = inputAxis * move_speed

func handle_network_jumping():
    if is_on_floor() and !double_jump:
        jump()
    elif double_jump and jump_count > 0:
        jump()
        jump_count -= 1

# Handles jumping functionality (double jump or single jump, can be toggled from inspector)
func handle_jumping():
    if Input.is_action_just_pressed("Jump") and movement_enabled:
        if is_on_floor() and !double_jump:
            jump()
        elif double_jump and jump_count > 0:
            jump()
            jump_count -= 1

# Player jump
func jump():
    jump_tween()
    if AudioManager.jump_sfx:
        AudioManager.jump_sfx.play()
    velocity.y = -jump_force

# Handle Player Animations
func player_animations():
    particle_trails.emitting = false
    
    if is_on_floor():
        # Check movement for network input (position change) or keyboard (velocity)
        var is_moving = false
        if use_network_input:
            is_moving = abs(global_position.x - target_position.x) > 1.0
        else:
            is_moving = abs(velocity.x) > 0
            
        if is_moving:
            particle_trails.emitting = true
            player_sprite.play("Walk", 1.5)
        else:
            player_sprite.play("Idle")
    else:
        player_sprite.play("Jump")

# Flip player sprite based on movement direction
func flip_player():
    var movement_direction = 0.0
    
    if use_network_input:
        # For network input, check position difference
        movement_direction = target_position.x - global_position.x
    else:
        # For keyboard input, check velocity
        movement_direction = velocity.x
    
    if movement_direction < -1.0: 
        player_sprite.flip_h = true
    elif movement_direction > 1.0:
        player_sprite.flip_h = false

# Toggle between network and keyboard input (useful for testing)
func toggle_input_mode():
    use_network_input = !use_network_input
    print("Input mode: ", "Network" if use_network_input else "Keyboard")

# Reset network positioning (call when player respawns)
func reset_network_positioning():
    if GlobalScript:
        target_position = global_position
        last_network_y = GlobalScript.network_position2D.y

# Set absolute position directly (useful for calibration)
func set_network_position_directly(pos: Vector2):
    target_position = pos
    global_position = pos

# Calibrate network position to current player position
func calibrate_network_position():
    if GlobalScript:
        var current_network = GlobalScript.network_position2D
        # Calculate offset needed to match current position
        position_offset = global_position - Vector2(
            current_network.x * network_scale_x,
            current_network.y * network_scale_y
        )
        print("Network position calibrated. Offset: ", position_offset)

# Tween Animations
func death_tween():
    movement_enabled = false
    var tween = create_tween()
    tween.tween_property(player_sprite, "scale", Vector2.ZERO, 0.15)
    tween.parallel().tween_property(player_sprite, "position", Vector2.ZERO, 0.15)
    await tween.finished
    global_position = spawn_point.global_position
    reset_network_positioning()  # Reset network positioning on respawn
    await get_tree().create_timer(0.3).timeout
    movement_enabled = true
    if AudioManager.respawn_sfx:
        AudioManager.respawn_sfx.play()
    respawn_tween()

func respawn_tween():
    var tween = create_tween()
    tween.stop(); tween.play()
    tween.tween_property(player_sprite, "scale", Vector2.ONE, 0.15) 
    tween.parallel().tween_property(player_sprite, "position", Vector2(0,-48), 0.15)

func jump_tween():
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector2(0.7, 1.4), 0.1)
    tween.tween_property(self, "scale", Vector2.ONE, 0.1)

# --------- SIGNALS ---------- #
# Reset the player's position to the current level spawn point if collided with any trap
func _on_collision_body_entered(body):
    if body.is_in_group("Traps"):
        if AudioManager.death_sfx:
            AudioManager.death_sfx.play()
        death_particles.emitting = true
        death_tween()
        




#extends CharacterBody2D
#
## --------- VARIABLES ---------- #
#@export_category("Player Properties")
#@export var jump_force : float = 1200
#@export var gravity : float = 30
#@export var max_jump_count : int = 2
#var jump_count : int = 2
#
#@export_category("Toggle Functions")
#@export var double_jump : = false
#@export var use_network_input : bool = true  # Toggle between network and keyboard input
#
#@export_category("Network Settings")
#@export var position_smoothing : float = 0.1       # Smoothing factor for position updates
#@export var network_scale_x : float = 1.0          # Scale factor for X position
#@export var network_scale_y : float = 1.0          # Scale factor for Y position
#@export var position_offset : Vector2 = Vector2.ZERO # Offset to apply to network position
#
#@export_category("Boundaries")
#@export var min_bounds = Vector2(-500, -300)       # Minimum X,Y boundaries
#@export var max_bounds = Vector2(500, 300)         # Maximum X,Y boundaries
#@export var boundary_buffer = 10.0                 # Buffer from boundaries
#
#@export_category("Keyboard Fallback")
#@export var move_speed : float = 400                # Only used for keyboard input
#
#var is_grounded : bool = false
#var movement_enabled : bool = true
#var target_position: Vector2
#var last_position: Vector2
#
#@onready var player_sprite = $AnimatedSprite2D
#@onready var spawn_point = %SpawnPoint
#@onready var particle_trails = $ParticleTrails
#@onready var death_particles = $DeathParticles
#
## --------- BUILT-IN FUNCTIONS ---------- #
#func _ready():
    #print("=== 2D PLAYER READY - ABSOLUTE POSITIONING ===")
    #target_position = global_position
    #last_position = global_position
    #
    #if not GlobalScript:
        #print("Warning: GlobalScript autoload not found, falling back to keyboard input")
        #use_network_input = false
    #
    ## Initialize position within bounds
    #global_position = _clamp_to_bounds(global_position)
    #target_position = global_position
#
#func _physics_process(delta):
    #if movement_enabled:
        #if use_network_input and GlobalScript and GlobalScript.connected:
            #network_absolute_movement()
        #else:
            #keyboard_movement(delta)
    #
    ## Only call move_and_slide for keyboard mode (physics-based)
    #if not use_network_input or not GlobalScript or not GlobalScript.connected:
        #move_and_slide()
#
#func _process(delta):
    #player_animations()
    #flip_player()
#
## --------- CUSTOM FUNCTIONS ---------- #
#
#func network_absolute_movement():
    #"""Pure absolute positioning from network data"""
    #if not movement_enabled:
        #return
    #
    ## Get network position
    #var network_pos = get_network_position()
    #
    #if network_pos == Vector2.ZERO:
        #return  # Skip if no valid network data
    #
    ## Apply offset calibration
    #network_pos = network_pos - position_offset
    #
    ## Update target position (absolute positioning for both X and Y)
    #target_position = _clamp_to_bounds(network_pos)
    #
    ## Smoothly move to target position (NO velocity, pure absolute positioning)
    #global_position = global_position.lerp(target_position, position_smoothing)
    #
    ## Ensure final position is within bounds
    #global_position = _clamp_to_bounds(global_position)
    #
    ## Clear all velocity since we're using absolute positioning
    #velocity = Vector2.ZERO
    #
    #last_position = global_position
#
#func get_network_position() -> Vector2:
    #"""Get network position from GlobalScript"""
    #if not GlobalScript:
        #return Vector2.ZERO
    #
    ## Get the 2D network position from GlobalScript
    #var network_pos = GlobalScript.network_position2D
    #
    ## Apply scaling
    #var scaled_pos = Vector2(
        #network_pos.x * network_scale_x,
        #network_pos.y * network_scale_y
    #)
    #
    #return scaled_pos
#
#func keyboard_movement(delta):
    #"""Keyboard movement with physics (fallback mode)"""
    #if not movement_enabled:
        #return
    #
    ## Gravity for keyboard mode
    #if !is_on_floor():
        #velocity.y += gravity * delta
    #elif is_on_floor():
        #jump_count = max_jump_count
        #
    #handle_keyboard_jumping()
    #
    ## Keyboard movement (velocity-based)
    #var inputAxis = Input.get_axis("Left", "Right")
    #velocity.x = inputAxis * move_speed
    #
    ## Clamp keyboard movement to boundaries
    #var next_position = global_position + velocity * delta
    #next_position = _clamp_to_bounds(next_position)
    #
    ## Adjust velocity if position would be clamped
    #if next_position != global_position + velocity * delta:
        #velocity = (next_position - global_position) / delta
#
#func handle_keyboard_jumping():
    #"""Handle jumping for keyboard input only"""
    #if Input.is_action_just_pressed("Jump") and movement_enabled:
        #if is_on_floor() and !double_jump:
            #jump()
        #elif double_jump and jump_count > 0:
            #jump()
            #jump_count -= 1
#
#func jump():
    #"""Player jump (keyboard mode only)"""
    #jump_tween()
    #if AudioManager and AudioManager.jump_sfx:
        #AudioManager.jump_sfx.play()
    #velocity.y = -jump_force
#
#func _clamp_to_bounds(pos: Vector2) -> Vector2:
    #"""Clamp position to boundaries"""
    #return Vector2(
        #clamp(pos.x, min_bounds.x + boundary_buffer, max_bounds.x - boundary_buffer),
        #clamp(pos.y, min_bounds.y + boundary_buffer, max_bounds.y - boundary_buffer)
    #)
#
## Handle Player Animations
#func player_animations():
    #particle_trails.emitting = false
    #
    ## Determine if player is moving
    #var is_moving = false
    #var is_on_ground = true  # For network mode, assume always on ground since no physics
    #
    #if use_network_input:
        ## For network input, check position change
        #is_moving = (global_position - last_position).length() > 1.0
    #else:
        ## For keyboard input, use physics
        #is_on_ground = is_on_floor()
        #is_moving = abs(velocity.x) > 10.0
    #
    #if is_on_ground:
        #if is_moving:
            #particle_trails.emitting = true
            #player_sprite.play("Walk", 1.5)
        #else:
            #player_sprite.play("Idle")
    #else:
        #player_sprite.play("Jump")
#
## Flip player sprite based on movement direction
#func flip_player():
    #var movement_direction = 0.0
    #
    #if use_network_input:
        ## For network input, check position difference from last frame
        #movement_direction = global_position.x - last_position.x
    #else:
        ## For keyboard input, check velocity
        #movement_direction = velocity.x
    #
    #if movement_direction < -1.0: 
        #player_sprite.flip_h = true
    #elif movement_direction > 1.0:
        #player_sprite.flip_h = false
#
## Calibration and utility functions
#func calibrate_network_position():
    #"""Calibrate network position to current player position"""
    #print("=== CALIBRATING 2D NETWORK POSITION ===")
    #if not GlobalScript or not use_network_input:
        #print("Cannot calibrate: GlobalScript not available or network input disabled")
        #return
    #
    #var current_network = get_network_position()
    #
    #if current_network == Vector2.ZERO:
        #print("WARNING: Network position is zero during calibration")
        #position_offset = Vector2.ZERO
        #return
    #
    ## Calculate offset to maintain current position
    #var clamped_position = _clamp_to_bounds(global_position)
    #position_offset = current_network - clamped_position
    #
    #print("2D Network position calibrated:")
    #print("  Current network pos: ", current_network)
    #print("  Target game pos: ", clamped_position)  
    #print("  Calculated offset: ", position_offset)
#
#func toggle_input_mode():
    #"""Toggle between network and keyboard input"""
    #use_network_input = !use_network_input
    #print("Input mode: ", "Network" if use_network_input else "Keyboard")
    #
    ## Reset velocities when switching modes
    #if use_network_input:
        #velocity = Vector2.ZERO
#
#func reset_network_positioning():
    #"""Reset network positioning"""
    #target_position = global_position
    #last_position = global_position
    #print("Network positioning reset")
#
#func set_network_position_directly(pos: Vector2):
    #"""Set position directly (useful for testing)"""
    #pos = _clamp_to_bounds(pos)
    #target_position = pos
    #global_position = pos
    #last_position = pos
#
## Tween Animations
#func death_tween():
    #movement_enabled = false
    #var tween = create_tween()
    #tween.tween_property(player_sprite, "scale", Vector2.ZERO, 0.15)
    #tween.parallel().tween_property(player_sprite, "position", Vector2.ZERO, 0.15)
    #await tween.finished
    #
    ## Respawn at spawn point
    #global_position = spawn_point.global_position
    #global_position = _clamp_to_bounds(global_position)
    #reset_network_positioning()
    #
    #await get_tree().create_timer(0.3).timeout
    #movement_enabled = true
    #
    #if AudioManager and AudioManager.respawn_sfx:
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
## Input handling
#func _input(event):
    #if event.is_action_pressed("ui_select"):
        #print("Manual calibration triggered")
        #calibrate_network_position()
    #elif event.is_action_pressed("ui_cancel"):
        #toggle_input_mode()
#
## --------- SIGNALS ---------- #
#func _on_collision_body_entered(body):
    #"""Handle collision with traps"""
    #if body.is_in_group("Traps"):
        #if AudioManager and AudioManager.death_sfx:
            #AudioManager.death_sfx.play()
        #death_particles.emitting = true
        #death_tween()
#
## Public API
#func start_game():
    #"""Called when game starts"""
    #print("=== 2D GAME STARTING ===")
    #movement_enabled = true
    #
    ## Ensure player is within bounds
    #global_position = _clamp_to_bounds(global_position)
    #reset_network_positioning()
    #
    ## Auto-calibrate if using network input
    #if use_network_input and GlobalScript:
        #await get_tree().create_timer(0.2).timeout
        #calibrate_network_position()
    #
    #print("2D Game started! Player position: ", global_position)
