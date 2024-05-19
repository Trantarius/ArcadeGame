class_name ActorSubBody
extends RigidBody2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	custom_integrator=true
	contact_monitor = true
	max_contacts_reported = 32
	global_transform = get_parent().global_transform

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var parent:Actor = get_parent().get_parent()
	
	state.transform = get_parent().global_transform
	state.linear_velocity = parent.linear_velocity + get_parent().position.normalized().orthogonal() * parent.angular_velocity
	state.angular_velocity = parent.angular_velocity
	
	for c:int in state.get_contact_count():
		parent.apply_force(state.get_contact_impulse(c), state.get_contact_local_position(c)  - (global_position - parent.global_position))
		
	PhysicsServer2D.body_set_param(get_rid(), PhysicsServer2D.BODY_PARAM_MASS, 
		PhysicsServer2D.body_get_param(parent.get_rid(), PhysicsServer2D.BODY_PARAM_MASS))
	PhysicsServer2D.body_set_param(get_rid(), PhysicsServer2D.BODY_PARAM_INERTIA, 
		PhysicsServer2D.body_get_param(parent.get_rid(), PhysicsServer2D.BODY_PARAM_INERTIA))
	PhysicsServer2D.body_set_param(get_rid(), PhysicsServer2D.BODY_PARAM_CENTER_OF_MASS, 
		PhysicsServer2D.body_get_param(parent.get_rid(), PhysicsServer2D.BODY_PARAM_CENTER_OF_MASS))
