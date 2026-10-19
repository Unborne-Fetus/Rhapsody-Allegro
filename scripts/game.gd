extends Node2D
## One simulation for native and browser. Presentation uses resolution-independent vector art.
const CombatRules = preload("res://scripts/combat_rules.gd")
const PhoneUI = preload("res://scripts/phone_ui.gd")
const SongBosses = preload("res://scripts/song_bosses.gd")
const Encounters = preload("res://scripts/encounters.gd")
const Profile = preload("res://scripts/profile.gd")
const Sound = preload("res://scripts/sound.gd")
const Characters = preload("res://scripts/characters.gd")
const Mechanics = preload("res://scripts/mechanics.gd")
const Tutorial = preload("res://scripts/tutorial.gd")
const Arsenal = preload("res://scripts/weapons.gd")
const RunState = preload("res://scripts/run_state.gd")
const HazardView = preload("res://scripts/hazard_view.gd")
const Hazard = preload("res://scripts/hazard.gd")
const Shot = preload("res://scripts/projectile.gd")
const INK := Color("0b1019")
const PAPER := Color("f2ebda")
const MUTED := Color("8c9ba9")
const TEAL := Color("74ead5")
const CORAL := Color("ef7854")
const GOLD := Color("e8c575")
const FIELD := Rect2(100,164,1080,440)
var parry_enabled := CombatRules.PARRY_ENABLED
var phone = PhoneUI.new()
var phone_mode := false
var phone_jump_held := false
var arena_origin := Vector2.ZERO
var arena_scale := 1.0
var songs = SongBosses.new()
var boss_page := 0
var run = RunState.new()
var profile = Profile.new()
var fight_base_score := 0
var fight_base_time := 0.0
var fight_base_hits := 0
var fight_assisted := false
var tutorial_active := false
var tutorial = Tutorial.new()
var tutorial_shot_timer := 1.0
var riposte_time := 0.0
var bleed_time := 0.0
var bleed_tick := 0.5
var bleed_stacks := 0
var chain_active := false
var followup_delay := 0.0
var followup_pattern := ""
var upgrade_focus := 0
var ui_mouse_active := true
var training := false
var training_attacks := false
var mouse_attack_latched := false
var weapon_index := Arsenal.DEFAULT
var melee_windup := 0.0
var melee_snapshot: Dictionary = {}
var active_melee: Dictionary = {}
var training_damage := 0.0
var training_hit_count := 0
var training_last_hit := 0.0
var training_window: Array = []
var range_guides := true
var hazards: Array = []
var hazard_view: Node2D
var stagger := 0.0
var stagger_time := 0.0
var stagger_lock := 0.0
var style := 0.0
var style_chain := 0
var last_action := ""
var fight_score := 0
var parries := 0
var perfect_dodges := 0
var dash_rewarded := false
var hit_stop := 0.0
var victory_accounted := false
var upgrade_options: Array = []
var ground_grace := 0.0
var jump_buffer := 0.0
var jump_cut := false
var last_move := Vector2.RIGHT
var story_time := 0.0
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
var menu_history: Array[String] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	font = ThemeDB.fallback_font
	bosses = Encounters.roster()
	profile.load_profile()
	run.difficulty = int(profile.data.difficulty)
	weapon_index = int(profile.data.weapon)
	run.loadout_index = weapon_index
	sound = Sound.new()
	add_child(sound)
	var clip = Control.new()
	clip.position = FIELD.position; clip.size = FIELD.size; clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(clip)
	hazard_view = HazardView.new(); hazard_view.game = self; hazard_view.position = -FIELD.position
	clip.add_child(hazard_view)
	apply_volume()
	print("RHAPSODY_BOOT_READY")
	rng.seed = 91428
	phone_mode = DisplayServer.is_touchscreen_available() or OS.has_feature("android") or OS.has_feature("ios")
	if OS.has_feature("web"):
		phone_mode = bool(JavaScriptBridge.eval("navigator.maxTouchPoints > 0 && (matchMedia('(pointer: coarse)').matches || /Android|iPhone|iPad/i.test(navigator.userAgent))"))
	get_viewport().size_changed.connect(configure_phone)
	configure_phone()
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
		gamepad = false; used_touch = false; ui_mouse_active = false
		if screen != "playing" and event.physical_keycode in [KEY_UP,KEY_DOWN,KEY_TAB,KEY_ENTER] and not buttons.is_empty():
			if event.physical_keycode == KEY_ENTER:
				command(buttons[maxi(0,menu_focus)%buttons.size()].action)
			else:
				navigate_menu(-1 if event.physical_keycode == KEY_UP else 1)
			return
		match event.physical_keycode:
			KEY_ESCAPE, KEY_P:
				if screen == "playing": screen = "paused"; clear_touch()
				elif screen == "paused": screen = "playing"
				elif screen in ["settings","help","arsenal"]: close_panel()
				elif screen in ["loadout","select","intermission"]: screen = "title"
			KEY_ENTER:
				if screen == "title" or screen == "tutorial_clear": screen = "loadout"
				elif screen == "dead": restart_fight()
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
			KEY_Q:
				if screen == "playing": cycle_weapon()
			KEY_H:
				if screen == "help": close_panel()
				else: open_panel("help")
			KEY_G:
				if screen == "playing" and training: range_guides = not range_guides
			KEY_R:
				if screen == "playing" and training: reset_training_readout()
			KEY_T:
				if screen == "playing" and training: training_attacks = not training_attacks
			KEY_V:
				if screen == "playing" and training: change_perspective(not side)
			KEY_F:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
	if event is InputEventMouseMotion and event.relative.length()>1:
		gamepad = false; used_touch = false; ui_mouse_active = true
		if screen == "intermission": inspect_upgrade_at(event.position)
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT: mouse_attack_latched = false
	if event is InputEventMouseButton and event.pressed:
		gamepad = false; used_touch = false
		if event.button_index == MOUSE_BUTTON_LEFT:
			if screen != "playing": click_ui(event.position)
			elif event.position.distance_to(Vector2(1190,92)) < 35: screen = "paused"; clear_touch()
			else: melee()
		elif event.button_index == MOUSE_BUTTON_RIGHT and screen == "playing": get_viewport().set_input_as_handled()
	if event is InputEventScreenTouch and phone_mode:
		phone_touch(event); return
	if event is InputEventScreenDrag and phone_mode:
		phone_drag(event); return
	if event is InputEventScreenTouch:
		used_touch = true; ui_mouse_active = false
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
		clear_touch()

func click_ui(p: Vector2) -> void:
	if screen == "intermission" and not phone_mode: inspect_upgrade_at(p)
	for button in buttons:
		if button.rect.has_point(p):
			command(button.action)
			return

func command(action: String) -> void:
	sound.tone(440,0.05)
	menu_focus = -1
	match action:
		"phone_noop": return
		"phone_pause": screen = "paused"; clear_touch()
		"phone_auto": profile.data.auto_attack = not profile.data.auto_attack; profile.save_profile()
		"phone_fullscreen":
			if OS.has_feature("web"): JavaScriptBridge.eval("window.rhapsodyFullscreen && window.rhapsodyFullscreen()")
			else: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"phone_char_previous","phone_char_next":
			var direction = 1 if action == "phone_char_next" else -1
			if character_locked(): phone.character_focus = posmod(phone.character_focus+direction,4)
			else: equip_set(posmod(int(profile.data.weapon)+direction,4),true)
		"phone_boss_previous","phone_boss_next": phone.boss_focus = posmod(phone.boss_focus+(1 if action == "phone_boss_next" else -1),bosses.size())
		"phone_songs": phone.boss_focus = 3
		"start": screen = "loadout"
		"resume": screen = "playing"; mouse_attack_latched = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		"retry": restart_fight()
		"next": advance()
		"menu": screen = "title"; tutorial_active = false; training = false; menu_history.clear(); clear_touch()
		"select": tutorial_active = false; screen = "select"
		"begin": start_run()
		"tutorial": start_tutorial()
		"continue_run": continue_run()
		"training_attacks": training_attacks = not training_attacks
		"training_view": change_perspective(not side)
		"training":
			tutorial_active = false; run.reset(); equip_set(int(profile.data.weapon)); training = true; training_attacks = false; practice = true; start_fight(0); resonance = 100
		"arsenal": open_panel("arsenal")
		"help": open_panel("help")
		"difficulty": profile.data.difficulty = (int(profile.data.difficulty)+1)%3; profile.save_profile()
		"flashes": profile.data.flashes = not profile.data.flashes; profile.save_profile()
		"settings": open_panel("settings")
		"back": close_panel()
		"assist": profile.data.assist = not profile.data.assist; profile.save_profile()
		"shake": profile.data.shake = not profile.data.shake; profile.save_profile()
		"volume": profile.data.volume = fmod(float(profile.data.volume)+0.2,1.2); apply_volume(); profile.save_profile()
		"pulse": metronome = not metronome
		"close_help": screen = "playing"
		_:
			if action.begins_with("phone_inspect_"): upgrade_focus = clampi(int(action.trim_prefix("phone_inspect_")),0,upgrade_options.size()-1); return
			if action.begins_with("page_"): boss_page = clampi(int(action.trim_prefix("page_")),0,1); return
			if action.begins_with("set_"): equip_set(int(action.trim_prefix("set_")),true); return
			if action.begins_with("level_"): profile.data.difficulty = clampi(int(action.trim_prefix("level_")),0,2); profile.save_profile(); return
			if action.begins_with("upgrade_"): choose_upgrade(action.trim_prefix("upgrade_")); return
			if action.begins_with("boss_"):
				tutorial_active = false; practice = true; training = false; run.reset(int(profile.data.difficulty)); equip_set(int(profile.data.weapon))
				start_fight(int(action.trim_prefix("boss_")))

func start_fight(index: int) -> void:
	songs = SongBosses.new()
	menu_history.clear()
	mouse_attack_latched = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	fight_base_score = run.score; fight_base_time = run.time; fight_base_hits = run.hits
	fight_assisted = bool(profile.data.assist) or run.assisted
	weapon_index = run.loadout_index
	melee_snapshot.clear(); active_melee.clear(); melee_windup = 0
	reset_training_readout()
	boss_index = clampi(index,0,bosses.size()-1)
	max_hp = float(bosses[boss_index].hp)
	boss_hp = max_hp
	hp = run.stat("health")
	energy = run.stat("energy")
	resonance = 0
	side = false
	player = Vector2(350,440)
	boss = Vector2(900,355)
	velocity = Vector2.ZERO
	facing = Vector2.RIGHT
	shots.clear(); hazards.clear(); sparks.clear(); floats.clear(); rings.clear()
	stagger = 0; stagger_time = 0; stagger_lock = 0; style = 0; style_chain = 0
	last_action = ""; fight_score = 0; parries = 0; perfect_dodges = 0
	hit_stop = 0; ground_grace = 0; jump_buffer = 0; victory_accounted = false
	dash_time = 0; dash_cd = 0; invincible = 1; melee_cd = 0; shoot_cd = 0
	parry_cd = 0; parry_time = 0; charge_time = 0; windup = 0; phase = 0
	riposte_time = 0; bleed_time = 0; bleed_stacks = 0; bleed_tick = 0.5; followup_delay = 0; followup_pattern = ""
	combo = 0; combo_time = 0; attack_number = 0; elapsed = 0; hits = 0; attack_timer = 1.8
	shake = 0; boss_flash = 0
	banner = "MOVEMENT %02d  /  %s" % [boss_index+1,bosses[boss_index].name]
	banner_time = 2.6
	screen = "playing"
	print("RHAPSODY_FIGHT_READY movement=",boss_index+1)
	if phone_mode and phone.portrait: update_phone_camera(1)
	clear_touch()

