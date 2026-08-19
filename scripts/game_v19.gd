extends "res://scripts/game_v18.gd"

const V19_BG := Color("#edf1f6")
const V19_BG_CH17 := Color("#e9edf2")
const V19_INK := Color("#111827")
const V19_SLATE := Color("#475569")
const V19_MUTED := Color("#64748b")
const V19_BLUE := Color("#2563eb")
const V19_CYAN := Color("#0891b2")
const V19_GREEN := Color("#16a34a")
const V19_AMBER := Color("#d97706")
const V19_RED := Color("#dc4455")
const V19_RED_DARK := Color("#7f2937")
const V19_PURPLE := Color("#7c3aed")

func _safe_load_progress() -> void:
    super._safe_load_progress()
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return
    var stored_unlock = cfg.get_value("progress", "unlocked_chapter", 1)
    if stored_unlock is int or stored_unlock is float:
        unlocked_chapter = clampi(int(stored_unlock), 1, 18)

func _start_level(c: int, p: int) -> void:
    super._start_level(c, p)
    if c == 17:
        RenderingServer.set_default_clear_color(V19_BG_CH17)
        _add_chapter17_decor()

func _build_level(c: int, p: int) -> void:
    if c == 17 and p == 1:
        _level_17_1()
    elif c == 17 and p == 2:
        _level_17_2()
    elif c == 17 and p == 3:
        _level_17_3()
    else:
        super._build_level(c, p)

func _build_hud() -> void:
    super._build_hud()
    if chapter == 17:
        var mode := Label.new()
        mode.position = Vector2(720, 18)
        mode.size = Vector2(275, 38)
        mode.text = "ALIŞKANLIK / TERSİ"
        mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        mode.add_theme_font_size_override("font_size", 16)
        mode.add_theme_color_override("font_color", V19_PURPLE)
        hud.add_child(mode)

func _show_main_menu() -> void:
    active_map_key = ""
    timer_label = null
    RenderingServer.set_default_clear_color(V19_BG)
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
    bg.color = V19_BG
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(bg)

    var top_band := ColorRect.new()
    top_band.size = Vector2(1280, 92)
    top_band.color = V19_INK
    top_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(top_band)

    var version := Label.new()
    version.position = Vector2(24, 27)
    version.size = Vector2(250, 40)
    version.text = "ANDROID • v1.9"
    version.add_theme_font_size_override("font_size", 18)
    version.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(version)

    var records := Label.new()
    records.position = Vector2(925, 27)
    records.size = Vector2(325, 40)
    records.text = "KAYITLI REKOR: %d / 51" % best_times_ms.size()
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
    title.add_theme_color_override("font_color", V19_INK)
    hud.add_child(title)

    var subtitle := Label.new()
    subtitle.position = Vector2(205, 202)
    subtitle.size = Vector2(870, 58)
    subtitle.text = "Bölüm 17: Öğrendiğin güvenli davranışlar artık tek başına yeterli değil."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 20)
    subtitle.add_theme_color_override("font_color", V19_MUTED)
    hud.add_child(subtitle)

    var progress := Label.new()
    progress.position = Vector2(255, 276)
    progress.size = Vector2(770, 44)
    var available := maxi(1, mini(unlocked_chapter, 17))
    var completed_maps := maxi(0, (mini(unlocked_chapter, 18) - 1) * 3)
    progress.text = "AÇIK BÖLÜM: %d / 17     HARİTA: %d / 51     ÖLÜM: %d" % [available, completed_maps, deaths]
    progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    progress.add_theme_font_size_override("font_size", 19)
    progress.add_theme_color_override("font_color", V19_RED_DARK)
    hud.add_child(progress)

    _menu_button("DEVAM ET", Vector2(440, 350), Vector2(400, 72), func(): _start_level(maxi(1, mini(unlocked_chapter, 17)), 1))
    _menu_button("BÖLÜMLER", Vector2(440, 440), Vector2(400, 72), func(): _show_chapter_select())
    _menu_button("1. BÖLÜMDEN BAŞLA", Vector2(440, 530), Vector2(400, 72), func(): _start_level(1, 1))

    var warning := Label.new()
    warning.position = Vector2(170, 630)
    warning.size = Vector2(940, 40)
    warning.text = "Önceki kurallar tamamen silinmez; yalnızca hangi durumda geçerli oldukları değişir."
    warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    warning.add_theme_font_size_override("font_size", 17)
    warning.add_theme_color_override("font_color", V19_MUTED)
    hud.add_child(warning)
    _polish_menu_surface()

