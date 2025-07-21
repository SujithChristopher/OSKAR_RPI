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

# Hope

#class_name Player
#extends CharacterBody3D
#
#@export_group("Movement")
#@export var speed = 2.0
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
#@export var jump_threshold: float = 2.0  # 2cm threshold for jumping
#@export var position_lerp_factor: float = 0.8
#@export var network_deadzone: float = 0.05
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
## Network position variables
#var network_position = Vector3.ZERO
#var zero_offset = Vector3.ZERO
#var calibrated_ground_y: float = 0.0
#var is_calibrated: bool = false
#var game_started: bool = false
#
## Adaptive mode support (like Random Reach)
#var adapt_toggle: bool = false
#
## Jump detection
#var y_position_samples = []
#var y_sample_count = 10
#var jump_cooldown: float = 0.0
#var has_jumped_from_device: bool = false
#var ground_detection_samples = []
#var ground_sample_count = 5
#
## State
#var is_dead = false
#
## Debug
#var json = JSON.new()
#var path = "res://debug.json"
#var debug_from_file: bool
#
#func _ready() -> void:
    #if FileAccess.file_exists(path):
        #var file_data = JSON.parse_string(FileAccess.get_file_as_string(path))
        #if file_data and file_data.has('debug'):
            #debug_from_file = file_data['debug']
            #if debug_from_file:
                #debug_mode = true
    #
    #_initialize_buffers()
    #_start_calibration()
    #
    ## Initialize player at center of bounds
    #position = Vector3(
        #(min_bounds.x + max_bounds.x) / 2.0,
        #0,
        #(min_bounds.z + max_bounds.z) / 2.0
    #)
#
#func _initialize_buffers():
    #y_position_samples.resize(y_sample_count)
    #ground_detection_samples.resize(ground_sample_count)
    #
    #for i in range(y_sample_count):
        #y_position_samples[i] = 0.0
    #
    #for i in range(ground_sample_count):
        #ground_detection_samples[i] = 0.0
#
#func _start_calibration():
    #if network_movement_enabled and not debug_mode:
        #await get_tree().create_timer(1.0).timeout  # Wait for network to stabilize
        #_calibrate_zero_position()
#
#func _physics_process(delta: float) -> void:
    #if is_dead:
        #return
#
    #if jump_cooldown > 0:
        #jump_cooldown -= delta
#
    ## Update network position and movement
    #if network_movement_enabled and not debug_mode:
        #_update_network_position()
        #_update_ground_detection()
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
            #has_jumped_from_device = false
        #
        #if _should_jump():
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
    ## Get network position based on mode
    #var current_network_pos = Vector2.ZERO
    #
    #if debug_mode:
        ## Debug mode uses mouse position
        #var mouse_pos = get_viewport().get_mouse_position()
        #var screen_size = get_viewport().get_visible_rect().size
        ## Convert to bounds coordinates
        #current_network_pos = Vector2(
            #(mouse_pos.x / screen_size.x) * (max_bounds.x - min_bounds.x) + min_bounds.x,
            #(mouse_pos.y / screen_size.y) * (max_bounds.z - min_bounds.z) + min_bounds.z
        #)
    #elif adapt_toggle:
        ## Use scaled network position when adaptive mode is on
        #if GlobalScript.has_method("get_scaled_network_position"):
            #current_network_pos = GlobalScript.scaled_network_position
        #else:
            #current_network_pos = GlobalScript.network_position
    #else:
        ## Use regular network position
        #current_network_pos = GlobalScript.network_position
#
    ## Convert to 3D and apply zero offset
    #if current_network_pos != Vector2.ZERO:
        #var new_network_pos = Vector3(current_network_pos.x, 0, current_network_pos.y)
        #
        ## Apply zero offset
        #if zero_offset != Vector3.ZERO:
            #new_network_pos = new_network_pos - zero_offset
        #
        ## Map network coordinates to game bounds
        #network_position = _map_network_to_bounds(new_network_pos)
#
#func _map_network_to_bounds(net_pos: Vector3) -> Vector3:
    ## This function maps network coordinates to the game bounds
    ## You may need to adjust this based on your coordinate system
    #var mapped_pos = Vector3.ZERO
    #
    ## Simple mapping - adjust these factors based on your network coordinate range
    #var network_scale_x = 0.01  # Adjust based on your network coordinate range
    #var network_scale_z = 0.01  # Adjust based on your network coordinate range
    #
    #mapped_pos.x = net_pos.x * network_scale_x
    #mapped_pos.z = net_pos.z * network_scale_z
    #
    ## Clamp to bounds
    #mapped_pos.x = clamp(mapped_pos.x, min_bounds.x, max_bounds.x)
    #mapped_pos.z = clamp(mapped_pos.z, min_bounds.z, max_bounds.z)
    #
    #return mapped_pos
