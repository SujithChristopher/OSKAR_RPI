class_name Player
extends CharacterBody3D

@export_group("Movement")
@export var speed = 3.0
@export var fall_acceleration = 74.0
@export var jump_impulse = 20.0
@export var bounce_factor = 0.75
@export var position_lerp_factor = 0.15

@export_group("Boundaries")
@export var min_bounds = Vector3(-2.6, -100, -1.8)
@export var max_bounds = Vector3(2.6, 100, 3.42)
@export var boundary_buffer = 0.1

@export_group("Network Control")
@export var debug_mode: bool = false
@export var network_movement_enabled: bool = true
@export var movement_sensitivity: float = 2.0
@export var network_deadzone: float = 0.02

# Adaptive mode support
var adapt_toggle: bool = false

@export_group("Jump Detection - DIRECTION BASED")
@export var min_direction_change: float = 0.01  # Minimum change to detect direction switch
@export var jump_cooldown_time: float = 0.6     # Cooldown between jumps
@export var smoothing_factor: float = 0.3       # Smoothing for Y values

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

# Network position variables
var network_position = Vector3.ZERO
var target_position = Vector3.ZERO
var zero_offset = Vector3.ZERO
var preserve_current_position: bool = false

# Y DIRECTION CHANGE DETECTION
var raw_y_history: Array[float] = []
var smoothed_y_history: Array[float] = []
var y_direction_history: Array[int] = []  # -1 = down, 0 = no change, 1 = up
var history_size: int = 5

var current_smoothed_y: float = 0.0
var previous_smoothed_y: float = 0.0
var current_y_direction: int = 0
var previous_y_direction: int = 0

var jump_cooldown: float = 0.0
var is_calibrated: bool = false
var baseline_y: float = 0.0
var calibration_samples = []
var calibration_count = 8

var level_transition_active: bool = false

# State
var is_dead = false
var debug_frame_counter = 0

func _ready() -> void:
    print("=== PLAYER READY - DIRECTION CHANGE DETECTION ===")
    print("Debug mode: ", debug_mode)
    print("Network movement enabled: ", network_movement_enabled)
    
    # Initialize history arrays
    for i in range(history_size):
        raw_y_history.append(0.0)
        smoothed_y_history.append(0.0)
        y_direction_history.append(0)
    
    if not preserve_current_position:
        _initialize_position()
    else:
        target_position = position
        print("Preserving current position: ", position)
    
    _start_calibration()

func _initialize_position():
    """Initialize player at center of bounds"""
    position = Vector3(
        (min_bounds.x + max_bounds.x) / 2.0,
        0,
        (min_bounds.z + max_bounds.z) / 2.0
    )
    target_position = position
    print("Initial position: ", position)

func _start_calibration():
    """Start calibration process"""
    print("Starting calibration process...")
    calibration_samples.clear()
    is_calibrated = false
    level_transition_active = true
    
    if network_movement_enabled and not debug_mode:
        print("Waiting for network to stabilize...")
        await get_tree().create_timer(1.0).timeout
        _calibrate_zero_position()
        print("Collecting baseline samples...")
        await get_tree().create_timer(0.5).timeout
        level_transition_active = false
        print("Calibration complete - direction detection active")
    else:
        print("Skipping network calibration (debug mode)")
        await get_tree().create_timer(0.2).timeout
        level_transition_active = false

