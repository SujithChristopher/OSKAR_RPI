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


    

#version 2 moving smooth with minor issues 
#class_name Player
#extends Node3D
#
#@export_group("Movement")
#@export var speed = 2
#@export var fall_acceleration = 74
#@export var jump_impulse = 20
#@export var bounce_factor = 0.75
#@export var smooth_movement = 0.2
#
#@export_group("Network Control")
#@export var debug_mode: bool = true
#@export var network_movement_enabled: bool = false
#@export var movement_sensitivity: float = 1.0
#@export var jump_threshold: float = 0.1
#@export var position_lerp_factor: float = 0.8
#@export var network_deadzone: float = 0.01
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
#var network_position = Vector3.ZERO
#var last_network_y: float = 0.0
#var zero_offset = Vector3.ZERO
#var adapt_toggle: bool = false
#var previous_device_y: float = 0.0
#var jump_cooldown: float = 0.0
#var has_jumped_from_device: bool = false
#
#var is_dead = false
#var velocity_y: float = 0.0
#
#var json = JSON.new()
#var path = "res://debug.json"
#var debug_from_file: bool
#
#func _ready() -> void:
    #if FileAccess.file_exists(path):
        #debug_from_file = JSON.parse_string(FileAccess.get_file_as_string(path))['debug']
        #if debug_from_file:
            #debug_mode = true
    #_calibrate_zero_position()
#
#func _process(delta: float) -> void:
    #if is_dead:
        #return
#
    #if jump_cooldown > 0:
        #jump_cooldown -= delta
#
    #var direction = _calculate_velocity()
    #if direction.length() > 0:
        #direction = direction.normalized()
        #$Pivot.basis = $Pivot.basis.slerp(Basis.looking_at(direction * -1), smooth_movement)
#
    #var move = direction * speed * delta
    #position.x += move.x
    #position.z += move.z
#
    ## Gravity and Jumping
    #if _is_touching_floor():
        #if velocity_y < 0:
            #Scoreboard.reset_combo()
            #_spawn_smoke()
            #has_jumped_from_device = false
        #if _should_jump():
            #jump_sound.play()
            #velocity_y = jump_impulse
            #jump_cooldown = 0.3
            #has_jumped_from_device = true
        #else:
            #velocity_y = 0
    #else:
        #velocity_y -= fall_acceleration * delta
#
    #position.y += velocity_y * delta
#
#func _should_jump() -> bool:
    #if debug_mode:
        #return Input.is_action_just_pressed("ui_accept") and _is_touching_floor()
    #else:
        #return _check_network_jump() and _is_touching_floor() and jump_cooldown <= 0
#
#func _is_touching_floor() -> bool:
    #return position.y <= 0  # Simplified check, customize based on your level ground
#
#func _calculate_velocity() -> Vector3:
    #var direction = Vector3.ZERO
#
    #if debug_mode:
        #if Input.is_action_pressed("ui_right"):
            #direction.x += 1
        #if Input.is_action_pressed("ui_left"):
            #direction.x -= 1
        #if Input.is_action_pressed("ui_down"):
            #direction.z += 1
        #if Input.is_action_pressed("ui_up"):
            #direction.z -= 1
    #elif network_movement_enabled:
        #direction = _get_network_direction()
    #else:
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
#func _get_network_direction() -> Vector3:
    #var direction = Vector3.ZERO
    #if GlobalScript.network_position != Vector2.ZERO:
        #var current_network_pos = Vector3.ZERO
        #if adapt_toggle:
            #current_network_pos = Vector3(GlobalScript.scaled_network_position.x, 0, GlobalScript.scaled_network_position.y)
        #else:
            #current_network_pos = Vector3(GlobalScript.network_position.x, 0, GlobalScript.network_position.y)
#
        #current_network_pos -= zero_offset
        #var device_delta = current_network_pos - network_position
        #network_position = current_network_pos
#
        #var movement_scale = 0.01
        #direction.x = clamp(device_delta.x * movement_scale, -1.0, 1.0)
        #direction.z = clamp(device_delta.z * movement_scale, -1.0, 1.0)
         #
        #if abs(direction.x) < network_deadzone:
            #direction.x = 0
        #if abs(direction.z) < network_deadzone:
            #direction.z = 0
            #
#
    #return direction
#
#func _check_network_jump() -> bool:
    #var current_device_y = GlobalScript.raw_y
    #var lift_amount = current_device_y - previous_device_y
    #previous_device_y = current_device_y
    #return lift_amount > jump_threshold and not has_jumped_from_device
#
#func _calibrate_zero_position():
    #if network_movement_enabled and not debug_mode:
        #if GlobalScript.network_position != Vector2.ZERO:
            #zero_offset = Vector3(GlobalScript.network_position.x, 0, GlobalScript.network_position.y)
            #print("Zero position calibrated to: ", zero_offset)
#
#func _toggle_adaptive_mode(enabled: bool):
    #adapt_toggle = enabled
    #print("Adaptive mode: ", "ON" if enabled else "OFF")
#
#func die():
    #SignalBus.player_hit.emit()
    #animation_player.play("die")
    #death_sound.play()
    #_spawn_ko_effect()
    #is_dead = true
#
#func _spawn_ko_effect():
    #var effect_instance = ko_effect.instantiate()
    #ko_pivot.add_child(effect_instance)
#
#func _spawn_smoke() -> void:
    #var smoke_instance = smoke_particles.instantiate()
    #smoke_instance.position = position
    #get_tree().current_scene.add_child(smoke_instance)
#
#func _input(event):
    #if event.is_action_pressed("ui_select"):
        #_calibrate_zero_position()
    #elif event.is_action_pressed("ui_cancel"):
        #_toggle_adaptive_mode(!adapt_toggle)
#
#func _on_zero_pressed() -> void:
    #zero_offset = Vector3(GlobalScript.network_position.x, 0, GlobalScript.network_position.y)
    #
    #
#version 3 

#class_name Player
#extends Node3D
#
#@export_group("Movement")
#@export var speed = 2
#@export var fall_acceleration = 74
#@export var jump_impulse = 20
#@export var bounce_factor = 0.75
#@export var smooth_movement = 0.2
#
#@export_group("Boundaries")
#@export var min_bounds = Vector3(-10, -100, -10)
#@export var max_bounds = Vector3(10, 100, 10)
#@export var boundary_buffer = 0.1  # Small buffer to prevent edge clipping
#
#@export_group("Network Control")
#@export var debug_mode: bool = false
#@export var network_movement_enabled: bool = true
#@export var movement_sensitivity: float = 1.0
#@export var jump_threshold: float = 0.1
#@export var position_lerp_factor: float = 0.8
#@export var network_deadzone: float = 0.01
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
#var network_position = Vector3.ZERO
#var last_network_y: float = 0.0
#var zero_offset = Vector3.ZERO
#var adapt_toggle: bool = false
#var previous_device_y: float = 0.0
#var jump_cooldown: float = 0.0
#var has_jumped_from_device: bool = false
#
#var is_dead = false
#var velocity_y: float = 0.0
#
#var json = JSON.new()
#var path = "res://debug.json"
#var debug_from_file: bool
#
#func _ready() -> void:
    #if FileAccess.file_exists(path):
        #debug_from_file = JSON.parse_string(FileAccess.get_file_as_string(path))['debug']
        #if debug_from_file:
            #debug_mode = true
    #_calibrate_zero_position()
#
#func _process(delta: float) -> void:
    #if is_dead:
        #return
#
    #if jump_cooldown > 0:
        #jump_cooldown -= delta
#
    #var direction = _calculate_velocity()
    #if direction.length() > 0:
        #direction = direction.normalized()
        #$Pivot.basis = $Pivot.basis.slerp(Basis.looking_at(direction * -1), smooth_movement)
#
    #var move = direction * speed * delta
    #
    ## Apply movement with boundary checking
    #var new_x = position.x + move.x
    #var new_z = position.z + move.z
    #
    ## Clamp position to boundaries
    #new_x = clamp(new_x, min_bounds.x + boundary_buffer, max_bounds.x - boundary_buffer)
    #new_z = clamp(new_z, min_bounds.z + boundary_buffer, max_bounds.z - boundary_buffer)
    #
    #position.x = new_x
    #position.z = new_z
