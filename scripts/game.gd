extends Node2D
## One simulation for native and browser. Presentation uses resolution-independent vector art.
const Profile = preload("res://scripts/profile.gd")
const Sound = preload("res://scripts/sound.gd")
const Shot = preload("res://scripts/projectile.gd")
const INK := Color("0b1019")
const PAPER := Color("f2ebda")
const MUTED := Color("8c9ba9")
const TEAL := Color("74ead5")
const CORAL := Color("ef7854")
const GOLD := Color("e8c575")
const FIELD := Rect2(100,164,1080,440)
var profile = Profile.new()
var sound: Node
var bosses: Array
var font: Font
var screen := "title"
var boss_index := 0
var practice := false
var side := false
var player := Vector2(380,440)
var velocity := Vector2.ZERO
var facing := Vector2.RIGHT
var boss := Vector2(900,370)
var boss_hp := 900.0
var max_hp := 900.0
var hp := 100.0
var energy := 100.0
var resonance := 0.0
var invincible := 0.0
var dash_time := 0.0
var dash_cd := 0.0
var dash_dir := Vector2.RIGHT
var melee_cd := 0.0
var melee_flash := 0.0
var combo := 0
var combo_time := 0.0
var shoot_cd := 0.0
var parry_time := 0.0
var parry_cd := 0.0
var boss_flash := 0.0
var attack_timer := 1.5
var attack_number := 0
var phase := 0
var charge_time := 0.0
var charge_dir := Vector2.ZERO
var windup := 0.0
var pending_pattern := ""
var aim_snapshot := Vector2.ZERO
var shots: Array = []
var sparks: Array = []
var floats: Array = []
var rings: Array = []
var elapsed := 0.0
var hits := 0
var total_time := 0.0
var beat := 0
var beat_timer := 0.0
var metronome := false
var banner := ""
var banner_time := 0.0
var shake := 0.0
var buttons: Array = []
var menu_focus := -1
var touches: Dictionary = {}
var touch_origin := Vector2.ZERO
var touch_move := Vector2.ZERO
var move_finger := -1
var touch_actions: Dictionary = {}
var used_touch := false
var gamepad := false
var gamepad_previous: Dictionary = {}
var settings_from := "title"
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	font = ThemeDB.fallback_font
	bosses = JSON.parse_string(FileAccess.get_file_as_string("res://data/bosses.json"))
	profile.load_profile()
	sound = Sound.new()
	add_child(sound)
	apply_volume()
	print("RHAPSODY_BOOT_READY")
	rng.seed = 91428
	get_viewport().size_changed.connect(queue_redraw)
	if "--smoke" in OS.get_cmdline_user_args():
		start_fight(0)
		print("RHAPSODY_READY bosses=",bosses.size()," screen=",screen)

func apply_volume() -> void:
	AudioServer.set_bus_volume_db(0,linear_to_db(maxf(0.001,float(profile.data.volume))))

func held(key: Key) -> bool:
	return Input.is_physical_key_pressed(key)

func mouse_world() -> Vector2:
	return get_global_mouse_position()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if screen != "playing" and event.physical_keycode in [KEY_UP,KEY_DOWN,KEY_TAB,KEY_ENTER] and not buttons.is_empty():
			if event.physical_keycode == KEY_ENTER:
				command(buttons[maxi(0,menu_focus)%buttons.size()].action)
			else:
				menu_focus = posmod(menu_focus+(-1 if event.physical_keycode == KEY_UP else 1),buttons.size())
			return
		match event.physical_keycode:
			KEY_ESCAPE, KEY_P:
				if screen == "playing": screen = "paused"
				elif screen == "paused": screen = "playing"
				elif screen == "settings": screen = settings_from
			KEY_ENTER:
				if screen == "title": start_fight(0)
				elif screen == "dead": start_fight(boss_index)
				elif screen == "clear": advance()
			KEY_SPACE:
				if screen == "playing": dodge()
			KEY_K:
				if screen == "playing": melee()
			KEY_L:
				if screen == "playing": parry()
			KEY_E:
				if screen == "playing": burst()
			KEY_W, KEY_UP:
				if screen == "playing" and side: jump()
			KEY_F:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if screen != "playing": click_ui(event.position)
			elif event.position.distance_to(Vector2(1190,92)) < 35: screen = "paused"
			else: melee()
		elif event.button_index == MOUSE_BUTTON_RIGHT and screen == "playing": get_viewport().set_input_as_handled()
	if event is InputEventScreenTouch:
		used_touch = true
		if event.pressed:
			if screen != "playing": click_ui(event.position); return
			touches[event.index] = event.position
			if event.position.x < 520 and move_finger == -1:
				move_finger = event.index
				touch_origin = event.position
			else: touch_action(event.index,event.position)
		else:
			touches.erase(event.index)
			touch_actions.erase(event.index)
			if event.index == move_finger: move_finger = -1; touch_move = Vector2.ZERO
	if event is InputEventScreenDrag:
		touches[event.index] = event.position
		if event.index == move_finger: touch_move = (event.position-touch_origin).limit_length(65)/65.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and screen == "playing":
		screen = "paused"
		touch_actions.clear()
		touch_move = Vector2.ZERO
		move_finger = -1

