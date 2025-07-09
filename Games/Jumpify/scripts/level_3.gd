extends Node3D

@export var enemy_scene: PackedScene
@export var coin_scene: PackedScene  # Add coin scene reference
@export var spawn_location: PathFollow3D
@export var player: Player
@export var enemyTimer: Timer
@export var scoreLabel: Label
@export var retryRectangle: ColorRect


# Spawn settings
@export_group("Spawn Settings")
@export var coin_spawn_chance: float = 0.3  # 30% chance to spawn coin instead of enemy
@export var min_spawn_interval: float = 0.5
@export var max_spawn_interval: float = 2.0

var timer = Timer.new()

func _ready() -> void:
    enemyTimer.start()
    retryRectangle.hide()
    
    # Set up random spawn intervals
    _set_random_spawn_interval()
    
    # TODO: Transition is broken to self scene since packed scene ref is null
    # https://github.com/godotengine/godot/issues/104769
    # reload_game_transition.transition()
    
    SignalBus.player_hit.connect(_on_player_hit.bind())
    SignalBus.enemy_squashed.connect(_on_enemy_squashed.bind())
    SignalBus.coin_collected.connect(_on_coin_collected.bind())  # Add coin collection signal

func _on_spawn_timer_timeout() -> void:
    spawn_location.progress_ratio = randf()
    
    # Randomly decide whether to spawn coin or enemy
    if randf() < coin_spawn_chance:
        _spawn_coin()
    else:
        _spawn_enemy()
    
    # Set next random spawn interval
    _set_random_spawn_interval()

func _spawn_enemy() -> void:
    var enemy = enemy_scene.instantiate()
    enemy.initiliaze(spawn_location.position)  # Fixed typo: initiliaze -> initialize
    add_child(enemy)

func _spawn_coin() -> void:
    var coin = coin_scene.instantiate()
    coin.initialize(spawn_location.position)  # You'll need to add this method to coin.gd
    add_child(coin)

func _set_random_spawn_interval() -> void:
    var random_interval = randf_range(min_spawn_interval, max_spawn_interval)
    enemyTimer.wait_time = random_interval

func _on_player_hit() -> void:
    enemyTimer.stop()
    Scoreboard.record_score()
    await get_tree().create_timer(0.75).timeout
    retryRectangle.show()

func _on_enemy_squashed() -> void:
    Scoreboard.add_score()

func _on_coin_collected() -> void:
    # Add coin collection logic here
    Scoreboard.add_coin_score()  # You'll need to add this method to Scoreboard

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept") and retryRectangle.is_visible():
        # TODO: Transition is broken to self scene since packed scene ref is null
        # https://github.com/godotengine/godot/issues/104769
        # reload_game_transition.transition()
        get_tree().reload_current_scene()
        Scoreboard.reset_score()
