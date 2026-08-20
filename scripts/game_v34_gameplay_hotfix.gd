extends "res://scripts/game_v34_hotfix.gd"

const V34_MOVER_HORIZONTAL_PAD := 46.0
const V34_MOVER_VERTICAL_RANGE := 235.0
const V34_BOULDER_HEAD_ON_CAP := 282.0
const V34_BOULDER_CHASE_CAP := 238.0
const V34_BOULDER_CROSS_CAP := 258.0

func _build_level(c: int, p: int) -> void:
    if c == 2 and p == 1:
        _v34_level_2_1_minimal()
    elif c == 2 and p == 2:
        _v34_level_2_2_minimal()
    elif c == 2 and p == 3:
        _v34_level_2_3_minimal()
    else:
        super._build_level(c, p)

func _build_hud() -> void:
    super._build_hud()
    if not is_instance_valid(hud):
        return
    var jump_hint := Label.new()
    jump_hint.name = "V34DoubleJumpHint"
    jump_hint.position = Vector2(1045, 78)
    jump_hint.size = Vector2(190, 22)
    jump_hint.text = "ZIPLA ×2"
    jump_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    jump_hint.add_theme_font_size_override("font_size", 11)
    jump_hint.add_theme_color_override("font_color", Color(V34_CYAN, 0.72))
    jump_hint.z_index = 85
    hud.add_child(jump_hint)

func _v30_tick_pending_movers() -> void:
    if v30_pending_movers.is_empty() or not is_instance_valid(player) or not player.alive:
        return
    if player.global_position.x < V30_PLAYER_COMMIT_X and absf(player.velocity.x) < 40.0:
        return

    var player_pos := player.global_position
    for id in v30_pending_movers.keys():
        var state: Dictionary = v30_pending_movers[id]
        var raw_node = state.get("node")
        if raw_node == null or not is_instance_valid(raw_node):
            v30_pending_movers.erase(id)
            continue
        var body: AnimatableBody2D = raw_node as AnimatableBody2D
        if not is_instance_valid(body):
            v30_pending_movers.erase(id)
            continue

        var start: Vector2 = state.get("start", body.position)
        var target: Vector2 = state.get("target", body.position)
        var half_width := 70.0
        for child in body.get_children():
            if child is CollisionShape2D:
                var cs := child as CollisionShape2D
                if cs.shape is RectangleShape2D:
                    half_width = (cs.shape as RectangleShape2D).size.x * 0.5
                    break

        var horizontal_range := half_width + V34_MOVER_HORIZONTAL_PAD
        var near_start_x := absf(player_pos.x - start.x) <= horizontal_range
        var near_target_x := absf(player_pos.x - target.x) <= horizontal_range
        var near_start_y := absf(player_pos.y - start.y) <= V34_MOVER_VERTICAL_RANGE
        var near_target_y := absf(player_pos.y - target.y) <= V34_MOVER_VERTICAL_RANGE
        if (near_start_x and near_start_y) or (near_target_x and near_target_y):
            _v30_activate_mover(body, start, target, float(state.get("time", 1.2)))
            v30_pending_movers.erase(id)

func _v30_balanced_boulder_speed(pos: Vector2, speed: float, radius: float) -> float:
    var direction := signf(speed)
    if is_zero_approx(direction):
        direction = -1.0 if is_instance_valid(player) and pos.x > player.global_position.x else 1.0

    var magnitude := absf(speed)
    var cap := V34_BOULDER_CROSS_CAP
    v30_last_boulder_mode = "cross"
    if is_instance_valid(player):
        if pos.x > player.global_position.x and direction < 0.0:
            cap = V34_BOULDER_HEAD_ON_CAP
            v30_last_boulder_mode = "head_on"
        elif pos.x < player.global_position.x and direction > 0.0:
            cap = V34_BOULDER_CHASE_CAP
            v30_last_boulder_mode = "chase"

    var balanced := minf(magnitude, cap)
    if magnitude <= 0.01:
        balanced = cap
    var radius_penalty := clampf((radius - 62.0) * 0.50, 0.0, 14.0)
    balanced = maxf(180.0, balanced - radius_penalty)
    return direction * balanced

