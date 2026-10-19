extends RefCounted
## Touch-first presentation. Arena simulation and all combat rules remain shared.
var portrait := false
var character_focus := 2
var boss_focus := 0
var help_page := 0
func size() -> Vector2:
	return Vector2(720,1280) if portrait else Vector2(1280,720)
func controls(g: Node2D) -> Array:
	var items: Array
	if portrait:
		items = [[Vector2(565,1060),"dodge","DODGE",88.0],[Vector2(424,916),"shoot","ABILITY",76.0],[Vector2(620,866),"parry","PARRY",65.0],[Vector2(425,1163),"burst","BREAK",65.0]]
		if g.side: items.append([Vector2(615,1210),"jump","JUMP",53.0])
		if not g.profile.data.auto_attack: items.append([Vector2(575,708),"melee","STRIKE",65.0])
	else:
		items = [[Vector2(1110,551),"dodge","DODGE",68.0],[Vector2(971,448),"shoot","ABILITY",59.0],[Vector2(1165,394),"parry","PARRY",55.0],[Vector2(949,619),"burst","BREAK",53.0]]
		if g.side: items.append([Vector2(814,534),"jump","JUMP",51.0])
		if not g.profile.data.auto_attack: items.append([Vector2(835,380),"melee","STRIKE",52.0])
	return items
func stick_home() -> Vector2:
	return Vector2(160,1060) if portrait else Vector2(205,540)
func pause_rect() -> Rect2:
	return Rect2(586,20,108,92) if portrait else Rect2(1130,22,110,92)
func auto_rect() -> Rect2:
	return Rect2(32,764,235,92) if portrait else Rect2(38,610,260,92)
func heading(g: Node2D,title: String,sub: String = "") -> void:
	g.text_at("R / A · THUMB CONTROLS",Vector2(32,40),19,g.TEAL)
	g.wrapped_text(title,Vector2(32,94),size().x-64,32,g.PAPER)
	if not sub.is_empty(): g.wrapped_text(sub,Vector2(32,132),size().x-64,21,g.MUTED)
func button(g: Node2D,label: String,rect: Rect2,action: String,primary: bool = false) -> void:
	if rect.size.y<92: rect = Rect2(rect.position-Vector2(0,(92-rect.size.y)/2),Vector2(rect.size.x,92))
	g.buttons.append({"rect":rect,"action":action})
	g.draw_style_box(g.panel_style(g.TEAL if primary else Color("202b37"),g.TEAL if primary else Color("52616e")),rect)
	var fontsize = 26 if portrait else 25
	var width = g.font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,fontsize).x
	g.text_at(label,rect.position+Vector2((rect.size.x-width)/2,rect.size.y/2+9),fontsize,g.INK if primary else g.PAPER)
func actions(g: Node2D,items: Array,top: float = 310) -> void:
	for i in items.size():
		var rect = Rect2(32,top+i*105,656,88) if portrait else Rect2(64+(i%2)*604,top+(i/2)*99,548,82)
		button(g,items[i][0],rect,items[i][1],i == 0)
func card(g: Node2D) -> Rect2:
	var rect = Rect2(32,180,656,310) if portrait else Rect2(56,178,610,330)
	g.draw_style_box(g.panel_style(Color("14212c"),Color("52616e")),rect)
	return rect
func draw_character(g: Node2D,index: int,rect: Rect2) -> void:
	var c: Dictionary = g.Characters.ROSTER[index]
	var x = rect.position.x+24; var y = rect.position.y+40
	g.text_at(c.name+" / "+g.Arsenal.SETS[index].name,Vector2(x,y),29,Color(g.Arsenal.SETS[index].color))
	g.text_at("%d HP · %s" % [c.health,c.ability],Vector2(x,y+40),23,g.TEAL)
	var next = g.wrapped_text(c.ability_text,Vector2(x,y+77),rect.size.x-48,22)
	next = g.wrapped_text(c.passive,Vector2(x,next+12),rect.size.x-48,21,g.TEAL)
	g.wrapped_text(c.debuff,Vector2(x,next+12),rect.size.x-48,21,g.CORAL)
