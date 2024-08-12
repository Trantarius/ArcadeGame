extends VBoxContainer

@export var entries:VBoxContainer
@export var loading_sign:Node2D
@export var fail_message:Label

var is_updating:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update()

func update() -> void:
	if(is_updating):
		return
	is_updating = true
	
	for entry:Control in entries.get_children():
		entry.queue_free()
	
	entries.hide()
	fail_message.hide()
	loading_sign.show()
	
	if(!await Client.is_socket_connected()):
		await Client.try_connect_to(Client.host)
	if(!await Client.is_socket_connected()):
		fail_message.show()
		loading_sign.hide()
		is_updating=false
		return
	
	Client.send({'what':'get_leaderboard'})
	var response:Dictionary = await Client.get_response()
	if(!('what' in response && response.what=='leaderboard' && 'leaderboard' in response && response.leaderboard is Array)):
		fail_message.show()
		loading_sign.hide()
		is_updating=false
		return
	
	for n:int in range(response.leaderboard.size()):
		var run:RunRecord = RunRecord.new()
		run.is_local=false
		if(!(response.leaderboard[n] is Dictionary && run.deserialize(response.leaderboard[n]))):
			fail_message.show()
			loading_sign.hide()
			is_updating=false
			return
		var entry:Control = preload('res://ui/leaderboard_entry.tscn').instantiate()
		entry.run = run
		entry.rank = n+1
		entry.show_submitted = false
		entries.add_child(entry)
	
	is_updating = false
	entries.show()
	loading_sign.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	loading_sign.rotate(delta*2)
