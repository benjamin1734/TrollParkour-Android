extends "res://scripts/game_v25.gd"

func _v25_level_21_1() -> void:
    _floor_with_gaps(6200, [Vector2(2190, 2350), Vector2(3840, 4000)])
    _text(Vector2(120, 470), "BÖLÜM 21: KARANLIK.", 25, V25_CYAN)
    _text(Vector2(410, 520), "IŞIK BAZEN YOL GÖSTERİR. BAZEN SADECE BAKMANI İSTER.", 17, V25_MUTED)
    _v25_light_beacon(Vector2(760, 480), V25_CYAN, "IŞIK")

    var first := _spikes(Vector2(1120, 612), 3, true)
    _trigger(Rect2(860, 390, 130, 240), func():
        if _once("211_light_trap"):
            _v25_pulse_notice("GÖRDÜN")
            var tw := create_tween()
            tw.tween_interval(0.34)
            tw.tween_callback(func(): _reveal(first))
            tw.tween_interval(0.52)
            tw.tween_callback(func(): _hide(first))
    )

    _v25_light_beacon(Vector2(1620, 485), V25_GREEN, "GÜVENLİ?")
    var harmless := _platform(Vector2(1660, 550), Vector2(210, 26), V25_GREEN)
    _trigger(Rect2(1430, 390, 130, 240), func():
        if _once("211_false_light"):
            _false_alarm()
            create_tween().tween_property(harmless, "position:y", 547.0, 0.14)
    )

    _moving_platform(Vector2(2270, 555), Vector2(145, 24), Vector2(2310, 470), 1.38, V25_BLUE)

    var blackout_spikes := _spikes(Vector2(2850, 612), 3, true)
    _trigger(Rect2(2530, 390, 130, 240), func():
        if _once("211_blackout"):
            _v25_blackout(0.36, 0.76)
            var tw := create_tween()
            tw.tween_interval(0.46)
            tw.tween_callback(func(): _reveal(blackout_spikes))
            tw.tween_interval(0.54)
            tw.tween_callback(func(): _hide(blackout_spikes))
    )

    var gate := _hazard_block(Vector2(3450, 210), Vector2(120, 70), V25_RED)
    _trigger(Rect2(3170, 390, 130, 240), func():
        if _once("211_gate"):
            var tw := create_tween()
            tw.tween_property(gate, "position:y", 510.0, 0.44).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_interval(0.34)
            tw.tween_property(gate, "position:y", 210.0, 0.50).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

    _moving_platform(Vector2(3920, 555), Vector2(145, 24), Vector2(3960, 475), 1.40, V25_CYAN)
    _v25_light_beacon(Vector2(4550, 490), V25_AMBER, "BEKLEME")
    _trigger(Rect2(4320, 390, 280, 240), func():
        _wait_check(4480.0, 170.0, 1.05, func():
            _v25_blackout(0.28, 0.68)
            _v25_pulse_notice("FAZLA BEKLEDİN", V25_AMBER)
            _boulder(Vector2(5100, 560), -360.0, 66.0)
        , "211_wait")
    )

    var final_spikes := _spikes(Vector2(5480, 612), 2, true)
    _trigger(Rect2(5220, 390, 120, 240), func():
        if _once("211_final"):
            var tw := create_tween()
            tw.tween_interval(0.32)
            tw.tween_callback(func(): _reveal(final_spikes))
            tw.tween_interval(0.50)
            tw.tween_callback(func(): _hide(final_spikes))
    )
    _finish(Vector2(5950, 580))

func _v25_level_21_3() -> void:
    _floor_with_gaps(7500, [Vector2(1700, 1860), Vector2(3960, 4120), Vector2(6020, 6180)])
    var attempt: int = _attempt(21, 3)
    _text(Vector2(120, 470), "KARANLIK DA SENİ HATIRLIYOR.", 24, V25_PURPLE)
    _text(Vector2(420, 520), "DENEME %d" % attempt, 17, V25_MUTED)

    var first_a := _spikes(Vector2(900, 612), 3, true)
    var first_b := _spikes(Vector2(1250, 612), 3, true)
    _trigger(Rect2(650, 390, 130, 240), func():
        if _once("213_first"):
            _v25_blackout(0.26, 0.66)
            var target: Area2D = first_a if attempt % 2 == 1 else first_b
            var tw := create_tween()
            tw.tween_interval(0.36)
            tw.tween_callback(func(): _reveal(target))
            tw.tween_interval(0.54)
            tw.tween_callback(func(): _hide(target))
    )

    _moving_platform(Vector2(1780, 555), Vector2(145, 24), Vector2(1820, 470), 1.42, V25_CYAN)

    var gate := _hazard_block(Vector2(2450, 210), Vector2(125, 70), V25_RED)
    _trigger(Rect2(2140, 390, 130, 240), func():
        if _once("213_gate"):
            var delay := 0.30 + float(attempt % 3) * 0.06
            var tw := create_tween()
            tw.tween_interval(delay)
            tw.tween_property(gate, "position:y", 510.0, 0.44).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_interval(0.38)
            tw.tween_property(gate, "position:y", 210.0, 0.52).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

    _v25_light_beacon(Vector2(3100, 490), V25_GREEN if attempt % 3 != 0 else V25_RED, "SİNYAL")
    var signal_spikes := _spikes(Vector2(3320, 612), 3, true)
    _trigger(Rect2(2860, 390, 130, 240), func():
        if _once("213_signal"):
            if attempt % 3 == 0:
                _false_alarm()
            else:
                var tw := create_tween()
                tw.tween_interval(0.32)
                tw.tween_callback(func(): _reveal(signal_spikes))
                tw.tween_interval(0.52)
                tw.tween_callback(func(): _hide(signal_spikes))
    )

    _moving_platform(Vector2(4040, 555), Vector2(145, 24), Vector2(4080, 472), 1.40, V25_BLUE)

    _route_hint(Vector2(4660, 490), "SOLUK")
    _route_hint(Vector2(4660, 385), "PARLAK")
    _platform(Vector2(4750, 455), Vector2(240, 24), V25_PLATFORM_ALT)
    _trigger(Rect2(4420, 305, 260, 185), func():
        if _choose_route("bright"):
            _v25_pulse_notice("PARLAK")
    )
    _trigger(Rect2(4420, 490, 260, 150), func():
        if _choose_route("dim"):
            _v25_pulse_notice("SOLUK")
    )

    var route_spikes := _spikes(Vector2(5190, 612), 3, true)
    _trigger(Rect2(4940, 390, 120, 240), func():
        if _once("213_route"):
            var route_bad := (attempt % 2 == 0 and route_choice == "bright") or (attempt % 2 == 1 and route_choice == "dim")
            if route_bad:
                var tw := create_tween()
                tw.tween_interval(0.36)
                tw.tween_callback(func(): _reveal(route_spikes))
                tw.tween_interval(0.52)
                tw.tween_callback(func(): _hide(route_spikes))
            else:
                _false_alarm()
    )

    _moving_platform(Vector2(6100, 555), Vector2(145, 24), Vector2(6140, 470), 1.40, V25_CYAN)

    _trigger(Rect2(6430, 390, 120, 240), func():
        if _once("213_blackout_rock"):
            _v25_blackout(0.30, 0.72)
            var tw := create_tween()
            tw.tween_interval(0.48)
            tw.tween_callback(func(): _boulder(Vector2(7050, 560), -345.0, 66.0))
    )

    var last := _spikes(Vector2(6900, 612), 2, true)
    _trigger(Rect2(6680, 390, 120, 240), func():
        if _once("213_last"):
            var tw := create_tween()
            tw.tween_interval(0.34)
            tw.tween_callback(func(): _reveal(last))
            tw.tween_interval(0.52)
            tw.tween_callback(func(): _hide(last))
    )
    _finish(Vector2(7240, 580))
