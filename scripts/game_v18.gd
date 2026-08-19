extends "res://scripts/game_v17.gd"

const V18_BG := Color("#edf1f6")
const V18_BG_CH16 := Color("#e8edf3")
const V18_INK := Color("#111827")
const V18_SLATE := Color("#475569")
const V18_MUTED := Color("#64748b")
const V18_BLUE := Color("#2563eb")
const V18_CYAN := Color("#0891b2")
const V18_AMBER := Color("#d97706")
const V18_RED_DARK := Color("#7f2937")
const V18_PURPLE := Color("#7c3aed")

var ch16_backtrack_armed := false
var ch16_backtrack_origin := 0.0
var ch16_backtrack_distance := 0.0
var ch16_backtrack_key := ""
var ch16_backtrack_action: Callable

func _safe_load_progress() -> void:
    super._safe_load_progress()
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return
    var stored_unlock = cfg.get_value("progress", "unlocked_chapter", 1)
    if stored_unlock is int or stored_unlock is float:
        unlocked_chapter = clampi(int(stored_unlock), 1, 17)

func _start_level(c: int, p: int) -> void:
    ch16_backtrack_armed = false
    ch16_backtrack_action = Callable()
    super._start_level(c, p)
    if c == 16:
        RenderingServer.set_default_clear_color(V18_BG_CH16)
        _add_chapter16_decor()
        if is_instance_valid(player) and not player.jumped.is_connected(_on_ch16_jump):
            player.jumped.connect(_on_ch16_jump)

func _process(delta: float) -> void:
    super._process(delta)
    if chapter != 16 or not ch16_backtrack_armed or not is_instance_valid(player):
        return
    if player.global_position.x <= ch16_backtrack_origin - ch16_backtrack_distance:
        ch16_backtrack_armed = false
        if _once(ch16_backtrack_key) and ch16_backtrack_action.is_valid():
            ch16_backtrack_action.call()

func _build_level(c: int, p: int) -> void:
    if c == 16 and p == 1:
        _level_16_1()
    elif c == 16 and p == 2:
        _level_16_2()
    elif c == 16 and p == 3:
        _level_16_3()
    else:
        super._build_level(c, p)

func _build_hud() -> void:
    super._build_hud()
    if chapter == 16:
        var mode := Label.new()
        mode.position = Vector2(720, 18)
        mode.size = Vector2(275, 38)
        mode.text = "GİRDİ / TEPKİ"
        mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        mode.add_theme_font_size_override("font_size", 16)
        mode.add_theme_color_override("font_color", V18_CYAN)
        hud.add_child(mode)

func _show_main_menu() -> void:
    active_map_key = ""
    timer_label = null
    RenderingServer.set_default_clear_color(V18_BG)
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
    bg.color = V18_BG
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(bg)

    var top_band := ColorRect.new()
    top_band.size = Vector2(1280, 92)
    top_band.color = V18_INK
    top_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(top_band)

    var version := Label.new()
    version.position = Vector2(24, 27)
    version.size = Vector2(250, 40)
    version.text = "ANDROID • v1.8"
    version.add_theme_font_size_override("font_size", 18)
    version.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(version)

    var records := Label.new()
    records.position = Vector2(925, 27)
    records.size = Vector2(325, 40)
    records.text = "KAYITLI REKOR: %d / 48" % best_times_ms.size()
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
    title.add_theme_color_override("font_color", V18_INK)
    hud.add_child(title)

    var subtitle := Label.new()
    subtitle.position = Vector2(205, 202)
    subtitle.size = Vector2(870, 58)
    subtitle.text = "Bölüm 16: Parkur artık yalnızca konumuna değil, kararlarına da tepki veriyor."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 20)
    subtitle.add_theme_color_override("font_color", V18_MUTED)
    hud.add_child(subtitle)

    var progress := Label.new()
    progress.position = Vector2(255, 276)
    progress.size = Vector2(770, 44)
    var available := maxi(1, mini(unlocked_chapter, 16))
    var completed_maps := maxi(0, (mini(unlocked_chapter, 17) - 1) * 3)
    progress.text = "AÇIK BÖLÜM: %d / 16     HARİTA: %d / 48     ÖLÜM: %d" % [available, completed_maps, deaths]
    progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    progress.add_theme_font_size_override("font_size", 19)
    progress.add_theme_color_override("font_color", V18_RED_DARK)
    hud.add_child(progress)

    _menu_button("DEVAM ET", Vector2(440, 350), Vector2(400, 72), func(): _start_level(maxi(1, mini(unlocked_chapter, 16)), 1))
    _menu_button("BÖLÜMLER", Vector2(440, 440), Vector2(400, 72), func(): _show_chapter_select())
    _menu_button("1. BÖLÜMDEN BAŞLA", Vector2(440, 530), Vector2(400, 72), func(): _start_level(1, 1))

    var warning := Label.new()
    warning.position = Vector2(175, 630)
    warning.size = Vector2(930, 40)
    warning.text = "Zıplama tepkileri gerçek jumped sinyalinden okunur; dokunmatik girdiler tahmin edilmez."
    warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    warning.add_theme_font_size_override("font_size", 17)
    warning.add_theme_color_override("font_color", V18_MUTED)
    hud.add_child(warning)
    _polish_menu_surface()

