extends "res://scripts/game_v6.gd"

const V7_BG := Color("#eef2f7")
const V7_INK := Color("#111827")
const V7_SLATE := Color("#334155")
const V7_SLATE_2 := Color("#475569")
const V7_LINE := Color("#cbd5e1")
const V7_SOFT := Color("#e2e8f0")
const V7_ACCENT := Color("#38bdf8")
const V7_RED := Color("#dc4455")
const V7_RED_DARK := Color("#7f2937")
const V7_GREEN := Color("#22c55e")
const V7_GOLD := Color("#f59e0b")

func _start_level(c: int, p: int) -> void:
    super._start_level(c, p)
    _add_environment_polish()

func _show_main_menu() -> void:
    super._show_main_menu()
    for child in hud.get_children():
        if child is Label and child.text == "ANDROID • v0.7":
            child.text = "ANDROID • v0.8"
    _polish_menu_surface()

func _show_chapter_select() -> void:
    super._show_chapter_select()
    _polish_menu_surface()

func _show_chapter_result() -> void:
    super._show_chapter_result()
    _polish_menu_surface()

func _build_hud() -> void:
    super._build_hud()

    for child in hud.get_children():
        if child is Button:
            _style_button_node(child)
        elif child is ColorRect:
            if child.size.y <= 120.0 and child.size.x > 900.0:
                child.color = Color(0.985, 0.99, 1.0, 0.93)
            elif child.size.y >= 80.0 and child.size.x <= 180.0:
                child.color = Color(0.055, 0.075, 0.11, 0.20)

    var accent := ColorRect.new()
    accent.position = Vector2(0, 66)
    accent.size = Vector2(1280, 4)
    accent.color = Color(0.22, 0.74, 0.95, 0.38)
    accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
    accent.z_index = 4
    hud.add_child(accent)

    var lower_fade := ColorRect.new()
    lower_fade.position = Vector2(0, 575)
    lower_fade.size = Vector2(1280, 145)
    lower_fade.color = Color(0.03, 0.05, 0.08, 0.045)
    lower_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    lower_fade.z_index = -2
    hud.add_child(lower_fade)

func _menu_button(text: String, pos: Vector2, size: Vector2, callback: Callable) -> Button:
    var button := Button.new()
    button.position = pos
    button.size = size
    button.text = text
    button.add_theme_font_size_override("font_size", 23)
    button.pressed.connect(callback)
    _style_button_node(button)
    hud.add_child(button)
    return button

func _style_button_node(button: Button) -> void:
    button.add_theme_color_override("font_color", V7_INK)
    button.add_theme_color_override("font_hover_color", V7_INK)
    button.add_theme_color_override("font_pressed_color", V7_INK)
    button.add_theme_color_override("font_disabled_color", Color("#94a3b8"))

    var normal := StyleBoxFlat.new()
    normal.bg_color = Color(1.0, 1.0, 1.0, 0.94)
    normal.border_color = Color(0.73, 0.79, 0.86, 0.72)
    normal.set_border_width_all(2)
    normal.set_corner_radius_all(15)
    normal.shadow_color = Color(0.05, 0.08, 0.13, 0.16)
    normal.shadow_size = 7
    normal.content_margin_left = 18.0
    normal.content_margin_right = 18.0

    var hover := normal.duplicate() as StyleBoxFlat
    hover.bg_color = Color("#f0f9ff")
    hover.border_color = V7_ACCENT

    var pressed := normal.duplicate() as StyleBoxFlat
    pressed.bg_color = Color("#e0f2fe")
    pressed.border_color = Color("#0ea5e9")
    pressed.shadow_size = 3

    var disabled := normal.duplicate() as StyleBoxFlat
    disabled.bg_color = Color(0.92, 0.94, 0.97, 0.75)
    disabled.border_color = Color(0.78, 0.82, 0.88, 0.55)
    disabled.shadow_size = 0

    button.add_theme_stylebox_override("normal", normal)
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", pressed)
    button.add_theme_stylebox_override("disabled", disabled)

