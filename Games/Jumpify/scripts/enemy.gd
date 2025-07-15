extends CharacterBody3D

@export_group("Movement and size")
@export var min_speed = 1
@export var max_speed = 3
@export var min_scale = 1.0
@export var max_scale = 3.0


@export_group("Animation")
@export var collision_shape: CollisionShape3D
@export var animation_player: AnimationPlayer

@export_group("Sound")
@export var death_sound: AudioStreamPlayer

var is_dead = false

func _physics_process(_delta: float) -> void:
  move_and_slide()

func initiliaze(start_position: Vector3) -> void:
  var target = Vector3.BACK
  look_at_from_position(start_position, start_position + target, Vector3.UP)

  var random_speed = randf_range(min_speed, max_speed)
  velocity = Vector3.FORWARD * random_speed
  velocity = velocity.rotated(Vector3.UP, rotation.y)

  var target_scale = Vector3(
    randf_range(min_scale, max_scale),
    1.0,
    randf_range(min_scale, max_scale)
  )
  scale *= target_scale

  rotate_y(randf_range(-PI / 4, PI / 4))


func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
  queue_free()

func squash() -> void:
  if is_dead:
    return

  SignalBus.enemy_squashed.emit()

  is_dead = true

  collision_shape.disabled = true
  animation_player.play("squash")
  _play_squash_sound()

func _play_squash_sound() -> void:
  death_sound.pitch_scale = pow(1.05, Scoreboard.combo)
  death_sound.play()

func is_alive() -> bool:
  return !is_dead
 
