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
  #var effect_instance = ko_effect.instantiate()
  #ko_pivot.add_child(effect_instance)
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

#version 2
#
#class_name Player extends CharacterBody3D
#
#@export_group("Movement")
#@export var speed = 5
#@export var fall_acceleration = 74
#@export var jump_impulse = 20
#@export var bounce_factor = 0.75
#@export var smooth_movement = 0.2
#
#@export_group("Network Control")
#@export var debug_mode: bool = true
#@export var network_movement_enabled: bool = false
#@export var movement_sensitivity: float = 1.0
#@export var jump_threshold: float = 0.1  # Height threshold for jumping
#@export var position_lerp_factor: float = 0.8
#@export var network_deadzone: float = 0.01  # Minimum movement to register
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
## Network position variables
#var network_position = Vector3.ZERO
#var last_network_y: float = 0.0
#var zero_offset = Vector3.ZERO
#var adapt_toggle: bool = false
#var previous_device_y: float = 0.0
#var jump_cooldown: float = 0.0
#var has_jumped_from_device: bool = false
#
## Game state
#var target_velocity = Vector3.ZERO
#var is_dead = false
#
## JSON debug setup
#var json = JSON.new()
#var path = "res://debug.json"
#var debug_from_file: bool
#
#func _ready() -> void:
    ## Load debug setting from file if it exists
    #if FileAccess.file_exists(path):
        #debug_from_file = JSON.parse_string(FileAccess.get_file_as_string(path))['debug']
        #if debug_from_file:
            #debug_mode = true
    #
    #apply_floor_snap()
    #
    ## Initialize network position tracking
    #if network_movement_enabled and not debug_mode:
        #network_position = Vector3.ZERO
        #last_network_y = 0.0
#
#func _physics_process(delta: float) -> void:
    ## Update jump cooldown
    #if jump_cooldown > 0:
        #jump_cooldown -= delta
    #
    ## Get movement direction based on control mode
    #var direction = _calculate_velocity()
    #
    ## Handle rotation and movement
    #if direction != Vector3.ZERO:
        #direction = direction.normalized()
        #$Pivot.basis = $Pivot.basis.slerp(Basis.looking_at(direction * -1), smooth_movement)
    #
    #target_velocity.x = direction.x * speed
    #target_velocity.z = direction.z * speed
    #
    ## Handle landing
    #if _is_touching_floor() and target_velocity.y < 0:
        #Scoreboard.reset_combo()
        #_spawn_smoke()
        #has_jumped_from_device = false  # Reset jump flag when landing
    #
    ## Handle jumping
    #var should_jump = false
    #if debug_mode:
        #should_jump = Input.is_action_just_pressed("ui_accept") and _is_touching_floor() and !is_dead
    #else:
        #should_jump = _check_network_jump() and _is_touching_floor() and !is_dead and jump_cooldown <= 0
    #
    #if should_jump:
        #jump_sound.play()
        #target_velocity.y = jump_impulse
        #jump_cooldown = 0.3  # Prevent rapid jumping
        #has_jumped_from_device = true
    #elif _is_touching_surface():
        #target_velocity.y = 0
    #else:
        #target_velocity.y -= fall_acceleration * delta
    #
    ## Handle enemy collisions
    #for index in range(get_slide_collision_count()):
        #var collision = get_slide_collision(index)
        #if collision.get_collider() == null:
            #continue
        #if collision.get_collider().is_in_group("enemy"):
            #var enemy = collision.get_collider()
            #if Vector3.UP.dot(collision.get_normal()) > 0.1:
                #enemy.squash()
                #_spawn_smoke()
                #target_velocity.y = jump_impulse * bounce_factor
        #break
    #
    ## Apply smooth movement
    #velocity = velocity.lerp(target_velocity, smooth_movement)
    #move_and_slide()
#
#func _is_touching_floor() -> bool:
    #if !_is_touching_surface():
        #return false
    #
    #for index in range(get_slide_collision_count()):
        #var collision = get_slide_collision(index)
        #if collision.get_collider() == null:
            #continue
        #if collision.get_collider().is_in_group("floor"):
            #return true
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
    #if debug_mode:
        ## Debug mode: use keyboard input
        #if Input.is_action_pressed("ui_right"):
            #direction.x += 1
        #if Input.is_action_pressed("ui_left"):
            #direction.x -= 1
        #if Input.is_action_pressed("ui_down"):
            #direction.z += 1
        #if Input.is_action_pressed("ui_up"):
            #direction.z -= 1
    #elif network_movement_enabled:
        ## Network mode: use device position
        #direction = _get_network_direction()
    #else:
        ## Fallback: original input system
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
    #
    ## Get current network position from GlobalScript (same as Random Reach)
    #if GlobalScript.network_position != Vector2.ZERO:
        #var current_network_pos = Vector3.ZERO
        #
        #if adapt_toggle:
            #current_network_pos = Vector3(GlobalScript.scaled_network_position.x, 0, GlobalScript.scaled_network_position.y)
        #else:
            #current_network_pos = Vector3(GlobalScript.network_position.x, 0, GlobalScript.network_position.y)
        #
        ## Apply zero offset (same as Random Reach)
        #current_network_pos = current_network_pos - zero_offset
        #
        ## Calculate movement based on device position change (not absolute position)
        #var device_delta = current_network_pos - network_position
        #network_position = current_network_pos
        #
        ## Convert device movement to game direction
        ## Scale down the movement to make it more controllable
        #var movement_scale = 0.01  # Adjust this value to control sensitivity
        #direction.x = device_delta.x * movement_scale
        #direction.z = device_delta.z * movement_scale
        #
        ## Apply deadzone to prevent jittery movement
        #if abs(direction.x) < network_deadzone:
            #direction.x = 0
        #if abs(direction.z) < network_deadzone:
            #direction.z = 0
        #
        ## Clamp the direction to prevent too fast movement
        #direction.x = clamp(direction.x, -1.0, 1.0)
        #direction.z = clamp(direction.z, -1.0, 1.0)
    #
    #return direction
