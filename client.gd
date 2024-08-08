extends WebSocketConnection

var host:String = '127.0.0.1:8888'

func _ready() -> void:
	print(OS.has_feature('editor'))
	verbose = true
	connected.connect(send.bind({'what':'hello from client'}))
