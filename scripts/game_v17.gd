extends "res://scripts/game_v16.gd"

const V17_BG := Color("#edf1f6")
const V17_BG_CH15 := Color("#e8edf0")
const V17_INK := Color("#111827")
const V17_SLATE := Color("#475569")
const V17_MUTED := Color("#64748b")
const V17_BLUE := Color("#2563eb")
const V17_CYAN := Color("#0891b2")
const V17_GREEN := Color("#16a34a")
const V17_AMBER := Color("#d97706")
const V17_RED := Color("#dc4455")
const V17_RED_DARK := Color("#7f2937")
const V17_PURPLE := Color("#7c3aed")

func _safe_load_progress() -> void:
    super._safe_load_progress()
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return
    var stored_unlock = cfg.get_value("progress", "unlocked_chapter", 1)
    if stored_unlock is int or stored_unlock is float:
        unlocked_chapter = clampi(int(stored_unlock), 1, 16)

func _start_level(c: int, p: int) -> void:
    super._start_level(c, p)
    if c == 15:
        RenderingServer.set_default_clear_color(V17_BG_CH15)
        _add_chapter15_decor()

func _build_level(c: int, p: int) -> void:
    if c == 15 and p == 1:
        _level_15_1()
    elif c == 15 and p == 2:
        _level_15_2()
    elif c == 15 and p == 3:
        _level_15_3()
    else:
        super._build_level(c, p)

func _build_hud() -> void:
    super._build_hud()
    if chapter == 15:
        var mode := Label.new()
        mode.position = Vector2(720, 18)
        mode.size = Vector2(275, 38)
        mode.text = "SES / SESSİZLİK"
        mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        mode.add_theme_font_size_override("font_size", 16)
        mode.add_theme_color_override("font_color", V17_AMBER)
        hud.add_child(mode)

func _show_main_menu() -> void:
    active_map_key = ""
    timer_label = null
    RenderingServer.set_default_clear_color(V17_BG)
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
    bg.color = V17_BG
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(bg)

    var top_band := ColorRect.new()
    top_band.size = Vector2(1280, 92)
    top_band.color = V17_INK
    top_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(top_band)

    var version := Label.new()
    version.position = Vector2(24, 27)
    version.size = Vector2(250, 40)
    version.text = "ANDROID • v1.7"
    version.add_theme_font_size_override("font_size", 18)
    version.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(version)

    var records := Label.new()
    records.position = Vector2(925, 27)
    records.size = Vector2(325, 40)
    records.text = "KAYITLI REKOR: %d / 45" % best_times_ms.size()
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
    title.add_theme_color_override("font_color", V17_INK)
    hud.add_child(title)

    var subtitle := Label.new()
    subtitle.position = Vector2(205, 202)
    subtitle.size = Vector2(870, 58)
    subtitle.text = "Bölüm 15: Duyduğun uyarı bazen doğru, sessizlik bazen daha tehlikeli."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 20)
    subtitle.add_theme_color_override("font_color", V17_MUTED)
    hud.add_child(subtitle)

    var progress := Label.new()
    progress.position = Vector2(255, 276)
    progress.size = Vector2(770, 44)
    var available := maxi(1, mini(unlocked_chapter, 15))
    var completed_maps := maxi(0, (mini(unlocked_chapter, 16) - 1) * 3)
    progress.text = "AÇIK BÖLÜM: %d / 15     HARİTA: %d / 45     ÖLÜM: %d" % [available, completed_maps, deaths]
    progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    progress.add_theme_font_size_override("font_size", 19)
    progress.add_theme_color_override("font_color", V17_RED_DARK)
    hud.add_child(progress)

    _menu_button("DEVAM ET", Vector2(440, 350), Vector2(400, 72), func():
        _start_level(maxi(1, mini(unlocked_chapter, 15)), 1)
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
    warning.text = "Ses ipucu olabilir; tek başına kesin tuzak işareti değildir."
    warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    warning.add_theme_font_size_override("font_size", 17)
    warning.add_theme_color_override("font_color", V17_MUTED)
    hud.add_child(warning)
    _polish_menu_surface()

func _show_chapter_select() -> void:
    timer_label = null
    RenderingServer.set_default_clear_color(V17_BG)
    if is_instance_valid(hud):
        hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)

    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V17_BG
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(240, 14)
    title.size = Vector2(800, 54)
    title.text = "BÖLÜM SEÇ"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 35)
    title.add_theme_color_override("font_color", V17_INK)
    hud.add_child(title)

    var info := Label.new()
    info.position = Vector2(150, 61)
    info.size = Vector2(980, 32)
    info.text = "15 bölüm • 45 harita • Süre ve ölüm rekorları aktif"
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.add_theme_font_size_override("font_size", 16)
    info.add_theme_color_override("font_color", V17_MUTED)
    hud.add_child(info)

    for i in range(1, 16):
        var chapter_id := i
        var is_unlocked := chapter_id <= unlocked_chapter
        var col := (i - 1) % 4
        var row := int((i - 1) / 4)
        var pos := Vector2(55 + col * 300, 100 + row * 82)
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
        elif chapter_id == 15:
            suffix = "SES"
        var button_text := "BÖLÜM %d\n%s" % [chapter_id, suffix] if is_unlocked else "BÖLÜM %d\nKİLİTLİ" % chapter_id
        var button := _menu_button(button_text, pos, Vector2(270, 62), func():
            _start_level(chapter_id, 1)
        )
        button.disabled = not is_unlocked

    var note := Label.new()
    note.position = Vector2(175, 450)
    note.size = Vector2(930, 34)
    note.text = "Bölüm 15 gerçek ve sahte ses işaretlerini zamanlama, rota ve Troll Hafızasıyla birleştirir."
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    note.add_theme_font_size_override("font_size", 15)
    note.add_theme_color_override("font_color", V17_MUTED)
    hud.add_child(note)

    _menu_button("GERİ", Vector2(490, 500), Vector2(300, 58), func():
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
    bg.color = V17_INK
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(160, 62)
    title.size = Vector2(960, 300)
    var map_count := mini(chapter * 3, 45)
    title.text = "BÖLÜM %d TAMAMLANDI\n\nTOPLAM ÖLÜM: %d\nTAMAMLANAN HARİTA: %d / 45" % [chapter, deaths, map_count]
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(title)

    if chapter < 15:
        var next_chapter := chapter + 1
        _menu_button("SONRAKİ BÖLÜM", Vector2(440, 430), Vector2(400, 72), func():
            _start_level(next_chapter, 1)
        )
    else:
        var stats := Label.new()
        stats.position = Vector2(125, 350)
        stats.size = Vector2(1030, 145)
        stats.text = "15-1  %s / %s ölüm     15-2  %s / %s ölüm     15-3  %s / %s ölüm\n\n45 HARİTA TAMAM" % [
            _best_time_text(15, 1), _best_deaths_text(15, 1),
            _best_time_text(15, 2), _best_deaths_text(15, 2),
            _best_time_text(15, 3), _best_deaths_text(15, 3)
        ]
        stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        stats.add_theme_font_size_override("font_size", 19)
        stats.add_theme_color_override("font_color", V17_AMBER)
        hud.add_child(stats)

    _menu_button("ANA MENÜ", Vector2(490, 555), Vector2(300, 64), func():
        _show_main_menu()
    )

func _add_chapter15_decor() -> void:
    if not is_instance_valid(world):
        return
    var base := Line2D.new()
    base.width = 2.0
    base.default_color = Color(0.55, 0.36, 0.10, 0.08)
    base.points = PackedVector2Array([Vector2(0, 438), Vector2(level_width, 438)])
    base.z_index = -24
    world.add_child(base)
    for i in range(20):
        var x := 140.0 + float(i) * 370.0
        var wave := Line2D.new()
        wave.width = 2.0
        wave.default_color = Color(0.55, 0.36, 0.10, 0.06)
        wave.points = PackedVector2Array([
            Vector2(x - 48, 416), Vector2(x - 28, 400), Vector2(x - 10, 430),
            Vector2(x + 8, 390), Vector2(x + 28, 421), Vector2(x + 50, 405)
        ])
        wave.z_index = -23
        world.add_child(wave)

func _audio_warning(fake: bool = false) -> void:
    if fake:
        _play_tone(760.0, 0.05, 0.10)
        var tw := create_tween()
        tw.tween_interval(0.09)
        tw.tween_callback(func(): _play_tone(760.0, 0.05, 0.08))
    else:
        _play_tone(250.0, 0.08, 0.14)
        var tw := create_tween()
        tw.tween_interval(0.08)
        tw.tween_callback(func(): _play_tone(190.0, 0.10, 0.15))

func _silent_notice(text: String) -> void:
    _troll_popup(text, V17_SLATE)

func _level_15_1() -> void:
    _floor_with_gaps(6700, [Vector2(1810, 1970), Vector2(4470, 4630)])
    _text(Vector2(120, 470), "BÖLÜM 15: DUYDUĞUNA GÜVENME.", 23, V17_AMBER)
    _text(Vector2(410, 520), "BAZEN SES UYARIR. BAZEN SADECE SENİ YAVAŞLATIR.", 18, V17_MUTED)

    var silent_spikes := _spikes(Vector2(1050, 612), 3, true)
    _trigger(Rect2(700, 390, 120, 240), func():
        if _once("151_fake_sound"):
            _audio_warning(true)
            _false_alarm()
    )

    _trigger(Rect2(1120, 390, 120, 240), func():
        if _once("151_silent"):
            var tw := create_tween()
            tw.tween_interval(0.30)
            tw.tween_callback(func(): _reveal(silent_spikes))
            tw.tween_interval(0.46)
            tw.tween_callback(func(): _hide(silent_spikes))
    )

    _moving_platform(Vector2(1890, 555), Vector2(150, 24), Vector2(1930, 470), 1.36, V17_BLUE)

    var warned := _spikes(Vector2(2500, 612), 3, true)
    _trigger(Rect2(2210, 390, 120, 240), func():
        if _once("151_real_sound"):
            _audio_warning(false)
            var tw := create_tween()
            tw.tween_interval(0.48)
            tw.tween_callback(func(): _reveal(warned))
            tw.tween_interval(0.45)
            tw.tween_callback(func(): _hide(warned))
    )

    var decoy := _safe_pad(Vector2(3180, 548), 185.0)
    _trigger(Rect2(2920, 390, 120, 240), func():
        if _once("151_decoy"):
            _audio_warning(true)
            _false_alarm()
            create_tween().tween_property(decoy, "position:y", 545.0, 0.12)
    )

    _trigger(Rect2(3790, 390, 120, 240), func():
        if _once("151_rock"):
            _silent_notice("SESSİZ")
            var tw := create_tween()
            tw.tween_interval(0.38)
            tw.tween_callback(func(): _boulder(Vector2(4380, 560), -360.0, 70.0))
    )

    _moving_platform(Vector2(4550, 555), Vector2(145, 24), Vector2(4590, 470), 1.32, V17_CYAN)

    var last := _spikes(Vector2(5350, 612), 3, true)
    _trigger(Rect2(5060, 390, 120, 240), func():
        if _once("151_last"):
            _audio_warning(false)
            _timed_hazard(last, 0.38, 0.44, "151_last_hazard")
    )

    _finish(Vector2(6370, 580))

func _level_15_2() -> void:
    _floor_with_gaps(7200, [Vector2(2050, 2210), Vector2(5020, 5180)])
    _text(Vector2(120, 470), "SESSİZLİK DE BİR İŞARET.", 23, V17_AMBER)
    _text(Vector2(410, 520), "AMA HER SESSİZ BÖLGE DE TUZAK DEĞİL.", 18, V17_MUTED)

    _trigger(Rect2(680, 390, 120, 240), func():
        if _once("152_open"):
            _audio_warning(true)
            _false_alarm()
    )

    var upper_trap := _spikes(Vector2(1580, 612), 3, true)
    _route_hint(Vector2(1070, 500), "A")
    _route_hint(Vector2(1070, 390), "B")
    _platform(Vector2(1180, 465), Vector2(230, 24), V17_BLUE)
    _platform(Vector2(1470, 435), Vector2(210, 24), V17_BLUE)
    _trigger(Rect2(960, 315, 220, 175), func():
        if _choose_route("upper"):
            _audio_warning(false)
    )
    _trigger(Rect2(960, 500, 220, 150), func():
        if _choose_route("lower"):
            _false_alarm()
    )
    _trigger(Rect2(1370, 390, 120, 240), func():
        if _once("152_route") and route_choice == "upper":
            var tw := create_tween()
            tw.tween_interval(0.30)
            tw.tween_callback(func(): _reveal(upper_trap))
            tw.tween_interval(0.45)
            tw.tween_callback(func(): _hide(upper_trap))
    )

    _moving_platform(Vector2(2130, 555), Vector2(150, 24), Vector2(2170, 470), 1.35, V17_CYAN)

    var quiet_pad := _safe_pad(Vector2(2860, 548), 185.0)
    _trigger(Rect2(2600, 390, 120, 240), func():
        if _once("152_quiet_safe"):
            _false_alarm()
            create_tween().tween_property(quiet_pad, "position:x", 2864.0, 0.12)
    )

    var drop := _platform(Vector2(3530, 548), Vector2(185, 26), V17_SLATE)
    _trigger(Rect2(3270, 390, 120, 240), func():
        if _once("152_drop"):
            _audio_warning(true)
            _delayed_platform_drop(drop, 0.48, 300.0)
    )

    _trigger(Rect2(4050, 390, 120, 240), func():
        if _once("152_reverse"):
            _audio_warning(false)
            if route_choice == "lower":
                _reverse_controls(0.72)
    )

    _trigger(Rect2(4660, 390, 120, 240), func():
        if _once("152_fall"):
            _falling_boulder(Vector2(4880, 20), 58.0, 0.0)
            _falling_boulder(Vector2(5140, -20), 50.0, 0.42)
    )

    _moving_platform(Vector2(5100, 555), Vector2(145, 24), Vector2(5140, 470), 1.30, V17_BLUE)

    var end_spikes := _spikes(Vector2(6000, 612), 3, true)
    _trigger(Rect2(5700, 390, 120, 240), func():
        if _once("152_end"):
            _audio_warning(false)
            _timed_hazard(end_spikes, 0.42, 0.44, "152_end_hazard")
    )

    _finish(Vector2(6860, 580))

func _level_15_3() -> void:
    _floor_with_gaps(8000, [Vector2(1740, 1900), Vector2(4100, 4260), Vector2(6280, 6440)])
    var a := _attempt(15, 3)
    _text(Vector2(120, 470), "SESİ HATIRLIYORUM.", 24, V17_PURPLE)
    _text(Vector2(410, 520), "DENEME %d — AYNI SES AYNI ANLAMA GELMEYEBİLİR." % a, 18, V17_MUTED)

    var first_a := _spikes(Vector2(1180, 612), 3, true)
    var first_b := _spikes(Vector2(1450, 612), 3, true)
    _trigger(Rect2(650, 390, 120, 240), func():
        if _once("153_open"):
            var real_warning := a % 2 == 1
            _audio_warning(not real_warning)
            if real_warning:
                var target := first_a if a % 3 != 0 else first_b
                var tw := create_tween()
                tw.tween_interval(0.42)
                tw.tween_callback(func(): _reveal(target))
                tw.tween_interval(0.44)
                tw.tween_callback(func(): _hide(target))
            else:
                _false_alarm()
    )

    _moving_platform(Vector2(1820, 555), Vector2(150, 24), Vector2(1860, 470), 1.34, V17_CYAN)

    _route_hint(Vector2(2380, 500), "A")
    _route_hint(Vector2(2380, 390), "B")
    _platform(Vector2(2490, 465), Vector2(230, 24), V17_BLUE)
    _platform(Vector2(2780, 435), Vector2(210, 24), V17_BLUE)
    _trigger(Rect2(2270, 315, 220, 175), func():
        if _choose_route("upper"):
            _audio_warning(a % 3 != 0)
    )
    _trigger(Rect2(2270, 500, 220, 150), func():
        if _choose_route("lower"):
            _audio_warning(a % 3 == 0)
    )

    var route_gate := _hidden_hazard(Vector2(3370, 530), Vector2(28, 230), V17_RED)
    _trigger(Rect2(3070, 390, 120, 240), func():
        if _once("153_route"):
            var fire := (route_choice == "upper" and a % 3 == 0) or (route_choice == "lower" and a % 3 != 0)
            if fire:
                var tw := create_tween()
                tw.tween_interval(0.34)
                tw.tween_callback(func(): _reveal(route_gate))
                tw.tween_interval(0.42)
                tw.tween_callback(func(): _hide(route_gate))
            else:
                _false_alarm()
    )

    _moving_platform(Vector2(4180, 555), Vector2(145, 24), Vector2(4220, 470), 1.28, V17_BLUE)

    var silent := _spikes(Vector2(4800, 612), 3, true)
    _trigger(Rect2(4500, 390, 120, 240), func():
        if _once("153_silent"):
            if a % 2 == 0:
                _silent_notice("BU SEFER SES YOK")
                _timed_hazard(silent, 0.30, 0.45, "153_silent_hazard")
            else:
                _audio_warning(true)
                _false_alarm()
    )

    _trigger(Rect2(5360, 390, 120, 240), func():
        if _once("153_reverse") and a % 3 == 1:
            _audio_warning(false)
            _reverse_controls(0.72)
    )

    _trigger(Rect2(5820, 390, 120, 240), func():
        if _once("153_rock"):
            var tw := create_tween()
            tw.tween_interval(0.42)
            tw.tween_callback(func(): _boulder(Vector2(6500, 560), -355.0, 70.0))
    )

    _moving_platform(Vector2(6360, 555), Vector2(140, 24), Vector2(6400, 470), 1.26, V17_CYAN)

    var last := _spikes(Vector2(7040, 612), 3, true)
    _trigger(Rect2(6750, 390, 120, 240), func():
        if _once("153_last"):
            var warning_is_real := (a + int(route_choice == "upper")) % 2 == 0
            _audio_warning(not warning_is_real)
            if warning_is_real:
                _timed_hazard(last, 0.38, 0.43, "153_last_hazard")
            else:
                _false_alarm()
    )

    var goal := _finish(Vector2(7650, 580))
    _trigger(Rect2(7380, 390, 120, 240), func():
        if _once("153_goal") and a % 3 == 1:
            create_tween().tween_property(goal, "position:x", 7770.0, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )
