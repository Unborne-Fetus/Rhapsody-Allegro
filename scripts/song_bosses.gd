extends RefCounted
## Original song-inspired encounters. All delayed attacks are visible hazard objects.
const Hazard = preload("res://scripts/hazard.gd")
var heat := 0
var volume := 0
var recovery := 0.0
var attack_label := ""
const LABELS := {
	"fuse_chain":"FUSE CHAIN · KEEP MOVING", "velvet_trap":"VELVET TRAP · FIND THE SAFE EYE", "heartbreaker":"HEARTBREAKER · EXPANDING BLASTS",
	"ember_dash":"EMBER DASH · LEAVE THE TRAIL", "flame_fan":"FLAME FAN · FIND A LANE", "heartfire":"HEARTFIRE · WATCH THE FLOOR",
	"dancefloor":"DANCE FLOOR · DARK TILES ARE SAFE", "six_step":"SIX STEP · WATCH THE PERFORMERS", "spotlight":"SPOTLIGHT · FOLLOW THE OPEN LANE",
	"power_chord":"POWER CHORD · USE THE RING GAP", "amp_wall":"AMPLIFIER WALL · FIND THE OPENING", "stage_dive":"STAGE DIVE · CLEAR THE LANDING"
}
func tick(delta: float) -> void:
	recovery = maxf(0,recovery-delta)
func multiplier(index: int) -> float:
	return 1.2 if index == 4 and recovery>0 else 1.0
func add(game: Node2D,hazard: RefCounted) -> void:
	if game.hazards.size()<24: game.hazards.append(hazard)
func mine(game: Node2D,p: Vector2,radius: float,warning: float,duration: float = 0.32) -> void:
	var h = Hazard.new("mine",p,p,warning,duration); h.area_radius = radius; add(game,h)
func beam(game: Node2D,p: Vector2,to: Vector2,width: float,warning: float,duration: float) -> void:
	var h = Hazard.new("beam",p,to,warning,duration); h.width = width; add(game,h)
func wave(game: Node2D,p: Vector2,warning: float,gap_angle: float = 0,gap: float = 0) -> void:
	var h = Hazard.new("wave",p,p,warning,4.2)
	h.speed = 205+game.phase*26; h.width = 13; h.gap_angle = gap_angle; h.gap_width = gap; add(game,h)
func volley(game: Node2D,count: int,spread: float) -> void:
	var difficulty: Dictionary = game.RunState.DIFFICULTIES[game.run.difficulty]
	count += int(difficulty.density)
	var speed = float(game.bosses[game.boss_index].speed)*float(difficulty.speed)*(0.82+game.phase*0.10)
	var aim: float = game.boss.angle_to_point(game.aim_snapshot)
	for i in count: game.enemy_shot(game.boss,aim+(i-(count-1)/2.0)*spread,speed,7)
func destination(game: Node2D) -> Vector2:
	match game.boss_index:
		3: return game.player+Vector2(cos(game.elapsed*0.8)*220,sin(game.elapsed)*115)
		4: return game.player+game.player.direction_to(game.boss)*125
		5: return Vector2(640+sin(game.elapsed*0.65)*240,360+sin(game.elapsed)*95)
		6: return game.player+game.player.direction_to(game.boss)*175
	return game.player
