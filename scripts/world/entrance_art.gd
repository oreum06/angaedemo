extends Node2D
var font = preload("res://assets/fonts/NotoSansKR.otf")
func _draw() -> void:
    draw_rect(Rect2(0,0,1280,720), Color("bdc9aa"))
    draw_colored_polygon(PackedVector2Array([Vector2(440,720),Vector2(610,720),Vector2(700,490),Vector2(1200,315),Vector2(1170,230),Vector2(600,415)]),Color("ded0b2"))
    draw_rect(Rect2(168,300,464,200), Color("d6c9ab"))
    for i in range(85):
        var x := float((i * 173 + 41) % 1240 + 20)
        var y := float((i * 97 + 43) % 660 + 30)
        if x > 650 and y > 390 or x < 150:
            draw_line(Vector2(x,y),Vector2(x-3,y-6),Color("99ac87"),2)
            draw_line(Vector2(x,y),Vector2(x+4,y-4),Color("99ac87"),2)
    # Bus shelter and garden wall are also physical obstacles in the map.
    draw_rect(Rect2(190,215,210,78),Color("aa9b80"))
    draw_rect(Rect2(200,229,190,55),Color("e9dfc8"))
    draw_rect(Rect2(183,202,224,28),Color("7c8967"))
    draw_line(Vector2(205,281),Vector2(385,281),Color("80674f"),8)
    draw_string(font,Vector2(244,258),"안개골",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("574d3e"))
    draw_rect(Rect2(210,530,200,34),Color("a5a28b"))
    for i in range(5):
        draw_line(Vector2(210+i*40,530),Vector2(210+i*40,564),Color("c4c2a6"),2)
    # Bread sign.
    draw_line(Vector2(1075,284),Vector2(1075,355),Color("8c7152"),7)
    draw_rect(Rect2(1015,258,160,40),Color("ede1c7"))
    draw_string(font,Vector2(1037,286),"빵집 →",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("62533e"))
    for pos in [Vector2(100,180),Vector2(480,160),Vector2(760,175),Vector2(940,140),Vector2(1190,480),Vector2(850,600),Vector2(90,560)]:
        draw_rect(Rect2(pos+Vector2(-8,-20),Vector2(16,50)),Color("948268"))
        draw_circle(pos+Vector2(0,-45),49,Color("849a79"))
        draw_circle(pos+Vector2(-21,-58),30,Color("98ac87"))
        draw_circle(pos+Vector2(20,-63),32,Color("a4b58e"))
    draw_string(font,Vector2(65,670),"버스 정류장",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("68785b"))
