extends "res://scripts/game_v28.gd"

const V29_CORE := Color("#22d3ee")
const V29_CORE_ALT := Color("#8b5cf6")
const V29_SAFE := Color("#34d399")
const V29_WARN := Color("#f59e0b")
const V29_DANGER := Color("#fb7185")
const V29_PATH_MAX := 10

var v29_active_threats: Array[Dictionary] = []
var v29_risk_edges: Array[ColorRect] = []
var v29_last_visual_risk := -1

func _safe_load_progress() -> void:
    super._safe_load_progress()
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return
    var stored_unlock = cfg.get_value("progress", "unlocked_chapter", 1)
    if stored_unlock is int or stored_unlock is float:
        unlocked_chapter = clampi(int(stored_unlock), 1, 26)

func _start_level(c: int, p: int) -> void:
    _v29_cleanup_transients()
    v29_active_threats.clear()
    v29_risk_edges.clear()
    v29_last_visual_risk = -1
    super._start_level(c, p)
    if c == 25:
        RenderingServer.set_default_clear_color(Color("#040711"))
        _v29_add_synthesis_environment()

func _build_level(c: int, p: int) -> void:
    if c == 25 and p == 1:
        _v29_level_25_1()
    elif c == 25 and p == 2:
        _v29_level_25_2()
    elif c == 25 and p == 3:
        _v29_level_25_3()
    else:
        super._build_level(c, p)

func _process(delta: float) -> void:
    super._process(delta)
    _v29_sync_risk()
    _v29_update_risk_edges()

func _build_hud() -> void:
    super._build_hud()
    if not is_instance_valid(hud):
        return
    _v29_build_risk_edges()
    if chapter == 25:
        var mode := Label.new()
        mode.position = Vector2(650, 45)
        mode.size = Vector2(250, 22)
        mode.text = "SENTEZ / KARANLIK SINAV"
        mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        mode.add_theme_font_size_override("font_size", 11)
        mode.add_theme_color_override("font_color", V29_CORE)
        hud.add_child(mode)

func _on_player_died() -> void:
    if restarting or level_finished:
        return
    var filtered: Array[Vector2] = _v29_filter_path(v28_path_samples)
    super._on_player_died()
    if filtered.size() >= 2 and v28_path_pending:
        v28_last_path = filtered

func _show_main_menu() -> void:
    super._show_main_menu()
    if not is_instance_valid(hud):
        return
    for child in hud.get_children():
        if child is Label:
            var label := child as Label
            if label.text == "ANDROID • v2.8":
                label.text = "ANDROID • v2.9"
            elif label.text == "KARANLIK DÖNEM • BÖLÜM 24: TAKİP":
                label.text = "KARANLIK DÖNEM • BÖLÜM 25: SENTEZ"
            elif label.text.begins_with("REKOR KAYDI"):
                label.text = "REKOR KAYDI  %d / 75" % best_times_ms.size()
            elif label.text.begins_with("AÇIK BÖLÜM"):
                var available := maxi(1, mini(unlocked_chapter, 25))
                var completed_maps := maxi(0, (mini(unlocked_chapter, 26) - 1) * 3)
                label.text = "AÇIK BÖLÜM   %d / 25\nHARİTA        %d / 75\nTOPLAM ÖLÜM   %d" % [available, completed_maps, deaths]
            elif label.text == "İÇERİK ÜRETİMİ  72 / 300":
                label.text = "İÇERİK ÜRETİMİ  75 / 300"
            elif label.text == "Tehdit seni izliyor; kilitlendiği an nereye kaçacağını seç.":
                label.text = "Işık, gölge, sinyal ve takip artık aynı parkurda konuşuyor."
            elif label.text.begins_with("v2.8 TAKİP / RİSK"):
                label.text = "v2.9 SENTEZ / RİSK POLİSH\n\n• Risk HUD gerçek aktif tehditlerle senkronize\n• Ekran kenarı risk pulse sistemi eklendi\n• Ölüm rota izi akıllı filtreyle sadeleştirildi\n• Bölüm 25 karanlık dönemin ilk mini-finali"
        elif child is Button:
            var button := child as Button
            if button.text == "DEVAM ET":
                button.visible = false
                button.disabled = true
        elif child is ColorRect:
            var rect := child as ColorRect
            if is_equal_approx(rect.position.x, 98.0) and is_equal_approx(rect.position.y, 386.0) and is_equal_approx(rect.size.y, 10.0) and rect.size.x < 600.0:
                rect.size.x = 620.0 * 75.0 / 300.0
    _v25_button("DEVAM ET", Vector2(790, 350), Vector2(390, 60), func(): _start_level(maxi(1, mini(unlocked_chapter, 25)), 1), V29_CORE)

