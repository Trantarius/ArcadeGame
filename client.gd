extends WebSocketConnection

var host:String = '72.73.27.191:13337'

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var args:PackedStringArray = OS.get_cmdline_args()
	for arg:String in args:
		if(arg.begins_with('--host=')):
			host = arg.trim_prefix('--host=')
		if(arg.begins_with('--net_verbose=')):
			verbose = arg.trim_prefix('--net_verbose=').to_int()
