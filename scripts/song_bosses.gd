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
	"downpour":"DOWNPOUR · CLEAR THE LANDINGS", "thunder_clap":"THUNDERCLAP · CROSS BETWEEN CUES", "eye_storm":"STORM EYE · FIND SHELTER",
	"audition":"AUDITION · LEAVE THE SPOTLIGHT", "star_run":"STAR RUN · CLEAR THE PATH", "curtain_call":"CURTAIN CALL · FIND THE AISLE",
	"piano_keys":"PIANO KEYS · READ THE DARK NOTES", "spell_circle":"SPELL CIRCLE · INSIDE OR OUTSIDE", "blue_note":"BLUE NOTE · CROSS BETWEEN CHORDS",
	"vinyl_cut":"VINYL CUT · FOLLOW THE RECORD GAP", "disco_spell":"DISCO SPELL · STEP BETWEEN SEALS", "bassline":"BASS LINE · DODGE THE SEQUENCE",
	"drumline":"DRUMLINE · FOLLOW THE OPEN LANE", "crossfire":"CROSSFIRE · WAIT FOR THE RESPONSE", "ceasefire":"FINAL CALL · CLEAR THE BLAST",
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
		7: return Vector2(640+sin(game.elapsed*.7)*265,game.player.y-30)
		8: return game.player+Vector2(cos(game.elapsed)*200,sin(game.elapsed)*100)
		9: return Vector2(820+sin(game.elapsed*.4)*130,370)
		10: return Vector2(640+cos(game.elapsed*.7)*235,360+sin(game.elapsed*.7)*115)
		11: return game.player+game.player.direction_to(game.boss)*210
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
		"downpour":
			var safe: int = game.attack_number%6
			for i in 6:
				if i == safe: continue
				var p = Vector2(190+i*178,floor_y if game.side else 290+(i%2)*190)
				mine(game,p,66+level*4,1.0+(i%3)*0.25,0.45)
		"thunder_clap":
			for i in 2+level:
				var x: float = clampf(aim.x+(i-1)*145,170,1110)
				beam(game,Vector2(x,180),Vector2(x,595),22,0.9+i*.38,.3)
		"eye_storm":
			var h = Hazard.new("annulus",aim,aim,1.3,.6)
			h.inner_radius = 95; h.area_radius = 260; add(game,h)
			wave(game,game.boss,1.0,game.boss.angle_to_point(aim),.95)
		"audition":
			# Two spotlights cross a frozen target; the warning never tracks you.
			beam(game,Vector2(110,aim.y),Vector2(1170,aim.y),20,1.15,.35)
			beam(game,Vector2(aim.x,180),Vector2(aim.x,595),20,1.45,.35)
		"star_run":
			var direction: Vector2 = game.boss.direction_to(aim)
			if game.side: direction = Vector2(-1 if aim.x<game.boss.x else 1,0)
			beam(game,game.boss,game.boss+direction*400,35,.85,.5)
			mine(game,aim,92,1.45,.35)
			game.charge_dir = direction; game.charge_time = .5
		"curtain_call":
			var safe: int = game.attack_number%5
			for i in 5:
				if i == safe: continue
				var x = 135+i*210
				var h = Hazard.new("floor",Vector2(x,510 if game.side else 190),Vector2(x+145,595),1.2,.6)
				add(game,h)
		"piano_keys":
			for i in 8:
				if (i+game.attack_number)%3 == 0: continue
				var x = 116+i*130
				var h = Hazard.new("floor",Vector2(x,520 if game.side else 215),Vector2(x+94,595),1.05+(i%2)*.35,.38)
				add(game,h)
		"spell_circle":
			for i in 2:
				var p = (aim+Vector2((i*2-1)*130,0)).clamp(Vector2(210,260),Vector2(1070,535))
				if game.side: p.y = 560
				var h = Hazard.new("annulus",p,p,1.2+i*.55,.4)
				h.inner_radius = 70; h.area_radius = 155+level*10; add(game,h)
		"blue_note":
			for i in 3+level:
				var y = 240+i*68
				beam(game,Vector2(125,y),Vector2(1155,y),12,1.0+i*.3,.25)
		"vinyl_cut":
			for i in 2+level:
				wave(game,game.boss,.9+i*.65,game.boss.angle_to_point(aim)+sin(i)*.3,.95)
		"disco_spell":
			for i in 4+level:
				var angle = TAU*i/(4+level)
				var p = (aim+Vector2.RIGHT.rotated(angle)*145).clamp(Vector2(175,240),Vector2(1100,550))
				if game.side: p.y = 560
				mine(game,p,50,1.1+i*.12,.5)
		"bassline":
			for i in 4:
				var x = 240+i*230
				beam(game,Vector2(x,190),Vector2(x,595),28,1.0+i*.4,.26)
		"drumline":
			var safe: int = game.attack_number%6
			for i in 6:
				if i == safe: continue
				var x = 180+i*180
				beam(game,Vector2(x,190),Vector2(x,595),28,1.0+(i%3)*.3,.3)
		"crossfire":
			for i in 2+level:
				var p = Vector2(140 if i%2 == 0 else 1140,230+i*85)
				beam(game,p,aim,18,1.1+i*.4,.3)
		"ceasefire":
			mine(game,aim,125,1.3,.4)
			wave(game,game.boss,1.0,game.boss.angle_to_point(aim),1.1)
			recovery = 2.8; game.followup_delay = 0; game.attack_timer = 1.0
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
	game.sound.tone(float(game.bosses[game.boss_index].get("tone",220)),0.13,0.10)
	return true
