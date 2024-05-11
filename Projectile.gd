class_name Projectile
extends AnimatableBody2D

## Time left until deletion
@export var lifetime:float = 10

@export_group('Damage','damage_')
@export var damage_amount:float = 1
@export var damage_silent:bool = false

enum{
	VELOCITY,
	NORMAL
}

@export_enum("Velocity:0","Normal") var damage_direction:int

var source:Actor
var linear_velocity:Vector2:
	set(to):
		constant_linear_velocity=to
	get:
		return constant_linear_velocity
var angular_velocity:float:
	set(to):
		constant_angular_velocity=to
	get:
		return constant_angular_velocity

signal hit(collision:KinematicCollision2D)
signal damage_dealt(damage:Damage)

func _physics_process(delta: float) -> void:
		
	lifetime-=delta
	if(lifetime<0):
		queue_free()
	
	var collision:KinematicCollision2D = move_and_collide(linear_velocity*delta)
	if(collision!=null):
		if(collision.get_collider() is Actor):
			var damage:Damage = Damage.new()
			damage.amount = damage_amount
			damage.source = self
			damage.attacker = source
			damage.target = collision.get_collider()
			damage.position = collision.get_position()
			damage.direction = linear_velocity.normalized()
			damage.velocity = (damage.target.linear_velocity + linear_velocity)/2
			damage_dealt.emit(damage)
			damage.target.take_damage(damage)
		hit.emit(collision)
		queue_free()
