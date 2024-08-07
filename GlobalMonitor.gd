extends Node

var userdata:ConfigFile

var playtime:int:
	get:
		return userdata.get_value('','playtime',0)
	set(to):
		userdata.set_value('','playtime',to)
		userdata.save('user://userdata.txt')

var username:String:
	get:
		return userdata.get_value('','username','Anonymous')
	set(to):
		userdata.set_value('','username',to)
		userdata.save('user://userdata.txt')

var telemetry_enabled:bool:
	get:
		return userdata.get_value('','telemetry_enabled',false)
	set(to):
		userdata.set_value('','telemetry_enabled',to)
		userdata.save('user://userdata.txt')

func _ready()->void:
	userdata = ConfigFile.new()
	if(FileAccess.file_exists('user://userdata.txt')):
		userdata.load('user://userdata.txt')
	if(!userdata.has_section_key('','playtime')):
		userdata.set_value('','playtime',0)
	if(!userdata.has_section_key('','username')):
		userdata.set_value('','username','Anonymous')
	if(!userdata.has_section_key('','telemetry_enabled')):
		userdata.set_value('','telemetry_enabled',true)
	userdata.save('user://userdata.txt')

func record_run(events:Dictionary, score:float)->void:
	
	var hasher:HashingContext = HashingContext.new()
	hasher.start(HashingContext.HASH_SHA256)
	hasher.update(var_to_bytes(events))
	var sha:PackedByteArray = hasher.finish()
	var run_id:String = sha.hex_encode()
	var rundata:Dictionary = {
		'username': username,
		'submitted': false,
		'is_userfs_persistent': OS.is_userfs_persistent(),
		'events': events,
		'start_playtime': playtime,
		'final_score': score,
		'duration': float(events[events.keys()[-1]].time)/1000.0
	}
	
	if(telemetry_enabled):
		if(!Client.is_socket_connected()):
			await Client.try_connect_to(Client.host)
		if(Client.is_socket_connected() && Client.send({'what':'run','data':rundata})):
			rundata.submitted = true
	
	playtime += rundata.duration
	var file:FileAccess = FileAccess.open('user://runs/'+run_id,FileAccess.WRITE)
	file.store_var(rundata)
	file.close()
	