#
#func _check_network_jump() -> bool:
    #if not network_movement_enabled:
        #return false
    #
    ## Get current device Y position
    #var current_device_y = GlobalScript.raw_y
    #
    ## Check if device was lifted up significantly
    #var lift_amount = current_device_y - previous_device_y
    #var should_jump = lift_amount > jump_threshold and not has_jumped_from_device
    #
    ## Update previous position
    #previous_device_y = current_device_y
    #
    #return should_jump
#
#func _calibrate_zero_position():
    #"""Optional calibration function - call this to fine-tune position (same as Random Reach)"""
    #if network_movement_enabled and not debug_mode:
        #if GlobalScript.network_position != Vector2.ZERO:
            #zero_offset = Vector3(GlobalScript.network_position.x, 0, GlobalScript.network_position.y)
            #print("Zero position calibrated to: ", zero_offset)
#
#func _toggle_adaptive_mode(enabled: bool):
    #"""Toggle adaptive scaling mode"""
    #adapt_toggle = enabled
    #print("Adaptive mode: ", "ON" if enabled else "OFF")
#
#func die():
    #SignalBus.player_hit.emit()
    #animation_player.play("die")
    #death_sound.play()
    #_spawn_ko_effect()
    #_disable_enemy_collisions()
    #is_dead = true
#
#func _spawn_ko_effect():
    #var effect_instance = ko_effect.instantiate()
    #ko_pivot.add_child(effect_instance)
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
#
## Input handling functions for UI (optional calibration like Random Reach)
#func _input(event):
    #if event.is_action_pressed("ui_select"):  # Enter key - optional calibration
        #_calibrate_zero_position()
    #elif event.is_action_pressed("ui_cancel"):  # Escape key - toggle adaptive mode
        #_toggle_adaptive_mode(!adapt_toggle)
#
## Optional calibration function (same as Random Reach _on_zero_pressed)
#func _on_zero_pressed() -> void:
    #zero_offset = Vector3(GlobalScript.network_position.x, 0, GlobalScript.network_position.y)
    
    
    
#version 3 the player is slowly moving

#class_name Player extends CharacterBody3D
#
#@export_group("Movement")
#@export var speed = 5
#@export var fall_acceleration = 74
#@export var jump_impulse = 20
#@export var bounce_factor = 0.75
#@export var smooth_movement = 0.2
#
#@export_group("Network Control")
#@export var debug_mode: bool = true
#@export var network_movement_enabled: bool = false
#@export var movement_sensitivity: float = 10.0
#@export var jump_threshold: float = 0.1
#@export var position_lerp_factor: float = 0.8
#@export var network_deadzone: float = 0.01
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
## Network position variables
#var network_position = Vector3.ZERO
#var last_network_y: float = 0.0
#var zero_offset = Vector3.ZERO
#var adapt_toggle: bool = false
#var previous_device_y: float = 0.0
#var jump_cooldown: float = 0.0
#var has_jumped_from_device: bool = false
#
## Game state
#var is_dead = false
#var vertical_velocity = 0.0
#
## JSON debug setup
#var json = JSON.new()
#var path = "res://debug.json"
#var debug_from_file: bool
#
#func _ready() -> void:
    #if FileAccess.file_exists(path):
        #debug_from_file = JSON.parse_string(FileAccess.get_file_as_string(path))['debug']
        #if debug_from_file:
            #debug_mode = true
    #apply_floor_snap()
#
#func _physics_process(delta: float) -> void:
    #if jump_cooldown > 0:
        #jump_cooldown -= delta
#
    #var direction = _calculate_velocity()
#
    #if direction.length() > 1:
        #direction = direction.normalized()
#
    #position += direction * speed * delta
#
    #var should_jump = false
    #if debug_mode:
        #should_jump = Input.is_action_just_pressed("ui_accept") and _is_touching_floor() and !is_dead
    #else:
        #should_jump = _check_network_jump() and _is_touching_floor() and !is_dead and jump_cooldown <= 0
