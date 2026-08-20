extends "res://scripts/game_v22_release.gd"

const V23_BG := Color("#e6ecf3")
const V23_CYAN := Color("#0891b2")
const V23_GREEN := Color("#16a34a")
const V23_AMBER := Color("#d97706")
const V23_RED := Color("#dc4455")
const V23_MUTED := Color("#64748b")
const V23_MAX_CHASE_SPEED := 250.0
const V23_MAX_NAKED_GAP := 215.0

var v23_barriers: Dictionary = {}
var v23_level_gaps: Array[Vector2] = []

func _ready() -> void:
    if "--validate-all-levels" in OS.get_cmdline_user_args():
        RenderingServer.set_default_clear_color(V23_BG)
        _safe_load_progress()
        v20_effects_enabled = false
        v22_sound_enabled = false
        call_deferred("_v23_run_validation")
        return
    super._ready()

func _start_level(c: int, p: int) -> void:
    v23_barriers.clear()
    v23_level_gaps.clear()
    super._start_level(c, p)

func _process(delta: float) -> void:
    super._process(delta)
    if delta <= 0.0:
        return
    var max_step: float = V23_MAX_CHASE_SPEED * delta
    for id in v23_barriers.keys():
        var state: Dictionary = v23_barriers[id]
        var raw_node = state.get("node")
        if raw_node == null or not is_instance_valid(raw_node):
            v23_barriers.erase(id)
            continue
        var node := raw_node as Node2D
        if not is_instance_valid(node):
            v23_barriers.erase(id)
            continue
        var last_x: float = float(state.get("last_x", node.position.x))
        var dx: float = node.position.x - last_x
        if absf(dx) > max_step:
            node.position.x = last_x + clampf(dx, -max_step, max_step)
        state["last_x"] = node.position.x
        v23_barriers[id] = state

func _build_level(c: int, p: int) -> void:
    if c == 1 and p == 3:
        _v23_level_1_3()
    elif c == 3 and p == 3:
        _v23_level_3_3()
    else:
        super._build_level(c, p)

func _floor_with_gaps(width: float, gaps: Array[Vector2]) -> void:
    v23_level_gaps.clear()
    for gap in gaps:
        v23_level_gaps.append(gap)
    super._floor_with_gaps(width, gaps)

func _finish(pos: Vector2) -> Area2D:
    var area := super._finish(pos)
    if is_instance_valid(area):
        area.set_meta("v23_finish", true)
    return area

func _hazard_block(pos: Vector2, size: Vector2, color: Color) -> Area2D:
    var area := super._hazard_block(pos, size, color)
    if is_instance_valid(area) and size.x <= 120.0 and size.y >= 240.0:
        v23_barriers[area.get_instance_id()] = {
            "node": area,
            "last_x": area.position.x
        }
    return area

func _moving_platform(pos: Vector2, size: Vector2, target: Vector2, travel_time: float, color: Color = V6_BLUE) -> AnimatableBody2D:
    return super._moving_platform(pos, size, target, maxf(travel_time, 1.08), color)

func _reverse_controls(seconds: float) -> void:
    super._reverse_controls(clampf(seconds, 0.35, 0.88))

func _timed_hazard(area: Area2D, wait_before: float, active_time: float, key: String) -> void:
    super._timed_hazard(area, maxf(wait_before, 0.30), clampf(active_time, 0.30, 0.50), key)

func _delayed_platform_drop(body: StaticBody2D, delay: float, distance: float = 300.0) -> void:
    super._delayed_platform_drop(body, maxf(delay, 0.38), minf(distance, 285.0))

func _camera_trick(amount: float = 0.065) -> void:
    super._camera_trick(clampf(amount, -0.055, 0.055))

func _boulder(pos: Vector2, speed: float, radius: float) -> void:
    var capped_speed: float = signf(speed) * minf(absf(speed), 430.0)
    super._boulder(pos, capped_speed, minf(radius, 82.0))

func _falling_boulder(pos: Vector2, radius: float, delay: float) -> Area2D:
    return super._falling_boulder(pos, minf(radius, 76.0), maxf(delay, 0.06))

func _v23_level_1_3() -> void:
    _base_floor(3500)
    _text(Vector2(120, 470), "OYUN DA SENİ TANIYOR.", 24, MUTED)

    var bait := _spikes(Vector2(760, 612), 3, true)
    _trigger(Rect2(560, 420, 150, 220), func():
        if _once("13_bait_v23"):
            _reveal(bait)
            var tw := create_tween()
            tw.tween_interval(0.78)
            tw.tween_callback(func(): _hide(bait))
    )

    var lift := _platform(Vector2(1320, 590), Vector2(210, 28), BLUE)
    _spikes(Vector2(1320, 390), 3, false, true)
    _trigger(Rect2(1190, 450, 160, 180), func():
        if _once("13_lift_v23"):
            var tw := create_tween()
            tw.tween_property(lift, "position:y", 525.0, 0.46).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
            tw.tween_interval(0.32)
            tw.tween_property(lift, "position:y", 590.0, 0.44).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    )

    var closing := _hazard_block(Vector2(1850, 170), Vector2(40, 350), RED_DARK)
    _trigger(Rect2(1540, 400, 140, 230), func():
        if _once("13_wall_v23"):
            var tw := create_tween()
            tw.tween_property(closing, "position:y", 468.0, 0.62).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_interval(0.48)
            tw.tween_property(closing, "position:y", 170.0, 0.64).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    )

    var fake := _finish(Vector2(2550, 580))
    _trigger(Rect2(2210, 410, 180, 230), func():
        if _once("13_fake_v23"):
            fake.monitoring = false
            fake.visible = false
            _troll_popup("DAHA DEĞİL")
            var ball := _boulder(Vector2(2950, 555), -315.0, 70.0)
            if ball != null:
                ball.set_meta("v23_balanced", true)
    )

    var last_spikes := _spikes(Vector2(3000, 612), 3, true)
    _trigger(Rect2(2760, 410, 130, 230), func():
        if _once("13_last_v23"):
            _reveal(last_spikes)
            var tw := create_tween()
            tw.tween_interval(0.58)
            tw.tween_callback(func(): _hide(last_spikes))
    )
    _finish(Vector2(3320, 580))

