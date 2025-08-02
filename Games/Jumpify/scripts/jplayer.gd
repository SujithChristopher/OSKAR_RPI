class_name Player
extends CharacterBody3D

@export_group("Movement")
@export var position_lerp_factor = 0.9  

@export_group("Boundaries")
@export var min_bounds = Vector3(-2.6, -0.95, -1.8)    # Ground level Y = -1.0
@export var max_bounds = Vector3(2.6, 4.0, 3.42)     # Max height Y = 4
@export var boundary_buffer = 0.1

@export_group("Network Control")  
@export var debug_mode = DebugSettings.debug_mode
@export var network_movement_enabled: bool = true

# Adaptive mode support
var adapt_toggle: bool = false

@export_group("Animation")
@export var animation_player: AnimationPlayer
@export var enemy_layer = 1

@export_group("Sound")
@export var jump_sound: AudioStreamPlayer
@export var death_sound: AudioStreamPlayer

@export_group("Effects")
@export var ko_pivot: Node3D
@export var ko_effect: PackedScene
@export var smoke_particles: PackedScene

@export_group("Debug")
@export var verbose_debug: bool = true
@export var preserve_current_position: bool = false

# Network position variables - similar to Random Reach
var network_position = Vector3.ZERO
var zero_offset = Vector3.ZERO

# Position tracking variables - similar to Random Reach
var pos_x: float
var pos_y: float
var pos_z: float

# State
var is_dead = false
var debug_frame_counter = 0
var level_transition_active: bool = false

func _ready() -> void:
    print("=== JUMPIFY PLAYER READY - ABSOLUTE 3D POSITIONING ===")
    print("Debug mode: ", debug_mode)
    print("Network movement enabled: ", network_movement_enabled)
    
    _initialize_position()
    
    # Start calibration after a brief delay
    await get_tree().create_timer(0.5).timeout
    level_transition_active = false

func _initialize_position():
    """Initialize player at ground level"""
    position = Vector3(
        (min_bounds.x + max_bounds.x) / 2.0,
        min_bounds.y,  # Start at ground level (Y = -1.0)
        (min_bounds.z + max_bounds.z) / 2.0
    )
    print("Initial position (ground level): ", position)

func _physics_process(delta: float) -> void:
    debug_frame_counter += 1
    
    if is_dead or level_transition_active:
        return

    # Update player position using absolute positioning
    _update_player_position_absolute()
    
    # Handle collision detection (keep enemy collision)
    _check_enemy_collision()

func _update_player_position_absolute() -> void:
    """Update player position using absolute positioning like Random Reach"""
    
    if debug_mode:
        # Debug mode: Use mouse for 3D movement
        _handle_debug_movement()
    elif network_movement_enabled:
        # Network mode: Use absolute positioning from GlobalScript
        _handle_network_movement_absolute()
    else:
        # Keyboard mode: Use keyboard input
        _handle_keyboard_movement()

func _handle_debug_movement() -> void:
    """Debug movement using mouse and keyboard"""
    var mouse_pos = get_viewport().get_mouse_position()
    var screen_size = get_viewport().get_visible_rect().size
    
    # Map mouse to X and Z
    var target_x = (mouse_pos.x / screen_size.x) * (max_bounds.x - min_bounds.x) + min_bounds.x
    var target_z = (mouse_pos.y / screen_size.y) * (max_bounds.z - min_bounds.z) + min_bounds.z
    
    # Use keyboard for Y movement in debug - start from ground
    var target_y = position.y
    if Input.is_action_pressed("ui_up"):
        target_y += 0.05  # Move UP
    if Input.is_action_pressed("ui_down"):
        target_y -= 0.05  # Move DOWN
        target_y = max(target_y, min_bounds.y)  # Don't go below ground (-1.0)
    
    var target_position = Vector3(target_x, target_y, target_z)
    target_position = _clamp_to_bounds(target_position)
    
    # Apply smooth movement like Random Reach
    position = position.lerp(target_position, position_lerp_factor)

