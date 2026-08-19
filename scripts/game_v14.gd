extends "res://scripts/game_v13.gd"

const V14_BG := Color("#edf1f6")
const V14_BG_CH12 := Color("#e7ebf2")
const V14_INK := Color("#111827")
const V14_SLATE := Color("#475569")
const V14_MUTED := Color("#64748b")
const V14_BLUE := Color("#2563eb")
const V14_CYAN := Color("#0891b2")
const V14_GREEN := Color("#16a34a")
const V14_AMBER := Color("#d97706")
const V14_RED := Color("#dc4455")
const V14_RED_DARK := Color("#7f2937")
const V14_PURPLE := Color("#7c3aed")

var best_times_ms: Dictionary = {}
var best_deaths: Dictionary = {}
var level_start_msec: int = 0
var map_session_deaths_start: int = 0
var active_map_key := ""
var timer_label: Label
var last_result_time_ms: int = 0
var last_result_deaths: int = 0

func _safe_load_progress() -> void:
    super._safe_load_progress()
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return

    var stored_unlock = cfg.get_value("progress", "unlocked_chapter", 1)
    if stored_unlock is int or stored_unlock is float:
        unlocked_chapter = clampi(int(stored_unlock), 1, 13)

    var stored_times = cfg.get_value("records", "best_times_ms", {})
    if stored_times is Dictionary:
        best_times_ms = stored_times.duplicate(true)

    var stored_deaths = cfg.get_value("records", "best_deaths", {})
    if stored_deaths is Dictionary:
        best_deaths = stored_deaths.duplicate(true)

func _save() -> void:
    super._save()
    var cfg := ConfigFile.new()
    cfg.load(SAVE_PATH)
    cfg.set_value("records", "best_times_ms", best_times_ms)
    cfg.set_value("records", "best_deaths", best_deaths)
    cfg.save(SAVE_PATH)

func _map_key(c: int = chapter, p: int = part) -> String:
    return "%d-%d" % [c, p]

func _start_level(c: int, p: int) -> void:
    var next_key := _map_key(c, p)
    if active_map_key != next_key or level_finished:
        active_map_key = next_key
        map_session_deaths_start = deaths
    level_start_msec = Time.get_ticks_msec()
    timer_label = null
    super._start_level(c, p)
    if c == 12:
        RenderingServer.set_default_clear_color(V14_BG_CH12)
        _add_chapter12_decor()

func _process(delta: float) -> void:
    super._process(delta)
    if is_instance_valid(timer_label) and level_start_msec > 0 and not level_finished:
        timer_label.text = "SÜRE  %s" % _format_time_ms(_elapsed_attempt_ms())

func _elapsed_attempt_ms() -> int:
    if level_start_msec <= 0:
        return 0
    return maxi(0, Time.get_ticks_msec() - level_start_msec)

func _format_time_ms(ms: int) -> String:
    var total_cs := maxi(0, int(ms / 10))
    var minutes := int(total_cs / 6000)
    var seconds := int((total_cs / 100) % 60)
    var centiseconds := int(total_cs % 100)
    return "%02d:%02d.%02d" % [minutes, seconds, centiseconds]

func _pace_fast(limit_ms: int) -> bool:
    return _elapsed_attempt_ms() <= limit_ms

func _record_map_result() -> void:
    var key := _map_key()
    last_result_time_ms = _elapsed_attempt_ms()
    last_result_deaths = maxi(0, deaths - map_session_deaths_start)

    if not best_times_ms.has(key) or last_result_time_ms < int(best_times_ms[key]):
        best_times_ms[key] = last_result_time_ms
    if not best_deaths.has(key) or last_result_deaths < int(best_deaths[key]):
        best_deaths[key] = last_result_deaths
    _save()

func _best_time_text(c: int, p: int) -> String:
    var key := _map_key(c, p)
    if not best_times_ms.has(key):
        return "--:--.--"
    return _format_time_ms(int(best_times_ms[key]))

