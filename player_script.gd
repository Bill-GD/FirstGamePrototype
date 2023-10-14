extends CharacterBody2D

const BASE_SPEED: int = 150
const BASE_HP: int = 20
const BASE_ARMOR: int = 10
const SPRINT_SPEED: float = BASE_SPEED * 2

var can_speed_up: bool = true
var current_hp: int = BASE_HP
var current_armor: int = BASE_ARMOR

signal hit
signal dead

func _physics_process(_delta):
	var direction: Vector2 = Input.get_vector('aswd_left', 'aswd_right', 'aswd_up', 'aswd_down')
	can_speed_up = not (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_SPACE))
	
	velocity = direction * (SPRINT_SPEED if Input.is_action_pressed('ui_shift') and can_speed_up else BASE_SPEED)
	$Sprite2D.rotation = (get_global_mouse_position() - position).angle()
	$CollisionPolygon2D.rotation = $Sprite2D.rotation
	$LightOccluder2D.rotation = $Sprite2D.rotation

	move_and_slide()
	
	if current_armor < BASE_ARMOR and $ArmorRegenDelay.is_stopped() and $ArmorRegen.is_stopped():
		$ArmorRegen.start()
	
	var collision = get_last_slide_collision()
	if collision:
		var collider = collision.get_collider()
		if collider.is_in_group('enemies') and $iFrame.is_stopped():
			if current_hp <= 0:
				dead.emit()
			else:
				hit.emit()
				if current_armor > 0: current_armor -= 1
				else: current_hp -= 1
				$iFrame.start()
				$ArmorRegen.stop()
				$ArmorRegenDelay.start()

func _on_armor_regen_timeout():
	current_armor += 1
	if current_armor == BASE_ARMOR: $ArmorRegen.stop()
