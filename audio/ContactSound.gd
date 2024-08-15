@tool
class_name ContactSound
extends Node

@export var stream:AudioStream
@export var volume:float = 1

func _get_configuration_warnings() -> PackedStringArray:
	if(!get_parent() is RigidBody2D):
		return ["ContactSound needs to be the child of a rigid body"]
	elif(!get_parent().contact_monitor):
		return ["ContactSound needs parent's contact_monitor enabled"]
	elif(get_parent().max_contacts_reported<1):
		return ["ContactSound needs parent's max_contacts_reported to be > 0"]
	return []

func _physics_process(_delta: float) -> void:
	if(Engine.is_editor_hint()):
		return
	var state:PhysicsDirectBodyState2D = PhysicsServer2D.body_get_direct_state(get_parent().get_rid())
	for idx:int in range(state.get_contact_count()):
		var vol:float = state.get_contact_impulse(idx).length()*state.inverse_mass
		if(vol==0):
			continue
		var sound:AudioStreamPlayer2D = AudioStreamPlayer2D.new()
		sound.stream = stream
		sound.autoplay = true
		sound.finished.connect(sound.queue_free)
		sound.volume_db = log(vol*volume) + volume
		sound.position = state.get_contact_collider_position(idx)
		get_tree().current_scene.add_child(sound)