#
    ## Gravity and Jumping
    #if _is_touching_floor():
        #if velocity_y < 0:
            #Scoreboard.reset_combo()
            #_spawn_smoke()
            #has_jumped_from_device = false
        #if _should_jump():
            #jump_sound.play()
            #velocity_y = jump_impulse
            #jump_cooldown = 0.3
            #has_jumped_from_device = true
        #else:
            #velocity_y = 0
    #else:
        #velocity_y -= fall_acceleration * delta
#
    #var new_y = position.y + velocity_y * delta
    ## Clamp Y position to boundaries (optional, for ceiling/floor limits)
    #new_y = clamp(new_y, min_bounds.y, max_bounds.y)
    #position.y = new_y
#
#func _should_jump() -> bool:
    #if debug_mode:
        #return Input.is_action_just_pressed("ui_accept") and _is_touching_floor()
    #else:
        #return _check_network_jump() and _is_touching_floor() and jump_cooldown <= 0
#
#func _is_touching_floor() -> bool:
    #return position.y <= 0  # Simplified check, customize based on your level ground
#
#func _calculate_velocity() -> Vector3:
    #var direction = Vector3.ZERO
#
    #if debug_mode:
        #if Input.is_action_pressed("ui_right"):
            #direction.x += 1
        #if Input.is_action_pressed("ui_left"):
            #direction.x -= 1
        #if Input.is_action_pressed("ui_down"):
            #direction.z += 1
        #if Input.is_action_pressed("ui_up"):
            #direction.z -= 1
    #elif network_movement_enabled:
        #direction = _get_network_direction()
    #else:
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
#func _get_network_direction() -> Vector3:
    #var direction = Vector3.ZERO
    #if GlobalScript.network_position != Vector2.ZERO:
        #var current_network_pos = Vector3.ZERO
        #if adapt_toggle:
            #current_network_pos = Vector3(GlobalScript.scaled_network_position.x, 0, GlobalScript.scaled_network_position.y)
        #else:
            #current_network_pos = Vector3(GlobalScript.network_position.x, 0, GlobalScript.network_position.y)
#
        #current_network_pos -= zero_offset
        #var device_delta = current_network_pos - network_position
        #network_position = current_network_pos
#
        #var movement_scale = 0.01
        #direction.x = clamp(device_delta.x * movement_scale, -1.0, 1.0)
        #direction.z = clamp(device_delta.z * movement_scale, -1.0, 1.0)
         #
        #if abs(direction.x) < network_deadzone:
            #direction.x = 0
        #if abs(direction.z) < network_deadzone:
            #direction.z = 0
#
    #return direction
#
#func _check_network_jump() -> bool:
    #var current_device_y = GlobalScript.raw_y
    #var lift_amount = current_device_y - previous_device_y
    #previous_device_y = current_device_y
    #
    ## Enhanced jump detection with better threshold handling
    #var should_jump = lift_amount > jump_threshold and not has_jumped_from_device
    #
    ## Optional: Add debug print to help tune jump sensitivity
    #if debug_mode and should_jump:
        #print("Jump detected! Lift amount: ", lift_amount)
    #
    #return should_jump
#
#func _calibrate_zero_position():
    #if network_movement_enabled and not debug_mode:
        #if GlobalScript.network_position != Vector2.ZERO:
            #zero_offset = Vector3(GlobalScript.network_position.x, 0, GlobalScript.network_position.y)
            #print("Zero position calibrated to: ", zero_offset)
#
#func _toggle_adaptive_mode(enabled: bool):
    #adapt_toggle = enabled
    #print("Adaptive mode: ", "ON" if enabled else "OFF")
#
#func die():
    #SignalBus.player_hit.emit()
    #animation_player.play("die")
    #death_sound.play()
    #_spawn_ko_effect()
    #is_dead = true
#
#func _spawn_ko_effect():
    #var effect_instance = ko_effect.instantiate()
    #ko_pivot.add_child(effect_instance)
