@tool
extends EditorScript

const runs_path:PackedStringArray = [
	"/home/tranus/.local/share/StarshotServer/server/runs",
	"/home/tranus/.local/share/ArcadeGameServer/server/runs",
	"/home/tranus/.local/share/Starshot/server/runs"
	]

const enemy_list:SceneList = preload("res://enemies/enemy_list.tres")

const upgrade_list:SceneList = preload("res://upgrades/common_upgrade_list.tres")

const ability_list:SceneList = preload("res://abilities/ability_list.tres")

func _run() -> void:
	
	var runs:Array[RunRecord]
	
	for path:String in runs_path:
		if(!DirAccess.dir_exists_absolute(path)):
			printerr("runs_path doesn't exist: ",path)
			return
		
		for filename:String in DirAccess.get_files_at(path):
			var run:RunRecord = RunRecord.new()
			run.is_local = false
			if(run.load_file(path+'/'+filename)):
				runs.push_back(run)
	
	var kills:Dictionary
	for enemy:PackedScene in enemy_list.get_list():
		kills[enemy.resource_path] = {}
		for ability:PackedScene in ability_list.get_list():
			var ab:PlayerAbility = ability.instantiate()
			kills[enemy.resource_path][ability.resource_path] = [0];
			kills[enemy.resource_path][ab.ability_name] = kills[enemy.resource_path][ability.resource_path]
			ab.queue_free()
	
	var deaths:Dictionary
	for enemy:PackedScene in enemy_list.get_list():
		deaths[enemy.resource_path] = 0
	
	var abilities:Dictionary
	for ability:PackedScene in ability_list.get_list():
		var ab:PlayerAbility = ability.instantiate()
		abilities[ab.ability_name] = {'seen':0, 'taken':0}
		abilities[ability.resource_path] = abilities[ab.ability_name]
		ab.queue_free()
	
	var upgrades:Dictionary
	for upgrade:PackedScene in upgrade_list.get_list():
		var up:Upgrade = upgrade.instantiate()
		upgrades[up.upgrade_name] = {'seen':0, 'taken':0}
		upgrades[upgrade.resource_path] = upgrades[up.upgrade_name]
		up.queue_free()
	
	var playtime:Dictionary
	
	var perfdata:Array
	
	var runcount:int = 0
	var editor_count:int = 0
	
	
	for run:RunRecord in runs:
		if(run.extra_data.has('is_editor') && run.extra_data.is_editor || run.username=='test'):
			editor_count+=1
			continue
		if(run.extra_data.start_playtime>56*60000):
			editor_count+=1
			continue
		
		runcount += 1
		
		if(!playtime.has(run.username)):
			playtime[run.username]=[]
		playtime[run.username].push_back(run.time)
			
		if(run.extra_data.has('performance')):
			perfdata.append_array(run.extra_data.performance)
		else:
			printerr("run is missing perf data")
		
		if(run.events.is_empty()):
			printerr("run missing events")
			continue
		for event:Dictionary in run.events:
			
			if(event.event == 'player_kill'):
				var target:String
				for enemy:String in kills.keys():
					if(event.target.contains(enemy)):
						target = enemy
						break
				if(target.is_empty()):
					printerr("unknown target: "+event.target)
					continue
				var method:String
				if(event.method.contains("light_cannon_projectile")):
					method = "Light Cannon"
				else:
					for ability:String in kills[target].keys():
						if(event.method.contains(ability)):
							method = ability
							break
				if(method.is_empty()):
					printerr("unknown method: "+event.method)
					continue
				kills[target][method][0]+=1
			
			elif(event.event == 'player_death'):
				var found:bool = false
				for enemy:String in deaths.keys():
					if(event.attacker.contains(enemy)):
						deaths[enemy]+=1
						found=true
						break
				if(!found):
					printerr("unknown attacker: "+event.attacker)
			
			elif(event.event == 'player_new_ability'):
				if(abilities.has(event.ability_name)):
					abilities[event.ability_name].seen += 1
				else:
					printerr("unknown ability: "+event.ability_name)
			
			elif(event.event == 'player_added_ability'):
				if(abilities.has(event.ability_name)):
					abilities[event.ability_name].taken += 1
				else:
					printerr("unknown ability: "+event.ability_name)
			
			elif(event.event == 'player_new_upgrade'):
				if(upgrades.has(event.upgrade_name)):
					upgrades[event.upgrade_name].seen += 1
				else:
					printerr("unknown upgrade: "+event.upgrade_name)
			
			elif(event.event == 'player_added_upgrade'):
				if(upgrades.has(event.upgrade_name)):
					upgrades[event.upgrade_name].taken += 1
				else:
					printerr("unknown upgrade: "+event.upgrade_name)
	
	print(editor_count," editor runs ignored")
	print(runcount," runs included")
	
	#print("kills: ",kills)
	#print("deaths: ",deaths)
	#print("abilities: ",abilities)
	#print("upgrades: ",upgrades)
	
	print("kills:")
	var line:String = ' '.repeat(16)
	for ability:PackedScene in ability_list.get_list():
		var ab:PlayerAbility = ability.instantiate()
		var name:String = ab.ability_name
		ab.queue_free()
		line+=resize_str(name,16)
	print(line)
	line = ''
	for enemy:PackedScene in enemy_list.get_list():
		var name:String = enemy.resource_path.get_basename().get_file()
		line += resize_str(name,16)
		for ability:PackedScene in ability_list.get_list():
			line+= resize_str(str(kills[enemy.resource_path][ability.resource_path][0]), 16)
		print(line)
		line=''
	print()
	
	print("deaths:")
	line = ''
	for key:String in deaths.keys():
		line += resize_str(key.get_basename().get_file(), 16)
		line += resize_str(str(deaths[key]),16)
		print(line)
		line = ''
	print()
	
	print("abilities:")
	line = ' '.repeat(16)
	line += resize_str('seen',16)
	line += resize_str('taken',16)
	line += resize_str('taken %',16)
	print(line)
	line = ''
	for ability:PackedScene in ability_list.get_list():
		var ab:PlayerAbility = ability.instantiate()
		line += resize_str(ab.ability_name, 16)
		ab.queue_free()
		line += resize_str(str(abilities[ability.resource_path].seen), 16)
		line += resize_str(str(abilities[ability.resource_path].taken), 16)
		var pct:float
		if(abilities[ability.resource_path].seen==0):
			pct = 0
		else:
			pct = float(abilities[ability.resource_path].taken)/float(abilities[ability.resource_path].seen)
		line += resize_str(str(int(pct*100))+'%',16)
		print(line)
		line = ''
	print()
	
	print("upgrades:")
	line = ' '.repeat(16)
	line += resize_str('seen',16)
	line += resize_str('taken',16)
	line += resize_str('taken %',16)
	print(line)
	line = ''
	for upgrade:PackedScene in upgrade_list.get_list():
		var up:Upgrade = upgrade.instantiate()
		line += resize_str(up.upgrade_name, 16)
		up.queue_free()
		line += resize_str(str(upgrades[upgrade.resource_path].seen), 16)
		line += resize_str(str(upgrades[upgrade.resource_path].taken), 16)
		var pct:float
		if(upgrades[upgrade.resource_path].seen==0):
			pct = 0
		else:
			pct = float(upgrades[upgrade.resource_path].taken)/float(upgrades[upgrade.resource_path].seen)
		line += resize_str(str(int(pct*100))+'%',16)
		print(line)
		line = ''
	print()
	
	var fps_data:Array = perfdata.map(func(dict): return dict.fps)
	var process_data:Array = perfdata.map(func(dict): return dict.process)
	var physics_data:Array = perfdata.map(func(dict): return dict.physics)
	var nav_data:Array = perfdata.map(func(dict): return dict.nav)
	fps_data.sort()
	process_data.sort()
	physics_data.sort()
	nav_data.sort()
	
	print("performance:")
	line = ' '.repeat(16)
	line += resize_str('worst',16)
	line += resize_str('median',16)
	line += resize_str('5%',16)
	print(line)
	line = ''
	line += resize_str('fps',16)
	line += resize_str(str(fps_data.min()),16)
	line += resize_str(str(fps_data[fps_data.size()/2]),16)
	line += resize_str(str(fps_data[fps_data.size()*5/100]),16)
	print(line)
	line = ''
	line += resize_str('process',16)
	line += resize_str("%.1fms"%[process_data.max()*1000],16)
	line += resize_str("%.1fms"%[process_data[process_data.size()/2]*1000],16)
	line += resize_str("%.1fms"%[process_data[process_data.size()*95/100]*1000],16)
	print(line)
	line = ''
	line += resize_str('physics',16)
	line += resize_str("%.1fms"%[physics_data.max()*1000],16)
	line += resize_str("%.1fms"%[physics_data[physics_data.size()/2]*1000],16)
	line += resize_str("%.1fms"%[physics_data[physics_data.size()*95/100]*1000],16)
	print(line)
	line = ''
	line += resize_str('nav',16)
	line += resize_str("%.1fms"%[nav_data.max()*1000],16)
	line += resize_str("%.1fms"%[nav_data[nav_data.size()/2]*1000],16)
	line += resize_str("%.1fms"%[nav_data[nav_data.size()*95/100]*1000],16)
	print(line)
	line = ''
	
	var user_count:int = 0
	var run_count:int = 0
	var runtime_tot:int = 0
	for user:String in playtime:
		user_count += 1
		var user_tot:int = playtime[user].reduce(func(a,b): return a+b)
		runtime_tot += user_tot
		run_count += playtime[user].size()
	print()
	print("avg runtime: ", time_fmt(runtime_tot/run_count))
	print("avg playtime: ",time_fmt(runtime_tot/user_count))

func resize_str(st:String, sz:int)->String:
	if(st.length()<sz):
		return st.rpad(sz)
	elif(st.length()>sz):
		return st.left(sz)
	else:
		return st

func time_fmt(millis:int)->String:
	if(millis>3600000):
		return '%d:%02d:%02d'%[millis/3600000, (millis%3600000)/60000, (millis%60000)/1000]
	else:
		return '%d:%02d'%[millis/60000, (millis%60000)/1000]
