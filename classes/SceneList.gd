class_name SceneList
extends Resource

@export var include:Array[SceneList]
@export var scenes:Array[PackedScene]

func size()->int:
	var s:int = 0
	for sub:SceneList in include:
		s+=sub.size()
	return s+scenes.size()

func get_list()->Array[PackedScene]:
	var list:Array[PackedScene]
	for sub:SceneList in include:
		assert(sub!=self)
		list.append_array(sub.get_list())
	list.append_array(scenes)
	return list

func pick_random(weighter:Callable=Callable())->PackedScene:
	if(size()==0):
		return null
	var list:Array[PackedScene] = get_list()
	if(weighter.is_null()):
		return list.pick_random()
		
	var weights:Array[float] = [0]
	for scene:PackedScene in list:
		weights.push_back(weighter.call(scene)+weights.back())
	weights.pop_front()
	
	if(weights.back()==0):
		return null
	
	var rw:float = randf()*weights.back()
	var idx:int = weights.bsearch(rw)
	return list[idx]
