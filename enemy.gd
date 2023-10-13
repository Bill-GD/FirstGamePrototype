extends CharacterBody2D

var base_speed: int = 100

@export var player: Node2D
@onready var nav_agent := $NavigationAgent2D as NavigationAgent2D
var direction: Vector2

signal hit

func _ready():
	base_speed = 100 + (get_parent().score / 2)
	update_path()

func _physics_process(delta: float) -> void:
#	$Direction.queue_redraw()
#	direction = (get_parent().get_node('Player').position - global_position).normalized()
	direction = (nav_agent.get_next_path_position() - position).normalized()
	velocity = direction * base_speed
	rotation = direction.angle()
	
	var collision = move_and_collide(velocity * delta)

	if collision:
		var collider = collision.get_collider() as Node2D
#		if collider.is_in_group('walls'):
#			direction = to_local(nav_agent.get_next_path_position()).normalized()
		if collider.is_in_group('bullets') and $iFrame.is_stopped():
#			print('enemy hit bullet')
			hit.emit()
			queue_free()
			collider.queue_free()
		else:
			move_and_collide(velocity * Vector2.DOWN * delta)
			move_and_collide(velocity * Vector2.RIGHT * delta)
			
func update_path():
	nav_agent.target_position = player.position
	
#	print('next pos: %s' % nav_agent.get_next_path_position())
#	print('distance: %s' % nav_agent.distance_to_target())
#	print('current pos: %s' % position)
#	print('target pos: %s' % nav_agent.target_position)
#	print('player pos: %s' % player.position)
#	print('velocity: %s' % velocity)
#	print('direction: %s\n\n' % direction)

func _on_new_path_timer_timeout():
	update_path()