#
#func _spawn_smoke() -> void:
    #var smoke_instance = smoke_particles.instantiate()
    #smoke_instance.position = position
    #get_tree().current_scene.add_child(smoke_instance)
#
#func _input(event):
    #if event.is_action_pressed("ui_select"):
        #_calibrate_zero_position()
    #elif event.is_action_pressed("ui_cancel"):
        #_toggle_adaptive_mode(!adapt_toggle)
#
#func _on_zero_pressed() -> void:
    #zero_offset = Vector3(GlobalScript.network_position.x, 0, GlobalScript.network_position.y)
    
##  Version 4

class_name Player
extends Node3D



@export_group("Movement")
@export var speed = 2
@export var fall_acceleration = 74
@export var jump_impulse = 20
@export var bounce_factor = 0.75
@export var smooth_movement = 0.2

@export_group("Boundaries")
@export var min_bounds = Vector3(-10, -100, -10)
@export var max_bounds = Vector3(10, 100, 10)
@export var boundary_buffer = 0.1

@export_group("Network Control")
@export var debug_mode: bool = true
@export var network_movement_enabled: bool = false
@export var movement_sensitivity: float = 1.0
@export var jump_threshold: float = 0.3  # Increased for better jump detection
@export var position_lerp_factor: float = 0.8
@export var network_deadzone: float = 0.05  # Increased to reduce jittering

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

var network_position = Vector3.ZERO
var last_network_y: float = 0.0
var zero_offset = Vector3.ZERO
var adapt_toggle: bool = false
var previous_device_y: float = 0.0
var jump_cooldown: float = 0.0
var has_jumped_from_device: bool = false

var is_dead = false
var velocity_y: float = 0.0

# New variables for stability
var last_valid_position = Vector3.ZERO
var movement_accumulator = Vector3.ZERO
var y_velocity_samples = []
var sample_count = 5

var json = JSON.new()
var path = "res://debug.json"
var debug_from_file: bool

func _ready() -> void:
    if FileAccess.file_exists(path):
        debug_from_file = JSON.parse_string(FileAccess.get_file_as_string(path))['debug']
        if debug_from_file:
            debug_mode = true
    _calibrate_zero_position()
    last_valid_position = position

func _process(delta: float) -> void:
    if is_dead:
        return

    if jump_cooldown > 0:
        jump_cooldown -= delta

    var direction = _calculate_velocity()
    
    # Apply deadzone to reduce jittering
    if direction.length() < network_deadzone:
        direction = Vector3.ZERO
    
    if direction.length() > 0:
        direction = direction.normalized()
        $Pivot.basis = $Pivot.basis.slerp(Basis.looking_at(direction * -1), smooth_movement)

    # Calculate new position with proper boundary checking
    var move = direction * speed * delta
    var new_position = position + move
    
    # Strict boundary enforcement
    new_position.x = clamp(new_position.x, min_bounds.x + boundary_buffer, max_bounds.x - boundary_buffer)
    new_position.z = clamp(new_position.z, min_bounds.z + boundary_buffer, max_bounds.z - boundary_buffer)
    
    # Only update position if within bounds
    if new_position.x >= min_bounds.x + boundary_buffer and new_position.x <= max_bounds.x - boundary_buffer:
        position.x = new_position.x
    if new_position.z >= min_bounds.z + boundary_buffer and new_position.z <= max_bounds.z - boundary_buffer:
        position.z = new_position.z

    # Gravity and Jumping
    if _is_touching_floor():
        if velocity_y < 0:
            Scoreboard.reset_combo()
            _spawn_smoke()
            has_jumped_from_device = false
        if _should_jump():
            jump_sound.play()
            velocity_y = jump_impulse
            jump_cooldown = 0.5  # Increased cooldown
            has_jumped_from_device = true
            print("JUMP EXECUTED!")  # Debug print
        else:
            velocity_y = 0
    else:
        velocity_y -= fall_acceleration * delta

    var new_y = position.y + velocity_y * delta
    new_y = clamp(new_y, min_bounds.y, max_bounds.y)
    position.y = new_y
    
    # Store last valid position
    last_valid_position = position

