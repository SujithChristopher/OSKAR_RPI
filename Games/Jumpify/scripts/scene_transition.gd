extends Node3D
class_name SceneTransition

@export_group("References")
@export var next_scene: PackedScene
#@export var subviewport: SubViewport

@export_group("Animation")
@export var animator: AnimationPlayer
@export var animation: String = "closing"
@export var playback_speed: float = 1.5

var transitioning: bool = false

func _ready() -> void:
  #subviewport.size = get_viewport().get_visible_rect().size
  #get_viewport().connect("size_changed", _on_window_resized)
  #_on_window_resized()

  animator.speed_scale = playback_speed

func transition() -> void:
  if transitioning:
   return

  transitioning = true

  # Start closing animation
  animator.play(animation)
  await animator.animation_finished

  # Load next scene
  var old_scene = get_tree().current_scene
  var new_scene = next_scene.instantiate()

  # Change current scene to new scene
  get_tree().root.add_child(new_scene)
  self.reparent(new_scene)
  get_tree().current_scene = new_scene
  old_scene.queue_free()

  # Stop animation
  animator.play_backwards(animation)
  await animator.animation_finished

  # Destroy this node
  queue_free()


func _transition_to_new_scene() -> void:
  next_scene.instantiate()

#func _on_window_resized() -> void:
  #subviewport.size = get_viewport().get_visible_rect().size
