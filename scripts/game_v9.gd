extends "res://scripts/game_v8.gd"

const V9_BG := Color("#edf1f6")
const V9_BG_CH7 := Color("#e3eaf2")
const V9_INK := Color("#111827")
const V9_SLATE := Color("#475569")
const V9_MUTED := Color("#64748b")
const V9_BLUE := Color("#3b82f6")
const V9_CYAN := Color("#0891b2")
const V9_GREEN := Color("#22c55e")
const V9_YELLOW := Color("#f59e0b")
const V9_RED := Color("#dc4455")
const V9_RED_DARK := Color("#7f2937")

func _start_level(c: int, p: int) -> void:
    super._start_level(c, p)
    if c == 7:
        RenderingServer.set_default_clear_color(V9_BG_CH7)
        _add_chapter7_decor()

func _build_level(c: int, p: int) -> void:
    if c == 7 and p == 1:
        _level_7_1()
    elif c == 7 and p == 2:
        _level_7_2()
    elif c == 7 and p == 3:
        _level_7_3()
    else:
        super._build_level(c, p)

func _build_hud() -> void:
    super._build_hud()
    if chapter == 7:
        var mode := Label.new()
        mode.position = Vector2(735, 19)
        mode.size = Vector2(245, 36)
        mode.text = "GÜVEN TESTİ"
        mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        mode.add_theme_font_size_override("font_size", 16)
        mode.add_theme_color_override("font_color", V9_CYAN)
        hud.add_child(mode)

func _show_main_menu() -> void:
    RenderingServer.set_default_clear_color(V9_BG)
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
    bg.color = V9_BG
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(bg)

    var top_band := ColorRect.new()
    top_band.size = Vector2(1280, 92)
    top_band.color = V9_INK
    top_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(top_band)

    var version := Label.new()
    version.position = Vector2(24, 27)
    version.size = Vector2(250, 40)
    version.text = "ANDROID • v0.9"
    version.add_theme_font_size_override("font_size", 18)
    version.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(version)

    var title := Label.new()
    title.position = Vector2(180, 122)
    title.size = Vector2(920, 95)
    title.text = "TROLL PARKOUR"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 58)
    title.add_theme_color_override("font_color", V9_INK)
    hud.add_child(title)

    var subtitle := Label.new()
    subtitle.position = Vector2(220, 208)
    subtitle.size = Vector2(840, 55)
    subtitle.text = "Bölüm 7: Şüpheli görünen şey bazen sadece şüpheli görünür."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 22)
    subtitle.add_theme_color_override("font_color", V9_MUTED)
    hud.add_child(subtitle)

    var progress := Label.new()
    progress.position = Vector2(285, 278)
    progress.size = Vector2(710, 44)
    var available := maxi(1, mini(unlocked_chapter, 7))
    var completed_maps := maxi(0, (mini(unlocked_chapter, 8) - 1) * 3)
    progress.text = "AÇIK BÖLÜM: %d / 7     HARİTA: %d / 21     ÖLÜM: %d" % [available, completed_maps, deaths]
    progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    progress.add_theme_font_size_override("font_size", 19)
    progress.add_theme_color_override("font_color", V9_RED_DARK)
    hud.add_child(progress)

    _menu_button("DEVAM ET", Vector2(440, 350), Vector2(400, 72), func():
        _start_level(maxi(1, mini(unlocked_chapter, 7)), 1)
    )
    _menu_button("BÖLÜMLER", Vector2(440, 440), Vector2(400, 72), func():
        _show_chapter_select()
    )
    _menu_button("1. BÖLÜMDEN BAŞLA", Vector2(440, 530), Vector2(400, 72), func():
        _start_level(1, 1)
    )

    var warning := Label.new()
    warning.position = Vector2(235, 630)
    warning.size = Vector2(810, 40)
    warning.text = "İpucu: Oyun artık senin şüphelenmeni de kullanıyor."
    warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    warning.add_theme_font_size_override("font_size", 18)
    warning.add_theme_color_override("font_color", V9_MUTED)
    hud.add_child(warning)

    _polish_menu_surface()

