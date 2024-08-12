extends WebSocketConnection

var host:String = '127.0.0.1:8888'

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	verbose = true