func _handle_network_movement_absolute() -> void:
    """Handle absolute positioning from network data like Random Reach"""
    
    # Get network position similar to Random Reach
    if adapt_toggle:
        network_position = _get_scaled_network_position()
    else:
        network_position = _get_network_position()
    
    if network_position != Vector3.ZERO:
        # Apply zero offset calibration like Random Reach
        network_position = network_position - zero_offset
        
        # Map network coordinates to 3D world coordinates
        var target_position = _map_network_to_3d_bounds(network_position)
        
        # Clamp to boundaries
        target_position = _clamp_to_bounds(target_position)
        
        # Apply smooth movement like Random Reach
        position = position.lerp(target_position, position_lerp_factor)
        
        # Update position tracking variables
        _update_position_tracking()

func _get_network_position() -> Vector3:
    """Get network position from GlobalScript like Random Reach"""
    if not GlobalScript:
        return Vector3.ZERO
    
    # Get raw sensor data
    pos_x = GlobalScript.raw_x if "raw_x" in GlobalScript else 0.0
    pos_y = GlobalScript.raw_y if "raw_y" in GlobalScript else 0.0
    pos_z = GlobalScript.raw_z if "raw_z" in GlobalScript else 0.0
    
    # Apply scaling similar to GlobalScript transformation
    var net_x = pos_x * GlobalScript.PLAYER_POS_SCALER_X
    var net_y = pos_y * GlobalScript.PLAYER_POS_SCALER_Y
    var net_z = pos_z * GlobalScript.PLAYER_POS_SCALER_Y
    
    return Vector3(net_x, net_y, net_z)

func _get_scaled_network_position() -> Vector3:
    """Get scaled network position for adaptive mode"""
    if not GlobalScript:
        return Vector3.ZERO
    
    # Get raw sensor data
    pos_x = GlobalScript.raw_x if "raw_x" in GlobalScript else 0.0
    pos_y = GlobalScript.raw_y if "raw_y" in GlobalScript else 0.0
    pos_z = GlobalScript.raw_z if "raw_z" in GlobalScript else 0.0
    
    # Apply scaling with global scalars
    var scaled_x = pos_x * GlobalScript.PLAYER_POS_SCALER_X * GlobalSignals.global_scalar_x
    var scaled_y = pos_y * GlobalScript.PLAYER_POS_SCALER_Y * GlobalSignals.global_scalar_y
    var scaled_z = pos_z * GlobalScript.PLAYER_POS_SCALER_Y * GlobalSignals.global_scalar_y
    
    return Vector3(scaled_x, scaled_y, scaled_z)

func _map_network_to_3d_bounds(net_pos: Vector3) -> Vector3:
    """Map network position to 3D game boundaries"""
    # Increased scale factor for faster movement
    var scale_factor = 0.01  # Increased from 0.001 for faster movement
    
    var mapped_pos = Vector3(
        net_pos.x * scale_factor,
        net_pos.y * scale_factor,  # Y sensor controls Y movement (NOT inverted)
        net_pos.z * scale_factor
    )
    
    # Start from ground level, not center
    var base_position = Vector3(
        (min_bounds.x + max_bounds.x) / 2.0,  # Center X
        min_bounds.y,  # Ground level Y = -1.0
        (min_bounds.z + max_bounds.z) / 2.0   # Center Z
    )
    
    # For Y axis: positive sensor values move UP from ground
    var final_pos = Vector3(
        base_position.x + mapped_pos.x,
        base_position.y + abs(mapped_pos.y),  # Only positive Y movement from ground (-1.0)
        base_position.z + mapped_pos.z
    )
    
    return final_pos

func _update_position_tracking() -> void:
    """Update position tracking variables like Random Reach"""
    # Store current sensor values for logging
    if GlobalScript:
        pos_x = GlobalScript.raw_x if "raw_x" in GlobalScript else 0.0
        pos_y = GlobalScript.raw_y if "raw_y" in GlobalScript else 0.0
        pos_z = GlobalScript.raw_z if "raw_z" in GlobalScript else 0.0

func _handle_keyboard_movement() -> void:
    """Handle keyboard movement with absolute positioning"""
    var target_position = position
    var move_speed = 0.1  # Increased speed
    
    if Input.is_action_pressed("move_right"):
        target_position.x += move_speed
    if Input.is_action_pressed("move_left"):
        target_position.x -= move_speed
    if Input.is_action_pressed("move_back"):
        target_position.z += move_speed
    if Input.is_action_pressed("move_forward"):
        target_position.z -= move_speed
    if Input.is_action_pressed("ui_up"):  # Move up in Y
        target_position.y += move_speed
    if Input.is_action_pressed("ui_down"):  # Move down in Y
        target_position.y -= move_speed
        target_position.y = max(target_position.y, min_bounds.y)  # Don't go below ground (-1.0)
    
    target_position = _clamp_to_bounds(target_position)
    position = position.lerp(target_position, position_lerp_factor)

