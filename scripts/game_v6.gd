extends "res://scripts/game_v5.gd"

const V6_BG := Color("#edf3f0")
const V6_BG_CH6 := Color("#dff2ea")
const V6_INK := Color("#111827")
const V6_RED := Color("#ef4444")
const V6_RED_DARK := Color("#7f1d1d")
const V6_GREEN := Color("#16a34a")
const V6_YELLOW := Color("#f59e0b")
const V6_BLUE := Color("#2563eb")
const V6_CYAN := Color("#0891b2")
const V6_MUTED := Color("#64748b")

func _start_level(c: int, p: int) -> void:
    super._start_level(c, p)
    if c == 6:
        RenderingServer.set_default_clear_color(V6_BG_CH6)

func _build_level(c: int, p: int) -> void:
    if c == 6 and p == 1:
        _level_6_1()
    elif c == 6 and p == 2:
        _level_6_2()
    elif c == 6 and p == 3:
        _level_6_3()
    else:
        super._build_level(c, p)

func _build_hud() -> void:
    super._build_hud()
    if chapter == 6:
        var mode := Label.new()
        mode.position = Vector2(730, 19)
        mode.size = Vector2(250, 36)
        mode.text = "HAREKETLİ SİSTEMLER"
        mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        mode.add_theme_font_size_override("font_size", 16)
        mode.add_theme_color_override("font_color", V6_CYAN)
        hud.add_child(mode)

func _show_main_menu() -> void:
    RenderingServer.set_default_clear_color(V6_BG)
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
    bg.color = V6_BG
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(bg)

    var top_band := ColorRect.new()
    top_band.size = Vector2(1280, 92)
    top_band.color = V6_INK
    top_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(top_band)

    var version := Label.new()
    version.position = Vector2(24, 27)
    version.size = Vector2(250, 40)
    version.text = "ANDROID • v0.7"
    version.add_theme_font_size_override("font_size", 18)
    version.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(version)

    var title := Label.new()
    title.position = Vector2(180, 125)
    title.size = Vector2(920, 95)
    title.text = "TROLL PARKOUR"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 58)
    title.add_theme_color_override("font_color", V6_INK)
    hud.add_child(title)

    var subtitle := Label.new()
    subtitle.position = Vector2(220, 210)
    subtitle.size = Vector2(840, 55)
    subtitle.text = "Bölüm 6: Artık harita da yerinde durmuyor."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 23)
    subtitle.add_theme_color_override("font_color", V6_MUTED)
    hud.add_child(subtitle)

    var progress := Label.new()
    progress.position = Vector2(300, 280)
    progress.size = Vector2(680, 44)
    var available := maxi(1, mini(unlocked_chapter, 6))
    var completed_maps := maxi(0, (mini(unlocked_chapter, 7) - 1) * 3)
    progress.text = "AÇIK BÖLÜM: %d / 6     HARİTA: %d / 18     ÖLÜM: %d" % [available, completed_maps, deaths]
    progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    progress.add_theme_font_size_override("font_size", 19)
    progress.add_theme_color_override("font_color", V6_RED_DARK)
    hud.add_child(progress)

    _menu_button("DEVAM ET", Vector2(440, 355), Vector2(400, 72), func():
        _start_level(maxi(1, mini(unlocked_chapter, 6)), 1)
    )
    _menu_button("BÖLÜMLER", Vector2(440, 445), Vector2(400, 72), func():
        _show_chapter_select()
    )
    _menu_button("1. BÖLÜMDEN BAŞLA", Vector2(440, 535), Vector2(400, 72), func():
        _start_level(1, 1)
    )

    var warning := Label.new()
    warning.position = Vector2(250, 635)
    warning.size = Vector2(780, 40)
    warning.text = "İpucu: Kontroller tuhaf geldiyse parmakların değil, oyun suçlu."
    warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    warning.add_theme_font_size_override("font_size", 18)
    warning.add_theme_color_override("font_color", V6_MUTED)
    hud.add_child(warning)

