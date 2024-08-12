class_name RunRecord
extends Resource

var id:String
var username:String

var score:float
var time:int
var boss_kills:int
var events:Array

var is_local:bool
var has_been_submitted:bool = false
var submission_in_progress:bool = false
var submission_failed:bool = false
signal submission_begin
signal submission_complete

var extra_data:Dictionary

static func compare_score(run_a:RunRecord, run_b:RunRecord)->bool:
	if(is_equal_approx(run_a.score, run_b.score)):
		return compare_boss_kills(run_a,run_b)
	return run_a.score > run_b.score

static func compare_time(run_a:RunRecord, run_b:RunRecord)->bool:
	return run_a.time > run_b.time

static func compare_boss_kills(run_a:RunRecord, run_b:RunRecord)->bool:
	if(run_a.boss_kills == run_b.boss_kills):
		return compare_time_rev(run_a,run_b)
	return run_a.boss_kills > run_b.boss_kills

static func compare_score_rev(run_a:RunRecord, run_b:RunRecord)->bool:
	if(is_equal_approx(run_a.score, run_b.score)):
		return compare_boss_kills_rev(run_a,run_b)
	return run_a.score < run_b.score

static func compare_time_rev(run_a:RunRecord, run_b:RunRecord)->bool:
	return run_a.time < run_b.time

static func compare_boss_kills_rev(run_a:RunRecord, run_b:RunRecord)->bool:
	if(run_a.boss_kills == run_b.boss_kills):
		return compare_time(run_a,run_b)
	return run_a.boss_kills < run_b.boss_kills

func minimize()->void:
	events.clear()
	extra_data.clear()

func save_file()->void:
	var path:String = 'user://runs' if is_local else 'user://server/runs'
	if(!DirAccess.dir_exists_absolute(path)):
		var err:Error = DirAccess.make_dir_recursive_absolute(path)
		if(err!=OK):
			push_error('cannot create runs directory: ',error_string(err))
			return
	
	var file:FileAccess = FileAccess.open(path+'/'+id,FileAccess.WRITE)
	if(!is_instance_valid(file)):
		push_error("cannot write run file: ",error_string(FileAccess.get_open_error()))
		return
	file.store_string(var_to_str(serialize_full()))
	if(file.get_error()!=OK):
		push_error("cannot write run file: ",error_string(file.get_error()))
	file.close()

func load_file(path:String)->bool:
	var file:FileAccess = FileAccess.open(path,FileAccess.READ)
	if(!is_instance_valid(file)):
		push_error("cannot read run file: ", error_string(FileAccess.get_open_error()))
		return false
	var string:String = file.get_as_text()
	var data:Variant = str_to_var(string)
	if(!data is Dictionary):
		push_error("bad data in run file")
		return false
	return deserialize(data)

func serialize_full()->Dictionary:
	return {
		'id':id,
		'username':username,
		'score':score,
		'time':time,
		'boss_kills':boss_kills,
		'events':events,
		'extra_data':extra_data,
		'has_been_submitted':has_been_submitted
	}

func serialize_min()->Dictionary:
	return {
		'id':id,
		'username':username,
		'score':score,
		'time':time,
		'boss_kills':boss_kills
	}

func deserialize(data:Dictionary)->bool:
	var req_field:Callable = func(field:String, type:int)->bool:
		if(!data.has(field)):
			push_error('data is missing \'',field,'\' field')
			return false
		if(typeof(data[field])!=type):
			push_error('the \'',field,'\' field is the wrong type (is ',
				type_string(typeof(data[field])),', should be ',type_string(type),')')
			return false
		set(field, data[field])
		return true
	
	var opt_field:Callable = func(field:String, type:int)->bool:
		if(data.has(field)):
			if(typeof(data[field])!=type):
				push_error('the \'',field,'\' field is the wrong type (is ',
					type_string(typeof(data[field])),', should be ',type_string(type),')')
				return false
			set(field, data[field])
		return true
	
	if(!req_field.call('id',TYPE_STRING)):
		return false
	if(!req_field.call('username',TYPE_STRING)):
		return false
	if(!req_field.call('score',TYPE_FLOAT)):
		return false
	if(!req_field.call('time',TYPE_INT)):
		return false
	if(!req_field.call('boss_kills',TYPE_INT)):
		return false
	
	if(!opt_field.call('extra_data',TYPE_DICTIONARY)):
		return false
	if(!opt_field.call('has_been_submitted',TYPE_BOOL)):
		return false
	if(!opt_field.call('events', TYPE_ARRAY)):
		return false
	
	return true

func validate()->bool:
	
	if(events.is_empty()):
		print("no events")
		return false
	
	if(Util.verify_username(username)!=''):
		print("bad username")
		return false
	
	var hasher:HashingContext = HashingContext.new()
	hasher.start(HashingContext.HASH_SHA256)
	hasher.update(var_to_bytes(events))
	var sha:PackedByteArray = hasher.finish()
	var run_id:String = sha.hex_encode()
	if(run_id != id):
		print("wrong id")
		print(run_id)
		print(id)
		return false
	
	var event_score:float = 0
	var event_boss_kills:int = 0
	for event:Variant in events:
		if(event is Dictionary && 'event' in event):
			if(event.event=='player_kill'):
				if('point_value' in event && event.point_value is float):
					event_score += event.point_value
				else:
					print("bad player_kill")
					return false
			elif(event.event=='boss_kill'):
				event_boss_kills += 1
		else:
			print("bad event")
			return false
	
	if(!is_equal_approx(event_score, score) || event_boss_kills!=boss_kills):
		print("mismatched score/boss kills")
		return false
		
	return true

func set_from_events()->void:
	if(events.is_empty()):
		return
	
	var hasher:HashingContext = HashingContext.new()
	hasher.start(HashingContext.HASH_SHA256)
	hasher.update(var_to_bytes(events))
	var sha:PackedByteArray = hasher.finish()
	id = sha.hex_encode()
	
	score = 0
	boss_kills = 0
	for event:Variant in events:
		if(event is Dictionary && 'event' in event):
			if(event.event=='player_kill' && 'point_value' in event && event.point_value is float):
				score += event.point_value
			elif(event.event=='boss_kill'):
				boss_kills += 1
	
	time = events[-1].time

func submit()->void:
	if(submission_in_progress):
		return
	
	submission_in_progress = true
	submission_begin.emit()
	
	if(!await Client.is_socket_connected()):
		await Client.try_connect_to(Client.host)
	if(await Client.is_socket_connected() && await Client.send({'what':'run','data':serialize_full()})):
		var response:Dictionary = await Client.get_response()
		if(!response.is_empty() && response.what=='run_response' && response.status=='accepted'):
			has_been_submitted=true
			save_file()
			submission_in_progress=false
			submission_complete.emit()
			return
	
	has_been_submitted=false
	submission_in_progress=false
	submission_failed=true
	submission_complete.emit()
