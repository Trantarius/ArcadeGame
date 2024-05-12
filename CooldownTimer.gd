class_name CooldownTimer

var ticks:int:
	set(to):
		ticks = Time.get_ticks_usec() + to
	get:
		return ticks - Time.get_ticks_usec()

var time:float:
	set(to):
		ticks = roundi(to*1_000_000)
	get:
		return float(ticks)/1_000_000
