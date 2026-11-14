extends Node
signal line_changed(line: Dictionary)
signal closed
var nodes: Dictionary = {}
var current_id := ""
var active := false
func _ready() -> void:
    var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue/entrance.json"))
    if not parsed is Dictionary or not parsed.get("nodes") is Dictionary:
        push_error("Dialogue data is invalid")
        return
    nodes = parsed.nodes
    if not validate_data(): nodes.clear()
func validate_data() -> bool:
    for id in nodes:
        var line: Dictionary = nodes[id]
        if not line.has("speaker") or not line.has("text"):
            push_error("Missing dialogue text: " + id)
            return false
        var next: String = line.get("next", "")
        if next != "" and not nodes.has(next): return false
        for key in line.get("set", {}):
            if not GameState.flags.has(key): return false
        for choice in line.get("choices", []):
            if not nodes.has(choice.get("next", "")): return false
            for key in choice.get("set", {}):
                if not GameState.flags.has(key): return false
            for key in choice.get("when", {}):
                if not GameState.flags.has(key): return false
    return true
func choices() -> Array:
    var result := []
    for choice in nodes.get(current_id, {}).get("choices", []):
        var allowed := true
        for key in choice.get("when", {}):
            if GameState.flags.get(key) != choice.when[key]: allowed = false
        if allowed: result.append(choice)
    return result
func start(id: String) -> bool:
    if active or not nodes.has(id): return false
    active = true
    GameState.dialogue_active = true
    enter(id)
    return true
func enter(id: String) -> void:
    if id == "":
        active = false
        current_id = ""
        GameState.dialogue_active = false
        closed.emit()
        return
    current_id = id
    GameState.apply(nodes[id].get("set", {}))
    line_changed.emit(nodes[id])
func advance() -> void:
    if active and choices().is_empty(): enter(nodes[current_id].get("next", ""))
func choose(index: int) -> void:
    var available := choices()
    if not active or index < 0 or index >= available.size(): return
    var choice: Dictionary = available[index]
    GameState.apply(choice.get("set", {}))
    enter(choice.next)
