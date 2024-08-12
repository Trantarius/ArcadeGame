class_name Server
extends Node

var server:TCPServer
var port:int = 8008
var verbose:int = 0

var all_runs:Dictionary
var leaderboard:Array[RunRecord]

func _ready() -> void:
	
	for arg:String in OS.get_cmdline_args():
		if(arg.begins_with('--port=')):
			port = arg.trim_prefix('--port=').to_int()
		if(arg.begins_with('--net_verbose=')):
			verbose = arg.trim_prefix('--net_verbose=').to_int()
	
	server = TCPServer.new()
	var err:Error = server.listen(port)
	if(err!=OK):
		push_error("server listen error: ",error_string(err))
	elif(verbose>0):
		print("server listening on port ",port)
	
	if(!DirAccess.dir_exists_absolute('user://server/runs')):
		err = DirAccess.make_dir_recursive_absolute('user://server/runs')
		if(err!=OK):
			push_error('cannot create runs directory: ',error_string(err))
			return
	
	for filename:String in DirAccess.get_files_at('user://server/runs'):
		var run:RunRecord = RunRecord.new()
		run.is_local = false
		if(run.load_file('user://server/runs/'+filename)):
			run.minimize()
			var rank:int = leaderboard.bsearch_custom(run, RunRecord.compare_score)
			leaderboard.insert(rank,run)
			all_runs[run.id]=run 
	

func _process(_delta: float) -> void:
	
	if(!is_instance_valid(server)):
		return
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
	elif(message.what=='get_leaderboard'):
		handle_get_leaderboard_message(message, connection)
	else:
		push_error("server doesn't know what to do with message; what = '",message.what,"'")

func handle_get_leaderboard_message(message:Dictionary, connection:WebSocketConnection)->void:
	var data:Array = leaderboard.map(func(run:RunRecord)->Dictionary:
		return run.serialize_min())
	connection.send({'what':'leaderboard','leaderboard':data})

func handle_run_message(message:Dictionary, connection:WebSocketConnection)->void:
	
	if(!(message.what=='run' && 'data' in message && message.data is Dictionary)):
		push_error("bad run message: missing/invalid data")
		connection.send({'what':'run_response','status':'error'})
		return
	
	var run:RunRecord = RunRecord.new()
	run.is_local = false
	if(!run.deserialize(message.data)):
		connection.send({'what':'run_response','status':'error'})
		return
	
	if(!run.validate()):
		push_error("bad run message: failed to validate")
		connection.send({'what':'run_response','status':'error'})
		return
	
	var rank:int = leaderboard.bsearch_custom(run,RunRecord.compare_score)
	if(all_runs.has(run.id)):
		while(rank<leaderboard.size() && leaderboard[rank].id!=run.id):
			rank+=1
		leaderboard[rank] = run
	else:
		leaderboard.insert(rank,run)
	
	all_runs[run.id] = run
	run.save_file()
	run.minimize()
	connection.send({'what':'run_response','status':'accepted','rank':rank})
	

func _notification(what: int) -> void:
	if(what==NOTIFICATION_WM_CLOSE_REQUEST && is_instance_valid(server)):
		server.stop()
		if(verbose>1):
			print("server stopped")
		server = null
