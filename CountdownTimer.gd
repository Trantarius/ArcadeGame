## This is a timer that counts down from its current value. It uses ticks to be more accurate
## than the process delta time, which is prone to floating point error (which is noticable when 
## two timers that should match do not). It also is not a node (unlike the builtin [Timer]),
## allowing it to initialize earlier.
class_name CountdownTimer

## Halts the timer
var paused:bool = false

## Causes the timer to count upwards
var reverse:bool = false

var min_ticks:int = 1<<63:
	set(to):
		min_ticks = to
		ticks = clamp(ticks,min_ticks,max_ticks)

var max_ticks:int = (1<<63)-1:
	set(to):
		max_ticks = to
		ticks = clamp(ticks,min_ticks,max_ticks)

var min_time:float:
	set(to):
		min_ticks = (1<<63) if to==-INF else roundi(to*1_000_000)
	get:
		return -INF if min_ticks==(1<<63) else float(min_ticks)/1_000_000

var max_time:float:
	set(to):
		max_ticks = (1<<63)-1 if to==INF else roundi(to*1_000_000)
	get:
		return INF if max_ticks==(1<<63)-1 else float(max_ticks)/1_000_000

## Ticks remaining
var ticks:int:
	set(to):
		ticks = clamp(to,min_ticks,max_ticks)

## Seconds remaining
var time:float:
	set(to):
		ticks = roundi(to*1_000_000)
	get:
		return float(ticks)/1_000_000

func _init()->void:
	(Engine.get_main_loop() as SceneTree).process_frame.connect(_process)

func _process()->void:
	if(!(Engine.get_main_loop() as SceneTree).paused && !paused):
		if(reverse):
			ticks += process_tick_delta * Engine.time_scale
		else:
			ticks -= process_tick_delta * Engine.time_scale

## The tick (as reported by [method Time.get_ticks_usec]) the last process frame started.
static var last_process_tick:int
## The delta time for this process frame in usecs.
static var process_tick_delta:int
static func _static_init() -> void:
	(Engine.get_main_loop() as SceneTree).process_frame.connect(CountdownTimer._static_process)

static func _static_process()->void:
	var now:int = Time.get_ticks_usec()
	process_tick_delta = now - last_process_tick
	last_process_tick = now
