extends Node2D
func _draw() -> void:
    draw_set_transform(Vector2.ZERO,0,Vector2(1,0.4))
    draw_circle(Vector2(0,4),24,Color(0.2,0.22,0.16,0.17))
    draw_set_transform(Vector2.ZERO)
    draw_rect(Rect2(-30,-10,60,15),Color("927c5f"))
    draw_line(Vector2(-10,-10),Vector2(-17,8),Color("736b57"),9)
    draw_line(Vector2(7,-10),Vector2(17,8),Color("736b57"),9)
    draw_circle(Vector2(0,-25),19,Color("879370"))
    draw_circle(Vector2(0,-47),12,Color("e1bb97"))
    draw_arc(Vector2(0,-49),12,PI,TAU,12,Color("827263"),5)
    draw_line(Vector2(-7,-46),Vector2(-2,-45),Color("615343"),2)
    draw_line(Vector2(2,-45),Vector2(7,-46),Color("615343"),2)
    draw_rect(Rect2(36,-2,32,21),Color("b2956e"))
    var fruit_done: bool = GameState.flags.fruit_choice == "pick"
    for v in ([Vector2(45,0),Vector2(57,2)] if fruit_done else [Vector2(30,32),Vector2(-20,39),Vector2(55,24)]):
        draw_circle(v,7,Color("c18b56"))
        draw_line(v+Vector2(0,-4),v+Vector2(2,-10),Color("738455"),2)