func _show_chapter_select() -> void:
    super._show_chapter_select()
    if not is_instance_valid(hud):
        return
    for child in hud.get_children():
        if child is Label:
            var label := child as Label
            if label.text == "24 BÖLÜM • 72 HARİTA • KARANLIK FAZ":
                label.text = "25 BÖLÜM • 75 HARİTA • KARANLIK FAZ"
            elif label.text.begins_with("Bölüm 21-40:"):
                label.position.y = 596
                label.size.y = 28
                label.text = "Bölüm 25: Işık + gölge + sinyal + takip mini-finali"
                label.add_theme_font_size_override("font_size", 13)
        elif child is Button:
            var button := child as Button
            if button.text == "GERİ":
                button.position.y = 642
                button.size.y = 48
    var chapter_id := 25
    var is_unlocked := chapter_id <= unlocked_chapter
    var button_text := "BÖLÜM 25\nSENTEZ" if is_unlocked else "BÖLÜM 25\nKİLİTLİ"
    var button := _v25_button(button_text, Vector2(48, 533), Vector2(276, 52), func(): _start_level(25, 1), V29_CORE)
    button.disabled = not is_unlocked

func _show_chapter_result() -> void:
    if chapter != 25:
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
    line.color = V29_CORE
    hud.add_child(line)

    var title := Label.new()
    title.position = Vector2(120, 56)
    title.size = Vector2(1040, 230)
    title.text = "BÖLÜM 25 TAMAMLANDI\n\nKARANLIĞIN İLK SINAVI BİTTİ"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 36)
    title.add_theme_color_override("font_color", V25_TEXT)
    hud.add_child(title)

    var stats := Label.new()
    stats.position = Vector2(75, 300)
    stats.size = Vector2(1130, 165)
    stats.text = "25-1  %s / %s ölüm     25-2  %s / %s ölüm     25-3  %s / %s ölüm\n\nRİSKİ OKU. SİNYALİ SORGULA. KİLİT NOKTASINDAN SONRA HAREKET ET." % [_best_time_text(25, 1), _best_deaths_text(25, 1), _best_time_text(25, 2), _best_deaths_text(25, 2), _best_time_text(25, 3), _best_deaths_text(25, 3)]
    stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    stats.add_theme_font_size_override("font_size", 18)
    stats.add_theme_color_override("font_color", V29_CORE)
    hud.add_child(stats)

    var milestone := Label.new()
    milestone.position = Vector2(160, 485)
    milestone.size = Vector2(960, 50)
    milestone.text = "25 / 100 BÖLÜM   •   75 / 300 HARİTA   •   %25 İÇERİK"
    milestone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    milestone.add_theme_font_size_override("font_size", 19)
    milestone.add_theme_color_override("font_color", V29_WARN)
    hud.add_child(milestone)
    _v25_button("ANA MENÜ", Vector2(490, 565), Vector2(300, 64), func(): _show_main_menu(), V29_CORE)

func _v24_open_dev_console() -> void:
    super._v24_open_dev_console()
    if not is_instance_valid(v24_dev_overlay):
        return
    for panel_child in v24_dev_overlay.get_children():
        for child in panel_child.get_children():
            if child is Label and child.text.begins_with("Komut biçimi:"):
                child.text = "Komut biçimi: WAREXT 25-3\nBölüm 1-25 • Kısım 1-3"

