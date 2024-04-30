class_name Actor
extends RigidBody2D

@export var max_health:float = 10
@onready var health:float = max_health

enum ControlMode{
	## Target is the desired thrust value (will be clamped to max thrust before being applied).
	THRUST,
	## Target is the desired velocity. Thrust will automatically be set to try to reach that velocity.
	VELOCITY,
	## Target is the desired position. Thrust will automatically be set to try to reach that position (and stop there, if brake is true).
	POSITION}

## Maximum self-applied force.
@export var max_linear_thrust:float = 100
## Linear velocity will be clamped if it exceeds this value.
@export var max_linear_speed:float = 400
## Determines how linear_target will be used.
@export var linear_control_mode:ControlMode = ControlMode.THRUST
## When in position mode, thrust will be reversed to try to come to rest at the target position. Has no effect when linear_control_mode != POSITION.
@export var linear_brake:bool = true
## See [member Actor.linear_control_mode]
var linear_target:Vector2

## Maximum self-applied torque.
@export var max_angular_thrust:float = 100
## Angular velocity will be clamped if it exceeds this value.
@export var max_angular_speed:float = 3
## Determines how angular_target will be used.
@export var angular_control_mode:ControlMode = ControlMode.THRUST
## When in position mode, thrust will be reversed to try to come to rest at the target position. Has no effect when angular_control_mode != POSITION.
@export var angular_brake:bool = true
## See [member Actor.angular_control_mode]
var angular_target:float

signal death(damage:Damage)
signal kill(damage:Damage)
signal damage_taken(damage:Damage)
signal damage_dealt(damage:Damage)

func _init()->void:
	contact_monitor=true
	max_contacts_reported=2

func take_damage(damage:Damage)->void:
	damage.target=self
	if(health<=0):
		return # omae wa mo shindeiru
	health -= damage.amount
	damage_taken.emit(damage)
	if(is_instance_valid(damage.attacker)):
		damage.attacker.damage_dealt.emit(damage)
	if(health<=0):
		death.emit(damage)
		if(is_instance_valid(damage.attacker)):
			damage.attacker.kill.emit(damage)
		queue_free()

func predict_position(delta:float)->Vector2:
	return position + linear_velocity*delta + (constant_force/mass)*delta*delta/2

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	
	match(linear_control_mode):
		ControlMode.THRUST:
			state.set_constant_force(linear_target.limit_length(max_linear_thrust))
		
		ControlMode.VELOCITY:
			var thrust:Vector2 = (linear_target.limit_length(max_linear_speed)-state.linear_velocity).normalized()*max_linear_thrust
			state.set_constant_force(thrust)
		
		ControlMode.POSITION:
			if(linear_brake):
				
				var accel:float = max_linear_thrust*state.inverse_mass
				var brake_time:float = state.linear_velocity.length() / accel
				var anticipated_position:Vector2 = position + state.linear_velocity*brake_time/2
				var correction_dir:Vector2 = (linear_target-anticipated_position).normalized()
				var thrust:Vector2 = (correction_dir-state.linear_velocity.normalized()/2).normalized()*max_linear_thrust
				state.set_constant_force(thrust)
			else:
				
				var xlen:float = (linear_target-position).length()
				if(xlen>0.01):
					var xdir:Vector2 = (linear_target-position)/xlen
					var accel:float = max_linear_thrust*state.inverse_mass
					
					# 0 = (1/2) a t^2 + vi t + -d
					# (-b + sqrt(b*b - 4*a*c))/(2*a)
					var vi:float = state.linear_velocity.dot(xdir)
					var xtime:float = (sqrt(vi*vi + 2*accel*xlen)-vi)/accel
					
					var ytime:float = abs(state.linear_velocity.dot(xdir.orthogonal()))*2/accel
					var tdir:Vector2 = xtime*xdir - ytime*sign(state.linear_velocity.dot(xdir.orthogonal()))*xdir.orthogonal()
					var thrust:Vector2 = tdir.normalized()*max_linear_thrust
					state.set_constant_force(thrust)
	
	match(angular_control_mode):
		ControlMode.THRUST:
			state.set_constant_torque(clamp(angular_target,-max_angular_thrust,max_angular_thrust))
		
		ControlMode.VELOCITY:
			var thrust:float = sign(clamp(angular_target,-max_angular_speed,max_angular_speed)-state.angular_velocity)*max_angular_thrust
			state.set_constant_torque(thrust)
		
		ControlMode.POSITION:
			if(angular_brake):
				var accel:float = max_angular_thrust*state.inverse_inertia
				var brake_time:float = abs(state.angular_velocity) / accel
				var anticipated_position:float = rotation + state.angular_velocity*brake_time/2 
				var thrust:float = sign(angle_difference(anticipated_position,angular_target))*max_angular_thrust
				state.set_constant_torque(thrust)
			else:
				state.set_constant_torque(-max_angular_thrust*sign(angle_difference(angular_target,rotation)))
	
	state.linear_velocity = state.linear_velocity.limit_length(max_linear_speed)
	state.angular_velocity = clamp(state.angular_velocity,-max_angular_speed,max_angular_speed)
