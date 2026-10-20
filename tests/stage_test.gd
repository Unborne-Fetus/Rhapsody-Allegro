extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run_tests")
func run_tests() -> void:
	var game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_process(false); game.sound.enabled = false; game.profile.path = "user://stage-tests.json"
	check(game.StageArt.ATLAS != null and game.StageArt.ATLAS.get_size() == Vector2(768,528),"Twelve boss columns and six pixel animation rows import correctly")
	for index in 12:
		for pose in 6:
			var region = game.StageArt.region(index)
			region.position.y = pose*game.StageArt.CELL.y
			check(Rect2(Vector2.ZERO,Vector2(game.StageArt.ATLAS.get_size())).encloses(region),"Every boss idle, movement, attack, and hurt frame is inside the atlas")
	for character in game.Characters.ROSTER:
		check(not character.music.is_empty(),"Every playable character has a musical role")
	for index in 12:
		var base = game.sound.music_stream(index,false); var layer = game.sound.music_stream(index,true)
		check(base != null and layer != null and base.loop and layer.loop,"Each boss has an actual looping score and intensity stem")
		check(base.get_length()>20 and absf(base.get_length()-layer.get_length())<.01,"Music stems are long and synchronized")
	game.start_fight(0); game.player = Vector2(400,400); game.boss = Vector2(850,300)
	var original_player = game.player; var elapsed = game.elapsed
	game.change_perspective(true)
	check(game.shift_left == game.SHIFT_DURATION and game.side,"Shift starts a timed bridge toward side view")
	check(game.shift_position(game.player,game.shift_from_player) == original_player,"Shift begins at the old visual position")
	var reserve = game.energy
	game.melee(); game.shoot(); game.dodge(); game.jump(); game.burst(); game.invincible = 0; var hp = game.hp; game.hurt(100)
	check(game.energy == reserve and game.hp == hp and game.melee_snapshot.is_empty() and game.shots.is_empty(),"Combat inputs and damage are blocked during modulation")
	game.simulate(game.SHIFT_DURATION/2)
	var midpoint = game.shift_position(game.player,game.shift_from_player)
	check(midpoint.distance_to(original_player)>10 and midpoint.distance_to(game.player)>10,"Fighter moves through intermediate positions")
	check(game.elapsed == elapsed and game.windup == 0 and game.hazards.is_empty(),"Combat clock and attacks stay frozen during bridge")
	game.screen = "paused"; var remaining = game.shift_left; game._process(.04)
	check(game.shift_left == remaining,"Pause freezes the transition")
	game.screen = "playing"; game.simulate(game.SHIFT_DURATION)
	check(game.shift_left == 0 and game.shift_position(game.player,game.shift_from_player) == game.player,"Shift lands exactly at playable destination")
	game.change_perspective(false); game.simulate(game.SHIFT_DURATION/2)
	check(not game.side and game.shift_left>0,"Reverse modulation also animates")
	game.start_fight(4); check(game.shift_left == 0,"Retry/start clears unfinished transition")
	# Real AudioStreamPlayers, independently of combat-effect voices.
	game.sound.enabled = true
	game.sound.sync_music(4,0,true,false,true)
	check(game.sound.music.playing and game.sound.intensity.playing and game.sound.music_index == 4,"Boss music actually starts both synchronized players")
	game.sound.sync_music(4,2,true,false,true,2)
	check(game.sound.intensity.volume_db == -11 and game.sound.music_phase == 2,"Final phase brings in intensity arrangement")
	game.sound.sync_music(4,2,false,true,true)
	check(game.sound.music.stream_paused and game.sound.intensity.stream_paused,"Pause silences both music stems without losing position")
	game.sound.sync_music(4,2,true,false,true)
	check(not game.sound.music.stream_paused,"Resume restores the track")
	game.sound.sync_music(4,2,true,false,false)
	check(not game.sound.music.playing and game.sound.music_index == -1,"Music preference stops playback")
	game.sound.sync_music(11,0,true,false,true)
	check(game.sound.music_index == 11 and game.sound.music.playing,"New encounter loads its own score")
	game.sound.sync_music(11,0,false,false,true)
	check(not game.sound.music.playing and not game.sound.intensity.playing,"Leaving combat stops music")
	game.profile.data.music = false; game.profile.save_profile(); var profile = game.Profile.new(); profile.path = game.profile.path; profile.load_profile()
	check(not profile.data.music,"Boss music preference persists")
	DirAccess.remove_absolute(game.profile.path); game.sound.streams.clear(); game.sound.music.stream = null; game.sound.intensity.stream = null; game.queue_free()
	await process_frame
	await process_frame
	print("STAGE_TESTS checks=",checks," failures=",failures); quit(1 if failures else 0)