func _physics_process(delta: float) -> void:
    debug_frame_counter += 1
    
    if is_dead:
        return

    # Update cooldown timer
    if jump_cooldown > 0:
        jump_cooldown -= delta

    # Update network position and Y direction detection
    if network_movement_enabled and not debug_mode:
        _update_network_position()
        _update_y_direction_detection()

    # Handle smooth movement
    _update_player_position(delta)

    # Handle jumping and physics
    if is_on_floor():
        if velocity.y < 0:
            Scoreboard.reset_combo()
            _spawn_smoke()
        
        # Check for jump based on Y direction change
        if not level_transition_active and _should_jump():
            _perform_jump()
    else:
        velocity.y -= fall_acceleration * delta

    # Apply movement (only Y velocity for jumping/falling)
    velocity.x = 0
    velocity.z = 0
    move_and_slide()

    # Clamp to boundaries
    var new_x = clamp(position.x, min_bounds.x + boundary_buffer, max_bounds.x - boundary_buffer)
    var new_z = clamp(position.z, min_bounds.z + boundary_buffer, max_bounds.z - boundary_buffer)
    
    if abs(new_x - position.x) > 0.01 or abs(new_z - position.z) > 0.01:
        position.x = new_x
        position.z = new_z

func _update_network_position():
    """Update network position with smooth interpolation"""
    var current_network_pos = Vector2.ZERO
    
    if debug_mode:
        var mouse_pos = get_viewport().get_mouse_position()
        var screen_size = get_viewport().get_visible_rect().size
        current_network_pos = Vector2(
            (mouse_pos.x / screen_size.x) * (max_bounds.x - min_bounds.x) + min_bounds.x,
            (mouse_pos.y / screen_size.y) * (max_bounds.z - min_bounds.z) + min_bounds.z
        )
    elif adapt_toggle:
        if GlobalScript.has_method("get_scaled_network_position"):
            current_network_pos = GlobalScript.scaled_network_position
        else:
            current_network_pos = GlobalScript.network_position
    else:
        if "network_position" in GlobalScript:
            current_network_pos = GlobalScript.network_position

    if current_network_pos != Vector2.ZERO:
        var new_network_pos = Vector3(current_network_pos.x, 0, current_network_pos.y)
        
        if zero_offset != Vector3.ZERO:
            new_network_pos = new_network_pos - zero_offset
        
        var new_target = _map_network_to_bounds(new_network_pos)
        new_target.y = position.y
        
        if not level_transition_active:
            var distance_to_new_target = new_target.distance_to(target_position)
            if distance_to_new_target > network_deadzone:
                target_position = new_target

func _map_network_to_bounds(net_pos: Vector3) -> Vector3:
    """Map network position to game boundaries"""
    var mapped_pos = Vector3.ZERO
    
    var network_scale_x = movement_sensitivity * 0.008
    var network_scale_z = movement_sensitivity * 0.008
    
    mapped_pos.x = net_pos.x * network_scale_x
    mapped_pos.z = net_pos.z * network_scale_z
    
    mapped_pos.x = clamp(mapped_pos.x, min_bounds.x, max_bounds.x)
    mapped_pos.z = clamp(mapped_pos.z, min_bounds.z, max_bounds.z)
    mapped_pos.y = net_pos.y
    
    return mapped_pos

func _update_player_position(delta: float) -> void:
    """Update player position with smooth movement"""
    if debug_mode:
        var direction = Vector3.ZERO
        if Input.is_action_pressed("ui_right"):
            direction.x += 1
        if Input.is_action_pressed("ui_left"):
            direction.x -= 1
        if Input.is_action_pressed("ui_down"):
            direction.z += 1
        if Input.is_action_pressed("ui_up"):
            direction.z -= 1
        
        if direction.length() > 0:
            target_position += direction.normalized() * speed * delta
    elif network_movement_enabled and not level_transition_active:
        pass  # Handled in _update_network_position
    else:
        var direction = Vector3.ZERO
        if Input.is_action_pressed("move_right"):
            direction.x += 1
        if Input.is_action_pressed("move_left"):
            direction.x -= 1
        if Input.is_action_pressed("move_back"):
            direction.z += 1
        if Input.is_action_pressed("move_forward"):
            direction.z -= 1
            
        if direction.length() > 0:
            target_position += direction.normalized() * speed * delta

    # Smooth interpolation to target position
    if target_position != Vector3.ZERO and not level_transition_active:
        var horizontal_distance = Vector2(target_position.x - position.x, target_position.z - position.z).length()
        
        if horizontal_distance > network_deadzone:
            var new_pos = position.lerp(Vector3(target_position.x, position.y, target_position.z), position_lerp_factor)
            position.x = new_pos.x
            position.z = new_pos.z
            
            var movement_direction = Vector3(target_position.x - position.x, 0, target_position.z - position.z)
            if movement_direction.length() > network_deadzone:
                $Pivot.basis = $Pivot.basis.slerp(Basis.looking_at(-movement_direction), 0.15)

