extends Node3D
class_name CameraShake

@export var camera: Camera3D

@export_group("Shake")
@export var shake_intensity = 0.2
@export var shake_duration = 0.2

var shake_time = 0.0
var original_position = Vector3()

func _ready():
    original_position = camera.global_transform.origin

    SignalBus.enemy_squashed.connect(_shake.bind())
    SignalBus.player_hit.connect(_shake.bind())

func _process(delta):
    if shake_time > 0:
        shake_time -= delta
        camera.global_transform.origin = original_position + Vector3(
          randf_range(-shake_intensity, shake_intensity),
          randf_range(-shake_intensity, shake_intensity),
          randf_range(-shake_intensity, shake_intensity)
        )
    else:
        camera.global_transform.origin = original_position

# Call this method to trigger the shake
func _shake():
    shake_time = shake_duration
