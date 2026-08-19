extends "res://scripts/game_v11.gd"

const V12_BG := Color("#edf1f6")
const V12_BG_CH10 := Color("#e8e7e2")
const V12_INK := Color("#111827")
const V12_SLATE := Color("#475569")
const V12_MUTED := Color("#64748b")
const V12_BLUE := Color("#2563eb")
const V12_CYAN := Color("#0891b2")
const V12_GREEN := Color("#16a34a")
const V12_GOLD := Color("#d99a19")
const V12_RED := Color("#dc4455")
const V12_RED_DARK := Color("#7f2937")
const V12_PURPLE := Color("#7c3aed")

func _start_level(c: int, p: int) -> void:
    super._start_level(c, p)
    if c == 10:
        RenderingServer.set_default_clear_color(V12_BG_CH10)
        _add_chapter10_decor()

func _build_level(c: int, p: int) -> void:
    if c == 10 and p == 1:
        _level_10_1()
    elif c == 10 and p == 2:
        _level_10_2()
    elif c == 10 and p == 3:
        _level_10_3()
    else:
        super._build_level(c, p)

func _build_hud() -> void:
    super._build_hud()
    if chapter == 10:
        var mode := Label.new()
        mode.position = Vector2(720, 18)
        mode.size = Vector2(275, 38)
        mode.text = "İLK 10 • MİNİ FİNAL"
        mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        mode.add_theme_font_size_override("font_size", 16)
        mode.add_theme_color_override("font_color", V12_GOLD)
        hud.add_child(mode)

func _show_main_menu() -> void:
    RenderingServer.set_default_clear_color(V12_BG)
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
    bg.color = V12_BG
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(bg)

    var top_band := ColorRect.new()
    top_band.size = Vector2(1280, 92)
    top_band.color = V12_INK
    top_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(top_band)

    var version := Label.new()
    version.position = Vector2(24, 27)
    version.size = Vector2(250, 40)
    version.text = "ANDROID • v1.2"
    version.add_theme_font_size_override("font_size", 18)
    version.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(version)

    var title := Label.new()
    title.position = Vector2(180, 120)
    title.size = Vector2(920, 95)
    title.text = "TROLL PARKOUR"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 58)
    title.add_theme_color_override("font_color", V12_INK)
    hud.add_child(title)

    var subtitle := Label.new()
    subtitle.position = Vector2(220, 205)
    subtitle.size = Vector2(840, 55)
    subtitle.text = "İlk 10 bölüm: Oyun şimdi öğrendiğin her şeyi birlikte kullanıyor."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 21)
    subtitle.add_theme_color_override("font_color", V12_MUTED)
    hud.add_child(subtitle)

    var progress := Label.new()
    progress.position = Vector2(275, 276)
    progress.size = Vector2(730, 44)
    var available := maxi(1, mini(unlocked_chapter, 10))
    var completed_maps := maxi(0, (mini(unlocked_chapter, 11) - 1) * 3)
    progress.text = "AÇIK BÖLÜM: %d / 10     HARİTA: %d / 30     ÖLÜM: %d" % [available, completed_maps, deaths]
    progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    progress.add_theme_font_size_override("font_size", 19)
    progress.add_theme_color_override("font_color", V12_RED_DARK)
    hud.add_child(progress)

    _menu_button("DEVAM ET", Vector2(440, 350), Vector2(400, 72), func():
        _start_level(maxi(1, mini(unlocked_chapter, 10)), 1)
    )
    _menu_button("BÖLÜMLER", Vector2(440, 440), Vector2(400, 72), func():
        _show_chapter_select()
    )
    _menu_button("1. BÖLÜMDEN BAŞLA", Vector2(440, 530), Vector2(400, 72), func():
        _start_level(1, 1)
    )

    var warning := Label.new()
    warning.position = Vector2(225, 630)
    warning.size = Vector2(830, 40)
    warning.text = "İpucu: Mini final hızlı değil; dikkat etmediğin kadar acımasız."
    warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    warning.add_theme_font_size_override("font_size", 18)
    warning.add_theme_color_override("font_color", V12_MUTED)
    hud.add_child(warning)
    _polish_menu_surface()

