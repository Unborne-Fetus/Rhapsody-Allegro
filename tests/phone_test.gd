extends SceneTree
var checks := 0
var failures := 0
var game: Node2D
func check(condition: bool,message: String) -> void:
	checks += 1
	if not condition: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run_tests")
func settle() -> void:
	game.queue_redraw(); await process_frame; await process_frame
func touch(index: int,p: Vector2,pressed: bool = true) -> void:
	var e = InputEventScreenTouch.new(); e.index = index; e.position = root.get_final_transform()*p; e.pressed = pressed
	Input.parse_input_event(e); await settle()
func drag(index: int,p: Vector2) -> void:
	var e = InputEventScreenDrag.new(); e.index = index; e.position = root.get_final_transform()*p
	Input.parse_input_event(e); await settle()
func tap(index: int,p: Vector2) -> void:
	await touch(index,p); await touch(index,p,false)
func prepare(index: int = 2) -> void:
	game.command("menu"); game.equip_set(index,true); game.command("training")
	game.phone_mode = true; game.configure_phone(); game.gamepad = false
	game.profile.data.auto_attack = true
	game.player = Vector2(400,440); game.boss = Vector2(700,440); game.side = false
func run_tests() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.sound.enabled = false; game.profile.path = "user://phone-test-profile.json"
	game.profile.data.auto_attack = true; game.phone_mode = true
	root.size = Vector2i(844,390); game.configure_phone(); await settle()
	check(not game.phone.portrait and root.content_scale_size == Vector2i(1280,720),"Landscape phone uses full arena layout")
	prepare(); await settle()
	await touch(0,Vector2(205,540)); await drag(0,Vector2(275,540))
	check(game.move_finger == 0 and game.touch_move.x>0.8,"Left thumb steers without an attack finger")
	await touch(1,Vector2(1110,551))
	check(game.dash_time>0 and game.touch_actions.get(1) == "dodge","Right thumb dodges while left moves")
	await drag(1,Vector2(971,448))
	check(game.shoot_cd>0 and game.touch_actions.get(1) == "shoot","Right thumb slides from dodge to ability")
	check(game.move_finger == 0 and game.touch_move.x>0.8,"Skill slide preserves movement finger")
	await drag(1,Vector2(1165,394))
	check(game.parry_time == 0 and not game.touch_actions.has(1),"Former parry position has no active control")
	var cd = game.parry_cd; await drag(1,Vector2(1162,397))
	check(game.parry_cd == cd,"Touch cannot activate deferred parry")
	await drag(1,Vector2(700,200)); check(not game.touch_actions.has(1),"Sliding outside clears held attack")
	await touch(1,Vector2(700,200),false); await touch(0,Vector2(275,540),false)
	check(game.touch_move == Vector2.ZERO and game.touches.is_empty(),"Both thumb releases clear state")
	prepare(); game.side = true; game.player.y = 560; game.ground_grace = .1
	await touch(0,Vector2(205,540)); await drag(0,Vector2(205,455))
	check(game.velocity.y<0,"Flicking left thumb up jumps in platform view")
	game.velocity.y = 1; await drag(0,Vector2(205,450)); check(game.velocity.y == 1,"Held upward stick does not repeat jumps")
	await drag(0,Vector2(205,620)); check(game.touch_move.y>.65,"Left thumb down drops through platforms")
	prepare(); game.boss = game.player+Vector2(100,0); game.phone_basic_attack()
	check(not game.melee_snapshot.is_empty(),"Automatic basic strike starts in reach")
	game.resolve_melee(); check(game.training_damage>0,"Automatic strike lands actual shared combat damage")
	prepare(); game.boss = game.player+Vector2(400,0); game.phone_basic_attack()
	check(game.melee_snapshot.is_empty(),"Automatic melee waits until within reach")
	prepare(3); game.energy = 100; game.phone_basic_attack()
	check(game.shots.size() == 1 and game.shots[0].source_set == 3,"Horizon auto attack uses its rifle")
	game.shots.clear(); game.shoot_cd = 0; game.energy = game.run.stat("dodge_cost")+9; game.phone_basic_attack()
	check(game.shots.is_empty(),"Automatic rifle fire preserves a dodge reserve")
	game.energy = 100; game.tutorial_active = true; game.tutorial.step = 2; game.phone_basic_attack()
	check(game.shots.is_empty(),"Tutorial ability lesson still requires manual skill activation")
	game.tutorial_active = false; game.profile.data.auto_attack = false; await settle()
	check(game.phone.controls(game).any(func(item):return item[1] == "melee"),"Disabling auto exposes manual strike")
	prepare(); await settle(); await tap(1,Vector2(75,50))
	check(not game.profile.data.auto_attack and game.screen == "playing","Auto toggle stays in fight")
	game.profile.data.auto_attack = true; game._notification(game.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.screen == "paused" and game.touch_actions.is_empty() and game.move_finger == -1,"Focus loss pauses and clears phone input")
	root.size = Vector2i(390,844); game.configure_phone(); await settle()
	check(game.phone.portrait and root.content_scale_size == Vector2i(720,1280),"Portrait phone gets native tall interface")
	check(game.arena_scale>=.62 and game.arena_scale<=.95,"Portrait arena and hazard layer share scale")
	game.update_phone_camera(1)
	check((game.player*game.arena_scale+game.arena_origin).x>25 and (game.boss*game.arena_scale+game.arena_origin).x<695,"Portrait camera keeps both fighters in view")
	check(game.hazard_view.get_parent().position == game.arena_origin+game.FIELD.position*game.arena_scale,"Hazard clipping stays aligned")
	prepare(); await settle(); await touch(0,Vector2(160,1060)); await drag(0,Vector2(245,1060))
	await touch(1,Vector2(565,1060)); check(game.dash_time>0 and game.touch_move.x>.8,"Portrait supports two-thumb movement and dodge")
	await tap(2,Vector2(640,60))
	check(game.screen == "paused" and game.touches.is_empty(),"Large portrait pause clears all fingers")
	game.command("menu"); await settle()
	check(game.buttons.all(func(b):return b.rect.size.y>=80),"Phone menu buttons meet large touch target size")
	game.command("start"); await settle(); var selected = game.profile.data.weapon
	await tap(3,Vector2(535,555))
	check(game.profile.data.weapon == (selected+1)%4,"Portrait character selection works by thumb")
	game.screen = "intermission"; game.upgrade_options = [game.RunState.UPGRADES[7],game.RunState.UPGRADES[1],game.RunState.UPGRADES[4]]; game.upgrade_focus = 0; await settle()
	await tap(3,Vector2(350,700)); check(game.upgrade_focus == 1 and game.screen == "intermission","Large upgrade list inspects mechanics")
	await tap(3,Vector2(350,937)); check(game.screen == "playing" and game.run.has("cell"),"Separate confirmation accepts upgrade")
	await touch(0,Vector2(160,1060)); await drag(0,Vector2(245,1060))
	game.command("phone_auto")
	check(game.move_finger == 0 and game.touch_move.x>.8,"Auto preference change preserves left thumb movement")
	root.size = Vector2i(844,390); game.configure_phone()
	check(game.screen == "paused" and game.touches.is_empty(),"Rotating phone pauses fight and clears held input")
	prepare(); game.parry_enabled = false
	check(game.phone.controls(game).all(func(item):return item[1] != "parry") and game.touch_layout().all(func(item):return item[1] != "parry"),"Parry is absent from phone and legacy touch layouts")
	game.parry(); check(game.parry_time == 0 and game.parry_cd == 0,"Deferred parry cannot activate through direct or bound input")
	game.training = false; game.invincible = 0; game.parry_time = .5
	var incoming = game.Shot.new(game.player,Vector2.ZERO,false); game.shots.append(incoming); game.simulate(.005)
	check(game.hp<game.run.stat("health") and not incoming.friendly and game.parries == 0,"Stale parry windows neither absorb nor reflect shots")
	prepare(); game.energy = 20; game.player = Vector2(500,440); game.boss = Vector2(580,440)
	game.combo = 2; game.combo_time = 1; game.melee(); game.resolve_melee()
	check(game.energy == 41,"Aria finisher has a useful energy passive while parry is deferred")
	var state = game.RunState.new(); state.restore({"boss":1,"upgrades":["guard","step"]})
	check(not state.has("guard") and state.has("step") and state.has("cell"),"Saved parry upgrade migrates to an unowned working upgrade")
	check(state.active_upgrades().all(func(u):return u.id != "guard"),"No new parry upgrades are offered")
	prepare(); game.side = true; game.player = Vector2(380,560); game.ground_grace = .1; game.jump()
	var apex = game.player.y
	for frame in 144:
		game.simulate(1.0/120); apex = minf(apex,game.player.y)
	check(560-apex>170,"Jump reaches a substantially higher apex")
	check(is_equal_approx(game.player.y,450),"Higher jump can reach and land on the tutorial platform")
	check(game.phone.auto_rect().position.y<20 and game.phone.auto_rect().end.y<100,"Small auto control lives in top-left HUD")
	check(not game.phone.auto_rect().grow(150).has_point(game.phone.stick_home()),"Auto is safely separated from the movement thumb")
	game.command("menu"); game.profile.save_profile(); var profile = game.Profile.new(); profile.path = game.profile.path; profile.load_profile()
	check(profile.data.auto_attack == game.profile.data.auto_attack,"Auto attack preference persists")
	DirAccess.remove_absolute(game.profile.path); game.queue_free()
	print("PHONE_TESTS checks=",checks," failures=",failures); quit(1 if failures else 0)
