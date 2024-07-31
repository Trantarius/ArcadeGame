## This script makes a polygon pre-render itself to a texture in the editor. This allows for anti-aliasing with the
## compatibility renderer, and oversampling.
@tool
extends Polygon2D

@export var oversample:float = 2:
	set(to):
		oversample=to
		if(Engine.is_editor_hint()):
			_update_texture()
var poly_tex:ImageTexture
var poly_off:Vector2

func _set(property: StringName, value: Variant) -> bool:
	if(Engine.is_editor_hint() && property==&'polygon'):
		_update_texture()
	return false

func _get_property_list() -> Array[Dictionary]:
	return [
		{
			'name':'poly_tex',
			'type':TYPE_OBJECT,
			'usage':PROPERTY_USAGE_STORAGE|PROPERTY_USAGE_EDITOR|PROPERTY_USAGE_READ_ONLY
		},
		{
			'name':'poly_off',
			'type':TYPE_VECTOR2,
			'usage':PROPERTY_USAGE_STORAGE|PROPERTY_USAGE_EDITOR|PROPERTY_USAGE_READ_ONLY
		}
	]

func _update_texture()->void:
	var bounds:Rect2 = Rect2(polygon[0],Vector2.ZERO)
	for v:Vector2 in polygon:
		bounds = bounds.expand(v)
	bounds = bounds.grow_individual(1,1,1,1)
	
	var vp:RID = RenderingServer.viewport_create()
	RenderingServer.viewport_set_size(vp, bounds.size.x * oversample, bounds.size.y * oversample)
	RenderingServer.viewport_set_transparent_background(vp,true)
	RenderingServer.viewport_set_clear_mode(vp, RenderingServer.VIEWPORT_CLEAR_ALWAYS)
	RenderingServer.viewport_set_update_mode(vp, RenderingServer.VIEWPORT_UPDATE_ONCE)
	RenderingServer.viewport_set_active(vp, true)
	var cv:RID = RenderingServer.canvas_create()
	RenderingServer.viewport_attach_canvas(vp,cv)
	var ci:RID = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(ci,cv)
	RenderingServer.canvas_item_set_modulate(ci, color)
	RenderingServer.canvas_item_add_polygon(ci, polygon, vertex_colors, uv, texture)
	RenderingServer.canvas_item_set_transform(ci, Transform2D.IDENTITY.translated(-bounds.position).scaled(Vector2.ONE*oversample))
	RenderingServer.canvas_item_set_visible(ci, true)
	RenderingServer.canvas_item_set_custom_rect(ci, true, bounds)
	
	await RenderingServer.frame_post_draw
	
	var img:Image = RenderingServer.texture_2d_get(RenderingServer.viewport_get_texture(vp))
	RenderingServer.free_rid(vp)
	RenderingServer.free_rid(cv)
	RenderingServer.free_rid(ci)
	
	img.resize(img.get_width()/oversample,img.get_height()/oversample, Image.INTERPOLATE_LANCZOS)
	img.generate_mipmaps()
	poly_tex = ImageTexture.create_from_image(img)
	poly_off = bounds.position + offset
	
	queue_redraw()

func _notification(what: int) -> void:
	if(what==NOTIFICATION_EDITOR_PRE_SAVE):
		_update_texture()

func _draw()->void:
	
	RenderingServer.canvas_item_clear(get_canvas_item())
	
	if(is_instance_valid(poly_tex)):
		draw_texture(poly_tex, poly_off)
