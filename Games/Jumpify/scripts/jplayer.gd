#class_name Player extends CharacterBody3D
#
#@export_group("Movement")
#@export var speed = 3.5
#@export var fall_acceleration = 74
#@export var jump_impulse = 20
#@export var bounce_factor = 0.75
#@export var smooth_movement = 0.2
#
#@export_group("Animation")
#@export var animation_player: AnimationPlayer
#@export var rigidbody: CharacterBody3D
#@export var enemy_layer = 1
#
#@export_group("Sound")
#@export var jump_sound: AudioStreamPlayer
#@export var death_sound: AudioStreamPlayer
#
#@export_group("Effects")
#@export var ko_pivot: Node3D
#@export var ko_effect: PackedScene
#@export var smoke_particles: PackedScene
#
#var target_velocity = Vector3.ZERO
#var is_dead = false
#
#func _ready() -> void:
  #apply_floor_snap()
#
#func _physics_process(delta: float) -> void:
  #var direction = _calculate_velocity()
#
  #if direction != Vector3.ZERO:
    #direction = direction.normalized()
    #$Pivot.basis = $Pivot.basis.slerp(Basis.looking_at(direction * -1), smooth_movement)
#
  #target_velocity.x = direction.x * speed
  #target_velocity.z = direction.z * speed
#
  #if _is_touching_floor() and target_velocity.y < 0:
    #Scoreboard.reset_combo()
    #_spawn_smoke()
#
  #if _is_touching_floor() and Input.is_action_just_pressed("jump") and !is_dead:
    #jump_sound.play()
    #target_velocity.y = jump_impulse
  #elif _is_touching_surface():
    #target_velocity.y = 0
  #else:
    #target_velocity.y -= fall_acceleration * delta
#
  #for index in range(get_slide_collision_count()):
    #var collision = get_slide_collision(index)
#
    #if collision.get_collider() == null:
      #continue
#
    #if collision.get_collider().is_in_group("enemy"):
      #var enemy = collision.get_collider()
      #if Vector3.UP.dot(collision.get_normal()) > 0.1:
        #enemy.squash()
        #_spawn_smoke()
        #target_velocity.y = jump_impulse * bounce_factor
    #break
#
  #velocity = velocity.lerp(target_velocity, smooth_movement)
  #
  #move_and_slide()
#
#func _is_touching_floor() -> bool:
  #if !_is_touching_surface():
    #return false
  #
  #for index in range(get_slide_collision_count()):
    #var collision = get_slide_collision(index)
#
    #if collision.get_collider() == null:
      #continue
#
    #if collision.get_collider().is_in_group("floor"):
      #return true
#
  #return false
#
#func _is_touching_surface() -> bool:
  #return is_on_floor()
#
#func _calculate_velocity() -> Vector3:
  #var direction = Vector3.ZERO
#
  #if is_dead:
    #return direction
#
  #if Input.is_action_pressed("move_right"):
    #direction.x += 1
  #if Input.is_action_pressed("move_left"):
    #direction.x -= 1
  #if Input.is_action_pressed("move_back"):
    #direction.z += 1
  #if Input.is_action_pressed("move_forward"):
    #direction.z -= 1
#
  #return direction
#
#func die():
  #SignalBus.player_hit.emit()
#
  #animation_player.play("die")
  #death_sound.play()
  #_spawn_ko_effect()
  #_disable_enemy_collisions()
  #is_dead = true
#
#func _spawn_ko_effect():
    #if ko_effect:
       #var effect_instance = ko_effect.instantiate()
       #ko_pivot.add_child(effect_instance)
    #else:
        #return
#
#func _on_area_3d_body_entered(other: Node3D) -> void:
  #if other.is_in_group("enemy") and other.is_alive() and !is_dead:
    #die()
#
#func _disable_enemy_collisions():
  #rigidbody.collision_mask &= ~(1 << enemy_layer)
#
#func _spawn_smoke() -> void:
  #var smoke_instance = smoke_particles.instantiate()
  #smoke_instance.position = position
  #get_tree().current_scene.add_child(smoke_instance)


    
    



#jump working 