#
#func _update_ground_detection():
    #if not "raw_y" in GlobalScript:
        #return
    #
    #var current_device_y = GlobalScript.raw_y
    #
    ## Update ground detection samples
    #ground_detection_samples.push_back(current_device_y)
    #if ground_detection_samples.size() > ground_sample_count:
        #ground_detection_samples.pop_front()
    #
    ## Calibrate ground level if needed
    #if not is_calibrated and ground_detection_samples.size() >= ground_sample_count:
        #_calibrate_ground_level()
#
#func _calibrate_ground_level():
    #var sum = 0.0
    #for sample in ground_detection_samples:
        #sum += sample
    #
    #calibrated_ground_y = sum / ground_detection_samples.size()
    #is_calibrated = true
    #print("Ground level calibrated to: ", calibrated_ground_y, " cm")
#
#func _smooth_movement_input(direction: Vector3) -> Vector3:
    ## Simple smoothing without complex buffering
    #return direction
#
#func _should_jump() -> bool:
    #if debug_mode:
        #return Input.is_action_just_pressed("ui_accept") and is_on_floor()
    #else:
        #return _check_network_jump() and is_on_floor() and jump_cooldown <= 0
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
        #direction = (target_pos - current_pos).normalized()
        #
        ## Apply deadzone
        #if direction.length() < network_deadzone:
            #direction = Vector3.ZERO
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
#func _check_network_jump() -> bool:
    #if not is_calibrated or not "raw_y" in GlobalScript:
        #return false
    #
    #var current_device_y = GlobalScript.raw_y
    #var height_above_ground = current_device_y - calibrated_ground_y
    #
    ## Update Y position samples for jump detection
    #y_position_samples.push_back(height_above_ground)
    #if y_position_samples.size() > y_sample_count:
        #y_position_samples.pop_front()
    #
    ## Check if device is above jump threshold (2cm)
    #if height_above_ground > jump_threshold and not has_jumped_from_device:
        ## Additional check: ensure it's a sustained lift, not just noise
        #var sustained_samples = 0
        #var required_samples = min(3, y_position_samples.size())
        #
        #for i in range(y_position_samples.size() - required_samples, y_position_samples.size()):
            #if y_position_samples[i] > jump_threshold:
                #sustained_samples += 1
        #
        #var should_jump = sustained_samples >= required_samples
        #
        #if debug_mode:
            #print("Height above ground: ", height_above_ground, "cm, Should Jump: ", should_jump)
        #
        #return should_jump
    #
    #return false
#
#func _perform_jump():
    #jump_sound.play()
    #velocity.y = jump_impulse
    #jump_cooldown = 0.5
    #has_jumped_from_device = true
#
#func _calibrate_zero_position():
    #if network_movement_enabled and not debug_mode:
        #var current_network_pos = Vector2.ZERO
        #
        #if adapt_toggle:
            #if GlobalScript.has_method("get_scaled_network_position"):
                #current_network_pos = GlobalScript.scaled_network_position
            #else:
                #current_network_pos = GlobalScript.network_position
        #else:
            #current_network_pos = GlobalScript.network_position
        #
        #if current_network_pos != Vector2.ZERO:
            #zero_offset = Vector3(current_network_pos.x, 0, current_network_pos.y)
            #print("Zero position calibrated to: ", zero_offset)
#
#func die():
    #SignalBus.player_hit.emit()
    #animation_player.play("die")
    #death_sound.play()
    #_spawn_ko_effect()
    #is_dead = true
    #
#func _on_area_3d_body_entered(other: Node3D) -> void:
    #if other.is_in_group("enemy") and other.is_alive() and not is_dead:
        #die()
#
#func _disable_enemy_collisions():
    ## Disable enemy collisions on this CharacterBody3D
    #collision_mask &= ~(1 << enemy_layer)
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
        #_calibrate_zero_position()
    #elif event.is_action_pressed("ui_cancel"):
        ## Recalibrate ground level
        #is_calibrated = false
        #ground_detection_samples.clear()
        #print("Recalibrating ground level...")
#
#func _on_zero_pressed() -> void:
    #_calibrate_zero_position()
#
## Public functions for external calibration
#func recalibrate_position():
    #_calibrate_zero_position()
#
#func recalibrate_ground():
    #is_calibrated = false
    #ground_detection_samples.clear()
#
#func get_height_above_ground() -> float:
    #if not is_calibrated or not "raw_y" in GlobalScript:
        #return 0.0
    #return GlobalScript.raw_y - calibrated_ground_y