func _show_chapter_select() -> void:
    timer_label = null
    RenderingServer.set_default_clear_color(V19_BG)
    if is_instance_valid(hud):
        hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)

    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V19_BG
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(240, 12)
    title.size = Vector2(800, 52)
    title.text = "BÖLÜM SEÇ"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", V19_INK)
    hud.add_child(title)

    var info := Label.new()
    info.position = Vector2(150, 55)
    info.size = Vector2(980, 30)
    info.text = "17 bölüm • 51 harita • Süre ve ölüm rekorları aktif"
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.add_theme_font_size_override("font_size", 16)
    info.add_theme_color_override("font_color", V19_MUTED)
    hud.add_child(info)

    for i in range(1, 18):
        var chapter_id := i
        var is_unlocked := chapter_id <= unlocked_chapter
        var col := (i - 1) % 4
        var row := int((i - 1) / 4)
        var pos := Vector2(55 + col * 300, 91 + row * 76)
        var suffix := "3 HARİTA"
        if chapter_id == 5: suffix = "HAFIZA"
        elif chapter_id == 6: suffix = "HAREKET"
        elif chapter_id == 7: suffix = "GÜVEN"
        elif chapter_id == 8: suffix = "ZAMAN"
        elif chapter_id == 9: suffix = "ROTA"
        elif chapter_id == 10: suffix = "MİNİ FİNAL"
        elif chapter_id == 11: suffix = "REAKTİF"
        elif chapter_id == 12: suffix = "TEMPO"
        elif chapter_id == 13: suffix = "KAYAN GÜVEN"
        elif chapter_id == 14: suffix = "ALGI"
        elif chapter_id == 15: suffix = "SES"
        elif chapter_id == 16: suffix = "GİRDİ"
        elif chapter_id == 17: suffix = "ALIŞKANLIK"
        var button_text := "BÖLÜM %d\n%s" % [chapter_id, suffix] if is_unlocked else "BÖLÜM %d\nKİLİTLİ" % chapter_id
        var button := _menu_button(button_text, pos, Vector2(270, 58), func(): _start_level(chapter_id, 1))
        button.disabled = not is_unlocked

    var note := Label.new()
    note.position = Vector2(170, 480)
    note.size = Vector2(940, 34)
    note.text = "Bölüm 17 güven, ses, rota ve girdi alışkanlıklarını yeni bağlamlarda tersine çevirir."
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    note.add_theme_font_size_override("font_size", 16)
    note.add_theme_color_override("font_color", V19_MUTED)
    hud.add_child(note)

    _menu_button("GERİ", Vector2(490, 525), Vector2(300, 60), func(): _show_main_menu())
    _polish_menu_surface()

func _show_chapter_result() -> void:
    if chapter != 17:
        super._show_chapter_result()
        return
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
    bg.color = V19_INK
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(160, 62)
    title.size = Vector2(960, 300)
    title.text = "BÖLÜM 17 TAMAMLANDI\n\nTOPLAM ÖLÜM: %d\nTAMAMLANAN HARİTA: 51 / 51" % deaths
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(title)

    var stats := Label.new()
    stats.position = Vector2(125, 350)
    stats.size = Vector2(1030, 145)
    stats.text = "17-1  %s / %s ölüm     17-2  %s / %s ölüm     17-3  %s / %s ölüm\n\n51 HARİTA TAMAM" % [
        _best_time_text(17, 1), _best_deaths_text(17, 1),
        _best_time_text(17, 2), _best_deaths_text(17, 2),
        _best_time_text(17, 3), _best_deaths_text(17, 3)
    ]
    stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    stats.add_theme_font_size_override("font_size", 19)
    stats.add_theme_color_override("font_color", V19_PURPLE)
    hud.add_child(stats)

    _menu_button("ANA MENÜ", Vector2(490, 555), Vector2(300, 64), func(): _show_main_menu())

