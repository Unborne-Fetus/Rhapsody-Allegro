extends SceneTree
var game: Node2D
func _initialize() -> void: call_deferred("capture_all")
func capture(label: String) -> void:
	game.queue_redraw(); await process_frame; await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/screenshots/phone-"+label+".png")
func capture_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://build/screenshots")
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game); game.set_process(false); game.sound.enabled = false
	game.profile.path = "user://phone-presentation.json"; game.phone_mode = true; game.profile.data.auto_attack = true
	for portrait in [false,true]:
		root.size = Vector2i(390,844) if portrait else Vector2i(844,390)
		game.configure_phone(); var tag = "portrait-" if portrait else "landscape-"
		for screen in ["title","loadout","arsenal","select","settings","help","intermission"]:
			game.command("menu"); game.screen = screen; game.phone.boss_focus = 6
			game.upgrade_options = [game.RunState.UPGRADES[3],game.RunState.UPGRADES[7],game.RunState.UPGRADES[4]]
			await capture(tag+screen)
		game.command("menu"); game.practice = true; game.training = false; game.start_fight(5); game.banner_time = 0; game.aim_snapshot = game.player
		game.execute_pattern("dancefloor"); game.execute_pattern("six_step")
		await capture(tag+"combat")
		game.profile.data.auto_attack = false; await capture(tag+"manual"); game.profile.data.auto_attack = true
		game.screen = "paused"; await capture(tag+"pause")
		game.command("menu"); game.start_tutorial(); game.tutorial.step = 6; game.setup_tutorial_stage()
		await capture(tag+"tutorial")
	print("PHONE_PRESENTATION_COMPLETE"); quit()
