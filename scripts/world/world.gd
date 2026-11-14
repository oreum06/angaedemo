extends Node2D
const UI = preload("res://scripts/ui/ui_style.gd")
const Quest = preload("res://scripts/systems/quest_manager.gd")
@export var interaction_distance := 88.0
var player: CharacterBody2D
var manager: Node
var dialogue: CanvasLayer
var resident: Node2D
var target := ""
var prompt: Label
var objective: Label
var pause_panel: PanelContainer
var resume_button: Button
var pause_shade: ColorRect
var interaction_cooldown := 0.0
var locations := {"resident": Vector2(648,370), "sign": Vector2(1095,328)}
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(preload("res://scenes/maps/village_entrance.tscn").instantiate())
    for r in [Rect2(0,0,1280,135),Rect2(0,690,1280,30),Rect2(0,0,30,720),Rect2(1250,0,30,720),Rect2(183,202,224,95),Rect2(210,530,200,34)]:
        var b := StaticBody2D.new()
        b.position = r.get_center()
        var c := CollisionShape2D.new()
        var shape := RectangleShape2D.new()
        shape.size = r.size
        c.shape = shape
        b.add_child(c)
        add_child(b)
    player = preload("res://scenes/characters/pomi.tscn").instantiate()
    player.position = Vector2(480,540)
    player.process_mode = Node.PROCESS_MODE_PAUSABLE
    add_child(player)
    resident = Node2D.new()
    resident.set_script(preload("res://scripts/world/resident.gd"))
    resident.position = locations.resident
    add_child(resident)
    var solid := StaticBody2D.new()
    var collider := CollisionShape2D.new()
    var shape := CircleShape2D.new()
    shape.radius = 22
    collider.shape = shape
    solid.add_child(collider)
    resident.add_child(solid)
    var ui := CanvasLayer.new()
    add_child(ui)
    var hud := PanelContainer.new()
    hud.theme = UI.theme()
    hud.position = Vector2(32,24)
    hud.size = Vector2(1216,80)
    ui.add_child(hud)
    var row := HBoxContainer.new()
    hud.add_child(row)
    var title = UI.label("안개골  /  마을 입구",23)
    title.custom_minimum_size.x = 410
    row.add_child(title)
    objective = UI.label("",20)
    row.add_child(objective)
    prompt = UI.label("",18)
    prompt.theme = UI.theme()
    prompt.add_theme_stylebox_override("normal",UI.box(UI.CREAM))
    ui.add_child(prompt)
    var help = UI.label("WASD / 방향키  이동     E / Enter  말 걸기     Esc  쉬어가기",16)
    help.theme = UI.theme()
    help.position = Vector2(32,694)
    ui.add_child(help)
    manager = preload("res://scripts/systems/dialogue_manager.gd").new()
    add_child(manager)
    dialogue = preload("res://scripts/ui/dialogue_box.gd").new()
    add_child(dialogue)
    dialogue.connect_manager(manager)
    manager.closed.connect(func(): interaction_cooldown = 0.2)
    GameState.changed.connect(update_objective)
    update_objective()
    build_pause()
    manager.start("intro_1")

func update_objective() -> void:
    objective.text = "지금은  ·  " + Quest.objective()
    resident.queue_redraw()
func _process(delta: float) -> void:
    if get_tree().paused: return
    interaction_cooldown = maxf(0.0, interaction_cooldown - delta)
    target = ""
    var distance := interaction_distance
    for id in locations:
        var d: float = player.position.distance_to(locations[id])
        if d < distance:
            distance = d
            target = id
    prompt.visible = target != "" and not manager.active
    if prompt.visible:
        prompt.text = "E  ·  " + ("말 걸기" if target == "resident" else "표지판 보기")
        prompt.position = locations[target] + Vector2(-65,-105)
    # Feet determine overlap ordering.
    player.z_index = 2 if player.position.y > resident.position.y else 0
    resident.z_index = 1
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("pause") and not event.is_echo():
        get_viewport().set_input_as_handled()
        set_paused(not get_tree().paused)
    elif get_tree().paused and event.is_action_pressed("interact"):
        # Enter is handled by focused menu buttons. E is equivalent to confirm.
        if event is InputEventKey and event.physical_keycode == KEY_E:
            get_viewport().set_input_as_handled()
            if not event.is_echo():
                var focused := get_viewport().gui_get_focus_owner()
                if focused is Button: focused.pressed.emit()
func _unhandled_input(event: InputEvent) -> void:
    if get_tree().paused or manager.active or interaction_cooldown > 0: return
    if event.is_action_pressed("interact") and not event.is_echo() and target != "":
        get_viewport().set_input_as_handled()
        manager.start(Quest.dialogue_for(target))
func build_pause() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 10
    add_child(layer)
    pause_shade = ColorRect.new()
    pause_shade.color = Color(0.2,0.23,0.17,0.4)
    pause_shade.size = Vector2(1280,720)
    layer.add_child(pause_shade)
    pause_shade.hide()
    pause_panel = PanelContainer.new()
    pause_panel.theme = UI.theme()
    pause_panel.position = Vector2(420,206)
    pause_panel.size = Vector2(440,300)
    layer.add_child(pause_panel)
    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation",16)
    pause_panel.add_child(col)
    col.add_child(UI.label("잠시 쉬어가기",30))
    resume_button = Button.new()
    resume_button.text = "계속 걷기"
    resume_button.pressed.connect(func(): set_paused(false))
    col.add_child(resume_button)
    var back := Button.new()
    back.text = "메인 메뉴로 돌아가기"
    back.pressed.connect(return_to_menu)
    col.add_child(back)
    col.add_child(UI.label("메뉴로 돌아가면 진행이 초기화됩니다.",16))
    pause_panel.hide()
func set_paused(value: bool) -> void:
    get_tree().paused = value
    pause_panel.visible = value
    pause_shade.visible = value
    if value: resume_button.grab_focus()
    else:
        var focused := get_viewport().gui_get_focus_owner()
        if focused: focused.release_focus()
        interaction_cooldown = 0.2
        dialogue.cooldown = 0.2
func return_to_menu() -> void:
    get_tree().paused = false
    GameState.reset()
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
