extends "res://scripts/game_v29.gd"

const V30_MOVER_MIN_SPEED := 85.0
const V30_MOVER_MAX_SPEED := 180.0
const V30_MOVER_MIN_ACTIVATION := 340.0
const V30_MOVER_MAX_ACTIVATION := 460.0
const V30_PLAYER_COMMIT_X := 175.0
const V30_HEAD_ON_MIN := 335.0
const V30_HEAD_ON_MAX := 380.0
const V30_CHASE_MIN := 285.0
const V30_CHASE_MAX := 315.0
const V30_CROSS_MIN := 300.0
const V30_CROSS_MAX := 350.0

var v30_pending_movers: Dictionary = {}
var v30_last_boulder_speed := 0.0
var v30_last_boulder_mode := ""

func _start_level(c: int, p: int) -> void:
    v30_pending_movers.clear()
    v30_last_boulder_speed = 0.0
    v30_last_boulder_mode = ""
    super._start_level(c, p)

func _process(delta: float) -> void:
    super._process(delta)
    _v30_tick_pending_movers()

func _show_main_menu() -> void:
    super._show_main_menu()
    if not is_instance_valid(hud):
        return
    for child in hud.get_children():
        if child is Label:
            var label := child as Label
            if label.text == "ANDROID • v2.9":
                label.text = "ANDROID • v3.0"
            elif label.text.begins_with("v2.9 SENTEZ / RİSK POLİSH"):
                label.text = "v3.0 OYNANIŞ DENETİMİ\n\n• Hareketli platformlar oyuncu yaklaşmadan çalışmaz\n• Yuvarlak / kaya hızları role göre dengelendi\n• Tuzak reaksiyon ve düşüş süreleri yeniden sınırlandı\n• 75 harita için anti-spoiler ve mantık testleri eklendi"

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

    if chapter >= 21:
        var edge := Line2D.new()
        edge.width = 2.0
        edge.default_color = Color(V25_CYAN, 0.46)
        edge.points = PackedVector2Array([
            Vector2(-size.x * 0.5 + 7.0, -size.y * 0.5 + 2.0),
            Vector2(size.x * 0.5 - 7.0, -size.y * 0.5 + 2.0)
        ])
        edge.z_index = 7
        body.add_child(edge)

    world.add_child(body)

    var distance := pos.distance_to(target)
    if distance <= 1.0:
        return body

    var requested_speed := distance / maxf(travel_time, 0.10)
    var balanced_speed := clampf(requested_speed, V30_MOVER_MIN_SPEED, V30_MOVER_MAX_SPEED)
    var balanced_time := distance / balanced_speed
    var activation_distance := clampf(260.0 + size.x * 0.80, V30_MOVER_MIN_ACTIVATION, V30_MOVER_MAX_ACTIVATION)

    body.set_meta("v30_lazy_mover", true)
    body.set_meta("v30_mover_activated", false)
    body.set_meta("v30_mover_speed", balanced_speed)
    body.set_meta("v30_activation_distance", activation_distance)
    body.set_meta("v30_start", pos)
    body.set_meta("v30_target", target)

    v30_pending_movers[body.get_instance_id()] = {
        "node": body,
        "start": pos,
        "target": target,
        "time": balanced_time,
        "activation": activation_distance
    }
    return body

func _v30_tick_pending_movers() -> void:
    if v30_pending_movers.is_empty() or not is_instance_valid(player) or not player.alive:
        return
    var committed := player.global_position.x >= V30_PLAYER_COMMIT_X or absf(player.velocity.x) >= 40.0
    if not committed:
        return
    var px := player.global_position.x
    for id in v30_pending_movers.keys():
        var state: Dictionary = v30_pending_movers[id]
        var body := state.get("node") as AnimatableBody2D
        if not is_instance_valid(body):
            v30_pending_movers.erase(id)
            continue
        var start: Vector2 = state.get("start", body.position)
        var target: Vector2 = state.get("target", body.position)
        var activation := float(state.get("activation", 420.0))
        var approach := minf(absf(px - start.x), absf(px - target.x))
        if approach <= activation:
            _v30_activate_mover(body, start, target, float(state.get("time", 1.2)))
            v30_pending_movers.erase(id)