func _should_jump() -> bool:
    if debug_mode:
        return Input.is_action_just_pressed("ui_accept") and _is_touching_floor()
    else:
        return _check_network_jump() and _is_touching_floor() and jump_cooldown <= 0

func _is_touching_floor() -> bool:
    return position.y <= 0.1  # Small buffer for floor detection

func _calculate_velocity() -> Vector3:
    var direction = Vector3.ZERO

    if debug_mode:
        if Input.is_action_pressed("ui_right"):
            direction.x += 1
        if Input.is_action_pressed("ui_left"):
            direction.x -= 1
        if Input.is_action_pressed("ui_down"):
            direction.z += 1
        if Input.is_action_pressed("ui_up"):
            direction.z -= 1
    elif network_movement_enabled:
        direction = _get_network_direction()
    else:
        if Input.is_action_pressed("move_right"):
            direction.x += 1
        if Input.is_action_pressed("move_left"):
            direction.x -= 1
        if Input.is_action_pressed("move_back"):
            direction.z += 1
        if Input.is_action_pressed("move_forward"):
            direction.z -= 1

    return direction

func _get_network_direction() -> Vector3:
    var direction = Vector3.ZERO
    if GlobalScript.network_position != Vector2.ZERO:
        var current_network_pos = Vector3.ZERO
        if adapt_toggle:
            current_network_pos = Vector3(GlobalScript.scaled_network_position.x, 0, GlobalScript.scaled_network_position.y)
        else:
            current_network_pos = Vector3(GlobalScript.network_position.x, 0, GlobalScript.network_position.y)

        current_network_pos -= zero_offset
        var device_delta = current_network_pos - network_position
        network_position = current_network_pos

        var movement_scale = 0.01
        direction.x = clamp(device_delta.x * movement_scale, -1.0, 1.0)
        direction.z = clamp(device_delta.z * movement_scale, -1.0, 1.0)
         
        # Enhanced deadzone with hysteresis
        if abs(direction.x) < network_deadzone:
            direction.x = 0
        if abs(direction.z) < network_deadzone:
            direction.z = 0

    return direction

func _check_network_jump() -> bool:
    var current_device_y = GlobalScript.raw_y
    
    # Add current sample to array
    y_velocity_samples.append(current_device_y)
    if y_velocity_samples.size() > sample_count:
        y_velocity_samples.pop_front()
    
    # Calculate average change over multiple samples for more stable jump detection
    if y_velocity_samples.size() >= 2:
        var total_change = 0.0
        for i in range(1, y_velocity_samples.size()):
            total_change += y_velocity_samples[i] - y_velocity_samples[i-1]
        
        var avg_change = total_change / (y_velocity_samples.size() - 1)
        var should_jump = avg_change > jump_threshold and not has_jumped_from_device
        
        if debug_mode:
            print("Y Change: ", avg_change, " Threshold: ", jump_threshold, " Should Jump: ", should_jump)
        
        return should_jump
    
    return false

func _calibrate_zero_position():
    if network_movement_enabled and not debug_mode:
        if GlobalScript.network_position != Vector2.ZERO:
            zero_offset = Vector3(GlobalScript.network_position.x, 0, GlobalScript.network_position.y)
            print("Zero position calibrated to: ", zero_offset)

func _toggle_adaptive_mode(enabled: bool):
    adapt_toggle = enabled
    print("Adaptive mode: ", "ON" if enabled else "OFF")

func die():
    SignalBus.player_hit.emit()
    animation_player.play("die")
    death_sound.play()
    _spawn_ko_effect()
    is_dead = true

func _spawn_ko_effect():
    var effect_instance = ko_effect.instantiate()
    ko_pivot.add_child(effect_instance)

func _spawn_smoke() -> void:
    var smoke_instance = smoke_particles.instantiate()
    smoke_instance.position = position
    get_tree().current_scene.add_child(smoke_instance)

func _input(event):
    if event.is_action_pressed("ui_select"):
        _calibrate_zero_position()
    elif event.is_action_pressed("ui_cancel"):
        _toggle_adaptive_mode(!adapt_toggle)

func _on_zero_pressed() -> void:
    zero_offset = Vector3(GlobalScript.network_position.x, 0, GlobalScript.network_position.y)
    
#correct clamping but slow moevement  
#class_name Player
#extends CharacterBody3D
#
#@export_group("Movement")
#@export var speed = 2
#@export var fall_acceleration = 74
#@export var jump_impulse = 20
#@export var bounce_factor = 0.75
#@export var smooth_movement = 0.2
#
#@export_group("Boundaries")
#@export var min_bounds = Vector3(-10, -100, -10)
#@export var max_bounds = Vector3(10, 100, 10)
#@export var boundary_buffer = 0.1
#
#@export_group("Network Control")
#@export var debug_mode: bool = true
#@export var network_movement_enabled: bool = false
#@export var movement_sensitivity: float = 1.0
#@export var jump_threshold: float = 0.3
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
#var network_position = Vector3.ZERO
#var last_network_y: float = 0.0
#var zero_offset = Vector3.ZERO
#var adapt_toggle: bool = false
#var previous_device_y: float = 0.0
#var jump_cooldown: float = 0.0
#var has_jumped_from_device: bool = false
#
#var is_dead = false
#
#var y_velocity_samples = []
#var sample_count = 5
#
#var json = JSON.new()
#var path = "res://debug.json"
#var debug_from_file: bool
#
#func _ready() -> void:
    #if FileAccess.file_exists(path):
        #debug_from_file = JSON.parse_string(FileAccess.get_file_as_string(path))['debug']
        #if debug_from_file:
            #debug_mode = true
    #_calibrate_zero_position()
#
#func _physics_process(delta: float) -> void:
    #if is_dead:
        #return
#
    #if jump_cooldown > 0:
        #jump_cooldown -= delta
#
    #var direction = _calculate_velocity()
    #if direction.length() < network_deadzone:
        #direction = Vector3.ZERO
#
    #if direction.length() > 0:
        #direction = direction.normalized()
        #$Pivot.basis = $Pivot.basis.slerp(Basis.looking_at(-direction), smooth_movement)
#
    #var horizontal_velocity = direction * speed
    #velocity.x = horizontal_velocity.x
    #velocity.z = horizontal_velocity.z
#
    #if is_on_floor():
        #if velocity.y < 0:
            #Scoreboard.reset_combo()
            #_spawn_smoke()
            #has_jumped_from_device = false
        #if _should_jump():
            #jump_sound.play()
            #velocity.y = jump_impulses
            #jump_cooldown = 0.5
            #has_jumped_from_device = true
    #else:
        #velocity.y -= fall_acceleration * delta
#
    #move_and_slide()
#
    ## Clamp X and Z positions to stay inside bounds
    #position.x = clamp(position.x, min_bounds.x + boundary_buffer, max_bounds.x - boundary_buffer)
    #position.z = clamp(position.z, min_bounds.z + boundary_buffer, max_bounds.z - boundary_buffer)
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
        #if Input.is_action_pressed("ui_right"):
            #direction.x += 1
        #if Input.is_action_pressed("ui_left"):
            #direction.x -= 1
        #if Input.is_action_pressed("ui_down"):
            #direction.z += 1
        #if Input.is_action_pressed("ui_up"):
            #direction.z -= 1
    #elif network_movement_enabled:
        #direction = _get_network_direction()
    #else:
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
#func _get_network_direction() -> Vector3:
    #var direction = Vector3.ZERO
    #if GlobalScript.network_position != Vector2.ZERO:
        #var current_network_pos = Vector3.ZERO
        #if adapt_toggle:
            #current_network_pos = Vector3(GlobalScript.scaled_network_position.x, 0, GlobalScript.scaled_network_position.y)
        #else:
            #current_network_pos = Vector3(GlobalScript.network_position.x, 0, GlobalScript.network_position.y)
#
        #current_network_pos -= zero_offset
        #var device_delta = current_network_pos - network_position
        #network_position = current_network_pos
#
        #var movement_scale = 0.01
        #direction.x = clamp(device_delta.x * movement_scale, -1.0, 1.0)
        #direction.z = clamp(device_delta.z * movement_scale, -1.0, 1.0)
