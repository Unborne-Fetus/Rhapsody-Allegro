extends Node2D
## Render area attacks inside a clipped arena layer so warnings never cover the HUD.
var game: Node2D
func _process(_delta: float) -> void:
	visible = game.screen == "playing"
	queue_redraw()
func _draw() -> void:
	if game.screen != "playing": return
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
				draw_circle(hazard.origin,55,Color(c,0.2 if active else 0.04))
				draw_circle(hazard.origin,55,Color(c,alpha),false,3,true)
				if not active:
					draw_arc(hazard.origin,60,-PI/2,-PI/2+TAU*clampf(hazard.age/hazard.warning,0,1),32,Color("e8c575"),2,true)
					draw_string(game.font,hazard.origin+Vector2(-4,5),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("e8c575"))
			"wave":
				var radius = hazard.radius if active else 56.0
				draw_circle(hazard.origin,radius,Color(c,alpha),false,10 if active else 2,true)
				if active: draw_circle(hazard.origin,maxf(1,radius-8),Color(c,0.18),false,4,true)
