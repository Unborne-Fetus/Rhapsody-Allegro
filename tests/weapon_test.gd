extends SceneTree
var checks := 0
var failures := 0
var game: Node2D
func check(condition: bool,message: String) -> void:
	checks += 1
	if not condition: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run_tests")
func prepare(index: int,distance: float = 60) -> void:
	game.run.reset(); game.training = true; game.training_attacks = false; game.practice = true
	game.equip_set(index); game.start_fight(0)
	game.player = Vector2(400,400); game.boss = Vector2(400+distance,400)
	game.gamepad = true; game.used_touch = false
func finish_strike() -> void:
	var frames = 0
	while not game.melee_snapshot.is_empty() and frames<200:
		game.simulate(0.005); frames += 1
	check(frames<200,"Queued strike always resolves")
func run_tests() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game); game.set_process(false); game.sound.enabled = false
	game.profile.path = "user://weapon-test-profile.json"
	var sets = game.Arsenal.SETS
	check(sets.size() == 4,"Exactly four complete sets")
	check(sets[0].damage>sets[2].damage and sets[2].damage>sets[1].damage,"Heavy and balanced shot damage ordering")
	check(sets[0].melee_damage[0]>sets[2].melee_damage[0] and sets[2].melee_damage[0]>sets[1].melee_damage[0],"Melee roles match damage ordering")
	check(sets[1].cooldown<sets[2].cooldown and sets[2].cooldown<sets[0].cooldown,"Very-fast, balanced, heavy cadence ordering")
	check(sets[0].range<sets[2].range and sets[1].range<sets[2].range and sets[2].range<sets[3].range,"Close, mid and long reach ordering")
	check(sets[3].damage<sets[2].damage and sets[3].cooldown>sets[1].cooldown and sets[3].cooldown<sets[0].cooldown,"Long range trades damage for reach with moderate cadence")
	for i in sets.size():
		var weapon: Dictionary = sets[i]
		prepare(i,float(weapon.melee_range[0])-3)
		game.melee()
		check(game.training_damage == 0 and game.melee_windup>0,"Strike respects set windup")
		var pending = game.melee_snapshot.duplicate(true)
		game.melee()
		check(game.melee_snapshot == pending,"Repeated input cannot bypass recovery")
		finish_strike()
		check(is_equal_approx(game.training_last_hit,float(weapon.melee_damage[0])),"Set strike applies its own damage")
		check(game.training_hit_count == 1,"One damage application per strike")
		check(game.energy<=game.run.stat("energy") and game.resonance<=100,"Strike rewards remain capped")
		prepare(i,float(weapon.melee_range[0])+2)
		game.melee(); finish_strike()
		check(game.training_hit_count == 0,"Melee cannot hit beyond declared reach")
		prepare(i,200)
		game.shoot()
		check(game.shots.size() == 1,"One projectile per fire activation")
		var shot = game.shots[0]
		check(shot.source_set == i and shot.tint == Color(weapon.color),"Projectile captures originating set and appearance")
		check(is_equal_approx(shot.damage,float(weapon.damage)),"Projectile captures set damage")
		var muzzle = shot.position
		shot.step(10.0)
		check(is_equal_approx(shot.distance_traveled,float(weapon.range)-24) and shot.life<=0,"Large delta cannot extend projectile range")
		check(is_equal_approx(muzzle.distance_to(shot.position),float(weapon.range)-24),"Projectile endpoint clamps precisely")
		var beyond = shot.position+shot.velocity.normalized()*(shot.radius+44)
		check(not shot.intersects(beyond,43),"Swept collision does not extend beyond projectile endpoint")
		prepare(i)
		game.melee(); var recovery = game.melee_cd
		game.cycle_weapon()
		check(game.melee_cd == recovery and game.combo == 0,"Set swapping preserves recovery and resets combo")
		check(game.melee_snapshot.id == weapon.id,"Set swapping preserves original queued attack")
		finish_strike()
		check(is_equal_approx(game.training_last_hit,float(weapon.melee_damage[0])),"Queued attack cannot inherit a new set's damage")
	var gains: Array[float] = []
	for index in [0,1]:
		prepare(index); game.resonance = 0; game.shoot(); game.simulate(0.016)
		gains.append(game.resonance-0.4)
	check(gains[0]>gains[1],"Heavy ranged hit earns more meter than one light hit")
	check(is_equal_approx(gains[0]/float(sets[0].damage),gains[1]/float(sets[1].damage)),"Ranged meter scales with impact rather than projectile count")
	prepare(0)
	game.melee(); var committed = game.melee_cd; game.dodge()
	check(game.melee_snapshot.is_empty() and game.melee_cd == committed,"Dodge cancels windup without refunding recovery")
	game.simulate(0.3)
	check(game.training_hit_count == 0,"Cancelled heavy swing cannot damage later")
	prepare(0)
	game.melee(); game.melee_snapshot.facing = Vector2.LEFT; finish_strike()
	check(game.training_hit_count == 0,"Directional melee cannot hit behind its committed aim")
	prepare(1)
	game.training = false; game.run.upgrades.append("siphon"); game.hp = 50
	game.melee(); finish_strike()
	check(is_equal_approx(game.hp,50+float(sets[1].melee_damage[0])*0.05),"Healing scales with damage, not attack count")
	prepare(0)
	game.run.upgrades.append("edge"); game.melee(); finish_strike()
	check(is_equal_approx(game.training_last_hit,float(sets[0].melee_damage[0])*1.2),"Melee upgrade applies exactly once")
	game.shoot_cd = 0; game.run.upgrades.append("fire"); game.shots.clear(); game.shoot()
	check(is_equal_approx(game.shots[0].damage,float(sets[0].damage)*1.2),"Ranged upgrade applies to set damage")
	game.equip_set(3,true)
	var saved = game.Profile.new(); saved.path = game.profile.path; saved.load_profile()
	check(saved.data.weapon == 3,"Preferred set persists in profile")
	var restored = game.RunState.new(); check(restored.restore(game.run.snapshot(1,false)) and restored.loadout_index == 3,"Checkpoint preserves active set")
	check(restored.restore({"boss":1}) and restored.loadout_index == game.Arsenal.DEFAULT,"Older checkpoints default to balanced set")
	check(restored.restore({"boss":1,"weapon":{}}) and restored.loadout_index == game.Arsenal.DEFAULT,"Malformed set choice recovers safely")
	prepare(2); game.damage_boss(50); game.damage_boss(25)
	check(game.training_damage == 75 and game.training_hit_count == 2 and game.training_last_hit == 25,"Training damage totals and hit readout")
	check(game.training_dps() == 15,"Training readout uses explicit five-second average")
	game.elapsed += 6; game.simulate(0.005)
	check(game.training_dps() == 0,"Training DPS window expires old damage")
	game.reset_training_readout()
	check(game.training_damage == 0 and game.training_hit_count == 0,"Training readout resets independently")
	DirAccess.remove_absolute(game.profile.path)
	game.queue_free()
	print("WEAPON_TESTS checks=",checks," failures=",failures)
	quit(1 if failures else 0)
