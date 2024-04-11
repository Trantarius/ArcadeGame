class_name Actor
extends CharacterBody2D

@export var max_health:float = 10
## (Maximum) Linear acceleration
@export var acceleration:float = 30
## (Maximum) Linear speed
@export var max_speed:float = 300
## (Maximum) Angular speed
@export var rotation_speed:float = 3
## Portion of linear velocity decayed per second
@export var velocity_damp:float = 0

@onready var health:float = max_health

signal death
signal damage_taken(damage:Damage)
signal damage_dealt(damage:Damage)

# position the previous frame, used for correcting velocity
var _last_frame_position:Vector2

func _enter_tree() -> void:
	_last_frame_position=position

func take_damage(damage:Damage)->void:
	damage.target=self
	if(health<=0):
		return # omae wa mo shindeiru
	health -= damage.amount
	damage_taken.emit(damage)
	if(damage.source is Actor):
		damage.source.damage_dealt.emit(damage)
	elif(damage.source is Projectile):
		damage.source.source.damage_dealt.emit(damage)
	if(health<=0):
		death.emit()
		queue_free()

# NB: MUST be called by subclass if the subclass implements _physics_process
func _physics_process(delta: float) -> void:
	
	velocity *= 1 - velocity_damp * delta
	if(velocity.length() > max_speed):
		velocity = velocity.normalized() * max_speed

	move_and_slide()
	
	var actual_motion:Vector2 = (position-_last_frame_position)
	var am_lsqr:float = actual_motion.length_squared()
	if(am_lsqr>0.0001):
		# project the velocity onto the actual movement direction
		velocity = actual_motion * max(0,velocity.dot(actual_motion)) / am_lsqr
	_last_frame_position=position
