extends Node2D
## Render area attacks inside a clipped arena layer so warnings never cover the HUD.
var game: Node2D
func _process(_delta: float) -> void:
	visible = game.screen == "playing"
	queue_redraw()
func _draw() -> void:
	if game.screen != "playing": return
	draw_weapon_ranges()
	var color = Color(game.bosses[game.boss_index].color)
	for hazard in game.hazards:
		var active: bool = hazard.active()
		var c = color if active else Color("e8c575")
		var alpha = 0.75 if active else 0.4
		match hazard.kind:
			"beam":
				draw_line(hazard.origin,hazard.target,Color(c,0.17 if active else 0.1),hazard.width*2+12,true)
				draw_line(hazard.origin,hazard.target,Color(c,alpha),hazard.width*2 if active else 2,true)
				if active: draw_line(hazard.origin,hazard.target,Color("f2ebda",0.6),3,true)
			"mine":
				draw_circle(hazard.origin,hazard.area_radius,Color(c,0.2 if active else 0.04))
				draw_circle(hazard.origin,hazard.area_radius,Color(c,alpha),false,3,true)
				if not active:
					draw_arc(hazard.origin,hazard.area_radius+5,-PI/2,-PI/2+TAU*clampf(hazard.age/hazard.warning,0,1),32,Color("e8c575"),2,true)
					draw_string(game.font,hazard.origin+Vector2(-4,5),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("e8c575"))
			"wave":
				var radius = hazard.radius if active else 56.0
				draw_circle(hazard.origin,radius,Color(c,alpha),false,10 if active else 2,true)
				if active: draw_circle(hazard.origin,maxf(1,radius-8),Color(c,0.18),false,4,true)

func draw_weapon_ranges() -> void:
	var weapon: Dictionary = game.Arsenal.SETS[game.weapon_index]
	var c = Color(weapon.color)
	if game.training and game.range_guides:
		draw_circle(game.player,float(weapon.melee_range[0]),Color(c,0.24),false,1.5,true)
		draw_circle(game.player,float(weapon.range),Color(c,0.13),false,2,true)
		draw_line(game.player,game.player+game.facing*float(weapon.range),Color(c,0.1),1,true)
	if game.melee_windup>0 and not game.active_melee.is_empty():
		var attack: Dictionary = game.active_melee
		var angle: float = attack.facing.angle()
		draw_arc(game.player,float(attack.reach),angle-float(attack.arc),angle+float(attack.arc),30,Color(Color(attack.color),0.16),2,true)
		var progress = 1.0-game.melee_windup/float(attack.windup[int(attack.step)-1])
		draw_arc(game.player,25,-PI/2,-PI/2+TAU*progress,25,Color(attack.color),2,true)
	if game.melee_flash>0 and not game.active_melee.is_empty():
		var attack: Dictionary = game.active_melee
		var alpha = clampf(game.melee_flash/float(attack.flash),0,1)
		var aim: Vector2 = attack.facing
		var angle = aim.angle()
		var reach = float(attack.reach)
		var tint = Color(Color(attack.color),alpha*0.8)
		if attack.shape == "spear":
			draw_line(game.player+aim*20,game.player+aim*reach,tint,4,true)
			draw_line(game.player+aim*(reach-15)+aim.orthogonal()*8,game.player+aim*reach,tint,3,true)
			draw_line(game.player+aim*(reach-15)-aim.orthogonal()*8,game.player+aim*reach,tint,3,true)
		else:
			draw_arc(game.player,reach,angle-float(attack.arc),angle+float(attack.arc),32,tint,10 if attack.shape == "hammer" else 4,true)
			if attack.shape == "knives": draw_arc(game.player,reach-12,angle-0.6,angle+0.9,25,Color(Color(attack.color),alpha*0.35),3,true)
