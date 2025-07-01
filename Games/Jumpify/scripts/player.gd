class_name Player extends CharacterBody3D

@export_group("Movement")
@export var speed = 3.5
@export var fall_acceleration = 74
@export var jump_impulse = 20
@export var bounce_factor = 0.75
@export var smooth_movement = 0.2

@export_group("Animation")
@export var animation_player: AnimationPlayer
@export var rigidbody: CharacterBody3D
@export var enemy_layer = 1

@export_group("Sound")
@export var jump_sound: AudioStreamPlayer
@export var death_sound: AudioStreamPlayer

@export_group("Effects")
@export var ko_pivot: Node3D
@export var ko_effect: PackedScene
@export var smoke_particles: PackedScene

var target_velocity = Vector3.ZERO
var is_dead = false

func _ready() -> void:
  apply_floor_snap()

func _physics_process(delta: float) -> void:
  var direction = _calculate_velocity()

  if direction != Vector3.ZERO:
    direction = direction.normalized()
    $Pivot.basis = $Pivot.basis.slerp(Basis.looking_at(direction * -1), smooth_movement)

  target_velocity.x = direction.x * speed
  target_velocity.z = direction.z * speed

  if _is_touching_floor() and target_velocity.y < 0:
    Scoreboard.reset_combo()
    _spawn_smoke()

  if _is_touching_floor() and Input.is_action_just_pressed("jump") and !is_dead:
    jump_sound.play()
    target_velocity.y = jump_impulse
  elif _is_touching_surface():
    target_velocity.y = 0
  else:
    target_velocity.y -= fall_acceleration * delta

  for index in range(get_slide_collision_count()):
    var collision = get_slide_collision(index)

    if collision.get_collider() == null:
      continue

    if collision.get_collider().is_in_group("enemy"):
      var enemy = collision.get_collider()
      if Vector3.UP.dot(collision.get_normal()) > 0.1:
        enemy.squash()
        _spawn_smoke()
        target_velocity.y = jump_impulse * bounce_factor
    break

  velocity = velocity.lerp(target_velocity, smooth_movement)
  
  move_and_slide()

func _is_touching_floor() -> bool:
  if !_is_touching_surface():
    return false
  
  for index in range(get_slide_collision_count()):
    var collision = get_slide_collision(index)

    if collision.get_collider() == null:
      continue

    if collision.get_collider().is_in_group("floor"):
      return true

  return false

func _is_touching_surface() -> bool:
  return is_on_floor()

func _calculate_velocity() -> Vector3:
  var direction = Vector3.ZERO

  if is_dead:
    return direction

  if Input.is_action_pressed("move_right"):
    direction.x += 1
  if Input.is_action_pressed("move_left"):
    direction.x -= 1
  if Input.is_action_pressed("move_back"):
    direction.z += 1
  if Input.is_action_pressed("move_forward"):
    direction.z -= 1

  return direction

func die():
  SignalBus.player_hit.emit()

  animation_player.play("die")
  death_sound.play()
  _spawn_ko_effect()
  _disable_enemy_collisions()
  is_dead = true

func _spawn_ko_effect():
  var effect_instance = ko_effect.instantiate()
  ko_pivot.add_child(effect_instance)

func _on_area_3d_body_entered(other: Node3D) -> void:
  if other.is_in_group("enemy") and other.is_alive() and !is_dead:
    die()

func _disable_enemy_collisions():
  rigidbody.collision_mask &= ~(1 << enemy_layer)

func _spawn_smoke() -> void:
  var smoke_instance = smoke_particles.instantiate()
  smoke_instance.position = position
  get_tree().current_scene.add_child(smoke_instance)

func _physics_processs(delta):
    print("physics running")
    if Input.is_action_pressed("jump"):
        print("jump pressed")