#
    #if should_jump:
        #jump_sound.play()
        #vertical_velocity = jump_impulse
        #jump_cooldown = 0.3
        #has_jumped_from_device = true
    #elif _is_touching_floor():
        #vertical_velocity = 0
        #has_jumped_from_device = false
    #else:
        #vertical_velocity -= fall_acceleration * delta
#
    #position.y += vertical_velocity * delta
#
#func _calculate_velocity() -> Vector3:
    #var direction = Vector3.ZERO
    #if is_dead:
        #return direction
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
#
    #return direction
#
#func _get_network_direction() -> Vector3:
    #var direction = Vector3.ZERO
    #if GlobalScript.network_position != Vector2.ZERO:
        #var current_network_pos = Vector3.ZERO
#
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
        #direction.x = device_delta.x * movement_scale
        #direction.z = device_delta.z * movement_scale
#
        #if abs(direction.x) < network_deadzone:
            #direction.x = 0
        #if abs(direction.z) < network_deadzone:
            #direction.z = 0
#
        #direction.x = clamp(direction.x, -1.0, 1.0)
        #direction.z = clamp(direction.z, -1.0, 1.0)
#
    #return direction
#
#func _check_network_jump() -> bool:
    #if not network_movement_enabled:
        #return false
#
    #var current_device_y = GlobalScript.raw_y
    #var lift_amount = current_device_y - previous_device_y
    #var should_jump = lift_amount > jump_threshold and not has_jumped_from_device
    #previous_device_y = current_device_y
    #return should_jump
#
#func _is_touching_floor() -> bool:
    #return is_on_floor()
#
#func die():
    #SignalBus.player_hit.emit()
    #animation_player.play("die")
    #death_sound.play()
    #_spawn_ko_effect()
    #_disable_enemy_collisions()
    #is_dead = true
#
#func _spawn_ko_effect():
    #var effect_instance = ko_effect.instantiate()
    #ko_pivot.add_child(effect_instance)
#
#func _disable_enemy_collisions():
    #rigidbody.collision_mask &= ~(1 << enemy_layer)
#
#func _spawn_smoke() -> void:
    #var smoke_instance = smoke_particles.instantiate()
    #smoke_instance.position = position
    #get_tree().current_scene.add_child(smoke_instance)
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
#func _input(event):
    #if event.is_action_pressed("ui_select"):
        #_calibrate_zero_position()
    #elif event.is_action_pressed("ui_cancel"):
        #_toggle_adaptive_mode(!adapt_toggle)

#version 4 moving smooth with minor issues 

class_name Player
extends Node3D

@export_group("Movement")
@export var speed = 2
@export var fall_acceleration = 74
@export var jump_impulse = 20
@export var bounce_factor = 0.75
@export var smooth_movement = 0.2

@export_group("Network Control")
@export var debug_mode: bool = false
@export var network_movement_enabled: bool = true
@export var movement_sensitivity: float = 1.0
@export var jump_threshold: float = 0.1
@export var position_lerp_factor: float = 0.8
@export var network_deadzone: float = 0.01

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

var json = JSON.new()
var path = "res://debug.json"
var debug_from_file: bool

func _ready() -> void:
    if FileAccess.file_exists(path):
        debug_from_file = JSON.parse_string(FileAccess.get_file_as_string(path))['debug']
        if debug_from_file:
            debug_mode = true
    _calibrate_zero_position()

func _process(delta: float) -> void:
    if is_dead:
        return

    if jump_cooldown > 0:
        jump_cooldown -= delta

    var direction = _calculate_velocity()
    if direction.length() > 0:
        direction = direction.normalized()
        $Pivot.basis = $Pivot.basis.slerp(Basis.looking_at(direction * -1), smooth_movement)

    var move = direction * speed * delta
    position.x += move.x
    position.z += move.z

    # Gravity and Jumping
    if _is_touching_floor():
        if velocity_y < 0:
            Scoreboard.reset_combo()
            _spawn_smoke()
            has_jumped_from_device = false
        if _should_jump():
            jump_sound.play()
            velocity_y = jump_impulse
            jump_cooldown = 0.3
            has_jumped_from_device = true
        else:
            velocity_y = 0
    else:
        velocity_y -= fall_acceleration * delta

    position.y += velocity_y * delta

func _should_jump() -> bool:
    if debug_mode:
        return Input.is_action_just_pressed("ui_accept") and _is_touching_floor()
    else:
        return _check_network_jump() and _is_touching_floor() and jump_cooldown <= 0

func _is_touching_floor() -> bool:
    return position.y <= 0  # Simplified check, customize based on your level ground

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

        if abs(direction.x) < network_deadzone:
            direction.x = 0
        if abs(direction.z) < network_deadzone:
            direction.z = 0

    return direction

func _check_network_jump() -> bool:
    var current_device_y = GlobalScript.raw_y
    var lift_amount = current_device_y - previous_device_y
    previous_device_y = current_device_y
    return lift_amount > jump_threshold and not has_jumped_from_device

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