func click_ui(p: Vector2) -> void:
	for button in buttons:
		if button.rect.has_point(p):
			command(button.action)
			return

func command(action: String) -> void:
	sound.tone(440,0.05)
	menu_focus = -1
	match action:
		"start": practice = false; start_fight(0)
		"resume": screen = "playing"
		"retry": start_fight(boss_index)
		"next": advance()
		"menu": screen = "title"
		"select": screen = "select"
		"settings": settings_from = screen; screen = "settings"
		"back": screen = settings_from
		"assist": profile.data.assist = not profile.data.assist; profile.save_profile()
		"shake": profile.data.shake = not profile.data.shake; profile.save_profile()
		"volume": profile.data.volume = fmod(float(profile.data.volume)+0.2,1.2); apply_volume(); profile.save_profile()
		"pulse": metronome = not metronome
		"close_help": screen = "playing"
		_:
			if action.begins_with("boss_"):
				practice = true
				start_fight(int(action.trim_prefix("boss_")))

func start_fight(index: int) -> void:
	boss_index = clampi(index,0,bosses.size()-1)
	max_hp = float(bosses[boss_index].hp)
	boss_hp = max_hp
	hp = 100
	energy = 100
	resonance = 0
	side = false
	player = Vector2(350,440)
	boss = Vector2(900,355)
	velocity = Vector2.ZERO
	facing = Vector2.RIGHT
	shots.clear(); sparks.clear(); floats.clear(); rings.clear()
	dash_time = 0; dash_cd = 0; invincible = 1; melee_cd = 0; shoot_cd = 0
	parry_cd = 0; parry_time = 0; charge_time = 0; windup = 0; phase = 0
	combo = 0; combo_time = 0; attack_number = 0; elapsed = 0; hits = 0; attack_timer = 2.8
	shake = 0
	banner = "MOVEMENT %02d  /  %s" % [index+1,bosses[index].name]
	banner_time = 2.6
	screen = "playing"
	print("RHAPSODY_FIGHT_READY movement=",boss_index+1)
	touch_actions.clear(); touch_move = Vector2.ZERO; move_finger = -1

func advance() -> void:
	if practice or boss_index >= bosses.size()-1: screen = "title"
	else: start_fight(boss_index+1)

func move_input() -> Vector2:
	var move = Vector2(float(held(KEY_D) or held(KEY_RIGHT))-float(held(KEY_A) or held(KEY_LEFT)),float(held(KEY_S) or held(KEY_DOWN))-float(held(KEY_W) or held(KEY_UP))) + touch_move
	var pads = Input.get_connected_joypads()
	if not pads.is_empty():
		var pad: int = pads[0]
		var stick = Vector2(Input.get_joy_axis(pad,JOY_AXIS_LEFT_X),Input.get_joy_axis(pad,JOY_AXIS_LEFT_Y))
		if stick.length()>0.2: move += stick
	return move.limit_length(1)

func gamepad_input() -> void:
	var pads = Input.get_connected_joypads()
	if pads.is_empty(): return
	gamepad = true
	var pad: int = pads[0]
	for binding in [JOY_BUTTON_A,JOY_BUTTON_X,JOY_BUTTON_Y,JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_START]:
		var down = Input.is_joy_button_pressed(pad,binding)
		if down and not gamepad_previous.get(binding,false):
			if binding == JOY_BUTTON_START:
				if screen == "playing": screen = "paused"
				elif screen == "paused": screen = "playing"
			elif screen == "playing":
				match binding:
					JOY_BUTTON_A: dodge()
					JOY_BUTTON_X: melee()
					JOY_BUTTON_Y: burst()
					JOY_BUTTON_LEFT_SHOULDER: parry()
			elif binding == JOY_BUTTON_A:
				if screen == "title": start_fight(0)
				elif screen == "dead": start_fight(boss_index)
				elif screen == "clear": advance()
		gamepad_previous[binding] = down
	if screen == "playing" and side and Input.get_joy_axis(pad,JOY_AXIS_LEFT_Y)<-0.65: jump()