static func performer_position(index: int,side: bool) -> Vector2:
	if side: return Vector2(180+index*180,250)
	return [Vector2(180,260),Vector2(640,230),Vector2(1100,260),Vector2(180,535),Vector2(640,550),Vector2(1100,535)][index]

# Small, hand-drawn stage portraits: actual skin, hair and period costumes.
# Accent colors belong to the encounter effects, never to the performer's face.
func person(g: Node2D,p: Vector2,s: float,skin: Color,coat: Color,hair: Color,style: String) -> void:
	var white = Color("f9eedc")
	var ink = Color("17121c")
	var sway = sin(g.total_time*3)*3
	# Legs, shoes, tailored torso and neck.
	for sign_x in [-1,1]:
		g.poly_at(p,[Vector2(sign_x*3,22),Vector2(sign_x*20,22),Vector2(sign_x*24,60),Vector2(sign_x*9,60)],s,coat.darkened(.3))
		g.line(p+Vector2(sign_x*17,61)*s,p+Vector2(sign_x*29,61)*s,ink,7*s)
	g.poly_at(p,[Vector2(-23,-23),Vector2(23,-23),Vector2(26,29),Vector2(-26,29)],s,coat)
	g.draw_rect(Rect2(p+Vector2(-7,-32)*s,Vector2(14,17)*s),skin.darkened(.1))
	if style in ["curl","afro","long","dance"]:
		var wide = 27 if style == "long" else 25
		for i in 11:
			var a = PI+TAU*i/11.0
			var hp = p+Vector2(cos(a)*wide,-48+sin(a)*27)*s
			g.draw_circle(hp,10*s,hair)
		if style == "long":
			g.draw_rect(Rect2(p+Vector2(-32,-50)*s,Vector2(64,45)*s),hair)
	# Ears and face retain their own silhouette inside the hair.
	for sign_x in [-1,1]: g.draw_circle(p+Vector2(sign_x*17,-45)*s,5*s,skin.darkened(.1))
	g.draw_circle(p+Vector2(0,-48)*s,18*s,skin)
	g.poly_at(p,[Vector2(-14,-46),Vector2(14,-46),Vector2(11,-28),Vector2(0,-24),Vector2(-11,-28)],s,skin)
	if style in ["short","silver","cop"]:
		g.draw_arc(p+Vector2(0,-49)*s,18*s,PI,TAU,18,hair,8*s,true)
		for sign_x in [-1,1]: g.line(p+Vector2(sign_x*17,-52)*s,p+Vector2(sign_x*16,-40)*s,hair,4*s)
	if style == "pompadour":
		g.poly_at(p,[Vector2(-19,-48),Vector2(-21,-63),Vector2(-11,-77),Vector2(15,-76),Vector2(25,-65),Vector2(19,-51),Vector2(9,-60),Vector2(-10,-59)],s,hair)
		for x in [-17,17]: g.line(p+Vector2(x,-53)*s,p+Vector2(x,-32)*s,hair,5*s)
	if style == "wrap":
		g.poly_at(p,[Vector2(-21,-46),Vector2(-24,-67),Vector2(-12,-81),Vector2(15,-78),Vector2(23,-60),Vector2(19,-45),Vector2(10,-63),Vector2(-10,-62)],s,Color("d7a54b"))
		g.line(p+Vector2(-16,-70)*s,p+Vector2(14,-65)*s,white,2*s)
	for x in [-7,7]:
		g.line(p+Vector2(x-3,-48)*s,p+Vector2(x+3,-49)*s,ink,2*s)
		g.draw_circle(p+Vector2(x,-45)*s,1.7*s,ink)
	g.line(p+Vector2(1,-44)*s,p+Vector2(3,-37)*s,skin.darkened(.35),1.6*s)
	g.line(p+Vector2(-5,-32)*s,p+Vector2(5,-33)*s,Color("793f42"),2*s)
	# Right hand holds a silver microphone, with animated performance gesture.
	g.line(p+Vector2(21,-14)*s,p+Vector2(40,-4-sway)*s,coat,8*s)
	g.line(p+Vector2(40,-4-sway)*s,p+Vector2(43,-34)*s,skin,5*s)
	g.line(p+Vector2(43,-33)*s,p+Vector2(42,-48)*s,ink,4*s)
	g.draw_circle(p+Vector2(42,-49)*s,5*s,Color("c5d2d5"))
	g.line(p+Vector2(-21,-13)*s,p+Vector2(-40,8+sway)*s,coat,8*s)
	g.draw_circle(p+Vector2(-41,10+sway)*s,4*s,skin)

