extends "res://scripts/game_v25_release.gd"

const V26_SHADOW := Color("#0f172a")
const V26_GHOST := Color("#67e8f9")
const V26_GHOST_RED := Color("#fb7185")

var v26_last_death_key := ""
var v26_last_death_pos := Vector2.ZERO
var v26_echo_pending := false

func _safe_load_progress() -> void:
    super._safe_load_progress()
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return
    var stored_unlock = cfg.get_value("progress", "unlocked_chapter", 1)
    if stored_unlock is int or stored_unlock is float:
        unlocked_chapter = clampi(int(stored_unlock), 1, 23)

func _start_level(c: int, p: int) -> void:
    var next_key := _map_key(c, p)
    var show_echo := v26_echo_pending and v26_last_death_key == next_key
    if v26_echo_pending and v26_last_death_key != next_key:
        v26_echo_pending = false
        v26_last_death_key = ""
    super._start_level(c, p)
    if show_echo and is_instance_valid(world):
        _v26_add_death_echo(v26_last_death_pos)
        v26_echo_pending = false

func _build_level(c: int, p: int) -> void:
    if c == 22 and p == 1:
        _v26_level_22_1()
    elif c == 22 and p == 2:
        _v26_level_22_2()
    elif c == 22 and p == 3:
        _v26_level_22_3()
    else:
        super._build_level(c, p)

func _build_hud() -> void:
    super._build_hud()
    if not is_instance_valid(hud):
        return
    var attempt_chip := Label.new()
    attempt_chip.position = Vector2(548, 18)
    attempt_chip.size = Vector2(135, 30)
    attempt_chip.text = "DENEME %d" % _attempt()
    attempt_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    attempt_chip.add_theme_font_size_override("font_size", 12)
    attempt_chip.add_theme_color_override("font_color", V25_CYAN if chapter >= 21 else V25_MUTED)
    hud.add_child(attempt_chip)

    if chapter == 22:
        var mode := Label.new()
        mode.position = Vector2(650, 45)
        mode.size = Vector2(220, 22)
        mode.text = "GÖLGE / İZ"
        mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        mode.add_theme_font_size_override("font_size", 11)
        mode.add_theme_color_override("font_color", V26_GHOST)
        hud.add_child(mode)

func _on_player_died() -> void:
    if restarting or level_finished:
        return
    if is_instance_valid(player):
        v26_last_death_key = _map_key()
        v26_last_death_pos = player.global_position
        v26_echo_pending = true
    super._on_player_died()

func _show_main_menu() -> void:
    v26_echo_pending = false
    v26_last_death_key = ""
    super._show_main_menu()
    if not is_instance_valid(hud):
        return

    for child in hud.get_children():
        if child is Label:
            var label := child as Label
            if label.text == "ANDROID • v2.5":
                label.text = "ANDROID • v2.6"
            elif label.text == "KARANLIK DÖNEM BAŞLADI • BÖLÜM 21":
                label.text = "KARANLIK DÖNEM • BÖLÜM 22: GÖLGE"
            elif label.text.begins_with("REKOR KAYDI"):
                label.text = "REKOR KAYDI  %d / 66" % best_times_ms.size()
            elif label.text.begins_with("AÇIK BÖLÜM"):
                var available := maxi(1, mini(unlocked_chapter, 22))
                var completed_maps := maxi(0, (mini(unlocked_chapter, 23) - 1) * 3)
                label.text = "AÇIK BÖLÜM   %d / 22\nHARİTA        %d / 66\nTOPLAM ÖLÜM   %d" % [available, completed_maps, deaths]
            elif label.text == "İÇERİK ÜRETİMİ  63 / 300":
                label.text = "İÇERİK ÜRETİMİ  66 / 300"
            elif label.text == "Işık artık bilgi değil. Bazen ipucu, bazen tuzak.":
                label.text = "Gölgeler yolu saklıyor; son ölüm izin artık sana geri bakıyor."
            elif label.text.begins_with("v2.5 KARANLIK DÖNEM"):
                label.text = "v2.6 GÖLGE / ÖLÜM İZİ\n\n• Son ölüm noktası sonraki denemede görünür\n• HUD'a kalıcı deneme sayacı eklendi\n• Gölge platformları ışık darbesiyle görünürleşir\n• Developer Tool artık Bölüm 22'yi açabilir"
        elif child is Button:
            var button := child as Button
            if button.text == "DEVAM ET":
                button.visible = false
                button.disabled = true
        elif child is ColorRect:
            var rect := child as ColorRect
            if is_equal_approx(rect.position.x, 98.0) and is_equal_approx(rect.position.y, 386.0) and is_equal_approx(rect.size.y, 10.0) and rect.size.x < 600.0:
                rect.size.x = 620.0 * 66.0 / 300.0

    _v25_button("DEVAM ET", Vector2(790, 350), Vector2(390, 60), func(): _start_level(maxi(1, mini(unlocked_chapter, 22)), 1), V25_CYAN)

