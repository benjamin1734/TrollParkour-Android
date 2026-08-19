extends "res://scripts/game.gd"

const C_INK := Color("#111827")
const C_RED := Color("#ef4444")
const C_RED_DARK := Color("#7f1d1d")
const C_GREEN := Color("#22c55e")
const C_YELLOW := Color("#f59e0b")
const C_BLUE := Color("#3b82f6")
const C_PURPLE := Color("#8b5cf6")
const C_MUTED := Color("#9ca3af")

func _build_level(c: int, p: int) -> void:
    if c == 2 and p == 1:
        _level_2_1()
    elif c == 2 and p == 2:
        _level_2_2()
    elif c == 2 and p == 3:
        _level_2_3()
    else:
        super._build_level(c, p)

func _level_2_1() -> void:
    _base_floor(3650)
    _text(Vector2(120,470), "BÖLÜM 2: ARTIK OYUN DA HİLE YAPIYOR.", 24, C_MUTED)

    _text(Vector2(520,525), "GÜVENLİ", 20, C_GREEN)
    var fake_safe := _platform(Vector2(600,610), Vector2(250,30), C_GREEN)
    var hidden_safe := _spikes(Vector2(600,612), 5, true)
    _trigger(Rect2(430,410,140,230), func():
        if _once("21_safe"):
            create_tween().tween_property(fake_safe, "position:y", 790.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            _reveal(hidden_safe)
    )

    _platform(Vector2(1040,535), Vector2(190,26), C_BLUE)
    var ceiling := _hazard_block(Vector2(1320,205), Vector2(260,70), C_RED_DARK)
    _trigger(Rect2(1120,390,130,230), func():
        if _once("21_crush"):
            var tw := create_tween()
            tw.tween_interval(0.18)
            tw.tween_property(ceiling, "position:y", 535.0, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_interval(0.15)
            tw.tween_property(ceiling, "position:y", 205.0, 0.52).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

    _marker(Vector2(1710,555), C_YELLOW, "?")
    _trigger(Rect2(1580,400,120,230), func():
        if _once("21_double_rock"):
            _boulder(Vector2(2250,560), -470.0, 72.0)
            var tw := create_tween()
            tw.tween_interval(0.55)
            tw.tween_callback(func(): _boulder(Vector2(2380,560), -520.0, 58.0))
    )

    var bridge: Array[StaticBody2D] = []
    for i in range(5):
        bridge.append(_platform(Vector2(2200 + i * 150, 565), Vector2(125,24), C_PURPLE))
    _trigger(Rect2(2030,390,130,230), func():
        if _once("21_bridge"):
            for i in range(bridge.size()):
                var tw := create_tween()
                tw.tween_interval(0.18 + float(i) * 0.13)
                tw.tween_property(bridge[i], "position:y", 850.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    )

    _spikes(Vector2(3060,612), 4, false)
    var goal := _finish(Vector2(3410,580))
    _trigger(Rect2(3160,410,120,230), func():
        if _once("21_goal_bait"):
            create_tween().tween_property(goal, "position:x", 3540.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

func _level_2_2() -> void:
    _base_floor(4000)
    _text(Vector2(120,470), "HIZLI OLMAK BAZEN DAHA KÖTÜDÜR.", 24, C_MUTED)

    var pop1 := _spikes(Vector2(720,612), 3, true)
    var pop2 := _spikes(Vector2(1030,612), 3, true)
    _trigger(Rect2(510,410,120,230), func():
        if _once("22_chain"):
            _reveal(pop1)
            var tw := create_tween()
            tw.tween_interval(0.48)
            tw.tween_callback(func(): _hide(pop1))
            tw.tween_callback(func(): _reveal(pop2))
    )

    var elevator := _platform(Vector2(1450,590), Vector2(210,28), C_BLUE)
    _spikes(Vector2(1450,335), 4, false, true)
    _trigger(Rect2(1280,420,150,220), func():
        if _once("22_elevator"):
            var tw := create_tween()
            tw.tween_property(elevator, "position:y", 410.0, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
            tw.tween_interval(0.25)
            tw.tween_property(elevator, "position:y", 650.0, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    )

    _marker(Vector2(2050,555), C_GREEN, "FINISH")
    var fake_finish_spikes := _spikes(Vector2(2050,612), 5, true)
    _trigger(Rect2(1870,410,120,230), func():
        if _once("22_fake_finish"):
            _reveal(fake_finish_spikes)
            _play_tone(145.0, 0.18, 0.24)
    )

    var gate_left := _hazard_block(Vector2(2540,390), Vector2(55,360), C_RED_DARK)
    var gate_right := _hazard_block(Vector2(2840,390), Vector2(55,360), C_RED_DARK)
    _trigger(Rect2(2320,410,130,230), func():
        if _once("22_gates"):
            var a := create_tween()
            a.tween_property(gate_left, "position:x", 2660.0, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            a.tween_interval(0.18)
            a.tween_property(gate_left, "position:x", 2540.0, 0.42)
            var b := create_tween()
            b.tween_property(gate_right, "position:x", 2720.0, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            b.tween_interval(0.18)
            b.tween_property(gate_right, "position:x", 2840.0, 0.42)
    )

    _trigger(Rect2(3130,400,120,230), func():
        if _once("22_back_rock"):
            _boulder(Vector2(3020,560), 560.0, 70.0)
    )
    _finish(Vector2(3760,580))

func _level_2_3() -> void:
    _base_floor(4550)
    _text(Vector2(120,470), "SON TEST: DURMA. AMA ÇOK DA KOŞMA.", 24, C_MUTED)

    var chase_wall := _hazard_block(Vector2(260,500), Vector2(90,300), C_RED_DARK)
    _trigger(Rect2(380,390,120,250), func():
        if _once("23_chase"):
            var tw := create_tween()
            tw.tween_property(chase_wall, "position:x", 3120.0, 7.0).set_trans(Tween.TRANS_LINEAR)
    )

    var floor_trap1 := _spikes(Vector2(900,612), 3, true)
    var floor_trap2 := _spikes(Vector2(1260,612), 3, true)
    _trigger(Rect2(720,410,120,230), func():
        if _once("23_floor"):
            _reveal(floor_trap1)
            var tw := create_tween()
            tw.tween_interval(0.42)
            tw.tween_callback(func(): _reveal(floor_trap2))
    )

    var moving := _platform(Vector2(1710,540), Vector2(210,26), C_BLUE)
    _trigger(Rect2(1530,390,120,230), func():
        if _once("23_move"):
            var tw := create_tween()
            tw.tween_property(moving, "position:x", 2050.0, 0.70).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
            tw.tween_property(moving, "position:y", 420.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    )

    _spikes(Vector2(2360,612), 5, false)
    _platform(Vector2(2360,485), Vector2(340,24), C_INK)
    var ceiling_spikes := _spikes(Vector2(2360,355), 6, true, true)
    _trigger(Rect2(2150,350,130,280), func():
        if _once("23_ceiling"):
            _reveal(ceiling_spikes)
    )

    _marker(Vector2(3040,555), C_GREEN, "BİTTİ")
    _trigger(Rect2(2870,400,120,230), func():
        if _once("23_not_done"):
            _boulder(Vector2(3500,555), -590.0, 86.0)
            _play_tone(120.0, 0.28, 0.30)
    )

    var final_bridge: Array[StaticBody2D] = []
    for i in range(6):
        final_bridge.append(_platform(Vector2(3380 + i * 145, 560), Vector2(118,24), C_PURPLE))
    _trigger(Rect2(3240,390,120,230), func():
        if _once("23_final_bridge"):
            for i in range(final_bridge.size()):
                if i % 2 == 0:
                    var tw := create_tween()
                    tw.tween_interval(0.22 + float(i) * 0.09)
                    tw.tween_property(final_bridge[i], "position:y", 840.0, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    )

    var last_spikes := _spikes(Vector2(4240,612), 4, true)
    _trigger(Rect2(4050,400,110,230), func():
        if _once("23_last"):
            _reveal(last_spikes)
            var tw := create_tween()
            tw.tween_interval(0.35)
            tw.tween_callback(func(): _hide(last_spikes))
    )
    _finish(Vector2(4380,580))

func _hazard_block(pos: Vector2, size: Vector2, color: Color) -> Area2D:
    var area := Area2D.new()
    area.position = pos
    area.collision_layer = 2
    area.collision_mask = 1
    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = size
    cs.shape = shape
    area.add_child(cs)
    var poly := Polygon2D.new()
    poly.polygon = PackedVector2Array([
        Vector2(-size.x / 2.0, -size.y / 2.0),
        Vector2(size.x / 2.0, -size.y / 2.0),
        Vector2(size.x / 2.0, size.y / 2.0),
        Vector2(-size.x / 2.0, size.y / 2.0)
    ])
    poly.color = color
    area.add_child(poly)
    area.body_entered.connect(func(body):
        if body == player and player.alive:
            player.die()
    )
    world.add_child(area)
    return area

func _finish_level() -> void:
    if level_finished or restarting:
        return
    level_finished = true
    player.input_enabled = false
    _play_tone(880.0, 0.20, 0.20)
    var banner := Label.new()
    banner.position = Vector2(390,250)
    banner.size = Vector2(500,120)
    banner.text = "KISIM TAMAMLANDI!"
    banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    banner.add_theme_font_size_override("font_size", 42)
    banner.add_theme_color_override("font_color", C_GREEN)
    hud.add_child(banner)
    await get_tree().create_timer(0.9).timeout

    if part < 3:
        _start_level(chapter, part + 1)
        return

    unlocked_chapter = maxi(unlocked_chapter, chapter + 1)
    _save()
    if chapter == 1:
        _start_level(2, 1)
    else:
        _chapter_complete()

func _chapter_complete() -> void:
    if is_instance_valid(world):
        world.queue_free()
    var overlay := ColorRect.new()
    overlay.size = Vector2(1280,720)
    overlay.color = C_INK
    hud.add_child(overlay)

    var label := Label.new()
    label.position = Vector2(190,130)
    label.size = Vector2(900,330)
    label.text = "BÖLÜM 2 TAMAMLANDI\n\nTOPLAM ÖLÜM: %d\n\n6 HARİTA TAMAMLANDI\n\nDEVAMI SONRAKİ GELİŞTİRME TURUNDA" % deaths
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 32)
    label.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(label)

    var replay := Button.new()
    replay.position = Vector2(490,500)
    replay.size = Vector2(300,70)
    replay.text = "BAŞTAN OYNA"
    replay.add_theme_font_size_override("font_size", 22)
    replay.pressed.connect(func(): _start_level(1,1))
    hud.add_child(replay)
