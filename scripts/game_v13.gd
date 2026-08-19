extends "res://scripts/game_v12_boot.gd"

const V13_BG := Color("#edf1f6")
const V13_BG_CH11 := Color("#e8eef0")
const V13_INK := Color("#111827")
const V13_SLATE := Color("#475569")
const V13_MUTED := Color("#64748b")
const V13_BLUE := Color("#2563eb")
const V13_CYAN := Color("#0891b2")
const V13_GREEN := Color("#16a34a")
const V13_YELLOW := Color("#d97706")
const V13_RED := Color("#dc4455")
const V13_RED_DARK := Color("#7f2937")
const V13_PURPLE := Color("#7c3aed")

func _safe_load_progress() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return

    var stored_deaths = cfg.get_value("progress", "deaths", 0)
    if stored_deaths is int or stored_deaths is float:
        deaths = maxi(0, int(stored_deaths))

    var stored_unlock = cfg.get_value("progress", "unlocked_chapter", 1)
    if stored_unlock is int or stored_unlock is float:
        unlocked_chapter = clampi(int(stored_unlock), 1, 12)

    var stored_attempts = cfg.get_value("memory", "level_attempts", {})
    if stored_attempts is Dictionary:
        level_attempts = stored_attempts.duplicate(true)

func _start_level(c: int, p: int) -> void:
    super._start_level(c, p)
    if c == 11:
        RenderingServer.set_default_clear_color(V13_BG_CH11)
        _add_chapter11_decor()

func _build_level(c: int, p: int) -> void:
    if c == 11 and p == 1:
        _level_11_1()
    elif c == 11 and p == 2:
        _level_11_2()
    elif c == 11 and p == 3:
        _level_11_3()
    else:
        super._build_level(c, p)

func _build_hud() -> void:
    super._build_hud()
    if chapter == 11:
        var mode := Label.new()
        mode.position = Vector2(725, 18)
        mode.size = Vector2(270, 38)
        mode.text = "REAKTİF TUZAKLAR"
        mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        mode.add_theme_font_size_override("font_size", 16)
        mode.add_theme_color_override("font_color", V13_CYAN)
        hud.add_child(mode)

func _show_main_menu() -> void:
    RenderingServer.set_default_clear_color(V13_BG)
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
    bg.color = V13_BG
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(bg)

    var top_band := ColorRect.new()
    top_band.size = Vector2(1280, 92)
    top_band.color = V13_INK
    top_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(top_band)

    var version := Label.new()
    version.position = Vector2(24, 27)
    version.size = Vector2(250, 40)
    version.text = "ANDROID • v1.3"
    version.add_theme_font_size_override("font_size", 18)
    version.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(version)

    var title := Label.new()
    title.position = Vector2(180, 118)
    title.size = Vector2(920, 95)
    title.text = "TROLL PARKOUR"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 58)
    title.add_theme_color_override("font_color", V13_INK)
    hud.add_child(title)

    var subtitle := Label.new()
    subtitle.position = Vector2(205, 203)
    subtitle.size = Vector2(870, 58)
    subtitle.text = "Bölüm 11: Artık sadece harita değil, yaptığın hareket de tuzak olabilir."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 20)
    subtitle.add_theme_color_override("font_color", V13_MUTED)
    hud.add_child(subtitle)

    var progress := Label.new()
    progress.position = Vector2(270, 276)
    progress.size = Vector2(740, 44)
    var available := maxi(1, mini(unlocked_chapter, 11))
    var completed_maps := maxi(0, (mini(unlocked_chapter, 12) - 1) * 3)
    progress.text = "AÇIK BÖLÜM: %d / 11     HARİTA: %d / 33     ÖLÜM: %d" % [available, completed_maps, deaths]
    progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    progress.add_theme_font_size_override("font_size", 19)
    progress.add_theme_color_override("font_color", V13_RED_DARK)
    hud.add_child(progress)

    _menu_button("DEVAM ET", Vector2(440, 350), Vector2(400, 72), func():
        _start_level(maxi(1, mini(unlocked_chapter, 11)), 1)
    )
    _menu_button("BÖLÜMLER", Vector2(440, 440), Vector2(400, 72), func():
        _show_chapter_select()
    )
    _menu_button("1. BÖLÜMDEN BAŞLA", Vector2(440, 530), Vector2(400, 72), func():
        _start_level(1, 1)
    )

    var warning := Label.new()
    warning.position = Vector2(215, 630)
    warning.size = Vector2(850, 40)
    warning.text = "İpucu: Bazen koşmak, bazen beklemek, bazen de hiç zıplamamak daha güvenlidir."
    warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    warning.add_theme_font_size_override("font_size", 17)
    warning.add_theme_color_override("font_color", V13_MUTED)
    hud.add_child(warning)
    _polish_menu_surface()