func _v23_level_3_3() -> void:
    _base_floor(4700)
    _text(Vector2(120, 470), "BÖLÜM 3: KOŞU SINAVI. KAÇIŞ PENCERELERİN VAR.", 22, V23_AMBER)

    var chase := _hazard_block(Vector2(430, 470), Vector2(76, 290), V23_RED)
    _trigger(Rect2(700, 400, 130, 235), func():
        if _once("33_chase_v23"):
            create_tween().tween_property(chase, "position:x", 4050.0, 15.4).set_trans(Tween.TRANS_LINEAR)
    )

    var sweep := _spikes(Vector2(1370, 612), 3, true)
    _trigger(Rect2(1050, 400, 110, 230), func():
        if _once("33_sweep_v23"):
            _reveal(sweep)
            var tw := create_tween()
            tw.tween_interval(0.48)
            tw.tween_callback(func(): _hide(sweep))
    )

    for i in range(3):
        var drop_x := 1900.0 + float(i) * 500.0
        _falling_boulder(Vector2(drop_x, 130), 62.0, 0.45 + float(i) * 0.18)

    var fake_finish := _finish(Vector2(3330, 580))
    _trigger(Rect2(3030, 400, 140, 230), func():
        if _once("33_fake_finish_v23"):
            fake_finish.monitoring = false
            fake_finish.visible = false
            _troll_popup("SON DEĞİL")
    )

    var final_spikes := _spikes(Vector2(3930, 612), 3, true)
    _trigger(Rect2(3660, 400, 140, 230), func():
        if _once("33_last_v23"):
            var tw := create_tween()
            tw.tween_interval(0.34)
            tw.tween_callback(func(): _reveal(final_spikes))
            tw.tween_interval(0.60)
            tw.tween_callback(func(): _hide(final_spikes))
    )
    _finish(Vector2(4470, 580))

func _v23_run_validation() -> void:
    var failures: Array[String] = []
    var checked := 0
    for c in range(1, 26):
        for p in range(1, 4):
            checked += 1
            _start_level(c, p)
            await get_tree().process_frame
            await get_tree().process_frame
            var map_failures := _v23_validate_current_map(c, p)
            if map_failures.is_empty():
                print("LEVEL_VALIDATE_OK:%d-%d" % [c, p])
            else:
                for item in map_failures:
                    failures.append(item)
                    print("LEVEL_VALIDATE_FAIL:%s" % item)
    if failures.is_empty():
        print("ALL_LEVELS_OK:%d" % checked)
        get_tree().quit(0)
    else:
        print("ALL_LEVELS_FAILED:%d" % failures.size())
        for item in failures:
            print("  %s" % item)
        get_tree().quit(1)

func _v23_validate_current_map(c: int, p: int) -> Array[String]:
    var failures: Array[String] = []
    if not is_instance_valid(player):
        failures.append("%d-%d player missing" % [c, p])
    var finishes := _v23_find_finish_nodes(world)
    if finishes.is_empty():
        failures.append("%d-%d finish missing" % [c, p])
    elif finishes.size() > 3:
        failures.append("%d-%d suspicious finish count %d" % [c, p, finishes.size()])
    for finish in finishes:
        if finish.position.x < 300.0 or finish.position.x > level_width + 120.0:
            failures.append("%d-%d finish x out of bounds %.1f" % [c, p, finish.position.x])
        for gap in v23_level_gaps:
            if finish.position.x > gap.x and finish.position.x < gap.y:
                failures.append("%d-%d finish inside floor gap %.1f" % [c, p, finish.position.x])

    for gap in v23_level_gaps:
        var gap_width := gap.y - gap.x
        if gap_width > V23_MAX_NAKED_GAP and not _v23_gap_has_bridge(gap):
            failures.append("%d-%d naked gap %.1f px" % [c, p, gap_width])

    return failures

func _v23_find_finish_nodes(node: Node) -> Array[Area2D]:
    var result: Array[Area2D] = []
    if node == null:
        return result
    if node is Area2D and bool(node.get_meta("v23_finish", false)):
        result.append(node as Area2D)
    for child in node.get_children():
        result.append_array(_v23_find_finish_nodes(child))
    return result

func _v23_gap_has_bridge(gap: Vector2) -> bool:
    if not is_instance_valid(world):
        return false
    var center_x := (gap.x + gap.y) * 0.5
    for child in world.get_children():
        if child is StaticBody2D or child is AnimatableBody2D:
            var body := child as Node2D
            if body.position.x < gap.x - 150.0 or body.position.x > gap.y + 150.0:
                continue
            for sub in child.get_children():
                if sub is CollisionShape2D:
                    var cs := sub as CollisionShape2D
                    if cs.shape is RectangleShape2D:
                        var rect := cs.shape as RectangleShape2D
                        if rect.size.x >= 80.0 and absf(body.position.x - center_x) <= (gap.y - gap.x) * 0.75 + 120.0:
                            return true
    return false