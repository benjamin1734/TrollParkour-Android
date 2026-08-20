extends "res://scripts/game_v35.gd"

const V36_CYAN := Color("#38e8ff")
const V36_PURPLE := Color("#a78bfa")
const V36_GREEN := Color("#4ee6a4")
const V36_AMBER := Color("#ffbd59")
const V36_RED := Color("#ff5d73")
const V36_BG := Color("#030712")

var v36_last_jumps_used := 0
var v36_jump_state_label: Label

func _safe_load_progress() -> void:
    super._safe_load_progress()
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return
    var stored_unlock = cfg.get_value("progress", "unlocked_chapter", 1)
    if stored_unlock is int or stored_unlock is float:
        unlocked_chapter = clampi(int(stored_unlock), 1, 27)

func _start_level(c: int, p: int) -> void:
    v36_last_jumps_used = 0
    v36_jump_state_label = null
    super._start_level(c, p)
    if c == 26:
        RenderingServer.set_default_clear_color(V36_BG)
        if is_instance_valid(world):
            world.set_meta("v36_inversion", true)
            world.set_meta("v36_part", p)
            _v36_add_environment()

func _process(delta: float) -> void:
    super._process(delta)
    if not is_instance_valid(player) or not player.alive:
        return
    var used := int(player._jumps_used)
    if used == 2 and v36_last_jumps_used < 2 and v20_effects_enabled:
        _v36_air_jump_fx()
    v36_last_jumps_used = used
    if is_instance_valid(v36_jump_state_label):
        if player.is_on_floor() or used == 0:
            v36_jump_state_label.text = "ÇİFT ZIPLAMA HAZIR"
            v36_jump_state_label.add_theme_color_override("font_color", Color(V36_GREEN, 0.78))
        elif used == 1:
            v36_jump_state_label.text = "2. ZIPLAMA HAZIR"
            v36_jump_state_label.add_theme_color_override("font_color", Color(V36_CYAN, 0.88))
        else:
            v36_jump_state_label.text = "2. ZIPLAMA KULLANILDI"
            v36_jump_state_label.add_theme_color_override("font_color", Color(V36_PURPLE, 0.70))

func _build_level(c: int, p: int) -> void:
    if c == 26 and p >= 1 and p <= 3:
        _v36_build_inversion_map(p)
        return
    super._build_level(c, p)

func _build_hud() -> void:
    super._build_hud()
    if not is_instance_valid(hud):
        return
    v36_jump_state_label = Label.new()
    v36_jump_state_label.name = "V36DoubleJumpState"
    v36_jump_state_label.position = Vector2(1000, 100)
    v36_jump_state_label.size = Vector2(235, 20)
    v36_jump_state_label.text = "ÇİFT ZIPLAMA HAZIR"
    v36_jump_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    v36_jump_state_label.add_theme_font_size_override("font_size", 10)
    v36_jump_state_label.add_theme_color_override("font_color", Color(V36_GREEN, 0.78))
    v36_jump_state_label.z_index = 88
    hud.add_child(v36_jump_state_label)
    if chapter == 26:
        var mode := Label.new()
        mode.name = "V36Mode"
        mode.position = Vector2(635, 45)
        mode.size = Vector2(300, 22)
        mode.text = "TERS KURAL / BEKLENTİ"
        mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        mode.add_theme_font_size_override("font_size", 11)
        mode.add_theme_color_override("font_color", V36_PURPLE)
        mode.z_index = 86
        hud.add_child(mode)

