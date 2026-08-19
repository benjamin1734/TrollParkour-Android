extends "res://scripts/game_v27.gd"

const V28_TRACK := Color("#22d3ee")
const V28_TRACK_ALT := Color("#818cf8")
const V28_RISK_LOW := Color("#34d399")
const V28_RISK_MED := Color("#f59e0b")
const V28_RISK_HIGH := Color("#fb7185")
const V28_PATH_LIMIT := 18
const V28_PATH_SAMPLE_MS := 80

var v28_path_samples: Array[Vector2] = []
var v28_last_path: Array[Vector2] = []
var v28_path_pending := false
var v28_path_key := ""
var v28_last_sample_msec := 0
var v28_risk_level := 0
var v28_risk_until_msec := 0
var v28_risk_label: Label

func _safe_load_progress() -> void:
    super._safe_load_progress()
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return
    var stored_unlock = cfg.get_value("progress", "unlocked_chapter", 1)
    if stored_unlock is int or stored_unlock is float:
        unlocked_chapter = clampi(int(stored_unlock), 1, 25)

func _start_level(c: int, p: int) -> void:
    var next_key := _map_key(c, p)
    var show_path := v28_path_pending and v28_path_key == next_key
    if v28_path_pending and v28_path_key != next_key:
        v28_path_pending = false
        v28_path_key = ""
        v28_last_path.clear()
    v27_fx_live = 0
    v27_prev_grounded = false
    v27_last_contact_msec = 0
    v28_path_samples.clear()
    v28_last_sample_msec = 0
    v28_risk_level = 0
    v28_risk_until_msec = 0
    v28_risk_label = null
    super._start_level(c, p)
    if show_path and is_instance_valid(world):
        _v28_add_death_path(v28_last_path)
        v28_path_pending = false
    if c == 24:
        RenderingServer.set_default_clear_color(Color("#050812"))
        _v28_add_tracker_environment()

func _build_level(c: int, p: int) -> void:
    if c == 24 and p == 1:
        _v28_level_24_1()
    elif c == 24 and p == 2:
        _v28_level_24_2()
    elif c == 24 and p == 3:
        _v28_level_24_3()
    else:
        super._build_level(c, p)

func _process(delta: float) -> void:
    super._process(delta)
    if is_instance_valid(player) and not restarting and not level_finished:
        var now := Time.get_ticks_msec()
        if now - v28_last_sample_msec >= V28_PATH_SAMPLE_MS:
            v28_last_sample_msec = now
            v28_path_samples.append(player.global_position)
            while v28_path_samples.size() > V28_PATH_LIMIT:
                v28_path_samples.pop_front()
    if is_instance_valid(v28_risk_label):
        if v28_risk_until_msec > 0 and Time.get_ticks_msec() > v28_risk_until_msec:
            v28_risk_level = 0
            v28_risk_until_msec = 0
        _v28_refresh_risk_label()

func _build_hud() -> void:
    super._build_hud()
    if not is_instance_valid(hud):
        return
    var panel := ColorRect.new()
    panel.position = Vector2(885, 8)
    panel.size = Vector2(118, 50)
    panel.color = Color(0.015, 0.025, 0.055, 0.64) if chapter >= 21 else Color(1.0, 1.0, 1.0, 0.62)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.z_index = -31
    hud.add_child(panel)
    v28_risk_label = Label.new()
    v28_risk_label.position = Vector2(888, 18)
    v28_risk_label.size = Vector2(112, 30)
    v28_risk_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    v28_risk_label.add_theme_font_size_override("font_size", 12)
    hud.add_child(v28_risk_label)
    _v28_refresh_risk_label()
    if chapter == 24:
        var mode := Label.new()
        mode.position = Vector2(665, 45)
        mode.size = Vector2(230, 22)
        mode.text = "TAKİP / TEHDİT"
        mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        mode.add_theme_font_size_override("font_size", 11)
        mode.add_theme_color_override("font_color", V28_TRACK)
        hud.add_child(mode)

func _on_player_died() -> void:
    if restarting or level_finished:
        return
    if not v28_path_samples.is_empty():
        v28_last_path = v28_path_samples.duplicate()
        v28_path_key = _map_key()
        v28_path_pending = true
    super._on_player_died()

