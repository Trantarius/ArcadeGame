@tool
class_name SoundStack
extends Node

var length:float = 1:
	get:
		if(get_parent() is SoundStack):
			return get_parent().length
		else:
			return length
var loop:bool = false:
	get:
		if(get_parent() is SoundStack):
			return get_parent().loop
		else:
			return loop
var mix_rate:int = 44100:
	get:
		if(get_parent() is SoundStack):
			return get_parent().mix_rate
		else:
			return mix_rate
var amplitude:float = 1:
	get:
		if(get_parent() is SoundStack):
			return get_parent().amplitude
		else:
			return amplitude

var data:PackedFloat64Array

func _get_property_list() -> Array[Dictionary]:
	return [
		{
			'name':'length',
			'type':TYPE_FLOAT,
			'hint':PROPERTY_HINT_RANGE,
			'hint_string':'0,10,or_greater',
			'usage': PROPERTY_USAGE_DEFAULT | (PROPERTY_USAGE_READ_ONLY if get_parent() is SoundStack else 0)
		},
		{
			'name':'loop',
			'type':TYPE_BOOL,
			'usage':PROPERTY_USAGE_DEFAULT | (PROPERTY_USAGE_READ_ONLY if get_parent() is SoundStack else 0)
		},
		{
			'name':'mix_rate',
			'type':TYPE_INT,
			'usage':PROPERTY_USAGE_DEFAULT | (PROPERTY_USAGE_READ_ONLY if get_parent() is SoundStack else 0)
		},
		{
			'name':'amplitude',
			'type':TYPE_FLOAT,
			'hint':PROPERTY_HINT_RANGE,
			'hint_string':'0,1',
			'usage':PROPERTY_USAGE_DEFAULT | (PROPERTY_USAGE_READ_ONLY if get_parent() is SoundStack else 0)
		}
	]

func begin()->void:
	
	data.resize(roundi(length*mix_rate))
	data.fill(0)
	
	_begin()
	
	for child:Node in get_children():
		if(child is SoundStack || child is SoundMod):
			child.begin()

func _begin()->void:
	pass

func sample(time:float, idx:int)->void:
	_sample(time, idx)
	for child:Node in get_children():
		if(child is SoundStack || child is SoundMod):
			child.sample(time, idx)
		if(child is SoundStack):
			data[idx] += child.data[idx]

func _sample(time:float, idx:int)->void:
	pass

func finish()->void:
	for child:Node in get_children():
		if(child is SoundStack || child is SoundMod):
			child.finish()
	_finish()

func _finish()->void:
	pass

func make_sound()->void:
	begin()
	var time:float = 0
	for n:int in range(data.size()):
		sample(time, n)
		time += 1.0/mix_rate
	finish()

func make_wav()->AudioStreamWAV:
	
	var pcm:PackedByteArray
	pcm.resize(data.size()*2)
	
	for n:int in range(data.size()):
		pcm.encode_s16(n*2, clamp(data[n]*0x7fff,-0x7fff,0x7fff))
	
	var wav:AudioStreamWAV = AudioStreamWAV.new()
	wav.data = pcm
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	if(loop):
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = data.size()
		wav.mix_rate = mix_rate
	return wav
