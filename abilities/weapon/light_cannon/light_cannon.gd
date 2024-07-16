extends AutoFireAbility

var damage:Stat = Stat.new(10, 0, INF)
var projectile_count:Stat = Stat.new(1, 1, INF, Stat.PERIODIC)
var projectile_speed:Stat = Stat.new(1000, 0, INF)
var projectile_size:Stat = Stat.new(8, 1, INF)

const proj_spacing:float = 0.5

func _on_fired() -> void:
	var proj_count:int = projectile_count.get_value()
	
	var mpos:Vector2 = get_parent().get_muzzle_position()
	var mdir:Vector2 = get_parent().get_muzzle_direction()
	
	var tot_width:float = proj_count * projectile_size.get_value() + (proj_count-1) * projectile_size.get_value() * proj_spacing
	var p0:Vector2 = mpos - mdir.orthogonal() * (tot_width/2 - projectile_size.get_value()/2)
	var dp:Vector2 = mdir.orthogonal() * projectile_size.get_value() * (1+proj_spacing)
	
	for n:int in range(proj_count):
		var bullet:Projectile = preload("res://abilities/weapon/light_cannon/light_cannon_projectile.tscn").instantiate()
		bullet.global_position = p0 + dp*n
		
		bullet.linear_velocity = projectile_speed.get_value() * mdir + get_parent().linear_velocity
		bullet.source = get_parent()
		bullet.damage_amount = damage.get_value()
		bullet.scale = Vector2.ONE * projectile_size.get_value()/8
		await get_tree().process_frame
		get_tree().current_scene.add_child(bullet)
