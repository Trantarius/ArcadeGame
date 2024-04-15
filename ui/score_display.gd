extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = str(0)
	var player:Player = get_tree().get_first_node_in_group('Players')
	player.kill.connect(_on_player_kill.bind(player))


func _on_player_kill(_ignore:Damage,player:Player)->void:
	# wait a frame in case any other on-kill effects alter the score
	await get_tree().process_frame
	if(is_instance_valid(player)):
		text = str(int(player.score))
