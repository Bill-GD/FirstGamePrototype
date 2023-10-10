extends Node2D

@export var bullet_scene: PackedScene = load("res://bullet.tscn")
@export var enemy_scene: PackedScene = load("res://enemy.tscn")

var is_attacking: bool = false
var is_sped_up: bool = false
var fast_attack: bool = false
var score: float = 0
var total_kills: int = 0
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
			
		$Player/Camera/CanvasLayer/ControlOverlay.update_controls_text(
			'Speed up (shift): ' + str(is_sped_up) + 
			'\nMovement: ' + ' '.join(movement_keys) + 
			'\nAttacking (left mouse/space): ' + str(is_attacking) +
			'\nAttack mode (q) -> (' + str(snapped($AttackModeCooldown.time_left, 0.01)) + 's): ' + ('fast' if fast_attack else 'normal') +
			'\nEnemy spawn (z) -> (' + str(snapped($ToggleEnemySpawnCooldown.time_left, 0.01)) + 's): ' + str(toggle_enemy_spawn)
		)


func _on_enemy_hit():
	score += 0.25 if fast_attack else 1
	enemy_count = max (0, enemy_count - 1)
	max_enemy_count = 10 + (score / 5)
	total_kills += 1
	if $EnemySpawnTimer.wait_time > 0.2:
		$EnemySpawnTimer.wait_time -= 0.005
	
	$Player/Camera/CanvasLayer/ControlOverlay/Score.text = 'Score: ' + str(score)
	$Player/Camera/CanvasLayer/ControlOverlay/EnemyCount.text = 'Enemy count: ' + str(enemy_count) + '/' + str(max_enemy_count)
	$Player/Camera/CanvasLayer/ControlOverlay/TotalKill.text = 'Total kills: ' + str(total_kills)


func _on_player_hit():
	score -= 1
	max_enemy_count = 10 + (score / 5)
	
	$Player/Camera/CanvasLayer/ControlOverlay/PlayerHP.text = 'HP: ' + str($Player.current_hp)
	$Player/Camera/CanvasLayer/ControlOverlay/Score.text = 'Score: ' + str(score)
	$Player/Camera/CanvasLayer/ControlOverlay/EnemyCount.text = 'Enemy count: ' + str(enemy_count) + '/' + str(max_enemy_count)


func _on_enemy_spawn_timer_timeout():
	if enemy_count >= max_enemy_count or not toggle_enemy_spawn:
		return
	
	var enemy_spawn_location = $EnemyPath/EnemySpawnLocation
	enemy_spawn_location.progress_ratio = randf()
	
	var enemy = enemy_scene.instantiate()
	
	enemy.position = enemy_spawn_location.position
#	enemy.rotation = ($Player.position - enemy.position).normalized().angle()
	enemy.hit.connect(_on_enemy_hit)
	
	add_child(enemy)
	enemy_count += 1
	$Player/Camera/CanvasLayer/ControlOverlay/EnemyCount.text = 'Enemy count: ' + str(enemy_count) + '/' + str(max_enemy_count)


func _on_player_dead():
	$EnemySpawnTimer.stop()
	get_tree().call_group('enemies', 'queue_free')
	$Player.hide()
	$Player.set_physics_process(false)
	game_over = true
	$GameOverTimer.start()
	$Player/Camera/CanvasLayer/ControlOverlay.update_controls_text('Press "SPACE" to restart')
	await get_tree().create_timer(1).timeout
	$Player.position = Vector2(589, 315)


func set_new_game():
	game_over = false
	score = 0
	max_enemy_count = 10
	is_attacking = false
	is_sped_up = false
	fast_attack = false
	total_kills = 0
	enemy_count = 0
	$Player.current_hp = $Player.BASE_HP
	$Player.set_physics_process(true)
#	$Player.position = Vector2(589, 315)
	$Player.show()
	$EnemySpawnTimer.start()
	$Player/Camera/CanvasLayer/ControlOverlay.update_controls_text(
		'Speed up (shift): ' + str(is_sped_up) + 
		'\nMovement: ' + ' '.join(['  ', '  ', '  ', '  ']) + 
		'\nAttacking (left mouse/space): ' + str(is_attacking) +
		'\nAttack mode (q) -> (' + str(snapped($AttackModeCooldown.time_left, 0.01)) + 's): ' + ('fast' if fast_attack else 'normal') +
		'\nEnemy spawn (z) -> (' + str(snapped($ToggleEnemySpawnCooldown.time_left, 0.01)) + 's): ' + str(toggle_enemy_spawn)
	)
	$Player/Camera/CanvasLayer/ControlOverlay/PlayerHP.text = 'HP: ' + str($Player.current_hp)
	$Player/Camera/CanvasLayer/ControlOverlay/Score.text = 'Score: ' + str(score)
	$Player/Camera/CanvasLayer/ControlOverlay/EnemyCount.text = 'Enemy count: ' + str(enemy_count) + '/' + str(max_enemy_count)
	$Player/Camera/CanvasLayer/ControlOverlay/TotalKill.text = 'Total kills: ' + str(total_kills)