func _show_chapter_select() -> void:
    super._show_chapter_select()
    if not is_instance_valid(hud):
        return

    for child in hud.get_children():
        if child is Label:
            var label := child as Label
            if label.text == "21 BÖLÜM • 63 HARİTA • KARANLIK FAZ":
                label.text = "22 BÖLÜM • 66 HARİTA • KARANLIK FAZ"
            elif label.text.begins_with("Bölüm 21-40:"):
                label.text = "Bölüm 21-40: Karanlık dönem • Bölüm 22 gölge ve ölüm izi okumayı öğretiyor"

    var chapter_id := 22
    var is_unlocked := chapter_id <= unlocked_chapter
    var button_text := "BÖLÜM 22\nGÖLGE" if is_unlocked else "BÖLÜM 22\nKİLİTLİ"
    var button := _v25_button(button_text, Vector2(348, 461), Vector2(276, 56), func(): _start_level(22, 1), V26_GHOST)
    button.disabled = not is_unlocked

func _show_chapter_result() -> void:
    if chapter != 22:
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
    line.color = V26_GHOST
    hud.add_child(line)

    var title := Label.new()
    title.position = Vector2(140, 66)
    title.size = Vector2(1000, 220)
    title.text = "BÖLÜM 22 TAMAMLANDI\n\nGÖLGE ARTIK SADECE GÖRSEL DEĞİL"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 36)
    title.add_theme_color_override("font_color", V25_TEXT)
    hud.add_child(title)

    var stats := Label.new()
    stats.position = Vector2(95, 310)
    stats.size = Vector2(1090, 150)
    stats.text = "22-1  %s / %s ölüm     22-2  %s / %s ölüm     22-3  %s / %s ölüm\n\nSON ÖLÜM İZİNİ OKU. GÖLGENİN HER ZAMAN TEHLİKE OLMADIĞINI HATIRLA." % [_best_time_text(22, 1), _best_deaths_text(22, 1), _best_time_text(22, 2), _best_deaths_text(22, 2), _best_time_text(22, 3), _best_deaths_text(22, 3)]
    stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    stats.add_theme_font_size_override("font_size", 18)
    stats.add_theme_color_override("font_color", V26_GHOST)
    hud.add_child(stats)

    var milestone := Label.new()
    milestone.position = Vector2(180, 485)
    milestone.size = Vector2(920, 45)
    milestone.text = "22 / 100 BÖLÜM   •   66 / 300 HARİTA   •   %22 İÇERİK"
    milestone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    milestone.add_theme_font_size_override("font_size", 18)
    milestone.add_theme_color_override("font_color", V25_MUTED)
    hud.add_child(milestone)
    _v25_button("ANA MENÜ", Vector2(490, 565), Vector2(300, 64), func(): _show_main_menu(), V26_GHOST)

func _v24_open_dev_console() -> void:
    super._v24_open_dev_console()
    if not is_instance_valid(v24_dev_overlay):
        return
    for panel_child in v24_dev_overlay.get_children():
        for child in panel_child.get_children():
            if child is Label and child.text.begins_with("Komut biçimi:"):
                child.text = "Komut biçimi: WAREXT 22-3\nBölüm 1-22 • Kısım 1-3"

func _v24_execute_dev_command(command: String) -> void:
    var raw := command.strip_edges().to_upper()
    if not raw.begins_with("WAREXT "):
        _v24_dev_error("Kod WAREXT ile başlamalı. Örnek: WAREXT 22-3")
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
    if target_chapter < 1 or target_chapter > 22:
        _v24_dev_error("Bölüm 1 ile 22 arasında olmalı.")
        return
    if target_part < 1 or target_part > 3:
        _v24_dev_error("Kısım 1 ile 3 arasında olmalı.")
        return
    _v24_close_dev_console()
    v24_dev_session = true
    _start_level(target_chapter, target_part)

func _v26_add_death_echo(pos: Vector2) -> void:
    if not is_instance_valid(world):
        return
    var ring := Line2D.new()
    ring.position = pos
    ring.width = 2.0
    ring.closed = true
    ring.default_color = Color(V26_GHOST_RED, 0.46)
    ring.points = _circle_points(28.0, 24)
    ring.z_index = 18
    world.add_child(ring)

    var cross := Line2D.new()
    cross.position = pos
    cross.width = 2.0
    cross.default_color = Color(V26_GHOST, 0.58)
    cross.points = PackedVector2Array([
        Vector2(-20, -20), Vector2(20, 20),
        Vector2.ZERO,
        Vector2(20, -20), Vector2(-20, 20)
    ])
    cross.z_index = 19
    world.add_child(cross)

    var label := Label.new()
    label.position = pos + Vector2(-52, -62)
    label.size = Vector2(110, 24)
    label.text = "SON ÖLÜM"
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 11)
    label.add_theme_color_override("font_color", Color(V26_GHOST, 0.72))
    label.z_index = 19
    world.add_child(label)

    if v20_effects_enabled:
        var tw := create_tween().set_loops()
        tw.tween_property(ring, "modulate:a", 0.28, 0.62)
        tw.tween_property(ring, "modulate:a", 0.82, 0.62)

func _v26_shadow_platform(pos: Vector2, size: Vector2, alpha: float = 0.24) -> StaticBody2D:
    var body := _platform(pos, size, V26_SHADOW)
    if is_instance_valid(body):
        body.modulate.a = clampf(alpha, 0.16, 0.60)
        body.set_meta("v26_shadow", true)
    return body

func _v26_shadow_mover(pos: Vector2, size: Vector2, target: Vector2, travel_time: float, alpha: float = 0.24) -> AnimatableBody2D:
    var body := _moving_platform(pos, size, target, maxf(travel_time, 1.20), V25_PLATFORM_ALT)
    if is_instance_valid(body):
        body.modulate.a = clampf(alpha, 0.16, 0.60)
        body.set_meta("v26_shadow", true)
    return body