func _v24_execute_dev_command(command: String) -> void:
    var raw := command.strip_edges().to_upper()
    if not raw.begins_with("WAREXT "):
        _v24_dev_error("Kod WAREXT ile başlamalı. Örnek: WAREXT 25-3")
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
    if target_chapter < 1 or target_chapter > 25:
        _v24_dev_error("Bölüm 1 ile 25 arasında olmalı.")
        return
    if target_part < 1 or target_part > 3:
        _v24_dev_error("Kısım 1 ile 3 arasında olmalı.")
        return
    _v24_close_dev_console()
    v24_dev_session = true
    _start_level(target_chapter, target_part)

func _v28_set_risk(level: int, duration: float = 0.8) -> void:
    var safe_level := clampi(level, 0, 3)
    if safe_level <= 0:
        return
    var expiry := Time.get_ticks_msec() + int(maxf(0.15, duration) * 1000.0)
    v29_active_threats.append({"level": safe_level, "until": expiry})
    _v29_sync_risk()

func _v29_sync_risk() -> void:
    var now := Time.get_ticks_msec()
    var kept: Array[Dictionary] = []
    var max_level := 0
    var latest := 0
    for entry in v29_active_threats:
        var expiry := int(entry.get("until", 0))
        if expiry <= now:
            continue
        var level := clampi(int(entry.get("level", 0)), 0, 3)
        kept.append(entry)
        max_level = maxi(max_level, level)
        latest = maxi(latest, expiry)
    v29_active_threats = kept
    v28_risk_level = max_level
    v28_risk_until_msec = latest
    _v28_refresh_risk_label()

func _v29_build_risk_edges() -> void:
    if not is_instance_valid(hud):
        return
    var specs := [
        [Vector2(0, 0), Vector2(1280, 10)],
        [Vector2(0, 710), Vector2(1280, 10)],
        [Vector2(0, 0), Vector2(10, 720)],
        [Vector2(1270, 0), Vector2(10, 720)]
    ]
    for spec in specs:
        var edge := ColorRect.new()
        edge.position = spec[0]
        edge.size = spec[1]
        edge.color = Color(V29_DANGER, 0.0)
        edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
        edge.z_index = 70
        hud.add_child(edge)
        v29_risk_edges.append(edge)

func _v29_update_risk_edges() -> void:
    if v29_risk_edges.is_empty():
        return
    var level := v28_risk_level
    var base_color := V29_SAFE
    var base_alpha := 0.0
    if level == 1:
        base_color = V29_SAFE
        base_alpha = 0.08
    elif level == 2:
        base_color = V29_WARN
        base_alpha = 0.13
    elif level >= 3:
        base_color = V29_DANGER
        base_alpha = 0.18
    var pulse := 1.0
    if level >= 2:
        pulse = 0.72 + 0.28 * sin(float(Time.get_ticks_msec()) * 0.009)
    for edge in v29_risk_edges:
        if is_instance_valid(edge):
            edge.color = Color(base_color, base_alpha * pulse)
    v29_last_visual_risk = level

func _v29_filter_path(points: Array[Vector2]) -> Array[Vector2]:
    var result: Array[Vector2] = []
    if points.size() < 2:
        return result
    result.append(points[0])
    var last_kept := points[0]
    var last_dir := Vector2.ZERO
    for i in range(1, points.size() - 1):
        var point := points[i]
        var delta := point - last_kept
        if delta.length() < 34.0:
            continue
        var direction := delta.normalized()
        var changed_direction := last_dir == Vector2.ZERO or last_dir.dot(direction) < 0.94
        if changed_direction or delta.length() >= 72.0:
            result.append(point)
            last_kept = point
            last_dir = direction
    var endpoint := points[points.size() - 1]
    if result[result.size() - 1].distance_to(endpoint) > 10.0:
        result.append(endpoint)
    while result.size() > V29_PATH_MAX:
        var reduced: Array[Vector2] = []
        for i in range(result.size()):
            if i == 0 or i == result.size() - 1 or i % 2 == 0:
                reduced.append(result[i])
        result = reduced
    return result

func _v29_cleanup_transients() -> void:
    for node in get_tree().get_nodes_in_group("v29_transient"):
        if is_instance_valid(node):
            node.queue_free()