func draw_menu(g: Node2D) -> void:
	match g.screen:
		"title":
			heading(g,"RHAPSODY: ALLEGRO","Two thumbs. One performance.")
			g.wrapped_text("Left thumb moves. Right thumb dodges and uses skills. Basic attacks can happen automatically.",Vector2(40,218),size().x-80,25,g.MUTED)
			var items = [["PLAY TUTORIAL","tutorial"],["NEW PERFORMANCE","start"],["CONTINUE" if not g.profile.data.checkpoint.is_empty() else "BOSS PRACTICE","continue_run" if not g.profile.data.checkpoint.is_empty() else "select"],["CHARACTERS","arsenal"],["SETTINGS","settings"],["THUMB GUIDE","help"]]
			actions(g,items,395 if portrait else 340)
		"loadout","arsenal":
			var locked: bool = g.character_locked()
			heading(g,"CHARACTER LOCKED" if locked else "CHOOSE YOUR CHARACTER")
			var index: int = character_focus if locked else int(g.profile.data.weapon)
			draw_character(g,index,card(g))
			var x = 32 if portrait else 714
			var y = 515 if portrait else 180
			var w = 656 if portrait else 510
			button(g,"PREVIOUS",Rect2(x,y,w/2-9,82),"phone_char_previous")
			button(g,"NEXT",Rect2(x+w/2+9,y,w/2-9,82),"phone_char_next")
			if g.screen == "loadout":
				button(g,"DIFFICULTY: "+g.RunState.DIFFICULTIES[int(g.profile.data.difficulty)].name,Rect2(x,y+105,w,82),"difficulty")
				button(g,"BEGIN PERFORMANCE",Rect2(x,y+210,w,88),"begin",true)
				button(g,"BOSS PRACTICE",Rect2(x,y+318,w,82),"select")
			else:
				button(g,"YOUR FIXED SET" if locked else "TRAIN WITH THIS CHARACTER",Rect2(x,y+105,w,88),"back" if locked else "training",true)
			button(g,"BACK",Rect2(32,size().y-112,260,82),"back" if g.screen == "arsenal" else "menu")
		"select":
			heading(g,"BOSS PRACTICE","Song encounters can be tested immediately.")
			var index = boss_focus
			var info: Dictionary = g.bosses[index]
			var rect = card(g)
			var y = g.wrapped_text(info.name,rect.position+Vector2(24,40),rect.size.x-48,29,Color(info.color))
			y = g.wrapped_text(info.get("song",info.subtitle)+(" · "+info.artist if index>=3 else ""),Vector2(rect.position.x+24,y+16),rect.size.x-48,23)
			g.wrapped_text(info.get("tip","Read gold warnings. Dodge through danger and punish an opening."),Vector2(rect.position.x+24,y+16),rect.size.x-48,22,g.MUTED)
			var x = 32 if portrait else 714; var top = 515 if portrait else 180; var width = 656 if portrait else 510
			button(g,"PREVIOUS",Rect2(x,top,width/2-9,82),"phone_boss_previous")
			button(g,"NEXT",Rect2(x+width/2+9,top,width/2-9,82),"phone_boss_next")
			var available = index>=3 or index<=int(g.profile.data.unlocked)
			button(g,"FIGHT THIS BOSS" if available else "CLEAR PREVIOUS BOSS FIRST",Rect2(x,top+105,width,88),"boss_"+str(index) if available else "phone_noop",true)
			button(g,"SONG ENCOUNTERS",Rect2(x,top+215,width,82),"phone_songs")
			button(g,"TRAINING ARENA",Rect2(x,top+320,width,82),"training")
			button(g,"BACK",Rect2(32,size().y-112,260,82),"menu")
		"intermission":
			heading(g,"CHOOSE AN UPGRADE","Tap to read. Confirm when ready.")
			var rect = Rect2(32,180,656,350) if portrait else Rect2(56,180,610,414)
			g.draw_style_box(g.panel_style(Color("14212c"),g.GOLD),rect)
			var selected: Dictionary = g.upgrade_options[g.upgrade_focus]
			var topic: Dictionary = g.Mechanics.ENTRIES[g.Mechanics.TOPICS[selected.id][0]]
			var y = g.wrapped_text(topic.title,rect.position+Vector2(24,38),rect.size.x-48,27,g.TEAL)
			y = g.wrapped_text(selected.line1,Vector2(rect.position.x+24,y+8),rect.size.x-48,22,g.GOLD)
			g.wrapped_text(topic.text,Vector2(rect.position.x+24,y+8),rect.size.x-48,22,g.MUTED)
			for i in g.upgrade_options.size():
				var x = 32 if portrait else 714; var top = 550 if portrait else 180
				button(g,g.upgrade_options[i].name,Rect2(x,top+i*105,656 if portrait else 510,88),"phone_inspect_"+str(i),i == g.upgrade_focus)
			button(g,"CONFIRM: "+selected.name,Rect2(32 if portrait else 714,895 if portrait else 515,656 if portrait else 510,88),"upgrade_"+selected.id,true)
		"settings":
			heading(g,"PHONE SETTINGS","Saved automatically. Character choices stay locked in a run.")
			actions(g,[["AUTO ATTACK: "+("ON" if g.profile.data.auto_attack else "OFF"),"phone_auto"],["VOLUME: %d%%" % int(g.profile.data.volume*100),"volume"],["ASSIST: "+("ON" if g.profile.data.assist else "OFF"),"assist"],["SHAKE: "+("ON" if g.profile.data.shake else "OFF"),"shake"],["IMPACT FLASHES: "+("ON" if g.profile.data.flashes else "REDUCED"),"flashes"],["FULL SCREEN","phone_fullscreen"],["BACK","back"]],250 if portrait else 220)
		"help":
			heading(g,"TWO-THUMB GUIDE")
			var rect = Rect2(32,180,656,890) if portrait else Rect2(56,180,1168,350)
			g.draw_style_box(g.panel_style(Color("14212c"),g.TEAL),rect)
			var instructions = "LEFT: drag anywhere in the left control area to move. Slide up to jump in platform view; slide down to drop through.\n\nRIGHT: tap DODGE, ABILITY or PARRY. Slide between buttons without lifting. Hold ABILITY to repeat. BREAK spends full resonance.\n\nAUTO ATTACK: basic strikes trigger when the boss is in reach. Horizon fires automatically at range while saving dodge energy. Turn AUTO off for a manual STRIKE button.\n\nGold warnings are safe. Active floor attacks need movement or dodging; round bullets can be parried."
			var y = rect.position.y+38
			for paragraph in instructions.split("\n\n"):
				y = g.wrapped_text(paragraph,Vector2(rect.position.x+24,y),rect.size.x-48,23,g.MUTED)+16
			button(g,"BACK",Rect2(32,size().y-112,656 if portrait else 500,82),"back",true)
