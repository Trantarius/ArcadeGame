extends Node

var server:TCPServer
var port:int = 8888
var verbose:bool = true

var all_runs:Dictionary
var leaderboard:Array

func load_run(rundata:Dictionary)->int:
	all_runs[rundata.id]=rundata
	
	var trimmed:Dictionary = {
		'username':rundata.username,
		'final_score':rundata.final_score,
		'duration':rundata.duration,
		'boss_kills':rundata.boss_kills
	}
	
	var cmp_runs:Callable = func(run_a:Dictionary, run_b:Dictionary)->bool:
		return run_a.final_score>run_b.final_score
	
	var rank:int = leaderboard.bsearch_custom(trimmed, cmp_runs)
	leaderboard.insert(rank,trimmed)
	return rank

func _ready() -> void:
	server = TCPServer.new()
	var err:Error = server.listen(port)
	if(err!=OK):
		push_error("server listen error: ",error_string(err))
	elif(verbose):
		print("server listening on port ",port)
	
	if(!DirAccess.dir_exists_absolute('user://server')):
		DirAccess.make_dir_absolute('user://server')
	if(!DirAccess.dir_exists_absolute('user://server/runs')):
		DirAccess.make_dir_absolute('user://server/runs')
	
	for filename:String in DirAccess.get_files_at('user://server/runs'):
		var string:String = FileAccess.get_file_as_string('user://server/runs/'+filename)
		if(string.is_empty()):
			push_error("run file ",filename," could not be read: ",error_string(FileAccess.get_open_error()))
		else:
			load_run(str_to_var(string))
		
	

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

func received_message(message:Dictionary, connection:WebSocketConnection)->void:
	if(message.what=='run'):
		handle_run_message(message, connection)
	if(message.what=='get_leaderboard'):
		handle_get_leaderboard_message(message, connection)
	pass

func handle_get_leaderboard_message(message:Dictionary, connection:WebSocketConnection)->void:
	connection.send({'what':'leaderboard','leaderboard':leaderboard})

func handle_run_message(message:Dictionary, connection:WebSocketConnection)->void:
	
	if(!(message.what=='run' && 'data' in message && message.data is Dictionary 
		&& 'username' in message.data && message.data.username is String 
		&& 'events' in message.data && message.data.events is Array 
		&& 'final_score' in message.data && message.data.final_score is float
		&& 'boss_kills' in message.data && message.data.boss_kills is int
		&& 'duration' in message.data && message.data.duration is int)):
			push_error("bad run message: missing/invalid fields")
			connection.send({'what':'run_response','status':'error'})
			return
	
	if(Util.verify_username(message.data.username)!=""):
		push_error("bad run message: invalid username")
		connection.send({'what':'run_response','status':'error'})
		return
	
	for item:Variant in message.data.events:
		if(!(item is Dictionary && 'event' in item && item.event is String && 'time' in item && item.time is int)):
			push_error("bad run message: invalid event")
			connection.send({'what':'run_response','status':'error'})
			return
	
	var hasher:HashingContext = HashingContext.new()
	hasher.start(HashingContext.HASH_SHA256)
	hasher.update(var_to_bytes(message.data.events))
	var sha:PackedByteArray = hasher.finish()
	var run_id:String = sha.hex_encode()
	
	if(all_runs.has(run_id)):
		push_error("duplicate run submitted")
		connection.send({'what':'run_response','status':'accepted'})
		return
	
	message.data['id']=run_id
	var rank:int = load_run(message.data)
	connection.send({'what':'run_response', 'status':'accepted', 'rank':rank, 'leaderboard':leaderboard})
	
	var file:FileAccess = FileAccess.open('user://server/runs/'+run_id,FileAccess.WRITE)
	file.store_string(var_to_str(message.data))
	file.close()
	

func _notification(what: int) -> void:
	if(what==NOTIFICATION_WM_CLOSE_REQUEST && is_instance_valid(server)):
		server.stop()
		if(verbose):
			print("server stopped")
		server = null