func _v30_activate_mover(body: AnimatableBody2D, start: Vector2, target: Vector2, travel_time: float) -> void:
    if not is_instance_valid(body) or bool(body.get_meta("v30_mover_activated", false)):
        return
    body.set_meta("v30_mover_activated", true)
    var tw := body.create_tween().set_loops()
    tw.tween_property(body, "position", target, maxf(0.48, travel_time)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tw.tween_interval(0.06)
    tw.tween_property(body, "position", start, maxf(0.48, travel_time)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tw.tween_interval(0.06)

func _boulder(pos: Vector2, speed: float, radius: float) -> void:
    var balanced := _v30_balanced_boulder_speed(pos, speed, radius)
    v30_last_boulder_speed = balanced
    super._boulder(pos, balanced, clampf(radius, 42.0, 82.0))

func _v30_balanced_boulder_speed(pos: Vector2, speed: float, radius: float) -> float:
    var direction := signf(speed)
    if is_zero_approx(direction):
        direction = -1.0 if is_instance_valid(player) and pos.x > player.global_position.x else 1.0
    var magnitude := absf(speed)
    var target_speed := clampf(magnitude, V30_CROSS_MIN, V30_CROSS_MAX)
    v30_last_boulder_mode = "cross"

    if is_instance_valid(player):
        if pos.x > player.global_position.x and direction < 0.0:
            target_speed = clampf(magnitude, V30_HEAD_ON_MIN, V30_HEAD_ON_MAX)
            v30_last_boulder_mode = "head_on"
        elif pos.x < player.global_position.x and direction > 0.0:
            target_speed = clampf(magnitude, V30_CHASE_MIN, V30_CHASE_MAX)
            v30_last_boulder_mode = "chase"

    var radius_penalty := clampf((radius - 68.0) * 0.45, 0.0, 12.0)
    target_speed = maxf(280.0, target_speed - radius_penalty)
    return direction * target_speed

func _falling_boulder(pos: Vector2, radius: float, delay: float) -> Area2D:
    return super._falling_boulder(pos, clampf(radius, 42.0, 76.0), maxf(delay, 0.10))

func _reverse_controls(seconds: float) -> void:
    super._reverse_controls(clampf(seconds, 0.35, 0.82))

func _timed_hazard(area: Area2D, wait_before: float, active_time: float, key: String) -> void:
    super._timed_hazard(area, maxf(wait_before, 0.34), clampf(active_time, 0.32, 0.52), key)

func _delayed_platform_drop(body: StaticBody2D, delay: float, distance: float = 300.0) -> void:
    super._delayed_platform_drop(body, maxf(delay, 0.42), minf(distance, 260.0))

func _v23_validate_current_level(c: int, p: int) -> int:
    var failures := super._v23_validate_current_level(c, p)
    if not is_instance_valid(world):
        return failures

    for id in v30_pending_movers.keys():
        var state: Dictionary = v30_pending_movers[id]
        var body := state.get("node") as AnimatableBody2D
        if not is_instance_valid(body):
            continue
        var speed := float(body.get_meta("v30_mover_speed", 0.0))
        var activation := float(body.get_meta("v30_activation_distance", 0.0))
        if speed < V30_MOVER_MIN_SPEED - 0.1 or speed > V30_MOVER_MAX_SPEED + 0.1:
            push_error("VALIDATE %d-%d mover speed %.1f" % [c, p, speed])
            failures += 1
        if activation < V30_MOVER_MIN_ACTIVATION - 0.1 or activation > V30_MOVER_MAX_ACTIVATION + 0.1:
            push_error("VALIDATE %d-%d mover activation %.1f" % [c, p, activation])
            failures += 1
        if bool(body.get_meta("v30_mover_activated", false)):
            push_error("VALIDATE %d-%d mover self-activated before approach" % [c, p])
            failures += 1

    var finish_x := -1.0
    for child in world.get_children():
        if child.has_meta("v23_finish") and child is Node2D:
            finish_x = (child as Node2D).position.x
            break
    if finish_x >= 0.0:
        for gap in v23_level_gaps:
            if finish_x > gap.x and finish_x < gap.y:
                push_error("VALIDATE %d-%d finish inside floor gap %.1f" % [c, p, finish_x])
                failures += 1
    return failures