#
## Adaptive mode toggle function (like Random Reach)
#func _on_adapt_rom_toggled(toggled_on: bool) -> void:
    #adapt_toggle = toggled_on
#
## Game start function
#func start_game():
    #game_started = true
    #




class_name Player
extends CharacterBody3D

@export_group("Movement")
@export var speed = 2.0
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
@export var jump_threshold: float = 2.0  # 2cm threshold for jumping
@export var position_lerp_factor: float = 0.8
@export var network_deadzone: float = 0.05

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

# Network position variables (simplified like 2D)
var network_position_2d = Vector2.ZERO  # Keep as 2D like working code
var zero_offset = Vector2.ZERO  # Keep as 2D like working code
var calibrated_ground_y: float = 0.0
var is_calibrated: bool = false
var game_started: bool = false

# Adaptive mode support (like Random Reach)
var adapt_toggle: bool = false

# Jump detection
var y_position_samples = []
var y_sample_count = 10
var jump_cooldown: float = 0.0
var has_jumped_from_device: bool = false
var ground_detection_samples = []
var ground_sample_count = 5

# State
var is_dead = false

# Debug
var json = JSON.new()
var path = "res://debug.json"
var debug_from_file: bool

func _ready() -> void:
    if FileAccess.file_exists(path):
        var file_data = JSON.parse_string(FileAccess.get_file_as_string(path))
        if file_data and file_data.has('debug'):
            debug_from_file = file_data['debug']
            if debug_from_file:
                debug_mode = true
    
    _initialize_buffers()
    
    # Initialize player at center of bounds (safe position)
    position = Vector3(
        (min_bounds.x + max_bounds.x) / 2.0,
        2.0,  # Start above ground
        (min_bounds.z + max_bounds.z) / 2.0
    )
    
    # Initialize network position with safe default
    if is_instance_valid(GlobalScript):
        if GlobalScript.network_position == Vector2.ZERO:
            GlobalScript.network_position = Vector2(0.5, 0.5)
    
    _start_calibration()
    
    print("Player initialized at position: ", position)

func _initialize_buffers():
    y_position_samples.resize(y_sample_count)
    ground_detection_samples.resize(ground_sample_count)
    
    for i in range(y_sample_count):
        y_position_samples[i] = 0.0
    
    for i in range(ground_sample_count):
        ground_detection_samples[i] = 0.0

func _start_calibration():
    if network_movement_enabled and not debug_mode:
        await get_tree().create_timer(1.0).timeout  # Wait for network to stabilize
        _calibrate_zero_position()

func _physics_process(delta: float) -> void:
    if is_dead:
        return

    if jump_cooldown > 0:
        jump_cooldown -= delta

    # Update network position (simplified like 2D)
    if network_movement_enabled:
        _update_network_movement()
        _update_ground_detection()

    # Handle jumping and falling
    if is_on_floor():
        if velocity.y < 0:
            Scoreboard.reset_combo()
            _spawn_smoke()
            has_jumped_from_device = false
        
        if _should_jump():
            _perform_jump()
    else:
        velocity.y -= fall_acceleration * delta

    # Keep horizontal velocity zero (we control position directly like 2D)
    velocity.x = 0
    velocity.z = 0

    move_and_slide()

    # Clamp positions to boundaries (like 2D)
    position.x = clamp(position.x, min_bounds.x + boundary_buffer, max_bounds.x - boundary_buffer)
    position.z = clamp(position.z, min_bounds.z + boundary_buffer, max_bounds.z - boundary_buffer)

func _get_network_position() -> Vector2:
    """Get network position from appropriate source (like 2D code)"""
    
    if debug_mode:
        # Convert mouse position to normalized coordinates
        var mouse_pos = get_viewport().get_mouse_position()
        var screen_size = get_viewport().get_visible_rect().size
        return Vector2(
            mouse_pos.x / screen_size.x,
            mouse_pos.y / screen_size.y
        )
    elif adapt_toggle and is_instance_valid(GlobalScript):
        return GlobalScript.scaled_network_position if GlobalScript.has_method("get") else GlobalScript.network_position
    elif is_instance_valid(GlobalScript):
        return GlobalScript.network_position
    else:
        return Vector2(0.5, 0.5)  # Safe default

func _update_network_movement():
    """Update horizontal position based on network input (simplified like 2D code)"""
    
    network_position_2d = _get_network_position()
    
    # Only process valid network positions (like 2D code check)
    if network_position_2d == Vector2.ZERO and not debug_mode:
        return
    
    # Apply zero offset (like 2D code)
    network_position_2d = network_position_2d - zero_offset
    
    # Convert normalized position to world coordinates (like 2D)
    var target_x = network_position_2d.x * (max_bounds.x - min_bounds.x) + min_bounds.x
    var target_z = network_position_2d.y * (max_bounds.z - min_bounds.z) + min_bounds.z
    
    # Direct position lerping (like 2D code)
    position.x = lerp(position.x, target_x, position_lerp_factor)
    position.z = lerp(position.z, target_z, position_lerp_factor)
    
    # Update pivot rotation for visual feedback
    if network_position_2d.length() > network_deadzone:
        var direction = Vector3(target_x - position.x, 0, target_z - position.z)
        if direction.length() > 0.1:
            $Pivot.basis = $Pivot.basis.slerp(Basis.looking_at(-direction.normalized()), smooth_movement)

func _update_ground_detection():
    if not is_instance_valid(GlobalScript) or not "raw_y" in GlobalScript:
        return
    
    var current_device_y = GlobalScript.raw_y
    
    # Update ground detection samples
    ground_detection_samples.push_back(current_device_y)
    if ground_detection_samples.size() > ground_sample_count:
        ground_detection_samples.pop_front()
    
    # Calibrate ground level if needed
    if not is_calibrated and ground_detection_samples.size() >= ground_sample_count:
        _calibrate_ground_level()

func _calibrate_ground_level():
    var sum = 0.0
    for sample in ground_detection_samples:
        sum += sample
    
    calibrated_ground_y = sum / ground_detection_samples.size()
    is_calibrated = true
    print("Ground level calibrated to: ", calibrated_ground_y, " cm")

func _should_jump() -> bool:
    if debug_mode:
        return Input.is_action_just_pressed("ui_accept") and is_on_floor()
    else:
        return _check_network_jump() and is_on_floor() and jump_cooldown <= 0

func _check_network_jump() -> bool:
    if not is_calibrated or not is_instance_valid(GlobalScript) or not "raw_y" in GlobalScript:
        return false
    
    var current_device_y = GlobalScript.raw_y
    var height_above_ground = current_device_y - calibrated_ground_y
    
    # Update Y position samples for jump detection
    y_position_samples.push_back(height_above_ground)
    if y_position_samples.size() > y_sample_count:
        y_position_samples.pop_front()
    
    # Check if device is above jump threshold (2cm)
    if height_above_ground > jump_threshold and not has_jumped_from_device:
        # Additional check: ensure it's a sustained lift, not just noise
        var sustained_samples = 0
        var required_samples = min(3, y_position_samples.size())
        
        for i in range(y_position_samples.size() - required_samples, y_position_samples.size()):
            if y_position_samples[i] > jump_threshold:
                sustained_samples += 1
        
        var should_jump = sustained_samples >= required_samples
        
        if debug_mode:
            print("Height above ground: ", height_above_ground, "cm, Should Jump: ", should_jump)
        
        return should_jump
    
    return false

func _perform_jump():
    jump_sound.play()
    velocity.y = jump_impulse
    jump_cooldown = 0.5
    has_jumped_from_device = true

func _calibrate_zero_position():
    """Set current network position as zero point (like 2D code)"""
    zero_offset = _get_network_position()
    print("Zero position calibrated to: ", zero_offset)

func die():
    SignalBus.player_hit.emit()
    animation_player.play("die")
    death_sound.play()
    _spawn_ko_effect()
    is_dead = true
    
func _on_area_3d_body_entered(other: Node3D) -> void:
    if other.is_in_group("enemy") and other.is_alive() and not is_dead:
        die()

func _disable_enemy_collisions():
    # Disable enemy collisions on this CharacterBody3D
    collision_mask &= ~(1 << enemy_layer)

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
        _calibrate_zero_position()
    elif event.is_action_pressed("ui_cancel"):
        # Recalibrate ground level
        is_calibrated = false
        ground_detection_samples.clear()
        print("Recalibrating ground level...")

func _on_zero_pressed() -> void:
    _calibrate_zero_position()

# Public functions for external calibration
func recalibrate_position():
    _calibrate_zero_position()

func recalibrate_ground():
    is_calibrated = false
    ground_detection_samples.clear()

func get_height_above_ground() -> float:
    if not is_calibrated or not is_instance_valid(GlobalScript) or not "raw_y" in GlobalScript:
        return 0.0
    return GlobalScript.raw_y - calibrated_ground_y

# Adaptive mode toggle function (like Random Reach)
func _on_adapt_rom_toggled(toggled_on: bool) -> void:
    adapt_toggle = toggled_on

# Game start function
func start_game():
    game_started = true
