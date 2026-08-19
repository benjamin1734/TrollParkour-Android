extends "res://scripts/game_v10.gd"

const V11_BG := Color("#edf1f6")
const V11_BG_CH9 := Color("#ece9e3")
const V11_INK := Color("#111827")
const V11_SLATE := Color("#475569")
const V11_MUTED := Color("#64748b")
const V11_BLUE := Color("#2563eb")
const V11_CYAN := Color("#0891b2")
const V11_GREEN := Color("#16a34a")
const V11_YELLOW := Color("#d97706")
const V11_RED := Color("#dc4455")
const V11_RED_DARK := Color("#7f2937")
const V11_PURPLE := Color("#7c3aed")

var route_choice := ""

func _start_level(c: int, p: int) -> void:
    route_choice = ""
    super._start_level(c, p)
    if c == 9:
        RenderingServer.set_default_clear_color(V11_BG_CH9)
        _add_chapter9_decor()

func _build_level(c: int, p: int) -> void:
    if c == 9 and p == 1:
        _level_9_1()
    elif c == 9 and p == 2:
        _level_9_2()
    elif c == 9 and p == 3:
        _level_9_3()
    else:
        super._build_level(c, p)

func _build_hud() -> void:
    super._build_hud()
    if chapter == 9:
        var mode := Label.new()
        mode.position = Vector2(735, 19)
        mode.size = Vector2(245, 36)
        mode.text = "ROTA TESTİ"
        mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        mode.add_theme_font_size_override("font_size", 16)
        mode.add_theme_color_override("font_color", V11_YELLOW)
        hud.add_child(mode)