func _update_y_direction_detection():
    """Detect Y direction changes for jump triggering"""
    if not "raw_y" in GlobalScript:
        return
    
    var raw_y = GlobalScript.raw_y
    
    # Add to history and remove oldest
    raw_y_history.append(raw_y)
    raw_y_history.remove_at(0)
    
    # Apply smoothing
    current_smoothed_y = lerp(current_smoothed_y, raw_y, smoothing_factor)
    
    # Add smoothed value to history
    smoothed_y_history.append(current_smoothed_y)
    smoothed_y_history.remove_at(0)
    
    # Handle calibration
    if not is_calibrated:
        calibration_samples.append(current_smoothed_y)
        
        if calibration_samples.size() >= calibration_count:
            var sum = 0.0
            for sample in calibration_samples:
                sum += sample
            baseline_y = sum / calibration_samples.size()
            
            is_calibrated = true
            previous_smoothed_y = current_smoothed_y
            print("=== Y-AXIS CALIBRATED FOR DIRECTION DETECTION ===")
            print("Baseline Y: ", "%.4f" % baseline_y)
        return
    
    # Calculate direction
    previous_y_direction = current_y_direction
    var y_diff = current_smoothed_y - previous_smoothed_y
    
    if abs(y_diff) > min_direction_change:
        if y_diff > 0:
            current_y_direction = 1   # Moving up (Y increasing)
        else:
            current_y_direction = -1  # Moving down (Y decreasing)
    else:
        current_y_direction = 0  # No significant change
    
    # Add direction to history
    y_direction_history.append(current_y_direction)
    y_direction_history.remove_at(0)
    
    # Update previous value
    previous_smoothed_y = current_smoothed_y
    
    # Debug output
    if verbose_debug and debug_frame_counter % 30 == 0:
        print("Y DIRECTION: Current=", "%.3f" % current_smoothed_y, " Diff=", "%.3f" % y_diff, " Dir=", current_y_direction, " PrevDir=", previous_y_direction)

func _should_jump() -> bool:
    """Check for Y direction change to trigger jump"""
    if debug_mode:
        return Input.is_action_just_pressed("ui_accept")
    
    if not is_calibrated or level_transition_active:
        return false
    
    # Check cooldown
    if jump_cooldown > 0:
        return false
    
    # DIRECTION CHANGE DETECTION:
    # Jump when direction changes from UP to DOWN (head was moving up, now moving down)
    # This means: previous_y_direction = 1 (up) and current_y_direction = -1 (down)
    var direction_changed_to_down = (previous_y_direction == 1 and current_y_direction == -1)
    
    # Alternative: Also jump when we detect a sudden downward movement after being stable
    var sudden_downward = (previous_y_direction == 0 and current_y_direction == -1)
    
    var should_jump = direction_changed_to_down or sudden_downward
    
    if should_jump and verbose_debug:
        print("=== JUMP TRIGGERED BY DIRECTION CHANGE ===")
        print("Previous direction: ", previous_y_direction, " Current direction: ", current_y_direction)
        print("Direction changed to down: ", direction_changed_to_down)
        print("Sudden downward: ", sudden_downward)
    
    return should_jump