func advance() -> void:
	if practice or boss_index >= bosses.size()-1: screen = "title"
	else:
		upgrade_options = run.choices(boss_index)
		upgrade_focus = 0; menu_focus = -1
		screen = "intermission"

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
	var pad: int = pads[0]
	if Vector2(Input.get_joy_axis(pad,JOY_AXIS_LEFT_X),Input.get_joy_axis(pad,JOY_AXIS_LEFT_Y)).length()>0.2:
		gamepad = true; used_touch = false
	for binding in [JOY_BUTTON_A,JOY_BUTTON_B,JOY_BUTTON_X,JOY_BUTTON_Y,JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_START,JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN]:
		var down = Input.is_joy_button_pressed(pad,binding)
		if down and not gamepad_previous.get(binding,false):
			gamepad = true; used_touch = false; ui_mouse_active = false
			if binding == JOY_BUTTON_START:
				if screen == "playing": screen = "paused"; clear_touch()
				elif screen == "paused": screen = "playing"
			elif screen == "playing":
				match binding:
					JOY_BUTTON_A: dodge()
					JOY_BUTTON_B: cycle_weapon()
					JOY_BUTTON_X: melee()
					JOY_BUTTON_Y: burst()
					JOY_BUTTON_LEFT_SHOULDER: parry()
					JOY_BUTTON_DPAD_UP: jump()
			elif not buttons.is_empty():
				if binding in [JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN]:
					navigate_menu(-1 if binding == JOY_BUTTON_DPAD_UP else 1)
				elif binding == JOY_BUTTON_A: command(buttons[maxi(0,menu_focus)%buttons.size()].action)
		gamepad_previous[binding] = down
	var jump_down = Input.get_joy_axis(pad,JOY_AXIS_LEFT_Y)<-0.65
	if screen == "playing" and side and jump_down and not gamepad_previous.get("jump",false): jump()
	gamepad_previous["jump"] = jump_down

func touch_action(index: int,p: Vector2) -> void:
	if p.distance_to(Vector2(1190,92)) < 40: screen = "paused"; clear_touch(); return
	for item in touch_layout():
		if item[1] == "jump" and not side: continue
		if p.distance_to(item[0])<42:
			touch_actions[index] = item[1]
			match item[1]:
				"melee": melee()
				"dodge": dodge()
				"parry": parry()
				"burst": burst()
				"jump": jump()
				"weapon": cycle_weapon()
				"attacks": training_attacks = not training_attacks
				"view": change_perspective(not side)
				"ranges": range_guides = not range_guides
				"reset_stats": reset_training_readout()
			return

func jump() -> void:
	if not side: return
	jump_buffer = 0.12
	if ground_grace>0 or player.y>=550:
		velocity.y = -CombatRules.JUMP_SPEED; ground_grace = 0; jump_buffer = 0; jump_cut = false
		sound.tone(310,0.07)

func dodge() -> void:
	if dash_cd>0 or energy<run.stat("dodge_cost"): return
	melee_snapshot.clear(); melee_windup = 0
	energy -= run.stat("dodge_cost")
	dash_cd = run.stat("dodge_cd")
	dash_rewarded = false
	dash_time = 0.17
	invincible = maxf(invincible,0.23)
	dash_dir = move_input()
	if side: dash_dir.y = 0
	if dash_dir.length()<0.1: dash_dir = last_move
	if side: dash_dir = Vector2(signf(dash_dir.x) if absf(dash_dir.x)>0.1 else 1,0)
	dash_dir = dash_dir.normalized()
	sound.tone(150,0.09)

func melee() -> void:
	if melee_cd>0 or not melee_snapshot.is_empty() or screen != "playing": return
	var weapon: Dictionary = Arsenal.SETS[weapon_index]
	combo = (combo%3)+1 if combo_time>0 else 1
	var step = combo-1
	melee_cd = float(weapon.melee_cooldown[step])
	combo_time = melee_cd+0.65
	var target_dir = player.direction_to(boss)
	if used_touch or gamepad or held(KEY_K): facing = target_dir
	else: facing = player.direction_to(mouse_world())
	var dash_strike = dash_time>0
	melee_snapshot = weapon.duplicate(true)
	melee_snapshot["power"] = (float(weapon.dash_damage) if dash_strike else float(weapon.melee_damage[step]))*run.stat("melee")
	if parry_enabled and weapon_index == 2 and riposte_time>0: melee_snapshot.power *= 1.5; riposte_time = 0
	melee_snapshot["reach"] = float(weapon.dash_range) if dash_strike else float(weapon.melee_range[step])
	melee_snapshot["facing"] = facing
	melee_snapshot["step"] = combo
	melee_snapshot["dash"] = dash_strike
	melee_windup = float(weapon.windup[step])
	active_melee = melee_snapshot.duplicate(true)
	melee_flash = 0
	sound.tone(130+weapon_index*70,0.05,0.05)

func shoot() -> void:
	if shoot_cd>0 or screen != "playing" or not melee_snapshot.is_empty(): return
	var character: Dictionary = Characters.ROSTER[weapon_index]
	if energy<float(character.cost): return
	energy -= float(character.cost)
	shoot_cd = float(character.cooldown)
	var aim = player.direction_to(boss) if used_touch or gamepad or held(KEY_J) else player.direction_to(mouse_world())
	facing = aim
	if weapon_index != 3:
		var attack = Arsenal.SETS[weapon_index].duplicate(true)
		attack["power"] = float(character.power)*run.stat("ranged")
		if parry_enabled and weapon_index == 2 and riposte_time>0: attack.power *= 1.5; riposte_time = 0
		attack["reach"] = float(character.reach); attack["facing"] = aim
		attack["arc"] = PI if weapon_index == 0 else 1.4
		attack["step"] = 1; attack["dash"] = weapon_index == 1; attack["skill"] = true
		attack["windup"] = [float(character.windup)]; attack["flash"] = 0.22
		melee_snapshot = attack; active_melee = attack.duplicate(true); melee_windup = float(character.windup)
		if weapon_index == 1:
			dash_dir = aim; dash_time = 0.08; invincible = maxf(invincible,0.08)
		if parry_enabled and weapon_index == 2: parry_time = maxf(parry_time,0.28)
		return
	if shots.size()>=340: return
	var weapon: Dictionary = Arsenal.SETS[3]
	var power = float(weapon.damage)*run.stat("ranged")*(1.25 if player.distance_to(boss)>=400 else 1.0)
	var shot = Shot.new(player+aim*24,aim*float(weapon.speed),true,power,float(weapon.radius))
	shot.max_distance = float(weapon.range)-24; shot.source_set = 3; shot.tint = Color(weapon.color)
	shots.append(shot)
	sound.tone(740,0.045,0.06)

func parry() -> void:
	if not parry_enabled: return
	if parry_cd>0: return
	parry_time = run.stat("parry")
	parry_cd = 0.85
	sound.tone(820,0.06)

func burst() -> void:
	if resonance<100: return
	resonance = 0
	if tutorial_active: tutorial.event("burst")
	shots = shots.filter(func(s): return s.friendly)
	hazards.clear()
	damage_boss(135)
	add_stagger(35)
	add_style("resonance",22)
	invincible = maxf(invincible,0.7)
	rings.append({"p":player,"r":20.0,"life":0.65,"max":0.65,"color":TEAL})
	emit_sparks(player,TEAL,45)
	shake = 9
	banner = "RESONANCE BREAK"; banner_time = 0.9
	sound.tone(110,0.4,0.3)

func damage_boss(amount: float) -> void:
	if screen != "playing": return
	if tutorial_active and tutorial.step<7:
		boss_flash = 0.08
		floats.append({"p":boss+Vector2(0,-55),"text":str(int(amount)),"life":0.55})
		return
	if training:
		var dealt = amount*(1.3 if stagger_time>0 else 1.0)*songs.multiplier(boss_index)
		boss_flash = 0.08
		fight_score += int(dealt)
		training_damage += dealt; training_hit_count += 1; training_last_hit = dealt
		training_window.append({"time":elapsed,"damage":dealt})
		if training_window.size()>200: training_window.pop_front()
		floats.append({"p":boss+Vector2(rng.randf_range(-20,20),-55),"text":str(int(dealt)),"life":0.55})
		return
	var dealt = amount*(1.3 if stagger_time>0 else 1.0)*songs.multiplier(boss_index)
	boss_hp = maxf(0,boss_hp-dealt)
	fight_score += int(dealt*(1.0+style/100.0))
	boss_flash = 0.08
	floats.append({"p":boss+Vector2(rng.randf_range(-20,20),-55),"text":str(int(amount)),"life":0.65})
	if boss_hp <= 0:
		if tutorial_active:
			tutorial.event("victory"); shots.clear(); hazards.clear(); return
		if not victory_accounted:
			victory_accounted = true
			profile.record_clear(boss_index,elapsed,hits,run.difficulty,fight_assisted,not practice)
			run.score += fight_score+int(1000*maxf(0,1-elapsed/180.0))
			run.time += elapsed; run.hits += hits
			if boss_index == bosses.size()-1 and not practice:
				profile.data.checkpoint = {}; profile.save_profile()
		screen = "clear"
		emit_sparks(boss,GOLD,80)
		sound.tone(523,0.35,0.2)

func hurt(amount: float) -> void:
	if invincible>0 or screen != "playing": return
	hp = maxf(0,hp-amount*float(RunState.DIFFICULTIES[run.difficulty].damage)*float(Characters.ROSTER[weapon_index].incoming)*(0.5 if profile.data.assist else 1.0)*(0.5 if tutorial_active else 1.0))
	hits += 1
	style = maxf(0,style-40); style_chain = 0
	invincible = 0.55
	shake = 10
	emit_sparks(player,CORAL,18)
	sound.tone(75,0.18,0.25)
	if training: hp = run.stat("health")
	elif hp <= 0:
		if tutorial_active: setup_tutorial_stage(); return
		screen = "dead"; melee_snapshot.clear(); melee_windup = 0

