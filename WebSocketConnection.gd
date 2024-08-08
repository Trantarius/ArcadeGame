class_name WebSocketConnection
extends Node

var peer:WebSocketPeer
var verbose:bool = false

var crypto:Crypto=Crypto.new()
var this_side_key:CryptoKey
var other_side_key:CryptoKey

signal received(message:Dictionary)
signal connected
signal disconnected

var task:Signal

# some close codes from RFC 6455 section 7.4
enum{ CLOSE_NORMAL=1000, CLOSE_ERROR=1008}

func __make_task()->Signal:
	assert(task.is_null())
	var dummy:Object = Object.new()
	dummy.add_user_signal('task',[{'name':'success','type':TYPE_BOOL}])
	var sig:Signal = Signal(dummy,&'task')
	sig.connect(func(_s:bool)->void:
		dummy.free()
	,CONNECT_DEFERRED)
	return sig

func is_socket_connected()->bool:
	while(!task.is_null()):
		await task
	return (is_instance_valid(peer) && peer.get_ready_state()==WebSocketPeer.STATE_OPEN &&
			is_instance_valid(this_side_key) && is_instance_valid(other_side_key))
	
func try_connect_to(host:String, timeout:float = 5)->bool:
	
	while(!task.is_null()):
		await task
	
	if(verbose):
		print("attempting connection")
	
	if(!is_inside_tree() || is_instance_valid(peer)):
		return false
	
	peer = WebSocketPeer.new()
	var err:Error = peer.connect_to_url(host)
	if(err!=OK):
		if(verbose):
			push_error('connection failed: ',error_string(err))
		terminate_connection()
		return false
	else:
		peer.poll()
		if(peer.get_ready_state()==WebSocketPeer.STATE_CLOSED):
			if(verbose):
				push_error('connection failed')
			terminate_connection()
			return false
			
		else:
			
			# must be stored in a local variable so the following lambdas refer to this task, not whatever
			# is in the 'task' variable at the time
			var sig:Signal = __make_task()
			task = sig
			
			var on_connected:Callable = func()->void:
				sig.emit(true)
			connected.connect(on_connected)
			
			var timer:SceneTreeTimer = get_tree().create_timer(timeout,true, false, true)
			var on_timeout:Callable = func()->void:
				if(verbose):
					push_error('connection timed out')
				sig.emit(false)
			timer.timeout.connect(on_timeout)
			
			var success:bool = await sig
			connected.disconnect(on_connected)
			timer.timeout.disconnect(on_timeout)
			task = Signal()
			return success
			

func adopt_tcp_connection(tcp:StreamPeerTCP, timeout:float = 5)->bool:
	while(!task.is_null()):
		await task
		
	if(verbose):
		print("attempting connection")
		
	if(!is_inside_tree() || is_instance_valid(peer)):
		return false
	
	peer = WebSocketPeer.new()
	var err:Error = peer.accept_stream(tcp)
	if(err!=OK):
		if(verbose):
			push_error('web socket error: ',error_string(err))
		tcp.disconnect_from_host()
		terminate_connection()
		return false
	
	
	var sig:Signal = __make_task()
	task = sig
	
	var on_connected:Callable = func()->void:
		sig.emit(true)
	connected.connect(on_connected)
		
	var timer:SceneTreeTimer = get_tree().create_timer(timeout,true, false, true)
	var on_timeout:Callable = func()->void:
		if(verbose):
			push_error('connection timed out')
		tcp.disconnect_from_host()
		sig.emit(false)
	timer.timeout.connect(on_timeout)
	
	var success:bool = await sig
	connected.disconnect(on_connected)
	timer.timeout.disconnect(on_timeout)
	task = Signal()
	return success

func send(message:Dictionary)->bool:
	assert('what' in message)
	if(!await is_socket_connected()):
		return false
	var hasher:HashingContext = HashingContext.new()
	hasher.start(HashingContext.HASH_SHA256)
	hasher.update(var_to_bytes(message))
	var sha:PackedByteArray = hasher.finish()
	var signature:PackedByteArray = crypto.sign(HashingContext.HASH_SHA256, sha, this_side_key)
	var signed:Dictionary = {'signature':signature,'message':message}
	var data:PackedByteArray = var_to_bytes(signed)
	var encrypted:PackedByteArray
	for n:int in range(0,data.size(),200):
		encrypted.append_array(crypto.encrypt(other_side_key, data.slice(n,n+200)))
	var err:Error = peer.put_packet(encrypted)
	if(err!=OK):
		if(verbose):
			push_error("failed to send message: ",error_string(err))
		return false
	else:
		return true

