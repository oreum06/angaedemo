extends CanvasLayer
const UI = preload("res://scripts/ui/ui_style.gd")
var manager: Node
var panel: PanelContainer
var speaker: Label
var body: Label
var hint: Label
var row: HBoxContainer
var buttons: Array[Button] = []
var selected := 0
var elapsed := 0.0
var cooldown := 0.0
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_PAUSABLE
    layer = 5
    panel = PanelContainer.new()
    panel.theme = UI.theme()
    panel.position = Vector2(48,438)
    panel.size = Vector2(1184,254)
    add_child(panel)
    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation",10)
    panel.add_child(col)
    speaker = UI.label("",21)
    col.add_child(speaker)
    body = UI.label("",23)
    body.custom_minimum_size = Vector2(1100,76)
    body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    col.add_child(body)
    row = HBoxContainer.new()
    row.add_theme_constant_override("separation",12)
    col.add_child(row)
    hint = UI.label("",16)
    col.add_child(hint)
    panel.hide()
func connect_manager(value: Node) -> void:
    manager = value
    manager.line_changed.connect(show_line)
    manager.closed.connect(func(): panel.hide())
func show_line(line: Dictionary) -> void:
    panel.show()
    var thought: bool = line.get("style", "") == "thought"
    speaker.text = line.speaker + ("  ·  속마음" if thought else "")
    speaker.modulate = Color("72815e") if thought else UI.INK
    body.text = line.text
    body.visible_characters = 0
    elapsed = 0.0
    cooldown = 0.18
    selected = 0
    for child in row.get_children():
        row.remove_child(child)
        child.queue_free()
    buttons.clear()
    var available: Array = manager.choices()
    for i in range(available.size()):
        var b := Button.new()
        b.text = str(i+1) + "  " + available[i].text
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.custom_minimum_size.y = 48
        b.focus_mode = Control.FOCUS_NONE
        b.pressed.connect(confirm.bind(i))
        row.add_child(b)
        buttons.append(b)
    hint.text = "← → / ↑ ↓ 선택   ·   E / Enter 확인   ·   1–3 바로 선택" if not buttons.is_empty() else "E / Enter  다음     ·     Esc  일시정지"
    highlight()
func _process(delta: float) -> void:
    cooldown = maxf(0.0, cooldown - delta)
    if not panel.visible: return
    elapsed += delta
    body.visible_characters = mini(int(elapsed * 44), body.text.length())
func highlight() -> void:
    for i in range(buttons.size()):
        buttons[i].modulate = Color("dce6c9") if i == selected else Color.WHITE
func confirm(index := -1) -> void:
    if get_tree().paused or not panel.visible or cooldown > 0: return
    cooldown = 0.16
    if body.visible_characters < body.text.length():
        elapsed = float(body.text.length()) / 44.0
        body.visible_characters = body.text.length()
        return
    if buttons.is_empty(): manager.advance()
    else: manager.choose(selected if index < 0 else index)
func _input(event: InputEvent) -> void:
    if not panel.visible: return
    if event.is_action_pressed("interact", true):
        get_viewport().set_input_as_handled()
        if not event.is_echo(): confirm()
    elif event is InputEventKey and event.pressed:
        if event.keycode in [KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT,KEY_1,KEY_2,KEY_3,KEY_W,KEY_A,KEY_S,KEY_D]:
            get_viewport().set_input_as_handled()
            if event.echo or buttons.is_empty(): return
            if event.keycode in [KEY_1,KEY_2,KEY_3]: confirm(event.keycode - KEY_1)
            else:
                var step := -1 if event.keycode in [KEY_UP,KEY_LEFT,KEY_W,KEY_A] else 1
                selected = posmod(selected + step, buttons.size())
                highlight()
