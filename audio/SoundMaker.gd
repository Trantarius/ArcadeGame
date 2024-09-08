## This class creates [AudioStreamPlayer2D] instances and places them at its position.
## These stream players will delete themselves when the sound is done playing.
## This allows sounds to overlap, and to outlive the instigating node (such as when an enemy dies).
class_name SoundMaker
extends Node2D

@export var stream:AudioStream
@export var volume:float = 1

func play()->void:
	var sound:AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	sound.stream = stream
	sound.autoplay = true
	sound.finished.connect(sound.queue_free)
	sound.volume_db = volume
	sound.position = global_position
	get_tree().current_scene.add_child(sound)
