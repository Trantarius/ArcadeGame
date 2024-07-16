class_name Stat
extends RefCounted

var min_value:float = -INF
var max_value:float = INF

## Stat value before applying modifiers.
var base:float

enum {NONE,ROUND,FLOOR,CEIL,RANDOM,PERIODIC}
var _periodic_accum:float = 0

var round_mode:int = NONE

# format {String:float}
var pre_add_effects:Dictionary
var mul_effects:Dictionary
var add_effects:Dictionary
var post_mul_effects:Dictionary

func _init(_base:float, _min:float, _max:float, _round_mode:int=NONE)->void:
	base=_base
	min_value=_min
	max_value=_max
	round_mode=_round_mode

func get_value()->float:
	
	var val:float = base
	#val += pre_add_bonus
	#val *= mul_bonus
	#val += add_bonus
	#val *= post_mul_bonus
	
	for v:float in pre_add_effects.values():
		val += v
	for v:float in mul_effects.values():
		val *= v
	for v:float in add_effects.values():
		val += v
	for v:float in post_mul_effects.values():
		val *= v
	
	match round_mode:
		ROUND:
			val = round(val)
		FLOOR:
			val = floor(val)
		CEIL:
			val = ceil(val)
		RANDOM:
			if(randf()<fposmod(val,1)):
				val=floor(val)
			else:
				val=ceil(val)
		PERIODIC:
			_periodic_accum += fposmod(val,1)
			val = floor(val)
			if(_periodic_accum>=1):
				_periodic_accum-=1
				val+=1 
	
	val = clamp(val, min_value, max_value)
	return val

func get_explanation()->String:
	var val:float = base
	var ret:String = 'base: %.2f\n'%[base]
	
	for k:String in pre_add_effects.keys():
		val += pre_add_effects[k]
		ret += '%+.2f from %s = %.2f\n'%[pre_add_effects[k], k, val]
	for k:String in mul_effects.keys():
		val *= mul_effects[k]
		ret += '×%.2f from %s = %.2f\n'%[mul_effects[k], k, val]
	for k:String in add_effects.keys():
		val += add_effects[k]
		ret += '%+.2f from %s = %.2f\n'%[add_effects[k], k, val]
	for k:String in post_mul_effects.keys():
		val *= post_mul_effects[k]
		ret += '×%.2f from %s = %.2f\n'%[post_mul_effects[k], k, val]
	return ret
