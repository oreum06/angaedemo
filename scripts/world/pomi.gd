extends CharacterBody2D
@export var speed := 210.0
var facing := Vector2.DOWN
var phase := 0.0
func _physics_process(delta: float) -> void:
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if GameState.dialogue_active: direction = Vector2.ZERO
    velocity = direction * speed
    if direction != Vector2.ZERO:
        facing = direction
        phase += delta * 12.0
    else: phase = 0.0
    move_and_slide()
    queue_redraw()
func _draw() -> void:
    draw_set_transform(Vector2.ZERO, 0, Vector2(1,0.4))
    draw_circle(Vector2(0,3), 20, Color(0.2,0.22,0.16,0.18))
    draw_set_transform(Vector2.ZERO)
    var stride := sin(phase) * 4.0
    draw_line(Vector2(-7,-14), Vector2(-7,0+stride), Color("534a43"), 7)
    draw_line(Vector2(7,-14), Vector2(7,0-stride), Color("534a43"), 7)
    draw_colored_polygon(PackedVector2Array([Vector2(-13,-40), Vector2(13,-40), Vector2(17,-12), Vector2(-17,-12)]), Color("c9b28b"))
    draw_line(Vector2(0,-34), Vector2(0,-14), Color("927d60"), 2)
    draw_circle(Vector2(0,-49), 14, Color("443a36"))
    draw_circle(Vector2(0,-47), 10, Color("e8c4a4"))
    draw_arc(Vector2(0,-51), 11, PI, TAU, 16, Color("443a36"), 8)
    draw_circle(Vector2(-12,-47), 6, Color("443a36"))
    draw_line(Vector2(-9,-39), Vector2(14,-17), Color("725444"), 3)
    draw_rect(Rect2(9,-26,13,14), Color("85644c"))
    if facing.y >= 0:
        draw_circle(Vector2(-4,-46), 1.2, Color("443a36"))
        draw_circle(Vector2(4,-46), 1.2, Color("443a36"))
