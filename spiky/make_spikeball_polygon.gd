@tool
extends EditorScript

const outer_radius:float = 15
const middle_radius:float = 10
const inner_radius:float = 5
const spokes:int = 3

# Called when the script is executed (using File -> Run in Script Editor).
func _run() -> void:
	var points:PackedVector2Array = []
	var theta:float = TAU/(spokes*4)
	
	for n in range(spokes):
		points.push_back(Vector2(outer_radius,0).rotated((4*n)*theta))
		points.push_back(Vector2(inner_radius,0).rotated((4*n+1)*theta))
		points.push_back(Vector2(middle_radius,0).rotated((4*n+2)*theta))
		points.push_back(Vector2(inner_radius,0).rotated((4*n+3)*theta))
	
	var selections:Array[Node] = get_editor_interface().get_selection().get_selected_nodes()
	if(selections.size()==1):
		var node:Node = selections[0]
		if(node is CollisionPolygon2D || node is Polygon2D):
			node.polygon = points
			return
	
	printerr("nowhere to put polygon")
