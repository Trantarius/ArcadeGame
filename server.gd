extends Node

var server:TCPServer
var port:int = 8888
var verbose:bool = true

func _enter_tree() -> void:
	server = TCPServer.new()
	var err:Error = server.listen(port)
	if(err!=OK):
		push_error("server listen error: ",error_string(err))
	elif(verbose):
		print("server listening on port ",port)

func _process(_delta: float) -> void:
	
	while(server.is_connection_available()):
		var tcp:StreamPeerTCP = server.take_connection()
		var conn:WebSocketConnection = WebSocketConnection.new()
		add_child(conn)
		conn.verbose = verbose
		if(!await conn.adopt_tcp_connection(tcp)):
			conn.queue_free()
			continue
		conn.received.connect(received_message.bind(conn))
		conn.disconnected.connect(conn.queue_free)
		conn.send({'what':'hello from server'})

func received_message(message:Dictionary, connection:WebSocketConnection)->void:
	connection.send({'what':'got it'})
	pass
	
func _exit_tree() -> void:
	server.stop()
	if(verbose):
		print("server stopped")
	server = null
