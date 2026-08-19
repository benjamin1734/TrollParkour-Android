extends "res://scripts/game_v9.gd"

const V10_BG := Color("#edf1f6")
const V10_BG_CH8 := Color("#e7ece8")
const V10_INK := Color("#111827")
const V10_SLATE := Color("#475569")
const V10_MUTED := Color("#64748b")
const V10_BLUE := Color("#2563eb")
const V10_CYAN := Color("#0891b2")
const V10_GREEN := Color("#16a34a")
const V10_YELLOW := Color("#d97706")
const V10_RED := Color("#dc4455")
const V10_RED_DARK := Color("#7f2937")
const V10_PURPLE := Color("#7c3aed")

var controls_reversed: bool = false:
    set(value):
        controls_reversed = value
        if is_instance_valid(player):
            player.controls_reversed = value

func _start_level(c: int, p: int) -> void:
    super._start_level(c, p)
    if c == 8:
        RenderingServer.set_default_clear_color(V10_BG_CH8)
        _add_chapter8_decor()

func _build_level(c: int, p: int) -> void:
    if c == 8 and p == 1:
        _level_8_1()
    elif c == 8 and p == 2:
        _level_8_2()
    elif c == 8 and p == 3:
        _level_8_3()
    else:
        super._build_level(c, p)

func _build_hud() -> void:
    super._build_hud()
    if chapter == 8:
        var mode := Label.new()
        mode.position = Vector2(735, 19)
        mode.size = Vector2(245, 36)
        mode.text = "ZAMANLAMA"
        mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        mode.add_theme_font_size_override("font_size", 16)
        mode.add_theme_color_override("font_color", V10_CYAN)
        hud.add_child(mode)

func _show_main_menu() -> void:
    RenderingServer.set_default_clear_color(V10_BG)
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
    bg.color = V10_BG
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(bg)

    var top_band := ColorRect.new()
    top_band.size = Vector2(1280, 92)
    top_band.color = V10_INK
    top_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(top_band)

    var version := Label.new()
    version.position = Vector2(24, 27)
    version.size = Vector2(250, 40)
    version.text = "ANDROID • v1.0"
    version.add_theme_font_size_override("font_size", 18)
    version.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(version)

    var title := Label.new()
    title.position = Vector2(180, 122)
    title.size = Vector2(920, 95)
    title.text = "TROLL PARKOUR"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 58)
    title.add_theme_color_override("font_color", V10_INK)
    hud.add_child(title)

    var subtitle := Label.new()
    subtitle.position = Vector2(220, 208)
    subtitle.size = Vector2(840, 55)
    subtitle.text = "Bölüm 8: Doğru hareket yetmez. Doğru an da lazım."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 22)
    subtitle.add_theme_color_override("font_color", V10_MUTED)
    hud.add_child(subtitle)

    var progress := Label.new()
    progress.position = Vector2(285, 278)
    progress.size = Vector2(710, 44)
    var available := maxi(1, mini(unlocked_chapter, 8))
    var completed_maps := maxi(0, (mini(unlocked_chapter, 9) - 1) * 3)
    progress.text = "AÇIK BÖLÜM: %d / 8     HARİTA: %d / 24     ÖLÜM: %d" % [available, completed_maps, deaths]
    progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    progress.add_theme_font_size_override("font_size", 19)
    progress.add_theme_color_override("font_color", V10_RED_DARK)
    hud.add_child(progress)

    _menu_button("DEVAM ET", Vector2(440, 350), Vector2(400, 72), func():
        _start_level(maxi(1, mini(unlocked_chapter, 8)), 1)
    )
    _menu_button("BÖLÜMLER", Vector2(440, 440), Vector2(400, 72), func():
        _show_chapter_select()
    )
    _menu_button("1. BÖLÜMDEN BAŞLA", Vector2(440, 530), Vector2(400, 72), func():
        _start_level(1, 1)
    )

    var warning := Label.new()
    warning.position = Vector2(235, 630)
    warning.size = Vector2(810, 40)
    warning.text = "İpucu: Bazı tuzaklar sen geçtikten sonra çalışır."
    warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    warning.add_theme_font_size_override("font_size", 18)
    warning.add_theme_color_override("font_color", V10_MUTED)
    hud.add_child(warning)
    _polish_menu_surface()

