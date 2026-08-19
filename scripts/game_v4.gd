extends "res://scripts/game_v3.gd"

const V4_BG := Color("#f3f4f6")
const V4_BG_CH4 := Color("#f1e8df")
const V4_INK := Color("#111827")
const V4_RED := Color("#ef4444")
const V4_RED_DARK := Color("#7f1d1d")
const V4_GREEN := Color("#22c55e")
const V4_YELLOW := Color("#f59e0b")
const V4_BLUE := Color("#3b82f6")
const V4_PURPLE := Color("#8b5cf6")
const V4_MUTED := Color("#6b7280")

func _start_level(c: int, p: int) -> void:
    super._start_level(c, p)
    if c == 4:
        RenderingServer.set_default_clear_color(V4_BG_CH4)

func _build_level(c: int, p: int) -> void:
    if c == 4 and p == 1:
        _level_4_1()
    elif c == 4 and p == 2:
        _level_4_2()
    elif c == 4 and p == 3:
        _level_4_3()
    else:
        super._build_level(c, p)

func _show_main_menu() -> void:
    RenderingServer.set_default_clear_color(V4_BG)
    if is_instance_valid(world):
        world.queue_free()
    world = null
    if is_instance_valid(hud):
        hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)
    camera = null

    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V4_BG
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(bg)

    var top_band := ColorRect.new()
    top_band.size = Vector2(1280, 92)
    top_band.color = V4_INK
    top_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(top_band)

    var version := Label.new()
    version.position = Vector2(24, 27)
    version.size = Vector2(250, 40)
    version.text = "ANDROID • v0.5"
    version.add_theme_font_size_override("font_size", 18)
    version.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(version)

    var title := Label.new()
    title.position = Vector2(180, 125)
    title.size = Vector2(920, 95)
    title.text = "TROLL PARKOUR"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 58)
    title.add_theme_color_override("font_color", V4_INK)
    hud.add_child(title)

    var subtitle := Label.new()
    subtitle.position = Vector2(220, 210)
    subtitle.size = Vector2(840, 55)
    subtitle.text = "Ezberlediğini sandığın anda oyun fikrini değiştirir."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 23)
    subtitle.add_theme_color_override("font_color", V4_MUTED)
    hud.add_child(subtitle)

    var progress := Label.new()
    progress.position = Vector2(300, 280)
    progress.size = Vector2(680, 44)
    var available := maxi(1, mini(unlocked_chapter, 4))
    var completed_maps := maxi(0, (mini(unlocked_chapter, 5) - 1) * 3)
    progress.text = "AÇIK BÖLÜM: %d / 4     HARİTA: %d / 12     ÖLÜM: %d" % [available, completed_maps, deaths]
    progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    progress.add_theme_font_size_override("font_size", 19)
    progress.add_theme_color_override("font_color", V4_RED_DARK)
    hud.add_child(progress)

    _menu_button("DEVAM ET", Vector2(440, 355), Vector2(400, 72), func():
        _start_level(maxi(1, mini(unlocked_chapter, 4)), 1)
    )
    _menu_button("BÖLÜMLER", Vector2(440, 445), Vector2(400, 72), func():
        _show_chapter_select()
    )
    _menu_button("1. BÖLÜMDEN BAŞLA", Vector2(440, 535), Vector2(400, 72), func():
        _start_level(1, 1)
    )

    var warning := Label.new()
    warning.position = Vector2(260, 635)
    warning.size = Vector2(760, 40)
    warning.text = "İpucu: Bazen en şüpheli yer gerçekten güvenlidir."
    warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    warning.add_theme_font_size_override("font_size", 18)
    warning.add_theme_color_override("font_color", V4_MUTED)
    hud.add_child(warning)