func _best_deaths_text(c: int, p: int) -> String:
    var key := _map_key(c, p)
    if not best_deaths.has(key):
        return "-"
    return str(int(best_deaths[key]))

func _build_hud() -> void:
    super._build_hud()

    timer_label = Label.new()
    timer_label.name = "TimerLabel"
    timer_label.position = Vector2(355, 18)
    timer_label.size = Vector2(190, 38)
    timer_label.text = "SÜRE  00:00.00"
    timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    timer_label.add_theme_font_size_override("font_size", 18)
    timer_label.add_theme_color_override("font_color", V14_SLATE)
    hud.add_child(timer_label)

    if chapter == 12:
        var mode := Label.new()
        mode.position = Vector2(720, 18)
        mode.size = Vector2(275, 38)
        mode.text = "RİTİM / TEMPO"
        mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        mode.add_theme_font_size_override("font_size", 16)
        mode.add_theme_color_override("font_color", V14_AMBER)
        hud.add_child(mode)

func _show_main_menu() -> void:
    active_map_key = ""
    timer_label = null
    RenderingServer.set_default_clear_color(V14_BG)
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
    bg.color = V14_BG
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(bg)

    var top_band := ColorRect.new()
    top_band.size = Vector2(1280, 92)
    top_band.color = V14_INK
    top_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(top_band)

    var version := Label.new()
    version.position = Vector2(24, 27)
    version.size = Vector2(250, 40)
    version.text = "ANDROID • v1.4"
    version.add_theme_font_size_override("font_size", 18)
    version.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(version)

    var records := Label.new()
    records.position = Vector2(925, 27)
    records.size = Vector2(325, 40)
    records.text = "KAYITLI REKOR: %d / 36" % best_times_ms.size()
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
    title.add_theme_color_override("font_color", V14_INK)
    hud.add_child(title)

    var subtitle := Label.new()
    subtitle.position = Vector2(205, 202)
    subtitle.size = Vector2(870, 58)
    subtitle.text = "Bölüm 12: Hızın da beklemen de oyunun kullanabileceği bir karar."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 20)
    subtitle.add_theme_color_override("font_color", V14_MUTED)
    hud.add_child(subtitle)

    var progress := Label.new()
    progress.position = Vector2(255, 276)
    progress.size = Vector2(770, 44)
    var available := maxi(1, mini(unlocked_chapter, 12))
    var completed_maps := maxi(0, (mini(unlocked_chapter, 13) - 1) * 3)
    progress.text = "AÇIK BÖLÜM: %d / 12     HARİTA: %d / 36     ÖLÜM: %d" % [available, completed_maps, deaths]
    progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    progress.add_theme_font_size_override("font_size", 19)
    progress.add_theme_color_override("font_color", V14_RED_DARK)
    hud.add_child(progress)

    _menu_button("DEVAM ET", Vector2(440, 350), Vector2(400, 72), func():
        _start_level(maxi(1, mini(unlocked_chapter, 12)), 1)
    )
    _menu_button("BÖLÜMLER", Vector2(440, 440), Vector2(400, 72), func():
        _show_chapter_select()
    )
    _menu_button("1. BÖLÜMDEN BAŞLA", Vector2(440, 530), Vector2(400, 72), func():
        _start_level(1, 1)
    )

    var warning := Label.new()
    warning.position = Vector2(195, 630)
    warning.size = Vector2(890, 40)
    warning.text = "Her haritanın en iyi süresi ve en az ölüm kaydı artık cihazda saklanıyor."
    warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    warning.add_theme_font_size_override("font_size", 17)
    warning.add_theme_color_override("font_color", V14_MUTED)
    hud.add_child(warning)
    _polish_menu_surface()

func _show_chapter_select() -> void:
    timer_label = null
    RenderingServer.set_default_clear_color(V14_BG)
    if is_instance_valid(hud):
        hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)

    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V14_BG
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(240, 24)
    title.size = Vector2(800, 62)
    title.text = "BÖLÜM SEÇ"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 40)
    title.add_theme_color_override("font_color", V14_INK)
    hud.add_child(title)

    var info := Label.new()
    info.position = Vector2(150, 82)
    info.size = Vector2(980, 38)
    info.text = "12 bölüm • 36 harita • Süre ve ölüm rekorları aktif"
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.add_theme_font_size_override("font_size", 18)
    info.add_theme_color_override("font_color", V14_MUTED)
    hud.add_child(info)

    for i in range(1, 13):
        var chapter_id := i
        var is_unlocked := chapter_id <= unlocked_chapter
        var col := (i - 1) % 4
        var row := int((i - 1) / 4)
        var pos := Vector2(55 + col * 300, 140 + row * 108)
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
        var button_text := "BÖLÜM %d\n%s" % [chapter_id, suffix] if is_unlocked else "BÖLÜM %d\nKİLİTLİ" % chapter_id
        var button := _menu_button(button_text, pos, Vector2(270, 78), func():
            _start_level(chapter_id, 1)
        )
        button.disabled = not is_unlocked

    var note := Label.new()
    note.position = Vector2(190, 480)
    note.size = Vector2(900, 38)
    note.text = "Bölüm 12 acele etmeni ve fazla temkinli oynamanı farklı şekillerde cezalandırabilir."
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    note.add_theme_font_size_override("font_size", 16)
    note.add_theme_color_override("font_color", V14_MUTED)
    hud.add_child(note)

    _menu_button("GERİ", Vector2(490, 535), Vector2(300, 64), func():
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
    bg.color = V14_INK
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(160, 72)
    title.size = Vector2(960, 310)
    var map_count := mini(chapter * 3, 36)
    title.text = "BÖLÜM %d TAMAMLANDI\n\nTOPLAM ÖLÜM: %d\nTAMAMLANAN HARİTA: %d / 36" % [chapter, deaths, map_count]
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(title)

    if chapter < 12:
        var next_chapter := chapter + 1
        _menu_button("SONRAKİ BÖLÜM", Vector2(440, 430), Vector2(400, 72), func():
            _start_level(next_chapter, 1)
        )
    else:
        var stats := Label.new()
        stats.position = Vector2(150, 365)
        stats.size = Vector2(980, 130)
        stats.text = "12-1  %s / %s ölüm     12-2  %s / %s ölüm     12-3  %s / %s ölüm" % [
            _best_time_text(12, 1), _best_deaths_text(12, 1),
            _best_time_text(12, 2), _best_deaths_text(12, 2),
            _best_time_text(12, 3), _best_deaths_text(12, 3)
        ]
        stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        stats.add_theme_font_size_override("font_size", 19)
        stats.add_theme_color_override("font_color", V14_AMBER)
        hud.add_child(stats)

    _menu_button("ANA MENÜ", Vector2(490, 545), Vector2(300, 68), func():
        _show_main_menu()
    )

func _finish_level() -> void:
    if level_finished or restarting:
        return
    level_finished = true
    player.input_enabled = false
    _record_map_result()
    Input.vibrate_handheld(40)
    _play_tone(880.0, 0.20, 0.20)

    var banner := Label.new()
    banner.position = Vector2(300, 190)
    banner.size = Vector2(680, 220)
    banner.text = "%d-%d TAMAMLANDI\n\nSÜRE  %s     ÖLÜM  %d\nREKOR  %s / %s ölüm" % [
        chapter, part,
        _format_time_ms(last_result_time_ms), last_result_deaths,
        _best_time_text(chapter, part), _best_deaths_text(chapter, part)
    ]
    banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    banner.add_theme_font_size_override("font_size", 28)
    banner.add_theme_color_override("font_color", V14_GREEN)
    hud.add_child(banner)

    await get_tree().create_timer(1.05).timeout

    if part < 3:
        _start_level(chapter, part + 1)
        return

    unlocked_chapter = maxi(unlocked_chapter, chapter + 1)
    _save()
    _show_chapter_result()

func _build_level(c: int, p: int) -> void:
    if c == 12 and p == 1:
        _level_12_1()
    elif c == 12 and p == 2:
        _level_12_2()
    elif c == 12 and p == 3:
        _level_12_3()
    else:
        super._build_level(c, p)

func _add_chapter12_decor() -> void:
    if not is_instance_valid(world):
        return

    var horizon := Line2D.new()
    horizon.width = 2.0
    horizon.default_color = Color(0.12, 0.27, 0.48, 0.10)
    horizon.points = PackedVector2Array([Vector2(0, 438), Vector2(level_width, 438)])
    horizon.z_index = -24
    world.add_child(horizon)

    for i in range(22):
        var x := 120.0 + float(i) * 330.0
        var tick := Line2D.new()
        tick.width = 2.0 if i % 4 != 0 else 4.0
        tick.default_color = Color(0.12, 0.27, 0.48, 0.055 if i % 4 != 0 else 0.09)
        tick.points = PackedVector2Array([Vector2(x, 385), Vector2(x, 438)])
        tick.z_index = -23
        world.add_child(tick)

func _tempo_notice(text: String, color: Color = V14_AMBER) -> void:
    _troll_popup(text, color)
    _play_tone(470.0, 0.07, 0.10)

func _level_12_1() -> void:
    _floor_with_gaps(6400, [Vector2(1570, 1730), Vector2(4100, 4260)])
    _text(Vector2(120, 470), "BÖLÜM 12: AYNI PARKUR, FARKLI RİTİM.", 23, V14_AMBER)
    _text(Vector2(440, 520), "HIZLI OLMAK HER ZAMAN AVANTAJ DEĞİL.", 18, V14_MUTED)

    var rush_spikes := _spikes(Vector2(1080, 612), 3, true)
    _trigger(Rect2(650, 390, 130, 240), func():
        if _once("121_rush"):
            if _pace_fast(2800):
                _tempo_notice("ACELE")
                var tw := create_tween()
                tw.tween_interval(0.18)
                tw.tween_callback(func(): _reveal(rush_spikes))
                tw.tween_interval(0.46)
                tw.tween_callback(func(): _hide(rush_spikes))
            else:
                _false_alarm()
    )

    var suspicious := _platform(Vector2(1370, 548), Vector2(180, 26), V14_RED_DARK.lerp(V14_SLATE, 0.80))
    _trigger(Rect2(1190, 390, 120, 240), func():
        if _once("121_safe"):
            _false_alarm()
            create_tween().tween_property(suspicious, "position:y", 544.0, 0.12)
    )

    _moving_platform(Vector2(1650, 555), Vector2(150, 24), Vector2(1690, 470), 1.36, V14_BLUE)

    var slow_crusher := _hazard_block(Vector2(2550, 220), Vector2(150, 72), V14_RED_DARK)
    _trigger(Rect2(2260, 390, 120, 240), func():
        if _once("121_slow"):
            if not _pace_fast(7600):
                _tempo_notice("FAZLA TEMKİNLİ")
                var tw := create_tween()
                tw.tween_interval(0.26)
                tw.tween_property(slow_crusher, "position:y", 520.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
                tw.tween_interval(0.18)
                tw.tween_property(slow_crusher, "position:y", 220.0, 0.50).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
            else:
                _false_alarm()
    )

    var timed := _spikes(Vector2(3370, 612), 3, true)
    _trigger(Rect2(3090, 390, 120, 240), func():
        _timed_hazard(timed, 0.34, 0.48, "121_timed")
    )

    _moving_platform(Vector2(4180, 555), Vector2(145, 24), Vector2(4220, 472), 1.30, V14_CYAN)

    _trigger(Rect2(4710, 390, 120, 240), func():
        if _once("121_rock"):
            var tw := create_tween()
            tw.tween_interval(0.38)
            tw.tween_callback(func(): _boulder(Vector2(5350, 560), -380.0, 70.0))
    )

    var goal := _finish(Vector2(6060, 580))
    _trigger(Rect2(5750, 390, 120, 240), func():
        if _once("121_goal") and _pace_fast(17500):
            create_tween().tween_property(goal, "position:y", 505.0, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

func _level_12_2() -> void:
    _floor_with_gaps(6800, [Vector2(1830, 1990), Vector2(4650, 4810)])
    _text(Vector2(120, 470), "RİTİMİ BOZ.", 23, V14_AMBER)
    _text(Vector2(410, 520), "OYUN SENİN BEKLEMENİ DE ÖLÇÜYOR.", 18, V14_MUTED)

    var wait_spikes := _spikes(Vector2(1080, 612), 3, true)
    _trigger(Rect2(820, 390, 300, 240), func():
        _wait_check(980.0, 150.0, 1.05, func():
            _tempo_notice("ÇOK BEKLEDİN")
            _reveal(wait_spikes)
            var tw := create_tween()
            tw.tween_interval(0.46)
            tw.tween_callback(func(): _hide(wait_spikes))
        , "122_wait")
    )

    var plain := _platform(Vector2(1490, 548), Vector2(185, 26), V14_SLATE)
    _trigger(Rect2(1280, 390, 120, 240), func():
        if _once("122_plain"):
            _false_alarm()
            create_tween().tween_property(plain, "position:x", 1494.0, 0.12)
    )

    _moving_platform(Vector2(1910, 555), Vector2(150, 24), Vector2(1950, 470), 1.38, V14_CYAN)

    var drop := _platform(Vector2(2680, 548), Vector2(185, 26), V14_BLUE)
    _trigger(Rect2(2420, 390, 120, 240), func():
        if _once("122_pace_drop"):
            if _pace_fast(8200):
                _tempo_notice("ERKEN GELDİN")
                _delayed_platform_drop(drop, 0.42, 305.0)
            else:
                _false_alarm()
    )

    _trigger(Rect2(3200, 390, 120, 240), func():
        if _once("122_reverse") and _pace_fast(10800):
            _tempo_notice("RİTİM DEĞİŞTİ", V14_CYAN)
            _reverse_controls(0.78)
    )

    _trigger(Rect2(3790, 390, 120, 240), func():
        if _once("122_fall"):
            _falling_boulder(Vector2(4050, 20), 60.0, 0.0)
            _falling_boulder(Vector2(4300, -20), 52.0, 0.38)
    )

    _moving_platform(Vector2(4730, 555), Vector2(145, 24), Vector2(4770, 472), 1.32, V14_BLUE)

    var safe_red := _platform(Vector2(5290, 548), Vector2(180, 26), V14_RED_DARK.lerp(V14_SLATE, 0.78))
    _trigger(Rect2(5050, 390, 120, 240), func():
        if _once("122_safe_red"):
            _false_alarm()
            create_tween().tween_property(safe_red, "position:y", 544.0, 0.12)
    )

    var last := _spikes(Vector2(5850, 612), 3, true)
    _trigger(Rect2(5580, 390, 120, 240), func():
        _timed_hazard(last, 0.32, 0.46, "122_last")
    )

    _finish(Vector2(6500, 580))

func _level_12_3() -> void:
    _floor_with_gaps(7500, [Vector2(1660, 1820), Vector2(3720, 3880), Vector2(5750, 5910)])
    var a := _attempt(12, 3)
    var punish_fast := a % 2 == 1
    _text(Vector2(120, 470), "RİTİMİ HATIRLIYORUM.", 24, V14_PURPLE)
    _text(Vector2(420, 520), "DENEME %d — AYNI TEMPO AYNI SONUÇ DEĞİL." % a, 18, V14_MUTED)

    var first_fast := _spikes(Vector2(1080, 612), 3, true)
    var first_slow := _spikes(Vector2(1370, 612), 3, true)
    _trigger(Rect2(700, 390, 130, 240), func():
        if _once("123_first"):
            var arrived_fast := _pace_fast(3000)
            if arrived_fast == punish_fast:
                var target := first_fast if arrived_fast else first_slow
                _tempo_notice("RİTİM KAYDI")
                var tw := create_tween()
                tw.tween_interval(0.22)
                tw.tween_callback(func(): _reveal(target))
                tw.tween_interval(0.46)
                tw.tween_callback(func(): _hide(target))
            else:
                _false_alarm()
    )

    _moving_platform(Vector2(1740, 555), Vector2(150, 24), Vector2(1780, 470), 1.36, V14_CYAN)

    _route_hint(Vector2(2250, 500), "A")
    _route_hint(Vector2(2250, 390), "B")
    _platform(Vector2(2360, 465), Vector2(230, 24), V14_BLUE)
    _platform(Vector2(2650, 435), Vector2(210, 24), V14_BLUE)
    _trigger(Rect2(2140, 315, 220, 175), func():
        if _choose_route("upper"):
            _false_alarm()
    )
    _trigger(Rect2(2140, 500, 220, 150), func():
        if _choose_route("lower"):
            _tempo_notice("A")
    )

    var route_trap := _spikes(Vector2(3170, 612), 3, true)
    _trigger(Rect2(2910, 390, 120, 240), func():
        if _once("123_route"):
            var should_fire := (route_choice == "lower" and a % 3 != 0) or (route_choice == "upper" and a % 3 == 0)
            if should_fire:
                var tw := create_tween()
                tw.tween_interval(0.30)
                tw.tween_callback(func(): _reveal(route_trap))
                tw.tween_interval(0.46)
                tw.tween_callback(func(): _hide(route_trap))
            else:
                _false_alarm()
    )

    _moving_platform(Vector2(3800, 555), Vector2(145, 24), Vector2(3840, 472), 1.30, V14_BLUE)

    var wait_gate := _hazard_block(Vector2(4490, 220), Vector2(150, 72), V14_RED_DARK)
    _trigger(Rect2(4210, 390, 280, 240), func():
        _wait_check(4410.0, 150.0, 0.95, func():
            _tempo_notice("DURAKLADIN")
            var tw := create_tween()
            tw.tween_property(wait_gate, "position:y", 520.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_interval(0.18)
            tw.tween_property(wait_gate, "position:y", 220.0, 0.50).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        , "123_wait")
    )

    _trigger(Rect2(5010, 390, 120, 240), func():
        if _once("123_reverse") and a % 3 == 0:
            _reverse_controls(0.82)
    )

    _trigger(Rect2(5360, 390, 120, 240), func():
        if _once("123_rock"):
            var tw := create_tween()
            tw.tween_interval(0.40)
            tw.tween_callback(func(): _boulder(Vector2(6030, 560), -375.0, 70.0))
    )

    _moving_platform(Vector2(5830, 555), Vector2(140, 24), Vector2(5870, 470), 1.28, V14_CYAN)

    var final_gate := _spikes(Vector2(6500, 612), 3, true)
    _trigger(Rect2(6220, 390, 120, 240), func():
        if _once("123_final"):
            var late := not _pace_fast(19500 + (a % 3) * 900)
            if late == punish_fast:
                _false_alarm()
            else:
                _timed_hazard(final_gate, 0.28, 0.44, "123_final_hazard")
    )

    var goal := _finish(Vector2(7180, 580))
    _trigger(Rect2(6870, 390, 120, 240), func():
        if _once("123_goal") and a % 3 == 1:
            create_tween().tween_property(goal, "position:x", 7310.0, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )
