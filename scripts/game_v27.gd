extends "res://scripts/game_v26.gd"

const V27_SIGNAL := Color("#38bdf8")
const V27_SIGNAL_ALT := Color("#a78bfa")
const V27_WARNING := Color("#f59e0b")
const V27_DANGER := Color("#fb7185")
const V27_FX_LIMIT := 10

var v27_fx_live := 0
var v27_prev_grounded := false
var v27_last_contact_msec := 0

func _safe_load_progress() -> void:
    super._safe_load_progress()
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return
    var stored_unlock = cfg.get_value("progress", "unlocked_chapter", 1)
    if stored_unlock is int or stored_unlock is float:
        unlocked_chapter = clampi(int(stored_unlock), 1, 24)

func _start_level(c: int, p: int) -> void:
    v27_prev_grounded = false
    super._start_level(c, p)
    if c == 23:
        RenderingServer.set_default_clear_color(Color("#060914"))
        _v27_add_signal_environment()

func _build_level(c: int, p: int) -> void:
    if c == 23 and p == 1:
        _v27_level_23_1()
    elif c == 23 and p == 2:
        _v27_level_23_2()
    elif c == 23 and p == 3:
        _v27_level_23_3()
    else:
        super._build_level(c, p)

func _process(delta: float) -> void:
    super._process(delta)
    if not is_instance_valid(player):
        v27_prev_grounded = false
        return
    var grounded := player.is_on_floor()
    if grounded and not v27_prev_grounded and v20_effects_enabled:
        var now := Time.get_ticks_msec()
        if now - v27_last_contact_msec >= 150:
            v27_last_contact_msec = now
            _v27_platform_contact(player.global_position + Vector2(0, 19))
    v27_prev_grounded = grounded

func _build_hud() -> void:
    super._build_hud()
    if not is_instance_valid(hud):
        return

    if chapter >= 21:
        var readability := ColorRect.new()
        readability.position = Vector2(330, 8)
        readability.size = Vector2(380, 50)
        readability.color = Color(0.015, 0.025, 0.055, 0.58)
        readability.mouse_filter = Control.MOUSE_FILTER_IGNORE
        readability.z_index = -32
        hud.add_child(readability)
        for child in hud.get_children():
            if child is Label:
                var label := child as Label
                if label.text.begins_with("SÜRE") or label.text.begins_with("DENEME"):
                    label.add_theme_color_override("font_color", V25_TEXT)

    if chapter == 23:
        var mode := Label.new()
        mode.position = Vector2(665, 45)
        mode.size = Vector2(230, 22)
        mode.text = "SİNYAL / ÖNSEZİ"
        mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        mode.add_theme_font_size_override("font_size", 11)
        mode.add_theme_color_override("font_color", V27_SIGNAL)
        hud.add_child(mode)

func _show_main_menu() -> void:
    super._show_main_menu()
    if not is_instance_valid(hud):
        return
    for child in hud.get_children():
        if child is Label:
            var label := child as Label
            if label.text == "ANDROID • v2.6":
                label.text = "ANDROID • v2.7"
            elif label.text == "KARANLIK DÖNEM • BÖLÜM 22: GÖLGE":
                label.text = "KARANLIK DÖNEM • BÖLÜM 23: SİNYAL"
            elif label.text.begins_with("REKOR KAYDI"):
                label.text = "REKOR KAYDI  %d / 69" % best_times_ms.size()
            elif label.text.begins_with("AÇIK BÖLÜM"):
                var available := maxi(1, mini(unlocked_chapter, 23))
                var completed_maps := maxi(0, (mini(unlocked_chapter, 24) - 1) * 3)
                label.text = "AÇIK BÖLÜM   %d / 23\nHARİTA        %d / 69\nTOPLAM ÖLÜM   %d" % [available, completed_maps, deaths]
            elif label.text == "İÇERİK ÜRETİMİ  66 / 300":
                label.text = "İÇERİK ÜRETİMİ  69 / 300"
            elif label.text == "Gölgeler yolu saklıyor; son ölüm izin artık sana geri bakıyor.":
                label.text = "Sinyaller yaklaşan tehlikeyi fısıldıyor. Ama her sinyal doğru değil."
            elif label.text.begins_with("v2.6 GÖLGE / ÖLÜM İZİ"):
                label.text = "v2.7 SİNYAL / OYUN HİSSİ\n\n• Tehlike önsezi çizgileri ve sahte sinyaller\n• Platform temasında hafif enerji halkası\n• Karanlık HUD okunaklığı geliştirildi\n• Mobil efekt bütçesi ile yeni efektler sınırlandı"
        elif child is Button:
            var button := child as Button
            if button.text == "DEVAM ET":
                button.visible = false
                button.disabled = true
        elif child is ColorRect:
            var rect := child as ColorRect
            if is_equal_approx(rect.position.x, 98.0) and is_equal_approx(rect.position.y, 386.0) and is_equal_approx(rect.size.y, 10.0) and rect.size.x < 600.0:
                rect.size.x = 620.0 * 69.0 / 300.0
    _v25_button("DEVAM ET", Vector2(790, 350), Vector2(390, 60), func(): _start_level(maxi(1, mini(unlocked_chapter, 23)), 1), V27_SIGNAL)

func _show_chapter_select() -> void:
    super._show_chapter_select()
    if not is_instance_valid(hud):
        return
    for child in hud.get_children():
        if child is Label:
            var label := child as Label
            if label.text == "22 BÖLÜM • 66 HARİTA • KARANLIK FAZ":
                label.text = "23 BÖLÜM • 69 HARİTA • KARANLIK FAZ"
            elif label.text.begins_with("Bölüm 21-40:"):
                label.text = "Bölüm 21-40: Karanlık dönem • Bölüm 23 sinyalleri okumayı ve sorgulamayı öğretiyor"

    var chapter_id := 23
    var is_unlocked := chapter_id <= unlocked_chapter
    var button_text := "BÖLÜM 23\nSİNYAL" if is_unlocked else "BÖLÜM 23\nKİLİTLİ"
    var button := _v25_button(button_text, Vector2(648, 461), Vector2(276, 56), func(): _start_level(23, 1), V27_SIGNAL)
    button.disabled = not is_unlocked

func _show_chapter_result() -> void:
    if chapter != 23:
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
    bg.color = V25_BG
    hud.add_child(bg)
    var line := ColorRect.new()
    line.size = Vector2(1280, 4)
    line.color = V27_SIGNAL
    hud.add_child(line)

    var title := Label.new()
    title.position = Vector2(140, 66)
    title.size = Vector2(1000, 220)
    title.text = "BÖLÜM 23 TAMAMLANDI\n\nHER UYARI GERÇEK DEĞİL"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 36)
    title.add_theme_color_override("font_color", V25_TEXT)
    hud.add_child(title)

    var stats := Label.new()
    stats.position = Vector2(95, 310)
    stats.size = Vector2(1090, 150)
    stats.text = "23-1  %s / %s ölüm     23-2  %s / %s ölüm     23-3  %s / %s ölüm\n\nSİNYALİ GÖR. AMA KARARINI SADECE ONA BIRAKMA." % [_best_time_text(23, 1), _best_deaths_text(23, 1), _best_time_text(23, 2), _best_deaths_text(23, 2), _best_time_text(23, 3), _best_deaths_text(23, 3)]
    stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    stats.add_theme_font_size_override("font_size", 18)
    stats.add_theme_color_override("font_color", V27_SIGNAL)
    hud.add_child(stats)

    var milestone := Label.new()
    milestone.position = Vector2(180, 485)
    milestone.size = Vector2(920, 45)
    milestone.text = "23 / 100 BÖLÜM   •   69 / 300 HARİTA   •   %23 İÇERİK"
    milestone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    milestone.add_theme_font_size_override("font_size", 18)
    milestone.add_theme_color_override("font_color", V25_MUTED)
    hud.add_child(milestone)
    _v25_button("ANA MENÜ", Vector2(490, 565), Vector2(300, 64), func(): _show_main_menu(), V27_SIGNAL)

func _v24_open_dev_console() -> void:
    super._v24_open_dev_console()
    if not is_instance_valid(v24_dev_overlay):
        return
    for panel_child in v24_dev_overlay.get_children():
        for child in panel_child.get_children():
            if child is Label and child.text.begins_with("Komut biçimi:"):
                child.text = "Komut biçimi: WAREXT 23-3\nBölüm 1-23 • Kısım 1-3"