func touch_action(index: int,p: Vector2) -> void:
	if p.distance_to(Vector2(1190,92)) < 40: screen = "paused"; return
	for item in [[Vector2(1080,575),"melee"],[Vector2(1180,485),"shoot"],[Vector2(975,645),"dodge"],[Vector2(1180,645),"parry"],[Vector2(1080,400),"burst"],[Vector2(880,575),"jump"]]:
		if p.distance_to(item[0])<45:
			touch_actions[index] = item[1]
			match item[1]:
				"melee": melee()
				"dodge": dodge()
				"parry": parry()
				"burst": burst()
				"jump": jump()
			return

func jump() -> void:
	if side and player.y >= 550: velocity.y = -570; sound.tone(310,0.07)

func dodge() -> void:
	if dash_cd>0 or energy<24: return
	energy -= 24
	dash_cd = 0.48
	dash_time = 0.17
	invincible = maxf(invincible,0.23)
	dash_dir = move_input()
	if side: dash_dir.y = 0
	if dash_dir.length()<0.1: dash_dir = facing
	dash_dir = dash_dir.normalized()
	sound.tone(150,0.09)

func melee() -> void:
	if melee_cd>0: return
	combo = (combo % 3)+1 if combo_time>0 else 1
	combo_time = 0.9
	melee_cd = 0.22 if combo<3 else 0.4
	melee_flash = 0.17
	var target_dir = player.direction_to(boss)
	if used_touch or gamepad or held(KEY_K): facing = target_dir
	else: facing = player.direction_to(mouse_world())
	if player.distance_to(boss)<128 and facing.dot(target_dir)>0.1:
		damage_boss(30.0 if combo<3 else 55.0)
		resonance = minf(100,resonance+8)
		energy = minf(100,energy+13)
		emit_sparks(boss,TEAL,14)
		sound.tone(260+combo*90,0.1)
	else: sound.tone(170+combo*35,0.05,0.06)

func shoot() -> void:
	if shoot_cd>0 or energy<3: return
	energy -= 3
	shoot_cd = 0.14
	var aim = player.direction_to(boss) if used_touch or gamepad or held(KEY_J) else player.direction_to(mouse_world())
	facing = aim
	shots.append(Shot.new(player+aim*24,aim*850,true,9,4))
	sound.tone(620,0.045,0.055)

func parry() -> void:
	if parry_cd>0: return
	parry_time = 0.2
	parry_cd = 0.85
	sound.tone(820,0.06)

func burst() -> void:
	if resonance<100: return
	resonance = 0
	shots = shots.filter(func(s): return s.friendly)
	damage_boss(135)
	invincible = maxf(invincible,0.7)
	rings.append({"p":player,"r":20.0,"life":0.65,"max":0.65,"color":TEAL})
	emit_sparks(player,TEAL,45)
	shake = 9
	banner = "RESONANCE BREAK"; banner_time = 0.9
	sound.tone(110,0.4,0.3)

func damage_boss(amount: float) -> void:
	if screen != "playing": return
	boss_hp = maxf(0,boss_hp-amount)
	boss_flash = 0.08
	floats.append({"p":boss+Vector2(rng.randf_range(-20,20),-55),"text":str(int(amount)),"life":0.65})
	if boss_hp <= 0:
		profile.record_clear(boss_index,elapsed,hits)
		screen = "clear"
		emit_sparks(boss,GOLD,80)
		sound.tone(523,0.35,0.2)

func hurt(amount: float) -> void:
	if invincible>0 or screen != "playing": return
	hp = maxf(0,hp-amount*(0.5 if profile.data.assist else 1.0))
	hits += 1
	invincible = 0.85
	shake = 10
	emit_sparks(player,CORAL,18)
	sound.tone(75,0.18,0.25)
	if hp <= 0: screen = "dead"

func emit_sparks(p: Vector2,color: Color,count: int) -> void:
	for i in count:
		if sparks.size()>=300: break
		sparks.append({"p":p,"v":Vector2.RIGHT.rotated(rng.randf()*TAU)*rng.randf_range(40,270),"life":rng.randf_range(0.2,0.65),"color":color})

