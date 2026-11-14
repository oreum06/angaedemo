extends Node
signal changed
const DEFAULTS = {"intro_done": false, "fruit_event_done": false, "bakery_done": false,
    "delivery_1_done": false, "delivery_2_done": false, "walk_choice": "", "ending_seen": false,
    "fruit_choice": ""}
var flags: Dictionary = DEFAULTS.duplicate()
var dialogue_active := false
var stage := "ARRIVAL"
func _ready() -> void:
    var keys = {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
        "move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
        "interact": [KEY_E, KEY_ENTER], "pause": [KEY_ESCAPE]}
    for action in keys:
        if not InputMap.has_action(action): InputMap.add_action(action)
        for key in keys[action]:
            var event := InputEventKey.new()
            event.physical_keycode = key
            InputMap.action_add_event(action, event)
func reset() -> void:
    flags = DEFAULTS.duplicate()
    stage = "ARRIVAL"
    dialogue_active = false
    changed.emit()
func apply(values: Dictionary) -> void:
    for key in values:
        if flags.has(key): flags[key] = values[key]
    stage = "BAKERY" if flags.fruit_event_done else "ARRIVAL"
    changed.emit()
