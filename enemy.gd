extends CharacterBody2D

var base_speed: int = 100

signal hit

func _ready():
	base_speed = 100 + (get_parent().score / 2)
	pass

func _physics_process(delta):
	var direction: Vector2 = (get_parent().get_node('Player').position - position).normalized()

	velocity = direction * base_speed
	rotation = direction.angle() + (PI / 2)
#	$Sprite2D.rotation = direction.angle() + (PI / 2)
#	$CollisionShape2D.rotation = $Sprite2D.rotation
	
	var collision = move_and_collide(velocity * delta)

	if collision:
		var collider = collision.get_collider() as Node2D
		if collider.is_in_group('bullets') and $iFrame.is_stopped():
			print('enemy hit bullet')
			hit.emit()
			queue_free()
#			get_node(collider.get_path()).queue_free()
			collider.queue_free()
		else:
			move_and_collide(velocity * Vector2.DOWN * delta)
			move_and_collide(velocity * Vector2.RIGHT * delta)
#			get_parent().get_node('Bullet').queue_free()
#			$iFrame.start()