func draw_combat(g: Node2D) -> void:
	g.draw_arena()
	var width = size().x
	g.text_at(g.bosses[g.boss_index].name,Vector2(30,42),25,g.PAPER)
	g.text_at("TUTORIAL" if g.tutorial_active else "MOVEMENT %02d" % (g.boss_index+1),Vector2(30,75),19,g.MUTED)
	g.bar(Rect2(30,92,width-180,12),g.boss_hp/g.max_hp,Color(g.bosses[g.boss_index].color))
	g.text_at("HP %d" % g.hp,Vector2(30,145),23,g.CORAL)
	g.bar(Rect2(128,130,160 if portrait else 230,14),g.hp/g.run.stat("health"),g.CORAL)
	g.text_at("ENERGY",Vector2(328 if portrait else 445,145),20,g.TEAL)
	g.bar(Rect2(430 if portrait else 550,132,235 if portrait else 230,12),g.energy/g.run.stat("energy"),g.TEAL)
	g.text_at("RESONANCE %d / 100" % g.resonance,Vector2(32,737) if portrait else Vector2(840,145),19,g.GOLD)
	button(g,"II",pause_rect(),"phone_pause")
	if g.tutorial_active:
		var lesson: Dictionary = g.Tutorial.LESSONS[g.tutorial.step]
		var y = 634 if portrait else 180
		var x = 32 if portrait else 340
		var w = 656 if portrait else 570
		g.draw_style_box(g.panel_style(Color("101e29"),g.TEAL),Rect2(x,y-28,w,150 if portrait else 132))
		var next = g.wrapped_text("%d / 8 · %s" % [g.tutorial.step+1,lesson.title],Vector2(x+15,y),w-30,23,g.TEAL)
		var hint: String = ["Drag the LEFT stick into the checkpoint.","Approach the boss. Land three AUTO strikes.","Tap ABILITY with your RIGHT thumb.","Move toward the shot and tap DODGE.","Tap PARRY just before the shot arrives.","Tap the gold BREAK button.","Flick the LEFT stick up, or tap JUMP.","Keep moving. Dodge, use skills and attack."][g.tutorial.step]
		if g.tutorial.step == 1 and not g.profile.data.auto_attack: hint = "Hold STRIKE to land three melee hits."
		g.wrapped_text(hint if portrait else lesson.goal,Vector2(x+15,next+8),w-30,24)
		if not portrait: g.text_at(hint,Vector2(335,321),21,g.TEAL)
	elif portrait:
		g.wrapped_text("Left thumb moves. Right thumb dodges and uses skills.",Vector2(32,640),656 if g.profile.data.auto_attack else 300,23,g.MUTED)
		g.text_at("Turn sideways for a larger arena.",Vector2(32,716),20,g.TEAL)
	if g.screen == "playing": draw_controls(g)
	else: draw_overlay(g)