func _clamp_to_bounds(pos: Vector3) -> Vector3:
    """Clamp position to boundaries like Random Reach"""
    return Vector3(
        clamp(pos.x, min_bounds.x + boundary_buffer, max_bounds.x - boundary_buffer),
        clamp(pos.y, min_bounds.y + boundary_buffer, max_bounds.y - boundary_buffer),
        clamp(pos.z, min_bounds.z + boundary_buffer, max_bounds.z - boundary_buffer)
    )

func _check_enemy_collision() -> void:
    """Check for enemy collision"""
    # Keep the existing collision system
    pass

# Calibration functions like Random Reach
func _on_zero_pressed() -> void:
    """Calibrate zero position like Random Reach"""
    print("=== CALIBRATING ZERO POSITION (3D) ===")
    if network_movement_enabled and not debug_mode:
        var current_network_pos = Vector3.ZERO
        
        if adapt_toggle:
            current_network_pos = _get_scaled_network_position()
        else:
            current_network_pos = _get_network_position()
        
        if current_network_pos != Vector3.ZERO:
            # Calculate offset to maintain current position
            var desired_network_pos = _inverse_map_bounds_to_network(position)
            zero_offset = current_network_pos - desired_network_pos
            
            print("Zero offset calculated (3D): ", zero_offset)
        else:
            print("WARNING: Network position is zero during calibration")

func _inverse_map_bounds_to_network(world_pos: Vector3) -> Vector3:
    """Inverse mapping from world position to network position"""
    var scale_factor = 0.01  # Same as used in mapping
    
    var base_position = Vector3(
        (min_bounds.x + max_bounds.x) / 2.0,  # Center X
        min_bounds.y,  # Ground level Y = -1.0
        (min_bounds.z + max_bounds.z) / 2.0   # Center Z
    )
    
    var relative_pos = world_pos - base_position
    
    return Vector3(
        relative_pos.x / scale_factor,
        relative_pos.y / scale_factor,  # Y from ground up
        relative_pos.z / scale_factor
    )

# Level transition functions
func prepare_for_level_transition():
    """Prepare for level transition"""
    print("=== PREPARING FOR LEVEL TRANSITION ===")
    level_transition_active = true
    print("Current position preserved: ", position)

func complete_level_transition():
    """Complete level transition"""
    print("=== COMPLETING LEVEL TRANSITION ===")
    await get_tree().create_timer(0.5).timeout
    level_transition_active = false

func die():
    print("=== PLAYER DIED ===")
    SignalBus.player_hit.emit()
    if animation_player:
        animation_player.play("die")
    if death_sound:
        death_sound.play()
    _spawn_ko_effect()
    is_dead = true
    
func _on_area_3d_body_entered(other: Node3D) -> void:
    if other.is_in_group("enemy") and other.is_alive() and not is_dead:
        print("DEBUG: Hit by enemy: ", other.name)
        die()

func _spawn_ko_effect():
    if ko_effect and ko_pivot:
        var effect_instance = ko_effect.instantiate()
        ko_pivot.add_child(effect_instance)

func _spawn_smoke() -> void:
    if smoke_particles:
        var smoke_instance = smoke_particles.instantiate()
        smoke_instance.position = position
        get_tree().current_scene.add_child(smoke_instance)

func _input(event):
    if event.is_action_pressed("ui_select"):
        print("Manual zero position calibration triggered")
        _on_zero_pressed()
    elif event.is_action_pressed("ui_home"):
        verbose_debug = !verbose_debug
        print("Verbose debug toggled: ", verbose_debug)

# Public API functions
func recalibrate_position():
    print("External position recalibration requested")   
    _on_zero_pressed()

func start_game():
    print("Game started!")
    level_transition_active = false

func _on_adapt_rom_toggled(toggled_on: bool) -> void:
    adapt_toggle = toggled_on
    print("Adaptive mode toggled: ", toggled_on)