func execute(game: Node2D,pattern: String) -> bool:
	if not LABELS.has(pattern): return false
	attack_label = LABELS[pattern]
	var level: int = game.phase
	var aim: Vector2 = game.aim_snapshot.clamp(Vector2(175,240),Vector2(1100,550))
	var floor_y := 560.0 if game.side else aim.y
	match pattern:
		"fuse_chain":
			# Grounded snapshots, never invisible homing after the warning.
			for i in 3+level:
				var p = Vector2(clampf(aim.x+(i-1-level/2.0)*116,175,1100),floor_y if game.side else clampf(aim.y+sin(i*1.8)*76,245,540))
				mine(game,p,62+level*4,0.9+i*0.27)
		"velvet_trap":
			var h = Hazard.new("annulus",aim,aim,1.2,0.5)
			h.inner_radius = 85; h.area_radius = 180+level*12; add(game,h)
		"heartbreaker":
			for i in 2+level:
				var p = game.boss+Vector2((i-1)*110,0)
				wave(game,p,0.8+i*0.5,game.boss.angle_to_point(aim),0.65)
		"ember_dash":
			var direction: Vector2 = game.boss.direction_to(aim)
			if game.side: direction = Vector2(-1 if aim.x<game.boss.x else 1,0)
			var end: Vector2 = (game.boss+direction*324).clamp(Vector2(160,235),Vector2(1120,550))
			beam(game,game.boss,end,27,0.7,2.0+level*0.3)
			game.charge_dir = direction; game.charge_time = 0.45
		"flame_fan":
			var angle: float = game.boss.angle_to_point(aim)
			for i in 3+level:
				var direction = Vector2.RIGHT.rotated(angle+(i-(2+level)/2.0)*0.48)
				beam(game,game.boss,game.boss+direction*1050,15,0.9+i*0.08,0.55)
		"heartfire":
			for i in 3+level:
				var p = Vector2(clampf(aim.x+(i-1)*135,170,1110),floor_y if game.side else clampf(aim.y+(i%2)*95-45,240,550))
				mine(game,p,58,0.95+i*0.18,1.15)
		"dancefloor":
			var safe_col: int = game.attack_number%6
			for col in 6:
				for row in 3:
					if col == safe_col or (col+row+game.attack_number)%2 == 0: continue
					var p = Vector2(112+col*176,220+row*118)
					if game.side: p.y = 515 # Ground tiles can be jumped over.
					if game.side and row>0: continue
					var h = Hazard.new("floor",p,p+Vector2(158,70),1.1,0.7+level*0.15); add(game,h)
		"six_step":
			for i in 6:
				var p = performer_position(i,game.side)
				var direction: Vector2 = p.direction_to(aim)
				beam(game,p,p+direction*1250,10,0.9+(i%3)*0.3,0.24)
		"spotlight":
			# One full clear column; two seconds of readable, stationary geometry.
			var safe: int = game.attack_number%5
			for i in 5:
				if i == safe: continue
				var x = 210+i*210
				beam(game,Vector2(x,190),Vector2(x,595),45,1.1,0.5)
		"power_chord":
			for i in 2+level:
				wave(game,game.boss,0.85+i*0.56,game.boss.angle_to_point(aim),0.85 if level<2 else 0.65)
		"amp_wall":
			var gap_y: float = clampf(aim.y,285,540)
			for i in 3:
				var x = 350+i*290
				beam(game,Vector2(x,182),Vector2(x,gap_y-65),17,1.0+i*0.18,0.4)
				if gap_y+65<595: beam(game,Vector2(x,gap_y+65),Vector2(x,595),17,1.0+i*0.18,0.4)
		"stage_dive":
			mine(game,aim,115,1.05,0.45)
			var direction: Vector2 = game.boss.direction_to(aim)
			if game.side: direction = Vector2(-1 if aim.x<game.boss.x else 1,0)
			game.charge_dir = direction; game.charge_time = minf(0.55,game.boss.distance_to(aim)/720.0)
	if pattern in ["heartbreaker","flame_fan","six_step","amp_wall"]: volley(game,5 if pattern == "amp_wall" else 3,0.19)
	if game.boss_index == 4:
		heat += 1
		if heat>=4:
			heat = 0; recovery = 3.8+game.charge_time; game.windup = 0; game.followup_delay = 0
			game.attack_timer = 1.0; attack_label = "OVERHEATED · DAMAGE +20%"
	if game.boss_index == 6:
		volume += 1
		if volume>=3:
			volume = 0; recovery = 3.4+game.charge_time; game.followup_delay = 0
			game.attack_timer = 1.0; attack_label = "SILENCE · CLOSE IN AND STRIKE"
	game.sound.tone([270,185,440,95][game.boss_index-3],0.13,0.10)
	return true
static func performer_position(index: int,side: bool) -> Vector2:
	if side: return Vector2(180+index*180,250)
	return [Vector2(180,260),Vector2(640,230),Vector2(1100,260),Vector2(180,535),Vector2(640,550),Vector2(1100,535)][index]

