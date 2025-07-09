extends Node3D

@export var play_button: Button
@export var game_scene: PackedScene
@export var tutorial_panel: Control
@export var scene_transition: Node3D

func _ready() -> void:
  tutorial_panel.visible = false

func _on_play_button_pressed() -> void:
  play_button.disabled = true
  scene_transition.transition()

func _on_how_to_play_pressed() -> void:
  tutorial_panel.visible = true

func _on_tutorial_close_pressed() -> void:
  tutorial_panel.visible = false