func emit_sparks(p: Vector2,color: Color,count: int) -> void:
	for i in count:
		if sparks.size()>=300: break
		sparks.append({"p":p,"v":Vector2.RIGHT.rotated(rng.randf()*TAU)*rng.randf_range(40,270),"life":rng.randf_range(0.2,0.65),"color":color})

func _process(raw_delta: float) -> void:
	if phone_mode and phone.portrait: update_phone_camera(minf(raw_delta,0.04))
	var delta = minf(raw_delta,0.04)
	total_time += delta
	gamepad_input()
	if screen == "playing":
		if hit_stop>0: hit_stop = maxf(0,hit_stop-delta)
		else: simulate(delta)
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
	songs.tick(delta)
	if profile.data.assist: fight_assisted = true; run.assisted = true
	elapsed += delta
	for prop in ["invincible","dash_time","dash_cd","melee_cd","melee_flash","shoot_cd","parry_time","parry_cd","boss_flash","banner_time","combo_time"]:
		set(prop,maxf(0,float(get(prop))-delta))
	if not melee_snapshot.is_empty():
		melee_windup = maxf(0,melee_windup-delta)
		if melee_windup<=0: resolve_melee()
	if screen != "playing": return
	training_window = training_window.filter(func(hit): return elapsed-float(hit.time)<=5.0)
	if not tutorial_active or tutorial.step != 4: energy = minf(run.stat("energy"),energy+delta*float(Characters.ROSTER[weapon_index].regen))
	riposte_time = maxf(0,riposte_time-delta)
	update_bleed(delta)
	if screen != "playing": return
	style = maxf(0,style-delta*4)
	stagger_lock = maxf(0,stagger_lock-delta)
	stagger_time = maxf(0,stagger_time-delta)
	if stagger_time<=0: stagger = maxf(0,stagger-delta*3)
	if training:
		hp = run.stat("health")
		resonance = minf(100,resonance+delta*25)
	if profile.data.assist: hp = minf(run.stat("health"),hp+delta*0.7)
	var move = move_input()
	if move.length()>0.15: last_move = move.normalized()
	if move.length()>0.15 and (used_touch or gamepad): facing = Vector2(signf(move.x),0) if side else move.normalized()
	if side:
		ground_grace = maxf(0,ground_grace-delta)
		jump_buffer = maxf(0,jump_buffer-delta)
		var previous_y = player.y
		velocity.x = move.x*float(Characters.ROSTER[weapon_index].speed)
		velocity.y += 1500*delta
		if dash_time>0: velocity = dash_dir*1000
		player += velocity*delta
		if velocity.y>=0:
			for platform in platforms():
				if (held(KEY_S) or move.y>0.65) and platform.position.y<580: continue
				if player.x>=platform.position.x-8 and player.x<=platform.end.x+8 and previous_y+22<=platform.position.y+5 and player.y+22>=platform.position.y:
					player.y = platform.position.y-22; velocity.y = 0; ground_grace = 0.1
		if player.y>=560: player.y = 560; velocity.y = 0; ground_grace = 0.1
		if jump_buffer>0 and ground_grace>0: jump()
		player.y = maxf(195,player.y)
	else:
		velocity = move*float(Characters.ROSTER[weapon_index].speed)
		if dash_time>0: velocity = dash_dir*1000
		player += velocity*delta
		player.y = clampf(player.y,190,580)
	player.x = clampf(player.x,125,1155)
	if dash_time>0: emit_sparks(player,TEAL,2)
	var shooting = held(KEY_J) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or "shoot" in touch_actions.values()
	var pads = Input.get_connected_joypads()
	if not pads.is_empty(): shooting = shooting or Input.get_joy_axis(pads[0],JOY_AXIS_TRIGGER_RIGHT)>0.25 or Input.is_joy_button_pressed(pads[0],JOY_BUTTON_RIGHT_SHOULDER)
	if shooting: shoot()
	if phone_mode and profile.data.auto_attack: phone_basic_attack()
	if "melee" in touch_actions.values() or held(KEY_K) or (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not mouse_attack_latched): melee()
	beat_timer += delta
	if beat_timer>=0.5:
		beat_timer -= 0.5; beat += 1
		if metronome: sound.tone(1000 if beat%4 == 0 else 650,0.035,0.035)
	if tutorial_active:
		update_tutorial(delta)
		if screen != "playing": return
	var new_phase = 2 if boss_hp/max_hp<0.33 else (1 if boss_hp/max_hp<0.67 else 0)
	if new_phase>phase and not tutorial_active:
		phase = new_phase
		change_perspective(phase == 1)
		return
	update_hazards(delta)
	if (not training or training_attacks) and (not tutorial_active or (tutorial.step == 7 and tutorial.transition<=0)): update_boss(delta)
	if screen != "playing": return
	for shot in shots:
		shot.step(delta)
		if shot.friendly:
			if shot.intersects(boss,43):
				damage_boss(shot.damage)
				if tutorial_active and shot.source_set == 3: tutorial.event("ability_hit")
				shot.life = 0; emit_sparks(shot.position,TEAL,3); gain_resonance(shot.damage*0.08); add_style("fire",shot.damage*0.08); add_stagger(shot.damage*0.06)
		else:
			if shot.intersects(player,14):
				if parry_enabled and parry_time>0:
					shot.friendly = weapon_index == 3
					if weapon_index != 3: shot.life = 0
					if weapon_index == 2: riposte_time = 1.5
					if tutorial_active: tutorial.event("parry")
					shot.velocity = shot.position.direction_to(boss)*900
					shot.tint = GOLD
					shot.damage = 28
					gain_resonance(18)
					parries += 1; add_stagger(18); add_style("parry",20)
					energy = minf(run.stat("energy"),energy+15)
					emit_sparks(player,GOLD,10)
					sound.tone(1100,0.13)
				elif dash_time>0:
					perfect_dodge()
				else: hurt(16); shot.life = 0
	for shot in shots:
		if shot.friendly and shot.life<=0 and shot.distance_traveled>=shot.max_distance: emit_sparks(shot.position,shot.tint,3)
	shots = shots.filter(func(s): return s.life>0 and Rect2(50,110,1180,560).has_point(s.position))

func change_perspective(to_side: bool) -> void:
	side = to_side
	shots.clear(); hazards.clear()
	melee_snapshot.clear(); melee_windup = 0; melee_flash = 0
	ground_grace = 0; jump_buffer = 0
	windup = 0; charge_time = 0; followup_delay = 0; followup_pattern = ""; attack_timer = 2.5
	player = Vector2(clampf(player.x,170,600),560 if side else 440)
	boss = Vector2(950,515 if side else 350)
	velocity = Vector2.ZERO
	invincible = 2.0
	banner = "FORM SHIFT  /  " + ("SIDE-SCROLLER · W TO JUMP" if side else "TOP-DOWN · MOVE FREELY")
	banner_time = 2.4
	sound.tone(220,0.3)

func update_boss(delta: float) -> void:
	if stagger_time>0: return
	if charge_time>0:
		charge_time -= delta; boss += charge_dir*720*delta
		boss.x = clampf(boss.x,160,1120); boss.y = clampf(boss.y,235,550)
		if boss.distance_to(player)<58: hurt(28)
		return
	if songs.recovery>0: return
	if windup>0:
		windup -= delta
		if windup<=0:
			execute_pattern(pending_pattern)
			if phase>0 and not chain_active and attack_number%2 == 0 and not tutorial_active and songs.recovery<=0:
				followup_delay = 0.4; followup_pattern = bosses[boss_index].get("followup",["fan","rain","prism"][mini(boss_index,2)])
		return
	if followup_delay>0:
		followup_delay -= delta
		if followup_delay<=0:
			pending_pattern = followup_pattern; aim_snapshot = player; windup = 0.48; chain_active = true
		return
	var offset = Vector2(cos(elapsed*0.9+boss_index)*170,sin(elapsed*1.2)*85)
	var destination = player+offset
	if boss.distance_to(player)>350: destination = player+player.direction_to(boss)*170
	if boss_index>=3: destination = songs.destination(self)
	if side: destination.y = 510
	destination.x = clampf(destination.x,175,1110); destination.y = clampf(destination.y,240,540)
	boss = boss.move_toward(destination,delta*([190,225,185,175][boss_index-3] if boss_index>=3 else 180+boss_index*25))
	if boss.distance_to(player)<53: hurt(18)
	attack_timer -= delta
	if attack_timer<=0:
		var patterns: Array = ["fan","cleave"] if tutorial_active else bosses[boss_index].patterns
		pending_pattern = patterns[attack_number%patterns.size()]
		if not tutorial_active and boss_index<3 and attack_number%2 == 1:
			if boss.distance_to(player)<155: pending_pattern = "cleave"
			elif boss.distance_to(player)>470: pending_pattern = "mines"
		attack_number += 1; chain_active = false
		aim_snapshot = player+(velocity*0.12).limit_length(70)
		windup = 0.9 if tutorial_active else ((0.72 if phase == 0 else 0.60) if boss_index>=3 else (0.62 if phase == 0 else 0.48))
		attack_timer = 1.4 if tutorial_active else float(bosses[boss_index].interval)*(1.0-0.14*phase)*float(RunState.DIFFICULTIES[run.difficulty].interval)

func enemy_shot(p: Vector2,angle: float,speed: float,size: float = 7) -> void:
	if shots.size()<350: shots.append(Shot.new(p,Vector2.RIGHT.rotated(angle)*speed,false,12,size))

func execute_pattern(pattern: String) -> void:
	if songs.execute(self,pattern): return
	var speed = 170.0 if tutorial_active else float(bosses[boss_index].speed)*(1+0.14*phase)*float(RunState.DIFFICULTIES[run.difficulty].speed)
	var angle = boss.angle_to_point(aim_snapshot)
	sound.tone(130+boss_index*30,0.1,0.09)
	match pattern:
		"cleave":
			var cleave = Hazard.new("mine",boss,boss,0.95 if tutorial_active else 0.62,0.3)
			cleave.area_radius = 125.0; hazards.append(cleave)
		"wave":
			var wave = Hazard.new("wave",boss,boss,0.65,4.5)
			wave.speed = 260+phase*35; hazards.append(wave)
		"mines":
			for i in 3:
				var p = Vector2(clampf(aim_snapshot.x+(i-1)*125,160,1120),560 if side else clampf(aim_snapshot.y+(i-1)*35,220,550))
				hazards.append(Hazard.new("mine",p,p,1.05,1.2))
		"prism":
			for i in 3:
				var direction = boss.direction_to(aim_snapshot).rotated((i-1)*0.4)
				hazards.append(Hazard.new("beam",boss,boss+direction*1250,1.0,0.45))
		"sweep":
			for i in 3:
				var y = 260+i*120 if not side else 390+i*86
				hazards.append(Hazard.new("beam",Vector2(115,y),Vector2(1165,y),0.9+i*0.45,0.32))
		"spiral":
			for i in 32:
				enemy_shot(boss,TAU*i/32+attack_number*0.4,speed*(0.6+(i%4)*0.13),6)
		"fan":
			var count = (5 if tutorial_active else 9)+phase*2+int(RunState.DIFFICULTIES[run.difficulty].density)
			for i in count: enemy_shot(boss,angle+(i-(count-1)/2.0)*0.15,speed)
		"ring":
			for i in 24+phase*4: enemy_shot(boss,TAU*i/(24+phase*4)+attack_number*0.23,speed*0.83)
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
	if phone_mode:
		phone.draw(self); return
	draw_rect(Rect2(0,0,1280,720),INK)
	for i in 36:
		var x = float(i)*39+fmod(total_time*7,39)
		line(Vector2(x,0),Vector2(x-200,720),Color(0.25,0.38,0.43,0.045))
	if screen in ["title","select","settings","loadout","intermission","help","arsenal"]:
		draw_menu()
		return
	draw_arena()
	draw_hud()
	if screen != "playing": draw_overlay()