func _polish_menu_surface() -> void:
    if not is_instance_valid(hud):
        return

    var line := ColorRect.new()
    line.position = Vector2(0, 90)
    line.size = Vector2(1280, 3)
    line.color = Color(0.22, 0.74, 0.95, 0.35)
    line.mouse_filter = Control.MOUSE_FILTER_IGNORE
    line.z_index = 2
    hud.add_child(line)

    for i in range(7):
        var deco := ColorRect.new()
        deco.position = Vector2(70 + i * 190, 610 + (i % 2) * 18)
        deco.size = Vector2(100 + (i % 3) * 24, 8)
        deco.color = Color(0.20, 0.30, 0.42, 0.08)
        deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
        deco.z_index = -1
        hud.add_child(deco)

func _platform(pos: Vector2, size: Vector2, color: Color) -> StaticBody2D:
    var body := super._platform(pos, size, color)

    var shadow := Polygon2D.new()
    shadow.position = Vector2(0, 6)
    shadow.polygon = PackedVector2Array([
        Vector2(-size.x / 2.0, -size.y / 2.0),
        Vector2(size.x / 2.0, -size.y / 2.0),
        Vector2(size.x / 2.0, size.y / 2.0),
        Vector2(-size.x / 2.0, size.y / 2.0)
    ])
    shadow.color = Color(0.02, 0.04, 0.08, 0.18)
    shadow.z_index = -2
    body.add_child(shadow)

    if size.y <= 100.0:
        var top_edge := Polygon2D.new()
        top_edge.position = Vector2(0, -size.y / 2.0 + 3.0)
        top_edge.polygon = PackedVector2Array([
            Vector2(-size.x / 2.0 + 3.0, -2.0),
            Vector2(size.x / 2.0 - 3.0, -2.0),
            Vector2(size.x / 2.0 - 3.0, 2.0),
            Vector2(-size.x / 2.0 + 3.0, 2.0)
        ])
        top_edge.color = color.lightened(0.22)
        top_edge.z_index = 2
        body.add_child(top_edge)

    return body

func _spikes(pos: Vector2, count: int, hidden: bool, inverted: bool = false) -> Area2D:
    var area := super._spikes(pos, count, hidden, inverted)
    var visual_count := 3 if count == 4 and not inverted else count

    var base := Polygon2D.new()
    base.position.y = -17.0 if inverted else 17.0
    base.polygon = PackedVector2Array([
        Vector2(-visual_count * 22.0, -3.0),
        Vector2(visual_count * 22.0, -3.0),
        Vector2(visual_count * 22.0, 3.0),
        Vector2(-visual_count * 22.0, 3.0)
    ])
    base.color = Color(0.42, 0.10, 0.14, 0.72)
    base.visible = not hidden
    base.z_index = -1
    area.add_child(base)
    return area

func _reveal(area: Area2D) -> void:
    super._reveal(area)
    for child in area.get_children():
        if child is Polygon2D:
            child.visible = true

func _hide(area: Area2D) -> void:
    super._hide(area)
    for child in area.get_children():
        if child is Polygon2D:
            child.visible = false

func _hazard_block(pos: Vector2, size: Vector2, color: Color) -> Area2D:
    var toned := color.lerp(V7_SLATE, 0.62)
    var area := super._hazard_block(pos, size, toned)

    var accent := Polygon2D.new()
    var strip_w := minf(size.x * 0.55, 16.0)
    accent.polygon = PackedVector2Array([
        Vector2(-strip_w / 2.0, -size.y / 2.0 + 7.0),
        Vector2(strip_w / 2.0, -size.y / 2.0 + 7.0),
        Vector2(strip_w / 2.0, -size.y / 2.0 + 12.0),
        Vector2(-strip_w / 2.0, -size.y / 2.0 + 12.0)
    ])
    accent.color = Color(V7_RED.r, V7_RED.g, V7_RED.b, 0.52)
    area.add_child(accent)
    return area

func _marker(pos: Vector2, color: Color, text: String) -> void:
    var panel := Polygon2D.new()
    panel.position = pos
    panel.polygon = PackedVector2Array([
        Vector2(-52, -28), Vector2(52, -28), Vector2(52, 28), Vector2(-52, 28)
    ])
    panel.color = color.lerp(V7_SOFT, 0.58)
    panel.z_index = -1
    world.add_child(panel)

    var border := Line2D.new()
    border.position = pos
    border.width = 2.0
    border.default_color = Color(V7_SLATE.r, V7_SLATE.g, V7_SLATE.b, 0.35)
    border.closed = true
    border.points = PackedVector2Array([
        Vector2(-52, -28), Vector2(52, -28), Vector2(52, 28), Vector2(-52, 28)
    ])
    world.add_child(border)

    _text(pos + Vector2(-42, -14), text, 17, V7_SLATE)

