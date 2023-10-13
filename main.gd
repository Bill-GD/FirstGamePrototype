extends Node2D

@export var bullet_scene: PackedScene = load("res://bullet.tscn")
@export var enemy_scene: PackedScene = load("res://enemy.tscn")

var is_attacking: bool = false
var is_sped_up: bool = false
var fast_attack: bool = false
var score: float = 0
var highscore: float = 0
var total_kills: int = 0
var best_kill_count: int = 0
var enemy_count: int = 0
var max_enemy_count: int = 10
var toggle_enemy_spawn: bool = true
var game_over: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$AttackCooldown.start()
	$EnemySpawnTimer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if game_over:
		$Player/Camera/CanvasLayer/ControlOverlay/Controls.text = 'Can restart: ' + str($GameOverTimer.is_stopped()) + ' (' + str(snapped($GameOverTimer.time_left, 0.01)) + ')'
		if Input.is_key_pressed(KEY_SPACE) and $GameOverTimer.is_stopped():
			set_new_game()
	else:
		is_attacking = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_SPACE)
		is_sped_up = Input.is_action_pressed('ui_shift')
		
		if Input.is_key_pressed(KEY_Z) and $ToggleEnemySpawnCooldown.is_stopped():
			toggle_enemy_spawn = not toggle_enemy_spawn
			$ToggleEnemySpawnCooldown.start()
			
		if Input.is_key_pressed(KEY_Q) and $AttackModeCooldown.is_stopped():
			fast_attack = not fast_attack
			$AttackCooldown.wait_time = 0.05 if fast_attack else 0.5
			$AttackModeCooldown.start()

		var movement_keys = ['  ', '  ', '  ', '  ']
		if not movement_keys.has('A') and Input.is_action_pressed('aswd_left'): movement_keys[0] = 'A'
		if not movement_keys.has('S') and Input.is_action_pressed('aswd_down'): movement_keys[1] = 'S'
		if not movement_keys.has('W') and Input.is_action_pressed('aswd_up'): movement_keys[2] = 'W'
		if not movement_keys.has('D') and Input.is_action_pressed('aswd_right'): movement_keys[3] = 'D'
		
		if is_attacking and $AttackCooldown.is_stopped():
			var bullet = bullet_scene.instantiate()
			var shoot_direction: Vector2 = $Player.get_global_mouse_position() - $Player.position
			
			if shoot_direction.length() >= 15:
				bullet.position = $Player.position + shoot_direction.normalized() * 15
				add_child(bullet)
				$AttackCooldown.start()
			else:
				is_attacking = false
		
		$Player/Camera/CanvasLayer/ControlOverlay/Controls.text = 'Speed up: %s\n' % is_sped_up + 'Movement:\n' + 'Attacking: %s\n' % is_attacking + 'Attack mode: %s (%0.2fs)\n' % [('fast' if fast_attack else 'normal'), $AttackModeCooldown.time_left] + 'Enemy spawn: %s (%0.2fs)' % [toggle_enemy_spawn, $ToggleEnemySpawnCooldown.time_left]


func _on_enemy_hit():
	score += (0.25 if fast_attack else 1)
	enemy_count = max (0, enemy_count - 1)
	max_enemy_count = 10 + int(score / 5)
	total_kills += 1
	if $EnemySpawnTimer.wait_time > 0.2:
		$EnemySpawnTimer.wait_time -= 0.005
	
	$Player/Camera/CanvasLayer/ControlOverlay/Score.text = 'Score: %s' % score
	$Player/Camera/CanvasLayer/ControlOverlay/EnemyCount.text = 'Enemy count: %s/%s' % [enemy_count, max_enemy_count]
	$Player/Camera/CanvasLayer/ControlOverlay/TotalKill.text = 'Total kills: %s' % total_kills


func _on_player_hit():
	score -= 1
	max_enemy_count = 10 + (max(0, score) / 5)
	
	$Player/Camera/CanvasLayer/ControlOverlay/PlayerHP.text = 'HP: %s' % $Player.current_hp
	$Player/Camera/CanvasLayer/ControlOverlay/Score.text = 'Score: %s' % score
	$Player/Camera/CanvasLayer/ControlOverlay/EnemyCount.text = 'Enemy count: %s/%s' % [enemy_count, max_enemy_count]


func _on_enemy_spawn_timer_timeout():
	if enemy_count >= max_enemy_count or not toggle_enemy_spawn:
		return
	
	var enemy_spawn_location = $EnemyPath/EnemySpawnLocation
	var enemy = enemy_scene.instantiate()
	enemy.player = $Player
	while true:
		enemy_spawn_location.progress_ratio = randf()
		
		enemy.position = enemy_spawn_location.position
		
		if (enemy.position - $Player.position).length() > 200:
			break
#	enemy.rotation = ($Player.position - enemy.position).normalized().angle()
	enemy.hit.connect(_on_enemy_hit)
	
	add_child(enemy)
	enemy_count += 1
	$Player/Camera/CanvasLayer/ControlOverlay/EnemyCount.text = 'Enemy count: %s/%s' % [enemy_count, max_enemy_count]


func _on_player_dead():
	$Player/Camera/CanvasLayer/ControlOverlay/PlayerHP.text = 'HP: 0'
	if score > highscore:
		highscore = score
		$Player/Camera/CanvasLayer/ControlOverlay/HighScore.text = 'High Score: %s' % highscore
	if total_kills > best_kill_count:
		best_kill_count = total_kills
		$Player/Camera/CanvasLayer/ControlOverlay/BestKillCount.text = 'Best Kill Count: %s' % best_kill_count
	if score < 0: $Player/Camera/CanvasLayer/ControlOverlay/Score.text += ' (git gud)'
	$Player/Camera/CanvasLayer/ControlOverlay/Controls.text = 'Press "SPACE" to restart'
	
	$EnemySpawnTimer.stop()
	get_tree().call_group('enemies', 'queue_free')
	$Player.hide()
	$Player.set_physics_process(false)
	game_over = true
	$GameOverTimer.start()
	await get_tree().create_timer(1).timeout
	$Player.position = Vector2(589, 315)


func set_new_game():
	get_tree().call_group('enemies', 'queue_free')
	score = 0
	max_enemy_count = 10
	is_attacking = false
	is_sped_up = false
	fast_attack = false
	$AttackCooldown.wait_time = 0.5
	total_kills = 0
	enemy_count = 0
	$Player.current_hp = $Player.BASE_HP
	$Player.set_physics_process(true)
#	$Player.position = Vector2(589, 315)
	$Player.show()
	$EnemySpawnTimer.start()
	$Player/Camera/CanvasLayer/ControlOverlay/Controls.text = 'Speed up: %s\n' % is_sped_up + 'Movement:\n' + 'Attacking: %s\n' % is_attacking + 'Attack mode: %s (%0.2fs)\n' % [('fast' if fast_attack else 'normal'), $AttackModeCooldown.time_left] + 'Enemy spawn: %s (%0.2fs)' % [toggle_enemy_spawn, $ToggleEnemySpawnCooldown.time_left]

	$Player/Camera/CanvasLayer/ControlOverlay/PlayerHP.text = 'HP: %s' % $Player.current_hp
	$Player/Camera/CanvasLayer/ControlOverlay/Score.text = 'Score: %s' % score
	$Player/Camera/CanvasLayer/ControlOverlay/EnemyCount.text = 'Enemy count: %s/%s' % [enemy_count, max_enemy_count]
	$Player/Camera/CanvasLayer/ControlOverlay/TotalKill.text = 'Total kills: %s' % total_kills
	
	await get_tree().create_timer(1).timeout
	game_over = false
