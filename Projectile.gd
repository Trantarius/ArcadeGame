class_name Projectile
extends PhysicsBody2D

## Time left until deletion
@export var lifetime:float = 10
@export var damage_amount:float = 1
var source:Actor
var velocity:Vector2

signal hit(collision:KinematicCollision2D)

func _physics_process(delta: float) -> void:
		
	lifetime-=delta
	if(lifetime<0):
		queue_free()
	
	var collision:KinematicCollision2D = move_and_collide(velocity*delta)
	if(collision!=null):
		if(collision.get_collider() is Actor):
			var damage:Damage = Damage.new()
			damage.amount=damage_amount
			damage.source=self
			damage.position = collision.get_position()
			damage.direction = velocity.normalized()
			collision.get_collider().take_damage(damage)
		hit.emit(collision)
		queue_free()