func _process(raw_delta: float) -> void:
	var delta = minf(raw_delta,0.04)
	total_time += delta
	gamepad_input()
	if screen == "playing": simulate(delta)
	if screen in ["playing","clear","dead"]:
		for spark in sparks: spark.p += spark.v*delta; spark.v *= pow(0.06,delta); spark.life -= delta
		sparks = sparks.filter(func(s): return s.life>0)
		for number in floats: number.p.y -= delta*42; number.life -= delta
		floats = floats.filter(func(n): return n.life>0)
		for ring in rings: ring.r += 950*delta; ring.life -= delta
		rings = rings.filter(func(r): return r.life>0)
	shake = maxf(0,shake-delta*45)
	queue_redraw()

func simulate(delta: float) -> void:
	elapsed += delta
	for prop in ["invincible","dash_time","dash_cd","melee_cd","melee_flash","shoot_cd","parry_time","parry_cd","boss_flash","banner_time","combo_time"]:
		set(prop,maxf(0,float(get(prop))-delta))
	energy = minf(100,energy+delta*16)
	if profile.data.assist: hp = minf(100,hp+delta*0.7)
	var move = move_input()
	if move.length()>0.15 and (used_touch or gamepad): facing = Vector2(signf(move.x),0) if side else move.normalized()
	if side:
		velocity.x = move.x*310
		velocity.y += 1500*delta
		if dash_time>0: velocity = dash_dir*1000
		player += velocity*delta
		if player.y>=560: player.y = 560; velocity.y = 0
		player.y = maxf(195,player.y)
	else:
		velocity = move*310
		if dash_time>0: velocity = dash_dir*1000
		player += velocity*delta
		player.y = clampf(player.y,190,580)
	player.x = clampf(player.x,125,1155)
	if dash_time>0: emit_sparks(player,TEAL,2)
	var shooting = held(KEY_J) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or "shoot" in touch_actions.values()
	var pads = Input.get_connected_joypads()
	if not pads.is_empty(): shooting = shooting or Input.get_joy_axis(pads[0],JOY_AXIS_TRIGGER_RIGHT)>0.25 or Input.is_joy_button_pressed(pads[0],JOY_BUTTON_RIGHT_SHOULDER)
	if shooting: shoot()
	if "melee" in touch_actions.values(): melee()
	beat_timer += delta
	if beat_timer>=0.5:
		beat_timer -= 0.5; beat += 1
		if metronome: sound.tone(1000 if beat%4 == 0 else 650,0.035,0.035)
	var new_phase = 2 if boss_hp/max_hp<0.33 else (1 if boss_hp/max_hp<0.67 else 0)
	if new_phase>phase:
		phase = new_phase
		change_perspective(phase == 1)
		return
	update_boss(delta)
	if screen != "playing": return
	for shot in shots:
		shot.step(delta)
		if shot.friendly:
			if shot.intersects(boss,43): damage_boss(shot.damage); shot.life = 0; emit_sparks(shot.position,TEAL,3); resonance = minf(100,resonance+1.2)
		else:
			if shot.intersects(player,14):
				if parry_time>0:
					shot.friendly = true
					shot.velocity = shot.position.direction_to(boss)*900
					shot.damage = 28
					resonance = minf(100,resonance+18)
					energy = minf(100,energy+15)
					emit_sparks(player,GOLD,10)
					sound.tone(1100,0.13)
				else: hurt(12); shot.life = 0
	shots = shots.filter(func(s): return s.life>0 and Rect2(50,110,1180,560).has_point(s.position))

func change_perspective(to_side: bool) -> void:
	side = to_side
	shots.clear()
	windup = 0; charge_time = 0; attack_timer = 2.5
	player = Vector2(clampf(player.x,170,600),560 if side else 440)
	boss = Vector2(950,515 if side else 350)
	velocity = Vector2.ZERO
	invincible = 2.0
	banner = "FORM SHIFT  /  " + ("SIDE-SCROLLER · W TO JUMP" if side else "TOP-DOWN · MOVE FREELY")
	banner_time = 2.4
	sound.tone(220,0.3)

func update_boss(delta: float) -> void:
	if charge_time>0:
		charge_time -= delta
		boss += charge_dir*650*delta
		boss.x = clampf(boss.x,160,1120)
		boss.y = clampf(boss.y,215,550)
		if boss.distance_to(player)<58: hurt(22)
		return
	var destination = Vector2(870+sin(elapsed*0.7)*125,515 if side else 355+sin(elapsed*1.1)*105)
	boss = boss.move_toward(destination,delta*100)
	if boss.distance_to(player)<53: hurt(14)
	if windup>0:
		windup -= delta
		if windup<=0: execute_pattern(pending_pattern)
		return
	attack_timer -= delta
	if attack_timer<=0:
		var patterns: Array = bosses[boss_index].patterns
		pending_pattern = patterns[attack_number%patterns.size()]
		attack_number += 1
		aim_snapshot = player
		windup = 0.78 if phase == 0 else 0.6
		attack_timer = float(bosses[boss_index].interval)*(1.0-0.13*phase)

