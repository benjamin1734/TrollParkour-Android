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
        var node: Node2D = state.get("node") as Node2D
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

    var wall := _platform(Vector2(1850, 250), Vector2(36, 280), RED_DARK)
    _trigger(Rect2(1680, 430, 120, 210), func():
        if _once("13_wall_v23"):
            var tw := create_tween()
            tw.tween_interval(0.10)
            tw.tween_property(wall, "position:y", 470.0, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_interval(0.46)
            tw.tween_property(wall, "position:y", 250.0, 0.44).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

    _trigger(Rect2(2200, 410, 100, 220), func():
        if _once("13_rock_v23"):
            _boulder(Vector2(2820, 560), -410.0, 78.0)
    )

    _marker(Vector2(3040, 560), GREEN, "FINISH")
    var fake := _spikes(Vector2(3050, 612), 3, true)
    _trigger(Rect2(2900, 420, 100, 210), func():
        if _once("13_fake_v23"):
            _reveal(fake)
            var tw := create_tween()
            tw.tween_interval(0.58)
            tw.tween_callback(func(): _hide(fake))
    )
    _finish(Vector2(3340, 580))

func _v23_level_3_3() -> void:
    _base_floor(5000)
    _text(Vector2(120, 470), "SON KISIM: PARANOYANI KULLAN.", 24, V3_MUTED)
    _text(Vector2(430, 520), "YOL AÇIK.", 20, V3_GREEN)

    var lonely := _spikes(Vector2(1050, 612), 2, true)
    _trigger(Rect2(850, 390, 120, 240), func():
        if _once("33_lonely_v23"):
            _reveal(lonely)
            var tw := create_tween()
            tw.tween_interval(0.62)
            tw.tween_callback(func(): _hide(lonely))
    )

    var chase := _hazard_block(Vector2(430, 500), Vector2(90, 300), V3_RED_DARK)
    _trigger(Rect2(1250, 390, 120, 240), func():
        if _once("33_chase_v23"):
            create_tween().tween_property(chase, "position:x", 3650.0, 13.4).set_trans(Tween.TRANS_LINEAR)
    )

    var slide_spikes := _spikes(Vector2(2050, 612), 3, false)
    _trigger(Rect2(1660, 390, 120, 240), func():
        if _once("33_slide_v23"):
            create_tween().tween_property(slide_spikes, "position:x", 1840.0, 0.68).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    )

    _trigger(Rect2(2300, 390, 120, 240), func():
        if _once("33_rocks_v23"):
            _falling_boulder(Vector2(2550, 70), 68.0, 0.12)
            _falling_boulder(Vector2(2840, 45), 60.0, 0.52)
            _falling_boulder(Vector2(3110, 20), 54.0, 0.92)
    )

    _marker(Vector2(3620, 555), V3_GREEN, "FINISH")
    var fake_finish := _spikes(Vector2(3620, 612), 3, true)
    _trigger(Rect2(3420, 390, 120, 240), func():
        if _once("33_fake_v23"):
            _reveal(fake_finish)
            _play_tone(125.0, 0.18, 0.20)
            var tw := create_tween()
            tw.tween_interval(0.56)
            tw.tween_callback(func(): _hide(fake_finish))
    )

    var last := _spikes(Vector2(4250, 612), 3, true)
    _trigger(Rect2(4050, 390, 120, 240), func():
        if _once("33_last_v23"):
            var tw := create_tween()
            tw.tween_interval(0.34)
            tw.tween_callback(func(): _reveal(last))
            tw.tween_interval(0.46)
            tw.tween_callback(func(): _hide(last))
    )

    var goal := _finish(Vector2(4700, 580))
    _trigger(Rect2(4450, 390, 120, 240), func():
        if _once("33_goal_v23"):
            var tw := create_tween()
            tw.tween_property(goal, "position:x", 4780.0, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
            tw.tween_interval(0.42)
            tw.tween_property(goal, "position:x", 4700.0, 0.30)
    )

func _v23_run_validation() -> void:
    await get_tree().process_frame
    var failures: int = 0
    var checked: int = 0
    for c in range(1, 21):
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
    if failures == 0 and checked == 60:
        print("ALL_LEVELS_OK:60")
        get_tree().quit(0)
    else:
        print("ALL_LEVELS_FAILED:%d:%d" % [checked, failures])
        get_tree().quit(1)

func _v23_validate_current_level(c: int, p: int) -> int:
    var failures: int = 0
    if not is_instance_valid(world):
        push_error("VALIDATE %d-%d world missing" % [c, p])
        return 1
    if not is_instance_valid(player):
        push_error("VALIDATE %d-%d player missing" % [c, p])
        failures += 1

    var finish_count: int = 0
    var finish_x: float = -1.0
    for child in world.get_children():
        if child.has_meta("v23_finish"):
            finish_count += 1
            if child is Node2D:
                finish_x = maxf(finish_x, child.position.x)
    if finish_count != 1:
        push_error("VALIDATE %d-%d finish count %d" % [c, p, finish_count])
        failures += 1
    elif finish_x < 80.0 or finish_x > level_width + 180.0:
        push_error("VALIDATE %d-%d finish out of bounds %.1f / %.1f" % [c, p, finish_x, level_width])
        failures += 1

    for gap in v23_level_gaps:
        var gap_width: float = gap.y - gap.x
        if gap_width > V23_MAX_NAKED_GAP and not _v23_gap_has_bridge(gap):
            push_error("VALIDATE %d-%d unbridged gap %.1f-%.1f width %.1f" % [c, p, gap.x, gap.y, gap_width])
            failures += 1
    return failures

func _v23_gap_has_bridge(gap: Vector2) -> bool:
    if not is_instance_valid(world):
        return false
    for child in world.get_children():
        if child is StaticBody2D or child is AnimatableBody2D:
            if child.position.x > gap.x + 12.0 and child.position.x < gap.y - 12.0 and child.position.y < 620.0:
                return true
    return false