func _v29_telegraph(x: float, level: int, duration: float = 0.48, honest: bool = true) -> void:
    var color := V29_CORE_ALT
    if honest:
        color = V29_DANGER if level >= 3 else V29_WARN if level == 2 else V29_SAFE
    _v28_set_risk(level if honest else 1, duration + 0.62)
    _v28_tracker_line(x, color, duration)
    _v27_signal_line(x, color, duration)

func _v29_add_synthesis_environment() -> void:
    if not is_instance_valid(world):
        return
    for i in range(16):
        var x := 240.0 + float(i) * 470.0
        if x > level_width:
            break
        var line := Line2D.new()
        line.width = 1.0
        line.default_color = Color(V29_CORE_ALT, 0.035 if i % 2 == 0 else 0.020)
        line.points = PackedVector2Array([Vector2(x - 70, 175), Vector2(x + 70, 175)])
        line.z_index = -105
        world.add_child(line)

func _v29_level_25_1() -> void:
    _floor_with_gaps(6700, [Vector2(1780, 1940), Vector2(4120, 4280)])
    _text(Vector2(120, 470), "BÖLÜM 25: SENTEZ.", 25, V29_CORE)
    _text(Vector2(390, 520), "GÖR. SORGULA. KİLİTLENİNCE HAREKET ET.", 17, V25_MUTED)

    var first := _spikes(Vector2(1080, 612), 3, true)
    _trigger(Rect2(700, 390, 130, 240), func():
        if _once("251_first"):
            _v29_telegraph(1080.0, 2, 0.48, true)
            var tw := create_tween()
            tw.tween_interval(0.54)
            tw.tween_callback(func(): _reveal(first))
            tw.tween_interval(0.56)
            tw.tween_callback(func(): _hide(first))
    )

    var shadow_bridge := _v26_shadow_platform(Vector2(1860, 555), Vector2(150, 24), 0.20)
    _trigger(Rect2(1460, 390, 130, 240), func():
        if _once("251_shadow"):
            _v26_shadow_pulse([shadow_bridge], V29_CORE)
    )

    _trigger(Rect2(2230, 390, 130, 240), func():
        if _once("251_fake"):
            _v29_telegraph(2700.0, 1, 0.48, false)
            _false_alarm()
    )

    var lock_gate := _hazard_block(Vector2(3300, 210), Vector2(110, 70), V25_RED)
    _trigger(Rect2(2860, 390, 140, 240), func():
        if not trigger_state.has("251_lock"):
            trigger_state["251_lock"] = true
            _v28_lock_player_lane(lock_gate, "251_lock_real", 0.58)
    )

    _moving_platform(Vector2(4200, 555), Vector2(145, 24), Vector2(4240, 470), 1.44, V25_CYAN)

    _trigger(Rect2(4650, 390, 130, 240), func():
        if _once("251_rock"):
            _v29_telegraph(5250.0, 2, 0.50, true)
            var tw := create_tween()
            tw.tween_interval(0.58)
            tw.tween_callback(func(): _boulder(Vector2(5420, 560), -322.0, 62.0))
    )

    var last := _spikes(Vector2(6040, 612), 2, true)
    _trigger(Rect2(5680, 390, 130, 240), func():
        if _once("251_last"):
            _v29_telegraph(6040.0, 2, 0.46, true)
            var tw := create_tween()
            tw.tween_interval(0.52)
            tw.tween_callback(func(): _reveal(last))
            tw.tween_interval(0.56)
            tw.tween_callback(func(): _hide(last))
    )
    _finish(Vector2(6440, 580))

