extends SceneTree
var game: Node2D
func _initialize() -> void: call_deferred("capture_all")
func capture(label: String) -> void:
	game.queue_redraw(); await process_frame; await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/screenshots/stage-"+label+".png")
func capture_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://build/screenshots")
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game); game.set_process(false); game.sound.enabled = false
	game.profile.path = "user://stage-presentation.json"
	for page in range(4):
		game.screen = "select"; game.boss_page = page; await capture("gallery-"+str(page))
	game.command("arsenal"); await capture("heroes")
	game.command("menu"); game.practice = true; game.training = false; game.start_fight(4); game.banner_time = 0
	game.player = Vector2(500,440); game.boss = Vector2(850,400)
	await capture("combat")
	game.change_perspective(true)
	for t in [0.0,.25,.5,.75,1.0]:
		game.shift_left = game.SHIFT_DURATION*(1-t); await capture("shift-"+str(t))
	game.change_perspective(false); game.shift_left = game.SHIFT_DURATION/2; await capture("reverse")
	game.phone_mode = true; root.size = Vector2i(844,390); game.configure_phone(); game.shift_left = 0
	game.screen = "select"; game.phone.boss_focus = 9; await capture("phone-boss")
	game.screen = "arsenal"; await capture("phone-hero")
	root.size = Vector2i(390,844); game.configure_phone(); await capture("portrait-hero")
	game.screen = "select"; await capture("portrait-boss")
	game.command("menu"); game.start_fight(7); game.banner_time = 0; game.change_perspective(true); game.shift_left = game.SHIFT_DURATION/2
	await capture("portrait-shift")
	print("STAGE_PRESENTATION_COMPLETE"); quit()