func enemy_shot(p: Vector2,angle: float,speed: float,size: float = 7) -> void:
	if shots.size()<350: shots.append(Shot.new(p,Vector2.RIGHT.rotated(angle)*speed,false,12,size))

func execute_pattern(pattern: String) -> void:
	var speed = float(bosses[boss_index].speed)*(1+0.12*phase)
	var angle = boss.angle_to_point(aim_snapshot)
	sound.tone(130+boss_index*30,0.1,0.09)
	match pattern:
		"fan":
			for i in 7+phase*2: enemy_shot(boss,angle+(i-(6+phase*2)/2.0)*0.15,speed)
		"ring":
			for i in 18+phase*4: enemy_shot(boss,TAU*i/(18+phase*4)+attack_number*0.23,speed*0.83)
		"charge":
			charge_dir = boss.direction_to(aim_snapshot)
			if side: charge_dir = Vector2(-1 if player.x<boss.x else 1,0)
			charge_time = 0.65
		"rain":
			var gap = clampf(aim_snapshot.x+100,250,1030)
			for i in 18:
				var x = 150+i*57
				if absf(x-gap)>85: enemy_shot(Vector2(x,178),PI/2,speed,8)
		"cross":
			for i in 12:
				var y = 210+i*31
				if absf(y-aim_snapshot.y)>48: enemy_shot(Vector2(1160,y),PI,speed,7)
			for i in 5: enemy_shot(boss,angle+(i-2)*0.22,speed*1.1)

