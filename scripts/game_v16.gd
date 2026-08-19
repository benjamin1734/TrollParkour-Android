extends "res://scripts/game_v15.gd"

const V16_BG := Color("#edf1f6")
const V16_BG_CH14 := Color("#e7edf2")
const V16_INK := Color("#111827")
const V16_SLATE := Color("#475569")
const V16_MUTED := Color("#64748b")
const V16_BLUE := Color("#2563eb")
const V16_CYAN := Color("#0891b2")
const V16_GREEN := Color("#16a34a")
const V16_AMBER := Color("#d97706")
const V16_RED := Color("#dc4455")
const V16_RED_DARK := Color("#7f2937")
const V16_PURPLE := Color("#7c3aed")

func _safe_load_progress() -> void:
    super._safe_load_progress()
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return
    var stored_unlock = cfg.get_value("progress", "unlocked_chapter", 1)
    if stored_unlock is int or stored_unlock is float:
        unlocked_chapter = clampi(int(stored_unlock), 1, 15)

func _start_level(c: int, p: int) -> void:
    super._start_level(c, p)
    if c == 14:
        RenderingServer.set_default_clear_color(V16_BG_CH14)
        _add_chapter14_decor()

func _build_level(c: int, p: int) -> void:
    if c == 14 and p == 1:
        _level_14_1()
    elif c == 14 and p == 2:
        _level_14_2()
    elif c == 14 and p == 3:
        _level_14_3()
    else:
        super._build_level(c, p)

func _build_hud() -> void:
    super._build_hud()
    if chapter == 14:
        var mode := Label.new()
        mode.position = Vector2(720, 18)
        mode.size = Vector2(275, 38)
        mode.text = "ALGI / DERİNLİK"
        mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        mode.add_theme_font_size_override("font_size", 16)
        mode.add_theme_color_override("font_color", V16_PURPLE)
        hud.add_child(mode)

func _show_main_menu() -> void:
    active_map_key = ""
    timer_label = null
    RenderingServer.set_default_clear_color(V16_BG)
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
    bg.color = V16_BG
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(bg)

    var top_band := ColorRect.new()
    top_band.size = Vector2(1280, 92)
    top_band.color = V16_INK
    top_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(top_band)

    var version := Label.new()
    version.position = Vector2(24, 27)
    version.size = Vector2(250, 40)
    version.text = "ANDROID • v1.6"
    version.add_theme_font_size_override("font_size", 18)
    version.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(version)

    var records := Label.new()
    records.position = Vector2(925, 27)
    records.size = Vector2(325, 40)
    records.text = "KAYITLI REKOR: %d / 42" % best_times_ms.size()
    records.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    records.add_theme_font_size_override("font_size", 17)
    records.add_theme_color_override("font_color", Color(1, 1, 1, 0.78))
    hud.add_child(records)

    var title := Label.new()
    title.position = Vector2(180, 118)
    title.size = Vector2(920, 95)
    title.text = "TROLL PARKOUR"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 58)
    title.add_theme_color_override("font_color", V16_INK)
    hud.add_child(title)

    var subtitle := Label.new()
    subtitle.position = Vector2(205, 202)
    subtitle.size = Vector2(870, 58)
    subtitle.text = "Bölüm 14: Ekranın söylediği yön ile parkurun gerçek yönü aynı olmayabilir."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 20)
    subtitle.add_theme_color_override("font_color", V16_MUTED)
    hud.add_child(subtitle)

    var progress := Label.new()
    progress.position = Vector2(255, 276)
    progress.size = Vector2(770, 44)
    var available := maxi(1, mini(unlocked_chapter, 14))
    var completed_maps := maxi(0, (mini(unlocked_chapter, 15) - 1) * 3)
    progress.text = "AÇIK BÖLÜM: %d / 14     HARİTA: %d / 42     ÖLÜM: %d" % [available, completed_maps, deaths]
    progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    progress.add_theme_font_size_override("font_size", 19)
    progress.add_theme_color_override("font_color", V16_RED_DARK)
    hud.add_child(progress)

    _menu_button("DEVAM ET", Vector2(440, 350), Vector2(400, 72), func():
        _start_level(maxi(1, mini(unlocked_chapter, 14)), 1)
    )
    _menu_button("BÖLÜMLER", Vector2(440, 440), Vector2(400, 72), func():
        _show_chapter_select()
    )
    _menu_button("1. BÖLÜMDEN BAŞLA", Vector2(440, 530), Vector2(400, 72), func():
        _start_level(1, 1)
    )

    var warning := Label.new()
    warning.position = Vector2(185, 630)
    warning.size = Vector2(910, 40)
    warning.text = "Kamera numaraları kısa tutulur; gerçek tehlike hâlâ parkurun kendisidir."
    warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    warning.add_theme_font_size_override("font_size", 17)
    warning.add_theme_color_override("font_color", V16_MUTED)
    hud.add_child(warning)
    _polish_menu_surface()

func _show_chapter_select() -> void:
    timer_label = null
    RenderingServer.set_default_clear_color(V16_BG)
    if is_instance_valid(hud):
        hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)

    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V16_BG
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(240, 16)
    title.size = Vector2(800, 56)
    title.text = "BÖLÜM SEÇ"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 36)
    title.add_theme_color_override("font_color", V16_INK)
    hud.add_child(title)

    var info := Label.new()
    info.position = Vector2(150, 65)
    info.size = Vector2(980, 32)
    info.text = "14 bölüm • 42 harita • Süre ve ölüm rekorları aktif"
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.add_theme_font_size_override("font_size", 16)
    info.add_theme_color_override("font_color", V16_MUTED)
    hud.add_child(info)

    for i in range(1, 15):
        var chapter_id := i
        var is_unlocked := chapter_id <= unlocked_chapter
        var col := (i - 1) % 4
        var row := int((i - 1) / 4)
        var pos := Vector2(55 + col * 300, 105 + row * 86)
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
        elif chapter_id == 11:
            suffix = "REAKTİF"
        elif chapter_id == 12:
            suffix = "TEMPO"
        elif chapter_id == 13:
            suffix = "KAYAN GÜVEN"
        elif chapter_id == 14:
            suffix = "ALGI"
        var button_text := "BÖLÜM %d\n%s" % [chapter_id, suffix] if is_unlocked else "BÖLÜM %d\nKİLİTLİ" % chapter_id
        var button := _menu_button(button_text, pos, Vector2(270, 66), func():
            _start_level(chapter_id, 1)
        )
        button.disabled = not is_unlocked

    var note := Label.new()
    note.position = Vector2(175, 475)
    note.size = Vector2(930, 36)
    note.text = "Bölüm 14 kamera algısını, hareketli platformları ve Troll Hafızasını birlikte kullanır."
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    note.add_theme_font_size_override("font_size", 16)
    note.add_theme_color_override("font_color", V16_MUTED)
    hud.add_child(note)

    _menu_button("GERİ", Vector2(490, 525), Vector2(300, 60), func():
        _show_main_menu()
    )
    _polish_menu_surface()

func _show_chapter_result() -> void:
    timer_label = null
    if is_instance_valid(world):
        world.queue_free()
    world = null
    if is_instance_valid(hud):
        hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)

    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V16_INK
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(160, 62)
    title.size = Vector2(960, 300)
    var map_count := mini(chapter * 3, 42)
    title.text = "BÖLÜM %d TAMAMLANDI\n\nTOPLAM ÖLÜM: %d\nTAMAMLANAN HARİTA: %d / 42" % [chapter, deaths, map_count]
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(title)

    if chapter < 14:
        var next_chapter := chapter + 1
        _menu_button("SONRAKİ BÖLÜM", Vector2(440, 430), Vector2(400, 72), func():
            _start_level(next_chapter, 1)
        )
    else:
        var stats := Label.new()
        stats.position = Vector2(125, 350)
        stats.size = Vector2(1030, 145)
        stats.text = "14-1  %s / %s ölüm     14-2  %s / %s ölüm     14-3  %s / %s ölüm\n\n42 HARİTA TAMAM" % [
            _best_time_text(14, 1), _best_deaths_text(14, 1),
            _best_time_text(14, 2), _best_deaths_text(14, 2),
            _best_time_text(14, 3), _best_deaths_text(14, 3)
        ]
        stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        stats.add_theme_font_size_override("font_size", 19)
        stats.add_theme_color_override("font_color", V16_PURPLE)
        hud.add_child(stats)

    _menu_button("ANA MENÜ", Vector2(490, 555), Vector2(300, 64), func():
        _show_main_menu()
    )