func _v24_execute_dev_command(command: String) -> void:
    var raw := command.strip_edges().to_upper()
    if not raw.begins_with("WAREXT "):
        _v24_dev_error("Kod WAREXT ile başlamalı. Örnek: WAREXT 23-3")
        return
    var target := raw.trim_prefix("WAREXT ").strip_edges()
    var pieces := target.split("-")
    if pieces.size() != 2:
        _v24_dev_error("Biçim hatalı. Örnek: WAREXT 12-2")
        return
    var chapter_text := String(pieces[0]).strip_edges()
    var part_text := String(pieces[1]).strip_edges()
    if not chapter_text.is_valid_int() or not part_text.is_valid_int():
        _v24_dev_error("Bölüm ve kısım sayı olmalı.")
        return
    var target_chapter: int = int(chapter_text)
    var target_part: int = int(part_text)
    if target_chapter < 1 or target_chapter > 23:
        _v24_dev_error("Bölüm 1 ile 23 arasında olmalı.")
        return
    if target_part < 1 or target_part > 3:
        _v24_dev_error("Kısım 1 ile 3 arasında olmalı.")
        return
    _v24_close_dev_console()
    v24_dev_session = true
    _start_level(target_chapter, target_part)

func _v27_fx_begin(lifetime: float) -> bool:
    if not v20_effects_enabled or v27_fx_live >= V27_FX_LIMIT:
        return false
    v27_fx_live += 1
    var timer := get_tree().create_timer(maxf(0.12, lifetime))
    timer.timeout.connect(func(): v27_fx_live = maxi(0, v27_fx_live - 1))
    return true

func _v27_platform_contact(pos: Vector2) -> void:
    if not is_instance_valid(world) or not _v27_fx_begin(0.34):
        return
    var ring := Line2D.new()
    ring.position = pos
    ring.width = 2.0
    ring.closed = true
    ring.default_color = Color(V27_SIGNAL, 0.46)
    ring.points = _circle_points(15.0, 20)
    ring.scale = Vector2(0.65, 0.25)
    ring.z_index = 17
    world.add_child(ring)
    var tw := create_tween()
    tw.set_parallel(true)
    tw.tween_property(ring, "scale", Vector2(1.75, 0.48), 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tw.tween_property(ring, "modulate:a", 0.0, 0.30)
    tw.set_parallel(false)
    tw.tween_callback(ring.queue_free)

func _v27_signal_line(x: float, color: Color = V27_SIGNAL, duration: float = 0.42) -> void:
    if not is_instance_valid(world) or not _v27_fx_begin(duration + 0.20):
        return
    var line := Line2D.new()
    line.width = 3.0
    line.default_color = Color(color, 0.62)
    line.points = PackedVector2Array([Vector2(x, 280), Vector2(x, 635)])
    line.z_index = 14
    world.add_child(line)
    var dot := Polygon2D.new()
    dot.position = Vector2(x, 610)
    dot.polygon = _circle_points(7.0, 16)
    dot.color = Color(color, 0.62)
    dot.z_index = 15
    world.add_child(dot)
    var tw := create_tween()
    tw.tween_interval(maxf(0.10, duration * 0.48))
    tw.set_parallel(true)
    tw.tween_property(line, "modulate:a", 0.0, maxf(0.12, duration * 0.52))
    tw.tween_property(dot, "modulate:a", 0.0, maxf(0.12, duration * 0.52))
    tw.set_parallel(false)
    tw.tween_callback(line.queue_free)
    tw.tween_callback(dot.queue_free)

func _v27_add_signal_environment() -> void:
    if not is_instance_valid(world):
        return
    for i in range(16):
        var x := 260.0 + float(i) * 450.0
        if x > level_width:
            break
        var dash := Line2D.new()
        dash.width = 1.0
        dash.default_color = Color(V27_SIGNAL_ALT, 0.045 if i % 2 == 0 else 0.025)
        dash.points = PackedVector2Array([Vector2(x, 150), Vector2(x + 110, 150)])
        dash.z_index = -105
        world.add_child(dash)

func _v27_level_23_1() -> void:
    _floor_with_gaps(6400, [Vector2(1840, 2000), Vector2(4040, 4200)])
    _text(Vector2(120, 470), "BÖLÜM 23: SİNYAL.", 25, V27_SIGNAL)
    _text(Vector2(390, 520), "ÇİZGİ BİR ŞEY OLACAĞINI SÖYLER. BAZEN YALAN SÖYLER.", 17, V25_MUTED)

    var first := _spikes(Vector2(1120, 612), 3, true)
    _trigger(Rect2(700, 390, 130, 240), func():
        if _once("231_true_signal"):
            _v27_signal_line(1120.0, V27_WARNING, 0.46)
            var tw := create_tween()
            tw.tween_interval(0.48)
            tw.tween_callback(func(): _reveal(first))
            tw.tween_interval(0.54)
            tw.tween_callback(func(): _hide(first))
    )

    _trigger(Rect2(1360, 390, 130, 240), func():
        if _once("231_false_signal"):
            _v27_signal_line(1620.0, V27_DANGER, 0.48)
            _false_alarm()
    )

    _moving_platform(Vector2(1920, 555), Vector2(145, 24), Vector2(1960, 470), 1.42, V25_BLUE)

    var gate := _hazard_block(Vector2(2700, 210), Vector2(120, 70), V25_RED)
    _trigger(Rect2(2280, 390, 130, 240), func():
        if _once("231_gate"):
            _v27_signal_line(2700.0, V27_SIGNAL, 0.44)
            var tw := create_tween()
            tw.tween_interval(0.46)
            tw.tween_property(gate, "position:y", 505.0, 0.46).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_interval(0.38)
            tw.tween_property(gate, "position:y", 210.0, 0.54).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

    _trigger(Rect2(3200, 390, 130, 240), func():
        if _once("231_harmless"):
            _v27_signal_line(3470.0, V27_WARNING, 0.42)
    )

    _moving_platform(Vector2(4120, 555), Vector2(145, 24), Vector2(4160, 472), 1.40, V25_CYAN)

    _trigger(Rect2(4540, 390, 130, 240), func():
        if _once("231_rock"):
            _v27_signal_line(5100.0, V27_DANGER, 0.44)
            var tw := create_tween()
            tw.tween_interval(0.50)
            tw.tween_callback(func(): _boulder(Vector2(5220, 560), -338.0, 64.0))
    )

    var final_spikes := _spikes(Vector2(5650, 612), 2, true)
    _trigger(Rect2(5350, 390, 120, 240), func():
        if _once("231_final"):
            _v27_signal_line(5650.0, V27_SIGNAL_ALT, 0.40)
            var tw := create_tween()
            tw.tween_interval(0.44)
            tw.tween_callback(func(): _reveal(final_spikes))
            tw.tween_interval(0.52)
            tw.tween_callback(func(): _hide(final_spikes))
    )
    _finish(Vector2(6140, 580))

func _v27_level_23_2() -> void:
    _floor_with_gaps(7000, [Vector2(1540, 1700), Vector2(3580, 3740), Vector2(5480, 5640)])
    _text(Vector2(120, 470), "RENK DEĞİL, SONUÇ ÖNEMLİ.", 24, V27_SIGNAL_ALT)

    _trigger(Rect2(600, 390, 120, 240), func():
        if _once("232_false_first"):
            _v27_signal_line(930.0, V27_DANGER, 0.44)
            _false_alarm()
    )

    var early := _spikes(Vector2(1280, 612), 3, true)
    _trigger(Rect2(880, 390, 120, 240), func():
        if _once("232_true_first"):
            _v27_signal_line(1280.0, V27_SIGNAL, 0.44)
            var tw := create_tween()
            tw.tween_interval(0.48)
            tw.tween_callback(func(): _reveal(early))
            tw.tween_interval(0.54)
            tw.tween_callback(func(): _hide(early))
    )

    _moving_platform(Vector2(1620, 555), Vector2(145, 24), Vector2(1660, 472), 1.40, V25_CYAN)

    _route_hint(Vector2(2530, 490), "ALT")
    _route_hint(Vector2(2530, 385), "ÜST")
    _platform(Vector2(2620, 455), Vector2(240, 24), V25_PLATFORM_ALT)
    _trigger(Rect2(2290, 305, 260, 185), func():
        if _choose_route("upper"):
            _v25_pulse_notice("ÜST", V27_SIGNAL_ALT)
    )
    _trigger(Rect2(2290, 490, 260, 150), func():
        if _choose_route("lower"):
            _v25_pulse_notice("ALT", V27_SIGNAL)
    )

    var route_spikes := _spikes(Vector2(3220, 612), 3, true)
    _trigger(Rect2(2920, 390, 120, 240), func():
        if _once("232_route"):
            _v27_signal_line(3220.0, V27_WARNING, 0.42)
            if route_choice == "upper":
                var tw := create_tween()
                tw.tween_interval(0.46)
                tw.tween_callback(func(): _reveal(route_spikes))
                tw.tween_interval(0.52)
                tw.tween_callback(func(): _hide(route_spikes))
            else:
                _false_alarm()
    )

    _moving_platform(Vector2(3660, 555), Vector2(145, 24), Vector2(3700, 470), 1.42, V25_BLUE)

    var ceiling := _spikes(Vector2(4300, 345), 3, true, true)
    _trigger(Rect2(4010, 350, 140, 280), func():
        if _once("232_ceiling"):
            _v27_signal_line(4300.0, V27_DANGER, 0.42)
            var tw := create_tween()
            tw.tween_interval(0.46)
            tw.tween_callback(func(): _reveal(ceiling))
            tw.tween_interval(0.56)
            tw.tween_callback(func(): _hide(ceiling))
    )

    _trigger(Rect2(4760, 390, 150, 240), func():
        if _once("232_fake_late"):
            _v27_signal_line(5020.0, V27_SIGNAL, 0.46)
    )

    _moving_platform(Vector2(5560, 555), Vector2(145, 24), Vector2(5600, 472), 1.42, V25_CYAN)

    _trigger(Rect2(5950, 390, 120, 240), func():
        if _once("232_rock"):
            _v27_signal_line(6420.0, V27_WARNING, 0.44)
            var tw := create_tween()
            tw.tween_interval(0.50)
            tw.tween_callback(func(): _boulder(Vector2(6560, 560), -336.0, 64.0))
    )
    _finish(Vector2(6740, 580))

func _v27_level_23_3() -> void:
    _floor_with_gaps(7700, [Vector2(1720, 1880), Vector2(3980, 4140), Vector2(6080, 6240)])
    var attempt: int = _attempt(23, 3)
    _text(Vector2(120, 470), "SİNYAL DE SENİ HATIRLIYOR.", 24, V27_SIGNAL_ALT)
    _text(Vector2(430, 520), "DENEME %d" % attempt, 17, V25_MUTED)

    var first_a := _spikes(Vector2(950, 612), 3, true)
    var first_b := _spikes(Vector2(1320, 612), 3, true)
    _trigger(Rect2(650, 390, 120, 240), func():
        if _once("233_first"):
            var target_x := 950.0 if attempt % 2 == 1 else 1320.0
            var target: Area2D = first_a if attempt % 2 == 1 else first_b
            _v27_signal_line(target_x, V27_SIGNAL, 0.44)
            _v27_signal_line(1320.0 if attempt % 2 == 1 else 950.0, V27_DANGER, 0.44)
            var tw := create_tween()
            tw.tween_interval(0.48)
            tw.tween_callback(func(): _reveal(target))
            tw.tween_interval(0.54)
            tw.tween_callback(func(): _hide(target))
    )

    _moving_platform(Vector2(1800, 555), Vector2(145, 24), Vector2(1840, 470), 1.42, V25_CYAN)

    var gate := _hazard_block(Vector2(2500, 210), Vector2(120, 70), V25_RED)
    _trigger(Rect2(2150, 390, 130, 240), func():
        if _once("233_gate"):
            var honest := attempt % 3 != 0
            _v27_signal_line(2500.0, V27_WARNING if honest else V27_SIGNAL, 0.44)
            if honest:
                var tw := create_tween()
                tw.tween_interval(0.48)
                tw.tween_property(gate, "position:y", 505.0, 0.46).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
                tw.tween_interval(0.38)
                tw.tween_property(gate, "position:y", 210.0, 0.54).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
            else:
                _false_alarm()
    )

    _route_hint(Vector2(3320, 490), "SOL")
    _route_hint(Vector2(3320, 385), "ÜST")
    _platform(Vector2(3410, 455), Vector2(240, 24), V25_PLATFORM_ALT)
    _trigger(Rect2(3080, 305, 260, 185), func():
        if _choose_route("upper"):
            _v25_pulse_notice("ÜST", V27_SIGNAL_ALT)
    )
    _trigger(Rect2(3080, 490, 260, 150), func():
        if _choose_route("lower"):
            _v25_pulse_notice("SOL", V27_SIGNAL)
    )

    _moving_platform(Vector2(4060, 555), Vector2(145, 24), Vector2(4100, 472), 1.40, V25_BLUE)

    var route_trap := _spikes(Vector2(4720, 612), 3, true)
    _trigger(Rect2(4400, 390, 120, 240), func():
        if _once("233_route"):
            var route_bad := (attempt % 2 == 0 and route_choice == "upper") or (attempt % 2 == 1 and route_choice == "lower")
            _v27_signal_line(4720.0, V27_DANGER if route_bad else V27_SIGNAL, 0.44)
            if route_bad:
                var tw := create_tween()
                tw.tween_interval(0.48)
                tw.tween_callback(func(): _reveal(route_trap))
                tw.tween_interval(0.54)
                tw.tween_callback(func(): _hide(route_trap))
            else:
                _false_alarm()
    )

    var wait_gate := _hazard_block(Vector2(5500, 210), Vector2(120, 70), V25_RED)
    _trigger(Rect2(5150, 390, 260, 240), func():
        _wait_check(5300.0, 165.0, 1.10, func():
            _v27_signal_line(5500.0, V27_WARNING, 0.42)
            var tw := create_tween()
            tw.tween_interval(0.46)
            tw.tween_property(wait_gate, "position:y", 505.0, 0.46).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_interval(0.38)
            tw.tween_property(wait_gate, "position:y", 210.0, 0.54).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        , "233_wait")
    )

    _moving_platform(Vector2(6160, 555), Vector2(145, 24), Vector2(6200, 470), 1.42, V25_CYAN)

    _trigger(Rect2(6460, 390, 120, 240), func():
        if _once("233_rock"):
            _v27_signal_line(7040.0, V27_SIGNAL_ALT, 0.44)
            var tw := create_tween()
            tw.tween_interval(0.52)
            if attempt % 3 == 1:
                tw.tween_callback(func(): _boulder(Vector2(7160, 560), -334.0, 64.0))
            else:
                tw.tween_callback(_false_alarm)
    )

    var last := _spikes(Vector2(7040, 612), 2, true)
    _trigger(Rect2(6800, 390, 120, 240), func():
        if _once("233_last"):
            if attempt % 3 != 1:
                _v27_signal_line(7040.0, V27_WARNING, 0.42)
                var tw := create_tween()
                tw.tween_interval(0.46)
                tw.tween_callback(func(): _reveal(last))
                tw.tween_interval(0.54)
                tw.tween_callback(func(): _hide(last))
    )
    _finish(Vector2(7440, 580))

func _v23_run_validation() -> void:
    await get_tree().process_frame
    var failures: int = 0
    var checked: int = 0
    for c in range(1, 24):
        for p in range(1, 4):
            _start_level(c, p)
            await get_tree().process_frame
            await get_tree().process_frame
            checked += 1
            var level_failures: int = _v23_validate_current_level(c, p)
            failures += level_failures
            if level_failures == 0:
                print("LEVEL_VALIDATE_OK:%d-%d" % [c, p])
            else:
                print("LEVEL_VALIDATE_FAIL:%d-%d:%d" % [c, p, level_failures])
    if failures == 0 and checked == 69:
        print("ALL_LEVELS_OK:69")
        get_tree().quit(0)
    else:
        print("ALL_LEVELS_FAILED:%d:%d" % [checked, failures])
        get_tree().quit(1)