func _show_main_menu() -> void:
    super._show_main_menu()
    if not is_instance_valid(hud):
        return
    for child in hud.get_children():
        if child is Label:
            var label := child as Label
            if label.text == "ANDROID • v3.5":
                label.text = "ANDROID • v3.6"
            elif label.name == "V35AuditBadge":
                label.text = "İNSAN OYUNCU ROTASI • 78 / 78"
            elif label.text.begins_with("REKOR KAYDI"):
                label.text = "REKOR KAYDI  %d / 78" % best_times_ms.size()
            elif label.text.begins_with("AÇIK BÖLÜM"):
                var available := maxi(1, mini(unlocked_chapter, 26))
                var completed_maps := maxi(0, (mini(unlocked_chapter, 27) - 1) * 3)
                label.text = "AÇIK BÖLÜM   %d / 26\nHARİTA        %d / 78\nTOPLAM ÖLÜM   %d" % [available, completed_maps, deaths]
            elif label.text == "İÇERİK ÜRETİMİ  75 / 300":
                label.text = "İÇERİK ÜRETİMİ  78 / 300"
        elif child is Button:
            var button := child as Button
            if button.text == "DEVAM ET":
                button.visible = false
                button.disabled = true
        elif child is ColorRect:
            var rect := child as ColorRect
            if is_equal_approx(rect.position.x, 98.0) and is_equal_approx(rect.position.y, 386.0) and is_equal_approx(rect.size.y, 10.0) and rect.size.x < 600.0:
                rect.size.x = 620.0 * 78.0 / 300.0
    var phase := Label.new()
    phase.name = "V36PhaseBadge"
    phase.position = Vector2(820, 170)
    phase.size = Vector2(385, 24)
    phase.text = "BÖLÜM 26 • KURALLAR TERSİNE DÖNÜYOR"
    phase.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    phase.add_theme_font_size_override("font_size", 11)
    phase.add_theme_color_override("font_color", Color(V36_PURPLE, 0.84))
    phase.z_index = 83
    hud.add_child(phase)
    _v25_button("DEVAM ET", Vector2(790, 350), Vector2(390, 60), func(): _start_level(maxi(1, mini(unlocked_chapter, 26)), 1), V36_CYAN)

func _show_chapter_select() -> void:
    super._show_chapter_select()
    if not is_instance_valid(hud):
        return
    for child in hud.get_children():
        if child is Label:
            var label := child as Label
            if label.text == "25 BÖLÜM • 75 HARİTA • KARANLIK FAZ":
                label.text = "26 BÖLÜM • 78 HARİTA • TERS KURAL FAZI"
            elif label.text.begins_with("Bölüm 25:"):
                label.text = "Bölüm 26: Tehlike görünüşü ile gerçek davranış artık aynı şeyi söylemez."
        elif child is Button:
            var old := child as Button
            if old.text == "GERİ":
                old.position.y = 642
                old.size.y = 48
    var is_unlocked := 26 <= unlocked_chapter
    var button_text := "BÖLÜM 26\nTERS KURAL" if is_unlocked else "BÖLÜM 26\nKİLİTLİ"
    var button := _v25_button(button_text, Vector2(348, 533), Vector2(276, 52), func(): _start_level(26, 1), V36_PURPLE)
    button.disabled = not is_unlocked

func _v24_execute_dev_command(command: String) -> void:
    var raw := command.strip_edges().to_upper()
    if raw == "WAREXT":
        _v34_show_dev_selector()
        return
    if raw.begins_with("WAREXT "):
        var target := raw.trim_prefix("WAREXT ").strip_edges()
        var pieces := target.split("-")
        if pieces.size() == 2:
            var chapter_text := String(pieces[0]).strip_edges()
            var part_text := String(pieces[1]).strip_edges()
            if chapter_text.is_valid_int() and part_text.is_valid_int():
                var target_chapter := int(chapter_text)
                var target_part := int(part_text)
                if target_chapter >= 1 and target_chapter <= 26 and target_part >= 1 and target_part <= 3:
                    _v34_start_dev_map(target_chapter, target_part)
                    return
    _v24_dev_error("Sadece WAREXT yaz. Haritayı ekrandan seçebilirsin.")