func _show_chapter_select() -> void:
    if is_instance_valid(hud):
        hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)

    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V4_BG
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(240, 85)
    title.size = Vector2(800, 80)
    title.text = "BÖLÜM SEÇ"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 46)
    title.add_theme_color_override("font_color", V4_INK)
    hud.add_child(title)

    var info := Label.new()
    info.position = Vector2(290, 160)
    info.size = Vector2(700, 45)
    info.text = "Her bölüm 3 kısa haritadan oluşur."
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.add_theme_font_size_override("font_size", 19)
    info.add_theme_color_override("font_color", V4_MUTED)
    hud.add_child(info)

    for i in range(1, 5):
        var chapter_id := i
        var is_unlocked := chapter_id <= unlocked_chapter
        var col := (i - 1) % 2
        var row := int((i - 1) / 2)
        var pos := Vector2(250 + col * 410, 235 + row * 120)
        var button_text := "BÖLÜM %d\n3 HARİTA" % chapter_id if is_unlocked else "BÖLÜM %d\nKİLİTLİ" % chapter_id
        var button := _menu_button(button_text, pos, Vector2(370, 92), func():
            _start_level(chapter_id, 1)
        )
        button.disabled = not is_unlocked

    _menu_button("GERİ", Vector2(490, 525), Vector2(300, 68), func():
        _show_main_menu()
    )

func _show_chapter_result() -> void:
    if is_instance_valid(world):
        world.queue_free()
    world = null
    if is_instance_valid(hud):
        hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)

    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V4_INK
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(190, 115)
    title.size = Vector2(900, 280)
    var map_count := mini(chapter * 3, 12)
    title.text = "BÖLÜM %d TAMAMLANDI\n\nTOPLAM ÖLÜM: %d\nTAMAMLANAN HARİTA: %d / 12" % [chapter, deaths, map_count]
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(title)

    if chapter < 4:
        var next_chapter := chapter + 1
        _menu_button("SONRAKİ BÖLÜM", Vector2(440, 430), Vector2(400, 72), func():
            _start_level(next_chapter, 1)
        )
    else:
        var done := Label.new()
        done.position = Vector2(280, 405)
        done.size = Vector2(720, 70)
        done.text = "12 HARİTA TAMAM — OYUN DAHA YENİ ISINIYOR."
        done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        done.add_theme_font_size_override("font_size", 23)
        done.add_theme_color_override("font_color", V4_YELLOW)
        hud.add_child(done)

    _menu_button("ANA MENÜ", Vector2(490, 540), Vector2(300, 68), func():
        _show_main_menu()
    )

func _floor_with_gaps(width: float, gaps: Array[Vector2]) -> void:
    level_width = width
    var cursor := 0.0
    for gap in gaps:
        var gap_start := gap.x
        var gap_end := gap.y
        if gap_start > cursor:
            var segment_width := gap_start - cursor
            _platform(Vector2(cursor + segment_width / 2.0, 675), Vector2(segment_width, 90), V4_INK)
        cursor = gap_end
    if cursor < width:
        var tail_width := width - cursor
        _platform(Vector2(cursor + tail_width / 2.0, 675), Vector2(tail_width, 90), V4_INK)

func _hidden_hazard(pos: Vector2, size: Vector2, color: Color = V4_RED) -> Area2D:
    var area := Area2D.new()
    area.position = pos
    area.collision_layer = 2
    area.collision_mask = 1

    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = size
    cs.shape = shape
    cs.disabled = true
    area.add_child(cs)

    var poly := Polygon2D.new()
    poly.polygon = PackedVector2Array([
        Vector2(-size.x / 2.0, -size.y / 2.0),
        Vector2(size.x / 2.0, -size.y / 2.0),
        Vector2(size.x / 2.0, size.y / 2.0),
        Vector2(-size.x / 2.0, size.y / 2.0)
    ])
    poly.color = color
    poly.visible = false
    area.add_child(poly)

    area.body_entered.connect(func(body):
        if body == player and player.alive:
            player.die()
    )
    world.add_child(area)
    return area