func _show_chapter_select() -> void:
    timer_label = null
    RenderingServer.set_default_clear_color(V18_BG)
    if is_instance_valid(hud):
        hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)

    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V18_BG
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(240, 14)
    title.size = Vector2(800, 54)
    title.text = "BÖLÜM SEÇ"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 35)
    title.add_theme_color_override("font_color", V18_INK)
    hud.add_child(title)

    var info := Label.new()
    info.position = Vector2(150, 60)
    info.size = Vector2(980, 30)
    info.text = "16 bölüm • 48 harita • Süre ve ölüm rekorları aktif"
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.add_theme_font_size_override("font_size", 16)
    info.add_theme_color_override("font_color", V18_MUTED)
    hud.add_child(info)

    for i in range(1, 17):
        var chapter_id := i
        var is_unlocked := chapter_id <= unlocked_chapter
        var col := (i - 1) % 4
        var row := int((i - 1) / 4)
        var pos := Vector2(55 + col * 300, 96 + row * 82)
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
        var button_text := "BÖLÜM %d\n%s" % [chapter_id, suffix] if is_unlocked else "BÖLÜM %d\nKİLİTLİ" % chapter_id
        var button := _menu_button(button_text, pos, Vector2(270, 62), func(): _start_level(chapter_id, 1))
        button.disabled = not is_unlocked

    var note := Label.new()
    note.position = Vector2(175, 455)
    note.size = Vector2(930, 34)
    note.text = "Bölüm 16 zıplama, geri dönüş ve bekleme kararlarını parkurun bir parçası yapar."
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    note.add_theme_font_size_override("font_size", 16)
    note.add_theme_color_override("font_color", V18_MUTED)
    hud.add_child(note)
    _menu_button("GERİ", Vector2(490, 505), Vector2(300, 60), func(): _show_main_menu())
    _polish_menu_surface()

func _show_chapter_result() -> void:
    if chapter != 16:
        super._show_chapter_result()
        return
    timer_label = null
    if is_instance_valid(world): world.queue_free()
    world = null
    if is_instance_valid(hud): hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)
    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V18_INK
    hud.add_child(bg)
    var title := Label.new()
    title.position = Vector2(160, 62)
    title.size = Vector2(960, 300)
    title.text = "BÖLÜM 16 TAMAMLANDI\n\nTOPLAM ÖLÜM: %d\nTAMAMLANAN HARİTA: 48 / 48" % deaths
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(title)
    var stats := Label.new()
    stats.position = Vector2(125, 350)
    stats.size = Vector2(1030, 145)
    stats.text = "16-1  %s / %s ölüm     16-2  %s / %s ölüm     16-3  %s / %s ölüm\n\n48 HARİTA TAMAM" % [_best_time_text(16, 1), _best_deaths_text(16, 1), _best_time_text(16, 2), _best_deaths_text(16, 2), _best_time_text(16, 3), _best_deaths_text(16, 3)]
    stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    stats.add_theme_font_size_override("font_size", 19)
    stats.add_theme_color_override("font_color", V18_CYAN)
    hud.add_child(stats)
    _menu_button("ANA MENÜ", Vector2(490, 555), Vector2(300, 64), func(): _show_main_menu())

func _add_chapter16_decor() -> void:
    if not is_instance_valid(world): return
    var horizon := Line2D.new()
    horizon.width = 2.0
    horizon.default_color = Color(0.05, 0.40, 0.48, 0.09)
    horizon.points = PackedVector2Array([Vector2(0, 438), Vector2(level_width, 438)])
    horizon.z_index = -24
    world.add_child(horizon)
    for i in range(20):
        var x := 150.0 + float(i) * 360.0
        var pulse := Line2D.new()
        pulse.width = 2.0
        pulse.default_color = Color(0.05, 0.40, 0.48, 0.055)
        pulse.points = PackedVector2Array([Vector2(x - 38, 420), Vector2(x - 18, 420), Vector2(x - 6, 390), Vector2(x + 8, 438), Vector2(x + 22, 405), Vector2(x + 38, 405)])
        pulse.z_index = -23
        world.add_child(pulse)

func _input_notice(text: String, color: Color = V18_CYAN) -> void:
    _troll_popup(text, color)
    _play_tone(520.0, 0.07, 0.10)

func _arm_backtrack(distance: float, key: String, action: Callable) -> void:
    if not is_instance_valid(player): return
    ch16_backtrack_armed = true
    ch16_backtrack_origin = player.global_position.x
    ch16_backtrack_distance = distance
    ch16_backtrack_key = key
    ch16_backtrack_action = action

func _on_ch16_jump() -> void:
    if chapter != 16 or level_finished or restarting or not is_instance_valid(player): return
    var x := player.global_position.x
    if part == 1: _jump_map_16_1(x)
    elif part == 2: _jump_map_16_2(x)
    elif part == 3: _jump_map_16_3(x)

