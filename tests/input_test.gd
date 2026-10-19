extends SceneTree
## Inject events through Godot's input dispatcher, not combat-method shortcuts.
var checks := 0
var failures := 0
var game: Node2D
func check(condition: bool,label: String) -> void:
	checks += 1
	if not condition: failures += 1; push_error(label)
func settle() -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
func key(code: Key,pressed: bool = true) -> void:
	var event = InputEventKey.new(); event.physical_keycode = code; event.keycode = code; event.pressed = pressed
	Input.parse_input_event(event)
	await settle()
func tap_key(code: Key) -> void:
	await key(code); await key(code,false)
func click(p: Vector2) -> void:
	var event = InputEventMouseButton.new(); event.position = root.get_final_transform()*p; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true
	Input.parse_input_event(event); await settle()
	event = InputEventMouseButton.new(); event.position = root.get_final_transform()*p; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = false
	Input.parse_input_event(event); await settle()
func touch(index: int,p: Vector2,pressed: bool) -> void:
	var event = InputEventScreenTouch.new(); event.index = index; event.position = root.get_final_transform()*p; event.pressed = pressed
	Input.parse_input_event(event); await settle()
func _initialize() -> void: call_deferred("run_tests")
func run_tests() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game); game.set_process(false); game.sound.enabled = false
	game.profile.path = "user://input-test-profile.json"; game.profile.data.checkpoint = {}
	print("INPUT_VIEWPORT size=",root.size," transform=",root.get_final_transform())
	await settle()
	check(game.buttons.size()>=5,"Title controls render")
	await tap_key(KEY_ENTER)
	check(game.screen == "loadout","Enter opens difficulty selection")
	await click(Vector2(640,611))
	check(game.screen == "playing" and not game.practice and not game.training,"Mouse begins full performance")
	await key(KEY_J)
	game.simulate(0.016)
	check(not game.shots.is_empty(),"Keyboard firing through Input dispatcher")
	await key(KEY_J,false)
	var old_set = game.weapon_index
	await tap_key(KEY_Q)
	check(game.weapon_index == (old_set+1)%game.Arsenal.SETS.size(),"Q switches weapons")
	await tap_key(KEY_ESCAPE)
	check(game.screen == "paused","Escape pauses")
	await tap_key(KEY_H)
	check(game.screen == "help" and game.settings_from == "paused","Guide keeps pause return target")
	await tap_key(KEY_ESCAPE)
	check(game.screen == "paused","Guide returns to paused state")
	game.command("arsenal"); await settle()
	await tap_key(KEY_H); await tap_key(KEY_ESCAPE)
	check(game.screen == "arsenal","Nested guide returns to Arsenal")
	await tap_key(KEY_ESCAPE)
	check(game.screen == "paused","Arsenal retains its own return path after nested guide")
	await tap_key(KEY_ESCAPE)
	check(game.screen == "playing","Escape resumes")
	await touch(0,Vector2(200,500),true)
	check(game.move_finger == 0,"First touch creates movement stick")
	var drag = InputEventScreenDrag.new(); drag.index = 0; drag.position = root.get_final_transform()*Vector2(260,500); drag.relative = root.get_final_transform().basis_xform(Vector2(60,0))
	Input.parse_input_event(drag); await settle()
	check(game.touch_move.x>0.8,"Dragging movement stick updates direction")
	await touch(1,Vector2(1180,460),true)
	check(game.touch_actions.get(1) == "shoot","Second touch can fire while moving")
	await touch(1,Vector2(1180,460),false)
	check(not game.touch_actions.has(1),"Fire release clears action")
	await touch(0,Vector2(260,500),false)
	check(game.move_finger == -1 and game.touch_move == Vector2.ZERO,"Movement release clears stick")
	await touch(2,Vector2(1190,92),true)
	check(game.screen == "paused" and game.touch_actions.is_empty(),"Touch pause clears held actions")
	await touch(2,Vector2(1190,92),false)
	game.command("training"); await settle()
	await touch(0,Vector2(600,215),true); await touch(0,Vector2(600,215),false)
	check(game.training_attacks,"Touch training attack toggle")
	await touch(1,Vector2(700,215),true); await touch(1,Vector2(700,215),false)
	check(game.side,"Touch training view toggle")
	game.command("menu"); await settle()
	await tap_key(KEY_UP)
	check(game.menu_focus == game.buttons.size()-1,"Up initially selects last menu action")
	root.size = Vector2i(720,1280); await settle()
	game.command("menu"); await settle()
	await touch(0,Vector2(290,445),true); await touch(0,Vector2(290,445),false)
	check(game.screen == "loadout","Letterboxed portrait touch opens new run")
	await touch(0,Vector2(640,611),true); await touch(0,Vector2(640,611),false)
	check(game.screen == "playing" and not game.training,"Letterboxed portrait touch begins combat")
	DirAccess.remove_absolute(game.profile.path)
	game.queue_free()
	print("INPUT_TESTS checks=",checks," failures=",failures)
	quit(1 if failures else 0)