#class_name Player
#extends CharacterBody3D
#
#@export_group("Movement")
#@export var speed = 3.0
#@export var fall_acceleration = 74.0
#@export var jump_impulse = 20.0
#@export var bounce_factor = 0.75
#@export var smooth_movement = 0.2
#
#@export_group("Boundaries")
#@export var min_bounds = Vector3(-10, -100, -10)
#@export var max_bounds = Vector3(10, 100, 10)
#@export var boundary_buffer = 0.1
#
#@export_group("Network Control")
#@export var debug_mode: bool = false
#@export var network_movement_enabled: bool = true
#@export var movement_sensitivity: float = 1.0
#@export var position_lerp_factor: float = 1
#@export var network_deadzone: float = 0.05
#
#@export_group("Jump Detection - SIMPLIFIED")
#@export var jump_height_threshold: float = 0.02  # Minimum lift to trigger jump (2cm)
#@export var jump_velocity_threshold: float = 0.005  # Minimum upward velocity
#@export var jump_cooldown_time: float = 1.0  # Seconds between jumps
#@export var smoothing_factor: float = 0.3  # For filtering sensor noise
#
#@export_group("Animation")
#@export var animation_player: AnimationPlayer
#@export var enemy_layer = 1
#
#@export_group("Sound")
#@export var jump_sound: AudioStreamPlayer
#@export var death_sound: AudioStreamPlayer
#
#@export_group("Effects")
#@export var ko_pivot: Node3D
#@export var ko_effect: PackedScene
#@export var smoke_particles: PackedScene
#
#@export_group("Debug")
#@export var verbose_debug: bool = true
#
## Network position variables
#var network_position = Vector3.ZERO
#var zero_offset = Vector3.ZERO
#
## SIMPLIFIED Jump detection variables
#var baseline_y: float = 0.0  # Ground reference point
#var current_y: float = 0.0
#var previous_y: float = 0.0
#var filtered_y: float = 0.0
#var y_velocity: float = 0.0
#
#var jump_cooldown: float = 0.0
#var is_calibrated: bool = false
#var calibration_samples = []
#var calibration_count = 30  # Samples to collect for baseline
#
## State
#var is_dead = false
#var debug_frame_counter = 0
#
#func _ready() -> void:
    #print("=== PLAYER READY - SIMPLIFIED JUMP ===")
    #print("Debug mode: ", debug_mode)
    #print("Network movement enabled: ", network_movement_enabled)
    #print("Jump height threshold: ", jump_height_threshold)
    #print("Jump velocity threshold: ", jump_velocity_threshold)
    #
    #_initialize_position()
    #_start_calibration()
#
#func _initialize_position():
    ## Initialize player at center of bounds
    #position = Vector3(
        #(min_bounds.x + max_bounds.x) / 2.0,
        #0,
        #(min_bounds.z + max_bounds.z) / 2.0
    #)
    #print("Initial position: ", position)
#
#func _start_calibration():
    #print("Starting Y-axis calibration...")
    #calibration_samples.clear()
    #is_calibrated = false
    #
    #if not debug_mode:
        #print("Collecting baseline samples...")
        ## Start collecting samples immediately
        #baseline_y = 0.0
#
#func _physics_process(delta: float) -> void:
    #debug_frame_counter += 1
    #
    #if is_dead:
        #return
#
    #if jump_cooldown > 0:
        #jump_cooldown -= delta
#
    ## Update network position and Y tracking
    #if network_movement_enabled and not debug_mode:
        #_update_network_position()
        #_update_y_tracking()
#
    ## Calculate movement direction
    #var direction = _calculate_velocity()
    #direction = _smooth_movement_input(direction)
#
    ## Apply movement with smoothing
    #if direction.length() > network_deadzone:
        #direction = direction.normalized()
        #$Pivot.basis = $Pivot.basis.slerp(Basis.looking_at(-direction), smooth_movement)
#
    ## Set horizontal velocity
    #var horizontal_velocity = direction * speed
    #velocity.x = lerp(velocity.x, horizontal_velocity.x, position_lerp_factor)
    #velocity.z = lerp(velocity.z, horizontal_velocity.z, position_lerp_factor)
#
    ## Handle jumping and falling
    #if is_on_floor():
        #if velocity.y < 0:
            #Scoreboard.reset_combo()
            #_spawn_smoke()
        #
        ## SIMPLIFIED JUMP CHECK
        #if _should_jump():
            #print("=== JUMP TRIGGERED ===")
            #_perform_jump()
    #else:
        #velocity.y -= fall_acceleration * delta
