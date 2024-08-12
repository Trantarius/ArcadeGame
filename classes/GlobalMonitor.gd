extends Node

var userdata:ConfigFile

var local_leaderboard:Array[RunRecord]

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
	
	if(!DirAccess.dir_exists_absolute('user://runs')):
		var err:Error = DirAccess.make_dir_absolute('user://runs')
		if(err!=OK):
			push_error('cannot create runs directory: ',error_string(err))
			return
	
	for filename:String in DirAccess.get_files_at('user://runs'):
		var run:RunRecord = RunRecord.new()
		if(run.load_file('user://runs/'+filename)):
			var rank:int = local_leaderboard.bsearch_custom(run, RunRecord.compare_score)
			local_leaderboard.insert(rank,run)

func record_run(run:RunRecord)->void:
	
	run.username = username
	run.extra_data['is_userfs_persistent'] = OS.is_userfs_persistent()
	run.extra_data['is_debug'] = OS.has_feature('debug')
	run.extra_data['is_editor'] = OS.has_feature('editor')
	run.extra_data['start_playtime'] = playtime
	
	playtime += run.time
	
	var rank:int = local_leaderboard.bsearch_custom(run,RunRecord.compare_score)
	local_leaderboard.insert(rank,run)
	
	run.save_file()
	if(telemetry_enabled):
		run.submit()
	