func _add_chapter14_decor() -> void:
    if not is_instance_valid(world):
        return

    for layer in range(3):
        var line := Line2D.new()
        line.width = 2.0 + float(layer)
        line.default_color = Color(0.16, 0.28, 0.45, 0.045 + float(layer) * 0.018)
        var y := 350.0 + float(layer) * 34.0
        line.points = PackedVector2Array([Vector2(0, y), Vector2(level_width, y)])
        line.z_index = -26 + layer
        world.add_child(line)

    for i in range(18):
        var x := 140.0 + float(i) * 410.0
        var post := Line2D.new()
        post.width = 2.0
        post.default_color = Color(0.20, 0.30, 0.48, 0.06)
        post.points = PackedVector2Array([
            Vector2(x - 35, 438), Vector2(x - 12, 388), Vector2(x + 12, 388), Vector2(x + 35, 438)
        ])
        post.z_index = -23
        world.add_child(post)

func _perspective_shift(offset_x: float, offset_y: float, angle_deg: float, hold: float = 0.42) -> void:
    if not is_instance_valid(camera):
        return
    var target_offset := Vector2(offset_x, offset_y)
    var tw := create_tween()
    tw.set_parallel(true)
    tw.tween_property(camera, "offset", target_offset, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tw.tween_property(camera, "rotation", deg_to_rad(angle_deg), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tw.set_parallel(false)
    tw.tween_interval(hold)
    tw.set_parallel(true)
    tw.tween_property(camera, "offset", Vector2.ZERO, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
    tw.tween_property(camera, "rotation", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func _depth_plate(pos: Vector2, size: Vector2, tint: Color) -> Polygon2D:
    var plate := Polygon2D.new()
    plate.position = pos
    plate.polygon = PackedVector2Array([
        Vector2(-size.x / 2.0, -size.y / 2.0), Vector2(size.x / 2.0, -size.y / 2.0),
        Vector2(size.x / 2.0, size.y / 2.0), Vector2(-size.x / 2.0, size.y / 2.0)
    ])
    plate.color = tint
    plate.z_index = -8
    world.add_child(plate)
    return plate

func _level_14_1() -> void:
    _floor_with_gaps(6600, [Vector2(1780, 1940), Vector2(4380, 4540)])
    _text(Vector2(120, 470), "BÖLÜM 14: GÖZÜNE GÜVENME.", 23, V16_PURPLE)
    _text(Vector2(410, 520), "KAMERA HAREKET EDER. ZEMİN HER ZAMAN ETMEZ.", 18, V16_MUTED)

    _depth_plate(Vector2(900, 430), Vector2(420, 120), Color(0.18, 0.30, 0.50, 0.055))
    _trigger(Rect2(640, 390, 120, 240), func():
        if _once("141_view"):
            _perspective_shift(42.0, -10.0, 2.2, 0.36)
            _false_alarm()
    )

    var first := _spikes(Vector2(1320, 612), 3, true)
    _trigger(Rect2(1080, 390, 120, 240), func():
        if _once("141_first"):
            var tw := create_tween()
            tw.tween_interval(0.30)
            tw.tween_callback(func(): _reveal(first))
            tw.tween_interval(0.46)
            tw.tween_callback(func(): _hide(first))
    )

    _moving_platform(Vector2(1860, 555), Vector2(150, 24), Vector2(1900, 470), 1.36, V16_BLUE)

    var safe := _safe_pad(Vector2(2450, 548), 190.0)
    _trigger(Rect2(2200, 390, 120, 240), func():
        if _once("141_safe"):
            _perspective_shift(-34.0, 8.0, -1.8, 0.30)
            _false_alarm()
            create_tween().tween_property(safe, "position:y", 545.0, 0.12)
    )

    _moving_platform(Vector2(3150, 548), Vector2(190, 26), Vector2(3390, 548), 1.48, V16_CYAN)
    _trigger(Rect2(2860, 390, 120, 240), func():
        if _once("141_slider"):
            _perspective_shift(-50.0, 0.0, -2.0, 0.48)
            _shift_notice("EKRAN SOLA, PLATFORM SAĞA", V16_PURPLE)
    )

    _trigger(Rect2(3700, 390, 120, 240), func():
        if _once("141_rock"):
            var tw := create_tween()
            tw.tween_interval(0.42)
            tw.tween_callback(func(): _boulder(Vector2(4300, 560), -365.0, 70.0))
    )

    _moving_platform(Vector2(4460, 555), Vector2(145, 24), Vector2(4500, 470), 1.32, V16_BLUE)

    var last := _spikes(Vector2(5170, 612), 3, true)
    _trigger(Rect2(4890, 390, 120, 240), func():
        _timed_hazard(last, 0.32, 0.46, "141_last")
    )

    _finish(Vector2(6250, 580))

func _level_14_2() -> void:
    _floor_with_gaps(7000, [Vector2(2050, 2210), Vector2(4860, 5020)])
    _text(Vector2(120, 470), "ÖN PLAN / ARKA PLAN.", 23, V16_PURPLE)
    _text(Vector2(410, 520), "GÖRSEL DERİNLİK HER ZAMAN ÇARPIŞMA DEMEK DEĞİL.", 18, V16_MUTED)

    _depth_plate(Vector2(980, 405), Vector2(520, 150), Color(0.12, 0.32, 0.50, 0.06))
    _platform(Vector2(970, 505), Vector2(220, 24), V16_BLUE)
    _platform(Vector2(1280, 455), Vector2(210, 24), V16_BLUE)
    _trigger(Rect2(720, 315, 220, 175), func():
        if _choose_route("upper"):
            _perspective_shift(34.0, -12.0, 1.7, 0.32)
            _false_alarm()
    )
    _trigger(Rect2(720, 500, 220, 150), func():
        if _choose_route("lower"):
            _shift_notice("ALT ROTA", V16_CYAN)
    )

    var lower := _spikes(Vector2(1640, 612), 3, true)
    _trigger(Rect2(1420, 390, 120, 240), func():
        if _once("142_route") and route_choice == "lower":
            var tw := create_tween()
            tw.tween_interval(0.34)
            tw.tween_callback(func(): _reveal(lower))
            tw.tween_interval(0.44)
            tw.tween_callback(func(): _hide(lower))
    )

    _moving_platform(Vector2(2130, 555), Vector2(150, 24), Vector2(2170, 470), 1.36, V16_CYAN)

    var fake_depth := _depth_plate(Vector2(2830, 520), Vector2(250, 34), Color(0.18, 0.30, 0.46, 0.12))
    _trigger(Rect2(2520, 390, 120, 240), func():
        if _once("142_depth"):
            _perspective_shift(-40.0, 10.0, -2.0, 0.34)
            create_tween().tween_property(fake_depth, "position:y", 500.0, 0.24)
            _false_alarm()
    )

    var real_drop := _platform(Vector2(3440, 548), Vector2(190, 26), V16_SLATE)
    _trigger(Rect2(3190, 390, 120, 240), func():
        if _once("142_drop"):
            _delayed_platform_drop(real_drop, 0.46, 300.0)
    )

    _trigger(Rect2(3920, 390, 120, 240), func():
        if _once("142_reverse_view"):
            _perspective_shift(52.0, 0.0, 2.2, 0.46)
            if route_choice == "upper":
                _reverse_controls(0.68)
    )

    _moving_platform(Vector2(4940, 555), Vector2(145, 24), Vector2(4980, 470), 1.30, V16_BLUE)

    _trigger(Rect2(5380, 390, 120, 240), func():
        if _once("142_fall"):
            _falling_boulder(Vector2(5630, 20), 58.0, 0.0)
            _falling_boulder(Vector2(5880, -20), 50.0, 0.40)
    )

    var safe_end := _safe_pad(Vector2(6250, 548), 180.0)
    _trigger(Rect2(6010, 390, 120, 240), func():
        if _once("142_safe_end"):
            _false_alarm()
            create_tween().tween_property(safe_end, "position:x", 6254.0, 0.12)
    )

    _finish(Vector2(6700, 580))

func _level_14_3() -> void:
    _floor_with_gaps(7800, [Vector2(1710, 1870), Vector2(3970, 4130), Vector2(6040, 6200)])
    var a := _attempt(14, 3)
    _text(Vector2(120, 470), "ALGIYI HATIRLIYORUM.", 24, V16_PURPLE)
    _text(Vector2(410, 520), "DENEME %d — KAMERA AYNI NUMARAYI AYNI YÖNDE YAPMAZ." % a, 18, V16_MUTED)

    _trigger(Rect2(650, 390, 120, 240), func():
        if _once("143_open"):
            var dir := 1.0 if a % 2 == 0 else -1.0
            _perspective_shift(46.0 * dir, -8.0, 2.0 * dir, 0.38)
            _false_alarm()
    )

    var memory_a := _spikes(Vector2(1230, 612), 3, true)
    var memory_b := _spikes(Vector2(1480, 612), 3, true)
    _trigger(Rect2(930, 390, 120, 240), func():
        if _once("143_memory"):
            var target := memory_a if a % 2 == 1 else memory_b
            var tw := create_tween()
            tw.tween_interval(0.30)
            tw.tween_callback(func(): _reveal(target))
            tw.tween_interval(0.44)
            tw.tween_callback(func(): _hide(target))
    )

    _moving_platform(Vector2(1790, 555), Vector2(150, 24), Vector2(1830, 470), 1.34, V16_CYAN)

    _route_hint(Vector2(2350, 500), "A")
    _route_hint(Vector2(2350, 390), "B")
    _platform(Vector2(2460, 465), Vector2(230, 24), V16_BLUE)
    _platform(Vector2(2750, 435), Vector2(210, 24), V16_BLUE)
    _trigger(Rect2(2240, 315, 220, 175), func():
        if _choose_route("upper"):
            _false_alarm()
    )
    _trigger(Rect2(2240, 500, 220, 150), func():
        if _choose_route("lower"):
            _shift_notice("A", V16_CYAN)
    )

    var route_gate := _hidden_hazard(Vector2(3340, 530), Vector2(28, 230), V16_RED)
    _trigger(Rect2(3070, 390, 120, 240), func():
        if _once("143_route_gate"):
            var fire := (route_choice == "upper" and a % 3 == 0) or (route_choice == "lower" and a % 3 != 0)
            if fire:
                var tw := create_tween()
                tw.tween_interval(0.30)
                tw.tween_callback(func(): _reveal(route_gate))
                tw.tween_interval(0.40)
                tw.tween_callback(func(): _hide(route_gate))
            else:
                _false_alarm()
    )

    _moving_platform(Vector2(4050, 555), Vector2(145, 24), Vector2(4090, 470), 1.28, V16_BLUE)

    _trigger(Rect2(4470, 390, 120, 240), func():
        if _once("143_camera_reverse"):
            var dir := -1.0 if a % 2 == 0 else 1.0
            _perspective_shift(56.0 * dir, 6.0, 2.4 * dir, 0.42)
            if a % 3 == 1:
                _reverse_controls(0.72)
    )

    var safe := _safe_pad(Vector2(5050, 548), 185.0)
    _trigger(Rect2(4810, 390, 120, 240), func():
        if _once("143_safe"):
            if a % 3 == 2:
                _delayed_platform_drop(safe, 0.52, 290.0)
                _shift_notice("BU SEFER DEĞİL", V16_PURPLE)
            else:
                _false_alarm()
    )

    _trigger(Rect2(5480, 390, 120, 240), func():
        if _once("143_rock"):
            var tw := create_tween()
            tw.tween_interval(0.42)
            tw.tween_callback(func(): _boulder(Vector2(6120, 560), -360.0, 70.0))
    )

    _moving_platform(Vector2(6120, 555), Vector2(140, 24), Vector2(6160, 470), 1.28, V16_CYAN)

    var final_spikes := _spikes(Vector2(6750, 612), 3, true)
    _trigger(Rect2(6480, 390, 120, 240), func():
        _timed_hazard(final_spikes, 0.30 + float(a % 2) * 0.10, 0.44, "143_final")
    )

    var goal := _finish(Vector2(7470, 580))
    _trigger(Rect2(7160, 390, 120, 240), func():
        if _once("143_goal"):
            if a % 3 == 1:
                _perspective_shift(-42.0, 0.0, -1.8, 0.30)
                create_tween().tween_property(goal, "position:x", 7585.0, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
            else:
                _false_alarm()
    )