func draw_controls(g: Node2D) -> void:
	var origin = g.touch_origin if g.move_finger>=0 else stick_home()
	g.draw_circle(origin,112 if portrait else 88,Color(g.TEAL,.10))
	g.draw_circle(origin,112 if portrait else 88,Color(g.TEAL,.35),false,3,true)
	g.draw_circle(origin+g.touch_move*(75 if portrait else 60),35,Color(g.TEAL,.6))
	for item in controls(g):
		var action: String = item[1]
		var cooldown: float = g.dash_cd if action == "dodge" else (g.shoot_cd if action == "shoot" else (g.parry_cd if action == "parry" else 0))
		var ready = cooldown<=0 and (g.resonance>=100 if action == "burst" else true)
		var color = g.GOLD if action == "burst" else g.TEAL
		g.draw_circle(item[0],item[3],Color("12232f"))
		g.draw_circle(item[0],item[3],Color(color,.85 if ready else .25),false,4,true)
		var label: String = item[2] if cooldown<=0 else "%.1f" % cooldown
		var fontsize = 23 if portrait else 21
		var text_width = g.font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,fontsize).x
		g.text_at(label,item[0]+Vector2(-text_width/2,8),fontsize,color if ready else g.MUTED)
		if action == "burst": g.draw_arc(item[0],item[3]-8,-PI/2,-PI/2+TAU*g.resonance/100,48,g.GOLD,4,true)
	button(g,"AUTO: "+("ON" if g.profile.data.auto_attack else "OFF"),auto_rect(),"phone_auto",g.profile.data.auto_attack)
func draw_overlay(g: Node2D) -> void:
	g.draw_rect(Rect2(Vector2.ZERO,size()),Color(.02,.035,.055,.95))
	match g.screen:
		"paused":
			heading(g,"PAUSED","Your character stays fixed. Automatic basic attacks are optional.")
			actions(g,[["RESUME","resume"],["RETRY","retry"],["AUTO ATTACK: "+("ON" if g.profile.data.auto_attack else "OFF"),"phone_auto"],["SWITCH VIEW" if g.training else "THUMB GUIDE","training_view" if g.training else "help"],["ATTACKS "+("ON" if g.training_attacks else "OFF") if g.training else "CHARACTER DETAILS","training_attacks" if g.training else "arsenal"],["SETTINGS","settings"],["TITLE SCREEN","menu"]],250 if portrait else 200)
		"dead":
			heading(g,"TRY AGAIN","Read the warning, dodge the danger and find an opening.")
			actions(g,[["RETRY MOVEMENT","retry"],["SETTINGS / ASSIST","settings"],["TITLE SCREEN","menu"]])
		"clear":
			heading(g,"MOVEMENT COMPLETE",g.bosses[g.boss_index].name)
			actions(g,[["CHOOSE UPGRADE" if not g.practice and g.boss_index<g.bosses.size()-1 else "RETURN TO TITLE","next"],["PLAY AGAIN","retry"],["TITLE SCREEN","menu"]])
		"tutorial_clear":
			heading(g,"FIRST NOTES COMPLETE","Your first real performance awaits.")
			actions(g,[["CHOOSE A PERFORMANCE","start"],["TITLE SCREEN","menu"]])
func draw(g: Node2D) -> void:
	g.draw_rect(Rect2(Vector2.ZERO,size()),g.INK)
	if g.screen in ["title","select","settings","loadout","intermission","help","arsenal"]: draw_menu(g)
	else: draw_combat(g)