func draw_menu() -> void:
	text_at("R / A",Vector2(58,62),22,TEAL)
	text_at("MOVEMENT UPDATE  /  0.6.1",Vector2(896,59),14,MUTED)
	line(Vector2(58,82),Vector2(1222,82),Color("293340"))
	if screen == "title":
		text_at("A HYBRID-PERSPECTIVE BOSS RUSH",Vector2(94,157),16,TEAL)
		text_at("RHAPSODY",Vector2(88,250),84)
		text_at("ALLEGRO",Vector2(94,307),42,CORAL)
		text_at("Change the form. Keep the fight.",Vector2(96,355),25)
		text_at("Four characters. One committed performance.",Vector2(96,389),17,MUTED)
		button("NEW PERFORMANCE" if profile.data.tutorial_complete else "PLAY THE TUTORIAL",Rect2(96,422,390,49),"start" if profile.data.tutorial_complete else "tutorial",true)
		button("REPLAY TUTORIAL" if profile.data.tutorial_complete else "NEW PERFORMANCE",Rect2(96,482,390,44),"tutorial" if profile.data.tutorial_complete else "start")
		button("CONTINUE" if not profile.data.checkpoint.is_empty() else "BOSS PRACTICE",Rect2(96,537,188,44),"continue_run" if not profile.data.checkpoint.is_empty() else "select")
		button("HOW TO PLAY",Rect2(298,537,188,44),"help")
		button("SETTINGS",Rect2(96,592,188,44),"settings")
		button("CHARACTERS",Rect2(298,592,188,44),"arsenal")
		text_at("WASD MOVE  ·  K STRIKE  ·  J ABILITY  ·  SPACE DODGE",Vector2(96,681),14,MUTED)
		draw_boss_figure(Vector2(920,330),0,2.4,Color("ef7854"))
		draw_arc(Vector2(920,330),185,-PI*0.85,PI*0.7,80,Color("33414e"),1.5,true)
		draw_arc(Vector2(920,330),194,-PI*0.3,PI*0.35,30,TEAL,2,true)
		text_at("I  /  THE METRONOME",Vector2(800,570),18,CORAL)
		text_at("Master the pattern. Break the form.",Vector2(795,607),17,MUTED)
	elif screen == "loadout":
		centered("SET THE TEMPO",167,38)
		centered("Choose your challenge and character. The character stays locked for the run.",209,18,MUTED)
		for i in 3:
			var x = 96+i*373
			var selected = int(profile.data.difficulty) == i
			draw_style_box(panel_style(Color("14272a") if selected else Color("141e29"),TEAL if selected else Color("33414e")),Rect2(x,255,343,200))
			text_at(RunState.DIFFICULTIES[i].name,Vector2(x+22,297),24,TEAL if selected else PAPER)
			text_at(["STANDARD","CHALLENGING","EXPERT"][i],Vector2(x+22,328),14,MUTED)
			text_at(["The intended first playthrough.","Faster, denser, harder hitting.","Every opening must be earned."][i],Vector2(x+22,364),16)
			button("SELECTED" if selected else "SELECT",Rect2(x+22,389,299,44),"level_"+str(i),selected)
		for i in Arsenal.SETS.size():
			var x = 96+i*278
			var selected = int(profile.data.weapon) == i
			button(Characters.ROSTER[i].name+" / "+Arsenal.SETS[i].name,Rect2(x,479,262,43),"set_"+str(i),selected)
		centered(Characters.ROSTER[int(profile.data.weapon)].ability+" · "+Characters.ROSTER[int(profile.data.weapon)].debuff,555,16,TEAL)
		button("BEGIN PERFORMANCE",Rect2(440,585,400,52),"begin",true)
		button("BACK",Rect2(96,620,180,44),"menu")
		button("BOSS PRACTICE",Rect2(930,620,250,44),"select")
	elif screen == "arsenal":
		centered("CHOOSE YOUR CHARACTER" if not character_locked() else "YOUR CHARACTER IS LOCKED",151,34)
		centered("Each has one set, a unique ability, a passive and a drawback. Inspect freely; select before the performance.",190,16,MUTED)
		for i in Characters.ROSTER.size():
			var character: Dictionary = Characters.ROSTER[i]
			var weapon: Dictionary = Arsenal.SETS[i]
			var x = 64+i*292; var c = Color(weapon.color)
			var selected = weapon_index == i
			draw_style_box(panel_style(Color("15222c"),c if selected else Color("33414e")),Rect2(x,220,276,404))
			draw_character_portrait(Vector2(x+138,269),i)
			text_at(character.name,Vector2(x+18,332),26,c)
			text_at(weapon.name+" / "+character.title,Vector2(x+18,357),13,MUTED)
			text_at("HP %d / SPEED %d" % [character.health,character.speed],Vector2(x+18,385),14)
			text_at(character.ability,Vector2(x+18,416),15,c)
			wrapped_text(character.ability_text,Vector2(x+18,438),240,13,MUTED)
			wrapped_text(character.passive,Vector2(x+18,489),240,13,TEAL)
			wrapped_text(character.debuff,Vector2(x+18,541),240,13,CORAL)
			if not character_locked(): button("SELECTED" if selected else "SELECT",Rect2(x+18,580,240,32),"set_"+str(i),selected)
			elif selected: text_at("CURRENT CHARACTER",Vector2(x+18,606),14,c)
		centered("J / right mouse / RT / ABILITY: character skill. Only Lyra fires bullets. Q inspects; it never swaps.",656,15,MUTED)
		button("BACK",Rect2(490,674,300,34),"back",true)
	elif screen == "select":
		centered("CHOOSE YOUR MOVEMENT",151,34)
		centered("Four song encounters are available now. A full performance includes all seven bosses.",188,17,MUTED)
		var first = 0 if boss_page == 0 else 3
		var last = 3 if boss_page == 0 else bosses.size()
		for i in range(first,last):
			var slot = i-first
			var x = 96+(slot%2)*552; var y = 220+(slot/2)*180
			var available = i>=3 or i<=int(profile.data.unlocked)
			var color = Color(bosses[i].color) if available else MUTED
			draw_style_box(panel_style(Color("141e29"),Color("33414e")),Rect2(x,y,532,166))
			draw_boss_figure(Vector2(x+65,y+91),i,0.60,color)
			text_at("MOVEMENT %02d" % (i+1),Vector2(x+126,y+23),11,color)
			text_at(bosses[i].name,Vector2(x+126,y+50),21)
			wrapped_text(bosses[i].get("song",bosses[i].subtitle)+(" · "+bosses[i].artist if i>=3 else ""),Vector2(x+126,y+73),385,13,MUTED)
			var key = profile.record_key(i,int(profile.data.difficulty))
			var best = "BEST %.1fs" % profile.data.best[key].time if profile.data.best.has(key) else "NO CLEAR YET"
			text_at(best,Vector2(x+126,y+122),12,MUTED)
			if available: button("PLAY",Rect2(x+336,y+112,175,37),"boss_"+str(i),true)
			else: text_at("CLEAR PREVIOUS BOSS",Vector2(x+126,y+148),12,MUTED)
		button("BACK",Rect2(96,620,160,44),"menu")
		button("ORIGINAL TRIO",Rect2(282,620,235,44),"page_0",boss_page == 0)
		button("SONG ENCOUNTERS",Rect2(535,620,265,44),"page_1",boss_page == 1)
		button("TRAINING",Rect2(926,620,250,44),"training")
	elif screen == "settings":
		centered("TUNE YOUR EXPERIENCE",153,36)
		centered("Settings save automatically. Assist records stay separate.",191,17,MUTED)
		button("VOLUME   %d%%" % int(float(profile.data.volume)*100),Rect2(390,224,500,45),"volume")
		button("SCREEN SHAKE   "+("ON" if profile.data.shake else "OFF"),Rect2(390,281,500,45),"shake")
		button("ASSIST MODE   "+("ON" if profile.data.assist else "OFF"),Rect2(390,338,500,45),"assist")
		button("IMPACT FLASHES   "+("ON" if profile.data.flashes else "REDUCED"),Rect2(390,395,500,45),"flashes")
		button("PRACTICE PULSE   "+("ON" if metronome else "OFF"),Rect2(390,452,500,45),"pulse")
		centered("Assist halves damage and regenerates vitality. Pulse is optional.",536,16,MUTED)
		centered("Combat never requires playing on the beat.",563,16,MUTED)
		button("BACK",Rect2(490,602,300,48),"back",true)
	elif screen == "intermission":
		centered("AN INTERLUDE",155,37,GOLD)
		centered("Hover, focus or tap a card to inspect its mechanics. Choose with its button.",198,17,MUTED)
		if not ui_mouse_active and menu_focus>=0 and menu_focus<upgrade_options.size(): upgrade_focus = menu_focus
		for i in upgrade_options.size():
			var upgrade: Dictionary = upgrade_options[i]
			var y = 228+i*124
			draw_style_box(panel_style(Color("1b2931") if i == upgrade_focus else Color("151f29"),GOLD if i == upgrade_focus else Color("435155")),Rect2(96,y,620,110))
			draw_upgrade_icon(Vector2(146,y+54),upgrade.icon)
			text_at(upgrade.name,Vector2(204,y+32),22,GOLD)
			text_at(upgrade.line1,Vector2(204,y+62),15)
			text_at(upgrade.line2,Vector2(204,y+87),13,MUTED)
			button("CHOOSE",Rect2(564,y+32,132,43),"upgrade_"+upgrade.id,true)
		draw_mechanic_panel()
		centered("Vitality and energy restore. Your checkpoint saves after choosing. Character stays locked.",642,15,TEAL)
		centered("RUN SCORE %d / %.1fs / %d HITS" % [run.score,run.time,run.hits],680,17)
	elif screen == "help":
		centered("THE COMBAT LANGUAGE",157,36)
		var entries = [
			["MOVE / DODGE","WASD or arrows · Space to dodge through danger. A close dodge builds resonance."],
			["STRIKE / DASH STRIKE","Hold K or click left mouse. Heavy attacks wind up; dodge cancels them without refunding recovery."],
			["FOUR CHARACTERS","Choose before a run. Q inspects your character. Only Lyra shoots; J uses each character ability."],
			["RESONANCE BREAK","Attacks and perfect dodges earn resonance. E spends 100 on a damaging break."],
			["STAGGER / STYLE","Mix blade hits, abilities and ranged fire. Fill stagger to open a +30% damage window."],
			["FORM SHIFTS","Boss health thresholds change perspective. W jumps in side view; S drops through platforms."],
			["CONTROLLER / TOUCH","Pad: X strike, RT ability, A dodge, Y burst, B inspect, D-pad up jump. Touch has labeled buttons."]
		]
		for i in entries.size():
			var y = 215+i*55
			text_at(entries[i][0],Vector2(96,y),15,TEAL)
			text_at(entries[i][1],Vector2(96,y+24),16,MUTED)
		button("BACK",Rect2(490,632,300,48),"back",true)

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
	draw_set_transform(arena_origin+offset*arena_scale,0,Vector2.ONE*arena_scale)
	draw_rect(FIELD,Color("101a26"))
	draw_architecture(color)
	for x in range(100,1181,54): line(Vector2(x,164),Vector2(x,604),Color("1b2936"))
	for y in range(164,605,44): line(Vector2(100,y),Vector2(1180,y),Color("1b2936"))
	draw_rect(FIELD,Color("3b4c59"),false,2)
	for p in [Vector2(100,164),Vector2(1180,164),Vector2(100,604),Vector2(1180,604)]:
		line(p-Vector2(10,0),p+Vector2(10,0),color,3)
		line(p-Vector2(0,10),p+Vector2(0,10),color,3)
	if side:
		draw_rect(Rect2(100,582,1080,22),Color("203743"))
		line(Vector2(100,582),Vector2(1180,582),TEAL,2)
		for platform in platforms():
			draw_rect(platform,Color("2a414b"))
			line(platform.position,Vector2(platform.end.x,platform.position.y),TEAL,2)
		for i in 14: line(Vector2(110+i*80,598),Vector2(125+i*80,584),Color("49616a"))
	else:
		draw_arc(Vector2(640,385),177,0,TAU,90,Color("263848"),1,true)
		draw_arc(Vector2(640,385),172,0,TAU,90,Color("1e303e"),1,true)
	text_at(bosses[boss_index].arena,Vector2(124,192),12,Color("587080"))
	if windup>0:
		var alpha = 0.25+0.2*sin(total_time*25)
		if pending_pattern in ["charge","fan","ember_dash","stage_dive","flame_fan"]:
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
		if boss_index>=3: centered(SongBosses.LABELS.get(pending_pattern,"CLOSE SWEEP · STEP BACK"),575,14,GOLD)
	for shot in shots:
		var c = shot.tint if shot.friendly else color
		if shot.friendly and shot.source_set == 0: draw_circle(shot.position,shot.radius+5,Color(c,0.13))
		var trail = [14.0,18.0,28.0,58.0][shot.source_set] if shot.friendly and shot.source_set>=0 else 12.0
		line(shot.position-shot.velocity.normalized()*trail,shot.position,Color(c,0.4),shot.radius*1.5)
		draw_circle(shot.position,shot.radius,c)
		if not shot.friendly: draw_circle(shot.position,shot.radius*0.4,INK)
	if boss_hp>0:
		draw_circle(boss+Vector2(0,45),41,Color(0,0,0,0.3))
		draw_boss_figure(boss,boss_index,1.0,PAPER if boss_flash>0 and profile.data.flashes else color)
		draw_arc(boss,59,0,TAU,48,Color(color,0.25),1,true)
	if tutorial_active and tutorial.step == 0:
		draw_rect(Rect2(900,470,130,100),Color(TEAL,0.08))
		draw_rect(Rect2(900,470,130,100),TEAL,false,2)
		text_at("CHECKPOINT",Vector2(909,495),14,TEAL)
	draw_player()
	for spark in sparks: draw_circle(spark.p,maxf(1,spark.life*5),Color(spark.color,minf(1,spark.life*2)))
	for ring in rings: draw_circle(ring.p,ring.r,Color(ring.color,ring.life/ring.max),false,5,true)
	for number in floats: text_at(number.text,number.p,19,Color(PAPER,minf(1,number.life*2)))
	draw_set_transform(Vector2.ZERO)

func draw_player() -> void:
	var blink = invincible>0 and int(total_time*16)%2 == 0
	var base = Color(Arsenal.SETS[weapon_index].color)
	var color = Color(base,0.45) if blink else base
	var stride = sin(elapsed*21)*4 if velocity.length()>40 and dash_time<=0 else 0.0
	draw_circle(player+Vector2(0,19),17,Color(0,0,0,0.3))
	var tail = player-facing*30+Vector2(0,sin(elapsed*12)*4)
	draw_colored_polygon(PackedVector2Array([player+Vector2(-7,-14),tail+Vector2(0,5),tail-Vector2(0,11)]),CORAL)
	line(player+Vector2(-5,4),player+Vector2(-8,18+stride),Color("416c77"),5)
	line(player+Vector2(5,4),player+Vector2(8,18-stride),Color("416c77"),5)
	draw_colored_polygon(PackedVector2Array([player+Vector2(-10,-12),player+Vector2(10,-12),player+Vector2(8,8),player+Vector2(-8,8)]),color)
	if weapon_index == 0:
		draw_rect(Rect2(player+Vector2(-16,-13),Vector2(10,22)),color)
		draw_rect(Rect2(player+Vector2(6,-13),Vector2(10,22)),color)
	elif weapon_index == 1:
		poly_at(player,[Vector2(-11,-16),Vector2(0,-32),Vector2(11,-16)],1.0,color)
	elif weapon_index == 2:
		poly_at(player,[Vector2(-8,-10),Vector2(-18,22),Vector2(0,12)],1.0,Color(base,0.7))
	else:
		poly_at(player,[Vector2(-12,-13),Vector2(12,-13),Vector2(15,22),Vector2(-15,22)],1.0,base.darkened(0.35))
		draw_arc(player+Vector2(0,-17),11,PI,TAU,16,base,3,true)
	draw_circle(player+Vector2(0,-17),8,Color("dfdfd1"))
	line(player+Vector2(-6,-18),player+Vector2(6,-18),INK,3)
	draw_equipped_weapon()
	if parry_enabled and parry_time>0: draw_circle(player,34,GOLD,false,4,true)
	if dash_time>0: line(player-dash_dir*55,player,Color(TEAL,0.6),5)

func draw_hud() -> void:
	text_at("R / A",Vector2(42,45),20,TEAL)
	text_at("MOVEMENT %02d" % (boss_index+1),Vector2(124,43),14,MUTED)
	text_at("FIRST NOTES / TUTORIAL" if tutorial_active else bosses[boss_index].name,Vector2(124,76),28)
	var subtitle = bosses[boss_index].song+" · "+bosses[boss_index].artist if boss_index>=3 else bosses[boss_index].subtitle
	text_at("Practice, learn and finish the rehearsal encounter." if tutorial_active else subtitle,Vector2(124,100),14,MUTED)
	bar(Rect2(124,118,1032,7),boss_hp/max_hp,Color(bosses[boss_index].color))
	for threshold in [0.33,0.67]: line(Vector2(124+1032*threshold,115),Vector2(124+1032*threshold,128),PAPER,2)
	text_at("%d / %d" % [int(boss_hp),int(max_hp)],Vector2(1010,100),14,MUTED)
	text_at("%02d:%02d" % [int(elapsed)/60,int(elapsed)%60],Vector2(1058,44),20)
	text_at("SIDE-SCROLLER" if side else "TOP-DOWN",Vector2(895,74),14,TEAL)
	text_at("II",Vector2(1180,100),26,MUTED)
	text_at("VITALITY  %d" % int(hp),Vector2(100,638),14,PAPER)
	bar(Rect2(100,650,240,7),hp/run.stat("health"),CORAL)
	text_at(Characters.ROSTER[weapon_index].name+(" / READY" if shoot_cd<=0 else " / %.1fs" % shoot_cd),Vector2(370,638),14,Color(Arsenal.SETS[weapon_index].color))
	bar(Rect2(370,650,190,7),energy/run.stat("energy"),TEAL)
	text_at("RESONANCE"+ ("  /  E TO BREAK" if resonance>=100 else ""),Vector2(590,638),14,GOLD)
	bar(Rect2(590,650,290,7),resonance/100,GOLD)
	text_at("DODGE READY" if dash_cd<=0 else "DODGE %.1f" % dash_cd,Vector2(930,692 if used_touch else 638),14,MUTED)
	bar(Rect2(930,702 if used_touch else 650,105,5),1.0-dash_cd/run.stat("dodge_cd"),TEAL)
	text_at("ASSIST" if profile.data.assist else RunState.DIFFICULTIES[run.difficulty].name,Vector2(1060,659),12,TEAL if profile.data.assist else MUTED)
	if not used_touch:
		centered("K / LMB STRIKE · J / RMB ABILITY · Q INSPECT · SPACE DODGE · E BURST · H HELP · ESC PAUSE",701,13,MUTED)
	bar(Rect2(124,133,1032,3),1.0 if stagger_time>0 else stagger/100.0,GOLD)
	var grade = "S" if style>=80 else ("A" if style>=55 else ("B" if style>=30 else "C"))
	text_at("STYLE "+grade+"  /  %d" % fight_score,Vector2(120,157),13,GOLD)
	text_at("STAGGERED" if stagger_time>0 else "STAGGER",Vector2(1057,153),11,GOLD)
	if not training and not tutorial_active:
		if parry_enabled and riposte_time>0: text_at("RIPOSTE READY",Vector2(800,153),12,GOLD)
		elif bleed_stacks>0: text_at("BLEED x%d" % bleed_stacks,Vector2(800,153),12,CORAL)
	if boss_index>=3 and not training and not tutorial_active:
		var encounter: Dictionary = bosses[boss_index]
		var state = encounter.phases[phase]
		if boss_index == 4: state += " · HEAT %d / 4" % songs.heat if songs.recovery<=0 else " · OVERHEATED %.1fs" % songs.recovery
		if boss_index == 6: state += " · VOLUME %d / 3" % songs.volume if songs.recovery<=0 else " · SILENCE %.1fs" % songs.recovery
		text_at(state,Vector2(360,153),12,GOLD)
		if elapsed<14: centered(encounter.tip,677,13,GOLD)
		elif not songs.attack_label.is_empty() and windup<=0: centered(songs.attack_label,677,13,GOLD)
	if training:
		text_at("TRAINING · NO RECORDS · T ATTACKS "+("ON" if training_attacks else "OFF")+" · V SHIFT VIEW",Vector2(360,153),13,TEAL)
	if banner_time>0 and screen == "playing":
		draw_rect(Rect2(200,284,880,78),Color(0.03,0.05,0.08,0.93))
		centered(banner,330,22,TEAL)
	elif elapsed<14 and screen == "playing" and not used_touch and not training and boss_index<3:
		centered("Melee restores energy. Mix actions to build stagger and style.",678,12,GOLD)
	if training:
		draw_rect(Rect2(114,198,326,61),Color(INK,0.9))
		text_at("TOTAL %d  ·  HITS %d  ·  LAST %.0f" % [int(training_damage),training_hit_count,training_last_hit],Vector2(125,221),13,TEAL)
		text_at("5s DPS %.1f  ·  G RANGE  ·  R RESET" % training_dps(),Vector2(125,244),13,MUTED)
	if tutorial_active: draw_tutorial_hud()
	if used_touch and screen == "playing": draw_touch()

func draw_touch() -> void:
	var origin = touch_origin if move_finger>=0 else Vector2(210,520)
	draw_circle(origin,65,Color(TEAL,0.08))
	draw_circle(origin,65,Color(TEAL,0.3),false,2,true)
	draw_circle(origin+touch_move*55,23,Color(TEAL,0.5))
	for item in touch_layout():
		if item[1] == "jump" and not side: continue
		draw_circle(item[0],35,Color(0.05,0.12,0.17,0.85))
		draw_circle(item[0],35,Color(TEAL,0.45),false,2,true)
		text_at(item[2],item[0]+Vector2(-24,5),12,TEAL)

func draw_overlay() -> void:
	draw_rect(Rect2(0,0,1280,720),Color(0.02,0.035,0.055,0.88))
	if screen == "paused":
		centered("A MOMENT OF SILENCE",235,38)
		centered("Character locked · Q inspects · H opens the combat guide",278,18,MUTED)
		button("RESUME",Rect2(450,320,380,52),"resume",true)
		button("SETTINGS",Rect2(450,390,380,48),"settings")
		button("RESTART MOVEMENT",Rect2(450,454,380,48),"retry")
		button("CHARACTER DETAILS",Rect2(450,518,380,48),"arsenal")
		button("COMBAT GUIDE",Rect2(90,518,285,48),"help")
		button("TITLE SCREEN",Rect2(450,582,380,48),"menu")
		if boss_index>=3:
			var encounter: Dictionary = bosses[boss_index]
			draw_style_box(panel_style(Color("14212c"),Color(encounter.color)),Rect2(870,320,330,286))
			text_at("ENCOUNTER NOTES",Vector2(890,349),14,GOLD)
			var y = wrapped_text(encounter.song+" · "+encounter.artist,Vector2(890,378),290,16)
			y = wrapped_text(encounter.mechanic,Vector2(890,y+14),290,14,TEAL)
			wrapped_text(encounter.tip+" Gold warnings are safe. Dodge through incoming attacks.",Vector2(890,y+12),290,14,MUTED)
		if training:
			button("ATTACKS "+("ON" if training_attacks else "OFF"),Rect2(90,390,285,48),"training_attacks")
			button("SWITCH PERSPECTIVE",Rect2(90,454,285,48),"training_view")
	elif screen == "tutorial_clear":
		centered("FIRST NOTES COMPLETE",252,39,TEAL)
		centered("Movement, strikes, abilities, dodging, energy, resonance and form shifts.",302,18,MUTED)
		centered("Your first real performance awaits.",350,23)
		button("CHOOSE A PERFORMANCE",Rect2(440,410,400,54),"start",true)
		button("TITLE SCREEN",Rect2(440,485,400,48),"menu")
	elif screen == "dead":
		centered("A REST, NOT THE END.",254,40,CORAL)
		centered("Read the warning. Find the opening. Try again.",302,21,MUTED)
		centered("%.1f SECONDS  /  %d HITS TAKEN" % [elapsed,hits],354,17)
		button("RETRY MOVEMENT",Rect2(450,401,380,54),"retry",true)
		button("SETTINGS / ASSIST",Rect2(450,475,380,48),"settings")
		button("TITLE SCREEN",Rect2(450,540,380,48),"menu")
	elif screen == "clear":
		centered("MOVEMENT COMPLETE" if boss_index<bosses.size()-1 else "FINALE COMPLETE",239,40,GOLD)
		centered(bosses[boss_index].name+"  /  SILENCED",291,20,MUTED)
		var rank = "S" if hits == 0 else ("A" if hits<=3 else ("B" if hits<=6 else "C"))
		centered("%s     %.1fs     %d HITS" % [rank,elapsed,hits],364,34)
		centered("%d PERFECT DODGES  /  SCORE %d" % [perfect_dodges,fight_score],400,16,TEAL)
		button("CHOOSE AUGMENTATION" if boss_index<bosses.size()-1 and not practice else "RETURN TO TITLE",Rect2(450,445,380,54),"next",true)
		button("PLAY AGAIN",Rect2(450,516,380,48),"retry")
		centered("PERFORMANCE TOTAL  %d  /  %.1fs  /  %d HITS" % [run.score,run.time,run.hits],608,18,GOLD)

func clear_touch() -> void:
	touch_actions.clear(); touches.clear(); touch_move = Vector2.ZERO; move_finger = -1; phone_jump_held = false

func start_run() -> void:
	tutorial_active = false
	practice = false; training = false
	run.reset(int(profile.data.difficulty))
	equip_set(int(profile.data.weapon))
	profile.data.checkpoint = run.snapshot(0,bool(profile.data.assist)); profile.save_profile()
	start_fight(0)

func continue_run() -> void:
	tutorial_active = false
	var checkpoint: Dictionary = profile.data.checkpoint
	if checkpoint.is_empty() or not run.restore(checkpoint):
		profile.data.checkpoint = {}; profile.save_profile(); screen = "loadout"; return
	profile.data.assist = bool(checkpoint.get("assist",false))
	training = false; practice = false
	start_fight(int(checkpoint.boss))

func choose_upgrade(id: String) -> void:
	if screen != "intermission" or run.has(id) or not upgrade_options.any(func(u): return u.id == id): return
	run.upgrades.append(id)
	profile.data.checkpoint = run.snapshot(boss_index+1,bool(profile.data.assist))
	profile.save_profile()
	start_fight(boss_index+1)

func cycle_weapon() -> void:
	# Character inspection pauses combat; equipment never changes in the encounter.
	if screen == "playing": open_panel("arsenal")

func gain_resonance(amount: float) -> void:
	resonance = minf(100,resonance+amount*run.stat("resonance"))

func add_style(action: String,amount: float) -> void:
	style = minf(100,style+amount*(1.5 if action != last_action else 0.5))
	if action != last_action: style_chain += 1
	last_action = action

func add_stagger(amount: float) -> void:
	if stagger_lock>0 or stagger_time>0: return
	stagger = minf(100,stagger+amount)
	if stagger>=100:
		stagger = 0; stagger_time = 1.25; stagger_lock = 7.0
		windup = 0; charge_time = 0; followup_delay = 0; followup_pattern = ""; attack_timer = 1.1
		banner = "STAGGER  /  DAMAGE +30%"; banner_time = 1.1
		emit_sparks(boss,GOLD,30)
		sound.tone(180,0.25)

func perfect_dodge() -> void:
	if dash_rewarded: return
	dash_rewarded = true
	perfect_dodges += 1
	if tutorial_active: tutorial.event("perfect_dodge")
	gain_resonance(12)
	add_style("perfect dodge",16)
	floats.append({"p":player+Vector2(-40,-35),"text":"PERFECT","life":0.8})
	sound.tone(950,0.1,0.06)

func platforms() -> Array[Rect2]:
	if not side: return []
	return [Rect2(300,472,190,9),Rect2(610,392,165,9),Rect2(880,455,185,9)]

func update_hazards(delta: float) -> void:
	for hazard in hazards:
		hazard.step(delta)
		if hazard.intersects(player):
			if dash_time>0: perfect_dodge()
			else: hurt(22)
	hazards = hazards.filter(func(h): return not h.expired())
	if hazards.size()>24: hazards.resize(24)

func touch_layout() -> Array:
	var layout = [[Vector2(1080,555),"melee","BLADE"],[Vector2(1180,460),"shoot","ABILITY"],[Vector2(965,630),"dodge","DODGE"],[Vector2(1180,630),"parry","PARRY"],[Vector2(1080,370),"burst","BURST"],[Vector2(860,555),"jump","JUMP"]]
	if training:
		layout.append([Vector2(600,215),"attacks","ATK"])
		layout.append([Vector2(700,215),"view","VIEW"])
		layout.append([Vector2(800,215),"ranges","RANGE"])
		layout.append([Vector2(900,215),"reset_stats","RESET"])
	return layout.filter(func(item): return parry_enabled or item[1] != "parry")

func draw_architecture(color: Color) -> void:
	if boss_index>=3:
		songs.draw_arena(self,boss_index,color); return
	var faint = Color(color,0.10)
	if boss_index == 0:
		var center = Vector2(640,380)
		for i in 12:
			var direction = Vector2.UP.rotated(TAU*i/12)
			line(center+direction*180,center+direction*200,faint,4)
		line(center,center+Vector2.RIGHT.rotated(elapsed*0.1)*145,faint,3)
		line(center,center+Vector2.UP.rotated(elapsed*0.04)*100,faint,5)
		for x in [135,1135]:
			for y in [235,330,425,520]: draw_rect(Rect2(x,y,10,42),faint)
	elif boss_index == 1:
		for i in 9:
			var x = 150+i*128
			var height = 35+sin(i*1.4)*25
			draw_colored_polygon(PackedVector2Array([Vector2(x,596),Vector2(x+23,596-height),Vector2(x+46,596)]),faint)
		for i in 6:
			var x = 170+i*195
			line(Vector2(x,165),Vector2(x+80,360),Color(color,0.045),24)
	else:
		for i in 7:
			var x = 155+i*160
			line(Vector2(x,166),Vector2(x,266+sin(elapsed+i)*30),faint,2)
			line(Vector2(x,266+sin(elapsed+i)*30),Vector2(x+55,330),faint,1)
		for i in 5:
			draw_arc(Vector2(640,620),110+i*75,PI,TAU,50,Color(color,0.06),2,true)

func poly_at(p: Vector2,points: Array,scale_factor: float,color: Color) -> void:
	var packed = PackedVector2Array()
	for point in points: packed.append(p+point*scale_factor)
	draw_colored_polygon(packed,color)

