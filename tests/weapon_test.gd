extends SceneTree
## Character, tutorial, boss-pressure and contextual-reference regressions.
var checks := 0
var failures := 0
var game: Node2D
func check(condition: bool,message: String) -> void:
	checks += 1
	if not condition: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run_tests")
func prepare(index: int,distance: float = 60) -> void:
	game.parry_enabled = false; game.command("menu"); game.screen = "loadout"; game.run.reset()
	game.equip_set(index); game.training = true; game.training_attacks = false; game.practice = true
	game.start_fight(0); game.player = Vector2(400,400); game.boss = Vector2(400+distance,400)
	game.gamepad = true; game.used_touch = false; game.profile.data.assist = false
func finish_strike() -> void:
	var frames = 0
	while not game.melee_snapshot.is_empty() and frames<200:
		game.simulate(0.005); frames += 1
	check(frames<200,"Committed strike resolves")
func next_lesson() -> void:
	game.update_tutorial(0.71)
func run_tests() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game); game.set_process(false); game.sound.enabled = false
	game.profile.path = "user://weapon-test-profile.json"
	var sets = game.Arsenal.SETS
	check(sets.size() == 4 and game.Characters.ROSTER.size() == 4,"Four characters and assigned sets")
	# Eco settings are purely visual; collision logic and character kits remain unchanged.
	var low_style = game.panel_style(Color("182432"),Color("4a6472"))
	check(low_style == game.panel_style(Color("182432"),Color("4a6472")),"UI panel resources are reused between draws")
	var cached_styles = game.panel_style_cache.size()
	game.panel_style(Color("182432"),Color("4a6472"))
	check(game.panel_style_cache.size() == cached_styles,"Repeated menu rendering does not allocate more style resources")
	game.profile.data.eco_mode = true; game.sparks.clear()
	game.emit_sparks(Vector2(500,400),game.TEAL,300)
	check(game.sparks.size() == 80,"Eco mode respects its eighty-particle VFX budget")
	game.sparks.clear(); game.profile.data.eco_mode = false
	game.emit_sparks(Vector2(500,400),game.TEAL,300)
	check(game.sparks.size() == 300,"Full effects mode preserves the original particle budget")
	game.sparks.clear()
	game.profile.data.eco_mode = true
	game.command("eco_mode")
	check(not game.profile.data.eco_mode,"Eco renderer setting toggles without changing difficulty")
	game.profile.data.eco_mode = false

	check(game.Characters.ROSTER.map(func(c): return c.title) == ["The Drummer","The Bassist","The Guitarist","The Singer"],"Four distinct playable musician types")
	var sprite_art = game.StageArt.PixelPerformers
	check(sprite_art.ATLAS != null and sprite_art.ATLAS.get_size() == Vector2(1440,224),"Pixel atlas imports at 36 poses by 4 characters")
	check(sprite_art.frame_for(game,true)>=16 and sprite_art.frame_for(game,true)<=19,"Animated musician portrait")
	game.side = true; game.velocity = Vector2(210,0); game.ground_grace = 0.1
	check(sprite_art.frame_for(game)>=20 and sprite_art.frame_for(game)<=25,"Running selects a real frame")
	game.attack_animation = 0.36; check(sprite_art.frame_for(game) == 30,"Attack starts with wind-up sprite")
	game.attack_animation = 0.07; check(sprite_art.frame_for(game) == 33,"Attack progresses to a distinct follow-through pose")
	game.attack_animation = 0; game.hurt_animation = 0.2
	check(sprite_art.frame_for(game)>=34,"Damage switches to recoil sprite")
	game.hurt_animation = 0; game.side = false; game.velocity = Vector2.ZERO
	check(sets[0].melee_damage[0]>sets[2].melee_damage[0] and sets[2].melee_damage[0]>sets[1].melee_damage[0],"Heavy, balanced and fast damage roles")
	check(sets[1].melee_cooldown[0]<sets[2].melee_cooldown[0] and sets[2].melee_cooldown[0]<sets[0].melee_cooldown[0],"Distinct attack cadence")
	for i in 4:
		var c: Dictionary = game.Characters.ROSTER[i]
		prepare(i)
		check(game.hp == c.health and game.weapon_index == i,"Character vitality and set applied")
		game.training = false; game.invincible = 0; game.hurt(10)
		check(is_equal_approx(game.hp,c.health-10*c.incoming),"Character armor or vulnerability applied")
		for state in ["playing","paused","intermission","dead","clear"]:
			game.screen = state
			check(not game.equip_set((i+1)%4) and game.weapon_index == i,"Character locked in "+state)
		game.screen = "playing"; game.open_panel("arsenal"); game.open_panel("help")
		check(not game.equip_set((i+1)%4),"Nested inspection cannot bypass character lock")
		game.close_panel(); game.close_panel()
		prepare(i); game.shoot()
		check(game.energy == 100-c.cost and game.shoot_cd == c.cooldown,"Ability has character cost and recovery")
		var before = game.energy; game.shoot()
		check(game.energy == before,"Ability cannot bypass recovery")
		if i<3:
			check(game.shots.is_empty() and not game.melee_snapshot.is_empty(),"Melee ability creates no bullets")
			finish_strike()
			check(is_equal_approx(game.training_last_hit,c.power),"Melee ability damage")
			if i == 1: check(game.bleed_stacks == 1,"Razorstep applies bleeding")
			if i == 2: check(game.parry_time == 0,"Crescent Sweep has no active parry")
		else:
			check(game.shots.size() == 1 and game.shots[0].source_set == 3,"Only Horizon fires player bullets")
			check(game.shots[0].damage == 12,"Horizon modest close-range damage")
			var shot = game.shots[0]; shot.step(10)
			check(is_equal_approx(shot.distance_traveled,926) and shot.life<=0,"Projectile cannot exceed declared range")
		prepare(i); game.parry_enabled = true; game.parry(); var shot = game.Shot.new(game.player,Vector2.ZERO,false); game.shots.append(shot); game.simulate(0.005)
		check(shot.friendly == (i == 3),"Only Horizon reflects bullets")
		check(game.parries == 1,"Each character can parry")
		if i == 2:
			game.melee(); check(is_equal_approx(game.melee_snapshot.power,sets[i].melee_damage[0]*1.5),"Aria riposte empowers next strike")
			check(game.riposte_time == 0,"Riposte consumed once")
		prepare(i); game.energy = 0; game.shoot()
		check(game.melee_snapshot.is_empty() and game.shots.is_empty(),"Insufficient energy rejects ability")
		prepare(i); game.run.upgrades.append("fire"); game.shoot()
		check(is_equal_approx(game.shots[0].damage,c.power*1.2) if i == 3 else is_equal_approx(game.melee_snapshot.power,c.power*1.2),"Overtone boosts correct ability")
	prepare(3,500); game.shoot(); check(game.shots[0].damage == 15,"Lyra Long Sight bonus")
	prepare(1); game.bleed_stacks = 3; game.bleed_time = 3; game.update_bleed(0.5)
	check(game.training_last_hit == 4.5,"Three bleeding stacks tick damage")
	game.update_bleed(3.1); game.update_bleed(0.01); check(game.bleed_stacks == 0,"Bleeding expires")
	prepare(0); game.melee(); var recovery = game.melee_cd; game.dodge()
	check(game.melee_snapshot.is_empty() and game.melee_cd == recovery,"Dodge cancels windup without refund")
	prepare(2); game.melee(); game.melee_snapshot.facing = Vector2.LEFT; finish_strike()
	check(game.training_hit_count == 0,"Melee respects committed direction")
	prepare(0); game.cycle_weapon()
	check(game.weapon_index == 0 and game.screen == "arsenal","Inspection pauses without swapping")
	game.command("menu"); game.equip_set(1,true)
	var saved = game.Profile.new(); saved.path = game.profile.path; saved.load_profile()
	check(saved.data.weapon == 1,"Character preference persists")
	var restored = game.RunState.new()
	check(restored.restore(game.run.snapshot(1,false)) and restored.loadout_index == 1,"Checkpoint preserves character")
	check(restored.restore({"boss":1,"weapon":{}}) and restored.loadout_index == 2,"Old or malformed selection recovers")
	# Tutorial cannot advance merely by waiting or invoking a different objective.
	var lesson = game.Tutorial.new(); lesson.event("victory"); lesson.tick(500)
	check(lesson.step == 0 and lesson.progress == 0,"Tutorial gates ignore time and wrong events")
	var records = game.profile.data.best.duplicate(true)
	var unlocked = game.profile.data.unlocked
	game.profile.data.checkpoint = {"boss":1,"weapon":1}
	game.command("menu"); game.start_tutorial()
	check(game.tutorial_active and game.practice and not game.training,"Playable tutorial starts separately")
	check(not game.equip_set(3),"Tutorial character also locked")
	game.player = Vector2(950,510); game.update_tutorial(0.01); next_lesson()
	check(game.tutorial.step == 1,"Movement reaches checkpoint")
	game.gamepad = true; game.player = Vector2(700,420)
	for i in 3:
		game.melee_cd = 0; game.melee(); finish_strike()
	next_lesson(); check(game.tutorial.step == 2,"Three landed melee hits advance lesson")
	game.player = Vector2(700,420); game.shoot(); finish_strike(); next_lesson()
	check(game.tutorial.step == 3,"Actual character ability advances lesson")
	game.update_tutorial(1.3)
	check(game.shots.size() == 1 and not game.shots[0].friendly,"Dodge lesson supplies safe practice shot")
	game.shots.clear(); game.dodge(); game.shots.append(game.Shot.new(game.player,Vector2.ZERO,false)); game.simulate(0.005); next_lesson()
	check(game.tutorial.step == 4,"Real projectile dodge advances lesson")
	game.player = game.boss-Vector2(55,0)
	for i in 2:
		game.melee_cd = 0; game.melee(); finish_strike()
	next_lesson()
	check(game.tutorial.step == 5 and game.resonance == 100,"Energy recovery lesson advances to charged resonance")
	game.burst(); next_lesson(); check(game.tutorial.step == 6 and game.side,"Resonance lesson introduces side view")
	game.simulate(game.SHIFT_DURATION)
	game.player = Vector2(380,420); game.velocity = Vector2(0,250)
	for i in 30: game.simulate(1.0/60)
	next_lesson(); game.simulate(game.SHIFT_DURATION); check(game.tutorial.step == 7,"Landing on first platform completes objective")
	game.invincible = 0; game.hurt(9999)
	check(game.tutorial.step == 7 and game.hp == game.run.stat("health") and game.boss_hp == 480,"Death retries current tutorial checkpoint")
	game.damage_boss(9999); next_lesson()
	check(game.screen == "tutorial_clear" and game.profile.data.tutorial_complete,"Tutorial ends and saves completion")
	check(game.profile.data.best == records and game.profile.data.unlocked == unlocked,"Tutorial creates no normal records or unlocks")
	check(game.profile.data.checkpoint.boss == 1,"Tutorial preserves existing campaign checkpoint")
	# Context panel metadata and inspection are independent from accepting upgrades.
	game.screen = "intermission"; game.upgrade_options = game.RunState.UPGRADES.slice(0,3)
	game.inspect_upgrade_at(Vector2(300,370))
	check(game.upgrade_focus == 1 and game.screen == "intermission" and game.run.upgrades.is_empty(),"Hover inspection never accepts upgrade")
	for u in game.RunState.UPGRADES:
		check(game.Mechanics.TOPICS.has(u.id),"Upgrade has contextual topics")
		for topic in game.Mechanics.TOPICS[u.id]: check(game.Mechanics.ENTRIES.has(topic),"Reference topic exists")
	# Bosses approach ranged players and telegraph close punishment / later-phase chains.
	prepare(2); game.training = false; game.player = Vector2(200,400); game.boss = Vector2(1000,400)
	var distance = game.player.distance_to(game.boss); game.update_boss(0.5)
	check(game.player.distance_to(game.boss)<distance-80,"Boss closes distance against kiting")
	game.boss = game.player+Vector2(70,0); game.attack_number = 1; game.attack_timer = 0; game.update_boss(0.01)
	check(game.pending_pattern == "cleave" and game.windup>0,"Close range sweep has warning")
	game.hazards.clear(); game.execute_pattern("cleave")
	check(game.hazards[0].area_radius == 125 and not game.hazards[0].intersects(game.boss),"Large cleave begins harmlessly telegraphed")
	game.phase = 1; game.attack_number = 2; game.chain_active = false; game.windup = 0.01; game.pending_pattern = "fan"; game.update_boss(0.02)
	check(game.followup_delay>0,"Later phases schedule chained attacks")
	game.update_boss(0.5); check(game.windup>0 and game.chain_active,"Follow-up has its own warning")
	for b in game.bosses.slice(0,3): check(b.hp>=1500 and b.interval<=0.9,"Boss durability and pressure increased")
	DirAccess.remove_absolute(game.profile.path); game.queue_free()
	print("CHARACTER_TUTORIAL_TESTS checks=",checks," failures=",failures)
	quit(1 if failures else 0)