#
        #if abs(direction.x) < network_deadzone:
            #direction.x = 0
        #if abs(direction.z) < network_deadzone:
            #direction.z = 0
#
    #return direction
#
#func _check_network_jump() -> bool:
    #var current_device_y = GlobalScript.raw_y
#
    #y_velocity_samples.append(current_device_y)
    #if y_velocity_samples.size() > sample_count:
        #y_velocity_samples.pop_front()
#
    #if y_velocity_samples.size() >= 2:
        #var total_change = 0.0
        #for i in range(1, y_velocity_samples.size()):
            #total_change += y_velocity_samples[i] - y_velocity_samples[i - 1]
#
        #var avg_change = total_change / (y_velocity_samples.size() - 1)
        #var should_jump = avg_change > jump_threshold and not has_jumped_from_device
#
        #if debug_mode:
            #print("Y Change: ", avg_change, " Threshold: ", jump_threshold, " Should Jump: ", should_jump)
#
        #return should_jump
#
    #return false
#
#func _calibrate_zero_position():
    #if network_movement_enabled and not debug_mode:
        #if GlobalScript.network_position != Vector2.ZERO:
            #zero_offset = Vector3(GlobalScript.network_position.x, 0, GlobalScript.network_position.y)
            #print("Zero position calibrated to: ", zero_offset)
#
#func _toggle_adaptive_mode(enabled: bool):
    #adapt_toggle = enabled
    #print("Adaptive mode: ", "ON" if enabled else "OFF")
#
#func die():
    #SignalBus.player_hit.emit()
    #animation_player.play("die")
    #death_sound.play()
    #_spawn_ko_effect()
    #is_dead = true
#
#func _spawn_ko_effect():
    #var effect_instance = ko_effect.instantiate()
    #ko_pivot.add_child(effect_instance)
#
#func _spawn_smoke() -> void:
    #var smoke_instance = smoke_particles.instantiate()
    #smoke_instance.position = position
    #get_tree().current_scene.add_child(smoke_instance)
#
#func _input(event):
    #if event.is_action_pressed("ui_select"):
        #_calibrate_zero_position()
    #elif event.is_action_pressed("ui_cancel"):
        #_toggle_adaptive_mode(!adapt_toggle)
#
#func _on_zero_pressed() -> void:
    #zero_offset = Vector3(GlobalScript.network_position.x, 0, GlobalScript.network_position.y)



#newwwwwwww
#
#class_name Player
#extends CharacterBody3D
#
#@export_group("Movement")
#@export var speed = 2
#@export var fall_acceleration = 74
#@export var jump_impulse = 2  # Small Y jump
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
#@export var jump_threshold: float = 0.3
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
#var network_position = Vector3.ZERO
#var zero_offset = Vector3.ZERO
#var adapt_toggle := false
#var jump_cooldown := 0.0
#var has_jumped_from_device := false
#var is_dead := false
#
#var y_velocity_samples = []
#var sample_count := 5
#var current_y := 0.0
#var y_velocity := 0.0
#
#func _ready():
    #_calibrate_zero_position()
    #current_y = global_position.y
#
#func _physics_process(delta: float) -> void:
    #if is_dead:
        #return
#
    #if jump_cooldown > 0:
        #jump_cooldown -= delta
#
    ## XZ Absolute movement
    #var direction = _calculate_velocity()
    #if direction.length() < network_deadzone:
        #direction = Vector3.ZERO
    #else:
        #direction = direction.normalized()
        #$Pivot.basis = $Pivot.basis.slerp(Basis.looking_at(-direction), smooth_movement)
#
    #var move = direction * speed * delta
    #var new_pos = global_position + move
    #new_pos.x = clamp(new_pos.x, min_bounds.x + boundary_buffer, max_bounds.x - boundary_buffer)
    #new_pos.z = clamp(new_pos.z, min_bounds.z + boundary_buffer, max_bounds.z - boundary_buffer)
#
    #global_position.x = new_pos.x
    #global_position.z = new_pos.z
