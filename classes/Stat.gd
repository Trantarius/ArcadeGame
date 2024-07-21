@tool
class_name Stat
extends Resource

@export var use_min_value:bool = false:
	set(to):
		use_min_value=to
		if(use_min_value):
			min_value=0
		else:
			min_value=-INF
		notify_property_list_changed()
		emit_changed()

@export var use_max_value:bool = false:
	set(to):
		use_max_value=to
		if(use_max_value):
			max_value=0
		else:
			max_value=INF
		notify_property_list_changed()
		emit_changed()

var min_value:float = -INF:
	set(to):
		if(use_min_value):
			min_value=to
		else:
			min_value=-INF
		_calc_value()
		emit_changed()

var max_value:float = INF:
	set(to):
		if(use_max_value):
			max_value=to
		else:
			max_value=INF
		_calc_value()
		emit_changed()

## Stat value before applying modifiers.
@export var base:float:
	set(to):
		base=to
		_calc_value()
		emit_changed()

enum {NONE=0,ROUND=1,FLOOR=2,CEIL=3,RANDOM=4}
enum{PRE_ADD=0, MUL=1, ADD=2, POST_MUL=3}

@export_enum('None:0','Round:1','Floor:2','Ceil:3','Random:4') var round_mode:int = NONE:
	set(to):
		round_mode=to
		_calc_value()
		emit_changed()

func _get_property_list() -> Array[Dictionary]:
	var ret:Array[Dictionary]
	if(use_min_value):
		ret.push_back({'name':'min_value','type':TYPE_FLOAT})
	if(use_max_value):
		ret.push_back({'name':'max_value','type':TYPE_FLOAT})
	return ret

signal value_changed

# form is {Stage:{StringName:{'strength':float,'stacks':int}}}
var _mods:Dictionary={PRE_ADD:{},MUL:{},ADD:{},POST_MUL:{}}
var _value:float = base

func add_mod(name:StringName, stage:int, strength:float, stacks:int)->void:
	if(_mods[stage].has(name)):
		assert(_mods[stage][name].strength==strength)
		_mods[stage][name].stacks += stacks
	else:
		_mods[stage][name]={&'strength':strength,&'stacks':stacks}
	_calc_value()

func remove_mod(name:StringName, stage:int, stacks:int)->void:
	if(_mods[stage].has(name)):
		_mods[stage][name].stacks -= stacks
		if(_mods[stage][name].stacks <= 0):
			_mods[stage].erase(name)
	_calc_value()

func _init(_base:float=0, _min:float=-INF, _max:float=INF, _round_mode:int=NONE)->void:
	resource_local_to_scene=true
	_calc_value()

func _calc_value()->void:
	var prev_value:float = _value
	_value=base
	
	for mod:Dictionary in _mods[PRE_ADD].values():
		_value += mod.strength * mod.stacks
	for mod:Dictionary in _mods[MUL].values():
		_value *= mod.strength ** mod.stacks
	for mod:Dictionary in _mods[ADD].values():
		_value += mod.strength * mod.stacks
	for mod:Dictionary in _mods[POST_MUL].values():
		_value *= mod.strength ** mod.stacks
	
	match round_mode:
		ROUND:
			_value = round(_value)
		FLOOR:
			_value = floor(_value)
		CEIL:
			_value = ceil(_value)
		RANDOM:
			if(randf()<fposmod(_value,1)):
				_value=floor(_value)
			else:
				_value=ceil(_value)
	
	_value = clamp(_value, min_value, max_value)
	
	if(!is_equal_approx(prev_value,_value)):
		value_changed.emit()

func get_value()->float:
	return _value

func get_explanation()->String:
	var val:float = base
	var ret:String = 'base: %.2f\n'%[base]
	
	for mname:StringName in _mods[PRE_ADD]:
		var mstrength:float = _mods[PRE_ADD][mname].strength 
		var mstacks:int = _mods[PRE_ADD][mname].stacks
		var desc:String = "%i stacks of %s"%[mstacks,mname] if mstacks>1 else mname
		val += mstrength * mstacks
		ret += '%+.2f from %s = %.2f\n'%[mstrength*mstacks, desc, val]
	for mname:StringName in _mods[MUL]:
		var mstrength:float = _mods[MUL][mname].strength 
		var mstacks:int = _mods[MUL][mname].stacks
		var desc:String = "%i stacks of %s"%[mstacks,mname] if mstacks>1 else mname
		val *= mstrength**mstacks
		ret += '×%.2f from %s = %.2f\n'%[mstrength**mstacks, desc, val]
	for mname:StringName in _mods[ADD]:
		var mstrength:float = _mods[ADD][mname].strength 
		var mstacks:int = _mods[ADD][mname].stacks
		var desc:String = "%i stacks of %s"%[mstacks,mname] if mstacks>1 else mname
		val += mstrength * mstacks
		ret += '%+.2f from %s = %.2f\n'%[mstrength*mstacks, desc, val]
	for mname:StringName in _mods[POST_MUL]:
		var mstrength:float = _mods[POST_MUL][mname].strength 
		var mstacks:int = _mods[POST_MUL][mname].stacks
		var desc:String = "%i stacks of %s"%[mstacks,mname] if mstacks>1 else mname
		val *= mstrength**mstacks
		ret += '×%.2f from %s = %.2f\n'%[mstrength**mstacks, desc, val]
	
	return ret
	
