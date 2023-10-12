extends CharacterBody2D

var BASE_SPEED: int = 200
var BASE_HP: int = 20

var SPRINT_SPEED: float = BASE_SPEED * 2
var can_speed_up: bool = true
var current_hp: int = BASE_HP

signal hit
signal dead

func _physics_process(_delta):
	var direction: Vector2 = Input.get_vector('aswd_left', 'aswd_right', 'aswd_up', 'aswd_down')
	can_speed_up = not (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_SPACE))
	
	velocity = direction * (SPRINT_SPEED if Input.is_action_pressed('ui_shift') and can_speed_up else BASE_SPEED)
	$Sprite2D.rotation = (get_global_mouse_position() - position).angle() + (PI / 2)
	$CollisionPolygon2D.rotation = $Sprite2D.rotation

	move_and_slide()
	
	var collision = get_last_slide_collision()
	if collision:
		var collider = collision.get_collider()
		if collider.is_in_group('enemies') and $iFrame.is_stopped():
			if current_hp <= 0:
				dead.emit()
			else:
				hit.emit()
				current_hp -= 1
				$iFrame.start()