func _habit_notice(text: String, color: Color = V19_PURPLE) -> void:
    _troll_popup(text, color)
    _play_tone(500.0, 0.07, 0.10)

func _add_chapter17_decor() -> void:
    if not is_instance_valid(world):
        return
    var horizon := Line2D.new()
    horizon.width = 2.0
    horizon.default_color = Color(0.31, 0.20, 0.55, 0.08)
    horizon.points = PackedVector2Array([Vector2(0, 438), Vector2(level_width, 438)])
    horizon.z_index = -24
    world.add_child(horizon)
    for i in range(19):
        var x := 140.0 + float(i) * 390.0
        var mark := Line2D.new()
        mark.width = 2.0
        mark.default_color = Color(0.31, 0.20, 0.55, 0.05)
        if i % 2 == 0:
            mark.points = PackedVector2Array([Vector2(x - 30, 420), Vector2(x, 390), Vector2(x + 30, 420)])
        else:
            mark.points = PackedVector2Array([Vector2(x - 30, 395), Vector2(x, 425), Vector2(x + 30, 395)])
        mark.z_index = -23
        world.add_child(mark)

func _pulse_spikes(spikes: Area2D, delay: float, live_time: float) -> void:
    var tw := create_tween()
    tw.tween_interval(delay)
    tw.tween_callback(func(): _reveal(spikes))
    tw.tween_interval(live_time)
    tw.tween_callback(func(): _hide(spikes))

func _level_17_1() -> void:
    _floor_with_gaps(6900, [Vector2(1900, 2060), Vector2(4520, 4680)])
    _text(Vector2(120, 470), "BÖLÜM 17: ALIŞKANLIK GÜVENLİK DEĞİL.", 23, V19_PURPLE)
    _text(Vector2(430, 520), "AYNI İŞARET, YENİ BAĞLAM.", 18, V19_MUTED)

    var first_safe := _safe_pad(Vector2(910, 548), 190.0)
    _trigger(Rect2(680, 390, 120, 240), func():
        if _once("171_first_safe"):
            _false_alarm()
            create_tween().tween_property(first_safe, "position:y", 545.0, 0.12)
    )

    var second_safe := _safe_pad(Vector2(1410, 548), 190.0)
    _trigger(Rect2(1170, 390, 120, 240), func():
        if _once("171_second_safe"):
            _habit_notice("GÜVENİ KOPYALAMA")
            _delayed_platform_drop(second_safe, 0.50, 300.0)
    )

    _moving_platform(Vector2(1980, 555), Vector2(150, 24), Vector2(2020, 470), 1.36, V19_BLUE)

    var warning_spikes := _spikes(Vector2(2700, 612), 3, true)
    _trigger(Rect2(2380, 390, 120, 240), func():
        if _once("171_audio_fake"):
            _play_tone(820.0, 0.09, 0.12)
            _false_alarm()
    )
    _trigger(Rect2(2920, 390, 120, 240), func():
        if _once("171_silent_real"):
            _pulse_spikes(warning_spikes, 0.24, 0.44)
    )

    var high := _platform(Vector2(3560, 455), Vector2(210, 24), V19_BLUE)
    _platform(Vector2(3300, 520), Vector2(190, 24), V19_SLATE)
    _trigger(Rect2(3190, 315, 220, 175), func():
        if _choose_route("upper"):
            _habit_notice("YÜKSEK = GÜVENLİ DEĞİL", V19_AMBER)
            _delayed_platform_drop(high, 0.48, 250.0)
    )
    _trigger(Rect2(3190, 500, 220, 150), func():
        if _choose_route("lower"):
            _false_alarm()
    )

    _moving_platform(Vector2(4600, 555), Vector2(145, 24), Vector2(4640, 470), 1.30, V19_CYAN)

    _trigger(Rect2(5050, 390, 120, 240), func():
        if _once("171_rock"):
            _play_tone(350.0, 0.06, 0.08)
            var tw := create_tween()
            tw.tween_interval(0.44)
            tw.tween_callback(func(): _boulder(Vector2(5660, 560), -365.0, 70.0))
    )

    var end_safe := _safe_pad(Vector2(6040, 548), 185.0)
    _trigger(Rect2(5800, 390, 120, 240), func():
        if _once("171_end_safe"):
            _false_alarm()
            create_tween().tween_property(end_safe, "position:x", 6044.0, 0.12)
    )
    _finish(Vector2(6570, 580))

