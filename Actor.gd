class_name Actor
extends RigidBody2D

@export var max_health:float = 10:
	set(to):
		set_block_signals(true)
		if(is_inside_tree()):
			health = to * health/max_health
		else:
			health = max_health
		max_health = to
		set_block_signals(false)
		health_changed.emit(health,max_health)

var health:float = max_health:
	set(to):
		health = clamp(to,0,max_health)
		health_changed.emit(health,max_health)

## Disables death. Can still take damage, but health never goes below 0.
@export var immortal:bool = false
## Toggles whether or not queue_free should automatically be called on death.
@export var free_on_death:bool = true
## Approximate size of the actor
@export var radius:float = 32

enum ControlMode{
	## Target is the desired thrust value (will be clamped to max thrust before being applied).
	THRUST,
	## Target is the desired acceleration. Thrust will automatically be set to try to reach that acceleration.
	ACCELERATION,
	## Target is the desired velocity. Thrust will automatically be set to try to reach that velocity.
	VELOCITY,
	## Target is the desired position. Thrust will automatically be set to try to reach that position (and stop there, if brake is true).
	POSITION}

## Maximum self-applied force.
@export var max_linear_thrust:float = 128
## Linear velocity will be clamped if it exceeds this value.
@export var max_linear_speed:float = 1024
## Determines how linear_target will be used.
@export var linear_control_mode:ControlMode = ControlMode.THRUST
## When in position mode, controls how much thrust will be reversed to try to come to rest at the target position.
@export var linear_brake:float = 1
## See [member Actor.linear_control_mode]
var linear_target:Vector2

## Performs linear calculations in a reference frame defined by this position.
var reference_position:Vector2
## Performs linear calculations in a reference frame defined by this velocity.
var reference_velocity:Vector2
## Performs linear calculations in a reference frame defined by this acceleration.
var reference_acceleration:Vector2

## Maximum self-applied torque.
@export var max_angular_thrust:float = 128
## Angular velocity will be clamped if it exceeds this value.
@export var max_angular_speed:float = 4
## Determines how angular_target will be used.
@export var angular_control_mode:ControlMode = ControlMode.THRUST
## When in position mode, controls how much thrust will be reversed to try to come to rest at the target position.
@export var angular_brake:float = 1
## See [member Actor.angular_control_mode]
var angular_target:float

## Linear thrust applied last physics frame.
var linear_thrust:Vector2
## Linear acceleration applied last physics frame (excluding collisions).
var linear_acceleration:Vector2
## Angular thrust applied last physics frame.
var angular_thrust:float
## Angular acceleration applied last physics frame (excluding collisions).
var angular_acceleration:float

## Map of StringName:Modifier
var modifiers:Dictionary

signal death(damage:Damage)
signal kill(damage:Damage)
signal damage_taken(damage:Damage)
signal damage_dealt(damage:Damage)
signal health_changed(health:float, max_health:float)

signal mod_added(mod:Modifier)
signal mod_removed(mod:Modifier)

static var something_spawned:Signal
static var something_died:Signal
static var something_took_damage:Signal
static func _static_init()->void:
	(Actor as Object).add_user_signal('something_spawned',[{'name':'thing','type':TYPE_OBJECT}])
	something_spawned = Signal(Actor,'something_spawned')
	(Actor as Object).add_user_signal('something_died',[{'name':'damage','type':TYPE_OBJECT}])
	something_died = Signal(Actor,'something_died')
	(Actor as Object).add_user_signal('something_took_damage',[{'name':'damage','type':TYPE_OBJECT}])
	something_took_damage = Signal(Actor,'something_took_damage')

func _init()->void:
	custom_integrator=true
	contact_monitor=true
	max_contacts_reported=3
	# using _init instead of _ready for this to prevent it from being overridden
	ready.connect(_actor_ready)
	
func _actor_ready()->void:
	something_spawned.emit(self)
	health = max_health

func take_damage(damage:Damage)->void:
	damage.target=self
	if(health<=0):
		return # omae wa mo shindeiru
	if(is_instance_valid(damage.attacker)):
		damage.attacker.damage_dealt.emit(damage)
	damage_taken.emit(damage)
	something_took_damage.emit(damage)
	health -= damage.amount
	if(immortal):
		health = max(health,0)
	elif(health<=0):
		if(is_instance_valid(damage.attacker)):
			damage.attacker.kill.emit(damage)
		death.emit(damage)
		something_died.emit(damage)
		if(free_on_death):
			queue_free()

func add_modifier(mod:Modifier)->void:
	if(modifiers.has(mod.mod_name)):
		remove_modifier(mod.mod_name)
	modifiers[mod.mod_name]=mod
	add_child(mod)
	mod_added.emit(mod)

func remove_modifier(mod_name:StringName)->void:
	if(modifiers.has(mod_name)):
		var oldmod:Modifier = modifiers[mod_name]
		remove_child(oldmod)
		modifiers.erase(mod_name)
		mod_removed.emit(oldmod)
		oldmod.queue_free()


var _actor_warp_queue:Array[Dictionary]

