@tool
class_name Tone
extends SoundStack

enum Waveform{ SINE, SQUARE, SAW, SAW_REV }
@export var waveform:Waveform
var frequency:float

func _get_property_list() -> Array:
	return [
		{'name':'frequency',
		'type':TYPE_FLOAT,
		'hint':PROPERTY_HINT_RANGE,
		'hint_string':'50,10000,exp'}
	]

var period:float

func _begin()->void:
	period = 1.0/frequency
	if(loop):
		var count:int = roundi(length/period)
		period = length/count

func _sample(time:float, idx:int)->void:
	var dt:float = fposmod(time, period)
	match waveform:
		Waveform.SINE:
			data[idx] = sin(dt*TAU/period)*amplitude
		Waveform.SQUARE:
			data[idx] = amplitude if dt > period/2 else -amplitude
		Waveform.SAW:
			data[idx] = amplitude * (2 * dt/period - 1)
		Waveform.SAW_REV:
			data[idx] = amplitude * (1 - (2 * dt/period -1))