func _jump_map_16_1(x: float) -> void:
    if x >= 520.0 and x <= 980.0 and _once("161_jump_safe"):
        _input_notice("ZIPLAMA ALGILANDI")
        _false_alarm()
    elif x >= 1260.0 and x <= 1650.0 and _once("161_jump_spikes"):
        var spikes := _spikes(Vector2(1840, 612), 3, true)
        var tw := create_tween()
        tw.tween_interval(0.30)
        tw.tween_callback(func(): _reveal(spikes))
        tw.tween_interval(0.44)
        tw.tween_callback(func(): _hide(spikes))
    elif x >= 2630.0 and x <= 3070.0 and _once("161_jump_platform"):
        var reactive := get_node_or_null("World/Ch16Reactive161")
        if is_instance_valid(reactive):
            _input_notice("ZIPLAMA → PLATFORM")
            create_tween().tween_property(reactive, "position:y", reactive.position.y + 72.0, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    elif x >= 4860.0 and x <= 5230.0 and _once("161_jump_end"):
        _false_alarm()

func _jump_map_16_2(x: float) -> void:
    if x >= 760.0 and x <= 1160.0 and _once("162_jump_fake"):
        _input_notice("BİP", V18_AMBER)
        _false_alarm()
    elif x >= 2250.0 and x <= 2670.0 and _once("162_jump_gate"):
        var gate := get_node_or_null("World/Ch16Gate162")
        if is_instance_valid(gate):
            var tw := create_tween()
            tw.tween_interval(0.26)
            tw.tween_property(gate, "position:y", 520.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_interval(0.18)
            tw.tween_property(gate, "position:y", 220.0, 0.50).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    elif x >= 4100.0 and x <= 4520.0 and _once("162_jump_reverse"):
        _input_notice("ZIPLAMA YÖNÜ BOZDU", V18_PURPLE)
        _reverse_controls(0.70)

func _jump_map_16_3(x: float) -> void:
    var a := _attempt(16, 3)
    if x >= 620.0 and x <= 1100.0 and _once("163_jump_open"):
        if a % 2 == 0: _false_alarm()
        else:
            var spikes := _spikes(Vector2(1320, 612), 3, true)
            var tw := create_tween()
            tw.tween_interval(0.28)
            tw.tween_callback(func(): _reveal(spikes))
            tw.tween_interval(0.42)
            tw.tween_callback(func(): _hide(spikes))
    elif x >= 2860.0 and x <= 3330.0 and _once("163_jump_route"):
        var punish := (route_choice == "upper" and a % 3 == 0) or (route_choice == "lower" and a % 3 != 0)
        if punish:
            var gate := get_node_or_null("World/Ch16Gate163")
            if is_instance_valid(gate):
                _input_notice("GİRDİ HATIRLANDI", V18_PURPLE)
                create_tween().tween_property(gate, "position:y", 520.0, 0.44).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
        else: _false_alarm()
    elif x >= 5480.0 and x <= 5900.0 and _once("163_jump_late"):
        if a % 3 == 1: _reverse_controls(0.68)
        else: _false_alarm()

func _level_16_1() -> void:
    _floor_with_gaps(6700, [Vector2(2050, 2210), Vector2(4450, 4610)])
    _text(Vector2(120, 470), "BÖLÜM 16: TUŞUN DA PARKURUN PARÇASI.", 23, V18_CYAN)
    _text(Vector2(430, 520), "HER ZIPLAMA CEZA DEĞİL.", 18, V18_MUTED)
    _safe_pad(Vector2(900, 548), 185.0)
    _moving_platform(Vector2(2130, 555), Vector2(150, 24), Vector2(2170, 470), 1.36, V18_BLUE)
    var reactive := _platform(Vector2(2860, 548), Vector2(200, 26), V18_CYAN.lerp(V18_SLATE, 0.60))
    reactive.name = "Ch16Reactive161"
    _trigger(Rect2(3260, 390, 120, 240), func():
        if _once("161_back_arm"):
            _arm_backtrack(165.0, "161_back", func():
                _input_notice("GERİ DÖNDÜN", V18_AMBER)
                _false_alarm()
            )
    )
    _trigger(Rect2(3800, 390, 120, 240), func():
        if _once("161_fall"): _falling_boulder(Vector2(4060, 20), 56.0, 0.0)
    )
    _moving_platform(Vector2(4530, 555), Vector2(145, 24), Vector2(4570, 470), 1.30, V18_CYAN)
    var last := _spikes(Vector2(5460, 612), 3, true)
    _trigger(Rect2(5200, 390, 120, 240), func(): _timed_hazard(last, 0.32, 0.46, "161_last"))
    _finish(Vector2(6350, 580))

func _level_16_2() -> void:
    _floor_with_gaps(7200, [Vector2(1820, 1980), Vector2(4800, 4960)])
    _text(Vector2(120, 470), "ZIPLA / BEKLE / GERİ DÖN.", 23, V18_CYAN)
    _text(Vector2(430, 520), "OYUN KARARININ TÜRÜNÜ AYIRIYOR.", 18, V18_MUTED)
    _safe_pad(Vector2(980, 548), 185.0)
    _moving_platform(Vector2(1900, 555), Vector2(150, 24), Vector2(1940, 470), 1.34, V18_BLUE)
    var gate := _hazard_block(Vector2(2860, 220), Vector2(150, 72), V18_RED_DARK)
    gate.name = "Ch16Gate162"
    _trigger(Rect2(3260, 390, 120, 240), func():
        if _once("162_back_arm"):
            _arm_backtrack(180.0, "162_back", func():
                var spikes := _spikes(Vector2(3100, 612), 3, true)
                _input_notice("GERİ DÖNÜŞ")
                _reveal(spikes)
                var tw := create_tween()
                tw.tween_interval(0.44)
                tw.tween_callback(func(): _hide(spikes))
            )
    )
    var wait_spikes := _spikes(Vector2(3810, 612), 3, true)
    _trigger(Rect2(3540, 390, 300, 240), func():
        _wait_check(3710.0, 145.0, 1.00, func():
            _input_notice("BEKLEDİN", V18_AMBER)
            _reveal(wait_spikes)
            var tw := create_tween()
            tw.tween_interval(0.44)
            tw.tween_callback(func(): _hide(wait_spikes))
        , "162_wait")
    )
    _moving_platform(Vector2(4880, 555), Vector2(145, 24), Vector2(4920, 470), 1.30, V18_CYAN)
    _trigger(Rect2(5300, 390, 120, 240), func():
        if _once("162_rock"):
            var tw := create_tween()
            tw.tween_interval(0.42)
            tw.tween_callback(func(): _boulder(Vector2(5900, 560), -365.0, 70.0))
    )
    var safe_end := _safe_pad(Vector2(6260, 548), 180.0)
    _trigger(Rect2(6000, 390, 120, 240), func():
        if _once("162_safe_end"):
            _false_alarm()
            create_tween().tween_property(safe_end, "position:x", 6264.0, 0.12)
    )
    _finish(Vector2(6880, 580))

func _level_16_3() -> void:
    _floor_with_gaps(8000, [Vector2(1760, 1920), Vector2(3980, 4140), Vector2(6200, 6360)])
    var a := _attempt(16, 3)
    _text(Vector2(120, 470), "GİRDİNİ HATIRLIYORUM.", 24, V18_PURPLE)
    _text(Vector2(430, 520), "DENEME %d — AYNI ZIPLAMA AYNI CEVAP DEĞİL." % a, 18, V18_MUTED)
    _moving_platform(Vector2(1840, 555), Vector2(150, 24), Vector2(1880, 470), 1.34, V18_CYAN)
    _route_hint(Vector2(2400, 500), "A")
    _route_hint(Vector2(2400, 390), "B")
    _platform(Vector2(2510, 465), Vector2(230, 24), V18_BLUE)
    _platform(Vector2(2800, 435), Vector2(210, 24), V18_BLUE)
    _trigger(Rect2(2290, 315, 220, 175), func():
        if _choose_route("upper"): _false_alarm()
    )
    _trigger(Rect2(2290, 500, 220, 150), func():
        if _choose_route("lower"): _input_notice("A", V18_CYAN)
    )
    var route_gate := _hazard_block(Vector2(3550, 220), Vector2(150, 72), V18_RED_DARK)
    route_gate.name = "Ch16Gate163"
    _moving_platform(Vector2(4060, 555), Vector2(145, 24), Vector2(4100, 470), 1.28, V18_BLUE)
    _trigger(Rect2(4470, 390, 120, 240), func():
        if _once("163_back_arm"):
            _arm_backtrack(175.0, "163_back", func():
                if a % 2 == 0: _false_alarm()
                else:
                    _input_notice("GERİ DÖNÜŞ HATIRLANDI", V18_PURPLE)
                    _reverse_controls(0.66)
            )
    )
    var wait_gate := _spikes(Vector2(5050, 612), 3, true)
    _trigger(Rect2(4780, 390, 300, 240), func():
        _wait_check(4960.0, 145.0, 0.96, func():
            if a % 3 == 2: _false_alarm()
            else:
                _reveal(wait_gate)
                var tw := create_tween()
                tw.tween_interval(0.42)
                tw.tween_callback(func(): _hide(wait_gate))
        , "163_wait")
    )
    _moving_platform(Vector2(6280, 555), Vector2(145, 24), Vector2(6320, 470), 1.28, V18_CYAN)
    _trigger(Rect2(6660, 390, 120, 240), func():
        if _once("163_rock"):
            var tw := create_tween()
            tw.tween_interval(0.42)
            tw.tween_callback(func(): _boulder(Vector2(7280, 560), -360.0, 70.0))
    )
    var goal := _finish(Vector2(7660, 580))
    _trigger(Rect2(7350, 390, 120, 240), func():
        if _once("163_goal") and a % 3 == 1:
            create_tween().tween_property(goal, "position:x", 7790.0, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )
