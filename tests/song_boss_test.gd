extends SceneTree
var checks := 0
var failures := 0
var game: Node2D
func check(condition: bool,message: String) -> void:
	checks += 1
	if not condition: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run_tests")
func prepare(index: int,phase: int = 0,side: bool = false) -> void:
	game.command("menu"); game.practice = true; game.training = false; game.tutorial_active = false
	game.run.reset(); game.start_fight(index); game.phase = phase; game.side = side
	game.player = Vector2(400,560 if side else 420); game.boss = Vector2(850,510 if side else 390)
	game.aim_snapshot = game.player; game.invincible = 1
func run_tests() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.sound.enabled = false; game.profile.path = "user://song-boss-tests.json"
	game.profile.data.assist = false
	check(game.bosses.size() == 7 and game.Encounters.last_index() == 6,"Seven encounter roster drives bounds")
	check(game.bosses[0].name == "THE METRONOME" and game.bosses[2].name == "THE CONDUCTOR","Original roster indices preserved")
	var titles = ["Sexbomb","Burning Love","Can't Stop the Music","Cum On Feel the Noize"]
	var signatures: Array[String] = []
	for index in range(3,7):
		check(game.bosses[index].song == titles[index-3],"Correct song attribution")
		check(game.bosses[index].phases.size() == 3 and not game.bosses[index].tip.is_empty(),"Phase names and tactical guidance")
		for phase in 3:
			for side in [false,true]:
				for pattern in game.bosses[index].patterns:
					prepare(index,phase,side); game.execute_pattern(pattern)
					check(not game.hazards.is_empty() or game.charge_time>0,"Pattern creates gameplay: "+pattern)
					for h in game.hazards:
						check(h.warning>=0.6 and not h.active(),"Song hazard always warns before damage")
						check(h.origin.is_finite() and h.target.is_finite(),"Hazard geometry finite")
					check(game.shots.all(func(s): return not s.friendly),"Boss patterns do not create friendly bullets")
					check(game.hazards.size()<=24,"Pattern respects hazard budget")
					if phase == 0 and not side: signatures.append(str(game.hazards.map(func(h): return h.kind))+str(game.charge_time))
		prepare(index,1)
		game.windup = 0.01; game.pending_pattern = game.bosses[index].patterns[0]; game.attack_number = 2
		game.update_boss(0.02)
		check(game.followup_pattern == game.bosses[index].followup and game.followup_delay>0,"Custom phase follow-up")
		game.add_stagger(100)
		check(game.followup_delay == 0 and game.windup == 0,"Stagger cancels queued follow-up")
		prepare(index); game.boss_hp = game.max_hp*0.66; game.simulate(0.016)
		check(game.side and game.phase == 1,"Song encounter enters platform phase")
		game.boss_hp = game.max_hp*0.32; game.simulate(0.016)
		check(not game.side and game.phase == 2,"Song encounter returns for final phase")
	for index in range(3,7):
		prepare(index)
		var pattern = ["heartbreaker","flame_fan","six_step","amp_wall"][index-3]
		game.execute_pattern(pattern)
		check(game.shots.size()>=3,"Each song boss offers parryable projectile attacks")
	# Velvet's hollow ring leaves a real safe inner pocket.
	prepare(3); game.execute_pattern("velvet_trap")
	var ring = game.hazards[0]; ring.step(1.21)
	check(not ring.intersects(ring.origin),"Velvet safe eye is harmless")
	check(ring.intersects(ring.origin+Vector2(130,0)),"Velvet blast annulus damages")
	check(not ring.intersects(ring.origin+Vector2(240,0)),"Velvet outside ring is safe")
	prepare(3); game.execute_pattern("fuse_chain")
	check(game.hazards[0].warning<game.hazards[1].warning,"Fuses detonate in sequence")
	# Heat and volume recover on simulation time; phase changes and retries clear chains.
	prepare(4)
	for i in 4: game.execute_pattern("heartfire")
	check(game.songs.recovery>3 and game.songs.heat == 0,"Four flame attacks cause overheat")
	var before = game.boss_hp; game.damage_boss(100)
	check(is_equal_approx(before-game.boss_hp,120),"Overheat creates +20% punish window")
	var position = game.boss; game.update_boss(0.1)
	check(game.boss == position and game.windup == 0,"Overheated boss cannot act")
	game.songs.tick(4); check(game.songs.multiplier(4) == 1,"Overheat expires")
	prepare(5); game.execute_pattern("dancefloor")
	var safe_col: int = game.attack_number%6
	for h in game.hazards:
		h.step(1.2)
		check(not h.intersects(Vector2(112+safe_col*176+79,255)),"Dancefloor retains clear column")
	prepare(5,1,true); game.execute_pattern("dancefloor")
	for h in game.hazards:
		h.step(1.2); check(not h.intersects(Vector2(h.origin.x+50,450)),"Platform jump clears dancefloor tiles")
	prepare(5); game.execute_pattern("six_step")
	check(game.hazards.size() == 6 and game.hazards[0].origin != game.hazards[1].origin,"Six separate performers aim their lanes")
	prepare(6); game.execute_pattern("power_chord")
	var wave = game.hazards[0]; wave.step(1.4)
	var direction = Vector2.RIGHT.rotated(wave.gap_angle)
	check(not wave.intersects(wave.origin+direction*wave.radius),"Soundwave gap protects player")
	check(wave.intersects(wave.origin-direction*wave.radius),"Soundwave body remains dangerous")
	for i in 2: game.execute_pattern("amp_wall")
	check(game.songs.recovery>0 and game.songs.volume == 0,"Three loud attacks create silence")
	prepare(6); game.execute_pattern("power_chord"); game.execute_pattern("amp_wall"); game.execute_pattern("stage_dive")
	var initial = game.boss; game.update_boss(0.1)
	check(game.boss != initial,"Final stage dive completes before silence recovery")
	game.start_fight(6)
	check(game.songs.recovery == 0 and game.songs.volume == 0 and game.hazards.is_empty(),"Retry clears song state and hazards")
	prepare(6,1,true); game.execute_pattern("amp_wall")
	for h in game.hazards:
		h.step(h.warning+0.1)
		check(not h.intersects(Vector2(h.origin.x,560)),"Amplifier opening fits player radius at floor height")
	# Checkpoint and profile bounds migrate beyond the old three-movement limit.
	var run = game.RunState.new()
	for index in 7: check(run.restore({"boss":index}),"Checkpoint restores movement "+str(index))
	check(not run.restore({"boss":7}) and not run.restore({"boss":-1}),"Invalid movement rejected")
	game.profile.data.unlocked = 6; game.profile.save_profile()
	var profile = game.Profile.new(); profile.path = game.profile.path; profile.load_profile()
	check(profile.data.unlocked == 6,"Unlock survives roundtrip beyond original trio")
	game.profile.data.unlocked = 0; prepare(6); game.damage_boss(99999)
	check(game.screen == "clear" and game.profile.data.unlocked == 0,"Direct song practice cannot skip campaign unlocks")
	# One simulated minute in every phase, difficulty, and new encounter.
	for difficulty in 3:
		for index in range(3,7):
			for phase in 3:
				prepare(index,phase,phase == 1); game.run.difficulty = difficulty
				game.boss_hp = game.max_hp*([.85,.5,.2][phase])
				for frame in 3600:
					game.hp = 150; game.invincible = 1; game.simulate(1.0/60.0)
				check(game.shots.size()<=350 and game.hazards.size()<=24,"Song stress budgets")
				check(game.player.is_finite() and game.boss.is_finite(),"Song stress physics finite")
	DirAccess.remove_absolute(game.profile.path); game.queue_free()
	print("SONG_BOSS_TESTS checks=",checks," failures=",failures)
	quit(1 if failures else 0)