func _perform_jump():
    """Perform jump with proper cooldown"""
    print("=== PERFORMING JUMP ===")
    print("Y Direction change detected - jumping!")
    
    if jump_sound:
        jump_sound.play()
    
    velocity.y = jump_impulse
    jump_cooldown = jump_cooldown_time
    
    print("Jump applied, velocity.y = ", velocity.y)

func _calibrate_zero_position():
    """Calibrate zero position while preserving current player position"""
    print("=== CALIBRATING ZERO POSITION ===")
    if network_movement_enabled and not debug_mode:
        var current_network_pos = Vector2.ZERO
        
        if adapt_toggle:
            if GlobalScript.has_method("get_scaled_network_position"):
                current_network_pos = GlobalScript.scaled_network_position
            else:
                current_network_pos = GlobalScript.network_position
        else:
            if "network_position" in GlobalScript:
                current_network_pos = GlobalScript.network_position
            else:
                print("ERROR: GlobalScript.network_position not found!")
                return
        
        if current_network_pos != Vector2.ZERO:
            var current_3d_pos = Vector3(current_network_pos.x, 0, current_network_pos.y)
            var desired_network_pos = _inverse_map_bounds_to_network(Vector3(position.x, 0, position.z))
            zero_offset = current_3d_pos - desired_network_pos
            
            print("Zero offset calculated: ", zero_offset)
        else:
            print("WARNING: Network position is zero during calibration")

func _inverse_map_bounds_to_network(world_pos: Vector3) -> Vector3:
    """Inverse mapping from world position to network position"""
    var network_scale_x = movement_sensitivity * 0.008
    var network_scale_z = movement_sensitivity * 0.008
    
    return Vector3(
        world_pos.x / network_scale_x,
        0,
        world_pos.z / network_scale_z
    )

# Level transition functions
func prepare_for_level_transition():
    """Prepare for level transition"""
    print("=== PREPARING FOR LEVEL TRANSITION ===")
    level_transition_active = true
    preserve_current_position = true
    is_calibrated = false
    calibration_samples.clear()
    jump_cooldown = jump_cooldown_time
    
    # Reset direction detection
    current_y_direction = 0
    previous_y_direction = 0
    for i in range(history_size):
        y_direction_history[i] = 0
    
    print("Current position preserved: ", position)

func complete_level_transition():
    """Complete level transition"""
    print("=== COMPLETING LEVEL TRANSITION ===")
    preserve_current_position = false
    target_position = position
    await get_tree().create_timer(0.5).timeout
    _start_calibration()

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

func _disable_enemy_collisions():
    collision_mask &= ~(1 << enemy_layer)
    print("DEBUG: Enemy collisions disabled")

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
        _calibrate_zero_position()
    elif event.is_action_pressed("ui_cancel"):
        print("Manual Y-axis recalibration triggered")
        is_calibrated = false
        calibration_samples.clear()
        current_y_direction = 0
        previous_y_direction = 0
    elif event.is_action_pressed("ui_up"):
        print("Manual jump test triggered")
        if is_on_floor():
            _perform_jump()
        else:
            print("Cannot jump - not on floor")
    elif event.is_action_pressed("ui_home"):
        verbose_debug = !verbose_debug
        print("Verbose debug toggled: ", verbose_debug)

# Public API functions
func _on_zero_pressed() -> void:
    print("Zero button pressed")
    _calibrate_zero_position()

func recalibrate_position():
    print("External position recalibration requested")   
    _calibrate_zero_position()

func recalibrate_ground():
    print("External Y-axis recalibration requested")
    is_calibrated = false
    calibration_samples.clear()
    current_y_direction = 0
    previous_y_direction = 0

func get_height_above_ground() -> float:
    if not is_calibrated:
        return 0.0
    return current_smoothed_y - baseline_y

func start_game():
    print("Game started!")
    level_transition_active = false

func _on_adapt_rom_toggled(toggled_on: bool) -> void:
    adapt_toggle = toggled_on
    print("Adaptive mode toggled: ", toggled_on)