func _show_main_menu() -> void:
    v28_path_pending = false
    v28_path_key = ""
    v28_last_path.clear()
    super._show_main_menu()
    if not is_instance_valid(hud):
        return
    for child in hud.get_children():
        if child is Label:
            var label := child as Label
            if label.text == "ANDROID • v2.7":
                label.text = "ANDROID • v2.8"
            elif label.text == "KARANLIK DÖNEM • BÖLÜM 23: SİNYAL":
                label.text = "KARANLIK DÖNEM • BÖLÜM 24: TAKİP"
            elif label.text.begins_with("REKOR KAYDI"):
                label.text = "REKOR KAYDI  %d / 72" % best_times_ms.size()
            elif label.text.begins_with("AÇIK BÖLÜM"):
                var available := maxi(1, mini(unlocked_chapter, 24))
                var completed_maps := maxi(0, (mini(unlocked_chapter, 25) - 1) * 3)
                label.text = "AÇIK BÖLÜM   %d / 24\nHARİTA        %d / 72\nTOPLAM ÖLÜM   %d" % [available, completed_maps, deaths]
            elif label.text == "İÇERİK ÜRETİMİ  69 / 300":
                label.text = "İÇERİK ÜRETİMİ  72 / 300"
            elif label.text == "Sinyaller yaklaşan tehlikeyi fısıldıyor. Ama her sinyal doğru değil.":
                label.text = "Tehdit seni izliyor; kilitlendiği an nereye kaçacağını seç."
            elif label.text.begins_with("v2.7 SİNYAL / OYUN HİSSİ"):
                label.text = "v2.8 TAKİP / RİSK\n\n• Ölümden önceki kısa rota sonraki denemede görünür\n• HUD'a anlık risk göstergesi eklendi\n• Tehdit alanı önce takip eder sonra konuma kilitlenir\n• Efekt sayaçları harita geçişinde artık tamamen temizlenir"
        elif child is Button:
            var button := child as Button
            if button.text == "DEVAM ET":
                button.visible = false
                button.disabled = true
        elif child is ColorRect:
            var rect := child as ColorRect
            if is_equal_approx(rect.position.x, 98.0) and is_equal_approx(rect.position.y, 386.0) and is_equal_approx(rect.size.y, 10.0) and rect.size.x < 600.0:
                rect.size.x = 620.0 * 72.0 / 300.0
    _v25_button("DEVAM ET", Vector2(790, 350), Vector2(390, 60), func(): _start_level(maxi(1, mini(unlocked_chapter, 24)), 1), V28_TRACK)

func _show_chapter_select() -> void:
    super._show_chapter_select()
    if not is_instance_valid(hud):
        return
    for child in hud.get_children():
        if child is Label:
            var label := child as Label
            if label.text == "23 BÖLÜM • 69 HARİTA • KARANLIK FAZ":
                label.text = "24 BÖLÜM • 72 HARİTA • KARANLIK FAZ"
            elif label.text.begins_with("Bölüm 21-40:"):
                label.text = "Bölüm 21-40: Karanlık dönem • Bölüm 24 takip eden tehdit alanlarını tanıtıyor"
    var chapter_id := 24
    var is_unlocked := chapter_id <= unlocked_chapter
    var button_text := "BÖLÜM 24\nTAKİP" if is_unlocked else "BÖLÜM 24\nKİLİTLİ"
    var button := _v25_button(button_text, Vector2(948, 461), Vector2(276, 56), func(): _start_level(24, 1), V28_TRACK)
    button.disabled = not is_unlocked

func _show_chapter_result() -> void:
    if chapter != 24:
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
    line.color = V28_TRACK
    hud.add_child(line)
    var title := Label.new()
    title.position = Vector2(140, 66)
    title.size = Vector2(1000, 220)
    title.text = "BÖLÜM 24 TAMAMLANDI\n\nTEHDİT SENİ TAKİP EDER. SONSUZA KADAR DEĞİL."
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", V25_TEXT)
    hud.add_child(title)
    var stats := Label.new()
    stats.position = Vector2(95, 310)
    stats.size = Vector2(1090, 150)
    stats.text = "24-1  %s / %s ölüm     24-2  %s / %s ölüm     24-3  %s / %s ölüm\n\nTAKİP EDİLEN KONUMU OKU. KİLİTLENDİKTEN SONRA HAREKET ET." % [_best_time_text(24, 1), _best_deaths_text(24, 1), _best_time_text(24, 2), _best_deaths_text(24, 2), _best_time_text(24, 3), _best_deaths_text(24, 3)]
    stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    stats.add_theme_font_size_override("font_size", 18)
    stats.add_theme_color_override("font_color", V28_TRACK)
    hud.add_child(stats)
    var milestone := Label.new()
    milestone.position = Vector2(180, 485)
    milestone.size = Vector2(920, 45)
    milestone.text = "24 / 100 BÖLÜM   •   72 / 300 HARİTA   •   %24 İÇERİK"
    milestone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    milestone.add_theme_font_size_override("font_size", 18)
    milestone.add_theme_color_override("font_color", V25_MUTED)
    hud.add_child(milestone)
    _v25_button("ANA MENÜ", Vector2(490, 565), Vector2(300, 64), func(): _show_main_menu(), V28_TRACK)