func _v26_shadow_pulse(items: Array, color: Color = V26_GHOST) -> void:
    if is_instance_valid(hud) and v20_effects_enabled:
        var flash := ColorRect.new()
        flash.size = Vector2(1280, 720)
        flash.color = Color(color, 0.075)
        flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
        flash.z_index = 72
        hud.add_child(flash)
        var ft := create_tween()
        ft.tween_property(flash, "color:a", 0.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        ft.tween_callback(flash.queue_free)

    for item in items:
        if not is_instance_valid(item) or not (item is CanvasItem):
            continue
        var canvas := item as CanvasItem
        var base_alpha := canvas.modulate.a
        var tw := create_tween()
        tw.tween_property(canvas, "modulate:a", 1.0, 0.14)
        tw.tween_interval(0.42)
        tw.tween_property(canvas, "modulate:a", base_alpha, 0.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    _play_tone(520.0, 0.07, 0.09)

func _v26_level_22_1() -> void:
    _floor_with_gaps(6200, [Vector2(1720, 1880), Vector2(3560, 3720)])
    _text(Vector2(120, 470), "BÖLÜM 22: GÖLGE.", 25, V26_GHOST)
    _text(Vector2(410, 520), "GÖREMEDİĞİN ŞEY HER ZAMAN YOK DEĞİLDİR.", 17, V25_MUTED)

    var intro_shadow := _v26_shadow_platform(Vector2(760, 548), Vector2(190, 26), 0.22)
    _trigger(Rect2(520, 390, 130, 240), func():
        if _once("221_intro"):
            _v26_shadow_pulse([intro_shadow])
            _false_alarm()
    )

    var first := _spikes(Vector2(1180, 612), 3, true)
    _trigger(Rect2(930, 390, 120, 240), func():
        if _once("221_first"):
            var tw := create_tween()
            tw.tween_interval(0.36)
            tw.tween_callback(func(): _reveal(first))
            tw.tween_interval(0.54)
            tw.tween_callback(func(): _hide(first))
    )

    var bridge_a := _v26_shadow_platform(Vector2(1800, 555), Vector2(145, 24), 0.20)
    _trigger(Rect2(1450, 390, 130, 240), func():
        if _once("221_bridge_a"):
            _v26_shadow_pulse([bridge_a])
    )

    var gate := _hazard_block(Vector2(2460, 210), Vector2(118, 70), V25_RED)
    _trigger(Rect2(2160, 390, 130, 240), func():
        if _once("221_gate"):
            var tw := create_tween()
            tw.tween_interval(0.18)
            tw.tween_property(gate, "position:y", 505.0, 0.46).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_interval(0.38)
            tw.tween_property(gate, "position:y", 210.0, 0.54).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

    var harmless := _v26_shadow_platform(Vector2(3010, 548), Vector2(210, 26), 0.26)
    _trigger(Rect2(2760, 390, 130, 240), func():
        if _once("221_harmless"):
            _v26_shadow_pulse([harmless], V25_PURPLE)
            _false_alarm()
    )

    var bridge_b := _v26_shadow_platform(Vector2(3640, 555), Vector2(145, 24), 0.18)
    _trigger(Rect2(3300, 390, 130, 240), func():
        if _once("221_bridge_b"):
            _v26_shadow_pulse([bridge_b])
    )

    _v25_light_beacon(Vector2(4240, 490), V25_AMBER, "SESSİZ")
    _trigger(Rect2(4020, 390, 120, 240), func():
        if _once("221_rock"):
            var tw := create_tween()
            tw.tween_interval(0.44)
            tw.tween_callback(func(): _boulder(Vector2(4850, 560), -345.0, 66.0))
    )

    var final_shadow := _v26_shadow_platform(Vector2(5080, 548), Vector2(185, 26), 0.20)
    _trigger(Rect2(4840, 390, 120, 240), func():
        if _once("221_final_shadow"):
            _v26_shadow_pulse([final_shadow])
    )

    var last := _spikes(Vector2(5550, 612), 2, true)
    _trigger(Rect2(5320, 390, 120, 240), func():
        if _once("221_last"):
            var tw := create_tween()
            tw.tween_interval(0.32)
            tw.tween_callback(func(): _reveal(last))
            tw.tween_interval(0.54)
            tw.tween_callback(func(): _hide(last))
    )
    _finish(Vector2(5940, 580))

func _v26_level_22_2() -> void:
    _floor_with_gaps(6800, [Vector2(1480, 1640), Vector2(3400, 3560), Vector2(5240, 5400)])
    _text(Vector2(120, 470), "GÖLGE HAREKET EDER.", 24, V26_GHOST)
    _text(Vector2(410, 520), "IŞIK SADECE NEREDE OLDUĞUNU GÖSTERİR. NEREYE GİDECEĞİNİ DEĞİL.", 16, V25_MUTED)

    var mover_a := _v26_shadow_mover(Vector2(1560, 555), Vector2(145, 24), Vector2(1600, 474), 1.42, 0.20)
    _trigger(Rect2(1120, 390, 150, 240), func():
        if _once("222_mover_a"):
            _v26_shadow_pulse([mover_a])
    )

    var pulse_spikes := _spikes(Vector2(2140, 612), 3, true)
    _trigger(Rect2(1900, 390, 120, 240), func():
        if _once("222_spikes"):
            _v25_light_beacon(Vector2(2260, 490), V25_CYAN, "PULSE")
            var tw := create_tween()
            tw.tween_interval(0.38)
            tw.tween_callback(func(): _reveal(pulse_spikes))
            tw.tween_interval(0.52)
            tw.tween_callback(func(): _hide(pulse_spikes))
    )

    var decoy := _v26_shadow_platform(Vector2(2780, 548), Vector2(205, 26), 0.18)
    _trigger(Rect2(2540, 390, 130, 240), func():
        if _once("222_decoy"):
            _v26_shadow_pulse([decoy], V25_GREEN)
            _false_alarm()
    )

    var mover_b := _v26_shadow_mover(Vector2(3480, 555), Vector2(145, 24), Vector2(3520, 470), 1.40, 0.20)
    _trigger(Rect2(3140, 390, 130, 240), func():
        if _once("222_mover_b"):
            _v26_shadow_pulse([mover_b])
    )

    _route_hint(Vector2(4110, 490), "IŞIK")
    _route_hint(Vector2(4110, 385), "GÖLGE")
    var upper := _v26_shadow_platform(Vector2(4210, 455), Vector2(235, 24), 0.24)
    _trigger(Rect2(3880, 305, 250, 185), func():
        if _choose_route("shadow"):
            _v26_shadow_pulse([upper])
    )
    _trigger(Rect2(3880, 490, 250, 150), func():
        if _choose_route("light"):
            _v25_pulse_notice("IŞIK")
    )

    var route_spikes := _spikes(Vector2(4670, 612), 3, true)
    _trigger(Rect2(4440, 390, 120, 240), func():
        if _once("222_route"):
            if route_choice == "light":
                var tw := create_tween()
                tw.tween_interval(0.36)
                tw.tween_callback(func(): _reveal(route_spikes))
                tw.tween_interval(0.54)
                tw.tween_callback(func(): _hide(route_spikes))
            else:
                _false_alarm()
    )

    var mover_c := _v26_shadow_mover(Vector2(5320, 555), Vector2(145, 24), Vector2(5360, 472), 1.44, 0.19)
    _trigger(Rect2(5000, 390, 120, 240), func():
        if _once("222_mover_c"):
            _v26_shadow_pulse([mover_c])
    )

    var safe_shadow := _v26_shadow_platform(Vector2(5780, 548), Vector2(190, 26), 0.18)
    _trigger(Rect2(5540, 390, 120, 240), func():
        if _once("222_safe"):
            _v26_shadow_pulse([safe_shadow], V25_GREEN)
            _false_alarm()
    )

    _trigger(Rect2(6040, 390, 120, 240), func():
        if _once("222_rock"):
            var tw := create_tween()
            tw.tween_interval(0.44)
            tw.tween_callback(func(): _boulder(Vector2(6580, 560), -340.0, 64.0))
    )
    _finish(Vector2(6500, 580))

func _v26_level_22_3() -> void:
    _floor_with_gaps(7600, [Vector2(1700, 1860), Vector2(3980, 4140), Vector2(6020, 6180)])
    var attempt: int = _attempt(22, 3)
    _text(Vector2(120, 470), "GÖLGEN SENİ HATIRLIYOR.", 24, V25_PURPLE)
    _text(Vector2(420, 520), "DENEME %d • SON ÖLÜM İZİNİ OKU" % attempt, 16, V25_MUTED)

    var pad_a := _v26_shadow_platform(Vector2(820, 548), Vector2(175, 26), 0.18)
    var pad_b := _v26_shadow_platform(Vector2(1190, 548), Vector2(175, 26), 0.18)
    _trigger(Rect2(580, 390, 130, 240), func():
        if _once("223_intro"):
            if attempt % 2 == 0:
                _v26_shadow_pulse([pad_a], V25_GREEN)
            else:
                _v26_shadow_pulse([pad_b], V25_GREEN)
            _false_alarm()
    )

    var intro_spikes := _spikes(Vector2(1450, 612), 2, true)
    _trigger(Rect2(1300, 390, 110, 240), func():
        if _once("223_intro_spikes"):
            var tw := create_tween()
            tw.tween_interval(0.34 + float(attempt % 2) * 0.06)
            tw.tween_callback(func(): _reveal(intro_spikes))
            tw.tween_interval(0.54)
            tw.tween_callback(func(): _hide(intro_spikes))
    )

    var bridge_a := _v26_shadow_platform(Vector2(1780, 555), Vector2(145, 24), 0.18)
    _trigger(Rect2(1540, 390, 120, 240), func():
        if _once("223_bridge_a"):
            _v26_shadow_pulse([bridge_a])
    )

    var gate := _hazard_block(Vector2(2460, 210), Vector2(120, 70), V25_RED)
    _trigger(Rect2(2160, 390, 130, 240), func():
        if _once("223_gate"):
            var delay := 0.24 + float(attempt % 3) * 0.05
            var tw := create_tween()
            tw.tween_interval(delay)
            tw.tween_property(gate, "position:y", 505.0, 0.46).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_interval(0.40)
            tw.tween_property(gate, "position:y", 210.0, 0.54).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

    _v25_light_beacon(Vector2(3100, 490), V25_CYAN if attempt % 3 != 0 else V25_AMBER, "EKO")
    var echo_shadow := _v26_shadow_platform(Vector2(3260, 548), Vector2(205, 26), 0.18)
    _trigger(Rect2(2860, 390, 130, 240), func():
        if _once("223_echo"):
            _v26_shadow_pulse([echo_shadow], V25_CYAN if attempt % 3 != 0 else V25_AMBER)
            if attempt % 3 == 0:
                _false_alarm()
    )

    var bridge_b := _v26_shadow_platform(Vector2(4060, 555), Vector2(145, 24), 0.18)
    _trigger(Rect2(3760, 390, 120, 240), func():
        if _once("223_bridge_b"):
            _v26_shadow_pulse([bridge_b])
    )

    _route_hint(Vector2(4670, 490), "SOLUK")
    _route_hint(Vector2(4670, 385), "PARLAK")
    var upper := _v26_shadow_platform(Vector2(4770, 455), Vector2(240, 24), 0.23)
    _trigger(Rect2(4430, 305, 260, 185), func():
        if _choose_route("bright"):
            _v25_pulse_notice("PARLAK")
    )
    _trigger(Rect2(4430, 490, 260, 150), func():
        if _choose_route("dim"):
            _v26_shadow_pulse([upper])
    )

    var route_spikes := _spikes(Vector2(5220, 612), 3, true)
    _trigger(Rect2(4970, 390, 120, 240), func():
        if _once("223_route"):
            var route_bad := (attempt % 2 == 0 and route_choice == "bright") or (attempt % 2 == 1 and route_choice == "dim")
            if route_bad:
                var tw := create_tween()
                tw.tween_interval(0.36)
                tw.tween_callback(func(): _reveal(route_spikes))
                tw.tween_interval(0.54)
                tw.tween_callback(func(): _hide(route_spikes))
            else:
                _false_alarm()
    )

    var wait_gate := _hazard_block(Vector2(5710, 210), Vector2(116, 68), V25_RED)
    _trigger(Rect2(5460, 390, 250, 240), func():
        _wait_check(5650.0, 145.0, 1.10, func():
            if attempt % 3 != 1:
                var tw := create_tween()
                tw.tween_property(wait_gate, "position:y", 505.0, 0.46).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
                tw.tween_interval(0.38)
                tw.tween_property(wait_gate, "position:y", 210.0, 0.54).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
            else:
                _false_alarm()
        , "223_wait")
    )

    var bridge_c := _v26_shadow_platform(Vector2(6100, 555), Vector2(145, 24), 0.18)
    _trigger(Rect2(5840, 390, 120, 240), func():
        if _once("223_bridge_c"):
            _v26_shadow_pulse([bridge_c])
    )

    _trigger(Rect2(6460, 390, 120, 240), func():
        if _once("223_rock"):
            var tw := create_tween()
            tw.tween_interval(0.46)
            tw.tween_callback(func(): _boulder(Vector2(7060, 560), -338.0, 64.0))
    )

    var last := _spikes(Vector2(6900, 612), 2, true)
    _trigger(Rect2(6700, 390, 120, 240), func():
        if _once("223_last"):
            var tw := create_tween()
            tw.tween_interval(0.34)
            tw.tween_callback(func(): _reveal(last))
            tw.tween_interval(0.54)
            tw.tween_callback(func(): _hide(last))
    )
    _finish(Vector2(7330, 580))

func _v23_run_validation() -> void:
    await get_tree().process_frame
    var failures: int = 0
    var checked: int = 0
    for c in range(1, 23):
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
    if failures == 0 and checked == 66:
        print("ALL_LEVELS_OK:66")
        get_tree().quit(0)
    else:
        print("ALL_LEVELS_FAILED:%d:%d" % [checked, failures])
        get_tree().quit(1)