func _show_chapter_select() -> void:
    if is_instance_valid(hud):
        hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)

    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V6_BG
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(240, 45)
    title.size = Vector2(800, 72)
    title.text = "BÖLÜM SEÇ"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 44)
    title.add_theme_color_override("font_color", V6_INK)
    hud.add_child(title)

    var info := Label.new()
    info.position = Vector2(190, 112)
    info.size = Vector2(900, 42)
    info.text = "6 bölüm • 18 harita • Hafıza + hareketli sistemler"
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.add_theme_font_size_override("font_size", 19)
    info.add_theme_color_override("font_color", V6_MUTED)
    hud.add_child(info)

    for i in range(1, 7):
        var chapter_id := i
        var is_unlocked := chapter_id <= unlocked_chapter
        var col := (i - 1) % 3
        var row := int((i - 1) / 3)
        var pos := Vector2(125 + col * 350, 195 + row * 125)
        var suffix := "3 HARİTA"
        if chapter_id == 5:
            suffix = "HAFIZA • 3 HARİTA"
        elif chapter_id == 6:
            suffix = "HAREKET • 3 HARİTA"
        var button_text := "BÖLÜM %d\n%s" % [chapter_id, suffix] if is_unlocked else "BÖLÜM %d\nKİLİTLİ" % chapter_id
        var button := _menu_button(button_text, pos, Vector2(330, 92), func():
            _start_level(chapter_id, 1)
        )
        button.disabled = not is_unlocked

    _menu_button("GERİ", Vector2(490, 505), Vector2(300, 66), func():
        _show_main_menu()
    )

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
    bg.color = V6_INK
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(190, 105)
    title.size = Vector2(900, 290)
    var map_count := mini(chapter * 3, 18)
    title.text = "BÖLÜM %d TAMAMLANDI\n\nTOPLAM ÖLÜM: %d\nTAMAMLANAN HARİTA: %d / 18" % [chapter, deaths, map_count]
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(title)

    if chapter < 6:
        var next_chapter := chapter + 1
        _menu_button("SONRAKİ BÖLÜM", Vector2(440, 430), Vector2(400, 72), func():
            _start_level(next_chapter, 1)
        )
    else:
        var done := Label.new()
        done.position = Vector2(250, 400)
        done.size = Vector2(780, 82)
        done.text = "18 HARİTA TAMAM\nŞİMDİ HARİTA DA SANA KARŞI HAREKET EDİYOR."
        done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        done.add_theme_font_size_override("font_size", 22)
        done.add_theme_color_override("font_color", V6_YELLOW)
        hud.add_child(done)

    _menu_button("ANA MENÜ", Vector2(490, 545), Vector2(300, 68), func():
        _show_main_menu()
    )

