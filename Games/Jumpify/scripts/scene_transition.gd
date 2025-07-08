extends Node3D
class_name SceneTransition

@export_group("References")
@export var next_scene: PackedScene
@export var subviewport: SubViewport

@export_group("Animation")
@export var animator: AnimationPlayer
@export var animation: String = "closing"
@export var playback_speed: float = 1.5

var transitioning: bool = false

func _ready() -> void:
  subviewport.size = get_viewport().get_visible_rect().size
  get_viewport().connect("size_changed", _on_window_resized)
  _on_window_resized()

  animator.speed_scale = playback_speed

func transition() -> void:
    if transitioning:
        print("Already transitioning, skipping.")
        return

    print("Starting transition...")
    transitioning = true

    if animator.has_animation(animation):
        print("Playing animation: ", animation)
        animator.play(animation)
        await animator.animation_finished
        print("Animation finished")
    else:
        print("❌ ERROR: Animation not found: ", animation)
        return

    var old_scene = get_tree().current_scene
    var new_scene = next_scene.instantiate()

    get_tree().root.add_child(new_scene)
    self.reparent(new_scene)
    get_tree().current_scene = new_scene
    old_scene.queue_free()

    print("Scene changed, now playing animation backwards...")
    animator.play_backwards(animation)
    await animator.animation_finished
    print("Finished transition.")
    queue_free()



func _transition_to_new_scene() -> void:
  next_scene.instantiate()

func _on_window_resized() -> void:
  subviewport.size = get_viewport().get_visible_rect().size
