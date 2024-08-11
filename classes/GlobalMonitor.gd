extends Node

var userdata:ConfigFile

var local_leaderboard:Array
var local_runs:Dictionary

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
	
	var cmp_runs:Callable = func(run_a:Dictionary, run_b:Dictionary)->bool:
		return run_a.final_score>run_b.final_score
	
	if(!DirAccess.dir_exists_absolute('user://runs')):
		var err:Error = DirAccess.make_dir_absolute('user://runs')
		if(err!=OK):
			push_error('cannot create runs directory: ',error_string(err))
	
	for filename:String in DirAccess.get_files_at('user://runs'):
		var run:Dictionary = str_to_var(FileAccess.get_file_as_string('user://runs/'+filename))
		var rank:int = local_leaderboard.bsearch_custom(run, cmp_runs)
		local_leaderboard.insert(rank,run)
		local_runs[run.id]=run

func update_username(run_id:String,new_username:String)->void:
	assert(local_runs.has(run_id))
	local_runs[run_id].username = new_username
	
	if(local_runs[run_id].submitted):
		if(!await Client.is_socket_connected()):
			await Client.try_connect_to(Client.host)
		if(await Client.is_socket_connected()):
			Client.send({'what':'username_update','id':'run_id','username':'new_username'})
	
	if(!DirAccess.dir_exists_absolute('user://runs')):
		var err:Error = DirAccess.make_dir_absolute('user://runs')
		if(err!=OK):
			push_error('cannot create runs directory: ',error_string(err))
			return
	var file:FileAccess = FileAccess.open('user://runs/'+run_id,FileAccess.WRITE)
	if(!is_instance_valid(file)):
		push_error('cannot write run file: ',error_string(FileAccess.get_open_error()))
	else:
		file.store_string(var_to_str(local_runs[run_id]))
		file.close()

func update_username_matching(old_username:String, new_username:String)->void:
	for run:Dictionary in local_runs.values():
		if(run.username == old_username):
			update_username(run.id,new_username)

func count_username_matching(uname:String)->int:
	var count:int = 0
	for run:Dictionary in local_runs.values():
		if(run.username == uname):
			count += 1
	return count

func submit_run(id:String)->bool:
	assert(local_runs.has(id))
	if(local_runs[id]['submitted']):
		return true
	if(!await Client.is_socket_connected()):
		await Client.try_connect_to(Client.host)
	if(await Client.is_socket_connected() && await Client.send({'what':'run','data':local_runs[id]})):
		var response:Dictionary = await Client.get_response()
		if(!response.is_empty() && response.what=='run_response' && response.status=='accepted'):
			local_runs[id]['submitted'] = true
			
			if(!DirAccess.dir_exists_absolute('user://runs')):
				var err:Error = DirAccess.make_dir_absolute('user://runs')
				if(err!=OK):
					push_error('cannot create runs directory: ',error_string(err))
			
			var file:FileAccess = FileAccess.open('user://runs/'+id,FileAccess.WRITE)
			if(!is_instance_valid(file)):
				push_error("cannot write run file: ",error_string(FileAccess.get_open_error()))
			else:
				file.store_string(var_to_str(local_runs[id]))
				file.close()
	else:
		local_runs[id]['submitted'] = false
	
	return local_runs[id]['submitted']

func record_run(rundata:Dictionary)->void:
	
	var hasher:HashingContext = HashingContext.new()
	hasher.start(HashingContext.HASH_SHA256)
	hasher.update(var_to_bytes(rundata.events))
	var sha:PackedByteArray = hasher.finish()
	var run_id:String = sha.hex_encode()
	rundata['id']=run_id
	rundata['username']=username
	rundata['is_userfs_persistent']=OS.is_userfs_persistent()
	rundata['start_playtime']=playtime
	rundata['is_debug']=OS.has_feature('debug')
	rundata['is_editor']=OS.has_feature('editor')
	rundata['submitted']=false
	
	playtime += rundata.duration
	
	var cmp_runs:Callable = func(run_a:Dictionary, run_b:Dictionary)->bool:
		return run_a.final_score>run_b.final_score
	
	var rank:int = local_leaderboard.bsearch_custom(rundata,cmp_runs)
	local_leaderboard.insert(rank,rundata)
	local_runs[run_id] = rundata
	if(telemetry_enabled):
		submit_run(run_id)
	
	if(!DirAccess.dir_exists_absolute('user://runs')):
		var err:Error = DirAccess.make_dir_absolute('user://runs')
		if(err!=OK):
			push_error('cannot create runs directory: ',error_string(err))
	
	var file:FileAccess = FileAccess.open('user://runs/'+run_id,FileAccess.WRITE)
	if(!is_instance_valid(file)):
		push_error("cannot write run file: ",error_string(FileAccess.get_open_error()))
	else:
		file.store_string(var_to_str(rundata))
		file.close()
	
