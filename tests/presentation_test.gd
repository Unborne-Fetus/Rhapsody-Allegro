extends SceneTree
## Optional native-renderer visual regression capture. Run with a real display or Xvfb.
var game: Node2D
func _initialize() -> void: call_deferred("run_capture")
func capture(label: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image = root.get_texture().get_image()
	image.save_png("res://build/screenshots/"+label+".png")
func run_capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://build/screenshots")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game); game.set_process(false); game.sound.enabled = false
	game.profile.path = "user://presentation-test-profile.json"
	game.profile.data.checkpoint = {}
	await capture("title")
	game.command("start"); await capture("loadout")
	game.command("training"); game.banner_time = 0; game.elapsed = 20
	game.execute_pattern("wave"); game.execute_pattern("fan")
	for i in 40: game.simulate(1.0/60.0)
	await capture("training")
	for boss in 3:
		game.start_fight(boss); game.banner_time = 0; game.elapsed = 20
		for pattern in ["mines","prism"]: game.execute_pattern(pattern)
		game.simulate(0.016)
		await capture("boss-"+str(boss))
	game.change_perspective(true); game.banner_time = 0; await capture("side-view")
	game.used_touch = true; await capture("touch")
	game.used_touch = false
	game.screen = "intermission"; game.upgrade_options = game.run.choices(0); await capture("intermission")
	game.screen = "settings"; await capture("settings")
	game.screen = "help"; await capture("guide")
	game.screen = "arsenal"; await capture("arsenal")
	for i in game.Arsenal.SETS.size():
		game.command("menu"); game.equip_set(i,true); game.command("training"); game.banner_time = 0
		game.player = Vector2(500,440); game.boss = Vector2(500+float(game.Arsenal.SETS[i].melee_range[0])-3,440)
		game.gamepad = true; game.melee()
		for frame in 80:
			if game.melee_snapshot.is_empty(): break
			game.simulate(0.005)
		await capture("set-"+str(i))
	game.command("menu"); game.start_tutorial()
	for step in [0,3,6,7]:
		game.tutorial.step = step; game.setup_tutorial_stage(); await capture("tutorial-"+str(step))
	game.command("menu"); game.screen = "intermission"
	game.upgrade_options = [game.RunState.UPGRADES[7],game.RunState.UPGRADES[1],game.RunState.UPGRADES[4]]
	game.ui_mouse_active = false
	for focus in 3:
		game.menu_focus = focus; game.upgrade_focus = focus; await capture("mechanic-"+str(focus))
	game.command("menu"); game.command("select"); game.boss_page = 0; await capture("boss-select-original")
	game.boss_page = 1; await capture("boss-select-songs")
	for index in range(3,7):
		game.command("menu"); game.practice = true; game.training = false; game.start_fight(index)
		game.banner_time = 0; game.elapsed = 20; game.aim_snapshot = game.player
		game.execute_pattern(game.bosses[index].patterns[0]); game.execute_pattern(game.bosses[index].patterns[1])
		game.simulate(0.016); await capture("song-"+str(index))
		game.screen = "paused"; await capture("song-notes-"+str(index)); game.screen = "playing"
		game.change_perspective(true); game.banner_time = 0; game.phase = 1; game.aim_snapshot = game.player
		game.execute_pattern(game.bosses[index].patterns[0]); game.simulate(0.016)
		await capture("song-side-"+str(index))
	print("PRESENTATION_CAPTURE_COMPLETE")
	quit()