func _moving_platform(pos: Vector2, size: Vector2, target: Vector2, travel_time: float, color: Color = V6_BLUE) -> AnimatableBody2D:
    var body := AnimatableBody2D.new()
    body.position = pos
    body.collision_layer = 1
    body.collision_mask = 1

    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = size
    cs.shape = shape
    body.add_child(cs)

    var poly := Polygon2D.new()
    poly.polygon = PackedVector2Array([
        Vector2(-size.x / 2.0, -size.y / 2.0),
        Vector2(size.x / 2.0, -size.y / 2.0),
        Vector2(size.x / 2.0, size.y / 2.0),
        Vector2(-size.x / 2.0, size.y / 2.0)
    ])
    poly.color = color
    body.add_child(poly)
    world.add_child(body)

    var tw := create_tween().set_loops()
    tw.tween_property(body, "position", target, travel_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tw.tween_property(body, "position", pos, travel_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    return body

func _reverse_controls(seconds: float) -> void:
    if not is_instance_valid(player) or not player.alive:
        return
    player.controls_reversed = true
    _troll_popup("SOL SAĞ OLDU • SAĞ SOL", V6_CYAN)
    _play_tone(330.0, 0.12, 0.18)
    Input.vibrate_handheld(35)
    await get_tree().create_timer(seconds).timeout
    if is_instance_valid(player) and player.alive:
        player.controls_reversed = false
        _troll_popup("KONTROLLER DÜZELDİ", V6_GREEN)

func _camera_trick(amount: float = 0.065) -> void:
    if not is_instance_valid(camera):
        return
    var tw := create_tween()
    tw.tween_property(camera, "rotation", amount, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tw.parallel().tween_property(camera, "offset", Vector2(24, -10), 0.14)
    tw.tween_interval(0.34)
    tw.tween_property(camera, "rotation", -amount * 0.55, 0.16)
    tw.parallel().tween_property(camera, "offset", Vector2(-14, 6), 0.16)
    tw.tween_interval(0.20)
    tw.tween_property(camera, "rotation", 0.0, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tw.parallel().tween_property(camera, "offset", Vector2.ZERO, 0.20)

func _level_6_1() -> void:
    _floor_with_gaps(5200, [Vector2(1280, 1700), Vector2(3140, 3310)])
    _text(Vector2(120, 470), "BÖLÜM 6: YERİNDE DURAN ŞEYLERE ALIŞMIŞTIN.", 23, V6_CYAN)
    _text(Vector2(430, 520), "ARTIK O ALIŞKANLIK DA YOK.", 19, V6_MUTED)

    _moving_platform(Vector2(1390, 560), Vector2(180, 24), Vector2(1580, 500), 1.25, V6_BLUE)
    _moving_platform(Vector2(1610, 485), Vector2(150, 24), Vector2(1390, 430), 1.05, V6_CYAN)

    var s1 := _spikes(Vector2(2120, 612), 3, true)
    _trigger(Rect2(1880, 390, 130, 240), func():
        if _once("61_reverse"):
            _reverse_controls(1.55)
            var tw := create_tween()
            tw.tween_interval(0.48)
            tw.tween_callback(func(): _reveal(s1))
    )

    var crusher := _hazard_block(Vector2(2640, 130), Vector2(120, 210), V6_RED_DARK)
    _trigger(Rect2(2380, 390, 130, 240), func():
        if _once("61_crusher"):
            var tw := create_tween()
            tw.tween_interval(0.18)
            tw.tween_property(crusher, "position:y", 480.0, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_interval(0.28)
            tw.tween_property(crusher, "position:y", 130.0, 0.48).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

    _trigger(Rect2(3450, 390, 120, 240), func():
        if _once("61_camera"):
            _camera_trick()
    )
    _spikes(Vector2(3740, 612), 3, false)

    _trigger(Rect2(4050, 390, 120, 240), func():
        if _once("61_rock"):
            _boulder(Vector2(4620, 560), -500.0, 74.0)
    )

    var goal := _finish(Vector2(4920, 580))
    _trigger(Rect2(4680, 390, 120, 240), func():
        if _once("61_goal"):
            create_tween().tween_property(goal, "position:y", 470.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

func _level_6_2() -> void:
    _floor_with_gaps(5700, [Vector2(950, 1160), Vector2(2240, 2670), Vector2(4020, 4180)])
    _text(Vector2(120, 470), "HAREKET EDEN PLATFORM GÜVENLİ DEMEK DEĞİL.", 23, V6_CYAN)

    _moving_platform(Vector2(1030, 545), Vector2(150, 24), Vector2(1100, 430), 0.90, V6_GREEN)

    var slide := _spikes(Vector2(1550, 612), 3, false)
    _trigger(Rect2(1290, 390, 120, 240), func():
        if _once("62_slide"):
            create_tween().tween_property(slide, "position:x", 1340.0, 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    )

    _moving_platform(Vector2(2330, 560), Vector2(170, 24), Vector2(2520, 475), 1.05, V6_BLUE)
    _moving_platform(Vector2(2580, 470), Vector2(145, 24), Vector2(2380, 400), 1.10, V6_CYAN)

    var left := _hazard_block(Vector2(3100, 430), Vector2(60, 280), V6_RED_DARK)
    var right := _hazard_block(Vector2(3480, 430), Vector2(60, 280), V6_RED_DARK)
    _trigger(Rect2(2860, 390, 120, 240), func():
        if _once("62_crush"):
            var a := create_tween()
            a.tween_property(left, "position:x", 3250.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            a.tween_interval(0.20)
            a.tween_property(left, "position:x", 3100.0, 0.46)
            var b := create_tween()
            b.tween_property(right, "position:x", 3330.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            b.tween_interval(0.20)
            b.tween_property(right, "position:x", 3480.0, 0.46)
    )

    _trigger(Rect2(3650, 390, 120, 240), func():
        if _once("62_reverse"):
            _reverse_controls(1.30)
            _camera_trick(0.045)
    )

    var hidden := _spikes(Vector2(4480, 612), 3, true)
    _trigger(Rect2(4250, 390, 120, 240), func():
        if _once("62_hidden"):
            var tw := create_tween()
            tw.tween_interval(0.20)
            tw.tween_callback(func(): _reveal(hidden))
            tw.tween_interval(0.55)
            tw.tween_callback(func(): _hide(hidden))
    )

    _trigger(Rect2(4780, 390, 120, 240), func():
        if _once("62_rocks"):
            _falling_boulder(Vector2(5000, 0), 64.0, 0.0)
            _falling_boulder(Vector2(5240, -20), 56.0, 0.34)
    )

    _finish(Vector2(5450, 580))

func _level_6_3() -> void:
    _floor_with_gaps(6400, [Vector2(1660, 1810), Vector2(2780, 3230), Vector2(4850, 5020)])
    _text(Vector2(120, 470), "SON KISIM: HARİTA SENİNLE AYNI ANDA KARAR DEĞİŞTİRİR.", 22, V6_CYAN)

    var chase := _hazard_block(Vector2(260, 500), Vector2(88, 300), V6_RED_DARK)
    _trigger(Rect2(430, 390, 120, 240), func():
        if _once("63_chase"):
            create_tween().tween_property(chase, "position:x", 3900.0, 9.0).set_trans(Tween.TRANS_LINEAR)
    )

    _trigger(Rect2(900, 390, 120, 240), func():
        if _once("63_reverse"):
            _reverse_controls(1.45)
    )
    _spikes(Vector2(1320, 612), 2, false)

    _moving_platform(Vector2(2880, 560), Vector2(155, 24), Vector2(3070, 475), 0.95, V6_BLUE)
    _moving_platform(Vector2(3150, 465), Vector2(150, 24), Vector2(2920, 385), 1.10, V6_CYAN)

    _trigger(Rect2(3430, 390, 120, 240), func():
        if _once("63_camera"):
            _camera_trick(0.075)
            _falling_boulder(Vector2(3710, -10), 62.0, 0.28)
    )

    var fake_safe := _platform(Vector2(4240, 575), Vector2(220, 28), V6_GREEN)
    _text(Vector2(4160, 510), "SAFE", 20, V6_GREEN)
    _trigger(Rect2(3970, 390, 120, 240), func():
        if _once("63_safe"):
            var tw := create_tween()
            tw.tween_interval(0.14)
            tw.tween_property(fake_safe, "position:y", 835.0, 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    )

    var final_spikes := _spikes(Vector2(5300, 612), 3, true)
    _trigger(Rect2(5100, 390, 120, 240), func():
        if _once("63_final"):
            _reveal(final_spikes)
            _reverse_controls(1.10)
            var tw := create_tween()
            tw.tween_interval(0.48)
            tw.tween_callback(func(): _hide(final_spikes))
    )

    _trigger(Rect2(5550, 390, 120, 240), func():
        if _once("63_last_rock"):
            _boulder(Vector2(6100, 560), -520.0, 78.0)
    )

    var goal := _finish(Vector2(6150, 580))
    _trigger(Rect2(5900, 390, 120, 240), func():
        if _once("63_goal"):
            var tw := create_tween()
            tw.tween_property(goal, "position:x", 6260.0, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
            tw.tween_interval(0.40)
            tw.tween_property(goal, "position:x", 6150.0, 0.30)
    )