func village_member(g: Node2D,p: Vector2,s: float,role: int) -> void:
	var skins = [Color("8e5638"),Color("ad744b"),Color("c98b64"),Color("a86842"),Color("9c6244"),Color("bd825b")]
	var clothes = [Color("253f70"),Color("5d382d"),Color("d19c43"),Color("3b4050"),Color("df9c32"),Color("507048")]
	person(g,p,s,skins[role],clothes[role],Color("241a18"),"cop" if role == 0 else "short")
	match role:
		0: # Police cap, badge and mustache.
			g.draw_rect(Rect2(p+Vector2(-23,-76)*s,Vector2(46,15)*s),clothes[0])
			g.line(p+Vector2(-25,-60)*s,p+Vector2(23,-60)*s,Color("11141c"),5*s)
			g.draw_circle(p+Vector2(-9,-10)*s,4*s,g.GOLD)
		1: # Cowboy hat and fringed vest.
			g.draw_rect(Rect2(p+Vector2(-19,-83)*s,Vector2(38,22)*s),Color("b08b53"))
			g.line(p+Vector2(-33,-61)*s,p+Vector2(33,-61)*s,Color("d0a56a"),6*s)
		2: # Feathered stage headdress.
			for i in 7:
				var v = Vector2.RIGHT.rotated(PI+PI*i/6.0)
				g.line(p+Vector2(0,-62)*s,p+(Vector2(0,-62)+v*42)*s,Color("ede3cd") if i%2 else Color("df6751"),5*s)
		3: # Leather biker cap and vest.
			g.draw_arc(p+Vector2(0,-62)*s,24*s,PI,TAU,16,Color("171a23"),10*s,true)
			g.line(p+Vector2(-17,-18)*s,p+Vector2(-9,24)*s,g.PAPER,2*s)
		4: # Construction helmet and overall straps.
			g.draw_arc(p+Vector2(0,-62)*s,23*s,PI,TAU,16,Color("ffc84c"),11*s,true)
			for x in [-12,12]: g.line(p+Vector2(x,-20)*s,p+Vector2(x,28)*s,Color("416180"),7*s)
		5: # Military cap and shoulder stripes.
			g.draw_rect(Rect2(p+Vector2(-22,-76)*s,Vector2(44,15)*s),clothes[5])
			g.line(p+Vector2(-22,-10)*s,p+Vector2(-7,-10)*s,g.GOLD,3*s)
	g.line(p+Vector2(-6,-35)*s,p+Vector2(6,-35)*s,Color("2a1d19"),3*s)