func _show_chapter_select() -> void:
    RenderingServer.set_default_clear_color(V9_BG)
    if is_instance_valid(hud):
        hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)

    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V9_BG
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(240, 32)
    title.size = Vector2(800, 72)
    title.text = "BÖLÜM SEÇ"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 44)
    title.add_theme_color_override("font_color", V9_INK)
    hud.add_child(title)

    var info := Label.new()
    info.position = Vector2(180, 99)
    info.size = Vector2(920, 42)
    info.text = "7 bölüm • 21 harita • Hafıza + hareket + güven testleri"
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.add_theme_font_size_override("font_size", 19)
    info.add_theme_color_override("font_color", V9_MUTED)
    hud.add_child(info)

    for i in range(1, 8):
        var chapter_id := i
        var is_unlocked := chapter_id <= unlocked_chapter
        var col := (i - 1) % 3
        var row := int((i - 1) / 3)
        var pos := Vector2(105 + col * 355, 165 + row * 112)
        var suffix := "3 HARİTA"
        if chapter_id == 5:
            suffix = "HAFIZA • 3 HARİTA"
        elif chapter_id == 6:
            suffix = "HAREKET • 3 HARİTA"
        elif chapter_id == 7:
            suffix = "GÜVEN • 3 HARİTA"
        var button_text := "BÖLÜM %d\n%s" % [chapter_id, suffix] if is_unlocked else "BÖLÜM %d\nKİLİTLİ" % chapter_id
        var button := _menu_button(button_text, pos, Vector2(320, 84), func():
            _start_level(chapter_id, 1)
        )
        button.disabled = not is_unlocked

    _menu_button("GERİ", Vector2(490, 535), Vector2(300, 66), func():
        _show_main_menu()
    )
    _polish_menu_surface()

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
    bg.color = V9_INK
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(190, 105)
    title.size = Vector2(900, 290)
    var map_count := mini(chapter * 3, 21)
    title.text = "BÖLÜM %d TAMAMLANDI\n\nTOPLAM ÖLÜM: %d\nTAMAMLANAN HARİTA: %d / 21" % [chapter, deaths, map_count]
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(title)

    if chapter < 7:
        var next_chapter := chapter + 1
        _menu_button("SONRAKİ BÖLÜM", Vector2(440, 430), Vector2(400, 72), func():
            _start_level(next_chapter, 1)
        )
    else:
        var done := Label.new()
        done.position = Vector2(245, 400)
        done.size = Vector2(790, 90)
        done.text = "21 HARİTA TAMAM\nARTIK ŞÜPHELENMEK DE TEK BAŞINA YETMİYOR."
        done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        done.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        done.add_theme_font_size_override("font_size", 22)
        done.add_theme_color_override("font_color", V9_YELLOW)
        hud.add_child(done)

    _menu_button("ANA MENÜ", Vector2(490, 545), Vector2(300, 68), func():
        _show_main_menu()
    )

func _add_chapter7_decor() -> void:
    if not is_instance_valid(world):
        return
    for i in range(12):
        var pillar := Polygon2D.new()
        var x := 260.0 + float(i) * 470.0
        var h := 90.0 + float((i * 37) % 130)
        pillar.position = Vector2(x, 390.0 - h / 2.0)
        pillar.polygon = PackedVector2Array([
            Vector2(-30, -h / 2.0), Vector2(30, -h / 2.0), Vector2(30, h / 2.0), Vector2(-30, h / 2.0)
        ])
        pillar.color = Color(0.18, 0.28, 0.40, 0.055)
        pillar.z_index = -20
        world.add_child(pillar)

    var horizon := Line2D.new()
    horizon.width = 2.0
    horizon.default_color = Color(0.18, 0.35, 0.50, 0.10)
    horizon.points = PackedVector2Array([Vector2(0, 420), Vector2(level_width, 420)])
    horizon.z_index = -19
    world.add_child(horizon)

func _decor_block(pos: Vector2, size: Vector2) -> void:
    var body := Polygon2D.new()
    body.position = pos
    body.polygon = PackedVector2Array([
        Vector2(-size.x / 2.0, -size.y / 2.0),
        Vector2(size.x / 2.0, -size.y / 2.0),
        Vector2(size.x / 2.0, size.y / 2.0),
        Vector2(-size.x / 2.0, size.y / 2.0)
    ])
    body.color = Color(0.24, 0.31, 0.40, 0.22)
    body.z_index = -3
    world.add_child(body)

    var edge := Line2D.new()
    edge.position = pos
    edge.width = 2.0
    edge.default_color = Color(0.40, 0.52, 0.64, 0.24)
    edge.closed = true
    edge.points = PackedVector2Array([
        Vector2(-size.x / 2.0, -size.y / 2.0),
        Vector2(size.x / 2.0, -size.y / 2.0),
        Vector2(size.x / 2.0, size.y / 2.0),
        Vector2(-size.x / 2.0, size.y / 2.0)
    ])
    edge.z_index = -2
    world.add_child(edge)

