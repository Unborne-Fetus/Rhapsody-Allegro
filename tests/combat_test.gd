extends SceneTree
var failures := 0
var checks := 0
func check(condition: bool,message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.sound.enabled = false
	game.profile.path = "user://combat-test-profile.json"
	var original = game.profile.data.duplicate(true)
	game.profile.data.assist = false
	for index in 3:
		game.start_fight(index)
		check(game.boss_hp == float(game.bosses[index].hp),"Boss HP loaded from data")
		for pattern in game.bosses[index].patterns:
			game.execute_pattern(pattern)
			check(game.shots.size()<=350,"Projectile count bounded")
		game.shots.clear()
		game.boss_hp = game.max_hp*0.66
		game.simulate(0.016)
		check(game.side and game.phase == 1,"First threshold enters side-scroller")
		check(game.shots.is_empty() and game.invincible>1,"Shift clears bullets and grants protection")
		game.boss_hp = game.max_hp*0.32
		game.simulate(0.016)
		check(not game.side and game.phase == 2,"Final threshold returns to top-down")
	game.start_fight(0)
	game.invincible = 0
	game.hurt(12)
	check(game.hp == 88 and game.hits == 1,"Damage and hit count")
	game.hurt(12)
	check(game.hp == 88,"Post-hit invulnerability")
	game.invincible = 0
	game.dodge()
	check(game.energy == 76 and game.invincible>0,"Dodge costs energy and grants invulnerability")
	game.hurt(20)
	check(game.hp == 88,"Dodge prevents damage")
	game.dash_cd = 0; game.energy = 0; game.dodge()
	check(game.energy == 0,"No dodge with insufficient energy")
	game.start_fight(0)
	game.invincible = 0
	game.parry()
	var shot = game.Shot.new(game.player,Vector2(0,20),false)
	game.shots.append(shot)
	game.simulate(0.016)
	check(not shot.friendly and shot.life<=0,"Saber parry absorbs projectile")
	check(game.resonance>0 and game.hp == 100,"Parry charges resonance without damage")
	game.resonance = 100
	game.shots.append(game.Shot.new(Vector2(200,200),Vector2.ZERO,false))
	game.burst()
	check(game.resonance == 0 and game.boss_hp == game.max_hp-135,"Burst spends full meter and damages boss")
	check(game.shots.all(func(s): return s.friendly),"Burst clears hostile bullets")
	game.start_fight(0)
	game.side = true; game.player.y = 560; game.jump()
	check(game.velocity.y<0,"Side-scroller jump")
	for i in 180: game.simulate(1.0/60.0)
	check(game.player.y<=560 and game.player.y>=195,"Gravity and floor bounds")
	game.start_fight(0)
	game.invincible = 0; game.profile.data.assist = true; game.hurt(12)
	check(game.hp == 94,"Assist halves damage")
	var fast = game.Shot.new(Vector2(0,0),Vector2(1000,0),true)
	fast.step(0.1)
	check(fast.intersects(Vector2(50,0),5),"Swept collision catches fast bullets")
	game.profile.record_clear(0,12.5,2)
	var saved = game.Profile.new()
	saved.path = game.profile.path
	saved.load_profile()
	check(saved.data.unlocked >= 1,"JSON numeric unlock survives save/reload")
	check(saved.data.best.has("0_assist"),"Assist record survives save/reload")
	var broken = FileAccess.open(saved.path,FileAccess.WRITE)
	broken.store_string("broken json"); broken.close()
	var recovered = game.Profile.new()
	recovered.path = saved.path; recovered.load_profile()
	check(recovered.data.unlocked == 0,"Corrupt profile safely falls back")
	DirAccess.remove_absolute(saved.path)
	for index in 3:
		game.start_fight(index)
		for frame in 7200:
			game.hp = 100; game.invincible = 1
			game.simulate(1.0/60.0)
		check(game.shots.size()<=350,"Two-minute boss stress simulation bounded")
		check(game.player.is_finite() and game.boss.is_finite(),"Simulation positions remain finite")
	game.profile.data = original
	game.queue_free()
	print("COMBAT_TESTS checks=",checks," failures=",failures)
	quit(1 if failures else 0)