#
    ## Y-axis handled by move_and_slide()
    #if is_on_floor():
        #if velocity.y < 0:
            #Scoreboard.reset_combo()
            #_spawn_smoke()
            #has_jumped_from_device = false
        #if _should_jump():
            #jump_sound.play()
            #velocity.y = jump_impulse
            #jump_cooldown = 0.5
            #has_jumped_from_device = true
        #else:
            #velocity.y = 0
    #else:
        #velocity.y -= fall_acceleration * delta
#
    #velocity = Vector3(0, velocity.y, 0)
    #move_and_slide()
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
        #if Input.is_action_pressed("ui_right"):
            #direction.x += 1
        #if Input.is_action_pressed("ui_left"):
            #direction.x -= 1
        #if Input.is_action_pressed("ui_down"):
            #direction.z += 1
        #if Input.is_action_pressed("ui_up"):
            #direction.z -= 1
    #elif network_movement_enabled:
        #direction = _get_network_direction()
    #else:
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
#func _get_network_direction() -> Vector3:
    #var direction = Vector3.ZERO
    #if GlobalScript.network_position != Vector2.ZERO:
        #var current_network_pos = Vector3.ZERO
        #if adapt_toggle:
            #current_network_pos = Vector3(GlobalScript.scaled_network_position.x, 0, GlobalScript.scaled_network_position.y)
        #else:
            #current_network_pos = Vector3(GlobalScript.network_position.x, 0, GlobalScript.network_position.y)
#
        #current_network_pos -= zero_offset
        #var device_delta = current_network_pos - network_position
        #network_position = current_network_pos
#
        #var movement_scale = 0.01
        #direction.x = clamp(device_delta.x * movement_scale, -1.0, 1.0)
        #direction.z = clamp(device_delta.z * movement_scale, -1.0, 1.0)
#
        #if abs(direction.x) < network_deadzone:
            #direction.x = 0
        #if abs(direction.z) < network_deadzone:
            #direction.z = 0
#
    #return direction
#
#func _check_network_jump() -> bool:
    #var current_device_y = GlobalScript.raw_y
#
    #y_velocity_samples.append(current_device_y)
    #if y_velocity_samples.size() > sample_count:
        #y_velocity_samples.pop_front()
#
    #if y_velocity_samples.size() >= 2:
        #var total_change = 0.0
        #for i in range(1, y_velocity_samples.size()):
            #total_change += y_velocity_samples[i] - y_velocity_samples[i - 1]
#
        #var avg_change = total_change / (y_velocity_samples.size() - 1)
        #var should_jump = avg_change > jump_threshold and not has_jumped_from_device
#
        #if debug_mode:
            #print("Y Change: ", avg_change, " Threshold: ", jump_threshold, " Should Jump: ", should_jump)
#
        #return should_jump
#
    #return false
#
#func _calibrate_zero_position():
    #if network_movement_enabled and not debug_mode:
        #if GlobalScript.network_position != Vector2.ZERO:
            #zero_offset = Vector3(GlobalScript.network_position.x, 0, GlobalScript.network_position.y)
            #print("Zero position calibrated to: ", zero_offset)
#
#func _toggle_adaptive_mode(enabled: bool):
    #adapt_toggle = enabled
    #print("Adaptive mode: ", "ON" if enabled else "OFF")
#
#func die():
    #SignalBus.player_hit.emit()
    #animation_player.play("die")
    #death_sound.play()
    #_spawn_ko_effect()
    #is_dead = true
#
#func _spawn_ko_effect():
    #var effect_instance = ko_effect.instantiate()
    #ko_pivot.add_child(effect_instance)
#
#func _spawn_smoke() -> void:
    #var smoke_instance = smoke_particles.instantiate()
    #smoke_instance.position = global_position
    #get_tree().current_scene.add_child(smoke_instance)
#
#func _input(event):
    #if event.is_action_pressed("ui_select"):
        #_calibrate_zero_position()
    #elif event.is_action_pressed("ui_cancel"):
        #_toggle_adaptive_mode(!adapt_toggle)
#
#func _on_zero_pressed() -> void:
    #zero_offset = Vector3(GlobalScript.network_position.x, 0, GlobalScript.network_position.y)
