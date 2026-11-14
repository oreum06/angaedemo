extends Node
var failures := 0
var checks := 0
var world: Node
func check(ok: bool, message: String) -> void:
    checks += 1
    print(("PASS " if ok else "FAIL ") + message)
    if not ok: failures += 1
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("run")
func frames(count := 3) -> void:
    for i in count: await get_tree().process_frame
func key(code: int, echo := false) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = true
    event.echo = echo
    Input.parse_input_event(event)
    await frames(2)
    event = InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = false
    Input.parse_input_event(event)
    await frames(2)
func ready_line() -> void:
    world.dialogue.elapsed = 1000.0
    world.dialogue.cooldown = 0.0
    await frames(2)
func next_line() -> void:
    await ready_line()
    await key(KEY_E)
func screenshot(file: String) -> void:
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        var err := get_viewport().get_texture().get_image().save_png("res://verification/" + file + ".png")
        check(err == OK, "render screenshot: " + file)
func run() -> void:
    # Keep this runner alive while the actual application changes scenes.
    get_tree().current_scene = null
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
    await frames(8)
    check(get_tree().current_scene.name == "MainMenu", "real main scene loaded")
    await screenshot("01-menu")
    await key(KEY_ENTER)
    await frames(8)
    world = get_tree().current_scene
    check(world.name == "World", "Enter on Start changes to World")
    if world.name != "World":
        get_tree().quit(1)
        return
    check(world.manager.validate_data(), "dialogue references and flag keys valid")
    check(world.manager.current_id == "intro_1", "start key does not skip introduction")
    await ready_line()
    await screenshot("02-arrival")
    var initial: Vector2 = world.player.position
    Input.action_press("move_right")
    await get_tree().create_timer(0.25).timeout
    Input.action_release("move_right")
    check(world.player.position == initial, "movement blocked during dialogue")
    await key(KEY_E, true)
    check(world.manager.current_id == "intro_1", "keyboard repeat ignored")
    await next_line()
    check(world.manager.current_id == "intro_2", "single confirm advances exactly one node")
    await key(KEY_E)
    check(world.manager.current_id == "intro_2", "rapid repeat suppressed by cooldown")
    # First press reveals current text without advancing.
    world.dialogue.elapsed = 0.0
    world.dialogue.cooldown = 0.0
    await frames(2)
    await key(KEY_E)
    check(world.manager.current_id == "intro_2", "reveal text does not skip a node")
    await next_line()
    await next_line()
    check(GameState.flags.intro_done and not world.manager.active, "intro finishes and unlocks movement")
    Input.action_press("move_right")
    await get_tree().create_timer(0.25).timeout
    Input.action_release("move_right")
    check(world.player.position.x > initial.x + 30, "movement resumes after dialogue")
    world.player.position = Vector2(440,550)
    Input.action_press("move_left")
    await get_tree().create_timer(0.4).timeout
    Input.action_release("move_left")
    check(world.player.position.x >= 421, "wall collision")
    world.player.position = Vector2(45,450)
    Input.action_press("move_left")
    await get_tree().create_timer(0.25).timeout
    Input.action_release("move_left")
    check(world.player.position.x >= 41, "map boundary collision")
    world.player.position = Vector2(648,420)
    Input.action_press("move_up")
    await get_tree().create_timer(0.4).timeout
    Input.action_release("move_up")
    check(world.player.position.y >= 403, "NPC collision")
    await frames()
    check(world.target == "resident" and world.prompt.visible, "NPC range prompt")
    await key(KEY_E)
    check(world.manager.current_id == "fruit_start", "E opens nearest NPC dialogue")
    await ready_line()
    await screenshot("03-choices")
    await key(KEY_DOWN)
    check(world.dialogue.selected == 1, "choice keyboard navigation")
    await key(KEY_ENTER)
    check(GameState.flags.fruit_choice == "pick", "Enter commits exactly selected choice")
    await next_line()
    await next_line()
    check(GameState.flags.fruit_event_done and GameState.stage == "BAKERY", "fruit choice updates quest and unlocks sign")
    await key(KEY_E)
    check(not world.manager.active, "closing key cannot immediately reopen dialogue")
    await get_tree().create_timer(0.25).timeout
    await key(KEY_E)
    check(world.manager.current_id == "fruit_repeat", "repeat NPC interaction is idempotent")
    await next_line()
    for choice_index in range(3):
        GameState.reset()
        GameState.apply({"intro_done":true})
        world.manager.start("fruit_start")
        world.manager.choose(choice_index)
        var guard := 0
        while world.manager.active and guard < 8:
            world.manager.advance()
            guard += 1
        check(GameState.flags.fruit_event_done and GameState.stage == "BAKERY", "branch %d reaches BAKERY without dead end" % choice_index)
        check(GameState.flags.fruit_choice == ["wake","pick","pass"][choice_index], "branch %d preserves choice flag" % choice_index)
    GameState.reset()
    GameState.apply({"intro_done":true})
    world.player.position = Vector2(1060,355)
    await get_tree().create_timer(0.25).timeout
    await key(KEY_E)
    check(world.manager.current_id == "gate_locked", "out-of-order sign gives guidance")
    await next_line()
    check(not GameState.flags.fruit_event_done, "locked sign cannot bypass fruit event")
    GameState.apply({"fruit_event_done":true})
    await get_tree().create_timer(0.25).timeout
    await key(KEY_E)
    check(world.manager.current_id == "gate_ready", "completed event opens destination dialogue")
    await next_line()
    check(world.manager.current_id == "stage_end", "stage boundary explains next development step")
    await next_line()
    await screenshot("04-entrance")
    # Pause during a live dialogue must freeze text, movement and choice state.
    world.manager.start("fruit_start")
    await ready_line()
    await key(KEY_ESCAPE)
    check(get_tree().paused and world.pause_panel.visible, "Esc pauses game during choices")
    initial = world.player.position
    Input.action_press("move_left")
    await get_tree().create_timer(0.15,true).timeout
    Input.action_release("move_left")
    check(world.player.position == initial, "pause freezes physics")
    await screenshot("05-pause")
    await key(KEY_ESCAPE)
    check(not get_tree().paused and world.manager.current_id == "fruit_start", "resume preserves dialogue")
    await key(KEY_ESCAPE)
    # Actual focused pause menu navigation and confirmation.
    await key(KEY_DOWN)
    await key(KEY_ENTER)
    await frames(6)
    check(get_tree().current_scene.name == "MainMenu", "pause menu returns to main menu")
    check(not GameState.dialogue_active and not GameState.flags.intro_done, "menu return resets flags and input lock")
    await key(KEY_E)
    await frames(6)
    world = get_tree().current_scene
    check(world.name == "World" and world.manager.current_id == "intro_1", "new game starts cleanly after menu return")
    print("INTEGRATION checks=%d failures=%d" % [checks,failures])
    get_tree().quit(1 if failures else 0)
