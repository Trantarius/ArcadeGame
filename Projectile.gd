class_name Projectile
extends AnimatableBody2D

## How long after firing the projectile is destroyed
@export var lifetime:float = 10
var lifetime_timer:CountdownTimer = CountdownTimer.new()

@export_group('Damage','damage_')
@export var damage_amount:float = 1
@export var damage_silent:bool = false

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

func _ready()->void:
	lifetime_timer.time = lifetime

func _physics_process(delta: float) -> void:
	
	modulate.a = clamp(lifetime_timer.time,0,1)
	if(lifetime_timer.time <= 0):
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
			damage.direction = (linear_velocity - collision.get_collider_velocity()).normalized()
			damage.silent = damage_silent
			damage_dealt.emit(damage)
			damage.target.take_damage(damage)
		hit.emit(collision)
		queue_free()