func _v29_level_25_2() -> void:
    _floor_with_gaps(7200, [Vector2(1680, 1840), Vector2(3900, 4060), Vector2(5700, 5860)])
    _text(Vector2(120, 470), "AYNI SİNYAL. FARKLI ROTA.", 24, V29_CORE_ALT)

    _v29_telegraph(820.0, 1, 0.52, false)
    var harmless := _platform(Vector2(850, 555), Vector2(180, 24), V25_PLATFORM_ALT)
    _trigger(Rect2(600, 390, 130, 240), func():
        if _once("252_harmless"):
            create_tween().tween_property(harmless, "position:y", 552.0, 0.14)
            _false_alarm()
    )

    _moving_platform(Vector2(1760, 555), Vector2(145, 24), Vector2(1800, 470), 1.44, V25_CYAN)

    _route_hint(Vector2(2520, 490), "ALT")
    _route_hint(Vector2(2520, 385), "ÜST")
    _platform(Vector2(2610, 455), Vector2(240, 24), V25_PLATFORM_ALT)
    _trigger(Rect2(2280, 305, 260, 185), func():
        if _choose_route("upper"):
            _v25_pulse_notice("ÜST", V29_CORE_ALT)
    )
    _trigger(Rect2(2280, 490, 260, 150), func():
        if _choose_route("lower"):
            _v25_pulse_notice("ALT", V29_CORE)
    )

    var route_spikes := _spikes(Vector2(3340, 612), 3, true)
    _trigger(Rect2(3020, 390, 130, 240), func():
        if _once("252_route"):
            if route_choice == "upper":
                _v29_telegraph(3340.0, 2, 0.48, true)
                var tw := create_tween()
                tw.tween_interval(0.54)
                tw.tween_callback(func(): _reveal(route_spikes))
                tw.tween_interval(0.56)
                tw.tween_callback(func(): _hide(route_spikes))
            else:
                _v29_telegraph(3340.0, 1, 0.48, false)
                _false_alarm()
    )

    _moving_platform(Vector2(3980, 555), Vector2(145, 24), Vector2(4020, 472), 1.44, V25_BLUE)

    var lock_gate := _hazard_block(Vector2(4880, 210), Vector2(110, 70), V25_RED)
    _trigger(Rect2(4460, 390, 140, 240), func():
        if not trigger_state.has("252_lock"):
            trigger_state["252_lock"] = true
            if route_choice == "lower":
                _v28_lock_player_lane(lock_gate, "252_lock_real", 0.60)
            else:
                _v29_telegraph(player.global_position.x + 120.0 if is_instance_valid(player) else 4880.0, 1, 0.50, false)
                _false_alarm()
    )

    var shadow := _v26_shadow_mover(Vector2(5780, 555), Vector2(145, 24), Vector2(5820, 470), 1.46, 0.20)
    _trigger(Rect2(5400, 390, 130, 240), func():
        if _once("252_shadow"):
            _v26_shadow_pulse([shadow], V29_CORE)
    )

    _trigger(Rect2(6200, 390, 130, 240), func():
        if _once("252_rock"):
            var real := route_choice == "upper"
            _v29_telegraph(6760.0, 2 if real else 1, 0.48, real)
            if real:
                var tw := create_tween()
                tw.tween_interval(0.56)
                tw.tween_callback(func(): _boulder(Vector2(6890, 560), -318.0, 62.0))
            else:
                _false_alarm()
    )
    _finish(Vector2(6940, 580))