func _v34_show_dev_selector() -> void:
    _v34_replace_dev_overlay("V36DevSelector")
    var overlay := v24_dev_overlay
    if not is_instance_valid(overlay):
        return
    var title := Label.new()
    title.position = Vector2(130, 20)
    title.size = Vector2(1020, 48)
    title.text = "DEV HARİTA SEÇİMİ"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 28)
    title.add_theme_color_override("font_color", V34_TEXT)
    overlay.add_child(title)
    var sub := Label.new()
    sub.position = Vector2(130, 67)
    sub.size = Vector2(1020, 28)
    sub.text = "26 bölüm • 78 harita • kayıt ve rekor etkilenmez"
    sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sub.add_theme_font_size_override("font_size", 14)
    sub.add_theme_color_override("font_color", V34_MUTED)
    overlay.add_child(sub)
    for i in range(26):
        var chapter_id := i + 1
        var col := i % 6
        var row := int(i / 6)
        var pos := Vector2(68 + col * 192, 112 + row * 86)
        var accent := V36_PURPLE if chapter_id == 26 else (V34_CYAN if chapter_id >= 21 else V34_GREEN)
        var button := _v34_button("BÖLÜM %02d" % chapter_id, pos, Vector2(166, 58), accent)
        button.add_theme_font_size_override("font_size", 15)
        button.pressed.connect(func(): _v34_show_part_selector(chapter_id))
        overlay.add_child(button)
    var close := _v34_button("KAPAT", Vector2(490, 575), Vector2(300, 52), V34_RED)
    close.pressed.connect(_v24_close_dev_console)
    overlay.add_child(close)

func _v34_next_dev_target(c: int, p: int) -> Vector2i:
    if p < 3:
        return Vector2i(c, p + 1)
    if c < 26:
        return Vector2i(c + 1, 1)
    return Vector2i(-1, -1)

func _show_chapter_result() -> void:
    if chapter != 26:
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
    bg.color = V36_BG
    hud.add_child(bg)
    var line := ColorRect.new()
    line.size = Vector2(1280, 4)
    line.color = V36_PURPLE
    hud.add_child(line)
    var title := Label.new()
    title.position = Vector2(120, 65)
    title.size = Vector2(1040, 220)
    title.text = "BÖLÜM 26 TAMAMLANDI\n\nGÖRDÜĞÜN ŞEY ARTIK KURAL DEĞİL"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(title)
    var stats := Label.new()
    stats.position = Vector2(80, 305)
    stats.size = Vector2(1120, 155)
    stats.text = "26-1  %s / %s ölüm     26-2  %s / %s ölüm     26-3  %s / %s ölüm\n\nGÖRÜNÜR TEHLİKE • GERÇEK GÜVEN • TERS SİNYAL" % [_best_time_text(26, 1), _best_deaths_text(26, 1), _best_time_text(26, 2), _best_deaths_text(26, 2), _best_time_text(26, 3), _best_deaths_text(26, 3)]
    stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    stats.add_theme_font_size_override("font_size", 17)
    stats.add_theme_color_override("font_color", V36_CYAN)
    hud.add_child(stats)
    var milestone := Label.new()
    milestone.position = Vector2(160, 490)
    milestone.size = Vector2(960, 48)
    milestone.text = "26 / 100 BÖLÜM   •   78 / 300 HARİTA   •   %26 İÇERİK"
    milestone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    milestone.add_theme_font_size_override("font_size", 19)
    milestone.add_theme_color_override("font_color", V36_AMBER)
    hud.add_child(milestone)
    _v25_button("ANA MENÜ", Vector2(490, 565), Vector2(300, 64), func(): _show_main_menu(), V36_PURPLE)