## Warps the actor in a direction defined by motion. It will be stopped early by anything in the way.
func slide_warp(motion:Vector2)->void:
	_actor_warp_queue.push_back({&'type':&'slide',&'motion':motion})

## Warps the actor in a direction defined by motion. It will be cancelled if there is anything at the destination.
func jump_warp(motion:Vector2)->void:
	_actor_warp_queue.push_back({&'type':&'jump',&'motion':motion})

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	
	for warp:Dictionary in _actor_warp_queue:
		if(warp.type==&'slide'):
			move_and_collide(warp.motion)
		else:
			var dest:Transform2D = global_transform.translated(warp.motion)
			if(!test_move(dest,Vector2.ZERO)):
				state.transform = dest
	_actor_warp_queue.clear()
	
	var current_position:Vector2 = state.transform.origin - reference_position
	var current_velocity:Vector2 = state.linear_velocity - reference_velocity
	var current_acceleration:Vector2 = state.get_constant_force()*state.inverse_mass - reference_acceleration
	
	var solve_accel:Callable = func solve_accel(wdir:Vector2)->Dictionary:
		var cw:float = current_acceleration.dot(wdir)
		var perp:Vector2 = current_acceleration - cw*wdir
		var t_maxacc:float = max_linear_thrust*state.inverse_mass
		var ret:Dictionary = {}
		if(t_maxacc**2<perp.length_squared()):
			ret[&'success']=false
			# thrust won't be able to overcome current acc, just get as close as possible
			if(current_acceleration.dot(wdir)>0):
				ret[&'thrust'] = max_linear_thrust*-perp.normalized()
			else:
				ret[&'thrust'] = max_linear_thrust*-current_acceleration.normalized()
		else:
			ret[&'success'] = true
			ret[&'final_acc'] = sqrt(t_maxacc**2 - perp.length_squared())+abs(cw)
			var t_acc:Vector2 = wdir*(ret.final_acc)-current_acceleration
			ret[&'thrust'] = t_acc/state.inverse_mass
		return ret
	
	match(linear_control_mode):
		ControlMode.THRUST:
			linear_thrust = linear_target
		
		ControlMode.ACCELERATION:
			linear_thrust = (linear_target - current_acceleration)/state.inverse_mass
		
		ControlMode.VELOCITY:
			linear_thrust = solve_accel.call((linear_target-current_velocity).normalized()).thrust
			linear_thrust = linear_thrust.limit_length((linear_target-current_velocity).length()/state.step/state.inverse_mass)
		
		ControlMode.POSITION:
				
			var brake:Dictionary = solve_accel.call(-current_velocity.normalized())
			if(!brake.success):
				# braking is impossible
				linear_thrust = brake.thrust
			else:
				var brake_acc:float = brake.final_acc
				var brake_time:float = linear_brake*current_velocity.length()/brake_acc
				var anticipated_position:Vector2 = current_position + current_velocity*brake_time
				var correction_dir:Vector2 = (linear_target-anticipated_position).normalized()
				
				linear_thrust = solve_accel.call((correction_dir-current_velocity.normalized()/2).normalized()).thrust
				
	
	var current_angular_acceleration:float = state.get_constant_torque()*state.inverse_inertia
	
	match(angular_control_mode):
		ControlMode.THRUST:
			angular_thrust = angular_target
		
		ControlMode.ACCELERATION:
			angular_thrust = (angular_target-current_angular_acceleration)/state.inverse_inertia
		
		ControlMode.VELOCITY:
			angular_thrust = (angular_target-state.angular_velocity)/state.step/state.inverse_inertia
		
		ControlMode.POSITION:
			var accel:float = max_angular_thrust*state.inverse_inertia + current_angular_acceleration*-sign(state.angular_velocity)
			var brake_time:float = angular_brake*abs(state.angular_velocity) / accel
			var anticipated_position:float = rotation + state.angular_velocity*brake_time
			angular_thrust = sign(-angle_difference(angular_target,anticipated_position))*max_angular_thrust
	
	linear_thrust = linear_thrust.limit_length(max_linear_thrust)
	var linear_force:Vector2 = linear_thrust + state.get_constant_force()
	state.set_constant_force(Vector2.ZERO)
	linear_acceleration = linear_force * state.inverse_mass
	
	linear_acceleration += state.linear_velocity
	linear_acceleration = linear_acceleration.limit_length(max_linear_speed)
	linear_acceleration -= state.linear_velocity
	
	state.linear_velocity += linear_acceleration * state.step
	
	angular_thrust = clamp(angular_thrust, -max_angular_thrust, max_angular_thrust)
	var angular_force:float = angular_thrust + state.get_constant_torque()
	state.set_constant_torque(0)
	angular_acceleration = angular_force * state.inverse_inertia
	
	angular_acceleration += state.angular_velocity
	angular_acceleration = clamp(angular_acceleration,-max_angular_speed,max_angular_speed)
	angular_acceleration -= state.angular_velocity
	
	state.angular_velocity += angular_acceleration * state.step