func _v29_level_25_3() -> void:
    _floor_with_gaps(8100, [Vector2(1760, 1920), Vector2(4040, 4200), Vector2(6280, 6440)])
    var attempt: int = _attempt(25, 3)
    _text(Vector2(120, 470), "KARANLIK SINAV SENİ HATIRLIYOR.", 24, V29_CORE_ALT)
    _text(Vector2(430, 520), "DENEME %d" % attempt, 17, V25_MUTED)

    var first_a := _spikes(Vector2(980, 612), 3, true)
    var first_b := _spikes(Vector2(1320, 612), 3, true)
    _trigger(Rect2(660, 390, 130, 240), func():
        if _once("253_first"):
            var target: Area2D = first_a if attempt % 2 == 1 else first_b
            var target_x := 980.0 if attempt % 2 == 1 else 1320.0
            var fake_x := 1320.0 if attempt % 2 == 1 else 980.0
            _v29_telegraph(target_x, 2, 0.48, true)
            _v29_telegraph(fake_x, 1, 0.48, false)
            var tw := create_tween()
            tw.tween_interval(0.54)
            tw.tween_callback(func(): _reveal(target))
            tw.tween_interval(0.56)
            tw.tween_callback(func(): _hide(target))
    )

    var shadow_a := _v26_shadow_platform(Vector2(1840, 555), Vector2(145, 24), 0.18)
    _trigger(Rect2(1500, 390, 130, 240), func():
        if _once("253_shadow_a"):
            _v26_shadow_pulse([shadow_a], V29_CORE)
    )

    var gate_a := _hazard_block(Vector2(2640, 210), Vector2(110, 70), V25_RED)
    _trigger(Rect2(2220, 390, 140, 240), func():
        if not trigger_state.has("253_gate_a"):
            trigger_state["253_gate_a"] = true
            if attempt % 3 != 0:
                _v28_lock_player_lane(gate_a, "253_gate_a_real", 0.58)
            else:
                _v29_telegraph(2640.0, 1, 0.50, false)
                _false_alarm()
    )

    _route_hint(Vector2(3380, 490), "SOLUK")
    _route_hint(Vector2(3380, 385), "PARLAK")
    _platform(Vector2(3470, 455), Vector2(240, 24), V25_PLATFORM_ALT)
    _trigger(Rect2(3140, 305, 260, 185), func():
        if _choose_route("bright"):
            _v25_pulse_notice("PARLAK", V29_CORE_ALT)
    )
    _trigger(Rect2(3140, 490, 260, 150), func():
        if _choose_route("dim"):
            _v25_pulse_notice("SOLUK", V29_CORE)
    )

    _moving_platform(Vector2(4120, 555), Vector2(145, 24), Vector2(4160, 472), 1.44, V25_BLUE)

    var route_spikes := _spikes(Vector2(4860, 612), 3, true)
    _trigger(Rect2(4520, 390, 130, 240), func():
        if _once("253_route"):
            var bad_route := (attempt % 2 == 0 and route_choice == "bright") or (attempt % 2 == 1 and route_choice == "dim")
            _v29_telegraph(4860.0, 2 if bad_route else 1, 0.48, bad_route)
            if bad_route:
                var tw := create_tween()
                tw.tween_interval(0.54)
                tw.tween_callback(func(): _reveal(route_spikes))
                tw.tween_interval(0.56)
                tw.tween_callback(func(): _hide(route_spikes))
            else:
                _false_alarm()
    )

    var wait_gate := _hazard_block(Vector2(5660, 210), Vector2(110, 70), V25_RED)
    _trigger(Rect2(5280, 390, 260, 240), func():
        _wait_check(5440.0, 170.0, 1.08, func():
            var real := attempt % 3 == 1
            if real:
                _v28_lock_player_lane(wait_gate, "253_wait_gate_real", 0.60)
            else:
                _v29_telegraph(5660.0, 1, 0.48, false)
                _false_alarm()
        , "253_wait")
    )

    var shadow_b := _v26_shadow_mover(Vector2(6360, 555), Vector2(145, 24), Vector2(6400, 470), 1.46, 0.18)
    _trigger(Rect2(6040, 390, 130, 240), func():
        if _once("253_shadow_b"):
            _v26_shadow_pulse([shadow_b], V29_CORE_ALT)
    )

    _trigger(Rect2(6740, 390, 130, 240), func():
        if _once("253_rock"):
            var rock_real := attempt % 3 == 2
            _v29_telegraph(7300.0, 2 if rock_real else 1, 0.50, rock_real)
            if rock_real:
                var tw := create_tween()
                tw.tween_interval(0.58)
                tw.tween_callback(func(): _boulder(Vector2(7440, 560), -314.0, 62.0))
            else:
                _false_alarm()
    )

    var final_spikes := _spikes(Vector2(7480, 612), 2, true)
    _trigger(Rect2(7180, 390, 130, 240), func():
        if _once("253_final") and attempt % 3 != 2:
            _v29_telegraph(7480.0, 2, 0.46, true)
            var tw := create_tween()
            tw.tween_interval(0.52)
            tw.tween_callback(func(): _reveal(final_spikes))
            tw.tween_interval(0.56)
            tw.tween_callback(func(): _hide(final_spikes))
    )
    _finish(Vector2(7850, 580))

func _v23_run_validation() -> void:
    await get_tree().process_frame
    var failures: int = 0
    var checked: int = 0
    for c in range(1, 26):
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
    if failures == 0 and checked == 75:
        print("ALL_LEVELS_OK:75")
        get_tree().quit(0)
    else:
        print("ALL_LEVELS_FAILED:%d:%d" % [checked, failures])
        get_tree().quit(1)
