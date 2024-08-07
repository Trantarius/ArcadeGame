class_name WebSocketConnection
extends Node

var conn_name:String
var peer:WebSocketPeer
var verbose:bool = false

var crypto:Crypto=Crypto.new()
var this_side_key:CryptoKey
var other_side_key:CryptoKey

signal received(message:Dictionary)
signal connected
signal disconnected

func is_socket_connected()->bool:
	return (is_instance_valid(peer) && peer.get_ready_state()==WebSocketPeer.STATE_OPEN &&
			is_instance_valid(this_side_key) && is_instance_valid(other_side_key))

func try_connect_to(host:String, timeout:float = 5)->bool:
	assert(is_inside_tree())
	assert(!is_instance_valid(peer))
	
	peer = WebSocketPeer.new()
	conn_name = host
	var err:Error = peer.connect_to_url(host)
	if(err!=OK):
		push_error('connection to ',host,' failed: ',error_string(err))
		terminate_connection()
		return false
	else:
		peer.poll()
		if(peer.get_ready_state()==WebSocketPeer.STATE_CLOSED):
			push_error('connection to ',host,' failed')
			terminate_connection()
			return false
		else:
			
			var dummy:Object = Object.new()
			dummy.add_user_signal('done')
			connected.connect(dummy.emit_signal.bind(&'done'),CONNECT_ONE_SHOT)
			get_tree().create_timer(timeout,true, false, true).timeout.connect(dummy.emit_signal.bind(&'done'))
			await Signal(dummy,&'done')
			if(!is_socket_connected()):
				push_error('connection to ',host,' failed')
				terminate_connection()
				return false
			return true
			

func adopt_tcp_connection(tcp:StreamPeerTCP, timeout:float = 5)->bool:
	assert(is_inside_tree())
	assert(!is_instance_valid(peer))
	
	peer = WebSocketPeer.new()
	conn_name = tcp.get_connected_host()
	var err:Error = peer.accept_stream(tcp)
	if(err!=OK):
		push_error('web socket error: ',error_string(err))
		tcp.disconnect_from_host()
		terminate_connection()
		return false
	
	var dummy:Object = Object.new()
	dummy.add_user_signal('done')
	connected.connect(dummy.emit_signal.bind(&'done'),CONNECT_ONE_SHOT)
	get_tree().create_timer(timeout,true, false, true).timeout.connect(dummy.emit_signal.bind(&'done'))
	await Signal(dummy,&'done')
	if(!is_socket_connected()):
		push_error('connection to ',conn_name,' failed')
		terminate_connection()
		return false
	return true

func send(message:Dictionary)->bool:
	assert('what' in message)
	assert(is_socket_connected())
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
		push_error("failed to send message: ",error_string(err))
		return false
	else:
		return true

func get_response(timeout:float = 5)->Dictionary:
	var dummy:Object = Object.new()
	dummy.add_user_signal('done')
	var response:Dictionary = {}
	received.connect(func(m:Dictionary)->void:
		response=m
		dummy.emit_signal(&'done'), CONNECT_ONE_SHOT)
	get_tree().create_timer(timeout,true,false,true).timeout.connect(dummy.emit_signal.bind(&'done'))
	await Signal(dummy,&'done')
	return response

func close_connection(code:int=1000, timeout:float = 5)->void:
	peer.close(code)
	
	var dummy:Object = Object.new()
	dummy.add_user_signal('done')
	disconnected.connect(dummy.emit_signal.bind(&'done'),CONNECT_ONE_SHOT)
	get_tree().create_timer(timeout,true, false, true).timeout.connect(dummy.emit_signal.bind(&'done'))
	await Signal(dummy,&'done')
	if(is_instance_valid(peer)):
		push_error("disconnect from ",conn_name," timed out")
		terminate_connection()

func terminate_connection()->void:
	if(is_instance_valid(peer)):
		if(!peer.get_ready_state()==WebSocketPeer.STATE_CLOSED):
			peer.close(1001)
		peer = null
	conn_name = ''
	this_side_key = null
	other_side_key = null

func _process(_delta:float)->void:
	if(is_instance_valid(peer)):
		peer.poll()
		
		var state:WebSocketPeer.State = peer.get_ready_state()
		if(state==WebSocketPeer.STATE_CLOSED):
			if(verbose):
				print('disconnected from ',conn_name)
			terminate_connection()
			disconnected.emit()
			return
		elif(state==WebSocketPeer.STATE_OPEN && !is_instance_valid(this_side_key)):
			this_side_key = crypto.generate_rsa(2048)
			peer.put_var(this_side_key.save_to_string(true))
			#connected.emit()
		
		while(peer.get_available_packet_count()>0):
			var data:PackedByteArray = peer.get_packet()
			if(peer.get_packet_error()!=OK):
				push_error('packet error from ',conn_name,': ',error_string(peer.get_packet_error()))
				close_connection(1002)
			elif(peer.was_string_packet()):
				push_error('bad packet received from ',conn_name,' (received string packet)')
				close_connection(1003)
			elif(!is_instance_valid(other_side_key)):
				var vdata:Variant = data.decode_var(0)
				if(!(vdata is String)):
					push_error('bad packet received from ',conn_name,' (expected crypto key)')
					close_connection(1003)
				else:
					other_side_key = CryptoKey.new()
					var err:Error = other_side_key.load_from_string(vdata,true)
					if(err!=OK):
						push_error("bad crypto key received from ",conn_name,": ",error_string(err))
						close_connection(1003)
					else:
						if(verbose):
							print("connected to ",conn_name)
						connected.emit()
			else:
				var decrypted:PackedByteArray
				for n:int in range(0,data.size(),256):
					decrypted.append_array(crypto.decrypt(this_side_key,data.slice(n,n+256)))
				data = decrypted
				var vdata:Variant = data.decode_var(0)
				if(!(vdata is Dictionary) || !('signature' in vdata) || !('message' in vdata) ||
				!(vdata.signature is PackedByteArray) || !(vdata.message is Dictionary)):
					push_error('bad packet received from ',conn_name,' (invalid signature format)')
					close_connection(1003)
				else:
					var message:Dictionary = vdata.message
					var hasher:HashingContext = HashingContext.new()
					hasher.start(HashingContext.HASH_SHA256)
					hasher.update(var_to_bytes(message))
					var sha:PackedByteArray = hasher.finish()
					if(!crypto.verify(HashingContext.HASH_SHA256,sha,vdata.signature,other_side_key)):
						push_error('bad packet received from ',conn_name,' (bad signature)')
						close_connection(1003)
					elif(!('what' in message)):
						push_error('bad packet received from ',conn_name,' (message has no \'what\' field)')
						close_connection(1003)
					else:
						if(verbose):
							print('received message from ',conn_name,': ',message)
						received.emit(message)

func _exit_tree()->void:
	terminate_connection()