func _v34_level_2_1_minimal() -> void:
    _base_floor(3650)
    _text(Vector2(120, 470), "BÖLÜM 2: TUZAKLAR ARTIK DAHA SESSİZ.", 22, C_MUTED)

    _text(Vector2(520, 525), "GÜVENLİ", 18, C_GREEN)
    var fake_safe := _platform(Vector2(600, 610), Vector2(220, 24), C_GREEN)
    var hidden_safe := _spikes(Vector2(600, 612), 3, true)
    _trigger(Rect2(505, 500, 190, 138), func():
        if _once("21_safe_v34_min"):
            var tw := create_tween()
            tw.tween_property(fake_safe, "position:y", 755.0, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            _reveal(hidden_safe)
    )

    _platform(Vector2(1040, 545), Vector2(175, 22), C_BLUE)
    var ceiling := _hazard_block(Vector2(1320, 350), Vector2(132, 28), C_RED_DARK)
    _trigger(Rect2(1235, 445, 170, 190), func():
        if _once("21_crush_v34_min"):
            var tw := create_tween()
            tw.tween_interval(0.14)
            tw.tween_property(ceiling, "position:y", 505.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_interval(0.18)
            tw.tween_property(ceiling, "position:y", 350.0, 0.48).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

    _marker(Vector2(1710, 555), C_YELLOW, "?")
    _trigger(Rect2(1640, 455, 145, 180), func():
        if _once("21_double_rock_v34_min"):
            _boulder(Vector2(2200, 560), -320.0, 62.0)
            var tw := create_tween()
            tw.tween_interval(0.72)
            tw.tween_callback(func(): _boulder(Vector2(2340, 560), -300.0, 52.0))
    )

    var bridge: Array[StaticBody2D] = []
    for i in range(5):
        var segment := _platform(Vector2(2200 + i * 150, 565), Vector2(124, 22), C_PURPLE)
        bridge.append(segment)
        if i == 1 or i == 4:
            var segment_index := i
            _trigger(Rect2(2140 + i * 150, 505, 120, 130), func():
                if _once("21_bridge_v34_%d" % segment_index):
                    var tw := create_tween()
                    tw.tween_interval(0.18)
                    tw.tween_property(bridge[segment_index], "position:y", 780.0, 0.50).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            )

    _spikes(Vector2(3060, 612), 3, false)
    var goal := _finish(Vector2(3410, 580))
    _trigger(Rect2(3270, 455, 150, 180), func():
        if _once("21_goal_bait_v34_min"):
            create_tween().tween_property(goal, "position:x", 3500.0, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

func _v34_level_2_2_minimal() -> void:
    _base_floor(4000)
    _text(Vector2(120, 470), "YAKLAŞMADAN HİÇBİR ŞEYİN OYNAMAMASI GEREK.", 21, C_MUTED)

    var pop1 := _spikes(Vector2(720, 612), 3, true)
    var pop2 := _spikes(Vector2(1030, 612), 3, true)
    _trigger(Rect2(605, 465, 150, 170), func():
        if _once("22_chain_v34_min"):
            _reveal(pop1)
            var tw := create_tween()
            tw.tween_interval(0.55)
            tw.tween_callback(func(): _hide(pop1))
            tw.tween_interval(0.12)
            tw.tween_callback(func(): _reveal(pop2))
            tw.tween_interval(0.55)
            tw.tween_callback(func(): _hide(pop2))
    )

    var elevator := _platform(Vector2(1450, 590), Vector2(190, 24), C_BLUE)
    var ceiling_spikes := _spikes(Vector2(1450, 385), 3, true, true)
    _trigger(Rect2(1360, 505, 180, 130), func():
        if _once("22_elevator_v34_min"):
            var tw := create_tween()
            tw.tween_interval(0.10)
            tw.tween_property(elevator, "position:y", 455.0, 0.52).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
            tw.tween_callback(func(): _reveal(ceiling_spikes))
            tw.tween_interval(0.38)
            tw.tween_callback(func(): _hide(ceiling_spikes))
            tw.tween_property(elevator, "position:y", 590.0, 0.52).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    )

    _marker(Vector2(2050, 555), C_GREEN, "FINISH")
    var fake_finish_spikes := _spikes(Vector2(2050, 612), 3, true)
    _trigger(Rect2(1945, 470, 150, 165), func():
        if _once("22_fake_finish_v34_min"):
            _reveal(fake_finish_spikes)
            _play_tone(145.0, 0.16, 0.18)
            var tw := create_tween()
            tw.tween_interval(0.62)
            tw.tween_callback(func(): _hide(fake_finish_spikes))
    )

    var jaw_left := _hazard_block(Vector2(2585, 540), Vector2(38, 92), C_RED_DARK)
    var jaw_right := _hazard_block(Vector2(2795, 540), Vector2(38, 92), C_RED_DARK)
    _trigger(Rect2(2510, 475, 150, 160), func():
        if _once("22_jaws_v34_min"):
            var a := create_tween()
            a.tween_property(jaw_left, "position:x", 2640.0, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            a.tween_interval(0.24)
            a.tween_property(jaw_left, "position:x", 2585.0, 0.40)
            var b := create_tween()
            b.tween_property(jaw_right, "position:x", 2740.0, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            b.tween_interval(0.24)
            b.tween_property(jaw_right, "position:x", 2795.0, 0.40)
    )

    _trigger(Rect2(3140, 470, 150, 165), func():
        if _once("22_back_rock_v34_min"):
            _boulder(Vector2(3035, 560), 270.0, 60.0)
    )
    _finish(Vector2(3760, 580))

func _v34_level_2_3_minimal() -> void:
    _base_floor(4550)
    _text(Vector2(120, 470), "SON TEST: TUZAK SEN ORADAYKEN ÇALIŞIR.", 21, C_MUTED)

    var chase_wall := _hazard_block(Vector2(250, 540), Vector2(46, 176), C_RED_DARK)
    _trigger(Rect2(405, 470, 145, 165), func():
        if _once("23_chase_v34_min"):
            create_tween().tween_property(chase_wall, "position:x", 2700.0, 13.0).set_trans(Tween.TRANS_LINEAR)
    )

    var floor_trap1 := _spikes(Vector2(900, 612), 3, true)
    var floor_trap2 := _spikes(Vector2(1260, 612), 3, true)
    _trigger(Rect2(805, 470, 150, 165), func():
        if _once("23_floor_v34_min"):
            _reveal(floor_trap1)
            var tw := create_tween()
            tw.tween_interval(0.58)
            tw.tween_callback(func(): _hide(floor_trap1))
            tw.tween_interval(0.18)
            tw.tween_callback(func(): _reveal(floor_trap2))
            tw.tween_interval(0.58)
            tw.tween_callback(func(): _hide(floor_trap2))
    )

    var moving := _platform(Vector2(1710, 560), Vector2(210, 22), C_BLUE)
    _trigger(Rect2(1625, 505, 170, 130), func():
        if _once("23_move_v34_min"):
            var tw := create_tween()
            tw.tween_interval(0.08)
            tw.tween_property(moving, "position", Vector2(1840, 520), 0.68).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
            tw.tween_interval(0.34)
            tw.tween_property(moving, "position", Vector2(1710, 560), 0.62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    )

    _spikes(Vector2(2300, 612), 3, false)
    var corridor := _platform(Vector2(2300, 550), Vector2(250, 22), C_INK)
    corridor.set_meta("v34_required_corridor", true)
    var upper_spikes := _spikes(Vector2(2300, 390), 3, true, true)
    _trigger(Rect2(2180, 485, 160, 150), func():
        if _once("23_ceiling_v34_min"):
            var tw := create_tween()
            tw.tween_interval(0.30)
            tw.tween_callback(func(): _reveal(upper_spikes))
            tw.tween_interval(0.46)
            tw.tween_callback(func(): _hide(upper_spikes))
    )

    _marker(Vector2(3000, 555), C_GREEN, "BİTTİ")
    _trigger(Rect2(2920, 470, 150, 165), func():
        if _once("23_not_done_v34_min"):
            _boulder(Vector2(3470, 555), -300.0, 62.0)
            _play_tone(120.0, 0.20, 0.18)
    )

    var final_bridge: Array[StaticBody2D] = []
    for i in range(6):
        var segment := _platform(Vector2(3370 + i * 145, 565), Vector2(122, 22), C_PURPLE)
        final_bridge.append(segment)
        if i == 2 or i == 5:
            var segment_index := i
            _trigger(Rect2(3315 + i * 145, 505, 115, 130), func():
                if _once("23_final_bridge_v34_%d" % segment_index):
                    var tw := create_tween()
                    tw.tween_interval(0.16)
                    tw.tween_property(final_bridge[segment_index], "position:y", 770.0, 0.52).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
                    tw.tween_interval(0.52)
                    tw.tween_property(final_bridge[segment_index], "position:y", 565.0, 0.56).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
            )

    var last_spikes := _spikes(Vector2(4170, 612), 3, true)
    _trigger(Rect2(4070, 470, 145, 165), func():
        if _once("23_last_v34_min"):
            var tw := create_tween()
            tw.tween_interval(0.36)
            tw.tween_callback(func(): _reveal(last_spikes))
            tw.tween_interval(0.58)
            tw.tween_callback(func(): _hide(last_spikes))
    )
    _finish(Vector2(4390, 580))
