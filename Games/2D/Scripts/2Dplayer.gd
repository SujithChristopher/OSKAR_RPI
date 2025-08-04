#extends CharacterBody2D
#
## --------- VARIABLES ---------- #
#
#@export_category("Player Properties") # You can tweak these changes according to your likings
#@export var move_speed : float = 400
#@export var jump_force : float = 650
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


extends CharacterBody2D

# --------- VARIABLES ---------- #
@export_category("Player Properties")
@export var move_speed : float = 400
@export var jump_force : float = 650
@export var gravity : float = 30
@export var max_jump_count : int = 2
var jump_count : int = 2

@export_category("Toggle Functions")
@export var double_jump : = false

@export_category("Network Settings")
@export var use_network_position: bool = true
@export var network_lerp_speed: float = 0.8
@export var adapt_toggle: bool = false

# Movement and positioning
var network_position: Vector2 = Vector2.ZERO
var zero_offset: Vector2 = Vector2.ZERO
var centre: Vector2 = Vector2(120, 200)  # Adjust based on your game's center point

# Game state
var is_grounded : bool = false
var movement_enabled : bool = true

# Debug mode
@onready var debug_mode = false  # Set this based on your debug system

# Node references
@onready var player_sprite = $AnimatedSprite2D
@onready var spawn_point = %SpawnPoint
@onready var particle_trails = $ParticleTrails
@onready var death_particles = $DeathParticles

# --------- BUILT-IN FUNCTIONS ---------- #
func _ready() -> void:
    # Initialize debug mode if you have a debug system
    # debug_mode = DebugSettings.debug_mode  # Uncomment if you have this
    pass

func _physics_process(_delta):
    if use_network_position:
        _update_network_position()
        _apply_network_movement()
    else:
        _handle_traditional_movement()
    
    _apply_gravity_and_jump()
    move_and_slide()

func _process(_delta):
    player_animations()
    flip_player()

# --------- NETWORK POSITION FUNCTIONS ---------- #
func _update_network_position() -> void:
    if debug_mode:
        # Use mouse position for debugging
        network_position = get_global_mouse_position()
    elif adapt_toggle:
        # Use scaled network position
        network_position = GlobalScript.scaled_network_position
    else:
        # Use regular network position
        network_position = GlobalScript.network_position

func _apply_network_movement() -> void:
    if network_position != Vector2.ZERO and movement_enabled:
        # Apply offset and center adjustments (similar to pingpong)
        var target_position = network_position - zero_offset + centre
        
        # Only apply network position to X-axis for platformer
        var target_x = target_position.x
        
        # Lerp to the target X position for smooth movement
        position.x = lerp(position.x, target_x, network_lerp_speed)
        
        # Calculate velocity.x based on position change for animations
        var prev_x = position.x
        velocity.x = (target_x - prev_x) * 60.0  # Approximate velocity for animations

# --------- TRADITIONAL MOVEMENT FUNCTIONS ---------- #
func _handle_traditional_movement():
    if movement_enabled:
        var inputAxis = Input.get_axis("Left", "Right")
        velocity.x = inputAxis * move_speed

func _apply_gravity_and_jump():
    # Gravity
    if !is_on_floor():
        velocity.y += gravity
    elif is_on_floor():
        jump_count = max_jump_count
    
    handle_jumping()

# --------- CUSTOM FUNCTIONS ---------- #
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
    # Uncomment if you have AudioManager
    # AudioManager.jump_sfx.play()
    velocity.y = -jump_force

# Handle Player Animations
func player_animations():
    particle_trails.emitting = false
    
    if is_on_floor():
        if abs(velocity.x) > 10:  # Small threshold to avoid jittery animations
            particle_trails.emitting = true
            player_sprite.play("Walk", 1.5)
        else:
            player_sprite.play("Idle")
    else:
        player_sprite.play("Jump")

# Flip player sprite based on X velocity
func flip_player():
    if velocity.x < -10:  # Small threshold to avoid constant flipping
        player_sprite.flip_h = true
    elif velocity.x > 10:
        player_sprite.flip_h = false

# Network position calibration functions
func set_zero_offset():
    """Call this to calibrate the network position to current player position"""
    if network_position != Vector2.ZERO:
        zero_offset = network_position - position + centre

func reset_network_calibration():
    """Reset network calibration"""
    zero_offset = Vector2.ZERO

# Toggle between network and traditional controls
func toggle_network_control(enabled: bool):
    use_network_position = enabled
    if not enabled:
        velocity.x = 0  # Stop any network-induced movement

# --------- TWEEN ANIMATIONS ---------- #
func death_tween():
    movement_enabled = false
    var tween = create_tween()
    tween.tween_property(player_sprite, "scale", Vector2.ZERO, 0.15)
    tween.parallel().tween_property(player_sprite, "position", Vector2.ZERO, 0.15)
    await tween.finished
    global_position = spawn_point.global_position
    await get_tree().create_timer(0.3).timeout
    movement_enabled = true
    # Uncomment if you have AudioManager
    # AudioManager.respawn_sfx.play()
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
        # Uncomment if you have AudioManager
        # AudioManager.death_sfx.play()
        death_particles.emitting = true
        death_tween()

# --------- UTILITY FUNCTIONS ---------- #
func get_network_position_data() -> Dictionary:
    """Returns current network position data for logging/debugging"""
    return {
        "network_position": network_position,
        "zero_offset": zero_offset,
        "use_network": use_network_position,
        "adapt_toggle": adapt_toggle,
        "raw_x": GlobalScript.raw_x if GlobalScript else 0.0,
        "raw_y": GlobalScript.raw_y if GlobalScript else 0.0
    }