func _show_chapter_select() -> void:
    RenderingServer.set_default_clear_color(V10_BG)
    if is_instance_valid(hud):
        hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)

    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V10_BG
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(240, 26)
    title.size = Vector2(800, 68)
    title.text = "BÖLÜM SEÇ"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 42)
    title.add_theme_color_override("font_color", V10_INK)
    hud.add_child(title)

    var info := Label.new()
    info.position = Vector2(170, 88)
    info.size = Vector2(940, 40)
    info.text = "8 bölüm • 24 harita • Hafıza + hareket + güven + zamanlama"
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.add_theme_font_size_override("font_size", 18)
    info.add_theme_color_override("font_color", V10_MUTED)
    hud.add_child(info)

    for i in range(1, 9):
        var chapter_id := i
        var is_unlocked := chapter_id <= unlocked_chapter
        var col := (i - 1) % 3
        var row := int((i - 1) / 3)
        var pos := Vector2(105 + col * 355, 145 + row * 112)
        var suffix := "3 HARİTA"
        if chapter_id == 5:
            suffix = "HAFIZA • 3 HARİTA"
        elif chapter_id == 6:
            suffix = "HAREKET • 3 HARİTA"
        elif chapter_id == 7:
            suffix = "GÜVEN • 3 HARİTA"
        elif chapter_id == 8:
            suffix = "ZAMAN • 3 HARİTA"
        var button_text := "BÖLÜM %d\n%s" % [chapter_id, suffix] if is_unlocked else "BÖLÜM %d\nKİLİTLİ" % chapter_id
        var button := _menu_button(button_text, pos, Vector2(320, 84), func():
            _start_level(chapter_id, 1)
        )
        button.disabled = not is_unlocked

    _menu_button("GERİ", Vector2(490, 505), Vector2(300, 66), func():
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
    bg.color = V10_INK
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(190, 105)
    title.size = Vector2(900, 290)
    var map_count := mini(chapter * 3, 24)
    title.text = "BÖLÜM %d TAMAMLANDI\n\nTOPLAM ÖLÜM: %d\nTAMAMLANAN HARİTA: %d / 24" % [chapter, deaths, map_count]
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(title)

    if chapter < 8:
        var next_chapter := chapter + 1
        _menu_button("SONRAKİ BÖLÜM", Vector2(440, 430), Vector2(400, 72), func():
            _start_level(next_chapter, 1)
        )
    else:
        var done := Label.new()
        done.position = Vector2(245, 400)
        done.size = Vector2(790, 90)
        done.text = "24 HARİTA TAMAM\nARTIK NE ZAMAN HAREKET ETTİĞİN DE ÖNEMLİ."
        done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        done.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        done.add_theme_font_size_override("font_size", 22)
        done.add_theme_color_override("font_color", V10_YELLOW)
        hud.add_child(done)

    _menu_button("ANA MENÜ", Vector2(490, 545), Vector2(300, 68), func():
        _show_main_menu()
    )

func _add_chapter8_decor() -> void:
    if not is_instance_valid(world):
        return
    for i in range(14):
        var bar := Polygon2D.new()
        var x := 180.0 + float(i) * 420.0
        var h := 55.0 + float((i * 29) % 115)
        bar.position = Vector2(x, 420.0 - h / 2.0)
        bar.polygon = PackedVector2Array([
            Vector2(-22, -h / 2.0), Vector2(22, -h / 2.0), Vector2(22, h / 2.0), Vector2(-22, h / 2.0)
        ])
        bar.color = Color(0.16, 0.31, 0.27, 0.05)
        bar.z_index = -22
        world.add_child(bar)

    for i in range(10):
        var tick := Line2D.new()
        var x := 320.0 + float(i) * 560.0
        tick.width = 2.0
        tick.default_color = Color(0.08, 0.48, 0.42, 0.08)
        tick.points = PackedVector2Array([Vector2(x, 405), Vector2(x, 438)])
        tick.z_index = -20
        world.add_child(tick)

func _timed_hazard(area: Area2D, wait_before: float, active_time: float, key: String) -> void:
    if not _once(key):
        return
    var tw := create_tween()
    tw.tween_interval(wait_before)
    tw.tween_callback(func():
        if is_instance_valid(area):
            _reveal(area)
            _play_tone(285.0, 0.07, 0.09)
    )
    tw.tween_interval(active_time)
    tw.tween_callback(func():
        if is_instance_valid(area):
            _hide(area)
    )

func _delayed_platform_drop(body: StaticBody2D, delay: float, distance: float = 300.0) -> void:
    var tw := create_tween()
    tw.tween_interval(delay)
    tw.tween_property(body, "position:y", body.position.y + distance, 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _pulse_gate(pos: Vector2, size: Vector2, cycles: int = 3) -> Area2D:
    var gate := _hidden_hazard(pos, size, V10_RED)
    var tw := create_tween()
    for i in range(cycles):
        tw.tween_interval(0.55)
        tw.tween_callback(func():
            if is_instance_valid(gate):
                _reveal(gate)
        )
        tw.tween_interval(0.34)
        tw.tween_callback(func():
            if is_instance_valid(gate):
                _hide(gate)
        )
    return gate

func _level_8_1() -> void:
    _floor_with_gaps(5600, [Vector2(1390, 1545), Vector2(3320, 3475)])
    _text(Vector2(120, 470), "BÖLÜM 8: DOĞRU AN.", 23, V10_CYAN)
    _text(Vector2(410, 520), "BAZEN ERKEN, BAZEN GEÇ.", 18, V10_MUTED)

    var late_spikes := _spikes(Vector2(820, 612), 3, true)
    _trigger(Rect2(590, 390, 120, 240), func():
        _timed_hazard(late_spikes, 0.46, 0.56, "81_late_spikes")
    )

    _moving_platform(Vector2(1465, 560), Vector2(150, 24), Vector2(1500, 475), 1.55, V10_BLUE)

    var stable := _platform(Vector2(2050, 548), Vector2(185, 26), V10_SLATE)
    _trigger(Rect2(1800, 390, 120, 240), func():
        if _once("81_fake_drop"):
            _false_alarm()
            create_tween().tween_property(stable, "position:y", 544.0, 0.12)
    )

    var actual_drop := _platform(Vector2(2480, 548), Vector2(180, 26), V10_BLUE)
    _trigger(Rect2(2230, 390, 120, 240), func():
        if _once("81_drop"):
            _delayed_platform_drop(actual_drop, 0.42, 310.0)
    )

    var gate := _hidden_hazard(Vector2(2990, 525), Vector2(28, 250), V10_RED)
    _trigger(Rect2(2710, 390, 120, 240), func():
        _timed_hazard(gate, 0.34, 0.48, "81_gate")
    )

    _moving_platform(Vector2(3400, 555), Vector2(145, 24), Vector2(3435, 470), 1.20, V10_CYAN)

    _decor_block(Vector2(3890, 350), Vector2(80, 170))
    _trigger(Rect2(3740, 390, 120, 240), func():
        if _once("81_alarm"):
            _false_alarm()
    )

    _spikes(Vector2(4260, 612), 2, false)

    _trigger(Rect2(4580, 390, 120, 240), func():
        if _once("81_rock"):
            var tw := create_tween()
            tw.tween_interval(0.38)
            tw.tween_callback(func(): _boulder(Vector2(5160, 560), -410.0, 72.0))
    )

    _finish(Vector2(5360, 580))

func _level_8_2() -> void:
    _floor_with_gaps(6100, [Vector2(1120, 1280), Vector2(2630, 2790), Vector2(4500, 4650)])
    _text(Vector2(120, 470), "RİTME ALIŞMA.", 23, V10_CYAN)

    _moving_platform(Vector2(1200, 560), Vector2(150, 24), Vector2(1230, 470), 1.42, V10_BLUE)

    var pulse_a := _hidden_hazard(Vector2(1750, 545), Vector2(270, 22), V10_RED)
    _trigger(Rect2(1470, 390, 120, 240), func():
        if _once("82_pulse_a"):
            var tw := create_tween()
            tw.tween_interval(0.28)
            tw.tween_callback(func(): _reveal(pulse_a))
            tw.tween_interval(0.36)
            tw.tween_callback(func(): _hide(pulse_a))
            tw.tween_interval(0.34)
            tw.tween_callback(func(): _reveal(pulse_a))
            tw.tween_interval(0.30)
            tw.tween_callback(func(): _hide(pulse_a))
    )

    var normal_a := _platform(Vector2(2250, 550), Vector2(175, 26), V10_SLATE)
    var normal_b := _platform(Vector2(2460, 520), Vector2(150, 26), V10_SLATE)
    _trigger(Rect2(2010, 390, 120, 240), func():
        if _once("82_normal"):
            _false_alarm()
            create_tween().tween_property(normal_a, "position:x", normal_a.position.x + 5.0, 0.12)
            create_tween().tween_property(normal_b, "position:y", normal_b.position.y - 4.0, 0.12)
    )

    _moving_platform(Vector2(2710, 560), Vector2(150, 24), Vector2(2750, 455), 1.15, V10_CYAN)

    var crusher := _hazard_block(Vector2(3340, 155), Vector2(115, 200), V10_RED_DARK)
    _trigger(Rect2(3050, 390, 120, 240), func():
        if _once("82_crusher"):
            var tw := create_tween()
            tw.tween_interval(0.62)
            tw.tween_property(crusher, "position:y", 480.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_interval(0.26)
            tw.tween_property(crusher, "position:y", 155.0, 0.50).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

    _spikes(Vector2(3850, 612), 3, true)
    var phase_spikes := _spikes(Vector2(4140, 612), 3, true)
    _trigger(Rect2(3630, 390, 120, 240), func():
        if _once("82_phase"):
            var tw := create_tween()
            tw.tween_interval(0.20)
            tw.tween_callback(func(): _reveal(phase_spikes))
            tw.tween_interval(0.34)
            tw.tween_callback(func(): _hide(phase_spikes))
    )

    _moving_platform(Vector2(4570, 560), Vector2(145, 24), Vector2(4610, 480), 1.36, V10_BLUE)

    _trigger(Rect2(4970, 390, 120, 240), func():
        if _once("82_reverse"):
            var tw := create_tween()
            tw.tween_interval(0.36)
            tw.tween_callback(func(): _reverse_controls(1.05))
    )

    var goal := _finish(Vector2(5780, 580))
    _trigger(Rect2(5480, 390, 120, 240), func():
        if _once("82_goal"):
            var tw := create_tween()
            tw.tween_interval(0.40)
            tw.tween_property(goal, "position:x", 5890.0, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

func _level_8_3() -> void:
    _floor_with_gaps(6700, [Vector2(980, 1140), Vector2(2870, 3030), Vector2(4880, 5040)])
    var a := _attempt(8, 3)
    _text(Vector2(120, 470), "SON TEST: ZAMAN + HAFIZA.", 23, V10_PURPLE)
    _text(Vector2(430, 520), "DENEME %d" % a, 18, V10_MUTED)

    _moving_platform(Vector2(1060, 560), Vector2(150, 24), Vector2(1090, 470), 1.30, V10_BLUE)

    var memory_a := _spikes(Vector2(1570, 612), 3, true)
    var memory_b := _spikes(Vector2(1840, 612), 3, true)
    _trigger(Rect2(1330, 390, 120, 240), func():
        if _once("83_memory"):
            var chosen := memory_a if a % 2 == 1 else memory_b
            var tw := create_tween()
            tw.tween_interval(0.34 if a % 3 == 0 else 0.20)
            tw.tween_callback(func(): _reveal(chosen))
            tw.tween_interval(0.50)
            tw.tween_callback(func(): _hide(chosen))
    )

    var wait_platform := _platform(Vector2(2370, 548), Vector2(180, 26), V10_SLATE)
    _trigger(Rect2(2130, 390, 120, 240), func():
        if _once("83_wait"):
            if a % 2 == 0:
                _false_alarm()
            else:
                _delayed_platform_drop(wait_platform, 0.72, 290.0)
    )

    _moving_platform(Vector2(2950, 560), Vector2(145, 24), Vector2(2990, 465), 1.18, V10_CYAN)

    var center_gate := _hidden_hazard(Vector2(3470, 530), Vector2(30, 230), V10_RED)
    _trigger(Rect2(3210, 390, 120, 240), func():
        if _once("83_gate"):
            var delay := 0.30 if a % 2 == 0 else 0.52
            _timed_hazard(center_gate, delay, 0.44, "83_gate_inner")
    )

    var ceiling := _hazard_block(Vector2(4050, 145), Vector2(120, 190), V10_RED_DARK)
    _trigger(Rect2(3780, 390, 120, 240), func():
        if _once("83_ceiling"):
            var tw := create_tween()
            tw.tween_interval(0.52)
            if a % 3 == 0:
                tw.tween_callback(func(): _false_alarm())
            else:
                tw.tween_property(ceiling, "position:y", 475.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
                tw.tween_interval(0.22)
                tw.tween_property(ceiling, "position:y", 145.0, 0.48).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

    _moving_platform(Vector2(4960, 560), Vector2(145, 24), Vector2(5000, 470), 1.26, V10_BLUE)

    _trigger(Rect2(5360, 390, 120, 240), func():
        if _once("83_rock"):
            var delay := 0.30 if a % 2 == 1 else 0.55
            var tw := create_tween()
            tw.tween_interval(delay)
            tw.tween_callback(func(): _boulder(Vector2(5980, 560), -405.0, 74.0))
    )

    var final_spikes := _spikes(Vector2(6060, 612), 3, true)
    _trigger(Rect2(5810, 390, 120, 240), func():
        if _once("83_final"):
            var tw := create_tween()
            tw.tween_interval(0.38)
            tw.tween_callback(func(): _reveal(final_spikes))
            tw.tween_interval(0.40)
            tw.tween_callback(func(): _hide(final_spikes))
    )

    var goal := _finish(Vector2(6440, 580))
    _trigger(Rect2(6200, 390, 120, 240), func():
        if _once("83_goal"):
            if a % 2 == 0:
                create_tween().tween_property(goal, "position:y", 475.0, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
            else:
                _false_alarm()
    )