func _show_main_menu() -> void:
    RenderingServer.set_default_clear_color(V11_BG)
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
    bg.color = V11_BG
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(bg)

    var top_band := ColorRect.new()
    top_band.size = Vector2(1280, 92)
    top_band.color = V11_INK
    top_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(top_band)

    var version := Label.new()
    version.position = Vector2(24, 27)
    version.size = Vector2(250, 40)
    version.text = "ANDROID • v1.1"
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
    title.add_theme_color_override("font_color", V11_INK)
    hud.add_child(title)

    var subtitle := Label.new()
    subtitle.position = Vector2(220, 208)
    subtitle.size = Vector2(840, 55)
    subtitle.text = "Bölüm 9: Doğru yol diye bir şey var. Bazen."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 22)
    subtitle.add_theme_color_override("font_color", V11_MUTED)
    hud.add_child(subtitle)

    var progress := Label.new()
    progress.position = Vector2(285, 278)
    progress.size = Vector2(710, 44)
    var available := maxi(1, mini(unlocked_chapter, 9))
    var completed_maps := maxi(0, (mini(unlocked_chapter, 10) - 1) * 3)
    progress.text = "AÇIK BÖLÜM: %d / 9     HARİTA: %d / 27     ÖLÜM: %d" % [available, completed_maps, deaths]
    progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    progress.add_theme_font_size_override("font_size", 19)
    progress.add_theme_color_override("font_color", V11_RED_DARK)
    hud.add_child(progress)

    _menu_button("DEVAM ET", Vector2(440, 350), Vector2(400, 72), func():
        _start_level(maxi(1, mini(unlocked_chapter, 9)), 1)
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
    warning.text = "İpucu: Daha korkutucu görünen rota bazen daha dürüsttür."
    warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    warning.add_theme_font_size_override("font_size", 18)
    warning.add_theme_color_override("font_color", V11_MUTED)
    hud.add_child(warning)
    _polish_menu_surface()

func _show_chapter_select() -> void:
    RenderingServer.set_default_clear_color(V11_BG)
    if is_instance_valid(hud):
        hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)

    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V11_BG
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(240, 22)
    title.size = Vector2(800, 66)
    title.text = "BÖLÜM SEÇ"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 41)
    title.add_theme_color_override("font_color", V11_INK)
    hud.add_child(title)

    var info := Label.new()
    info.position = Vector2(160, 82)
    info.size = Vector2(960, 40)
    info.text = "9 bölüm • 27 harita • Hafıza + hareket + güven + zaman + rota"
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.add_theme_font_size_override("font_size", 18)
    info.add_theme_color_override("font_color", V11_MUTED)
    hud.add_child(info)

    for i in range(1, 10):
        var chapter_id := i
        var is_unlocked := chapter_id <= unlocked_chapter
        var col := (i - 1) % 3
        var row := int((i - 1) / 3)
        var pos := Vector2(105 + col * 355, 137 + row * 112)
        var suffix := "3 HARİTA"
        if chapter_id == 5:
            suffix = "HAFIZA • 3 HARİTA"
        elif chapter_id == 6:
            suffix = "HAREKET • 3 HARİTA"
        elif chapter_id == 7:
            suffix = "GÜVEN • 3 HARİTA"
        elif chapter_id == 8:
            suffix = "ZAMAN • 3 HARİTA"
        elif chapter_id == 9:
            suffix = "ROTA • 3 HARİTA"
        var button_text := "BÖLÜM %d\n%s" % [chapter_id, suffix] if is_unlocked else "BÖLÜM %d\nKİLİTLİ" % chapter_id
        var button := _menu_button(button_text, pos, Vector2(320, 84), func():
            _start_level(chapter_id, 1)
        )
        button.disabled = not is_unlocked

    _menu_button("GERİ", Vector2(490, 500), Vector2(300, 64), func():
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
    bg.color = V11_INK
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(190, 105)
    title.size = Vector2(900, 290)
    var map_count := mini(chapter * 3, 27)
    title.text = "BÖLÜM %d TAMAMLANDI\n\nTOPLAM ÖLÜM: %d\nTAMAMLANAN HARİTA: %d / 27" % [chapter, deaths, map_count]
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(title)

    if chapter < 9:
        var next_chapter := chapter + 1
        _menu_button("SONRAKİ BÖLÜM", Vector2(440, 430), Vector2(400, 72), func():
            _start_level(next_chapter, 1)
        )
    else:
        var done := Label.new()
        done.position = Vector2(245, 400)
        done.size = Vector2(790, 90)
        done.text = "27 HARİTA TAMAM\nBİR SONRAKİ BÖLÜM İLK 10'UN FİNALİ."
        done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        done.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        done.add_theme_font_size_override("font_size", 22)
        done.add_theme_color_override("font_color", V11_YELLOW)
        hud.add_child(done)

    _menu_button("ANA MENÜ", Vector2(490, 545), Vector2(300, 68), func():
        _show_main_menu()
    )

func _add_chapter9_decor() -> void:
    if not is_instance_valid(world):
        return
    for i in range(13):
        var fork := Line2D.new()
        var x := 260.0 + float(i) * 440.0
        fork.width = 3.0
        fork.default_color = Color(0.46, 0.32, 0.14, 0.07)
        fork.points = PackedVector2Array([Vector2(x - 42, 430), Vector2(x, 390), Vector2(x + 42, 430)])
        fork.z_index = -22
        world.add_child(fork)
    var horizon := Line2D.new()
    horizon.width = 2.0
    horizon.default_color = Color(0.36, 0.30, 0.24, 0.08)
    horizon.points = PackedVector2Array([Vector2(0, 438), Vector2(level_width, 438)])
    horizon.z_index = -21
    world.add_child(horizon)

func _route_hint(pos: Vector2, text: String) -> void:
    var line := Line2D.new()
    line.position = pos
    line.width = 2.0
    line.default_color = Color(0.25, 0.31, 0.39, 0.20)
    line.points = PackedVector2Array([Vector2(-54, 0), Vector2(54, 0)])
    world.add_child(line)
    _text(pos + Vector2(-48, -30), text, 15, V11_MUTED)

func _choose_route(name: String) -> bool:
    if route_choice != "":
        return false
    route_choice = name
    _play_tone(330.0 if name == "upper" else 250.0, 0.07, 0.08)
    return true

func _level_9_1() -> void:
    _floor_with_gaps(5900, [Vector2(1630, 1790), Vector2(4070, 4230)])
    _text(Vector2(120, 470), "BÖLÜM 9: YOLUNU SEÇ.", 23, V11_YELLOW)
    _text(Vector2(410, 520), "OYUN SENİN SEÇİMİNİ DE KULLANIR.", 18, V11_MUTED)
    _route_hint(Vector2(900, 500), "ALT")
    _route_hint(Vector2(900, 390), "ÜST")
    _platform(Vector2(970, 470), Vector2(260, 24), V11_BLUE)
    _platform(Vector2(1290, 450), Vector2(220, 24), V11_BLUE)
    var upper_spikes := _spikes(Vector2(1420, 447), 2, true)
    var lower_spikes := _spikes(Vector2(1370, 612), 3, true)
    _trigger(Rect2(810, 320, 220, 170), func():
        if _choose_route("upper"):
            _false_alarm()
            var tw := create_tween()
            tw.tween_interval(0.52)
            tw.tween_callback(func(): _reveal(lower_spikes))
            tw.tween_interval(0.42)
            tw.tween_callback(func(): _hide(lower_spikes))
    )
    _trigger(Rect2(810, 500, 220, 150), func():
        if _choose_route("lower"):
            var tw := create_tween()
            tw.tween_interval(0.34)
            tw.tween_callback(func(): _reveal(lower_spikes))
            tw.tween_interval(0.48)
            tw.tween_callback(func(): _hide(lower_spikes))
            tw.tween_callback(func(): _reveal(upper_spikes))
    )
    _moving_platform(Vector2(1710, 555), Vector2(150, 24), Vector2(1745, 470), 1.45, V11_CYAN)
    var decoy := _platform(Vector2(2220, 548), Vector2(190, 26), V11_SLATE)
    _trigger(Rect2(1980, 390, 120, 240), func():
        if _once("91_decoy"):
            _false_alarm()
            create_tween().tween_property(decoy, "position:y", 544.0, 0.14)
    )
    var plain_trap := _spikes(Vector2(2760, 612), 3, true)
    _trigger(Rect2(2500, 390, 120, 240), func():
        if _once("91_plain"):
            var tw := create_tween()
            tw.tween_interval(0.26)
            tw.tween_callback(func(): _reveal(plain_trap))
    )
    _decor_block(Vector2(3250, 350), Vector2(90, 190))
    _trigger(Rect2(3100, 390, 120, 240), func():
        if _once("91_harmless_machine"):
            _false_alarm()
    )
    _spikes(Vector2(3660, 612), 2, false)
    _moving_platform(Vector2(4150, 555), Vector2(150, 24), Vector2(4180, 475), 1.35, V11_BLUE)
    _trigger(Rect2(4550, 390, 120, 240), func():
        if _once("91_rock"):
            var tw := create_tween()
            tw.tween_interval(0.28)
            tw.tween_callback(func(): _boulder(Vector2(5150, 560), -400.0, 70.0))
    )
    var goal := _finish(Vector2(5570, 580))
    _trigger(Rect2(5260, 390, 120, 240), func():
        if _once("91_goal") and route_choice == "upper":
            create_tween().tween_property(goal, "position:y", 505.0, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

func _level_9_2() -> void:
    _floor_with_gaps(6200, [Vector2(1940, 2100), Vector2(4490, 4650)])
    _text(Vector2(120, 470), "KISA YOL, UZUN YOL.", 23, V11_YELLOW)
    _text(Vector2(410, 520), "ETİKETLER SADECE ETİKET.", 18, V11_MUTED)
    _route_hint(Vector2(820, 500), "KISA")
    _route_hint(Vector2(820, 390), "UZUN")
    _platform(Vector2(920, 465), Vector2(230, 24), V11_BLUE)
    _platform(Vector2(1200, 430), Vector2(210, 24), V11_BLUE)
    _platform(Vector2(1460, 470), Vector2(190, 24), V11_BLUE)
    _trigger(Rect2(730, 315, 220, 175), func():
        if _choose_route("upper"):
            _false_alarm()
    )
    _trigger(Rect2(730, 500, 220, 150), func():
        if _choose_route("lower"):
            var bait := _spikes(Vector2(1260, 612), 2, true)
            var tw := create_tween()
            tw.tween_interval(0.40)
            tw.tween_callback(func(): _reveal(bait))
            tw.tween_interval(0.45)
            tw.tween_callback(func(): _hide(bait))
    )
    _moving_platform(Vector2(2020, 555), Vector2(150, 24), Vector2(2060, 470), 1.45, V11_CYAN)
    var gate_a := _hidden_hazard(Vector2(2560, 530), Vector2(26, 230), V11_RED)
    var gate_b := _hidden_hazard(Vector2(2860, 530), Vector2(26, 230), V11_RED)
    _trigger(Rect2(2290, 390, 120, 240), func():
        if _once("92_gates"):
            var tw := create_tween()
            tw.tween_interval(0.28)
            tw.tween_callback(func(): _reveal(gate_a))
            tw.tween_interval(0.32)
            tw.tween_callback(func(): _hide(gate_a))
            tw.tween_interval(0.18)
            tw.tween_callback(func(): _reveal(gate_b))
            tw.tween_interval(0.34)
            tw.tween_callback(func(): _hide(gate_b))
    )
    var suspicious := _platform(Vector2(3350, 548), Vector2(180, 26), V11_RED_DARK.lerp(V11_SLATE, 0.75))
    _trigger(Rect2(3110, 390, 120, 240), func():
        if _once("92_suspicious_safe"):
            _false_alarm()
            create_tween().tween_property(suspicious, "position:x", 3355.0, 0.12)
    )
    var normal_drop := _platform(Vector2(3820, 548), Vector2(185, 26), V11_SLATE)
    _trigger(Rect2(3560, 390, 120, 240), func():
        if _once("92_normal_drop"):
            _delayed_platform_drop(normal_drop, 0.48, 305.0)
    )
    _moving_platform(Vector2(4570, 555), Vector2(145, 24), Vector2(4610, 470), 1.30, V11_BLUE)
    var last := _spikes(Vector2(5120, 612), 3, true)
    _trigger(Rect2(4860, 390, 120, 240), func():
        if _once("92_last"):
            var delay := 0.52 if route_choice == "upper" else 0.30
            var tw := create_tween()
            tw.tween_interval(delay)
            tw.tween_callback(func(): _reveal(last))
            tw.tween_interval(0.46)
            tw.tween_callback(func(): _hide(last))
    )
    _finish(Vector2(5900, 580))

func _level_9_3() -> void:
    _floor_with_gaps(6500, [Vector2(1710, 1865), Vector2(3650, 3810), Vector2(5310, 5470)])
    var a := _attempt(9, 3)
    _text(Vector2(120, 470), "SEÇİMİNİ HATIRLIYORUM.", 23, V11_PURPLE)
    _text(Vector2(410, 520), "DENEME %d — AYNI ROTA AYNI SONUÇ DEĞİL." % a, 18, V11_MUTED)
    _route_hint(Vector2(840, 500), "A")
    _route_hint(Vector2(840, 390), "B")
    _platform(Vector2(950, 465), Vector2(240, 24), V11_BLUE)
    _platform(Vector2(1250, 435), Vector2(210, 24), V11_BLUE)
    var upper_memory := _spikes(Vector2(1390, 432), 2, true)
    var lower_memory := _spikes(Vector2(1390, 612), 3, true)
    _trigger(Rect2(740, 315, 230, 175), func():
        if _choose_route("upper"):
            var tw := create_tween()
            tw.tween_interval(0.38)
            if a % 2 == 0:
                tw.tween_callback(func(): _reveal(upper_memory))
            else:
                tw.tween_callback(func(): _reveal(lower_memory))
    )
    _trigger(Rect2(740, 500, 230, 150), func():
        if _choose_route("lower"):
            var tw := create_tween()
            tw.tween_interval(0.38)
            if a % 2 == 0:
                tw.tween_callback(func(): _reveal(lower_memory))
            else:
                tw.tween_callback(func(): _reveal(upper_memory))
    )
    _moving_platform(Vector2(1790, 555), Vector2(150, 24), Vector2(1830, 470), 1.40, V11_CYAN)
    var crush := _hazard_block(Vector2(2410, 230), Vector2(170, 70), V11_RED_DARK)
    _trigger(Rect2(2150, 390, 120, 240), func():
        if _once("93_crush"):
            var tw := create_tween()
            tw.tween_interval(0.34 if a % 3 == 0 else 0.52)
            tw.tween_property(crush, "position:y", 525.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_interval(0.18)
            tw.tween_property(crush, "position:y", 230.0, 0.50).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )
    _decor_block(Vector2(3010, 345), Vector2(90, 205))
    _trigger(Rect2(2860, 390, 120, 240), func():
        if _once("93_alarm"):
            _false_alarm()
    )
    _moving_platform(Vector2(3730, 555), Vector2(145, 24), Vector2(3770, 470), 1.28, V11_BLUE)
    _trigger(Rect2(4110, 390, 120, 240), func():
        if _once("93_reverse") and a % 2 == 1:
            controls_reversed = true
            _troll_popup("ROTA DEĞİŞTİ")
            var tw := create_tween()
            tw.tween_interval(0.82)
            tw.tween_callback(func(): controls_reversed = false)
    )
    var memory_gate := _hidden_hazard(Vector2(4720, 530), Vector2(28, 230), V11_RED)
    _trigger(Rect2(4440, 390, 120, 240), func():
        if _once("93_gate"):
            var tw := create_tween()
            tw.tween_interval(0.28 + float(a % 3) * 0.12)
            tw.tween_callback(func(): _reveal(memory_gate))
            tw.tween_interval(0.38)
            tw.tween_callback(func(): _hide(memory_gate))
    )
    _moving_platform(Vector2(5390, 555), Vector2(145, 24), Vector2(5430, 470), 1.32, V11_CYAN)
    _trigger(Rect2(5700, 390, 120, 240), func():
        if _once("93_final_rock"):
            var tw := create_tween()
            tw.tween_interval(0.35)
            tw.tween_callback(func(): _boulder(Vector2(6260, 560), -390.0, 72.0))
    )
    var goal := _finish(Vector2(6240, 580))
    _trigger(Rect2(6020, 390, 120, 240), func():
        if _once("93_goal") and a % 3 == 1:
            create_tween().tween_property(goal, "position:x", 6370.0, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )
