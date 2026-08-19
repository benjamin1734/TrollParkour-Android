extends "res://scripts/game_balance.gd"

const V3_BG := Color("#f3f4f6")
const V3_BG_CH3 := Color("#e9eef8")
const V3_INK := Color("#111827")
const V3_RED := Color("#ef4444")
const V3_RED_DARK := Color("#7f1d1d")
const V3_GREEN := Color("#22c55e")
const V3_YELLOW := Color("#f59e0b")
const V3_BLUE := Color("#3b82f6")
const V3_PURPLE := Color("#8b5cf6")
const V3_MUTED := Color("#6b7280")

func _ready() -> void:
    RenderingServer.set_default_clear_color(V3_BG)
    _load_save()
    _start_music()
    _show_main_menu()

func _start_level(c: int, p: int) -> void:
    RenderingServer.set_default_clear_color(V3_BG_CH3 if c == 3 else V3_BG)
    super._start_level(c, p)

func _build_level(c: int, p: int) -> void:
    if c == 3 and p == 1:
        _level_3_1()
    elif c == 3 and p == 2:
        _level_3_2()
    elif c == 3 and p == 3:
        _level_3_3()
    else:
        super._build_level(c, p)

func _show_main_menu() -> void:
    RenderingServer.set_default_clear_color(V3_BG)
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
    bg.color = V3_BG
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(bg)

    var top_band := ColorRect.new()
    top_band.position = Vector2(0, 0)
    top_band.size = Vector2(1280, 92)
    top_band.color = V3_INK
    top_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(top_band)

    var title := Label.new()
    title.position = Vector2(180, 130)
    title.size = Vector2(920, 95)
    title.text = "TROLL PARKOUR"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 58)
    title.add_theme_color_override("font_color", V3_INK)
    hud.add_child(title)

    var subtitle := Label.new()
    subtitle.position = Vector2(220, 215)
    subtitle.size = Vector2(840, 55)
    subtitle.text = "Güvenli görünen hiçbir şey güvenli değil."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 24)
    subtitle.add_theme_color_override("font_color", V3_MUTED)
    hud.add_child(subtitle)

    var progress := Label.new()
    progress.position = Vector2(370, 280)
    progress.size = Vector2(540, 44)
    var available := maxi(1, mini(unlocked_chapter, 3))
    var completed_maps := maxi(0, (mini(unlocked_chapter, 4) - 1) * 3)
    progress.text = "AÇIK BÖLÜM: %d / 3     TAMAMLANAN HARİTA: %d / 9     ÖLÜM: %d" % [available, completed_maps, deaths]
    progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    progress.add_theme_font_size_override("font_size", 18)
    progress.add_theme_color_override("font_color", V3_RED_DARK)
    hud.add_child(progress)

    _menu_button("DEVAM ET", Vector2(440, 355), Vector2(400, 72), func():
        _start_level(maxi(1, mini(unlocked_chapter, 3)), 1)
    )
    _menu_button("BÖLÜMLER", Vector2(440, 445), Vector2(400, 72), func():
        _show_chapter_select()
    )
    _menu_button("1. BÖLÜMDEN BAŞLA", Vector2(440, 535), Vector2(400, 72), func():
        _start_level(1, 1)
    )

    var warning := Label.new()
    warning.position = Vector2(300, 635)
    warning.size = Vector2(680, 40)
    warning.text = "İpucu: Oyun sana bir şey söylüyorsa iki kere düşün."
    warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    warning.add_theme_font_size_override("font_size", 18)
    warning.add_theme_color_override("font_color", V3_MUTED)
    hud.add_child(warning)

func _show_chapter_select() -> void:
    if is_instance_valid(hud):
        hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)

    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V3_BG
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(240, 100)
    title.size = Vector2(800, 90)
    title.text = "BÖLÜM SEÇ"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 46)
    title.add_theme_color_override("font_color", V3_INK)
    hud.add_child(title)

    for i in range(1, 4):
        var chapter_id := i
        var is_unlocked := chapter_id <= unlocked_chapter
        var button_text := "BÖLÜM %d   •   3 HARİTA" % chapter_id if is_unlocked else "BÖLÜM %d   •   KİLİTLİ" % chapter_id
        var button := _menu_button(button_text, Vector2(390, 220 + (i - 1) * 105), Vector2(500, 78), func():
            _start_level(chapter_id, 1)
        )
        button.disabled = not is_unlocked

    _menu_button("GERİ", Vector2(490, 575), Vector2(300, 68), func():
        _show_main_menu()
    )

func _menu_button(text: String, pos: Vector2, size: Vector2, callback: Callable) -> Button:
    var button := Button.new()
    button.position = pos
    button.size = size
    button.text = text
    button.add_theme_font_size_override("font_size", 24)
    button.add_theme_color_override("font_color", V3_INK)
    button.pressed.connect(callback)
    hud.add_child(button)
    return button

func _build_hud() -> void:
    super._build_hud()
    var menu := Button.new()
    menu.position = Vector2(570, 11)
    menu.size = Vector2(140, 48)
    menu.text = "MENÜ"
    menu.add_theme_font_size_override("font_size", 18)
    menu.pressed.connect(func(): _show_main_menu())
    hud.add_child(menu)

func _level_3_1() -> void:
    _base_floor(4100)
    _text(Vector2(120, 470), "BÖLÜM 3: ZIPLAMAK HER ZAMAN ÇÖZÜM DEĞİL.", 24, V3_MUTED)

    _spikes(Vector2(610, 612), 2, false)

    _marker(Vector2(1040, 555), V3_GREEN, "ZIPLA")
    _spring_pad(Vector2(1040, 620), -980.0)
    _spikes(Vector2(1100, 270), 3, false, true)

    _trigger(Rect2(1320, 390, 120, 240), func():
        if _once("31_fall_rocks"):
            _falling_boulder(Vector2(1580, 70), 74.0, 0.0)
            _falling_boulder(Vector2(1810, 40), 62.0, 0.34)
    )

    var mover := _spikes(Vector2(2420, 612), 3, false)
    _trigger(Rect2(2020, 390, 130, 240), func():
        if _once("31_moving_spikes"):
            create_tween().tween_property(mover, "position:x", 2170.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    )

    var crusher := _hazard_block(Vector2(2980, 100), Vector2(100, 180), V3_RED_DARK)
    _trigger(Rect2(2700, 390, 130, 240), func():
        if _once("31_crusher"):
            var tw := create_tween()
            tw.tween_interval(0.12)
            tw.tween_property(crusher, "position:y", 500.0, 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_interval(0.22)
            tw.tween_property(crusher, "position:y", 100.0, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

    _spikes(Vector2(3330, 612), 3, false)
    var goal := _finish(Vector2(3760, 580))
    _trigger(Rect2(3480, 390, 130, 240), func():
        if _once("31_goal"):
            var tw := create_tween()
            tw.tween_property(goal, "position:y", 445.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
            tw.tween_interval(0.55)
            tw.tween_property(goal, "position:y", 580.0, 0.32)
    )

func _level_3_2() -> void:
    _base_floor(4500)
    _text(Vector2(120, 470), "HAREKET ETMEYEN TEK ŞEY SENİN SABRIN.", 24, V3_MUTED)

    var first := _spikes(Vector2(720, 612), 3, true)
    var second := _spikes(Vector2(1080, 612), 3, true)
    _trigger(Rect2(500, 390, 120, 240), func():
        if _once("32_chain"):
            _reveal(first)
            var tw := create_tween()
            tw.tween_interval(0.50)
            tw.tween_callback(func(): _hide(first))
            tw.tween_callback(func(): _reveal(second))
    )

    _text(Vector2(1430, 525), "SAFE", 22, V3_GREEN)
    _spring_pad(Vector2(1520, 620), -930.0, V3_GREEN)
    _spikes(Vector2(1580, 300), 3, false, true)

    var left_gate := _hazard_block(Vector2(2200, 430), Vector2(60, 280), V3_RED_DARK)
    var right_gate := _hazard_block(Vector2(2580, 430), Vector2(60, 280), V3_RED_DARK)
    _trigger(Rect2(1900, 390, 130, 240), func():
        if _once("32_gates"):
            var a := create_tween()
            a.tween_property(left_gate, "position:x", 2350.0, 0.44).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            a.tween_interval(0.20)
            a.tween_property(left_gate, "position:x", 2200.0, 0.45)
            var b := create_tween()
            b.tween_property(right_gate, "position:x", 2430.0, 0.44).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            b.tween_interval(0.20)
            b.tween_property(right_gate, "position:x", 2580.0, 0.45)
    )

    _trigger(Rect2(2820, 390, 120, 240), func():
        if _once("32_rain"):
            _falling_boulder(Vector2(3060, 20), 68.0, 0.0)
            _falling_boulder(Vector2(3320, -20), 54.0, 0.28)
    )

    var final_trap := _spikes(Vector2(3650, 612), 3, true)
    _trigger(Rect2(3450, 390, 120, 240), func():
        if _once("32_final"):
            _reveal(final_trap)
            var tw := create_tween()
            tw.tween_interval(0.42)
            tw.tween_callback(func(): _hide(final_trap))
    )

    _finish(Vector2(4210, 580))

func _level_3_3() -> void:
    _base_floor(5000)
    _text(Vector2(120, 470), "SON KISIM: PARANOYANI KULLAN.", 24, V3_MUTED)
    _text(Vector2(430, 520), "BURADA GERÇEKTEN HİÇBİR ŞEY YOK.", 20, V3_GREEN)

    var lonely := _spikes(Vector2(1050, 612), 2, true)
    _trigger(Rect2(850, 390, 120, 240), func():
        if _once("33_lonely"):
            _reveal(lonely)
    )

    var chase := _hazard_block(Vector2(430, 500), Vector2(90, 300), V3_RED_DARK)
    _trigger(Rect2(1250, 390, 120, 240), func():
        if _once("33_chase"):
            create_tween().tween_property(chase, "position:x", 3650.0, 8.2).set_trans(Tween.TRANS_LINEAR)
    )

    var slide_spikes := _spikes(Vector2(2050, 612), 3, false)
    _trigger(Rect2(1660, 390, 120, 240), func():
        if _once("33_slide"):
            create_tween().tween_property(slide_spikes, "position:x", 1810.0, 0.50).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    )

    _trigger(Rect2(2300, 390, 120, 240), func():
        if _once("33_rocks"):
            _falling_boulder(Vector2(2550, 20), 72.0, 0.0)
            _falling_boulder(Vector2(2840, 0), 64.0, 0.36)
            _falling_boulder(Vector2(3110, -30), 56.0, 0.70)
    )

    _marker(Vector2(3620, 555), V3_GREEN, "FINISH")
    var fake_finish := _spikes(Vector2(3620, 612), 3, true)
    _trigger(Rect2(3420, 390, 120, 240), func():
        if _once("33_fake"):
            _reveal(fake_finish)
            _play_tone(125.0, 0.22, 0.28)
    )

    var last := _spikes(Vector2(4250, 612), 3, true)
    _trigger(Rect2(4050, 390, 120, 240), func():
        if _once("33_last"):
            _reveal(last)
            var tw := create_tween()
            tw.tween_interval(0.32)
            tw.tween_callback(func(): _hide(last))
    )

    var goal := _finish(Vector2(4700, 580))
    _trigger(Rect2(4450, 390, 120, 240), func():
        if _once("33_goal"):
            create_tween().tween_property(goal, "position:x", 4830.0, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

func _spring_pad(pos: Vector2, launch_velocity: float, color: Color = V3_YELLOW) -> Area2D:
    var area := Area2D.new()
    area.position = pos
    area.collision_mask = 1
    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(105, 24)
    cs.shape = shape
    area.add_child(cs)

    var poly := Polygon2D.new()
    poly.polygon = PackedVector2Array([
        Vector2(-52, -12), Vector2(52, -12), Vector2(52, 12), Vector2(-52, 12)
    ])
    poly.color = color
    area.add_child(poly)

    area.body_entered.connect(func(body):
        if body == player and player.alive:
            player.velocity.y = launch_velocity
            _play_tone(760.0, 0.10, 0.18)
            Input.vibrate_handheld(35)
    )
    world.add_child(area)
    return area

func _falling_boulder(pos: Vector2, radius: float, delay: float) -> Area2D:
    var area := Area2D.new()
    area.position = pos
    area.collision_layer = 2
    area.collision_mask = 1
    var cs := CollisionShape2D.new()
    var shape := CircleShape2D.new()
    shape.radius = radius
    cs.shape = shape
    area.add_child(cs)

    var poly := Polygon2D.new()
    var points := PackedVector2Array()
    for i in range(22):
        var angle := TAU * float(i) / 22.0
        points.append(Vector2(cos(angle), sin(angle)) * radius)
    poly.polygon = points
    poly.color = V3_RED_DARK
    area.add_child(poly)

    area.body_entered.connect(func(body):
        if body == player and player.alive:
            player.die()
    )
    world.add_child(area)

    var tw := create_tween()
    tw.tween_interval(delay)
    tw.set_parallel(true)
    tw.tween_property(area, "position:y", 820.0, 0.72).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    tw.tween_property(poly, "rotation", TAU * 2.5, 0.72)
    tw.set_parallel(false)
    tw.tween_callback(area.queue_free)
    return area

func _on_player_died() -> void:
    if restarting or level_finished:
        return
    restarting = true
    deaths += 1
    _save()
    Input.vibrate_handheld(85)

    var death_label := hud.get_node_or_null("DeathLabel") as Label
    if death_label:
        death_label.text = "ÖLÜM: %d" % deaths

    _play_tone(105.0, 0.24, 0.32)

    var flash := ColorRect.new()
    flash.size = Vector2(1280, 720)
    flash.color = Color(1.0, 0.08, 0.08, 0.18)
    flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(flash)
    var flash_tween := create_tween()
    flash_tween.tween_property(flash, "color", Color(1.0, 0.08, 0.08, 0.0), 0.24)
    flash_tween.tween_callback(flash.queue_free)

    if is_instance_valid(camera):
        camera.offset = Vector2(12, -7)
        create_tween().tween_property(camera, "offset", Vector2.ZERO, 0.24).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

    var visual := player.get_node_or_null("Visual") as Polygon2D
    if visual:
        var death_tween := create_tween()
        death_tween.set_parallel(true)
        death_tween.tween_property(visual, "scale", Vector2(0.05, 0.05), 0.28)
        death_tween.tween_property(player, "rotation", PI * 1.5, 0.28)

    await get_tree().create_timer(0.42).timeout
    _start_level(chapter, part)

func _finish_level() -> void:
    if level_finished or restarting:
        return
    level_finished = true
    player.input_enabled = false
    Input.vibrate_handheld(40)
    _play_tone(880.0, 0.20, 0.20)

    var banner := Label.new()
    banner.position = Vector2(350, 230)
    banner.size = Vector2(580, 135)
    banner.text = "KISIM %d-%d TAMAMLANDI!" % [chapter, part]
    banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    banner.add_theme_font_size_override("font_size", 38)
    banner.add_theme_color_override("font_color", V3_GREEN)
    hud.add_child(banner)

    await get_tree().create_timer(0.85).timeout

    if part < 3:
        _start_level(chapter, part + 1)
        return

    unlocked_chapter = maxi(unlocked_chapter, chapter + 1)
    _save()
    _show_chapter_result()

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
    bg.color = V3_INK
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(190, 125)
    title.size = Vector2(900, 260)
    var map_count := chapter * 3
    title.text = "BÖLÜM %d TAMAMLANDI\n\nTOPLAM ÖLÜM: %d\nTAMAMLANAN HARİTA: %d / 9" % [chapter, deaths, map_count]
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(title)

    if chapter < 3:
        var next_chapter := chapter + 1
        _menu_button("SONRAKİ BÖLÜM", Vector2(440, 430), Vector2(400, 72), func():
            _start_level(next_chapter, 1)
        )
    else:
        var done := Label.new()
        done.position = Vector2(300, 405)
        done.size = Vector2(680, 70)
        done.text = "İLK 9 HARİTA TAMAM — DAHA KÖTÜSÜ GELİYOR."
        done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        done.add_theme_font_size_override("font_size", 23)
        done.add_theme_color_override("font_color", V3_YELLOW)
        hud.add_child(done)

    _menu_button("ANA MENÜ", Vector2(490, 540), Vector2(300, 68), func():
        _show_main_menu()
    )