func draw_figure(g: Node2D,p: Vector2,index: int,s: float,c: Color) -> void:
	var white = Color("f2ebda")
	var dark = c.darkened(0.7)
	var swing = sin(g.total_time*3)*7
	match index:
		3: # Tuxedo crooner with a spherical fuse head, microphone and explosive cufflinks.
			g.poly_at(p,[Vector2(-25,-25),Vector2(25,-25),Vector2(30,38),Vector2(0,28),Vector2(-30,38)],s,dark)
			g.poly_at(p,[Vector2(-16,-25),Vector2(0,4),Vector2(16,-25)],s,white)
			g.poly_at(p,[Vector2(-12,-24),Vector2(0,-17),Vector2(12,-24),Vector2(12,-10),Vector2(0,-17),Vector2(-12,-10)],s,c)
			g.draw_circle(p+Vector2(0,-48)*s,21*s,c)
			g.line(p+Vector2(9,-66)*s,p+Vector2(19,-85)*s,g.GOLD,3*s)
			g.draw_circle(p+Vector2(20,-87)*s,(4+sin(g.total_time*4))*s,g.GOLD)
			g.line(p+Vector2(23,-10)*s,p+Vector2(54,-20+swing)*s,c,5*s)
			g.line(p+Vector2(54,-20+swing)*s,p+Vector2(54,-49+swing)*s,white,3*s)
			g.draw_circle(p+Vector2(54,-52+swing)*s,7*s,white)
			for x in [-17,17]: g.line(p+Vector2(x,30)*s,p+Vector2(x,55)*s,c,6*s)
		4: # White stage suit, flame crown and blazing cape.
			g.poly_at(p,[Vector2(-18,-26),Vector2(20,-26),Vector2(56,48),Vector2(0,28),Vector2(-52,48)],s,c.darkened(.3))
			g.poly_at(p,[Vector2(-22,-26),Vector2(22,-26),Vector2(20,34),Vector2(-20,34)],s,white)
			g.poly_at(p,[Vector2(-14,-24),Vector2(0,3),Vector2(14,-24)],s,dark)
			g.draw_circle(p+Vector2(0,-46)*s,17*s,white)
			g.poly_at(p,[Vector2(-17,-52),Vector2(-9,-77),Vector2(2,-60),Vector2(16,-83),Vector2(20,-52)],s,c)
			for sign_x in [-1,1]:
				g.line(p+Vector2(sign_x*22,-12)*s,p+Vector2(sign_x*51,8+swing)*s,white,6*s)
				g.line(p+Vector2(sign_x*12,30)*s,p+Vector2(sign_x*23,59)*s,white,8*s)
			for i in 4: g.draw_circle(p+Vector2(0,i*9)*s,2*s,c)
		5: # Mirror-ball ringmaster surrounded by six spectral performers in the arena.
			g.draw_circle(p+Vector2(0,-40)*s,26*s,c)
			for x in [-12,0,12]: g.line(p+Vector2(x,-62)*s,p+Vector2(x,-18)*s,white,1*s)
			for y in [-52,-40,-28]: g.line(p+Vector2(-22,y)*s,p+Vector2(22,y)*s,white,1*s)
			g.poly_at(p,[Vector2(-20,-10),Vector2(20,-10),Vector2(32,38),Vector2(-32,38)],s,dark)
			for sign_x in [-1,1]:
				g.line(p+Vector2(sign_x*20,0)*s,p+Vector2(sign_x*56,-35+sign_x*swing)*s,c,5*s)
				g.line(p+Vector2(sign_x*13,30)*s,p+Vector2(sign_x*30,58)*s,c,7*s)
			g.draw_circle(p+Vector2(0,10)*s,8*s,g.GOLD)
		6: # Masked speaker-armored giant with an angular guitar.
			g.poly_at(p,[Vector2(-32,-28),Vector2(32,-28),Vector2(38,32),Vector2(-38,32)],s,dark)
			for sign_x in [-1,1]:
				g.draw_rect(Rect2(p+Vector2(sign_x*42-15,-25)*s,Vector2(30,53)*s),c)
				g.draw_circle(p+Vector2(sign_x*42,0)*s,11*s,g.INK)
				g.draw_circle(p+Vector2(sign_x*42,0)*s,6*s,white,false,2*s,true)
				g.line(p+Vector2(sign_x*20,30)*s,p+Vector2(sign_x*30,62)*s,c,9*s)
			g.poly_at(p,[Vector2(-19,-58),Vector2(19,-58),Vector2(22,-35),Vector2(0,-25),Vector2(-22,-35)],s,white)
			g.line(p+Vector2(-13,-46)*s,p+Vector2(-4,-41)*s,dark,3*s)
			g.line(p+Vector2(4,-41)*s,p+Vector2(13,-46)*s,dark,3*s)
			g.poly_at(p,[Vector2(-25,6),Vector2(5,-3),Vector2(27,28),Vector2(2,19),Vector2(-14,31)],s,c)
			g.line(p+Vector2(0,12)*s,p+Vector2(57,-43)*s,g.GOLD,5*s)

func draw_arena(g: Node2D,index: int,c: Color) -> void:
	var faint = Color(c,0.12)
	match index:
		3:
			for x in [125,1140]:
				for i in 8: g.draw_rect(Rect2(x,178+i*52,15,40),faint)
			for i in 7: g.draw_arc(Vector2(640,175),110+i*64,0,PI,45,faint,2,true)
		4:
			for i in 14:
				var x = 115+i*79
				g.poly_at(Vector2(x,598),[Vector2(0,0),Vector2(17,-35-10*sin(i+g.elapsed)),Vector2(33,0)],1,faint)
			g.draw_circle(Vector2(640,365),145,faint,false,3,true)
		5:
			for x in 12:
				for y in 5:
					g.draw_rect(Rect2(110+x*89,177+y*82,76,66),Color(Color.from_hsv(float((x+y)%6)/6,.5,.8),.07))
			for i in 6:
				var p = performer_position(i,g.side)
				var tint = Color.from_hsv(float(i)/6,.4,.9)
				g.draw_circle(p+Vector2(0,-18),8,Color(tint,.45))
				g.line(p+Vector2(0,-8),p+Vector2(0,15),Color(tint,.35),5)
				g.line(p+Vector2(-18,-8),p+Vector2(18,3),Color(tint,.35),3)
				g.line(p+Vector2(0,15),p+Vector2(-10,28),Color(tint,.35),3)
				g.line(p+Vector2(0,15),p+Vector2(10,28),Color(tint,.35),3)
		6:
			for x in [130,1110]:
				g.draw_rect(Rect2(x,225,40,325),faint)
				for i in 4: g.draw_circle(Vector2(x+20,260+i*80),16,Color(c,.2),false,3,true)
			for i in 12:
				var x = 220+i*72
				g.line(Vector2(x,598),Vector2(x,570-absf(sin(i+g.elapsed*2))*55),faint,10)