func _level_17_2() -> void:
    _floor_with_gaps(7350, [Vector2(1780, 1940), Vector2(4860, 5020)])
    _text(Vector2(120, 470), "BİP = TUZAK DEĞİLDİ. ŞİMDİ BAZEN ÖYLE.", 22, V19_PURPLE)
    _text(Vector2(430, 520), "SESSİZLİK DE GÜVENLİK DEĞİL.", 18, V19_MUTED)

    var first := _spikes(Vector2(1120, 612), 3, true)
    _trigger(Rect2(760, 390, 120, 240), func():
        if _once("172_beep_real"):
            _play_tone(840.0, 0.09, 0.12)
            _pulse_spikes(first, 0.32, 0.44)
    )

    _moving_platform(Vector2(1860, 555), Vector2(150, 24), Vector2(1900, 470), 1.34, V19_BLUE)

    var silent_drop := _platform(Vector2(2600, 548), Vector2(195, 26), V19_SLATE)
    _trigger(Rect2(2360, 390, 120, 240), func():
        if _once("172_silent_drop"):
            _delayed_platform_drop(silent_drop, 0.48, 300.0)
    )

    _trigger(Rect2(3180, 390, 120, 240), func():
        if _once("172_reverse_fake"):
            _habit_notice("TERS?", V19_CYAN)
            _false_alarm()
    )

    var real_reverse_gate := _hazard_block(Vector2(3900, 220), Vector2(150, 72), V19_RED_DARK)
    _trigger(Rect2(3540, 390, 120, 240), func():
        if _once("172_reverse_real"):
            _reverse_controls(0.70)
            var tw := create_tween()
            tw.tween_interval(0.30)
            tw.tween_property(real_reverse_gate, "position:y", 500.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_interval(0.18)
            tw.tween_property(real_reverse_gate, "position:y", 220.0, 0.50).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

    _trigger(Rect2(4300, 390, 300, 240), func():
        _wait_check(4470.0, 145.0, 0.96, func():
            _habit_notice("BU KEZ BEKLEMEK GÜVENLİ", V19_GREEN)
            _false_alarm()
        , "172_wait_safe")
    )

    _moving_platform(Vector2(4940, 555), Vector2(145, 24), Vector2(4980, 470), 1.30, V19_CYAN)

    _trigger(Rect2(5400, 390, 120, 240), func():
        if _once("172_fall"):
            _falling_boulder(Vector2(5660, 20), 56.0, 0.0)
            _falling_boulder(Vector2(5910, -20), 50.0, 0.42)
    )

    var last := _spikes(Vector2(6420, 612), 3, true)
    _trigger(Rect2(6110, 390, 120, 240), func():
        if _once("172_last"):
            _play_tone(300.0, 0.06, 0.08)
            _pulse_spikes(last, 0.38, 0.46)
    )

    _finish(Vector2(7040, 580))

func _level_17_3() -> void:
    _floor_with_gaps(8150, [Vector2(1680, 1840), Vector2(3890, 4050), Vector2(6180, 6340)])
    var a := _attempt(17, 3)
    _text(Vector2(120, 470), "ALIŞKANLIĞINI HATIRLIYORUM.", 24, V19_PURPLE)
    _text(Vector2(430, 520), "DENEME %d — KURAL DEĞİL, DESEN ÖĞREN." % a, 18, V19_MUTED)

    var safe_a := _safe_pad(Vector2(900, 548), 185.0)
    var safe_b := _safe_pad(Vector2(1320, 548), 185.0)
    _trigger(Rect2(660, 390, 120, 240), func():
        if _once("173_safe_pair"):
            if a % 2 == 0:
                _false_alarm()
                _delayed_platform_drop(safe_b, 0.54, 295.0)
            else:
                _false_alarm()
                _delayed_platform_drop(safe_a, 0.54, 295.0)
    )

    _moving_platform(Vector2(1760, 555), Vector2(150, 24), Vector2(1800, 470), 1.34, V19_CYAN)

    _route_hint(Vector2(2410, 500), "A")
    _route_hint(Vector2(2410, 390), "B")
    _platform(Vector2(2520, 465), Vector2(230, 24), V19_BLUE)
    _platform(Vector2(2810, 435), Vector2(210, 24), V19_BLUE)
    _trigger(Rect2(2300, 315, 220, 175), func():
        if _choose_route("upper"):
            if a % 3 == 0:
                _habit_notice("B BU KEZ DOĞRU", V19_AMBER)
            else:
                _false_alarm()
    )
    _trigger(Rect2(2300, 500, 220, 150), func():
        if _choose_route("lower"):
            if a % 3 == 1:
                _habit_notice("A BU KEZ DOĞRU", V19_CYAN)
            else:
                _false_alarm()
    )

    var route_spikes := _spikes(Vector2(3370, 612), 3, true)
    _trigger(Rect2(3090, 390, 120, 240), func():
        if _once("173_route_result"):
            var punish := (route_choice == "upper" and a % 3 == 0) or (route_choice == "lower" and a % 3 == 1)
            if punish:
                _pulse_spikes(route_spikes, 0.30, 0.44)
            else:
                _false_alarm()
    )

    _moving_platform(Vector2(3970, 555), Vector2(145, 24), Vector2(4010, 470), 1.28, V19_BLUE)

    _trigger(Rect2(4450, 390, 120, 240), func():
        if _once("173_audio"):
            _play_tone(830.0, 0.09, 0.12)
            if a % 2 == 0:
                _false_alarm()
            else:
                _reverse_controls(0.68)
    )

    var wait_spikes := _spikes(Vector2(5210, 612), 3, true)
    _trigger(Rect2(4920, 390, 300, 240), func():
        _wait_check(5070.0, 145.0, 0.94, func():
            if a % 3 == 2:
                _false_alarm()
            else:
                _pulse_spikes(wait_spikes, 0.10, 0.42)
        , "173_wait")
    )

    _moving_platform(Vector2(6260, 555), Vector2(145, 24), Vector2(6300, 470), 1.28, V19_CYAN)

    _trigger(Rect2(6690, 390, 120, 240), func():
        if _once("173_rock"):
            if a % 2 == 0:
                _habit_notice("SES VAR, KAYA YOK", V19_GREEN)
                _play_tone(330.0, 0.06, 0.08)
            else:
                var tw := create_tween()
                tw.tween_interval(0.42)
                tw.tween_callback(func(): _boulder(Vector2(7300, 560), -360.0, 70.0))
    )

    var finish_pad := _safe_pad(Vector2(7510, 548), 180.0)
    _trigger(Rect2(7280, 390, 120, 240), func():
        if _once("173_finish_pad"):
            if a % 3 == 0:
                _delayed_platform_drop(finish_pad, 0.56, 285.0)
            else:
                _false_alarm()
    )

    _finish(Vector2(7860, 580))