func _false_alarm() -> void:
    if is_instance_valid(camera):
        var tw := create_tween()
        tw.tween_property(camera, "offset", Vector2(7, -3), 0.07)
        tw.tween_property(camera, "offset", Vector2(-5, 2), 0.07)
        tw.tween_property(camera, "offset", Vector2.ZERO, 0.11)
    _play_tone(245.0, 0.06, 0.10)

func _level_7_1() -> void:
    _floor_with_gaps(5400, [Vector2(1480, 1635), Vector2(3760, 3905)])
    _text(Vector2(120, 470), "BÖLÜM 7: ŞÜPHELENMEK YETMEZ.", 23, V9_CYAN)
    _text(Vector2(410, 520), "BAZEN HİÇBİR ŞEY OLMAZ.", 18, V9_MUTED)

    _decor_block(Vector2(620, 360), Vector2(130, 180))
    _decor_block(Vector2(790, 330), Vector2(75, 120))

    var first := _spikes(Vector2(1080, 612), 3, true)
    _trigger(Rect2(860, 390, 120, 240), func():
        if _once("71_plain_spikes"):
            var tw := create_tween()
            tw.tween_interval(0.18)
            tw.tween_callback(func(): _reveal(first))
    )

    _moving_platform(Vector2(1550, 560), Vector2(155, 24), Vector2(1585, 475), 1.35, V9_BLUE)

    var harmless := _platform(Vector2(2110, 550), Vector2(190, 26), V9_SLATE)
    _trigger(Rect2(1880, 390, 120, 240), func():
        if _once("71_harmless"):
            _false_alarm()
            create_tween().tween_property(harmless, "position:y", 545.0, 0.12)
    )

    var sweep := _hidden_hazard(Vector2(2730, 545), Vector2(300, 24), V9_RED)
    _trigger(Rect2(2420, 390, 120, 240), func():
        if _once("71_sweep"):
            var tw := create_tween()
            tw.tween_interval(0.30)
            tw.tween_callback(func(): _reveal(sweep))
            tw.tween_interval(0.40)
            tw.tween_callback(func(): _hide(sweep))
    )

    _decor_block(Vector2(3210, 350), Vector2(90, 210))
    _trigger(Rect2(3070, 390, 120, 240), func():
        if _once("71_false_alarm"):
            _false_alarm()
    )

    _spikes(Vector2(3490, 612), 2, false)

    _trigger(Rect2(4140, 390, 120, 240), func():
        if _once("71_rock"):
            _boulder(Vector2(4700, 560), -420.0, 74.0)
    )

    _finish(Vector2(5140, 580))

