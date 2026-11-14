extends RefCounted
const INK = Color("473f36")
const CREAM = Color("faf4e6")
const OLIVE = Color("657653")
static func box(color: Color, border := Color("d8cbb4"), radius := 16) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = color
    s.border_color = border
    s.set_border_width_all(2)
    s.set_corner_radius_all(radius)
    s.content_margin_left = 22
    s.content_margin_right = 22
    s.content_margin_top = 12
    s.content_margin_bottom = 12
    return s
static func theme() -> Theme:
    var t := Theme.new()
    t.default_font = load("res://assets/fonts/NotoSansKR.otf")
    t.default_font_size = 20
    t.set_color("font_color", "Label", INK)
    t.set_color("font_color", "Button", INK)
    t.set_color("font_hover_color", "Button", INK)
    t.set_color("font_focus_color", "Button", INK)
    t.set_color("font_pressed_color", "Button", CREAM)
    t.set_stylebox("normal", "Button", box(Color("eee5d2")))
    t.set_stylebox("hover", "Button", box(Color("e2e8d3"), OLIVE))
    t.set_stylebox("pressed", "Button", box(OLIVE, OLIVE))
    t.set_stylebox("focus", "Button", box(Color(0,0,0,0), Color("af7850")))
    t.set_stylebox("panel", "PanelContainer", box(CREAM))
    return t
static func label(text: String, size := 20) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    return l
