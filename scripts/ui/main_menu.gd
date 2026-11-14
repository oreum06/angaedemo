extends Control
const UI = preload("res://scripts/ui/ui_style.gd")
func _ready() -> void:
    theme = UI.theme()
    var background = preload("res://scenes/maps/village_entrance.tscn").instantiate()
    add_child(background)
    var veil := ColorRect.new()
    veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    veil.color = Color(0.93,0.93,0.83,0.76)
    veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(veil)
    var column := VBoxContainer.new()
    column.position = Vector2(415,135)
    column.size = Vector2(450,470)
    column.add_theme_constant_override("separation",18)
    add_child(column)
    for pair in [["바람이 머무는 작은 마을",18],["안개골",66],["바람나침반",30],["잠시, 내 마음이 향하는 쪽으로.",20]]:
        var l = UI.label(pair[0],pair[1])
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        column.add_child(l)
    var space := Control.new()
    space.custom_minimum_size.y = 20
    column.add_child(space)
    var start := Button.new()
    start.name = "Start"
    start.text = "마을에 들어가기"
    start.custom_minimum_size.y = 58
    start.pressed.connect(start_game)
    column.add_child(start)
    var quit := Button.new()
    quit.text = "종료"
    quit.pressed.connect(func(): get_tree().quit())
    column.add_child(quit)
    start.grab_focus()
    var hint = UI.label("WASD / 방향키  이동     ·     E / Enter  대화     ·     Esc  일시정지",17)
    hint.position = Vector2(295,645)
    add_child(hint)
func start_game() -> void:
    GameState.reset()
    get_tree().change_scene_to_file("res://scenes/world.tscn")

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
        var focused := get_viewport().gui_get_focus_owner()
        if focused is Button:
            get_viewport().set_input_as_handled()
            focused.pressed.emit()
