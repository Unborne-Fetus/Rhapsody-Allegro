extends SceneTree
## A real project boot check for local and hosted release builds.
## Godot can return exit code 0 after logging dependency parse failures, and
## may still emit an unusable .exe/.pck. Only create the success marker after
## the actual main scene and its dependencies load and become initialized.
const MARKER := "res://build/preflight-ok.txt"
const StageArt = preload("res://scripts/stage_art.gd")

func _initialize() -> void:
	call_deferred("verify_project")

func fail(message: String) -> void:
	push_error("RHAPSODY_PREFLIGHT_FAILED: " + message)
	quit(1)

func verify_project() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		fail("Main scene cannot load.")
		return
	var game: Node = packed.instantiate()
	if game == null or game.get_script() == null:
		fail("Main game scene or attached script failed to compile.")
		return
	root.add_child(game)
	await process_frame
	if not is_instance_valid(game):
		fail("Main game did not initialize.")
		return
	game.set_process(false)
	if game.get("profile") == null or game.get("sound") == null:
		fail("Game's profile or sound subsystem did not initialize.")
		return
	var boss_list: Variant = game.get("bosses")
	if not (boss_list is Array) or boss_list.size() != 12:
		fail("The 12 boss encounters did not load.")
		return
	# Validate the *real* sprite resources, not merely filenames.
	if StageArt.ATLAS == null or StageArt.PixelPerformers.ATLAS == null:
		fail("Musician or boss pixel atlas failed to load.")
		return
	if StageArt.ATLAS.get_size() != Vector2(768,528) or StageArt.PixelPerformers.ATLAS.get_size() != Vector2(320,320):
		fail("Pixel atlases have unexpected dimensions.")
		return
	var file := FileAccess.open(MARKER,FileAccess.WRITE)
	if file == null:
		fail("Cannot write boot marker to build/.")
		return
	file.store_string("RHAPSODY_PREFLIGHT_OK\n")
	file.close()
	print("RHAPSODY_PREFLIGHT_OK")
	game.queue_free()
	quit(0)
