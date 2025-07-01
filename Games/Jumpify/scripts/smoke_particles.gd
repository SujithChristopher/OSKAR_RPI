extends Node3D

@export var particles: GPUParticles3D

func _ready() -> void:
  particles.emitting = true
  await particles.finished
  queue_free()