#
    #move_and_slide()
#
    ## Clamp positions to boundaries
    #position.x = clamp(position.x, min_bounds.x + boundary_buffer, max_bounds.x - boundary_buffer)
    #position.z = clamp(position.z, min_bounds.z + boundary_buffer, max_bounds.z - boundary_buffer)
#
#func _update_network_position():
    #var current_network_pos = Vector2.ZERO
    #
    #if debug_mode:
        ## Debug mode uses mouse position
        #var mouse_pos = get_viewport().get_mouse_position()
        #var screen_size = get_viewport().get_visible_rect().size
        #current_network_pos = Vector2(
            #(mouse_pos.x / screen_size.x) * (max_bounds.x - min_bounds.x) + min_bounds.x,
            #(mouse_pos.y / screen_size.y) * (max_bounds.z - min_bounds.z) + min_bounds.z
        #)
    #else:
        #if "network_position" in GlobalScript:
            #current_network_pos = GlobalScript.network_position
#
    ## Convert to 3D and apply zero offset
    #if current_network_pos != Vector2.ZERO:
        #var new_network_pos = Vector3(current_network_pos.x, 0, current_network_pos.y)
        #
        #if zero_offset != Vector3.ZERO:
            #new_network_pos = new_network_pos - zero_offset
        #
        #network_position = _map_network_to_bounds(new_network_pos)
#
#func _map_network_to_bounds(net_pos: Vector3) -> Vector3:
    #var mapped_pos = Vector3.ZERO
    #
    #var network_scale_x = movement_sensitivity * 0.01
    #var network_scale_z = movement_sensitivity * 0.01
    #
    #mapped_pos.x = net_pos.x * network_scale_x
    #mapped_pos.z = net_pos.z * network_scale_z
    #
    #mapped_pos.x = clamp(mapped_pos.x, min_bounds.x, max_bounds.x)
    #mapped_pos.z = clamp(mapped_pos.z, min_bounds.z, max_bounds.z)
    #
    #return mapped_pos
#
#func _update_y_tracking():
    #if not "raw_y" in GlobalScript:
        #return
    #
    ## Get raw Y value
    #var raw_y = GlobalScript.raw_y
    #previous_y = filtered_y
    #
    ## Apply smoothing filter to reduce noise
    #filtered_y = lerp(filtered_y, raw_y, smoothing_factor)
    #current_y = filtered_y
    #
    ## Calculate velocity (change per frame)
    #y_velocity = current_y - previous_y
    #
    ## Handle calibration
    #if not is_calibrated:
        #calibration_samples.append(current_y)
        #
        #if calibration_samples.size() >= calibration_count:
            ## Calculate baseline as average of samples
            #var sum = 0.0
            #for sample in calibration_samples:
                #sum += sample
            #baseline_y = sum / calibration_samples.size()
            #
            #is_calibrated = true
            #print("=== Y-AXIS CALIBRATED ===")
            #print("Baseline Y: ", baseline_y)
            #print("Current Y: ", current_y)
    #
    ## Debug output
    #if verbose_debug and debug_frame_counter % 30 == 0:
        #var height_diff = current_y - baseline_y
        #print("Y DEBUG: Raw=", raw_y, " Filtered=", current_y, " Baseline=", baseline_y, " Diff=", height_diff, " Vel=", y_velocity)
#
#func _smooth_movement_input(direction: Vector3) -> Vector3:
    #var magnitude = direction.length()
    #if magnitude < network_deadzone:
        #return Vector3.ZERO
    #
    #return direction.normalized() * pow(magnitude, 1.2)
#
#func _should_jump() -> bool:
    #if debug_mode:
        #return Input.is_action_just_pressed("ui_accept")
    #else:
        #return _check_device_lift() and is_on_floor() and jump_cooldown <= 0
