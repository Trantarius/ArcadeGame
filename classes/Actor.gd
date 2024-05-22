class_name Actor
extends Node2D

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

var _actor_log_maxsize:int = 100
const _actor_log_duration:float = 0.25
var _actor_position_log:PackedVector2Array
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


func _init()->void:
	# using _init instead of _ready for this to prevent it from being overridden
	ready.connect(_actor_ready)
	tree_entered.connect(_actor_enter_tree)
	tree_exiting.connect(_actor_exit_tree)
	
func _actor_ready()->void:
	health = max_health
	something_spawned.emit(self)

func _actor_enter_tree()->void:
	get_tree().physics_frame.connect(_actor_physics_process)

func _actor_exit_tree()->void:
	get_tree().physics_frame.disconnect(_actor_physics_process)

func _actor_physics_process()->void:
	if(!can_process()):
		return
	_actor_position_log.push_back(global_position)
	_actor_time_log.push_back(Util.game_time)
	if(_actor_time_log.size()>_actor_log_maxsize):
		_actor_position_log = _actor_position_log.slice(_actor_position_log.size()-_actor_log_maxsize)
		_actor_time_log = _actor_time_log.slice(_actor_time_log.size()-_actor_log_maxsize)
	if(Util.game_time - _actor_time_log[0] > _actor_log_duration):
		var start:int = _actor_time_log.bsearch(Util.game_time-_actor_log_duration)
		_actor_position_log = _actor_position_log.slice(start)
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
