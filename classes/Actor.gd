class_name Actor
extends Node2D

@export var max_health:Stat

var health:float:
	set(to):
		health = clamp(to,0,max_health.get_value())
		health_changed.emit(health,max_health.get_value())

## Disables death. Can still take damage, but health never goes below 0.
@export var immortal:bool = false
## Toggles whether or not queue_free should automatically be called on death.
@export var free_on_death:bool = true
## Approximate size of the actor
@export var radius:float = 32

## Forcibly disables showing a health bar.
@export var disable_health_bar:bool = false

signal death(damage:Damage)
signal kill(damage:Damage)
signal damage_taken(damage:Damage)
signal damage_dealt(damage:Damage)
signal health_changed(health:float, max_health:float)

var modifiers:Dictionary

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

const _actor_log_maxsize:int = 100
const _actor_log_duration:float = 0.25
var _actor_position_log:PackedVector2Array
var _actor_rotation_log:PackedFloat64Array
var _actor_time_log:PackedFloat64Array

## Calculates the average velocity over the time period between [param period] seconds ago and now.
func get_average_velocity(period:float = _actor_log_duration)->Vector2:
	var start:int = _actor_time_log.bsearch(Util.game_time-period)
	if(start>=_actor_position_log.size()-1):
		if(_actor_position_log.size()>=2):
			return (_actor_position_log[-1]-_actor_position_log[-2])/(_actor_time_log[-1]-_actor_time_log[-2])
		else:
			return Vector2.ZERO
	return (_actor_position_log[-1]-_actor_position_log[start])/(_actor_time_log[-1]-_actor_time_log[start])

## Calculates the average acceleration over the time period between [param period] seconds ago and now.
func get_average_acceleration(period:float = _actor_log_duration)->Vector2:
	var start:int = _actor_time_log.bsearch(Util.game_time-period)
	if(start>=_actor_position_log.size()-2):
		if(_actor_position_log.size()>=3):
			var vm2:Vector2 = (_actor_position_log[-2]-_actor_position_log[-3])/(_actor_time_log[-2]-_actor_time_log[-3])
			var tm2:float = (_actor_time_log[-2]+_actor_time_log[-3])/2
			var vm1:Vector2 = (_actor_position_log[-1]-_actor_position_log[-2])/(_actor_time_log[-1]-_actor_time_log[-2])
			var tm1:float = (_actor_time_log[-1]+_actor_time_log[-2])/2
			return (vm1-vm2)/(tm1-tm2)
		else:
			return Vector2.ZERO
	var v_o:Vector2 = (_actor_position_log[start+1]-_actor_position_log[start])/(_actor_time_log[start+1]-_actor_time_log[start])
	var t_o:float = (_actor_time_log[start+1]+_actor_time_log[start])/2
	var v_f:Vector2 = (_actor_position_log[-1]-_actor_position_log[-2])/(_actor_time_log[-1]-_actor_time_log[-2])
	var t_f:float = (_actor_time_log[-1]+_actor_time_log[-2])/2
	return (v_f-v_o)/(t_f-t_o)

## Calculates the average angular velocity over the time period between [param period] seconds ago and now.
func get_average_angular_velocity(period:float = _actor_log_duration)->float:
	var start:int = _actor_time_log.bsearch(Util.game_time-period)
	if(start>=_actor_rotation_log.size()-1):
		if(_actor_rotation_log.size()>=2):
			return angle_difference(_actor_rotation_log[-2],_actor_rotation_log[-1])/(_actor_time_log[-1]-_actor_time_log[-2])
		else:
			return 0
	return angle_difference(_actor_rotation_log[start],_actor_rotation_log[-1])/(_actor_time_log[-1]-_actor_time_log[start])

## Calculates the average angular acceleration over the time period between [param period] seconds ago and now.
func get_average_angular_acceleration(period:float = _actor_log_duration)->float:
	var start:int = _actor_time_log.bsearch(Util.game_time-period)
	if(start>=_actor_rotation_log.size()-2):
		if(_actor_rotation_log.size()>=3):
			var vm2:float = angle_difference(_actor_rotation_log[-3],_actor_rotation_log[-2])/(_actor_time_log[-2]-_actor_time_log[-3])
			var tm2:float = (_actor_time_log[-2]+_actor_time_log[-3])/2
			var vm1:float = angle_difference(_actor_rotation_log[-2],_actor_rotation_log[-1])/(_actor_time_log[-1]-_actor_time_log[-2])
			var tm1:float = (_actor_time_log[-1]+_actor_time_log[-2])/2
			return (vm1-vm2)/(tm1-tm2)
		else:
			return 0
	var v_o:float = angle_difference(_actor_rotation_log[start],_actor_rotation_log[start+1])/(_actor_time_log[start+1]-_actor_time_log[start])
	var t_o:float = (_actor_time_log[start+1]+_actor_time_log[start])/2
	var v_f:float = angle_difference(_actor_rotation_log[-2],_actor_rotation_log[-1])/(_actor_time_log[-1]-_actor_time_log[-2])
	var t_f:float = (_actor_time_log[-1]+_actor_time_log[-2])/2
	return (v_f-v_o)/(t_f-t_o)

func _init()->void:
	# using _init instead of _ready for this to prevent it from being overridden
	ready.connect(_actor_ready)
	tree_entered.connect(_actor_enter_tree)
	tree_exiting.connect(_actor_exit_tree)
	
func _actor_ready()->void:
	health = max_health.get_value()
	max_health.value_changed.connect(_actor_on_max_health_changed)
	something_spawned.emit(self)

func _actor_on_max_health_changed()->void:
	health = clamp(health, 0, max_health.get_value())

func _actor_enter_tree()->void:
	get_tree().physics_frame.connect(_actor_physics_process)

func _actor_exit_tree()->void:
	get_tree().physics_frame.disconnect(_actor_physics_process)

func _actor_physics_process()->void:
	if(!can_process()):
		return
	if(!_actor_time_log.is_empty() && is_equal_approx(Util.game_time,_actor_time_log[-1])):
		return
	_actor_position_log.push_back(global_position)
	_actor_rotation_log.push_back(global_rotation)
	_actor_time_log.push_back(Util.game_time)
	if(_actor_time_log.size()>_actor_log_maxsize):
		_actor_position_log = _actor_position_log.slice(_actor_position_log.size()-_actor_log_maxsize)
		_actor_rotation_log = _actor_rotation_log.slice(_actor_rotation_log.size()-_actor_log_maxsize)
		_actor_time_log = _actor_time_log.slice(_actor_time_log.size()-_actor_log_maxsize)
	if(Util.game_time - _actor_time_log[0] > _actor_log_duration):
		var start:int = _actor_time_log.bsearch(Util.game_time-_actor_log_duration)
		_actor_position_log = _actor_position_log.slice(start)
		_actor_rotation_log = _actor_rotation_log.slice(start)
		_actor_time_log = _actor_time_log.slice(start)

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
			var shatter:Node2D = preload('res://visual_effects/shatter.tscn').instantiate()
			get_tree().current_scene.add_child(shatter)
			shatter.adopt(self)
			shatter.shatter()
			#queue_free()
