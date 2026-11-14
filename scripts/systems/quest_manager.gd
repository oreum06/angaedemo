extends RefCounted
static func objective() -> String:
    if not GameState.flags.intro_done: return "버스표와 바람나침반 확인하기"
    if not GameState.flags.fruit_event_done: return "쉬고 있는 주민 곁으로 가 보기"
    return "오른쪽 빵집 표지판에서 방향 확인하기"
static func dialogue_for(target: String) -> String:
    if target == "resident":
        return "fruit_repeat" if GameState.flags.fruit_event_done else "fruit_start"
    return "gate_ready" if GameState.flags.fruit_event_done else "gate_locked"