func _v36_build_inversion_map(p: int) -> void:
    var length := 5300.0 + float(p - 1) * 120.0
    var gap1_start := 1540.0 + float(p - 1) * 10.0
    var gap1_width := 138.0 + float(p - 1) * 6.0
    var gap2_start := 3320.0 - float(p - 1) * 12.0
    var gap2_width := 142.0 + float(p % 2) * 6.0
    _floor_with_gaps(length, [Vector2(gap1_start, gap1_start + gap1_width), Vector2(gap2_start, gap2_start + gap2_width)])
    if is_instance_valid(world):
        world.set_meta("v35_gap_widths", PackedFloat32Array([gap1_width, gap2_width]))
        world.set_meta("v35_route_kind", "ground_single_jump")
        world.set_meta("v36_inversion", true)
        world.set_meta("v36_part", p)
    _v35_route_point(Vector2(140, 580), "walk", 0)
    _v35_route_point(Vector2(gap1_start - 22.0, 580), "walk", 1)
    _v35_route_point(Vector2(gap1_start + gap1_width + 22.0, 580), "single", 2)
    _v35_route_point(Vector2(gap2_start - 22.0, 580), "walk", 3)
    _v35_route_point(Vector2(gap2_start + gap2_width + 22.0, 580), "single", 4)
    _v35_route_point(Vector2(length - 250.0, 580), "walk", 5)
    _text(Vector2(120, 470), "BÖLÜM 26-%d • KURAL TERSİNE DÖNÜYOR" % p, 22, V36_PURPLE)
    if p == 1:
        _text(Vector2(440, 520), "GÖRDÜĞÜN TEHLİKE BAZEN ÇEKİLİR.", 16, V35_MUTED)
        _v36_disappearing_spikes(760.0, "261_visible")
        _v36_true_safe_marker(1130.0, "261_safe")
        _v35_lazy_mover_decoy(2110.0)
        _v36_plain_floor_trap(2710.0, "261_plain")
        _v36_boulder_or_fake(4020.0, "261_rock", true)
    elif p == 2:
        _text(Vector2(440, 520), "ŞÜPHELİ OLANIN HEPSİ TUZAK DEĞİL.", 16, V35_MUTED)
        _v36_true_safe_marker(720.0, "262_safe_a")
        _v36_plain_floor_trap(1120.0, "262_plain")
        _v36_disappearing_spikes(2050.0, "262_visible")
        _v36_true_safe_marker(2700.0, "262_safe_b")
        _v35_add_double_jump_rescue(3820.0)
        _v36_boulder_or_fake(4300.0, "262_fake_rock", false)
    else:
        var attempt := _attempt(26, 3)
        _text(Vector2(440, 520), "DENEME %d • SİNYAL DEĞİŞİR, FİZİK DEĞİŞMEZ." % attempt, 16, V35_MUTED)
        _v36_inverted_pair(820.0, "263_pair_a", attempt % 2 == 0)
        _v36_true_safe_marker(1250.0, "263_safe")
        _v35_lazy_mover_decoy(2110.0)
        _v36_inverted_pair(2720.0, "263_pair_b", attempt % 3 == 1)
        _v36_boulder_or_fake(4010.0, "263_rock", attempt % 3 == 2)
        _v35_fake_finish(4650.0, "263_fake_finish")
    _finish(Vector2(length - 170.0, 580))

func _v36_disappearing_spikes(x: float, key: String) -> void:
    var spikes := _spikes(Vector2(x, 612), 2, false)
    var trigger_x := x - 185.0
    _trigger(Rect2(trigger_x, 470, 105, 165), func():
        if _once(key):
            _hide(spikes)
            _false_alarm()
    )
    _v35_contract("inverted_visible", trigger_x, x, 1.0)

func _v36_true_safe_marker(x: float, key: String) -> void:
    _marker(Vector2(x, 555), V36_AMBER, "?")
    var trigger_x := x - 120.0
    _trigger(Rect2(trigger_x, 470, 95, 165), func():
        if _once(key):
            _false_alarm()
            _play_tone(620.0, 0.05, 0.06)
    )
    v35_contracts.append({"kind":"false_alarm", "trigger_x":trigger_x, "hazard_x":x, "reaction":1.0})

