extends "res://scripts/game_v14.gd"

const V15_BG := Color("#edf1f6")
const V15_BG_CH13 := Color("#e9edf1")
const V15_INK := Color("#111827")
const V15_SLATE := Color("#475569")
const V15_MUTED := Color("#64748b")
const V15_BLUE := Color("#2563eb")
const V15_CYAN := Color("#0891b2")
const V15_GREEN := Color("#16a34a")
const V15_AMBER := Color("#d97706")
const V15_RED := Color("#dc4455")
const V15_RED_DARK := Color("#7f2937")
const V15_PURPLE := Color("#7c3aed")

func _safe_load_progress() -> void:
    super._safe_load_progress()
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return
    var stored_unlock = cfg.get_value("progress", "unlocked_chapter", 1)
    if stored_unlock is int or stored_unlock is float:
        unlocked_chapter = clampi(int(stored_unlock), 1, 14)

func _start_level(c: int, p: int) -> void:
    super._start_level(c, p)
    if c == 13:
        RenderingServer.set_default_clear_color(V15_BG_CH13)
        _add_chapter13_decor()

func _build_level(c: int, p: int) -> void:
    if c == 13 and p == 1:
        _level_13_1()
    elif c == 13 and p == 2:
        _level_13_2()
    elif c == 13 and p == 3:
        _level_13_3()
    else:
        super._build_level(c, p)

func _build_hud() -> void:
    super._build_hud()
    if chapter == 13:
        var mode := Label.new()
        mode.position = Vector2(720, 18)
        mode.size = Vector2(275, 38)
        mode.text = "KAYAN GÜVEN"
        mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        mode.add_theme_font_size_override("font_size", 16)
        mode.add_theme_color_override("font_color", V15_CYAN)
        hud.add_child(mode)