func _text(pos: Vector2, text: String, size: int, color: Color) -> void:
    var cleaned := text
    match text:
        "BURADA GERÇEKTEN HİÇBİR ŞEY YOK.":
            cleaned = "YOL AÇIK."
        "BU PLATFORM GERÇEKTEN NORMAL.":
            cleaned = "DEVAM."
        "BOŞLUK NORMAL. SANIRIM.":
            cleaned = "İLERİ."
        "BURADA GERÇEKTEN HİÇBİR ŞEY YOK":
            cleaned = "DEVAM."
        "HAREKET EDEN PLATFORM GÜVENLİ DEMEK DEĞİL.":
            cleaned = "TEMPOYU KORU."
    super._text(pos, cleaned, size, color)

func _finish(pos: Vector2) -> Area2D:
    var area := super._finish(pos)

    var glow := Polygon2D.new()
    glow.polygon = PackedVector2Array([
        Vector2(-52, -72), Vector2(52, -72), Vector2(52, 72), Vector2(-52, 72)
    ])
    glow.color = Color(0.13, 0.77, 0.36, 0.07)
    glow.z_index = -3
    area.add_child(glow)
    return area

func _boulder(pos: Vector2, speed: float, radius: float) -> void:
    var area := Area2D.new()
    area.position = pos
    area.collision_layer = 2
    area.collision_mask = 1

    var cs := CollisionShape2D.new()
    var shape := CircleShape2D.new()
    shape.radius = radius
    cs.shape = shape
    area.add_child(cs)

    var shadow := Polygon2D.new()
    shadow.position = Vector2(8, 10)
    shadow.polygon = _circle_points(radius * 1.02, 32)
    shadow.color = Color(0.02, 0.03, 0.05, 0.22)
    shadow.z_index = -2
    area.add_child(shadow)

    var rock := Polygon2D.new()
    rock.polygon = _circle_points(radius, 32)
    rock.color = Color("#4b5563")
    area.add_child(rock)

    var inner := Polygon2D.new()
    inner.position = Vector2(-radius * 0.17, -radius * 0.18)
    inner.polygon = _circle_points(radius * 0.58, 26)
    inner.color = Color(0.15, 0.18, 0.23, 0.32)
    area.add_child(inner)

    var ring := Line2D.new()
    ring.width = maxf(3.0, radius * 0.055)
    ring.default_color = Color(0.76, 0.82, 0.89, 0.30)
    ring.closed = true
    ring.points = _circle_points(radius * 0.78, 28)
    area.add_child(ring)

    for angle in [-0.5, 1.4, 3.0]:
        var crack := Line2D.new()
        crack.width = 3.0
        crack.default_color = Color(0.04, 0.06, 0.09, 0.48)
        crack.points = PackedVector2Array([
            Vector2.ZERO,
            Vector2(cos(angle), sin(angle)) * radius * 0.36,
            Vector2(cos(angle + 0.35), sin(angle + 0.35)) * radius * 0.62
        ])
        area.add_child(crack)

    area.body_entered.connect(func(body):
        if body == player and player.alive:
            player.die()
    )
    world.add_child(area)

    _play_tone(82.0, 0.20, 0.18)

    var direction := signf(speed)
    var adjusted_speed := minf(absf(speed) * 0.66, 330.0)
    adjusted_speed = maxf(adjusted_speed, 255.0)
    var travel := 1500.0
    var duration := travel / adjusted_speed

    var tw := create_tween()
    tw.tween_interval(0.14)
    tw.set_parallel(true)
    tw.tween_property(area, "position:x", pos.x + direction * travel, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    tw.tween_property(rock, "rotation", direction * TAU * 6.0, duration)
    tw.tween_property(inner, "rotation", direction * TAU * 4.5, duration)
    tw.set_parallel(false)
    tw.tween_callback(area.queue_free)

func _falling_boulder(pos: Vector2, radius: float, delay: float) -> Area2D:
    var area := Area2D.new()
    area.position = pos
    area.collision_layer = 2
    area.collision_mask = 1

    var cs := CollisionShape2D.new()
    var shape := CircleShape2D.new()
    shape.radius = radius
    cs.shape = shape
    area.add_child(cs)

    var shadow := Polygon2D.new()
    shadow.position = Vector2(6, 8)
    shadow.polygon = _circle_points(radius, 28)
    shadow.color = Color(0.02, 0.03, 0.05, 0.20)
    shadow.z_index = -2
    area.add_child(shadow)

    var rock := Polygon2D.new()
    rock.polygon = _circle_points(radius, 30)
    rock.color = Color("#525b69")
    area.add_child(rock)

    var ring := Line2D.new()
    ring.width = maxf(2.0, radius * 0.045)
    ring.default_color = Color(0.78, 0.84, 0.90, 0.25)
    ring.closed = true
    ring.points = _circle_points(radius * 0.73, 24)
    area.add_child(ring)

    area.body_entered.connect(func(body):
        if body == player and player.alive:
            player.die()
    )
    world.add_child(area)

    var tw := create_tween()
    tw.tween_interval(delay + 0.08)
    tw.set_parallel(true)
    tw.tween_property(area, "position:y", 820.0, 0.88).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    tw.tween_property(rock, "rotation", TAU * 2.2, 0.88)
    tw.set_parallel(false)
    tw.tween_callback(area.queue_free)
    return area

func _circle_points(radius: float, segments: int) -> PackedVector2Array:
    var points := PackedVector2Array()
    for i in range(segments):
        var a := TAU * float(i) / float(segments)
        points.append(Vector2(cos(a), sin(a)) * radius)
    return points

func _add_environment_polish() -> void:
    if not is_instance_valid(world):
        return

    var horizon := Polygon2D.new()
    horizon.position = Vector2(level_width / 2.0, 430)
    horizon.polygon = PackedVector2Array([
        Vector2(-level_width / 2.0, -85),
        Vector2(level_width / 2.0, -85),
        Vector2(level_width / 2.0, 110),
        Vector2(-level_width / 2.0, 110)
    ])
    horizon.color = Color(0.38, 0.52, 0.65, 0.045)
    horizon.z_index = -40
    world.add_child(horizon)

    var skyline_step := 420
    var count := int(level_width / float(skyline_step)) + 2
    for i in range(count):
        var h := 55.0 + float((i * 37 + chapter * 19 + part * 11) % 95)
        var w := 80.0 + float((i * 29 + part * 23) % 75)
        var block := Polygon2D.new()
        block.position = Vector2(150 + i * skyline_step, 530 - h / 2.0)
        block.polygon = PackedVector2Array([
            Vector2(-w / 2.0, -h / 2.0), Vector2(w / 2.0, -h / 2.0),
            Vector2(w / 2.0, h / 2.0), Vector2(-w / 2.0, h / 2.0)
        ])
        block.color = Color(0.18, 0.27, 0.38, 0.055)
        block.z_index = -35
        world.add_child(block)

    for i in range(4):
        var x := 620.0 + float(i) * maxf(620.0, (level_width - 1100.0) / 4.0)
        if x > level_width - 280.0:
            continue
        var plate := Polygon2D.new()
        plate.position = Vector2(x, 623)
        plate.polygon = PackedVector2Array([
            Vector2(-46, -4), Vector2(46, -4), Vector2(46, 4), Vector2(-46, 4)
        ])
        plate.color = Color(0.08, 0.14, 0.22, 0.16)
        plate.z_index = 1
        world.add_child(plate)

        var bolt_l := Polygon2D.new()
        bolt_l.position = Vector2(x - 31, 623)
        bolt_l.polygon = _circle_points(3.0, 10)
        bolt_l.color = Color(0.55, 0.65, 0.75, 0.38)
        bolt_l.z_index = 2
        world.add_child(bolt_l)

        var bolt_r := Polygon2D.new()
        bolt_r.position = Vector2(x + 31, 623)
        bolt_r.polygon = _circle_points(3.0, 10)
        bolt_r.color = Color(0.55, 0.65, 0.75, 0.38)
        bolt_r.z_index = 2
        world.add_child(bolt_r)