func _show_chapter_select() -> void:
    RenderingServer.set_default_clear_color(V13_BG)
    if is_instance_valid(hud):
        hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)

    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V13_BG
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(240, 24)
    title.size = Vector2(800, 62)
    title.text = "BÖLÜM SEÇ"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 40)
    title.add_theme_color_override("font_color", V13_INK)
    hud.add_child(title)

    var info := Label.new()
    info.position = Vector2(150, 82)
    info.size = Vector2(980, 38)
    info.text = "11 bölüm • 33 harita • Bölüm 11: Reaktif tuzaklar"
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.add_theme_font_size_override("font_size", 18)
    info.add_theme_color_override("font_color", V13_MUTED)
    hud.add_child(info)

    for i in range(1, 12):
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
        var button_text := "BÖLÜM %d\n%s" % [chapter_id, suffix] if is_unlocked else "BÖLÜM %d\nKİLİTLİ" % chapter_id
        var button := _menu_button(button_text, pos, Vector2(270, 78), func():
            _start_level(chapter_id, 1)
        )
        button.disabled = not is_unlocked

    var note := Label.new()
    note.position = Vector2(220, 480)
    note.size = Vector2(840, 38)
    note.text = "Bölüm 11 bazı tuzakları zıplamana, beklemene veya geri dönmene göre çalıştırır."
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    note.add_theme_font_size_override("font_size", 16)
    note.add_theme_color_override("font_color", V13_MUTED)
    hud.add_child(note)

    _menu_button("GERİ", Vector2(490, 535), Vector2(300, 64), func():
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
    bg.color = V13_INK
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(180, 92)
    title.size = Vector2(920, 300)
    var map_count := mini(chapter * 3, 33)
    title.text = "BÖLÜM %d TAMAMLANDI\n\nTOPLAM ÖLÜM: %d\nTAMAMLANAN HARİTA: %d / 33" % [chapter, deaths, map_count]
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(title)

    if chapter < 11:
        var next_chapter := chapter + 1
        _menu_button("SONRAKİ BÖLÜM", Vector2(440, 430), Vector2(400, 72), func():
            _start_level(next_chapter, 1)
        )
    else:
        var done := Label.new()
        done.position = Vector2(205, 392)
        done.size = Vector2(870, 105)
        done.text = "33 HARİTA TAMAM\nOYUN ARTIK SADECE NEREDE OLDUĞUNU DEĞİL, NE YAPTIĞINI DA KULLANIYOR."
        done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        done.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        done.add_theme_font_size_override("font_size", 22)
        done.add_theme_color_override("font_color", V13_CYAN)
        hud.add_child(done)

    _menu_button("ANA MENÜ", Vector2(490, 545), Vector2(300, 68), func():
        _show_main_menu()
    )

func _add_chapter11_decor() -> void:
    if not is_instance_valid(world):
        return

    var horizon := Line2D.new()
    horizon.width = 2.0
    horizon.default_color = Color(0.05, 0.45, 0.52, 0.10)
    horizon.points = PackedVector2Array([Vector2(0, 438), Vector2(level_width, 438)])
    horizon.z_index = -24
    world.add_child(horizon)

    for i in range(16):
        var pulse := Line2D.new()
        var x := 180.0 + float(i) * 430.0
        pulse.width = 2.0
        pulse.default_color = Color(0.05, 0.45, 0.52, 0.075)
        pulse.points = PackedVector2Array([
            Vector2(x - 44, 418), Vector2(x - 16, 418), Vector2(x, 386),
            Vector2(x + 16, 445), Vector2(x + 34, 418), Vector2(x + 72, 418)
        ])
        pulse.z_index = -23
        world.add_child(pulse)

func _reaction_notice(text: String, color: Color = V13_CYAN) -> void:
    _troll_popup(text, color)
    _play_tone(410.0, 0.07, 0.11)

func _wait_check(center_x: float, tolerance: float, delay: float, callback: Callable, key: String) -> void:
    if not _once(key):
        return
    var tw := create_tween()
    tw.tween_interval(delay)
    tw.tween_callback(func():
        if is_instance_valid(player) and player.alive and absf(player.global_position.x - center_x) <= tolerance:
            callback.call()
    )

func _level_11_1() -> void:
    _floor_with_gaps(6200, [Vector2(1550, 1710), Vector2(3920, 4080)])
    _text(Vector2(120, 470), "BÖLÜM 11: OYUN SENİ İZLİYOR.", 23, V13_CYAN)
    _text(Vector2(420, 520), "BAZI TUZAKLARI SEN ÇALIŞTIRIRSIN.", 18, V13_MUTED)

    var jump_spikes := _spikes(Vector2(1120, 612), 3, true)
    _trigger(Rect2(720, 315, 250, 170), func():
        if _once("111_jump_sensor"):
            _reaction_notice("ZIPLADIN")
            var tw := create_tween()
            tw.tween_interval(0.12)
            tw.tween_callback(func(): _reveal(jump_spikes))
            tw.tween_interval(0.50)
            tw.tween_callback(func(): _hide(jump_spikes))
    )

    var suspicious := _platform(Vector2(1380, 548), Vector2(180, 26), V13_RED_DARK.lerp(V13_SLATE, 0.78))
    _trigger(Rect2(1180, 390, 120, 240), func():
        if _once("111_safe_decoy"):
            _false_alarm()
            create_tween().tween_property(suspicious, "position:y", 544.0, 0.12)
    )

    _moving_platform(Vector2(1630, 555), Vector2(150, 24), Vector2(1670, 470), 1.34, V13_BLUE)

    var back_spikes := _spikes(Vector2(2260, 612), 3, true)
    _trigger(Rect2(2460, 390, 120, 240), func():
        if _once("111_backtrack_arm"):
            _reaction_notice("GERİ DÖNME")
            _trigger(Rect2(2180, 390, 110, 240), func():
                if _once("111_backtrack_fire"):
                    _reveal(back_spikes)
                    Input.vibrate_handheld(30)
            )
    )

    _text(Vector2(2920, 520), "BEKLE?", 18, V13_YELLOW)
    _trigger(Rect2(2820, 390, 320, 240), func():
        _wait_check(3020.0, 145.0, 1.10, func():
            _reaction_notice("ÇOK BEKLEDİN", V13_RED)
            _falling_boulder(Vector2(3020, 20), 66.0, 0.0)
        , "111_wait")
    )

    var crusher := _hazard_block(Vector2(3560, 190), Vector2(145, 82), V13_RED_DARK)
    _trigger(Rect2(3320, 390, 120, 240), func():
        if _once("111_crusher"):
            var tw := create_tween()
            tw.tween_interval(0.42)
            tw.tween_property(crusher, "position:y", 515.0, 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_interval(0.22)
            tw.tween_property(crusher, "position:y", 190.0, 0.52).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

    _moving_platform(Vector2(4000, 555), Vector2(145, 24), Vector2(4040, 470), 1.28, V13_CYAN)

    var late := _spikes(Vector2(4660, 612), 2, true)
    _trigger(Rect2(4420, 390, 120, 240), func():
        _timed_hazard(late, 0.34, 0.46, "111_late")
    )

    _trigger(Rect2(5050, 390, 120, 240), func():
        if _once("111_harmless_alarm"):
            _reaction_notice("BU SEFER HİÇBİR ŞEY OLMADI", V13_GREEN)
    )

    _finish(Vector2(5900, 580))

func _level_11_2() -> void:
    _floor_with_gaps(6700, [Vector2(1260, 1420), Vector2(3310, 3470), Vector2(5100, 5260)])
    _text(Vector2(120, 470), "HER TEPKİN BİR GİRDİ.", 23, V13_CYAN)
    _text(Vector2(420, 520), "KOŞMAK DA BEKLEMEK DE KARAR.", 18, V13_MUTED)

    var early := _spikes(Vector2(1020, 612), 3, true)
    _trigger(Rect2(620, 320, 260, 165), func():
        if _once("112_early_jump"):
            _reaction_notice("ERKEN ZIPLAMA")
            var tw := create_tween()
            tw.tween_interval(0.15)
            tw.tween_callback(func(): _reveal(early))
            tw.tween_interval(0.48)
            tw.tween_callback(func(): _hide(early))
    )

    _moving_platform(Vector2(1340, 555), Vector2(150, 24), Vector2(1380, 468), 1.32, V13_BLUE)

    _route_hint(Vector2(1840, 500), "KOŞ")
    _route_hint(Vector2(1840, 390), "BEKLE")
    _platform(Vector2(1940, 465), Vector2(220, 24), V13_BLUE)
    _trigger(Rect2(1720, 315, 220, 175), func():
        if _choose_route("upper"):
            _reaction_notice("BEKLE ROTA")
    )
    _trigger(Rect2(1720, 500, 220, 150), func():
        if _choose_route("lower"):
            _reaction_notice("KOŞ ROTA")
    )

    var route_gate := _hidden_hazard(Vector2(2520, 530), Vector2(28, 230), V13_RED)
    _trigger(Rect2(2260, 390, 120, 240), func():
        if _once("112_route_gate"):
            var delay := 0.25 if route_choice == "lower" else 0.62
            _timed_hazard(route_gate, delay, 0.40, "112_route_gate_inner")
    )

    _trigger(Rect2(2820, 390, 300, 240), func():
        _wait_check(2990.0, 135.0, 0.95, func():
            if route_choice == "upper":
                _false_alarm()
            else:
                _reaction_notice("KOŞ DEDİK", V13_RED)
                _falling_boulder(Vector2(3000, 10), 62.0, 0.0)
        , "112_wait")
    )

    _moving_platform(Vector2(3390, 555), Vector2(145, 24), Vector2(3430, 470), 1.24, V13_CYAN)

    _trigger(Rect2(3840, 390, 120, 240), func():
        if _once("112_reverse"):
            _reaction_notice("KONTROLLER TEPKİ VERDİ", V13_PURPLE)
            _reverse_controls(0.90)
    )

    var pair_a := _spikes(Vector2(4350, 612), 2, true)
    var pair_b := _spikes(Vector2(4620, 612), 2, true)
    _trigger(Rect2(4100, 390, 120, 240), func():
        if _once("112_pair"):
            var tw := create_tween()
            tw.tween_interval(0.24)
            tw.tween_callback(func(): _reveal(pair_a))
            tw.tween_interval(0.32)
            tw.tween_callback(func(): _hide(pair_a))
            tw.tween_callback(func(): _reveal(pair_b))
            tw.tween_interval(0.36)
            tw.tween_callback(func(): _hide(pair_b))
    )

    _moving_platform(Vector2(5180, 555), Vector2(140, 24), Vector2(5220, 472), 1.30, V13_BLUE)

    _trigger(Rect2(5520, 390, 120, 240), func():
        if _once("112_fall"):
            _falling_boulder(Vector2(5740, 20), 58.0, 0.18)
            _falling_boulder(Vector2(5960, -10), 50.0, 0.48)
    )

    var goal := _finish(Vector2(6420, 580))
    _trigger(Rect2(6130, 390, 120, 240), func():
        if _once("112_goal") and route_choice == "upper":
            create_tween().tween_property(goal, "position:x", 6510.0, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

func _level_11_3() -> void:
    _floor_with_gaps(7500, [Vector2(1510, 1670), Vector2(3650, 3810), Vector2(5660, 5820)])
    var a := _attempt(11, 3)
    _text(Vector2(120, 470), "REAKSİYON TESTİ: 33. HARİTA.", 23, V13_PURPLE)
    _text(Vector2(420, 520), "DENEME %d — HAREKETİN DE HAFIZADA." % a, 18, V13_MUTED)

    _spikes(Vector2(620, 612), 2, false)

    var jump_a := _spikes(Vector2(1180, 612), 3, true)
    var jump_b := _spikes(Vector2(1390, 612), 2, true)
    _trigger(Rect2(820, 315, 250, 170), func():
        if _once("113_jump"):
            var target := jump_a if a % 2 == 1 else jump_b
            _reaction_notice("ZIPLAMA KAYDEDİLDİ")
            var tw := create_tween()
            tw.tween_interval(0.16 + float(a % 3) * 0.06)
            tw.tween_callback(func(): _reveal(target))
            tw.tween_interval(0.46)
            tw.tween_callback(func(): _hide(target))
    )

    _moving_platform(Vector2(1590, 555), Vector2(150, 24), Vector2(1630, 468), 1.30, V13_CYAN)

    var back := _spikes(Vector2(2220, 612), 3, true)
    _trigger(Rect2(2470, 390, 120, 240), func():
        if _once("113_back_arm"):
            _trigger(Rect2(2140, 390, 120, 240), func():
                if _once("113_back_fire"):
                    _reaction_notice("GERİ DÖNDÜN", V13_RED)
                    _reveal(back)
            )
    )

    var harmless := _platform(Vector2(2870, 548), Vector2(180, 26), V13_RED_DARK.lerp(V13_SLATE, 0.80))
    _trigger(Rect2(2630, 390, 120, 240), func():
        if _once("113_harmless"):
            _false_alarm()
            create_tween().tween_property(harmless, "position:x", 2875.0, 0.12)
    )

    _trigger(Rect2(3100, 390, 300, 240), func():
        _wait_check(3270.0, 135.0, 1.00, func():
            if a % 2 == 0:
                _reaction_notice("BU KEZ BEKLEMEK DOĞRUYDU", V13_GREEN)
            else:
                _reaction_notice("BEKLEME HATASI", V13_RED)
                _falling_boulder(Vector2(3270, 10), 64.0, 0.0)
        , "113_wait")
    )

    _moving_platform(Vector2(3730, 555), Vector2(145, 24), Vector2(3770, 470), 1.22, V13_BLUE)

    _route_hint(Vector2(4240, 500), "A")
    _route_hint(Vector2(4240, 390), "B")
    _platform(Vector2(4340, 465), Vector2(220, 24), V13_BLUE)
    _trigger(Rect2(4120, 315, 220, 175), func():
        if _choose_route("upper"):
            _reaction_notice("B ROTASI")
    )
    _trigger(Rect2(4120, 500, 220, 150), func():
        if _choose_route("lower"):
            _reaction_notice("A ROTASI")
    )

    _trigger(Rect2(4700, 390, 120, 240), func():
        if _once("113_reverse") and route_choice == "upper" and a % 2 == 1:
            _reverse_controls(0.82)
    )

    var memory_gate := _hidden_hazard(Vector2(5180, 530), Vector2(28, 230), V13_RED)
    _trigger(Rect2(4920, 390, 120, 240), func():
        if _once("113_gate"):
            var delay := 0.28 + float(a % 3) * 0.10
            _timed_hazard(memory_gate, delay, 0.40, "113_gate_inner")
    )

    _moving_platform(Vector2(5740, 555), Vector2(140, 24), Vector2(5780, 470), 1.28, V13_CYAN)

    var final_spikes := _spikes(Vector2(6260, 612), 3, true)
    _trigger(Rect2(6030, 390, 120, 240), func():
        if _once("113_final"):
            var tw := create_tween()
            tw.tween_interval(0.26 if a % 2 == 0 else 0.42)
            tw.tween_callback(func(): _reveal(final_spikes))
            tw.tween_interval(0.44)
            tw.tween_callback(func(): _hide(final_spikes))
    )

    _trigger(Rect2(6550, 390, 120, 240), func():
        if _once("113_rock"):
            var tw := create_tween()
            tw.tween_interval(0.34)
            tw.tween_callback(func(): _boulder(Vector2(7040, 560), -380.0, 70.0))
    )

    var goal := _finish(Vector2(7180, 580))
    _trigger(Rect2(6900, 390, 120, 240), func():
        if _once("113_goal"):
            if a % 3 == 1:
                create_tween().tween_property(goal, "position:y", 505.0, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
            else:
                _reaction_notice("33. HARİTA")
    )