#
#func _check_device_lift() -> bool:
    #if not is_calibrated:
        #return false
    #
    ## Calculate how much the device has been lifted
    #var height_above_baseline = current_y - baseline_y
    #var has_upward_velocity = y_velocity > jump_velocity_threshold
    #var sufficient_lift = height_above_baseline > jump_height_threshold
    #
    #if verbose_debug and (sufficient_lift or has_upward_velocity):
        #print("JUMP CHECK: Height=", height_above_baseline, " Vel=", y_velocity, " Lift=", sufficient_lift, " UpVel=", has_upward_velocity)
    #
    ## Jump if device is lifted high enough OR has strong upward velocity
    #return sufficient_lift or has_upward_velocity
#
#func _calculate_velocity() -> Vector3:
    #var direction = Vector3.ZERO
#
    #if debug_mode:
        ## Debug mode keyboard input
        #if Input.is_action_pressed("ui_right"):
            #direction.x += 1
        #if Input.is_action_pressed("ui_left"):
            #direction.x -= 1
        #if Input.is_action_pressed("ui_down"):
            #direction.z += 1
        #if Input.is_action_pressed("ui_up"):
            #direction.z -= 1
    #elif network_movement_enabled and network_position != Vector3.ZERO:
        ## Use network position for movement direction
        #var target_pos = network_position
        #var current_pos = Vector3(position.x, 0, position.z)
        #direction = (target_pos - current_pos)
        #
        #var distance = direction.length()
        #if distance > network_deadzone:
            #var scale_factor = min(distance * 2.0, 1.0)
            #direction = direction.normalized() * scale_factor
    #else:
        ## Fallback keyboard input
        #if Input.is_action_pressed("move_right"):
            #direction.x += 1
        #if Input.is_action_pressed("move_left"):
            #direction.x -= 1
        #if Input.is_action_pressed("move_back"):
            #direction.z += 1
        #if Input.is_action_pressed("move_forward"):
            #direction.z -= 1
#
    #return direction
#
#func _perform_jump():
    #print("=== PERFORMING JUMP ===")
    #print("Jump impulse: ", jump_impulse)
    #
    #if jump_sound:
        #jump_sound.play()
    #
    #velocity.y = jump_impulse
    #jump_cooldown = jump_cooldown_time
    #
    #print("New velocity.y: ", velocity.y)
#
#func _calibrate_zero_position():
    #print("=== CALIBRATING ZERO POSITION ===")
    #if network_movement_enabled and not debug_mode and "network_position" in GlobalScript:
        #var current_network_pos = GlobalScript.network_position
        #
        #if current_network_pos != Vector2.ZERO:
            #zero_offset = Vector3(current_network_pos.x, 0, current_network_pos.y)
            #print("Zero position calibrated to: ", zero_offset)
#
#func die():
    #print("=== PLAYER DIED ===")
    #SignalBus.player_hit.emit()
    #if animation_player:
        #animation_player.play("die")
    #if death_sound:
        #death_sound.play()
    #_spawn_ko_effect()
    #is_dead = true
    #
#func _on_area_3d_body_entered(other: Node3D) -> void:
    #if other.is_in_group("enemy") and other.is_alive() and not is_dead:
        #print("DEBUG: Hit by enemy: ", other.name)
        #die()
#
#func _disable_enemy_collisions():
    #collision_mask &= ~(1 << enemy_layer)
    #print("DEBUG: Enemy collisions disabled")
#
#func _spawn_ko_effect():
    #if ko_effect and ko_pivot:
        #var effect_instance = ko_effect.instantiate()
        #ko_pivot.add_child(effect_instance)
#
#func _spawn_smoke() -> void:
    #if smoke_particles:
        #var smoke_instance = smoke_particles.instantiate()
        #smoke_instance.position = position
        #get_tree().current_scene.add_child(smoke_instance)
#
#func _input(event):
    #if event.is_action_pressed("ui_select"):
        #print("Manual zero position calibration triggered")
        #_calibrate_zero_position()
    #elif event.is_action_pressed("ui_cancel"):
        #print("Manual Y-axis recalibration triggered")
        #is_calibrated = false
        #calibration_samples.clear()
        #print("Recalibrating Y baseline...")
    #elif event.is_action_pressed("ui_up"):
        #print("Manual jump test triggered")
        #if is_on_floor():
            #_perform_jump()
        #else:
            #print("Cannot jump - not on floor")
    #elif event.is_action_pressed("ui_home"):
        #verbose_debug = !verbose_debug
        #print("Verbose debug toggled: ", verbose_debug)
#
## Public API functions
#func _on_zero_pressed() -> void:
    #print("Zero button pressed")
    #_calibrate_zero_position()
#
#func recalibrate_position():
    #print("External position recalibration requested")
    #_calibrate_zero_position()
#
#func recalibrate_ground():
    #print("External Y-axis recalibration requested")
    #is_calibrated = false
    #calibration_samples.clear()
#
#func get_height_above_ground() -> float:
    #if not is_calibrated:
        #return 0.0
    #return current_y - baseline_y
#
#func start_game():
    #print("Game started!")
#
## Simplified toggle function
#func _on_adapt_rom_toggled(toggled_on: bool) -> void:
    #print("Adaptive mode toggled: ", toggled_on)



class_name Player
extends CharacterBody3D

@export_group("Movement")
@export var speed = 3.0
@export var fall_acceleration = 74.0
@export var jump_impulse = 20.0
@export var bounce_factor = 0.75
@export var smooth_movement = 0.2

@export_group("Boundaries")
@export var min_bounds = Vector3(-10, -100, -10)
@export var max_bounds = Vector3(10, 100, 10)
@export var boundary_buffer = 0.1

@export_group("Network Control")
@export var debug_mode: bool = false
@export var network_movement_enabled: bool = true
@export var movement_sensitivity: float = 1.0
@export var position_lerp_factor: float = 1
@export var network_deadzone: float = 0.05

# Adaptive mode support (restored from original)
var adapt_toggle: bool = false

@export_group("Jump Detection - SIMPLIFIED")
@export var jump_height_threshold: float = 0.02  # Minimum lift to trigger jump (2cm)
@export var jump_velocity_threshold: float = 0.005  # Minimum upward velocity
@export var jump_cooldown_time: float = 1.0  # Seconds between jumps
@export var smoothing_factor: float = 0.3  # For filtering sensor noise

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
var zero_offset = Vector3.ZERO

# SIMPLIFIED Jump detection variables
var baseline_y: float = 0.0  # Ground reference point
var current_y: float = 0.0
var previous_y: float = 0.0
var filtered_y: float = 0.0
var y_velocity: float = 0.0

var jump_cooldown: float = 0.0
var is_calibrated: bool = false
var calibration_samples = []
var calibration_count = 30  # Samples to collect for baseline

# State
var is_dead = false
var debug_frame_counter = 0

func _ready() -> void:
    print("=== PLAYER READY - SIMPLIFIED JUMP ===")
    print("Debug mode: ", debug_mode)
    print("Network movement enabled: ", network_movement_enabled)
    print("Jump height threshold: ", jump_height_threshold)
    print("Jump velocity threshold: ", jump_velocity_threshold)
    
    _initialize_position()
    _start_calibration()

func _initialize_position():
    # Initialize player at center of bounds
    position = Vector3(
        (min_bounds.x + max_bounds.x) / 2.0,
        0,
        (min_bounds.z + max_bounds.z) / 2.0
    )
    print("Initial position: ", position)

func _start_calibration():
    print("Starting calibration process...")
    calibration_samples.clear()
    is_calibrated = false
    
    if network_movement_enabled and not debug_mode:
        print("Waiting 1.5 seconds for network to stabilize...")
        await get_tree().create_timer(1.5).timeout
        _calibrate_zero_position()
        print("Collecting Y baseline samples...")
    else:
        print("Skipping network calibration (debug mode or network disabled)")

func _physics_process(delta: float) -> void:
    debug_frame_counter += 1
    
    if is_dead:
        return

    if jump_cooldown > 0:
        jump_cooldown -= delta

    # Update network position and Y tracking
    if network_movement_enabled and not debug_mode:
        _update_network_position()
        _update_y_tracking()

    # Calculate movement direction
    var direction = _calculate_velocity()
    direction = _smooth_movement_input(direction)

    # Apply movement with smoothing
    if direction.length() > network_deadzone:
        direction = direction.normalized()
        $Pivot.basis = $Pivot.basis.slerp(Basis.looking_at(-direction), smooth_movement)

    # Set horizontal velocity
    var horizontal_velocity = direction * speed
    velocity.x = lerp(velocity.x, horizontal_velocity.x, position_lerp_factor)
    velocity.z = lerp(velocity.z, horizontal_velocity.z, position_lerp_factor)

    # Handle jumping and falling
    if is_on_floor():
        if velocity.y < 0:
            Scoreboard.reset_combo()
            _spawn_smoke()
        
        # SIMPLIFIED JUMP CHECK
        if _should_jump():
            print("=== JUMP TRIGGERED ===")
            _perform_jump()
    else:
        velocity.y -= fall_acceleration * delta

    move_and_slide()

    # Clamp positions to boundaries
    position.x = clamp(position.x, min_bounds.x + boundary_buffer, max_bounds.x - boundary_buffer)
    position.z = clamp(position.z, min_bounds.z + boundary_buffer, max_bounds.z - boundary_buffer)

func _update_network_position():
    var current_network_pos = Vector2.ZERO
    
    if debug_mode:
        # Debug mode uses mouse position
        var mouse_pos = get_viewport().get_mouse_position()
        var screen_size = get_viewport().get_visible_rect().size
        current_network_pos = Vector2(
            (mouse_pos.x / screen_size.x) * (max_bounds.x - min_bounds.x) + min_bounds.x,
            (mouse_pos.y / screen_size.y) * (max_bounds.z - min_bounds.z) + min_bounds.z
        )
        if verbose_debug and debug_frame_counter % 60 == 0:
            print("DEBUG: Mouse position converted to network pos: ", current_network_pos)
    elif adapt_toggle:
        if GlobalScript.has_method("get_scaled_network_position"):
            current_network_pos = GlobalScript.scaled_network_position
        else:
            current_network_pos = GlobalScript.network_position
    else:
        if "network_position" in GlobalScript:
            current_network_pos = GlobalScript.network_position
            if verbose_debug and debug_frame_counter % 120 == 0:
                print("DEBUG: Network position: ", current_network_pos)

    # Convert to 3D and apply zero offset
    if current_network_pos != Vector2.ZERO:
        var new_network_pos = Vector3(current_network_pos.x, 0, current_network_pos.y)
        
        if zero_offset != Vector3.ZERO:
            new_network_pos = new_network_pos - zero_offset
        
        network_position = _map_network_to_bounds(new_network_pos)

func _map_network_to_bounds(net_pos: Vector3) -> Vector3:
    var mapped_pos = Vector3.ZERO
    
    var network_scale_x = movement_sensitivity * 0.01
    var network_scale_z = movement_sensitivity * 0.01
    
    mapped_pos.x = net_pos.x * network_scale_x
    mapped_pos.z = net_pos.z * network_scale_z
    
    mapped_pos.x = clamp(mapped_pos.x, min_bounds.x, max_bounds.x)
    mapped_pos.z = clamp(mapped_pos.z, min_bounds.z, max_bounds.z)
    
    return mapped_pos

func _update_y_tracking():
    if not "raw_y" in GlobalScript:
        return
    
    # Get raw Y value
    var raw_y = GlobalScript.raw_y
    previous_y = filtered_y
    
    # Apply smoothing filter to reduce noise
    filtered_y = lerp(filtered_y, raw_y, smoothing_factor)
    current_y = filtered_y
    
    # Calculate velocity (change per frame)
    y_velocity = current_y - previous_y
    
    # Handle calibration
    if not is_calibrated:
        calibration_samples.append(current_y)
        
        if calibration_samples.size() >= calibration_count:
            # Calculate baseline as average of samples
            var sum = 0.0
            for sample in calibration_samples:
                sum += sample
            baseline_y = sum / calibration_samples.size()
            
            is_calibrated = true
            print("=== Y-AXIS CALIBRATED ===")
            print("Baseline Y: ", baseline_y)
            print("Current Y: ", current_y)
    
    # Debug output
    if verbose_debug and debug_frame_counter % 30 == 0:
        var height_diff = current_y - baseline_y
        print("Y DEBUG: Raw=", raw_y, " Filtered=", current_y, " Baseline=", baseline_y, " Diff=", height_diff, " Vel=", y_velocity)

func _smooth_movement_input(direction: Vector3) -> Vector3:
    var magnitude = direction.length()
    if magnitude < network_deadzone:
        return Vector3.ZERO
    
    return direction.normalized() * pow(magnitude, 1.2)

func _should_jump() -> bool:
    if debug_mode:
        return Input.is_action_just_pressed("ui_accept")
    else:
        return _check_device_lift() and is_on_floor() and jump_cooldown <= 0

func _check_device_lift() -> bool:
    if not is_calibrated:
        return false
    
    # Calculate how much the device has been lifted
    var height_above_baseline = current_y - baseline_y
    var has_upward_velocity = y_velocity > jump_velocity_threshold
    var sufficient_lift = height_above_baseline > jump_height_threshold
    
    if verbose_debug and (sufficient_lift or has_upward_velocity):
        print("JUMP CHECK: Height=", height_above_baseline, " Vel=", y_velocity, " Lift=", sufficient_lift, " UpVel=", has_upward_velocity)
    
    # Jump if device is lifted high enough OR has strong upward velocity
    return sufficient_lift or has_upward_velocity

func _calculate_velocity() -> Vector3:
    var direction = Vector3.ZERO

    if debug_mode:
        # Debug mode keyboard input
        if Input.is_action_pressed("ui_right"):
            direction.x += 1
        if Input.is_action_pressed("ui_left"):
            direction.x -= 1
        if Input.is_action_pressed("ui_down"):
            direction.z += 1
        if Input.is_action_pressed("ui_up"):
            direction.z -= 1
    elif network_movement_enabled and network_position != Vector3.ZERO:
        # Use network position for movement direction (RESTORED SMOOTH MOVEMENT)
        var target_pos = network_position
        var current_pos = Vector3(position.x, 0, position.z)
        direction = (target_pos - current_pos)
        
        # Apply distance-based scaling for more responsive control
        var distance = direction.length()
        if distance > network_deadzone:
            # Scale movement based on distance for more responsive control
            var scale_factor = min(distance * 2.0, 1.0)
            direction = direction.normalized() * scale_factor
        
        if verbose_debug and debug_frame_counter % 60 == 0:
            print("DEBUG: Network movement - Target: ", target_pos, " Current: ", current_pos, " Direction: ", direction)
    else:
        # Fallback keyboard input
        if Input.is_action_pressed("move_right"):
            direction.x += 1
        if Input.is_action_pressed("move_left"):
            direction.x -= 1
        if Input.is_action_pressed("move_back"):
            direction.z += 1
        if Input.is_action_pressed("move_forward"):
            direction.z -= 1

    return direction

func _perform_jump():
    print("=== PERFORMING JUMP ===")
    print("Jump impulse: ", jump_impulse)
    
    if jump_sound:
        jump_sound.play()
    
    velocity.y = jump_impulse
    jump_cooldown = jump_cooldown_time
    
    print("New velocity.y: ", velocity.y)

func _calibrate_zero_position():
    print("=== CALIBRATING ZERO POSITION ===")
    if network_movement_enabled and not debug_mode:
        var current_network_pos = Vector2.ZERO
        
        if adapt_toggle:
            if GlobalScript.has_method("get_scaled_network_position"):
                current_network_pos = GlobalScript.scaled_network_position
                print("Using scaled network position for calibration")
            else:
                current_network_pos = GlobalScript.network_position
                print("Using fallback network position for calibration")
        else:
            if "network_position" in GlobalScript:
                current_network_pos = GlobalScript.network_position
                print("Using regular network position for calibration")
            else:
                print("ERROR: GlobalScript.network_position not found!")
                return
        
        if current_network_pos != Vector2.ZERO:
            zero_offset = Vector3(current_network_pos.x, 0, current_network_pos.y)
            print("Zero position calibrated to: ", zero_offset)
        else:
            print("WARNING: Network position is zero, calibration may not be accurate")
    else:
        print("Skipping zero position calibration (debug mode or network disabled)")

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
        print("Recalibrating Y baseline...")
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

func get_height_above_ground() -> float:
    if not is_calibrated:
        return 0.0
    return current_y - baseline_y

func start_game():
    print("Game started!")

# Simplified toggle function (restored from original)
func _on_adapt_rom_toggled(toggled_on: bool) -> void:
    adapt_toggle = toggled_on
    print("Adaptive mode toggled: ", toggled_on)