func get_response(timeout:float = 5)->Dictionary:
	if(!await is_socket_connected()):
		return {}
	var response:Dictionary = {}
	
	var sig:Signal = __make_task()
	task = sig
	
	var on_received:Callable = func(m:Dictionary)->void:
		response=m
		sig.emit(true)
	received.connect(on_received)
	
	var timer:SceneTreeTimer = get_tree().create_timer(timeout,true,false,true)
	var on_timeout:Callable = func()->void:
		if(verbose):
			push_error("response timed out")
		sig.emit(false)
	timer.timeout.connect(on_timeout)
	
	await sig
	received.disconnect(on_received)
	timer.timeout.disconnect(on_timeout)
	task = Signal()
	return response

func close_connection(timeout:float = 5)->bool:
	while(!task.is_null()):
		await task
	
	if(!is_instance_valid(peer)):
		return false
	
	peer.close(CLOSE_NORMAL)
	
	var sig:Signal = __make_task()
	task = sig
	
	var on_disconnected:Callable = func()->void:
		sig.emit(true)
	disconnected.connect(on_disconnected)
	
	var timer:SceneTreeTimer = get_tree().create_timer(timeout,true, false, true)
	var on_timeout:Callable = func()->void:
		if(verbose):
			push_error("disconnect timed out")
		if(is_instance_valid(peer)):
			peer.close(CLOSE_ERROR)
		peer=null
		this_side_key = null
		other_side_key = null
	timer.timeout.connect(on_timeout)
	
	var success:bool = await sig
	disconnected.disconnect(on_disconnected)
	timer.timeout.disconnect(on_timeout)
	task = Signal()
	return success


## Stops the connection immediately. This is messier than close_connection, so it should only be used in
## response to an error.
func terminate_connection()->void:
	if(is_instance_valid(peer)):
		if(!peer.get_ready_state()==WebSocketPeer.STATE_CLOSED):
			peer.close(CLOSE_ERROR)
	peer = null
	this_side_key = null
	other_side_key = null
	while(!task.is_null()):
		task.emit(false)

func _process(_delta:float)->void:
	if(is_instance_valid(peer)):
		peer.poll()
		
		var state:WebSocketPeer.State = peer.get_ready_state()
		if(state==WebSocketPeer.STATE_CLOSED):
			if(verbose):
				print('disconnected')
			peer = null
			this_side_key = null
			other_side_key = null
			disconnected.emit()
			return
		
		elif(state==WebSocketPeer.STATE_OPEN && !is_instance_valid(this_side_key)):
			this_side_key = crypto.generate_rsa(2048)
			peer.put_var(this_side_key.save_to_string(true))
		
		while(peer.get_available_packet_count()>0):
			var data:PackedByteArray = peer.get_packet()
			if(peer.get_packet_error()!=OK):
				if(verbose):
					push_error('packet error: ',error_string(peer.get_packet_error()))
				terminate_connection()
			elif(peer.was_string_packet()):
				if(verbose):
					push_error('bad packet received (received string packet)')
				terminate_connection()
			elif(!is_instance_valid(other_side_key)):
				var vdata:Variant = data.decode_var(0)
				if(!(vdata is String)):
					if(verbose):
						push_error('bad packet received (expected crypto key)')
					terminate_connection()
				else:
					other_side_key = CryptoKey.new()
					var err:Error = other_side_key.load_from_string(vdata,true)
					if(err!=OK):
						if(verbose):
							push_error("bad crypto key received: ",error_string(err))
						terminate_connection()
					else:
						if(verbose):
							print("connected")
						connected.emit()
			else:
				var decrypted:PackedByteArray
				for n:int in range(0,data.size(),256):
					decrypted.append_array(crypto.decrypt(this_side_key,data.slice(n,n+256)))
				data = decrypted
				var vdata:Variant = data.decode_var(0)
				if(!(vdata is Dictionary) || !('signature' in vdata) || !('message' in vdata) ||
				!(vdata.signature is PackedByteArray) || !(vdata.message is Dictionary)):
					if(verbose):
						push_error('bad packet received (invalid signature format)')
					terminate_connection()
				else:
					var message:Dictionary = vdata.message
					var hasher:HashingContext = HashingContext.new()
					hasher.start(HashingContext.HASH_SHA256)
					hasher.update(var_to_bytes(message))
					var sha:PackedByteArray = hasher.finish()
					if(!crypto.verify(HashingContext.HASH_SHA256,sha,vdata.signature,other_side_key)):
						if(verbose):
							push_error('bad packet received (bad signature)')
						terminate_connection()
					elif(!('what' in message)):
						if(verbose):
							push_error('bad packet received (message has no \'what\' field)')
						terminate_connection()
					else:
						if(verbose):
							print('received message: ',message)
						received.emit(message)

func _notification(what: int) -> void:
	if((what==NOTIFICATION_EXIT_TREE || what==NOTIFICATION_WM_CLOSE_REQUEST) && is_instance_valid(peer)):
		(func()->void:
			close_connection()
			while(!task.is_null()):
				_process(0)
		).call_deferred()