func _level_7_2() -> void:
    _floor_with_gaps(5900, [Vector2(930, 1090), Vector2(2460, 2590), Vector2(4550, 4690)])
    _text(Vector2(120, 470), "AYNI GÖRÜNEN İKİ ŞEY AYNI DAVRANMAYABİLİR.", 22, V9_CYAN)

    _moving_platform(Vector2(1010, 560), Vector2(150, 24), Vector2(1010, 455), 1.30, V9_BLUE)
    _decor_block(Vector2(1320, 345), Vector2(90, 180))

    _trigger(Rect2(1540, 390, 120, 240), func():
        if _once("72_reverse"):
            _reverse_controls(0.95)
    )

    _platform(Vector2(1960, 545), Vector2(180, 26), V9_SLATE)
    _decor_block(Vector2(2180, 340), Vector2(80, 150))

    var bridge: Array[StaticBody2D] = []
    for i in range(5):
        bridge.append(_platform(Vector2(2760 + i * 145, 560), Vector2(118, 24), V9_BLUE))
    _trigger(Rect2(2650, 390, 120, 240), func():
        if _once("72_bridge"):
            for i in range(bridge.size()):
                if i == 1 or i == 3:
                    var tw := create_tween()
                    tw.tween_interval(0.25 + float(i) * 0.08)
                    tw.tween_property(bridge[i], "position:y", 830.0, 0.46).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    )

    var late := _spikes(Vector2(3690, 612), 3, true)
    _trigger(Rect2(3450, 390, 120, 240), func():
        if _once("72_late"):
            var tw := create_tween()
            tw.tween_interval(0.28)
            tw.tween_callback(func(): _reveal(late))
    )

    var left_gate := _hazard_block(Vector2(4050, 420), Vector2(55, 260), V9_SLATE)
    var right_gate := _hazard_block(Vector2(4390, 420), Vector2(55, 260), V9_SLATE)
    _trigger(Rect2(3840, 390, 120, 240), func():
        if _once("72_gates"):
            var a := create_tween()
            a.tween_property(left_gate, "position:x", 4170.0, 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            a.tween_interval(0.20)
            a.tween_property(left_gate, "position:x", 4050.0, 0.48)
            var b := create_tween()
            b.tween_property(right_gate, "position:x", 4270.0, 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            b.tween_interval(0.20)
            b.tween_property(right_gate, "position:x", 4390.0, 0.48)
    )

    _moving_platform(Vector2(4620, 560), Vector2(145, 24), Vector2(4660, 480), 1.20, V9_BLUE)
    _decor_block(Vector2(5060, 350), Vector2(100, 190))
    _finish(Vector2(5570, 580))

func _level_7_3() -> void:
    _floor_with_gaps(6200, [Vector2(1320, 1470), Vector2(3320, 3470)])
    var a := _attempt(7, 3)
    _text(Vector2(120, 470), "SON TEST: OYUN SENİN ŞÜPHENİ HATIRLIYOR.", 22, V9_CYAN)
    _text(Vector2(430, 520), "DENEME %d", 18, V9_MUTED)

    _decor_block(Vector2(640, 350), Vector2(85, 170))
    _decor_block(Vector2(990, 350), Vector2(85, 170))

    var first := _spikes(Vector2(720, 612), 3, true)
    var second := _spikes(Vector2(1080, 612), 3, true)
    _trigger(Rect2(515, 390, 105, 240), func():
        if _once("73_first_choice"):
            if a % 2 == 0:
                _reveal(first)
            else:
                _false_alarm()
    )
    _trigger(Rect2(870, 390, 105, 240), func():
        if _once("73_second_choice"):
            if a % 2 == 1:
                _reveal(second)
            else:
                _false_alarm()
    )

    _moving_platform(Vector2(1395, 560), Vector2(150, 24), Vector2(1435, 475), 1.25, V9_BLUE)

    var left_gate := _hazard_block(Vector2(2050, 425), Vector2(56, 250), V9_SLATE)
    var right_gate := _hazard_block(Vector2(2390, 425), Vector2(56, 250), V9_SLATE)
    _trigger(Rect2(1820, 390, 120, 240), func():
        if _once("73_gate_memory"):
            if a % 3 == 0:
                var ga := create_tween()
                ga.tween_property(left_gate, "position:x", 2170.0, 0.48)
                ga.tween_interval(0.22)
                ga.tween_property(left_gate, "position:x", 2050.0, 0.48)
                var gb := create_tween()
                gb.tween_property(right_gate, "position:x", 2270.0, 0.48)
                gb.tween_interval(0.22)
                gb.tween_property(right_gate, "position:x", 2390.0, 0.48)
            else:
                _false_alarm()
    )

    _trigger(Rect2(2660, 390, 120, 240), func():
        if _once("73_rock_memory"):
            if a % 2 == 0:
                _boulder(Vector2(3180, 560), -390.0, 70.0)
            else:
                _false_alarm()
    )

    var memory_spikes := _spikes(Vector2(3020, 612), 3, true)
    _trigger(Rect2(2830, 390, 105, 240), func():
        if _once("73_spike_memory") and a % 2 == 1:
            _reveal(memory_spikes)
    )

    _moving_platform(Vector2(3395, 555), Vector2(145, 24), Vector2(3430, 470), 1.25, V9_BLUE)

    _decor_block(Vector2(3890, 345), Vector2(100, 195))
    _trigger(Rect2(3780, 390, 120, 240), func():
        if _once("73_camera_decoy"):
            _false_alarm()
    )

    var last := _spikes(Vector2(4380, 612), 3, true)
    _trigger(Rect2(4140, 390, 120, 240), func():
        if _once("73_last"):
            var tw := create_tween()
            tw.tween_interval(0.22)
            tw.tween_callback(func(): _reveal(last))
            tw.tween_interval(0.42)
            tw.tween_callback(func(): _hide(last))
    )

    _marker(Vector2(4860, 555), V9_GREEN, "ÇIKIŞ")
    _trigger(Rect2(4700, 390, 120, 240), func():
        if _once("73_harmless_exit"):
            _false_alarm()
    )

    _finish(Vector2(5820, 580))
