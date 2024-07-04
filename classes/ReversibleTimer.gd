## Similar to the built-in [Timer], but allows the time to be changed while still running. Can also 
## count backwards, and activate multiple times in a single frame.
@tool
class_name ReversibleTimer
extends Node

## Starts the timer when entering the scene tree, or when calling [method reset].
@export var autostart:bool = false
## Stops the timer when it times out.
@export var one_shot:bool = false
## Makes the time count upwards instead of downwards.
@export var reverse:bool = false

## Emitted when [member time] reaches [member min_time].
signal timeout
## Emitted when [member time] reaches [member max_time].
signal timeout_reverse

var _running:bool = false
var running:bool:
	get:
		return _running
	set(to):
		if(is_inside_tree()):
			_running=to
			update()

@export var duration:float=1:
	set(to):
		_dur_ticks = roundi(to*1_000_000)
		update()
	get:
		return float(_dur_ticks)/1_000_000

## Seconds remaining
var time:float:
	set(to):
		_ticks = roundi(to*1_000_000)
		update()
	get:
		return float(_ticks)/1_000_000

var _dur_ticks:int = 1_000_000:
	set(to):
		_dur_ticks=max(1,to)
var _ticks:int
# when <0, (_running && can_process()) was false last update, and the intervening period should be ignored
var _last_update_tick:int=-1

func _enter_tree() -> void:
	reset()

func _exit_tree() -> void:
	_running=false
	update()

func reset()->void:
	# discard the last update period
	_last_update_tick=-1
	
	if(reverse):
		_ticks=0
	else:
		_ticks=_dur_ticks
	_running = autostart && is_inside_tree()
	update()

func start()->void:
	running=true

func stop()->void:
	running=false

func _process(_delta: float) -> void:
	update()

func update()->void:
	if(Engine.is_editor_hint()):
		return
	var now:int = Time.get_ticks_usec()
	if(_last_update_tick>=0):
		var delta:int = now-_last_update_tick
		if(reverse):
			_ticks+=delta*Engine.time_scale
		else:
			_ticks-=delta*Engine.time_scale
	
	if(_running && can_process()):
		_last_update_tick=now
		if(reverse):
			if(_ticks>=_dur_ticks):
				if(one_shot):
					_ticks=_dur_ticks
					_running=false
				else:
					_ticks -= _dur_ticks
				timeout_reverse.emit()
				if(!one_shot):
					# recursively update until there is no timeout
					update()
					return
		else:
			if(_ticks<=0):
				if(one_shot):
					_ticks = 0
					_running=false
				else:
					_ticks += _dur_ticks
				timeout.emit()
				if(!one_shot):
					# recursively update until there is no timeout
					update()
					return
	else:
		_ticks = clamp(_ticks, 0, _dur_ticks)
		_last_update_tick=-1

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PAUSED, NOTIFICATION_UNPAUSED, NOTIFICATION_PROCESS:
			update()

