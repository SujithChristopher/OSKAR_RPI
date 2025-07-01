extends Node3D

@export var enemy_scene: PackedScene
@export var spawn_location: PathFollow3D
@export var player: Player
@export var enemyTimer: Timer

@export var scoreLabel: Label
@export var retryRectangle: ColorRect

@export var reload_game_transition: SceneTransition

var timer = Timer.new()

func _ready() -> void:
  enemyTimer.start()
  retryRectangle.hide()	# TODO: Transition is broken to self scene since packed scene ref is null
    # https://github.com/godotengine/godot/issues/104769
    # reload_game_transition.transition()

  SignalBus.player_hit.connect(_on_player_hit.bind())
  SignalBus.enemy_squashed.connect(_on_enemy_squashed.bind())

func _on_spawn_timer_timeout() -> void:
  spawn_location.progress_ratio = randf()

  var enemy = enemy_scene.instantiate()
  enemy.initiliaze(spawn_location.position)

  add_child(enemy)


func _on_player_hit() -> void:
  enemyTimer.stop()

  Scoreboard.record_score()
  await get_tree().create_timer(0.75).timeout

  retryRectangle.show()

func _on_enemy_squashed() -> void:
  Scoreboard.add_score()

func _unhandled_input(event: InputEvent) -> void:
   if event.is_action_pressed("ui_accept") and retryRectangle.is_visible():
    # TODO: Transition is broken to self scene since packed scene ref is null
    # https://github.com/godotengine/godot/issues/104769
    # reload_game_transition.transition()
     get_tree().reload_current_scene()
     Scoreboard.reset_score()