func _troll_popup(text: String, color: Color = V4_RED_DARK) -> void:
    if not is_instance_valid(hud):
        return
    var label := Label.new()
    label.position = Vector2(340, 135)
    label.size = Vector2(600, 90)
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 32)
    label.add_theme_color_override("font_color", color)
    hud.add_child(label)
    var tw := create_tween()
    tw.tween_interval(0.55)
    tw.tween_property(label, "modulate:a", 0.0, 0.38)
    tw.tween_callback(label.queue_free)

func _teleport_troll(rect: Rect2, target: Vector2, key: String, message: String) -> void:
    _trigger(rect, func():
        if _once(key):
            player.velocity = Vector2.ZERO
            player.set_deferred("global_position", target)
            _play_tone(310.0, 0.16, 0.22)
            Input.vibrate_handheld(45)
            _troll_popup(message)
    )

func _level_4_1() -> void:
    _floor_with_gaps(4500, [Vector2(2860, 3010)])
    _text(Vector2(120, 470), "BÖLÜM 4: ARTIK ZEMİN BİLE SÖZÜNÜ TUTMUYOR.", 24, V4_MUTED)
    _text(Vector2(420, 525), "BURADA GERÇEKTEN HİÇBİR ŞEY YOK.", 19, V4_GREEN)

    _teleport_troll(Rect2(760, 390, 120, 240), Vector2(430, 560), "41_teleport", "BİR DAHA GEL :D")

    var first := _spikes(Vector2(1250, 612), 3, true)
    _trigger(Rect2(1030, 390, 120, 240), func():
        if _once("41_first"):
            _reveal(first)
    )

    var drop := _platform(Vector2(1710, 555), Vector2(190, 26), V4_BLUE)
    _trigger(Rect2(1510, 390, 120, 240), func():
        if _once("41_drop"):
            var tw := create_tween()
            tw.tween_interval(0.16)
            tw.tween_property(drop, "position:y", 830.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    )

    var laser := _hidden_hazard(Vector2(2360, 545), Vector2(360, 26), V4_RED)
    _trigger(Rect2(2050, 390, 120, 240), func():
        if _once("41_laser"):
            var tw := create_tween()
            tw.tween_interval(0.22)
            tw.tween_callback(func(): _reveal(laser))
            tw.tween_interval(0.46)
            tw.tween_callback(func(): _hide(laser))
    )

    _text(Vector2(2750, 520), "BOŞLUK NORMAL. SANIRIM.", 19, V4_MUTED)

    _trigger(Rect2(3220, 390, 120, 240), func():
        if _once("41_rock"):
            _boulder(Vector2(3770, 560), -500.0, 76.0)
    )

    _spikes(Vector2(3730, 612), 3, false)
    var goal := _finish(Vector2(4210, 580))
    _trigger(Rect2(3940, 390, 120, 240), func():
        if _once("41_goal"):
            create_tween().tween_property(goal, "position:y", 455.0, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

func _level_4_2() -> void:
    _floor_with_gaps(5000, [Vector2(1850, 1990), Vector2(3170, 3330)])
    _text(Vector2(120, 470), "BU SEFER OYUN BAZEN YARDIM DA EDEBİLİR.", 24, V4_MUTED)

    _teleport_troll(Rect2(720, 390, 120, 240), Vector2(1280, 560), "42_help", "BU SEFER YARDIM ETTİM")

    _marker(Vector2(1580, 555), V4_YELLOW, "SAKIN")
    _spring_pad(Vector2(1580, 620), -960.0, V4_YELLOW)
    _spikes(Vector2(1620, 285), 3, false, true)

    var left_gate := _hazard_block(Vector2(2350, 430), Vector2(58, 280), V4_RED_DARK)
    var right_gate := _hazard_block(Vector2(2720, 430), Vector2(58, 280), V4_RED_DARK)
    _trigger(Rect2(2100, 390, 120, 240), func():
        if _once("42_gate"):
            var a := create_tween()
            a.tween_property(left_gate, "position:x", 2470.0, 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            a.tween_interval(0.18)
            a.tween_property(left_gate, "position:x", 2350.0, 0.44)
            var b := create_tween()
            b.tween_property(right_gate, "position:x", 2600.0, 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            b.tween_interval(0.18)
            b.tween_property(right_gate, "position:x", 2720.0, 0.44)
    )

    _trigger(Rect2(2820, 390, 120, 240), func():
        if _once("42_rain"):
            _falling_boulder(Vector2(3000, 10), 64.0, 0.0)
            _falling_boulder(Vector2(3450, -20), 56.0, 0.42)
    )

    var slide := _spikes(Vector2(3770, 612), 3, false)
    _trigger(Rect2(3490, 390, 120, 240), func():
        if _once("42_slide"):
            create_tween().tween_property(slide, "position:x", 3520.0, 0.52).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    )

    _marker(Vector2(4180, 555), V4_GREEN, "FINISH")
    var fake := _spikes(Vector2(4180, 612), 3, true)
    _trigger(Rect2(3980, 390, 120, 240), func():
        if _once("42_fake"):
            _reveal(fake)
            _troll_popup("O KADAR KOLAY DEĞİL")
    )

    _finish(Vector2(4700, 580))

func _level_4_3() -> void:
    _floor_with_gaps(5700, [Vector2(1410, 1550), Vector2(3610, 3770), Vector2(4740, 4900)])
    _text(Vector2(120, 470), "SON KISIM: KOŞ, DUR, ŞÜPHELEN, TEKRAR KOŞ.", 24, V4_MUTED)

    var chase := _hazard_block(Vector2(280, 500), Vector2(86, 300), V4_RED_DARK)
    _trigger(Rect2(430, 390, 120, 240), func():
        if _once("43_chase"):
            create_tween().tween_property(chase, "position:x", 4050.0, 9.2).set_trans(Tween.TRANS_LINEAR)
    )

    _text(Vector2(800, 520), "BU PLATFORM GERÇEKTEN NORMAL.", 18, V4_GREEN)
    _platform(Vector2(1040, 540), Vector2(190, 24), V4_BLUE)

    var pop1 := _spikes(Vector2(1900, 612), 3, true)
    var pop2 := _spikes(Vector2(2260, 612), 3, true)
    _trigger(Rect2(1710, 390, 120, 240), func():
        if _once("43_chain"):
            _reveal(pop1)
            var tw := create_tween()
            tw.tween_interval(0.46)
            tw.tween_callback(func(): _hide(pop1))
            tw.tween_callback(func(): _reveal(pop2))
    )

    _teleport_troll(Rect2(2580, 390, 120, 240), Vector2(2290, 560), "43_back", "BİRAZ GERİ")

    _trigger(Rect2(2940, 390, 120, 240), func():
        if _once("43_rocks"):
            _falling_boulder(Vector2(3170, 20), 70.0, 0.0)
            _falling_boulder(Vector2(3410, -10), 60.0, 0.32)
            _falling_boulder(Vector2(3900, -30), 54.0, 0.68)
    )

    var laser := _hidden_hazard(Vector2(4290, 545), Vector2(330, 26), V4_RED)
    _trigger(Rect2(4020, 390, 120, 240), func():
        if _once("43_laser"):
            var tw := create_tween()
            tw.tween_interval(0.18)
            tw.tween_callback(func(): _reveal(laser))
            tw.tween_interval(0.40)
            tw.tween_callback(func(): _hide(laser))
    )

    var last := _spikes(Vector2(5150, 612), 3, true)
    _trigger(Rect2(4960, 390, 120, 240), func():
        if _once("43_last"):
            _reveal(last)
            var tw := create_tween()
            tw.tween_interval(0.34)
            tw.tween_callback(func(): _hide(last))
    )

    var goal := _finish(Vector2(5450, 580))
    _trigger(Rect2(5250, 390, 110, 240), func():
        if _once("43_goal"):
            var tw := create_tween()
            tw.tween_property(goal, "position:x", 5580.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
            tw.tween_interval(0.45)
            tw.tween_property(goal, "position:x", 5450.0, 0.32)
    )