func draw_boss_figure(p: Vector2,index: int,size: float,color: Color) -> void:
	if index>=3:
		songs.draw_figure(self,p,index,size,color); return
	var dark = Color(color.darkened(0.7),1)
	var swing = sin(total_time*2.0)*8
	if index == 0:
		# Clockwork sentinel: segmented limbs, dial torso and pendulum crown.
		for sign_x in [-1,1]:
			line(p+Vector2(sign_x*26,-12)*size,p+Vector2(sign_x*55,7+swing)*size,color,6*size)
			line(p+Vector2(sign_x*55,7+swing)*size,p+Vector2(sign_x*65,-23)*size,color,4*size)
			draw_circle(p+Vector2(sign_x*55,7+swing)*size,5*size,GOLD)
			line(p+Vector2(sign_x*15,25)*size,p+Vector2(sign_x*24,54)*size,color,6*size)
		poly_at(p,[Vector2(-30,-22),Vector2(0,-38),Vector2(30,-22),Vector2(30,20),Vector2(0,38),Vector2(-30,20)],size,dark)
		draw_circle(p,30*size,color,false,3*size,true)
		for i in 8:
			var d = Vector2.UP.rotated(TAU*i/8)
			line(p+d*23*size,p+d*28*size,GOLD,1.5*size)
		line(p,p+Vector2.UP.rotated(total_time*2)*22*size,PAPER,2*size)
		draw_circle(p,5*size,GOLD)
		line(p+Vector2(0,-36)*size,p+Vector2(swing,-58)*size,color,3*size)
		draw_circle(p+Vector2(swing,-62)*size,9*size,PAPER)
		line(p+Vector2(swing-4,-62)*size,p+Vector2(swing+4,-62)*size,INK,2*size)
	elif index == 1:
		# A glass singer with six floating crystal feathers.
		for sign_x in [-1,1]:
			for i in 3:
				var x = sign_x*(38+i*15)
				var y = -30+i*19+sin(total_time*2+i)*5
				poly_at(p,[Vector2(x,y-21),Vector2(x+sign_x*15,y),Vector2(x,y+29),Vector2(x-sign_x*7,y)],size,Color(color,0.75-i*0.12))
		poly_at(p,[Vector2(0,-45),Vector2(28,-3),Vector2(0,49),Vector2(-28,-3)],size,color)
		poly_at(p,[Vector2(0,-37),Vector2(15,-3),Vector2(0,37),Vector2(-8,-3)],size,dark)
		draw_circle(p+Vector2(0,-53)*size,10*size,PAPER)
		line(p+Vector2(-5,-54)*size,p+Vector2(5,-54)*size,INK,2*size)
		draw_arc(p+Vector2(0,-53)*size,18*size,PI,TAU,20,color,2*size,true)
	else:
		# The conductor, suspended by strings, with a long coat and baton.
		for sign_x in [-1,1]:
			line(p+Vector2(sign_x*20,-15)*size,p+Vector2(sign_x*48,-38+swing)*size,color,4*size)
			line(p+Vector2(sign_x*48,-38+swing)*size,p+Vector2(sign_x*65,-20)*size,color,3*size)
			line(p+Vector2(sign_x*48,-38+swing)*size,p+Vector2(sign_x*48,-95)*size,Color(color,0.3),size)
		poly_at(p,[Vector2(-18,-25),Vector2(18,-25),Vector2(35,55),Vector2(0,40),Vector2(-35,55)],size,dark)
		line(p+Vector2(0,-23)*size,p+Vector2(0,38)*size,color,2*size)
		poly_at(p,[Vector2(-11,-56),Vector2(11,-56),Vector2(15,-35),Vector2(0,-27),Vector2(-15,-35)],size,PAPER)
		line(p+Vector2(-6,-44)*size,p+Vector2(6,-44)*size,INK,2*size)
		line(p+Vector2(65,-20)*size,p+Vector2(85,-57)*size,GOLD,3*size)
		draw_circle(p+Vector2(85,-57)*size,4*size,GOLD)
		draw_circle(p,10*size,color,false,2*size,true)
	if stagger_time>0 and screen == "playing":
		draw_arc(p,72*size,total_time*2,total_time*2+PI,24,GOLD,2,true)

func draw_upgrade_icon(p: Vector2,type: String) -> void:
	draw_circle(p,40,Color(GOLD,0.06))
	draw_circle(p,40,Color(GOLD,0.3),false,1,true)
	match type:
		"blade": line(p+Vector2(-18,20),p+Vector2(18,-20),GOLD,5); line(p+Vector2(-20,0),p+Vector2(2,20),PAPER,3)
		"cell": draw_rect(Rect2(p-Vector2(17,24),Vector2(34,48)),GOLD,false,3); line(p-Vector2(9,0),p+Vector2(9,0),GOLD,3)
		"step":
			for i in 3: line(p+Vector2(-22+i*16,-15),p+Vector2(-10+i*16,0),GOLD,3); line(p+Vector2(-10+i*16,0),p+Vector2(-22+i*16,15),GOLD,3)
		"guard": draw_arc(p,24,PI,TAU,24,GOLD,4,true); line(p+Vector2(-24,0),p+Vector2(0,27),GOLD,3); line(p+Vector2(24,0),p+Vector2(0,27),GOLD,3)
		"heart": poly_at(p,[Vector2(0,24),Vector2(-26,-3),Vector2(-14,-20),Vector2(0,-9),Vector2(14,-20),Vector2(26,-3)],1.0,GOLD)
		_:
			for i in 3: draw_arc(p,10+i*9,-PI*0.7,PI*0.7,20,GOLD,2,true)

func restart_fight() -> void:
	run.score = fight_base_score; run.time = fight_base_time; run.hits = fight_base_hits
	if not training and not practice:
		profile.data.checkpoint = run.snapshot(boss_index,bool(profile.data.assist))
		profile.save_profile()
	start_fight(boss_index)

func navigate_menu(direction: int) -> void:
	if buttons.is_empty(): return
	if menu_focus<0: menu_focus = 0 if direction>0 else buttons.size()-1
	else: menu_focus = posmod(menu_focus+direction,buttons.size())

func equip_set(index: int,persist: bool = false) -> bool:
	if character_locked(): return false
	weapon_index = Arsenal.valid_index(index)
	run.loadout_index = weapon_index
	combo = 0; combo_time = 0
	if persist:
		profile.data.weapon = weapon_index; profile.save_profile()
	return true

func resolve_melee() -> void:
	if melee_snapshot.is_empty() or screen != "playing": return
	var attack = melee_snapshot.duplicate(true)
	melee_snapshot.clear(); melee_windup = 0
	active_melee = attack
	melee_flash = float(attack.flash)
	var distance = player.distance_to(boss)
	var facing_target = attack.facing.dot(player.direction_to(boss))
	if distance<=float(attack.reach) and (distance<1 or facing_target>=cos(float(attack.arc))):
		damage_boss(float(attack.power))
		if weapon_index == 1: bleed_stacks = mini(3,bleed_stacks+1); bleed_time = 3.0
		if tutorial_active: tutorial.event("ability_hit" if attack.get("skill",false) else "melee_hit")
		var finisher = 1.4 if int(attack.step) == 3 else 1.0
		gain_resonance(float(attack.resonance)*finisher)
		add_stagger(float(attack.stagger)*finisher*(0.8 if weapon_index == 2 and not attack.get("skill",false) else 1.0))
		add_style("dash strike" if attack.dash else "blade",float(attack.resonance))
		if run.has("siphon"): hp = minf(run.stat("health"),hp+float(attack.power)*0.05)
		var recovery_bonus = 8.0 if weapon_index == 2 and not parry_enabled and int(attack.step) == 3 and not attack.get("skill",false) else 0.0
		energy = minf(run.stat("energy"),energy+float(attack.energy_return)+recovery_bonus)
		hit_stop = 0.0 if attack.shape == "knives" else minf(0.065,float(attack.flash)*0.22)
		emit_sparks(boss,Color(attack.color),18 if attack.shape == "hammer" else 8)
		sound.tone(170+int(attack.step)*60+weapon_index*65,0.12 if attack.shape == "hammer" else 0.05)
	else: sound.tone(160,0.04,0.04)

func reset_training_readout() -> void:
	training_damage = 0; training_hit_count = 0; training_last_hit = 0; training_window.clear()

func training_dps() -> float:
	var damage := 0.0
	for hit in training_window: damage += float(hit.damage)
	return damage/5.0

func draw_weapon_badge(p: Vector2,weapon: Dictionary) -> void:
	var c = Color(weapon.color)
	draw_circle(p,38,Color(c,0.07)); draw_circle(p,38,Color(c,0.25),false,1,true)
	match weapon.shape:
		"hammer": line(p+Vector2(-14,24),p+Vector2(12,-17),PAPER,4); poly_at(p,[Vector2(-2,-25),Vector2(28,-8),Vector2(16,10),Vector2(-14,-6)],1,c)
		"knives":
			for sign_x in [-1,1]: poly_at(p,[Vector2(sign_x*11,25),Vector2(sign_x*8,-27),Vector2(sign_x*24,-5)],1,c)
		"saber": poly_at(p,[Vector2(-15,24),Vector2(10,-22),Vector2(27,-28),Vector2(-5,22)],1,c); line(p+Vector2(-22,11),p+Vector2(0,26),PAPER,3)
		"spear": line(p+Vector2(-22,24),p+Vector2(17,-18),c,3); poly_at(p,[Vector2(11,-24),Vector2(29,-30),Vector2(22,-12)],1,PAPER)

func draw_equipped_weapon() -> void:
	var weapon: Dictionary = active_melee if (melee_windup>0 or melee_flash>0) and not active_melee.is_empty() else Arsenal.SETS[weapon_index]
	var aim: Vector2 = weapon.get("facing",facing)
	var normal = aim.orthogonal()
	var c = Color(weapon.color)
	var hand = player+aim*18
	line(player+Vector2(2,-1),hand,PAPER,3)
	match weapon.shape:
		"hammer":
			line(hand,player+aim*42,PAPER,4)
			draw_colored_polygon(PackedVector2Array([player+aim*34-normal*10,player+aim*49-normal*10,player+aim*49+normal*10,player+aim*34+normal*10]),c)
		"knives":
			for sign_x in [-1,1]: line(player+normal*sign_x*9+aim*12,player+normal*sign_x*9+aim*36,c,3)
		"saber": line(hand,player+aim*53,c,4); line(hand-normal*7,hand+normal*7,PAPER,2)
		"spear": line(player-aim*9,player+aim*62,c,3); draw_colored_polygon(PackedVector2Array([player+aim*75,player+aim*59-normal*5,player+aim*59+normal*5]),PAPER)

func open_panel(panel: String) -> void:
	if screen == panel: return
	if panel == "arsenal": phone.character_focus = weapon_index
	menu_history.append(screen)
	settings_from = screen; screen = panel
	menu_focus = -1

func close_panel() -> void:
	screen = menu_history.pop_back() if not menu_history.is_empty() else settings_from
	settings_from = menu_history.back() if not menu_history.is_empty() else "title"
	menu_focus = -1

func character_locked() -> bool:
	if screen in ["playing","paused","dead","clear","intermission"]: return true
	for prior in menu_history:
		if prior in ["playing","paused","dead","clear","intermission"]: return true
	return false

func update_bleed(delta: float) -> void:
	if bleed_time<=0: bleed_stacks = 0; return
	bleed_time = maxf(0,bleed_time-delta); bleed_tick -= delta
	if bleed_tick<=0:
		bleed_tick += 0.5
		damage_boss(float(bleed_stacks)*1.5)

func start_tutorial() -> void:
	training = false; practice = true; tutorial_active = true
	run.reset(); equip_set(int(profile.data.weapon))
	tutorial = Tutorial.new()
	start_fight(0); setup_tutorial_stage()

func setup_tutorial_stage() -> void:
	shots.clear(); hazards.clear(); melee_snapshot.clear(); active_melee.clear()
	melee_windup = 0; melee_flash = 0; melee_cd = 0; shoot_cd = 0
	bleed_time = 0; bleed_stacks = 0; bleed_tick = 0.5; charge_time = 0; windup = 0
	followup_delay = 0; followup_pattern = ""; attack_timer = 1.8
	hp = run.stat("health"); energy = 25.0 if tutorial.step == 4 else run.stat("energy"); invincible = 1.0
	resonance = 100 if tutorial.step == 5 else 0
	dash_cd = 0; dash_time = 0; parry_cd = 0; parry_time = 0
	side = tutorial.step == 6; velocity = Vector2.ZERO
	player = Vector2(260,560 if side else 440)
	boss = Vector2(760,515 if side else 420)
	max_hp = 480 if tutorial.step == 7 else 900; boss_hp = max_hp
	phase = 0; banner_time = 0; tutorial_shot_timer = 1.2
	if tutorial.step == 3: player = Vector2(640,440)
	if tutorial.step == 4: player = Vector2(400,440)
	if tutorial.step == 7: player = Vector2(340,440); boss = Vector2(850,380)
	if phone_mode and phone.portrait: update_phone_camera(1)

func update_tutorial(delta: float) -> void:
	if tutorial.tick(delta):
		if tutorial.complete:
			profile.data.tutorial_complete = true; profile.save_profile()
			tutorial_active = false; screen = "tutorial_clear"; clear_touch(); return
		setup_tutorial_stage()
	if tutorial.step == 0 and Rect2(900,470,130,100).has_point(player): tutorial.event("checkpoint")
	if tutorial.step == 6 and player.x>=300 and player.x<=490 and absf(player.y-450)<2 and ground_grace>0: tutorial.event("platform")
	if tutorial.step == 3 and tutorial.transition<=0:
		tutorial_shot_timer -= delta
		if tutorial_shot_timer<=0:
			tutorial_shot_timer = 1.8
			var spawn = Vector2(player.x+240,player.y)
			if spawn.x>1140: spawn.x = player.x-240
			enemy_shot(spawn,spawn.angle_to_point(player),170,8)

func wrapped_text(value: String,p: Vector2,width: float,size: int = 16,color: Color = PAPER) -> float:
	var current := ""
	var y = p.y
	for word in value.split(" "):
		var test = word if current.is_empty() else current+" "+word
		if font.get_string_size(test,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>width and not current.is_empty():
			text_at(current,Vector2(p.x,y),size,color); y += size+7; current = word
		else: current = test
	if not current.is_empty(): text_at(current,Vector2(p.x,y),size,color); y += size+7
	return y

func inspect_upgrade_at(p: Vector2) -> void:
	for i in upgrade_options.size():
		if Rect2(96,228+i*124,620,110).has_point(p): upgrade_focus = i; menu_focus = -1; return

func draw_mechanic_panel() -> void:
	if upgrade_options.is_empty(): return
	upgrade_focus = clampi(upgrade_focus,0,upgrade_options.size()-1)
	var upgrade: Dictionary = upgrade_options[upgrade_focus]
	var topics: Array = Mechanics.TOPICS[upgrade.id]
	var primary: Dictionary = Mechanics.ENTRIES[topics[0]]
	var related: Dictionary = Mechanics.ENTRIES[topics[1]]
	draw_style_box(panel_style(Color("17232d"),Color("52605b")),Rect2(754,228,448,372))
	text_at("MECHANIC REFERENCE",Vector2(776,254),12,GOLD)
	text_at(primary.title,Vector2(776,283),20,TEAL)
	var y = wrapped_text(primary.text,Vector2(776,312),402,15,MUTED)
	y += 15
	text_at("RELATED: "+related.title,Vector2(776,y),14,GOLD)
	wrapped_text(related.text.split(". ")[0]+".",Vector2(776,y+25),402,14,MUTED)

func draw_tutorial_hud() -> void:
	var lesson: Dictionary = Tutorial.LESSONS[tutorial.step]
	draw_style_box(panel_style(Color("101e29"),TEAL),Rect2(114,198,502,150))
	text_at("LESSON %d / %d · %s" % [tutorial.step+1,Tutorial.LESSONS.size(),lesson.title],Vector2(132,224),14,TEAL)
	var y = wrapped_text(lesson.goal,Vector2(132,251),464,16)
	wrapped_text(lesson.why,Vector2(132,y+4),464,13,MUTED)
	text_at("COMPLETE" if tutorial.transition>0 else "%d / %d" % [tutorial.progress,lesson.count],Vector2(522,335),13,GOLD)

func draw_character_portrait(p: Vector2,index: int) -> void:
	var c = Color(Arsenal.SETS[index].color)
	var width = 24 if index == 0 else (12 if index == 1 else 18)
	poly_at(p,[Vector2(-width,-12),Vector2(width,-12),Vector2(width+6,35),Vector2(-width-6,35)],1,c.darkened(0.3))
	draw_circle(p+Vector2(0,-26),13,PAPER)
	line(p+Vector2(-7,-27),p+Vector2(7,-27),INK,3)
	if index == 0: draw_rect(Rect2(p+Vector2(-34,-10),Vector2(68,12)),c)
	elif index == 1: poly_at(p,[Vector2(-18,-24),Vector2(0,-48),Vector2(18,-24)],1,c)
	elif index == 2: line(p+Vector2(20,4),p+Vector2(43,-33),c,5)
	else: draw_arc(p+Vector2(0,-26),19,PI,TAU,20,c,5,true); line(p+Vector2(15,15),p+Vector2(47,-2),c,5)

func configure_phone() -> void:
	if phone_mode:
		var physical = get_tree().root.size
		phone.portrait = physical.y>physical.x
		var logical = Vector2i(720,1280) if phone.portrait else Vector2i(1280,720)
		if get_tree().root.content_scale_size != logical:
			if screen == "playing": screen = "paused"
			clear_touch()
			get_tree().root.content_scale_size = logical
		used_touch = true
	arena_scale = 0.62 if phone_mode and phone.portrait else 1.0
	arena_origin = Vector2(-36,120) if phone_mode and phone.portrait else Vector2.ZERO
	if phone_mode and phone.portrait: update_phone_camera(1.0)
	if is_instance_valid(hazard_view):
		var clip = hazard_view.get_parent()
		clip.position = arena_origin+FIELD.position*arena_scale
		clip.scale = Vector2.ONE*arena_scale
	queue_redraw()

func phone_touch(event: InputEventScreenTouch) -> void:
	used_touch = true; ui_mouse_active = false
	if not event.pressed or event.canceled:
		touches.erase(event.index); touch_actions.erase(event.index)
		if event.index == move_finger: move_finger = -1; touch_move = Vector2.ZERO; phone_jump_held = false
		return
	if screen != "playing": click_ui(event.position); return
	if phone.pause_rect().has_point(event.position): command("phone_pause"); return
	if phone.auto_rect().has_point(event.position): command("phone_auto"); return
	touches[event.index] = event.position
	if event.position.x<phone.size().x/2 and event.position.y>(740 if phone.portrait else 300) and move_finger == -1:
		move_finger = event.index
		touch_origin = event.position.clamp(phone.stick_home()-Vector2(80,65),phone.stick_home()+Vector2(80,65))
		update_phone_stick(event.position)
	else: route_phone_action(event.index,event.position)

func phone_drag(event: InputEventScreenDrag) -> void:
	if screen != "playing" or not touches.has(event.index): return
	touches[event.index] = event.position
	if event.index == move_finger: update_phone_stick(event.position)
	else: route_phone_action(event.index,event.position)

func update_phone_stick(p: Vector2) -> void:
	var radius = 95.0 if phone.portrait else 75.0
	var input = (p-touch_origin).limit_length(radius)/radius
	touch_move = Vector2.ZERO if input.length()<0.14 else input
	if side and input.y< -0.72 and not phone_jump_held: jump(); phone_jump_held = true
	if input.y> -0.25: phone_jump_held = false

func route_phone_action(index: int,p: Vector2) -> void:
	var selected := ""
	var best := INF
	for item in phone.controls(self):
		var distance = p.distance_to(item[0])/float(item[3])
		if distance<=1.10 and distance<best: best = distance; selected = item[1]
	if selected == touch_actions.get(index,""): return
	touch_actions.erase(index)
	if selected.is_empty(): return
	touch_actions[index] = selected
	match selected:
		"shoot": shoot()
		"melee": melee()
		"dodge": dodge()
		"parry": parry()
		"burst": burst()
		"jump": jump()

func phone_basic_attack() -> void:
	if screen != "playing" or dash_time>0 or not melee_snapshot.is_empty(): return
	var distance = player.distance_to(boss)
	var weapon: Dictionary = Arsenal.SETS[weapon_index]
	if distance<=float(weapon.melee_range[0])-4:
		melee()
	elif weapon_index == 3 and distance<=float(weapon.range)-25 and energy>=run.stat("dodge_cost")+float(Characters.ROSTER[3].cost):
		if not tutorial_active or tutorial.step == 7: shoot()

func update_phone_camera(delta: float) -> void:
	if not phone_mode or not phone.portrait: return
	var span = absf(player.x-boss.x)
	var target_scale = clampf(660.0/(span+160.0),0.62,0.95)
	arena_scale = target_scale if target_scale<arena_scale else lerpf(arena_scale,target_scale,minf(1,delta*5))
	var focus = (player.x+boss.x)/2.0
	var target_origin = Vector2(360-focus*arena_scale,190-164*arena_scale)
	arena_origin = target_origin
	if is_instance_valid(hazard_view):
		var clip = hazard_view.get_parent()
		clip.position = arena_origin+FIELD.position*arena_scale
		clip.scale = Vector2.ONE*arena_scale
