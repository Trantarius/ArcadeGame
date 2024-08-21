@tool
class_name Stat
extends Resource

@export var use_min_value:bool = false:
	set(to):
		use_min_value=to
		if(use_min_value&&Engine.is_editor_hint()):
			min_value=0
		elif(!use_min_value):
			min_value=-INF
		notify_property_list_changed()
		emit_changed()

@export var use_max_value:bool = false:
	set(to):
		use_max_value=to
		if(use_max_value&&Engine.is_editor_hint()):
			max_value=0
		elif(!use_max_value):
			max_value=INF
		notify_property_list_changed()
		emit_changed()

var min_value:float = -INF:
	set(to):
		if(use_min_value||!Engine.is_editor_hint()):
			min_value=to
		else:
			min_value=-INF
		_calc_value()
		emit_changed()

var max_value:float = INF:
	set(to):
		if(use_max_value||!Engine.is_editor_hint()):
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
	var ret:Array[Dictionary] = []
	if(use_min_value):
		ret.push_back({'name':'min_value','type':TYPE_FLOAT})
	if(use_max_value):
		ret.push_back({'name':'max_value','type':TYPE_FLOAT})
	return ret

signal value_changed

# form is {Stage:{StatBuff:stacks}}
var _buffs:Dictionary={PRE_ADD:{},MUL:{},ADD:{},POST_MUL:{}}
var _value:float = base

func add_buff(buff:StatBuff)->void:
	if(_buffs[buff.stage].has(buff)):
		_buffs[buff.stage][buff]+=1
	else:
		_buffs[buff.stage][buff]=1
	_calc_value()

func remove_buff(buff:StatBuff)->void:
	if(_buffs[buff.stage].has(buff)):
		_buffs[buff.stage][buff]-=1
		if(_buffs[buff.stage][buff]<=0):
			_buffs[buff.stage].erase(buff)
		_calc_value()

func _init(_base:float=0, _min:float=-INF, _max:float=INF, _round_mode:int=NONE)->void:
	resource_local_to_scene=true
	_calc_value()

func _calc_value()->void:
	var prev_value:float = _value
	_value=base
	
	for buff:StatBuff in _buffs[PRE_ADD]:
		_value += buff.strength * _buffs[PRE_ADD][buff]
	for buff:StatBuff in _buffs[MUL]:
		_value *= buff.strength ** _buffs[MUL][buff]
	for buff:StatBuff in _buffs[ADD]:
		_value += buff.strength * _buffs[ADD][buff]
	for buff:StatBuff in _buffs[POST_MUL]:
		_value *= buff.strength ** _buffs[POST_MUL][buff]
	
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
	
	for buff:StatBuff in _buffs[PRE_ADD]:
		var stacks:int = _buffs[PRE_ADD][buff]
		var desc:String = "%d stacks of %s"%[stacks,buff.name] if stacks>1 else buff.name
		val += buff.strength * stacks
		ret += '%+.2f from %s = %.2f\n'%[buff.strength*stacks, desc, val]
	for buff:StatBuff in _buffs[MUL]:
		var stacks:int = _buffs[MUL][buff]
		var desc:String = "%d stacks of %s"%[stacks,buff.name] if stacks>1 else buff.name
		val *= buff.strength**stacks
		ret += '×%.2f from %s = %.2f\n'%[buff.strength**stacks, desc, val]
	for buff:StatBuff in _buffs[ADD]:
		var stacks:int = _buffs[ADD][buff]
		var desc:String = "%d stacks of %s"%[stacks,buff.name] if stacks>1 else buff.name
		val += buff.strength * stacks
		ret += '%+.2f from %s = %.2f\n'%[buff.strength*stacks, desc, val]
	for buff:StatBuff in _buffs[POST_MUL]:
		var stacks:int = _buffs[POST_MUL][buff]
		var desc:String = "%d stacks of %s"%[stacks,buff.name] if stacks>1 else buff.name
		val *= buff.strength**stacks
		ret += '×%.2f from %s = %.2f\n'%[buff.strength**stacks, desc, val]
	
	return ret
	
