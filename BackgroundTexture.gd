class_name BackgroundTexture
extends TextureRect

## If true, the point (0,0) on the canvas will be at the center of the texture instead of the corner
@export var centered:bool

func _process(_delta: float) -> void:
	var vp_rect:Rect2 = get_canvas_transform().affine_inverse() * get_viewport_rect()
	var target_start:Vector2 = (vp_rect.position/texture.get_size()).floor()*texture.get_size()
	var target_end:Vector2 = (vp_rect.end/texture.get_size()).ceil()*texture.get_size()
	global_position = target_start
	if(centered):
		global_position -= texture.get_size()/2
	size = target_end-global_position
