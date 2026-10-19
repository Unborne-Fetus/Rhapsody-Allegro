extends SceneTree
var checks := 0
var failures := 0
func check(condition: bool,label: String) -> void:
	checks += 1
	if not condition: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run_tests")
func run_tests() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game); game.set_process(false); game.sound.enabled = false
	game.profile.path = "user://advanced-test-profile.json"
	game.profile.data.assist = false
	var run = game.RunState.new()
	for difficulty in 3:
		run.reset(difficulty)
		for boss in 2:
			var choices = run.choices(boss)
			check(choices.size() == 3,"Three intermission choices")
			check(choices[0].id != choices[1].id and choices[0].id != choices[2].id and choices[1].id != choices[2].id,"Upgrade choices unique")
			run.upgrades.append(choices[0].id)
			check(run.choices(boss).all(func(u): return u.id != choices[0].id),"Owned upgrades excluded")
	for u in game.RunState.UPGRADES:
		if not run.has(u.id): run.upgrades.append(u.id)
	check(run.choices(0).is_empty(),"Exhausted upgrades safe")
	check(run.stat("health") == 125 and run.stat("energy") == 125,"Capacity upgrades")
	check(run.stat("dodge_cost") == 18 and run.stat("parry")>0.2,"Dodge and parry upgrades")
	var snapshot = run.snapshot(2,true)
	var restored = game.RunState.new()
	check(restored.restore(snapshot) and restored.upgrades == run.upgrades and restored.assisted,"Checkpoint round trip")
	run.assisted = true
	var prior_assist = run.snapshot(1,false)
	check(prior_assist.assist == false and restored.restore(prior_assist) and restored.assisted,"Checkpoint preserves current assist toggle separately from run classification")
	check(not restored.restore({"boss":"bad"}),"Invalid boss checkpoint rejected")
	check(restored.restore({"boss":1,"difficulty":{},"score":[],"time":"bad","hits":{},"upgrades":["invented","edge","edge"]}),"Malformed optional checkpoint fields sanitized")
	check(restored.upgrades == ["edge"] and restored.score == 0,"Unknown and duplicate upgrade IDs removed")
	game.run.reset(); game.training = false; game.practice = false; game.start_fight(0)
	for index in game.Arsenal.SETS.size():
		game.weapon_index = index; game.shoot_cd = 0; game.energy = 100; game.shots.clear(); game.shoot()
		check(game.shots.size() == int(game.RunState.WEAPONS[index].count),"Weapon projectile count")
		check(game.energy == 100-float(game.RunState.WEAPONS[index].cost),"Weapon energy cost")
		var cooldown = game.shoot_cd
		game.cycle_weapon()
		check(game.shoot_cd == cooldown,"Weapon switching cannot cancel recovery")
	game.weapon_index = 0; game.shoot_cd = 0; game.energy = 0; game.shots.clear(); game.shoot()
	check(game.shots.is_empty(),"Weapon cannot fire without energy")
	game.start_fight(0); game.add_stagger(100)
	check(game.stagger_time == 2.0 and game.windup == 0,"Stagger interrupts and opens vulnerability")
	var health = game.boss_hp
	game.damage_boss(10)
	check(is_equal_approx(game.boss_hp,health-13),"Stagger grants 30 percent damage bonus")
	game.add_stagger(100)
	check(game.stagger == 0,"Stagger lock prevents permanent stun")
	game.start_fight(0); game.perfect_dodge(); game.perfect_dodge()
	check(game.perfect_dodges == 1 and game.resonance == 12,"One perfect-dodge reward per dash")
	game.dash_cd = 0; game.dodge(); game.perfect_dodge()
	check(game.perfect_dodges == 2,"New dash resets reward gate")
	game.add_style("blade",10); var first = game.style; game.add_style("blade",10); var repeated = game.style-first
	game.add_style("fire",10)
	check(game.style-first-repeated>repeated,"Varied actions earn more style")
	for kind in ["beam","mine","wave"]:
		var hazard = game.Hazard.new(kind,Vector2(100,100),Vector2(300,100),0.5,2.0)
		check(not hazard.intersects(Vector2(110,100)),"Hazard warning never damages")
		hazard.step(0.55)
		if kind == "wave": check(hazard.intersects(Vector2(200,100)),"Swept wave radius detects contact")
		else: check(hazard.intersects(Vector2(110,100)),"Active hazard detects contact")
		hazard.step(3)
		check(hazard.expired(),"Hazard expires")
	game.start_fight(0); game.side = true; game.player = Vector2(380,420); game.velocity = Vector2(0,250)
	for frame in 30: game.simulate(1.0/60.0)
	check(is_equal_approx(game.player.y,450),"One-way platform catches descending player")
	game.jump()
	check(game.velocity.y<0,"Jump works on elevated platform")
	game.ground_grace = 0.08; game.player.y = 420; game.jump()
	check(game.velocity.y == -570,"Coyote-time jump")
	game.start_run(); game.damage_boss(9999)
	check(game.screen == "clear" and game.run.score>0,"Boss clear tallies run score")
	var first_score = game.run.score
	game.restart_fight(); game.damage_boss(9999)
	check(game.run.score == first_score,"Retry after victory cannot duplicate run score")
	game.advance()
	check(game.screen == "intermission" and game.upgrade_options.size() == 3,"Campaign clear leads to augmentation")
	var chosen = game.upgrade_options[0].id
	game.choose_upgrade(chosen)
	check(game.boss_index == 1 and game.run.has(chosen) and game.screen == "playing","Augmentation carries into next fight")
	check(int(game.profile.data.checkpoint.boss) == 1,"Checkpoint saved after augmentation")
	game.command("menu"); game.continue_run()
	check(game.boss_index == 1 and game.run.has(chosen),"Continue restores next movement and upgrades")
	game.damage_boss(99999); game.advance(); game.choose_upgrade(game.upgrade_options[0].id)
	check(game.boss_index == 2 and game.run.upgrades.size() == 2,"Full campaign reaches finale with two upgrades")
	game.damage_boss(99999)
	check(game.profile.data.checkpoint.is_empty() and game.screen == "clear","Finale clears completed checkpoint")
	game.start_run(); game.touch_move = Vector2.ONE; game.touch_actions[1] = "shoot"
	game._notification(game.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.screen == "paused" and game.touch_move == Vector2.ZERO and game.touch_actions.is_empty(),"Focus loss pauses and clears touch actions")
	var before_pause = game.elapsed
	game._process(0.04)
	check(game.elapsed == before_pause,"Paused state does not advance combat")
	var prior_records = game.profile.data.best.duplicate(true)
	game.command("training"); game.damage_boss(99999)
	check(game.screen == "playing" and game.boss_hp == game.max_hp,"Training dummy cannot die")
	check(game.profile.data.best == prior_records,"Training cannot create records")
	game.invincible = 0; game.hurt(9999)
	check(game.hp == game.run.stat("health"),"Training cannot kill player")
	game.training = false; game.run.reset(2); game.start_fight(0); game.profile.data.assist = true; game.simulate(0.016); game.profile.data.assist = false
	game.damage_boss(99999)
	check(game.profile.data.best.has("0_d2_assist"),"Turning assist off cannot reclassify an assisted fight")
	# Eighteen minutes across every boss/difficulty with all new hazards active.
	game.profile.data.assist = false
	for difficulty in 3:
		for boss in 3:
			game.run.reset(difficulty); game.start_fight(boss)
			for frame in 7200:
				game.hp = 100; game.invincible = 1
				game.simulate(1.0/60.0)
			check(game.shots.size()<=350 and game.hazards.size()<=24,"Boss stress object budgets")
			check(game.player.is_finite() and game.boss.is_finite(),"Boss stress finite physics")
	DirAccess.remove_absolute(game.profile.path)
	game.queue_free()
	print("ADVANCED_TESTS checks=",checks," failures=",failures)
	quit(1 if failures else 0)