func _show_chapter_select() -> void:
    RenderingServer.set_default_clear_color(V12_BG)
    if is_instance_valid(hud):
        hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)

    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V12_BG
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(240, 32)
    title.size = Vector2(800, 62)
    title.text = "BÖLÜM SEÇ"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 40)
    title.add_theme_color_override("font_color", V12_INK)
    hud.add_child(title)

    var info := Label.new()
    info.position = Vector2(150, 91)
    info.size = Vector2(980, 38)
    info.text = "10 bölüm • 30 harita • İlk büyük parkur eşiği"
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.add_theme_font_size_override("font_size", 18)
    info.add_theme_color_override("font_color", V12_MUTED)
    hud.add_child(info)

    for i in range(1, 11):
        var chapter_id := i
        var is_unlocked := chapter_id <= unlocked_chapter
        var col := (i - 1) % 5
        var row := int((i - 1) / 5)
        var pos := Vector2(55 + col * 240, 165 + row * 125)
        var suffix := "3 HARİTA"
        if chapter_id == 5:
            suffix = "HAFIZA"
        elif chapter_id == 6:
            suffix = "HAREKET"
        elif chapter_id == 7:
            suffix = "GÜVEN"
        elif chapter_id == 8:
            suffix = "ZAMAN"
        elif chapter_id == 9:
            suffix = "ROTA"
        elif chapter_id == 10:
            suffix = "MİNİ FİNAL"
        var button_text := "BÖLÜM %d\n%s" % [chapter_id, suffix] if is_unlocked else "BÖLÜM %d\nKİLİTLİ" % chapter_id
        var button := _menu_button(button_text, pos, Vector2(210, 88), func():
            _start_level(chapter_id, 1)
        )
        button.disabled = not is_unlocked

    var note := Label.new()
    note.position = Vector2(250, 438)
    note.size = Vector2(780, 42)
    note.text = "Bölüm 10 önceki sistemleri tek parkur zincirinde birleştirir."
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    note.add_theme_font_size_override("font_size", 17)
    note.add_theme_color_override("font_color", V12_MUTED)
    hud.add_child(note)

    _menu_button("GERİ", Vector2(490, 515), Vector2(300, 66), func():
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
    bg.color = V12_INK
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(180, 92)
    title.size = Vector2(920, 300)
    var map_count := mini(chapter * 3, 30)
    title.text = "BÖLÜM %d TAMAMLANDI\n\nTOPLAM ÖLÜM: %d\nTAMAMLANAN HARİTA: %d / 30" % [chapter, deaths, map_count]
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(title)

    if chapter < 10:
        var next_chapter := chapter + 1
        _menu_button("SONRAKİ BÖLÜM", Vector2(440, 430), Vector2(400, 72), func():
            _start_level(next_chapter, 1)
        )
    else:
        var milestone := Label.new()
        milestone.position = Vector2(210, 390)
        milestone.size = Vector2(860, 105)
        milestone.text = "İLK 10 BÖLÜM TAMAM\n30 HARİTA GEÇİLDİ — BUNDAN SONRA KURALLAR DAHA AZ GÜVENİLİR."
        milestone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        milestone.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        milestone.add_theme_font_size_override("font_size", 23)
        milestone.add_theme_color_override("font_color", V12_GOLD)
        hud.add_child(milestone)

    _menu_button("ANA MENÜ", Vector2(490, 545), Vector2(300, 68), func():
        _show_main_menu()
    )

func _add_chapter10_decor() -> void:
    if not is_instance_valid(world):
        return
    for i in range(15):
        var x := 220.0 + float(i) * 470.0
        var pillar := Polygon2D.new()
        var h := 65.0 + float((i * 31) % 130)
        pillar.position = Vector2(x, 425.0 - h / 2.0)
        pillar.polygon = PackedVector2Array([
            Vector2(-26, -h / 2.0), Vector2(26, -h / 2.0),
            Vector2(26, h / 2.0), Vector2(-26, h / 2.0)
        ])
        pillar.color = Color(0.42, 0.31, 0.10, 0.05)
        pillar.z_index = -24
        world.add_child(pillar)

    var horizon := Line2D.new()
    horizon.width = 2.0
    horizon.default_color = Color(0.50, 0.34, 0.10, 0.10)
    horizon.points = PackedVector2Array([Vector2(0, 438), Vector2(level_width, 438)])
    horizon.z_index = -23
    world.add_child(horizon)

    for i in range(6):
        var ring := Line2D.new()
        ring.position = Vector2(520 + i * 1080, 315)
        ring.width = 3.0
        ring.default_color = Color(0.65, 0.45, 0.12, 0.07)
        ring.closed = true
        ring.points = _circle_points(48.0 + float(i % 2) * 12.0, 28)
        ring.z_index = -22
        world.add_child(ring)

func _final_notice(text: String) -> void:
    _troll_popup(text, V12_GOLD)
    _play_tone(390.0, 0.09, 0.13)

func _level_10_1() -> void:
    _floor_with_gaps(6200, [Vector2(1510, 1665), Vector2(3820, 3980)])
    _text(Vector2(120, 470), "BÖLÜM 10: İLK SINAV.", 23, V12_GOLD)
    _text(Vector2(410, 520), "ESKİ NUMARALAR AYNI SIRADA GELMEZ.", 18, V12_MUTED)

    var first := _spikes(Vector2(820, 612), 3, true)
    _trigger(Rect2(590, 390, 120, 240), func():
        _timed_hazard(first, 0.34, 0.50, "101_first")
    )

    _decor_block(Vector2(1110, 350), Vector2(90, 190))
    _trigger(Rect2(970, 390, 120, 240), func():
        if _once("101_alarm"):
            _false_alarm()
    )

    _route_hint(Vector2(1370, 500), "ALT")
    _route_hint(Vector2(1370, 390), "ÜST")
    _platform(Vector2(1450, 465), Vector2(190, 24), V12_BLUE)
    _trigger(Rect2(1260, 315, 200, 175), func():
        if _choose_route("upper"):
            _final_notice("ÜST ROTA")
    )
    _trigger(Rect2(1260, 500, 200, 150), func():
        if _choose_route("lower"):
            _final_notice("ALT ROTA")
    )

    _moving_platform(Vector2(1590, 555), Vector2(150, 24), Vector2(1625, 470), 1.42, V12_CYAN)

    var lower_bait := _spikes(Vector2(2070, 612), 3, true)
    _trigger(Rect2(1820, 390, 120, 240), func():
        if _once("101_route_spike") and route_choice == "lower":
            var tw := create_tween()
            tw.tween_interval(0.30)
            tw.tween_callback(func(): _reveal(lower_bait))
            tw.tween_interval(0.48)
            tw.tween_callback(func(): _hide(lower_bait))
    )

    var crusher := _hazard_block(Vector2(2700, 220), Vector2(150, 72), V12_RED_DARK)
    _trigger(Rect2(2420, 390, 120, 240), func():
        if _once("101_crusher"):
            var tw := create_tween()
            tw.tween_interval(0.42)
            tw.tween_property(crusher, "position:y", 520.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_interval(0.20)
            tw.tween_property(crusher, "position:y", 220.0, 0.52).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

    var safe := _platform(Vector2(3210, 548), Vector2(185, 26), V12_SLATE)
    _trigger(Rect2(2960, 390, 120, 240), func():
        if _once("101_safe"):
            _false_alarm()
            create_tween().tween_property(safe, "position:y", 544.0, 0.14)
    )

    _trigger(Rect2(3420, 390, 120, 240), func():
        if _once("101_reverse"):
            controls_reversed = true
            _final_notice("KISA TERS")
            var tw := create_tween()
            tw.tween_interval(0.72)
            tw.tween_callback(func(): controls_reversed = false)
    )

    _moving_platform(Vector2(3900, 555), Vector2(145, 24), Vector2(3940, 472), 1.34, V12_BLUE)

    var last := _spikes(Vector2(4450, 612), 2, true)
    _trigger(Rect2(4190, 390, 120, 240), func():
        _timed_hazard(last, 0.28, 0.44, "101_last")
    )

    _trigger(Rect2(4840, 390, 120, 240), func():
        if _once("101_rock"):
            var tw := create_tween()
            tw.tween_interval(0.36)
            tw.tween_callback(func(): _boulder(Vector2(5480, 560), -390.0, 72.0))
    )

    var goal := _finish(Vector2(5880, 580))
    _trigger(Rect2(5580, 390, 120, 240), func():
        if _once("101_goal") and route_choice == "upper":
            create_tween().tween_property(goal, "position:y", 500.0, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

func _level_10_2() -> void:
    _floor_with_gaps(6650, [Vector2(1940, 2100), Vector2(4720, 4880)])
    var a := _attempt(10, 2)
    _text(Vector2(120, 470), "İKİNCİ SINAV: EZBER YOK.", 23, V12_PURPLE)
    _text(Vector2(410, 520), "DENEME %d — ZAMANLAMA DEĞİŞEBİLİR." % a, 18, V12_MUTED)

    var memory_a := _spikes(Vector2(780, 612), 3, true)
    var memory_b := _spikes(Vector2(1060, 612), 3, true)
    _trigger(Rect2(560, 390, 120, 240), func():
        if _once("102_memory"):
            var target := memory_a if a % 2 == 1 else memory_b
            var tw := create_tween()
            tw.tween_interval(0.30 + float(a % 3) * 0.08)
            tw.tween_callback(func(): _reveal(target))
            tw.tween_interval(0.46)
            tw.tween_callback(func(): _hide(target))
    )

    var suspicious := _platform(Vector2(1420, 548), Vector2(185, 26), V12_RED_DARK.lerp(V12_SLATE, 0.78))
    _trigger(Rect2(1180, 390, 120, 240), func():
        if _once("102_suspicious"):
            _false_alarm()
            create_tween().tween_property(suspicious, "position:x", 1425.0, 0.12)
    )

    _moving_platform(Vector2(2020, 555), Vector2(150, 24), Vector2(2060, 470), 1.40, V12_CYAN)

    _route_hint(Vector2(2460, 500), "KISA")
    _route_hint(Vector2(2460, 390), "UZUN")
    _platform(Vector2(2550, 465), Vector2(230, 24), V12_BLUE)
    _platform(Vector2(2840, 430), Vector2(200, 24), V12_BLUE)
    _trigger(Rect2(2350, 315, 210, 175), func():
        if _choose_route("upper"):
            _false_alarm()
    )
    _trigger(Rect2(2350, 500, 210, 150), func():
        if _choose_route("lower"):
            _final_notice("KISA YOL")
    )

    var gate_a := _hidden_hazard(Vector2(3330, 530), Vector2(28, 230), V12_RED)
    var gate_b := _hidden_hazard(Vector2(3620, 530), Vector2(28, 230), V12_RED)
    _trigger(Rect2(3070, 390, 120, 240), func():
        if _once("102_gates"):
            var first_delay := 0.26 if route_choice == "upper" else 0.42
            var tw := create_tween()
            tw.tween_interval(first_delay)
            tw.tween_callback(func(): _reveal(gate_a))
            tw.tween_interval(0.34)
            tw.tween_callback(func(): _hide(gate_a))
            tw.tween_interval(0.18)
            tw.tween_callback(func(): _reveal(gate_b))
            tw.tween_interval(0.36)
            tw.tween_callback(func(): _hide(gate_b))
    )

    var normal_drop := _platform(Vector2(4090, 548), Vector2(185, 26), V12_SLATE)
    _trigger(Rect2(3850, 390, 120, 240), func():
        if _once("102_drop"):
            _delayed_platform_drop(normal_drop, 0.38 + float(a % 2) * 0.16, 305.0)
    )

    _moving_platform(Vector2(4800, 555), Vector2(145, 24), Vector2(4840, 472), 1.30, V12_BLUE)

    _trigger(Rect2(5120, 390, 120, 240), func():
        if _once("102_fall"):
            _falling_boulder(Vector2(5370, 30), 62.0, 0.0)
            _falling_boulder(Vector2(5600, -10), 52.0, 0.34)
    )

    var final_spikes := _spikes(Vector2(5900, 612), 3, true)
    _trigger(Rect2(5680, 390, 120, 240), func():
        _timed_hazard(final_spikes, 0.32 + float(a % 3) * 0.08, 0.44, "102_final")
    )

    _finish(Vector2(6350, 580))

func _level_10_3() -> void:
    _floor_with_gaps(7400, [Vector2(1560, 1715), Vector2(3540, 3700), Vector2(5570, 5730)])
    var a := _attempt(10, 3)
    _text(Vector2(120, 470), "MİNİ FİNAL: 30. HARİTA.", 24, V12_GOLD)
    _text(Vector2(410, 520), "DENEME %d — HER SİSTEM MASADA." % a, 18, V12_MUTED)

    _route_hint(Vector2(820, 500), "A")
    _route_hint(Vector2(820, 390), "B")
    _platform(Vector2(930, 465), Vector2(230, 24), V12_BLUE)
    _platform(Vector2(1220, 435), Vector2(210, 24), V12_BLUE)
    var upper_memory := _spikes(Vector2(1370, 432), 2, true)
    var lower_memory := _spikes(Vector2(1370, 612), 3, true)
    _trigger(Rect2(720, 315, 230, 175), func():
        if _choose_route("upper"):
            var target := upper_memory if a % 2 == 0 else lower_memory
            var tw := create_tween()
            tw.tween_interval(0.34)
            tw.tween_callback(func(): _reveal(target))
    )
    _trigger(Rect2(720, 500, 230, 150), func():
        if _choose_route("lower"):
            var target := lower_memory if a % 2 == 0 else upper_memory
            var tw := create_tween()
            tw.tween_interval(0.34)
            tw.tween_callback(func(): _reveal(target))
    )

    _moving_platform(Vector2(1640, 555), Vector2(150, 24), Vector2(1680, 470), 1.38, V12_CYAN)

    var crusher := _hazard_block(Vector2(2250, 215), Vector2(160, 72), V12_RED_DARK)
    _trigger(Rect2(1980, 390, 120, 240), func():
        if _once("103_crush"):
            var tw := create_tween()
            tw.tween_interval(0.30 + float(a % 3) * 0.08)
            tw.tween_property(crusher, "position:y", 520.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_interval(0.18)
            tw.tween_property(crusher, "position:y", 215.0, 0.50).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

    _decor_block(Vector2(2780, 345), Vector2(90, 200))
    _trigger(Rect2(2630, 390, 120, 240), func():
        if _once("103_alarm"):
            _false_alarm()
    )

    var gate := _hidden_hazard(Vector2(3200, 530), Vector2(28, 230), V12_RED)
    _trigger(Rect2(2920, 390, 120, 240), func():
        _timed_hazard(gate, 0.30 + float(a % 2) * 0.14, 0.42, "103_gate")
    )

    _moving_platform(Vector2(3620, 555), Vector2(145, 24), Vector2(3660, 470), 1.30, V12_BLUE)

    _trigger(Rect2(3990, 390, 120, 240), func():
        if _once("103_reverse"):
            controls_reversed = true
            _final_notice("TERS KONTROL")
            var tw := create_tween()
            tw.tween_interval(0.78 if a % 2 == 0 else 0.94)
            tw.tween_callback(func(): controls_reversed = false)
    )

    var delayed := _spikes(Vector2(4520, 612), 3, true)
    _trigger(Rect2(4260, 390, 120, 240), func():
        _timed_hazard(delayed, 0.28 + float(a % 3) * 0.09, 0.48, "103_spikes")
    )

    _trigger(Rect2(4880, 390, 120, 240), func():
        if _once("103_rock"):
            var tw := create_tween()
            tw.tween_interval(0.38)
            tw.tween_callback(func(): _boulder(Vector2(5480, 560), -385.0, 72.0))
    )

    _moving_platform(Vector2(5650, 555), Vector2(140, 24), Vector2(5685, 470), 1.28, V12_CYAN)

    var safe_red := _platform(Vector2(6170, 548), Vector2(180, 26), V12_RED_DARK.lerp(V12_SLATE, 0.78))
    _trigger(Rect2(5930, 390, 120, 240), func():
        if _once("103_safe"):
            _false_alarm()
            create_tween().tween_property(safe_red, "position:y", 544.0, 0.12)
    )

    var last_gate := _hidden_hazard(Vector2(6550, 530), Vector2(28, 230), V12_RED)
    _trigger(Rect2(6280, 390, 120, 240), func():
        if _once("103_last_gate"):
            var tw := create_tween()
            tw.tween_interval(0.34)
            tw.tween_callback(func(): _reveal(last_gate))
            tw.tween_interval(0.38)
            tw.tween_callback(func(): _hide(last_gate))
    )

    var goal := _finish(Vector2(7080, 580))
    _trigger(Rect2(6800, 390, 120, 240), func():
        if _once("103_goal"):
            if a % 3 == 1:
                create_tween().tween_property(goal, "position:x", 7200.0, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
            else:
                _final_notice("30. HARİTA")
    )