func _show_main_menu() -> void:
    active_map_key = ""
    timer_label = null
    RenderingServer.set_default_clear_color(V15_BG)
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
    bg.color = V15_BG
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(bg)

    var top_band := ColorRect.new()
    top_band.size = Vector2(1280, 92)
    top_band.color = V15_INK
    top_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(top_band)

    var version := Label.new()
    version.position = Vector2(24, 27)
    version.size = Vector2(250, 40)
    version.text = "ANDROID • v1.5"
    version.add_theme_font_size_override("font_size", 18)
    version.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(version)

    var records := Label.new()
    records.position = Vector2(925, 27)
    records.size = Vector2(325, 40)
    records.text = "KAYITLI REKOR: %d / 39" % best_times_ms.size()
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
    title.add_theme_color_override("font_color", V15_INK)
    hud.add_child(title)

    var subtitle := Label.new()
    subtitle.position = Vector2(205, 202)
    subtitle.size = Vector2(870, 58)
    subtitle.text = "Bölüm 13: Güvenli görünen alan aynı yerde kalmak zorunda değil."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 20)
    subtitle.add_theme_color_override("font_color", V15_MUTED)
    hud.add_child(subtitle)

    var progress := Label.new()
    progress.position = Vector2(255, 276)
    progress.size = Vector2(770, 44)
    var available := maxi(1, mini(unlocked_chapter, 13))
    var completed_maps := maxi(0, (mini(unlocked_chapter, 14) - 1) * 3)
    progress.text = "AÇIK BÖLÜM: %d / 13     HARİTA: %d / 39     ÖLÜM: %d" % [available, completed_maps, deaths]
    progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    progress.add_theme_font_size_override("font_size", 19)
    progress.add_theme_color_override("font_color", V15_RED_DARK)
    hud.add_child(progress)

    _menu_button("DEVAM ET", Vector2(440, 350), Vector2(400, 72), func():
        _start_level(maxi(1, mini(unlocked_chapter, 13)), 1)
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
    warning.text = "Aynı görünen iki alanın aynı davranması gerekmiyor. Her şüpheli alan da tuzak değil."
    warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    warning.add_theme_font_size_override("font_size", 17)
    warning.add_theme_color_override("font_color", V15_MUTED)
    hud.add_child(warning)
    _polish_menu_surface()

func _show_chapter_select() -> void:
    timer_label = null
    RenderingServer.set_default_clear_color(V15_BG)
    if is_instance_valid(hud):
        hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)

    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V15_BG
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(240, 20)
    title.size = Vector2(800, 58)
    title.text = "BÖLÜM SEÇ"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 38)
    title.add_theme_color_override("font_color", V15_INK)
    hud.add_child(title)

    var info := Label.new()
    info.position = Vector2(150, 73)
    info.size = Vector2(980, 34)
    info.text = "13 bölüm • 39 harita • Süre ve ölüm rekorları aktif"
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.add_theme_font_size_override("font_size", 17)
    info.add_theme_color_override("font_color", V15_MUTED)
    hud.add_child(info)

    for i in range(1, 14):
        var chapter_id := i
        var is_unlocked := chapter_id <= unlocked_chapter
        var col := (i - 1) % 4
        var row := int((i - 1) / 4)
        var pos := Vector2(55 + col * 300, 120 + row * 92)
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
        var button_text := "BÖLÜM %d\n%s" % [chapter_id, suffix] if is_unlocked else "BÖLÜM %d\nKİLİTLİ" % chapter_id
        var button := _menu_button(button_text, pos, Vector2(270, 70), func():
            _start_level(chapter_id, 1)
        )
        button.disabled = not is_unlocked

    var note := Label.new()
    note.position = Vector2(175, 505)
    note.size = Vector2(930, 36)
    note.text = "Bölüm 13 güvenli görünen pedleri, yön değiştiren platformları ve Troll Hafızasını birleştirir."
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    note.add_theme_font_size_override("font_size", 16)
    note.add_theme_color_override("font_color", V15_MUTED)
    hud.add_child(note)

    _menu_button("GERİ", Vector2(490, 555), Vector2(300, 60), func():
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
    bg.color = V15_INK
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(160, 62)
    title.size = Vector2(960, 300)
    var map_count := mini(chapter * 3, 39)
    title.text = "BÖLÜM %d TAMAMLANDI\n\nTOPLAM ÖLÜM: %d\nTAMAMLANAN HARİTA: %d / 39" % [chapter, deaths, map_count]
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(title)

    if chapter < 13:
        var next_chapter := chapter + 1
        _menu_button("SONRAKİ BÖLÜM", Vector2(440, 430), Vector2(400, 72), func():
            _start_level(next_chapter, 1)
        )
    else:
        var stats := Label.new()
        stats.position = Vector2(125, 350)
        stats.size = Vector2(1030, 145)
        stats.text = "13-1  %s / %s ölüm     13-2  %s / %s ölüm     13-3  %s / %s ölüm\n\n39 HARİTA TAMAM" % [
            _best_time_text(13, 1), _best_deaths_text(13, 1),
            _best_time_text(13, 2), _best_deaths_text(13, 2),
            _best_time_text(13, 3), _best_deaths_text(13, 3)
        ]
        stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        stats.add_theme_font_size_override("font_size", 19)
        stats.add_theme_color_override("font_color", V15_CYAN)
        hud.add_child(stats)

    _menu_button("ANA MENÜ", Vector2(490, 555), Vector2(300, 64), func():
        _show_main_menu()
    )

func _on_player_died() -> void:
    if restarting or level_finished:
        return
    _spawn_death_fragments()
    super._on_player_died()

func _spawn_death_fragments() -> void:
    if not is_instance_valid(player) or not is_instance_valid(world):
        return
    var origin := player.position
    for i in range(10):
        var shard := Polygon2D.new()
        var shard_size := 5.0 + float(i % 3) * 2.0
        shard.position = origin + Vector2(float((i % 5) - 2) * 4.0, float(int(i / 5) - 1) * 5.0)
        shard.polygon = PackedVector2Array([
            Vector2(-shard_size, -shard_size), Vector2(shard_size, -shard_size),
            Vector2(shard_size, shard_size), Vector2(-shard_size, shard_size)
        ])
        shard.color = V15_INK if i % 3 != 0 else V15_RED
        shard.z_index = 30
        world.add_child(shard)

        var angle := TAU * float(i) / 10.0 + 0.18 * float(i % 2)
        var distance := 58.0 + float((i * 17) % 45)
        var target := origin + Vector2(cos(angle), sin(angle)) * distance + Vector2(0, 22)
        var tw := create_tween()
        tw.set_parallel(true)
        tw.tween_property(shard, "position", target, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tw.tween_property(shard, "rotation", (1.0 if i % 2 == 0 else -1.0) * 2.4, 0.30)
        tw.tween_property(shard, "scale", Vector2(0.15, 0.15), 0.30)
        tw.tween_property(shard, "modulate:a", 0.0, 0.30)
        tw.set_parallel(false)
        tw.tween_callback(shard.queue_free)

func _add_chapter13_decor() -> void:
    if not is_instance_valid(world):
        return

    var horizon := Line2D.new()
    horizon.width = 2.0
    horizon.default_color = Color(0.05, 0.40, 0.48, 0.10)
    horizon.points = PackedVector2Array([Vector2(0, 438), Vector2(level_width, 438)])
    horizon.z_index = -24
    world.add_child(horizon)

    for i in range(18):
        var x := 180.0 + float(i) * 390.0
        var chevron := Line2D.new()
        chevron.width = 2.0
        chevron.default_color = Color(0.05, 0.40, 0.48, 0.065)
        chevron.points = PackedVector2Array([
            Vector2(x - 34, 410), Vector2(x, 385), Vector2(x + 34, 410), Vector2(x, 435)
        ])
        chevron.z_index = -23
        world.add_child(chevron)

func _safe_pad(pos: Vector2, width: float = 180.0) -> StaticBody2D:
    var pad := _platform(pos, Vector2(width, 26), V15_GREEN.lerp(V15_SLATE, 0.58))
    var line := Line2D.new()
    line.position = pos + Vector2(0, -16)
    line.width = 3.0
    line.default_color = Color(V15_GREEN, 0.38)
    line.points = PackedVector2Array([Vector2(-width * 0.40, 0), Vector2(width * 0.40, 0)])
    line.z_index = 3
    world.add_child(line)
    return pad

func _shift_notice(text: String, color: Color = V15_CYAN) -> void:
    _troll_popup(text, color)
    _play_tone(440.0, 0.07, 0.10)

func _level_13_1() -> void:
    _floor_with_gaps(6500, [Vector2(1730, 1890), Vector2(4210, 4370)])
    _text(Vector2(120, 470), "BÖLÜM 13: GÜVENLİ ALAN.", 23, V15_CYAN)
    _text(Vector2(410, 520), "AYNI GÖRÜNÜM, AYNI SONUÇ DEMEK DEĞİL.", 18, V15_MUTED)

    var safe_a := _safe_pad(Vector2(930, 548), 190.0)
    _trigger(Rect2(690, 390, 120, 240), func():
        if _once("131_safe_a"):
            _false_alarm()
            create_tween().tween_property(safe_a, "position:y", 545.0, 0.12)
    )

    var safe_b := _safe_pad(Vector2(1370, 548), 190.0)
    _trigger(Rect2(1130, 390, 120, 240), func():
        if _once("131_safe_b"):
            _shift_notice("AYNI DEĞİL")
            _delayed_platform_drop(safe_b, 0.46, 300.0)
    )

    _moving_platform(Vector2(1810, 555), Vector2(150, 24), Vector2(1850, 470), 1.36, V15_BLUE)

    var hidden := _spikes(Vector2(2410, 612), 3, true)
    _trigger(Rect2(2140, 390, 120, 240), func():
        if _once("131_hidden"):
            var tw := create_tween()
            tw.tween_interval(0.34)
            tw.tween_callback(func(): _reveal(hidden))
            tw.tween_interval(0.46)
            tw.tween_callback(func(): _hide(hidden))
    )

    var mover := _moving_platform(Vector2(3050, 548), Vector2(185, 26), Vector2(3240, 500), 1.55, V15_CYAN)
    _trigger(Rect2(2790, 390, 120, 240), func():
        if _once("131_shift"):
            _shift_notice("YÖN DEĞİŞTİ")
            var tw := create_tween()
            tw.tween_interval(0.38)
            tw.tween_property(mover, "position", Vector2(2910, 475), 0.58).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    )

    var suspicious := _platform(Vector2(3750, 548), Vector2(180, 26), V15_RED_DARK.lerp(V15_SLATE, 0.80))
    _trigger(Rect2(3510, 390, 120, 240), func():
        if _once("131_suspicious"):
            _false_alarm()
            create_tween().tween_property(suspicious, "position:x", 3754.0, 0.12)
    )

    _moving_platform(Vector2(4290, 555), Vector2(145, 24), Vector2(4330, 472), 1.30, V15_BLUE)

    _trigger(Rect2(4820, 390, 120, 240), func():
        if _once("131_rock"):
            var tw := create_tween()
            tw.tween_interval(0.42)
            tw.tween_callback(func(): _boulder(Vector2(5450, 560), -370.0, 70.0))
    )

    _spikes(Vector2(5630, 612), 2, false)
    _finish(Vector2(6200, 580))

func _level_13_2() -> void:
    _floor_with_gaps(7000, [Vector2(1540, 1700), Vector2(3650, 3810), Vector2(5330, 5490)])
    var a := _attempt(13, 2)
    _text(Vector2(120, 470), "İKİ GÜVENLİ ALAN.", 23, V15_CYAN)
    _text(Vector2(410, 520), "BİRİ GERÇEKTEN GÜVENLİ. HER DENEMEDE AYNI DEĞİL.", 18, V15_MUTED)

    var pad_left := _safe_pad(Vector2(850, 548), 170.0)
    var pad_right := _safe_pad(Vector2(1180, 548), 170.0)
    var left_is_safe := a % 2 == 1

    _trigger(Rect2(650, 390, 130, 240), func():
        if _once("132_left"):
            if left_is_safe:
                _false_alarm()
                create_tween().tween_property(pad_left, "position:y", 545.0, 0.12)
            else:
                _shift_notice("BU SEFER DEĞİL")
                _delayed_platform_drop(pad_left, 0.42, 300.0)
    )
    _trigger(Rect2(1010, 390, 130, 240), func():
        if _once("132_right"):
            if left_is_safe:
                _delayed_platform_drop(pad_right, 0.42, 300.0)
            else:
                _false_alarm()
                create_tween().tween_property(pad_right, "position:y", 545.0, 0.12)
    )

    _moving_platform(Vector2(1620, 555), Vector2(150, 24), Vector2(1660, 470), 1.34, V15_CYAN)

    var gate := _hidden_hazard(Vector2(2220, 530), Vector2(28, 230), V15_RED)
    _trigger(Rect2(1940, 390, 120, 240), func():
        _timed_hazard(gate, 0.34 + float(a % 3) * 0.07, 0.42, "132_gate")
    )

    _route_hint(Vector2(2770, 500), "ALT")
    _route_hint(Vector2(2770, 390), "ÜST")
    _platform(Vector2(2860, 465), Vector2(220, 24), V15_BLUE)
    _trigger(Rect2(2640, 315, 220, 175), func():
        if _choose_route("upper"):
            _false_alarm()
    )
    _trigger(Rect2(2640, 500, 220, 150), func():
        if _choose_route("lower"):
            _shift_notice("ALT")
    )

    _moving_platform(Vector2(3730, 555), Vector2(145, 24), Vector2(3770, 472), 1.28, V15_BLUE)

    var route_spikes := _spikes(Vector2(4250, 612), 3, true)
    _trigger(Rect2(4000, 390, 120, 240), func():
        if _once("132_route"):
            var punish := (route_choice == "lower" and a % 3 != 0) or (route_choice == "upper" and a % 3 == 0)
            if punish:
                var tw := create_tween()
                tw.tween_interval(0.30)
                tw.tween_callback(func(): _reveal(route_spikes))
                tw.tween_interval(0.46)
                tw.tween_callback(func(): _hide(route_spikes))
            else:
                _false_alarm()
    )

    var red_safe := _platform(Vector2(4930, 548), Vector2(180, 26), V15_RED_DARK.lerp(V15_SLATE, 0.78))
    _trigger(Rect2(4690, 390, 120, 240), func():
        if _once("132_red_safe"):
            _false_alarm()
            create_tween().tween_property(red_safe, "position:y", 544.0, 0.12)
    )

    _moving_platform(Vector2(5410, 555), Vector2(145, 24), Vector2(5450, 472), 1.30, V15_CYAN)

    _trigger(Rect2(5850, 390, 120, 240), func():
        if _once("132_reverse") and a % 3 == 1:
            _reverse_controls(0.76)
    )

    _finish(Vector2(6700, 580))

func _level_13_3() -> void:
    _floor_with_gaps(7700, [Vector2(1690, 1850), Vector2(3890, 4050), Vector2(5940, 6100)])
    var a := _attempt(13, 3)
    _text(Vector2(120, 470), "KAYAN GÜVENİ HATIRLA.", 24, V15_PURPLE)
    _text(Vector2(410, 520), "DENEME %d — GÜVENLİ NOKTA DA HAREKET EDEBİLİR." % a, 18, V15_MUTED)

    var first := _safe_pad(Vector2(900, 548), 180.0)
    _trigger(Rect2(680, 390, 120, 240), func():
        if _once("133_first"):
            if a % 3 == 1:
                _false_alarm()
            elif a % 3 == 2:
                _delayed_platform_drop(first, 0.46, 300.0)
            else:
                _shift_notice("KAYDI")
                create_tween().tween_property(first, "position:x", 1060.0, 0.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    )

    _moving_platform(Vector2(1770, 555), Vector2(150, 24), Vector2(1810, 470), 1.34, V15_CYAN)

    var memory_spikes_a := _spikes(Vector2(2350, 612), 3, true)
    var memory_spikes_b := _spikes(Vector2(2640, 612), 3, true)
    _trigger(Rect2(2080, 390, 120, 240), func():
        if _once("133_memory"):
            var target := memory_spikes_a if a % 2 == 1 else memory_spikes_b
            var tw := create_tween()
            tw.tween_interval(0.30)
            tw.tween_callback(func(): _reveal(target))
            tw.tween_interval(0.46)
            tw.tween_callback(func(): _hide(target))
    )

    var mover := _moving_platform(Vector2(3230, 548), Vector2(190, 26), Vector2(3420, 500), 1.50, V15_BLUE)
    _trigger(Rect2(2970, 390, 120, 240), func():
        if _once("133_mover"):
            var target := Vector2(3070, 474) if a % 2 == 1 else Vector2(3490, 474)
            var tw := create_tween()
            tw.tween_interval(0.40)
            tw.tween_callback(func(): _shift_notice("YÖN DEĞİŞTİ"))
            tw.tween_property(mover, "position", target, 0.62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    )

    _moving_platform(Vector2(3970, 555), Vector2(145, 24), Vector2(4010, 472), 1.30, V15_CYAN)

    var wait_gate := _hazard_block(Vector2(4680, 220), Vector2(150, 72), V15_RED_DARK)
    _trigger(Rect2(4400, 390, 280, 240), func():
        _wait_check(4600.0, 150.0, 1.00, func():
            if a % 3 != 2:
                _shift_notice("FAZLA BEKLEDİN", V15_AMBER)
                var tw := create_tween()
                tw.tween_property(wait_gate, "position:y", 520.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
                tw.tween_interval(0.18)
                tw.tween_property(wait_gate, "position:y", 220.0, 0.50).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
            else:
                _false_alarm()
        , "133_wait")
    )

    var safe_red := _platform(Vector2(5350, 548), Vector2(180, 26), V15_RED_DARK.lerp(V15_SLATE, 0.78))
    _trigger(Rect2(5110, 390, 120, 240), func():
        if _once("133_safe_red"):
            _false_alarm()
            create_tween().tween_property(safe_red, "position:x", 5354.0, 0.12)
    )

    _moving_platform(Vector2(6020, 555), Vector2(140, 24), Vector2(6060, 470), 1.28, V15_BLUE)

    _trigger(Rect2(6350, 390, 120, 240), func():
        if _once("133_rock"):
            var tw := create_tween()
            tw.tween_interval(0.42)
            tw.tween_callback(func(): _boulder(Vector2(6990, 560), -365.0, 70.0))
    )

    var last := _spikes(Vector2(6900, 612), 3, true)
    _trigger(Rect2(6650, 390, 120, 240), func():
        if _once("133_last") and a % 3 == 0:
            _timed_hazard(last, 0.30, 0.44, "133_last_hazard")
    )

    var goal := _finish(Vector2(7380, 580))
    _trigger(Rect2(7100, 390, 120, 240), func():
        if _once("133_goal") and a % 2 == 1:
            create_tween().tween_property(goal, "position:y", 505.0, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )
