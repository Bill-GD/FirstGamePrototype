extends RigidBody2D

var move_direction: Vector2 = Vector2.ZERO
const SPEED: float = 800.0

func _ready():
	gravity_scale = 0
#	move_direction = (get_global_mouse_position() - position).normalized()
	$CollisionShape2D.rotation = move_direction.angle()
	$Sprite2D.rotation = $CollisionShape2D.rotation
	linear_velocity = move_direction * SPEED

func _on_body_entered(_body):
	var colliding_bodies = get_colliding_bodies()
	for collided_body in colliding_bodies:
		if collided_body.is_in_group('walls') or collided_body.is_in_group('wooden_boxes'):
			queue_free()
			break