func _v36_plain_floor_trap(x: float, key: String) -> void:
    var spikes := _spikes(Vector2(x, 612), 2, true)
    var trigger_x := x - 165.0
    _trigger(Rect2(trigger_x, 470, 105, 165), func():
        if _once(key):
            var tw := create_tween()
            tw.tween_interval(0.34)
            tw.tween_callback(func(): _reveal(spikes))
            tw.tween_interval(0.52)
            tw.tween_callback(func(): _hide(spikes))
    )
    _v35_contract("plain_floor", trigger_x, x, 0.34)

func _v36_inverted_pair(x: float, key: String, left_real: bool) -> void:
    _marker(Vector2(x - 80.0, 555), V36_AMBER, "!")
    _marker(Vector2(x + 90.0, 555), V36_GREEN, "•")
    var left := _spikes(Vector2(x - 80.0, 612), 2, true)
    var right := _spikes(Vector2(x + 90.0, 612), 2, true)
    var target: Area2D = left if left_real else right
    var target_x := x - 80.0 if left_real else x + 90.0
    var trigger_x := x - 230.0
    _trigger(Rect2(trigger_x, 470, 110, 165), func():
        if _once(key):
            var tw := create_tween()
            tw.tween_interval(0.36)
            tw.tween_callback(func(): _reveal(target))
            tw.tween_interval(0.50)
            tw.tween_callback(func(): _hide(target))
    )
    _v35_contract("inverted_pair", trigger_x, target_x, 0.36)

func _v36_boulder_or_fake(x: float, key: String, real: bool) -> void:
    var trigger_x := x - 170.0
    _trigger(Rect2(trigger_x, 470, 105, 165), func():
        if _once(key):
            if real:
                _boulder(Vector2(x + 390.0, 560), -232.0, 52.0)
            else:
                _false_alarm()
    )
    v35_contracts.append({"kind":"boulder" if real else "false_alarm", "trigger_x":trigger_x, "hazard_x":x, "reaction":0.90 if real else 1.0})

func _v36_add_environment() -> void:
    if not is_instance_valid(world):
        return
    for i in range(int(level_width / 520.0) + 1):
        var x := 180.0 + float(i) * 520.0
        var slash := Line2D.new()
        slash.width = 2.0
        slash.default_color = Color(V36_PURPLE, 0.055)
        slash.points = PackedVector2Array([Vector2(x - 80, 420), Vector2(x + 80, 300)])
        slash.z_index = -36
        world.add_child(slash)

func _v36_air_jump_fx() -> void:
    if not is_instance_valid(player) or not is_instance_valid(world):
        return
    if not _v27_fx_begin(0.34):
        return
    var ring := Line2D.new()
    ring.position = player.global_position
    ring.width = 3.0
    ring.default_color = Color(V36_PURPLE, 0.72)
    var points := PackedVector2Array()
    for i in range(17):
        var a := TAU * float(i) / 16.0
        points.append(Vector2(cos(a), sin(a)) * 24.0)
    ring.points = points
    ring.z_index = 36
    world.add_child(ring)
    var tw := create_tween().set_parallel(true)
    tw.tween_property(ring, "scale", Vector2(1.7, 1.7), 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tw.tween_property(ring, "modulate:a", 0.0, 0.30)
    tw.chain().tween_callback(func():
        if is_instance_valid(ring):
            ring.queue_free()
    )

func _v23_run_validation() -> void:
    await get_tree().process_frame
    var failures := 0
    var checked := 0
    for c in range(1, 27):
        for p in range(1, 4):
            _start_level(c, p)
            await get_tree().process_frame
            await get_tree().process_frame
            checked += 1
            var level_failures := _v23_validate_current_level(c, p)
            failures += level_failures
            if level_failures == 0:
                print("LEVEL_VALIDATE_OK:%d-%d" % [c, p])
            else:
                print("LEVEL_VALIDATE_FAIL:%d-%d:%d" % [c, p, level_failures])
    if failures == 0 and checked == 78:
        print("ALL_LEVELS_OK:78")
        get_tree().quit(0)
    else:
        print("ALL_LEVELS_FAILED:%d:%d" % [checked, failures])
        get_tree().quit(1)