func _v24_open_dev_console() -> void:
    super._v24_open_dev_console()
    if not is_instance_valid(v24_dev_overlay):
        return
    for panel_child in v24_dev_overlay.get_children():
        for child in panel_child.get_children():
            if child is Label and child.text.begins_with("Komut biçimi:"):
                child.text = "Komut biçimi: WAREXT 24-3\nBölüm 1-24 • Kısım 1-3"

func _v24_execute_dev_command(command: String) -> void:
    var raw := command.strip_edges().to_upper()
    if not raw.begins_with("WAREXT "):
        _v24_dev_error("Kod WAREXT ile başlamalı. Örnek: WAREXT 24-3")
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
    if target_chapter < 1 or target_chapter > 24:
        _v24_dev_error("Bölüm 1 ile 24 arasında olmalı.")
        return
    if target_part < 1 or target_part > 3:
        _v24_dev_error("Kısım 1 ile 3 arasında olmalı.")
        return
    _v24_close_dev_console()
    v24_dev_session = true
    _start_level(target_chapter, target_part)

func _v28_refresh_risk_label() -> void:
    if not is_instance_valid(v28_risk_label):
        return
    if v28_risk_level <= 0:
        v28_risk_label.text = "RİSK  —"
        v28_risk_label.add_theme_color_override("font_color", V25_MUTED if chapter >= 21 else V14_MUTED)
    elif v28_risk_level == 1:
        v28_risk_label.text = "RİSK  DÜŞÜK"
        v28_risk_label.add_theme_color_override("font_color", V28_RISK_LOW)
    elif v28_risk_level == 2:
        v28_risk_label.text = "RİSK  ORTA"
        v28_risk_label.add_theme_color_override("font_color", V28_RISK_MED)
    else:
        v28_risk_label.text = "RİSK  YÜKSEK"
        v28_risk_label.add_theme_color_override("font_color", V28_RISK_HIGH)

func _v28_set_risk(level: int, duration: float = 0.8) -> void:
    v28_risk_level = clampi(level, 0, 3)
    v28_risk_until_msec = Time.get_ticks_msec() + int(maxf(0.15, duration) * 1000.0)
    _v28_refresh_risk_label()

func _v28_add_death_path(points: Array[Vector2]) -> void:
    if not is_instance_valid(world) or points.size() < 2:
        return
    var line := Line2D.new()
    line.width = 2.0
    line.default_color = Color(V28_TRACK, 0.30)
    line.points = PackedVector2Array(points)
    line.z_index = 15
    world.add_child(line)
    for i in range(0, points.size(), 4):
        var dot := Polygon2D.new()
        dot.position = points[i]
        dot.polygon = _circle_points(4.0, 12)
        dot.color = Color(V28_TRACK_ALT, 0.38)
        dot.z_index = 16
        world.add_child(dot)

func _v28_tracker_line(x: float, color: Color = V28_TRACK, duration: float = 0.50) -> void:
    if not is_instance_valid(world) or not _v27_fx_begin(duration + 0.20):
        return
    var band := Line2D.new()
    band.width = 5.0
    band.default_color = Color(color, 0.54)
    band.points = PackedVector2Array([Vector2(x, 300), Vector2(x, 635)])
    band.z_index = 15
    world.add_child(band)
    var base := Line2D.new()
    base.width = 14.0
    base.default_color = Color(color, 0.10)
    base.points = band.points
    base.z_index = 14
    world.add_child(base)
    var tw := create_tween()
    tw.tween_interval(maxf(0.12, duration * 0.50))
    tw.set_parallel(true)
    tw.tween_property(band, "modulate:a", 0.0, maxf(0.12, duration * 0.50))
    tw.tween_property(base, "modulate:a", 0.0, maxf(0.12, duration * 0.50))
    tw.set_parallel(false)
    tw.tween_callback(band.queue_free)
    tw.tween_callback(base.queue_free)

func _v28_lock_player_lane(hazard: Area2D, key: String, lock_delay: float = 0.52) -> void:
    if not is_instance_valid(player) or not is_instance_valid(hazard) or not _once(key):
        return
    var lock_x := clampf(player.global_position.x + 105.0, 150.0, level_width - 180.0)
    _v28_set_risk(2, lock_delay + 0.9)
    _v28_tracker_line(lock_x, V28_RISK_MED, lock_delay)
    var tw := create_tween()
    tw.tween_interval(maxf(0.46, lock_delay))
    tw.tween_callback(func():
        if is_instance_valid(hazard):
            hazard.position.x = lock_x
            _v28_set_risk(3, 0.78)
    )
    tw.tween_interval(0.24)
    tw.tween_property(hazard, "position:y", 520.0, 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    tw.tween_interval(0.34)
    tw.tween_property(hazard, "position:y", 210.0, 0.50).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _v28_add_tracker_environment() -> void:
    if not is_instance_valid(world):
        return
    for i in range(14):
        var x := 320.0 + float(i) * 500.0
        if x > level_width:
            break
        var mark := Line2D.new()
        mark.width = 1.0
        mark.default_color = Color(V28_TRACK_ALT, 0.04)
        mark.points = PackedVector2Array([Vector2(x - 55, 185), Vector2(x + 55, 185)])
        mark.z_index = -104
        world.add_child(mark)

func _v28_level_24_1() -> void:
    _floor_with_gaps(6500, [Vector2(1880, 2040), Vector2(4200, 4360)])
    _text(Vector2(120, 470), "BÖLÜM 24: TAKİP.", 25, V28_TRACK)
    _text(Vector2(390, 520), "ÇİZGİ SENİ TAKİP ETMEZ. KONUMUNU KİLİTLER.", 17, V25_MUTED)
    var first_gate := _hazard_block(Vector2(1100, 210), Vector2(110, 70), V25_RED)
    _trigger(Rect2(650, 390, 140, 240), func():
        if not trigger_state.has("241_lock_a"):
            trigger_state["241_lock_a"] = true
            _v28_lock_player_lane(first_gate, "241_lock_a_real", 0.54)
    )
    _trigger(Rect2(1320, 390, 130, 240), func():
        if _once("241_fake"):
            _v28_set_risk(1, 0.72)
            _v28_tracker_line(1600.0, V28_TRACK_ALT, 0.50)
            _false_alarm()
    )
    _moving_platform(Vector2(1960, 555), Vector2(145, 24), Vector2(2000, 470), 1.42, V25_CYAN)
    var spikes := _spikes(Vector2(2860, 612), 3, true)
    _trigger(Rect2(2450, 390, 140, 240), func():
        if _once("241_spikes"):
            _v28_set_risk(2, 1.10)
            _v28_tracker_line(2860.0, V27_WARNING, 0.48)
            var tw := create_tween()
            tw.tween_interval(0.52)
            tw.tween_callback(func(): _reveal(spikes))
            tw.tween_interval(0.56)
            tw.tween_callback(func(): _hide(spikes))
    )
    var second_gate := _hazard_block(Vector2(3600, 210), Vector2(110, 70), V25_RED)
    _trigger(Rect2(3180, 390, 150, 240), func():
        if not trigger_state.has("241_lock_b"):
            trigger_state["241_lock_b"] = true
            _v28_lock_player_lane(second_gate, "241_lock_b_real", 0.58)
    )
    _moving_platform(Vector2(4280, 555), Vector2(145, 24), Vector2(4320, 472), 1.42, V25_BLUE)
    _trigger(Rect2(4700, 390, 120, 240), func():
        if _once("241_rock"):
            _v28_set_risk(2, 1.0)
            _v28_tracker_line(5240.0, V27_SIGNAL_ALT, 0.48)
            var tw := create_tween()
            tw.tween_interval(0.56)
            tw.tween_callback(func(): _boulder(Vector2(5400, 560), -330.0, 62.0))
    )
    var final_spikes := _spikes(Vector2(5820, 612), 2, true)
    _trigger(Rect2(5480, 390, 130, 240), func():
        if _once("241_final"):
            _v28_set_risk(2, 0.95)
            _v28_tracker_line(5820.0, V28_RISK_MED, 0.46)
            var tw := create_tween()
            tw.tween_interval(0.50)
            tw.tween_callback(func(): _reveal(final_spikes))
            tw.tween_interval(0.54)
            tw.tween_callback(func(): _hide(final_spikes))
    )
    _finish(Vector2(6250, 580))

func _v28_level_24_2() -> void:
    _floor_with_gaps(7000, [Vector2(1640, 1800), Vector2(3740, 3900), Vector2(5480, 5640)])
    _text(Vector2(120, 470), "TAKİP EDİLEN HER NOKTA TEHLİKE DEĞİL.", 23, V28_TRACK)
    _v28_tracker_line(760.0, V28_TRACK_ALT, 0.60)
    var harmless := _platform(Vector2(800, 555), Vector2(180, 24), V25_PLATFORM_ALT)
    _trigger(Rect2(560, 390, 130, 240), func():
        if _once("242_harmless"):
            _v28_set_risk(1, 0.72)
            create_tween().tween_property(harmless, "position:y", 552.0, 0.14)
            _false_alarm()
    )
    _moving_platform(Vector2(1720, 555), Vector2(145, 24), Vector2(1760, 470), 1.42, V25_CYAN)
    var gate_a := _hazard_block(Vector2(2500, 210), Vector2(115, 70), V25_RED)
    _trigger(Rect2(2100, 390, 140, 240), func():
        if not trigger_state.has("242_gate_a"):
            trigger_state["242_gate_a"] = true
            _v28_lock_player_lane(gate_a, "242_gate_a_real", 0.56)
    )
    _route_hint(Vector2(3180, 490), "ALT")
    _route_hint(Vector2(3180, 385), "ÜST")
    _platform(Vector2(3270, 455), Vector2(240, 24), V25_PLATFORM_ALT)
    _trigger(Rect2(2940, 305, 260, 185), func():
        if _choose_route("upper"):
            _v25_pulse_notice("ÜST", V28_TRACK_ALT)
    )
    _trigger(Rect2(2940, 490, 260, 150), func():
        if _choose_route("lower"):
            _v25_pulse_notice("ALT", V28_TRACK)
    )
    _moving_platform(Vector2(3820, 555), Vector2(145, 24), Vector2(3860, 472), 1.42, V25_BLUE)
    var route_spikes := _spikes(Vector2(4560, 612), 3, true)
    _trigger(Rect2(4240, 390, 130, 240), func():
        if _once("242_route"):
            if route_choice == "upper":
                _v28_set_risk(2, 1.05)
                _v28_tracker_line(4560.0, V28_RISK_MED, 0.48)
                var tw := create_tween()
                tw.tween_interval(0.52)
                tw.tween_callback(func(): _reveal(route_spikes))
                tw.tween_interval(0.54)
                tw.tween_callback(func(): _hide(route_spikes))
            else:
                _v28_set_risk(1, 0.72)
                _v28_tracker_line(4560.0, V28_TRACK_ALT, 0.48)
                _false_alarm()
    )
    _moving_platform(Vector2(5560, 555), Vector2(145, 24), Vector2(5600, 470), 1.42, V25_CYAN)
    var gate_b := _hazard_block(Vector2(6240, 210), Vector2(110, 70), V25_RED)
    _trigger(Rect2(5880, 390, 130, 240), func():
        if not trigger_state.has("242_gate_b"):
            trigger_state["242_gate_b"] = true
            if route_choice == "lower":
                _v28_lock_player_lane(gate_b, "242_gate_b_real", 0.58)
            else:
                _v28_set_risk(1, 0.72)
                _v28_tracker_line(player.global_position.x + 120.0 if is_instance_valid(player) else 6200.0, V28_TRACK_ALT, 0.52)
                _false_alarm()
    )
    _finish(Vector2(6740, 580))

func _v28_level_24_3() -> void:
    _floor_with_gaps(7800, [Vector2(1760, 1920), Vector2(4020, 4180), Vector2(6200, 6360)])
    var attempt: int = _attempt(24, 3)
    _text(Vector2(120, 470), "TAKİP DESENİ SENİ HATIRLIYOR.", 24, V28_TRACK_ALT)
    _text(Vector2(430, 520), "DENEME %d" % attempt, 17, V25_MUTED)
    var gate_a := _hazard_block(Vector2(1180, 210), Vector2(110, 70), V25_RED)
    _trigger(Rect2(650, 390, 140, 240), func():
        if not trigger_state.has("243_gate_a"):
            trigger_state["243_gate_a"] = true
            if attempt % 3 != 0:
                _v28_lock_player_lane(gate_a, "243_gate_a_real", 0.54)
            else:
                _v28_set_risk(1, 0.72)
                _v28_tracker_line(1180.0, V28_TRACK_ALT, 0.50)
                _false_alarm()
    )
    _moving_platform(Vector2(1840, 555), Vector2(145, 24), Vector2(1880, 470), 1.42, V25_CYAN)
    var memory_spikes := _spikes(Vector2(2700, 612), 3, true)
    _trigger(Rect2(2260, 390, 140, 240), func():
        if _once("243_memory"):
            var honest := attempt % 2 == 1
            _v28_set_risk(2 if honest else 1, 1.0)
            _v28_tracker_line(2700.0, V28_RISK_MED if honest else V28_TRACK_ALT, 0.48)
            if honest:
                var tw := create_tween()
                tw.tween_interval(0.52)
                tw.tween_callback(func(): _reveal(memory_spikes))
                tw.tween_interval(0.54)
                tw.tween_callback(func(): _hide(memory_spikes))
            else:
                _false_alarm()
    )
    _route_hint(Vector2(3440, 490), "SOLUK")
    _route_hint(Vector2(3440, 385), "PARLAK")
    _platform(Vector2(3530, 455), Vector2(240, 24), V25_PLATFORM_ALT)
    _trigger(Rect2(3200, 305, 260, 185), func():
        if _choose_route("bright"):
            _v25_pulse_notice("PARLAK", V28_TRACK_ALT)
    )
    _trigger(Rect2(3200, 490, 260, 150), func():
        if _choose_route("dim"):
            _v25_pulse_notice("SOLUK", V28_TRACK)
    )
    _moving_platform(Vector2(4100, 555), Vector2(145, 24), Vector2(4140, 472), 1.42, V25_BLUE)
    var route_gate := _hazard_block(Vector2(4920, 210), Vector2(110, 70), V25_RED)
    _trigger(Rect2(4500, 390, 140, 240), func():
        if not trigger_state.has("243_route_gate"):
            trigger_state["243_route_gate"] = true
            var bad_route := (attempt % 2 == 0 and route_choice == "bright") or (attempt % 2 == 1 and route_choice == "dim")
            if bad_route:
                _v28_lock_player_lane(route_gate, "243_route_gate_real", 0.58)
            else:
                _v28_set_risk(1, 0.72)
                _v28_tracker_line(player.global_position.x + 110.0 if is_instance_valid(player) else 4900.0, V28_TRACK_ALT, 0.50)
                _false_alarm()
    )
    var wait_spikes := _spikes(Vector2(5680, 612), 3, true)
    _trigger(Rect2(5300, 390, 260, 240), func():
        _wait_check(5460.0, 170.0, 1.05, func():
            _v28_set_risk(2, 1.05)
            _v28_tracker_line(5680.0, V28_RISK_MED, 0.46)
            var tw := create_tween()
            tw.tween_interval(0.50)
            tw.tween_callback(func(): _reveal(wait_spikes))
            tw.tween_interval(0.56)
            tw.tween_callback(func(): _hide(wait_spikes))
        , "243_wait")
    )
    _moving_platform(Vector2(6280, 555), Vector2(145, 24), Vector2(6320, 470), 1.42, V25_CYAN)
    _trigger(Rect2(6620, 390, 130, 240), func():
        if _once("243_rock"):
            var rock_real := attempt % 3 == 1
            _v28_set_risk(2 if rock_real else 1, 1.0)
            _v28_tracker_line(7160.0, V27_WARNING if rock_real else V28_TRACK_ALT, 0.48)
            if rock_real:
                var tw := create_tween()
                tw.tween_interval(0.56)
                tw.tween_callback(func(): _boulder(Vector2(7300, 560), -326.0, 62.0))
            else:
                _false_alarm()
    )
    var last := _spikes(Vector2(7200, 612), 2, true)
    _trigger(Rect2(6940, 390, 120, 240), func():
        if _once("243_last") and attempt % 3 != 1:
            _v28_set_risk(2, 0.98)
            _v28_tracker_line(7200.0, V28_RISK_MED, 0.46)
            var tw := create_tween()
            tw.tween_interval(0.50)
            tw.tween_callback(func(): _reveal(last))
            tw.tween_interval(0.54)
            tw.tween_callback(func(): _hide(last))
    )
    _finish(Vector2(7560, 580))

func _v23_run_validation() -> void:
    await get_tree().process_frame
    var failures: int = 0
    var checked: int = 0
    for c in range(1, 25):
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
    if failures == 0 and checked == 72:
        print("ALL_LEVELS_OK:72")
        get_tree().quit(0)
    else:
        print("ALL_LEVELS_FAILED:%d:%d" % [checked, failures])
        get_tree().quit(1)
