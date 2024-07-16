## Similar to the built-in [Timer], but allows the time to be changed while still running. Can also 
## count backwards, and activate multiple times in a single frame.
@tool
class_name ReversibleTimer
extends Node

## Automatically restarts the timer when complete. Also allows multiple activations per update.
@export var loop:bool = false

## Makes the time count upwards instead of downwards.
@export var reverse:bool = false

## Scales time like Engine.time_scale, but only for this timer.
@export var time_scale:float = 1.0:
	set(to):
		time_scale = max(0,to)

## Indicates the timer is enabled. The timer will only run when it is in the scene tree.
@export var running:bool = false

## Maximum value of [member time].
@export var duration:float=1:
	set(to):
		_dur_ticks = max(1,roundi(to*1_000_000))
		_ticks = clamp(_ticks, 0, _dur_ticks)
	get:
		return float(_dur_ticks)/1_000_000

enum{NONE=0, PROCESS=1, PHYSICS=2}
## Automaticall calls [method update] with a callback. If set to 'None', [method update] will have to be called manually.
@export_enum('None:0','Process:1','Physics:2') var auto_update:int = 1:
	set(to):
		set_process(to==PROCESS)
		set_physics_process(to==PHYSICS)
		auto_update=to

## Emitted when [member time] reaches 0, or when it reaches [member duration] when [member reverse] is true.
signal timeout
## Like [signal timeout], but includes how long ago the activation took place for more precision.
signal timeout_precise(ago:float)

## Seconds remaining.
var time:float:
	set(to):
		_ticks = clamp(roundi(to*1_000_000), 0, _dur_ticks)
	get:
		return float(_ticks)/1_000_000

var _dur_ticks:int = 1_000_000
var _ticks:int
var _last_update_tick:int = -1
var _doing_timeout:bool = false

func reset()->void:
	if(reverse):
		_ticks = 0
	else:
		_ticks = _dur_ticks

func start()->void:
	running=true

func stop()->void:
	running=false

func is_finished()->bool:
	return reverse && _ticks==_dur_ticks || !reverse && _ticks==0

func update()->void:
	var now:int = Time.get_ticks_usec()
	var elapsed:int = roundi(Engine.time_scale*time_scale*(now - _last_update_tick))
	if(_last_update_tick<0):
		elapsed = 0
	_last_update_tick = now
	
	var check_once:bool = true
	while((elapsed>0 || check_once) && running):
		check_once=false
		
		if(reverse):
			if(_dur_ticks-_ticks<=elapsed):
				elapsed -= _dur_ticks-_ticks
				_ticks = _dur_ticks
				timeout_precise.emit(float(elapsed)/1_000_000)
				timeout.emit()
				
				# redo checks in case a listener modified the timer
				if(_ticks==_dur_ticks && reverse && running):
					if(loop):
						_ticks = 0
					else:
						running = false
			else:
				_ticks += elapsed
				elapsed = 0
		
		else:
			if(_ticks<=elapsed):
				elapsed -= _ticks
				_ticks = 0
				timeout_precise.emit(float(elapsed)/1_000_000)
				timeout.emit()
				
				# redo checks in case a listener modified the timer
				if(_ticks==0 && !reverse && running):
					if(loop):
						_ticks = _dur_ticks
					else:
						running = false
			else:
				_ticks -= elapsed
				elapsed = 0

func _notification(what: int) -> void:
	if(Engine.is_editor_hint()):
		return
	match what:
		NOTIFICATION_READY:
			set_process(auto_update==PROCESS)
			set_physics_process(auto_update==PHYSICS)
			reset()
		NOTIFICATION_EXIT_TREE, NOTIFICATION_PAUSED:
			_last_update_tick = -1
		NOTIFICATION_PROCESS, NOTIFICATION_PHYSICS_PROCESS:
			update()

