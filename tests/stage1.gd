extends Node
var failures := 0
func check(ok: bool, message: String) -> void:
    print(("PASS " if ok else "FAIL ") + message)
    if not ok: failures += 1
func _ready() -> void:
    call_deferred("run")
func run() -> void:
    var menu = load("res://scenes/main_menu.tscn").instantiate()
    add_child(menu)
    check(menu.find_child("Start", true, false) != null, "main menu start button exists")
    menu.queue_free()
    await get_tree().process_frame
    var world = load("res://scenes/world.tscn").instantiate()
    add_child(world)
    await get_tree().physics_frame
    while world.manager.active: world.manager.advance()
    var p = world.player
    var start: Vector2 = p.position
    Input.action_press("move_right")
    await get_tree().create_timer(0.3).timeout
    Input.action_release("move_right")
    check(p.position.x > start.x + 40, "movement executed by physics engine")
    p.position = Vector2(440,550)
    Input.action_press("move_left")
    await get_tree().create_timer(0.4).timeout
    Input.action_release("move_left")
    check(p.position.x >= 421, "garden wall blocks movement")
    print("STAGE1 failures=", failures)
    get_tree().quit(failures)