func text_at(value: String,p: Vector2,size: int = 20,color: Color = PAPER) -> void:
	draw_string(font,p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func centered(value: String,y: float,size: int = 20,color: Color = PAPER) -> void:
	text_at(value,Vector2((1280-font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x)/2,y),size,color)

func line(a: Vector2,b: Vector2,color: Color,width: float = 1) -> void:
	draw_line(a,b,color,width,true)

func button(label: String,rect: Rect2,action: String,primary: bool = false) -> void:
	buttons.append({"rect":rect,"action":action})
	var hover = rect.has_point(mouse_world()) or menu_focus == buttons.size()-1
	draw_style_box(panel_style(TEAL if primary else Color("202b37"),TEAL if hover else Color("3c4c59")),rect)
	var size = 19
	var w = font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	text_at(label,rect.position+Vector2((rect.size.x-w)/2,rect.size.y/2+7),size,INK if primary else PAPER)

func panel_style(fill: Color,border: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	return style

func bar(rect: Rect2,value: float,color: Color) -> void:
	draw_rect(rect,Color("293340"))
	draw_rect(Rect2(rect.position,Vector2(rect.size.x*clampf(value,0,1),rect.size.y)),color)

func _draw() -> void:
	buttons.clear()
	draw_rect(Rect2(0,0,1280,720),INK)
	for i in 36:
		var x = float(i)*39+fmod(total_time*7,39)
		line(Vector2(x,0),Vector2(x-200,720),Color(0.25,0.38,0.43,0.045))
	if screen in ["title","select","settings"]:
		draw_menu()
		return
	draw_arena()
	draw_hud()
	if screen != "playing": draw_overlay()

func draw_menu() -> void:
	text_at("R / A",Vector2(58,62),22,TEAL)
	text_at("PLAYABLE FOUNDATION  /  0.1",Vector2(896,59),14,MUTED)
	line(Vector2(58,82),Vector2(1222,82),Color("293340"))
	if screen == "title":
		text_at("A HYBRID-PERSPECTIVE BOSS RUSH",Vector2(94,169),16,TEAL)
		text_at("RHAPSODY",Vector2(88,263),84)
		text_at("ALLEGRO",Vector2(94,320),42,CORAL)
		text_at("Change the form. Keep the fight.",Vector2(96,377),25)
		text_at("Blade, bullets, and a split-second decision.",Vector2(96,414),18,MUTED)
		button("BEGIN THE FIRST MOVEMENT",Rect2(96,459,390,54),"start",true)
		button("BOSS SELECT",Rect2(96,528,188,48),"select")
		button("SETTINGS",Rect2(298,528,188,48),"settings")
		text_at("WASD  MOVE     LMB / K  BLADE     RMB / J  FIRE",Vector2(96,626),15,MUTED)
		text_at("SPACE  DODGE     L  PARRY     E  RESONANCE     ESC  PAUSE",Vector2(96,655),15,MUTED)
		draw_emblem(Vector2(918,337),124,Color("ef7854"),total_time*0.14)
		draw_arc(Vector2(918,337),184,-PI*0.85,PI*0.7,80,Color("33414e"),1.5,true)
		draw_arc(Vector2(918,337),193,-PI*0.3,PI*0.35,30,TEAL,2,true)
		text_at("I  /  THE METRONOME",Vector2(800,577),18,CORAL)
		text_at("Three movements. One continuous combat language.",Vector2(735,615),14,MUTED)
	elif screen == "select":
		text_at("CHOOSE YOUR MOVEMENT",Vector2(96,170),35)
		text_at("Clear each boss to unlock the next. Practice clears are saved.",Vector2(96,210),18,MUTED)
		for i in bosses.size():
			var x = 96+i*373
			var available = i<=int(profile.data.unlocked)
			var color = Color(bosses[i].color) if available else MUTED
			draw_style_box(panel_style(Color("141e29"),Color("33414e")),Rect2(x,253,343,330))
			draw_emblem(Vector2(x+172,350),50,color,total_time*0.2)
			text_at("MOVEMENT %02d" % (i+1),Vector2(x+22,433),14,color)
			text_at(bosses[i].name,Vector2(x+22,468),22)
			var key = str(i)+("_assist" if profile.data.assist else "")
			var best = "NO CLEAR YET"
			if profile.data.best.has(key): best = "BEST  %.1fs  /  %d HITS" % [profile.data.best[key].time,profile.data.best[key].hits]
			text_at(best,Vector2(x+22,498),14,MUTED)
			if available: button("PLAY",Rect2(x+22,520,299,42),"boss_"+str(i),true)
			else: text_at("CLEAR PREVIOUS MOVEMENT",Vector2(x+22,550),14,MUTED)
		button("BACK",Rect2(96,621,190,45),"menu")
	elif screen == "settings":
		centered("TUNE YOUR EXPERIENCE",175,36)
		centered("Settings save automatically on this device.",214,17,MUTED)
		button("VOLUME   %d%%" % int(float(profile.data.volume)*100),Rect2(390,260,500,50),"volume")
		button("SCREEN SHAKE   "+("ON" if profile.data.shake else "OFF"),Rect2(390,325,500,50),"shake")
		button("ASSIST MODE   "+("ON" if profile.data.assist else "OFF"),Rect2(390,390,500,50),"assist")
		centered("Assist halves incoming damage and slowly regenerates health.",473,16,MUTED)
		button("PRACTICE PULSE   "+("ON" if metronome else "OFF"),Rect2(390,495,500,50),"pulse")
		centered("Optional timing clicks. Combat never requires playing on the beat.",573,16,MUTED)
		button("BACK",Rect2(490,609,300,48),"back",true)

func draw_emblem(p: Vector2,r: float,color: Color,angle: float) -> void:
	draw_circle(p,r*1.35,Color(color,0.035))
	draw_arc(p,r,0,TAU,64,Color(color,0.3),1,true)
	for i in 4:
		var direction = Vector2.RIGHT.rotated(angle+TAU*i/4)
		var normal = direction.orthogonal()
		var polygon = PackedVector2Array([p+direction*r,p+direction*r*0.5+normal*r*0.24,p+direction*r*0.18,p+direction*r*0.5-normal*r*0.24])
		draw_colored_polygon(polygon,Color(color,0.85))
		line(p+direction*r*1.12,p+direction*r*1.3,color,3)
	draw_circle(p,r*0.16,PAPER)
	draw_circle(p,r*0.065,INK)

func draw_arena() -> void:
	var color = Color(bosses[boss_index].color)
	var offset = Vector2.ZERO
	if profile.data.shake and shake>0: offset = Vector2(sin(total_time*101),cos(total_time*91))*shake
	draw_set_transform(offset)
	draw_rect(FIELD,Color("101a26"))
	for x in range(100,1181,54): line(Vector2(x,164),Vector2(x,604),Color("1b2936"))
	for y in range(164,605,44): line(Vector2(100,y),Vector2(1180,y),Color("1b2936"))
	draw_rect(FIELD,Color("3b4c59"),false,2)
	for p in [Vector2(100,164),Vector2(1180,164),Vector2(100,604),Vector2(1180,604)]:
		line(p-Vector2(10,0),p+Vector2(10,0),color,3)
		line(p-Vector2(0,10),p+Vector2(0,10),color,3)
	if side:
		draw_rect(Rect2(100,582,1080,22),Color("203743"))
		line(Vector2(100,582),Vector2(1180,582),TEAL,2)
		for i in 14: line(Vector2(110+i*80,598),Vector2(125+i*80,584),Color("49616a"))
	else:
		draw_arc(Vector2(640,385),177,0,TAU,90,Color("263848"),1,true)
		draw_arc(Vector2(640,385),172,0,TAU,90,Color("1e303e"),1,true)
	text_at(bosses[boss_index].arena,Vector2(124,192),12,Color("587080"))
	if windup>0:
		var alpha = 0.25+0.2*sin(total_time*25)
		if pending_pattern == "charge" or pending_pattern == "fan":
			line(boss,aim_snapshot,Color(CORAL,alpha),pending_pattern.length()*2)
			draw_circle(aim_snapshot,33,Color(CORAL,alpha),false,2,true)
		elif pending_pattern == "rain":
			for i in 18:
				var x = 150+i*57
				if absf(x-clampf(aim_snapshot.x+100,250,1030))>85: line(Vector2(x,180),Vector2(x,596),Color(CORAL,alpha),2)
		elif pending_pattern == "cross":
			for i in 12:
				var y = 210+i*31
				if absf(y-aim_snapshot.y)>48: line(Vector2(115,y),Vector2(1160,y),Color(CORAL,alpha),2)
		else: draw_circle(boss,65+(1-windup)*40,Color(CORAL,alpha),false,2,true)
		text_at("!",boss+Vector2(-5,-82),26,CORAL)
	for shot in shots:
		var c = TEAL if shot.friendly else color
		line(shot.position-shot.velocity.normalized()*12,shot.position,Color(c,0.4),shot.radius*1.5)
		draw_circle(shot.position,shot.radius,c)
		if not shot.friendly: draw_circle(shot.position,shot.radius*0.4,INK)
	if boss_hp>0:
		draw_circle(boss+Vector2(0,45),41,Color(0,0,0,0.3))
		draw_emblem(boss,46,PAPER if boss_flash>0 else color,total_time*0.6*(1+phase))
		draw_arc(boss,59,0,TAU,48,Color(color,0.25),1,true)
	draw_player()
	for spark in sparks: draw_circle(spark.p,maxf(1,spark.life*5),Color(spark.color,minf(1,spark.life*2)))
	for ring in rings: draw_circle(ring.p,ring.r,Color(ring.color,ring.life/ring.max),false,5,true)
	for number in floats: text_at(number.text,number.p,19,Color(PAPER,minf(1,number.life*2)))
	draw_set_transform(Vector2.ZERO)

func draw_player() -> void:
	var blink = invincible>0 and int(total_time*16)%2 == 0
	var color = Color(TEAL,0.45) if blink else TEAL
	draw_circle(player+Vector2(0,18),17,Color(0,0,0,0.3))
	var tail = player-facing*26
	draw_colored_polygon(PackedVector2Array([player+facing.orthogonal()*9,tail+facing.orthogonal()*5,tail-facing.orthogonal()*12]),CORAL)
	draw_circle(player,14,INK)
	draw_circle(player,14,color,false,2.5,true)
	line(player-facing.orthogonal()*7,player+facing.orthogonal()*7,PAPER,3)
	draw_circle(player+facing*7,3,PAPER)
	line(player+facing*16,player+facing*27,TEAL,3)
	if melee_flash>0:
		var angle = facing.angle()
		draw_arc(player,78 if combo<3 else 100,angle-1.05,angle+1.05,22,Color(TEAL,melee_flash/0.17),7,true)
	if parry_time>0: draw_circle(player,34,GOLD,false,4,true)
	if dash_time>0: line(player-dash_dir*55,player,Color(TEAL,0.6),5)

func draw_hud() -> void:
	text_at("R / A",Vector2(42,45),20,TEAL)
	text_at("MOVEMENT %02d" % (boss_index+1),Vector2(124,43),14,MUTED)
	text_at(bosses[boss_index].name,Vector2(124,76),28)
	text_at(bosses[boss_index].subtitle,Vector2(124,100),14,MUTED)
	bar(Rect2(124,118,1032,7),boss_hp/max_hp,Color(bosses[boss_index].color))
	for threshold in [0.33,0.67]: line(Vector2(124+1032*threshold,115),Vector2(124+1032*threshold,128),PAPER,2)
	text_at("%d / %d" % [int(boss_hp),int(max_hp)],Vector2(1010,100),14,MUTED)
	text_at("%02d:%02d" % [int(elapsed)/60,int(elapsed)%60],Vector2(1058,44),20)
	text_at("SIDE-SCROLLER" if side else "TOP-DOWN",Vector2(895,74),14,TEAL)
	text_at("II",Vector2(1180,100),26,MUTED)
	text_at("VITALITY  %d" % int(hp),Vector2(100,638),14,PAPER)
	bar(Rect2(100,650,240,7),hp/100,CORAL)
	text_at("ENERGY",Vector2(370,638),14,MUTED)
	bar(Rect2(370,650,190,7),energy/100,TEAL)
	text_at("RESONANCE"+ ("  /  E TO BREAK" if resonance>=100 else ""),Vector2(590,638),14,GOLD)
	bar(Rect2(590,650,290,7),resonance/100,GOLD)
	text_at("PARRY READY" if parry_cd<=0 else "PARRY %.1f" % parry_cd,Vector2(930,638),14,MUTED)
	text_at("ASSIST" if profile.data.assist else "STANDARD",Vector2(1060,659),12,TEAL if profile.data.assist else MUTED)
	if not used_touch:
		centered("WASD  MOVE   ·   K / LMB  BLADE   ·   J / RMB  FIRE   ·   SPACE  DODGE   ·   L  PARRY   ·   E  BURST   ·   ESC  PAUSE",696,13,MUTED)
	if banner_time>0 and screen == "playing":
		draw_rect(Rect2(200,284,880,78),Color(0.03,0.05,0.08,0.93))
		centered(banner,330,22,TEAL)
	elif elapsed<14 and screen == "playing" and not used_touch:
		centered("Close the gap with dodge. Melee restores energy. Gold parry reflects incoming shots.",150,14,GOLD)
	if used_touch and screen == "playing": draw_touch()

func draw_touch() -> void:
	var origin = touch_origin if move_finger>=0 else Vector2(210,520)
	draw_circle(origin,65,Color(TEAL,0.08))
	draw_circle(origin,65,Color(TEAL,0.3),false,2,true)
	draw_circle(origin+touch_move*55,23,Color(TEAL,0.5))
	for item in [[Vector2(1080,575),"BLADE"],[Vector2(1180,485),"FIRE"],[Vector2(975,645),"DODGE"],[Vector2(1180,645),"PARRY"],[Vector2(1080,400),"BURST"],[Vector2(880,575),"JUMP"]]:
		if item[1] == "JUMP" and not side: continue
		draw_circle(item[0],36,Color(0.05,0.12,0.17,0.85))
		draw_circle(item[0],36,Color(TEAL,0.45),false,2,true)
		text_at(item[1],item[0]+Vector2(-25,5),12,TEAL)

func draw_overlay() -> void:
	draw_rect(Rect2(0,0,1280,720),Color(0.02,0.035,0.055,0.88))
	if screen == "paused":
		centered("A MOMENT OF SILENCE",235,38)
		centered("Your movement resumes when you do.",278,19,MUTED)
		button("RESUME",Rect2(450,320,380,52),"resume",true)
		button("SETTINGS",Rect2(450,390,380,48),"settings")
		button("RESTART MOVEMENT",Rect2(450,454,380,48),"retry")
		button("TITLE SCREEN",Rect2(450,518,380,48),"menu")
	elif screen == "dead":
		centered("A REST, NOT THE END.",254,40,CORAL)
		centered("Read the warning. Find the opening. Try again.",302,21,MUTED)
		centered("%.1f SECONDS  /  %d HITS TAKEN" % [elapsed,hits],354,17)
		button("RETRY MOVEMENT",Rect2(450,401,380,54),"retry",true)
		button("SETTINGS / ASSIST",Rect2(450,475,380,48),"settings")
		button("TITLE SCREEN",Rect2(450,540,380,48),"menu")
	elif screen == "clear":
		centered("MOVEMENT COMPLETE" if boss_index<2 else "FINALE COMPLETE",239,40,GOLD)
		centered(bosses[boss_index].name+"  /  SILENCED",291,20,MUTED)
		var rank = "S" if hits == 0 else ("A" if hits<=3 else ("B" if hits<=6 else "C"))
		centered("%s     %.1fs     %d HITS" % [rank,elapsed,hits],364,34)
		centered("Personal best and unlocks saved"+(" · ASSIST RECORD" if profile.data.assist else ""),400,16,TEAL)
		button("NEXT MOVEMENT" if boss_index<2 and not practice else "RETURN TO TITLE",Rect2(450,445,380,54),"next",true)
		button("PLAY AGAIN",Rect2(450,516,380,48),"retry")