func draw_figure(g: Node2D,p: Vector2,index: int,s: float,c: Color) -> void:
	var light = Color("dba47e")
	var brown = Color("9d6144")
	var dark = Color("21191c")
	match index:
		3: # Tom Jones: silver curls, goatee, open shirt, dark stage suit.
			person(g,p,s,light,Color("242330"),Color("c5c1ba"),"silver")
			g.poly_at(p,[Vector2(-13,-23),Vector2(0,8),Vector2(13,-23)],s,light)
			g.draw_arc(p+Vector2(0,-33)*s,10*s,0,PI,12,Color("d3ccc4"),4*s,true)
			g.draw_arc(p+Vector2(0,-57)*s,20*s,PI,TAU,14,Color("ece2cc"),4*s,true)
			g.draw_circle(p+Vector2(0,-1)*s,3*s,g.GOLD)
		4: # Elvis: pompadour, sideburns, white flared suit and jeweled belt.
			person(g,p,s,light,Color("f9eedb"),dark,"pompadour")
			g.poly_at(p,[Vector2(-14,-24),Vector2(0,5),Vector2(14,-24)],s,light)
			for x in [-21,21]: g.poly_at(p,[Vector2(x,36),Vector2(x-10,62),Vector2(x+13,62)],s,Color("f9eedb"))
			g.line(p+Vector2(-23,20)*s,p+Vector2(23,20)*s,g.GOLD,6*s)
			for i in 4:
				for x in [-14,14]: g.draw_circle(p+Vector2(x,-12+i*8)*s,2*s,c)
		5:
			village_member(g,p,s,0)
		6: # Quiet Riot's Kevin DuBrow: long brown curls, vest and striped trousers.
			person(g,p,s,light,Color("301d24"),Color("745034"),"long")
			g.poly_at(p,[Vector2(-10,-24),Vector2(0,18),Vector2(10,-24)],s,light)
			for x in [-20,-13,-6,7,14,21]: g.line(p+Vector2(x,29)*s,p+Vector2(x,58)*s,Color("ece4dc") if x%2 else Color("de554c"),3*s)
		7: # The Weather Girls: two distinct singers, cloud-white and blue gowns.
			for i in 2:
				var at = p+Vector2(-29 if i == 0 else 29,0)*s
				var dress = Color("3879ae") if i == 0 else Color("e4d9ed")
				person(g,at,s*.77,Color("865033") if i == 0 else Color("a56947"),dress,dark,"curl")
				g.poly_at(at,[Vector2(-18,-13),Vector2(18,-13),Vector2(34,55),Vector2(-34,55)],s*.77,dress)
				g.line(at+Vector2(-18,-11)*s*.77,at+Vector2(18,-11)*s*.77,g.GOLD,2*s)
		8: # Irene Cara: 1980s dancer silhouette, abundant dark curls, pink stagewear.
			person(g,p,s,Color("b67d58"),Color("ee76a8"),Color("352320"),"dance")
			g.draw_rect(Rect2(p+Vector2(-23,12)*s,Vector2(46,12)*s),Color("32233e"))
			for x in [-17,17]: g.line(p+Vector2(x,40)*s,p+Vector2(x,58)*s,Color("bf8ac7"),9*s)
			g.line(p+Vector2(-21,-63)*s,p+Vector2(19,-63)*s,Color("e661a4"),4*s)
		9: # Nina Simone: high wrapped headpiece, gold earrings, regal evening gown.
			person(g,p,s,Color("75432e"),Color("36305c"),dark,"wrap")
			g.poly_at(p,[Vector2(-20,-17),Vector2(20,-17),Vector2(37,58),Vector2(-37,58)],s,Color("44335f"))
			for x in [-21,21]: g.draw_circle(p+Vector2(x,-33)*s,5*s,g.GOLD,false,2*s,true)
			g.draw_arc(p+Vector2(0,-23)*s,15*s,0,PI,15,g.GOLD,3*s,true)
		10: # Eddie Johns: 1970s afro, sunglasses and gold disco tailoring.
			person(g,p,s,brown,Color("b87832"),dark,"afro")
			for x in [-8,8]: g.draw_rect(Rect2(p+Vector2(x-6,-50)*s,Vector2(12,8)*s),Color("171b22"))
			g.line(p+Vector2(-3,-47)*s,p+Vector2(3,-47)*s,g.GOLD,2*s)
			g.poly_at(p,[Vector2(-13,-23),Vector2(0,6),Vector2(13,-23)],s,Color("f2d29e"))
			g.line(p+Vector2(-9,-35)*s,p+Vector2(9,-35)*s,dark,3*s)
		11: # Edwin Starr: close natural hair, mustache, olive soul-stage suit.
			person(g,p,s,Color("945c3e"),Color("69683e"),dark,"short")
			g.line(p+Vector2(-8,-35)*s,p+Vector2(8,-35)*s,dark,3*s)
			g.poly_at(p,[Vector2(-15,-25),Vector2(0,1),Vector2(15,-25)],s,Color("eddbb2"))
			for x in [-22,22]:
				for y in 4: g.line(p+Vector2(x,-15+y*5)*s,p+Vector2(x+7,-12+y*5)*s,g.GOLD,2*s)

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
				village_member(g,p,.32,i)
		6:
			for x in [130,1110]:
				g.draw_rect(Rect2(x,225,40,325),faint)
				for i in 4: g.draw_circle(Vector2(x+20,260+i*80),16,Color(c,.2),false,3,true)
			for i in 12:
				var x = 220+i*72
				g.line(Vector2(x,598),Vector2(x,570-absf(sin(i+g.elapsed*2))*55),faint,10)

		7:
			for i in 9:
				var x = 155+i*120
				g.draw_circle(Vector2(x,200),35,faint)
				g.line(Vector2(x,240),Vector2(x-25,275),faint,3)
			# Landings have falling human silhouettes during their warning.
			for h in g.hazards:
				if h.kind != "mine" or h.active(): continue
				var p = h.origin-Vector2(0,180*clampf(1-h.age/h.warning,0,1))
				g.draw_circle(p-Vector2(0,20),8,Color(c,.6))
				g.line(p-Vector2(0,10),p+Vector2(0,10),Color(c,.6),4)
				g.line(p+Vector2(0,10),p+Vector2(-10,25),Color(c,.6),3)
				g.line(p+Vector2(0,10),p+Vector2(10,25),Color(c,.6),3)
		8:
			for i in 7:
				var p = Vector2(175+i*155,580)
				g.poly_at(p,[Vector2(0,-24),Vector2(7,-7),Vector2(25,-5),Vector2(12,7),Vector2(15,25),Vector2(0,15),Vector2(-15,25),Vector2(-12,7),Vector2(-25,-5),Vector2(-7,-7)],1,faint)
		9:
			for i in 16:
				g.draw_rect(Rect2(115+i*65,185,58,60),faint)
				if i%7 in [0,1,3,4,5]: g.draw_rect(Rect2(154+i*65,185,22,38),Color(c,.18))
		10:
			for i in 5: g.draw_circle(Vector2(640,380),55+i*36,faint,false,2,true)
			g.line(Vector2(1060,210),Vector2(820,350),faint,8)
		11:
			for i in 10:
				var x = 145+i*108
				g.poly_at(Vector2(x,588),[Vector2(-18,0),Vector2(0,-17),Vector2(18,0)],1,faint)
