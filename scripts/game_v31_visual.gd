extends "res://scripts/game_v30_audit.gd"

const V31_SKY_LIGHT := Color("#e9f1f8")
const V31_SKY_DARK := Color("#050814")
const V31_INK := Color("#0b1220")
const V31_STEEL := Color("#263244")
const V31_STEEL_LIGHT := Color("#3b4b63")
const V31_CYAN := Color("#38d7f3")
const V31_BLUE := Color("#4f8cff")
const V31_PURPLE := Color("#9b72ff")
const V31_GREEN := Color("#47e3a4")
const V31_AMBER := Color("#ffb84a")
const V31_RED := Color("#ff5368")
const V31_ROCK := Color("#3a2530")
const V31_ROCK_DARK := Color("#17111a")
const V31_MAX_TRACKED_ROCKS := 6

var v31_environment: Node2D
var v31_far_layer: Node2D
var v31_mid_layer: Node2D
var v31_near_layer: Node2D
var v31_rocks: Dictionary = {}
var v31_environment_phase := 0.0

func _start_level(c: int, p: int) -> void:
    v31_environment = null
    v31_far_layer = null
    v31_mid_layer = null
    v31_near_layer = null
    v31_rocks.clear()
    v31_environment_phase = 0.0
    super._start_level(c, p)
    if is_instance_valid(world):
        _v31_build_environment()

func _process(delta: float) -> void:
    super._process(delta)
    v31_environment_phase += delta
    _v31_update_parallax()
    _v31_tick_rocks(delta)

func _show_main_menu() -> void:
    super._show_main_menu()
    if not is_instance_valid(hud):
        return
    for child in hud.get_children():
        if child is Label:
            var label := child as Label
            if label.text == "ANDROID • v3.0":
                label.text = "ANDROID • v3.1"
            elif label.text.begins_with("v3.0 OYNANIŞ DENETİMİ"):
                label.text = "v3.1 GÖRSEL OVERHAUL • FAZ 1\n\n• Katmanlı parallax ortam ve atmosfer\n• Platform / zemin materyal yükseltmesi\n• Diken ve kaya efektlerinin görsel yenilenmesi\n• Karakter, HUD ve impact polish katmanı"
    _v31_add_menu_visuals()

func _build_hud() -> void:
    super._build_hud()
    if not is_instance_valid(hud):
        return
    var top_glow := Line2D.new()
    top_glow.name = "V31HUDGlow"
    top_glow.width = 2.0
    top_glow.default_color = Color(V31_CYAN if chapter >= 21 else V31_BLUE, 0.42)
    top_glow.points = PackedVector2Array([Vector2(0, 69), Vector2(1280, 69)])
    top_glow.z_index = 40
    hud.add_child(top_glow)

    var progress := Label.new()
    progress.name = "V31MapProgress"
    progress.position = Vector2(465, 45)
    progress.size = Vector2(150, 20)
    progress.text = "HARİTA %d / 75" % clampi((chapter - 1) * 3 + part, 1, 75)
    progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    progress.add_theme_font_size_override("font_size", 10)
    progress.add_theme_color_override("font_color", Color(V31_CYAN if chapter >= 21 else V31_BLUE, 0.74))
    progress.z_index = 41
    hud.add_child(progress)

func _spawn_player(pos: Vector2) -> void:
    super._spawn_player(pos)
    _v31_upgrade_player_visual()

func _platform(pos: Vector2, size: Vector2, color: Color) -> StaticBody2D:
    var body := super._platform(pos, size, color)
    _v31_polish_platform(body, size, false)
    return body

func _moving_platform(pos: Vector2, size: Vector2, target: Vector2, travel_time: float, color: Color = V6_BLUE) -> AnimatableBody2D:
    var body := super._moving_platform(pos, size, target, travel_time, color)
    _v31_polish_platform(body, size, true)
    return body

func _v30_activate_mover(body: AnimatableBody2D, start: Vector2, target: Vector2, travel_time: float) -> void:
    super._v30_activate_mover(body, start, target, travel_time)
    if v20_effects_enabled and is_instance_valid(body):
        _v31_mover_activation_fx(body.global_position)

func _spikes(pos: Vector2, count: int, hidden: bool, inverted: bool = false) -> Area2D:
    var area := super._spikes(pos, count, hidden, inverted)
    if is_instance_valid(area):
        area.set_meta("v31_spike_hidden", hidden)
        _v31_polish_spikes(area, hidden)
    return area

func _reveal(area: Area2D) -> void:
    super._reveal(area)
    if not is_instance_valid(area):
        return
    var decor := area.get_node_or_null("V31SpikeDecor") as Node2D
    if is_instance_valid(decor):
        decor.visible = true
    if v20_effects_enabled:
        _v31_hazard_snap_fx(area.global_position)

func _hide(area: Area2D) -> void:
    super._hide(area)
    if not is_instance_valid(area):
        return
    var decor := area.get_node_or_null("V31SpikeDecor") as Node2D
    if is_instance_valid(decor):
        decor.visible = false

func _boulder(pos: Vector2, speed: float, radius: float) -> void:
    var before: Dictionary = {}
    if is_instance_valid(world):
        for child in world.get_children():
            if child is Area2D:
                before[child.get_instance_id()] = true
    super._boulder(pos, speed, radius)
    var rock := _v31_find_new_circle_area(before)
    if is_instance_valid(rock):
        var actual_radius := _v31_circle_radius(rock, clampf(radius, 42.0, 82.0))
        _v31_style_boulder(rock, actual_radius, false)
        if v31_rocks.size() < V31_MAX_TRACKED_ROCKS:
            v31_rocks[rock.get_instance_id()] = {
                "node": rock,
                "radius": actual_radius,
                "speed": v30_last_boulder_speed,
                "dust": 0.02,
                "near_done": false
            }

func _falling_boulder(pos: Vector2, radius: float, delay: float) -> Area2D:
    var area := super._falling_boulder(pos, radius, delay)
    if is_instance_valid(area):
        _v31_style_boulder(area, _v31_circle_radius(area, clampf(radius, 42.0, 76.0)), true)
        if v20_effects_enabled:
            _v31_fall_streak(area)
    return area

func _v31_build_environment() -> void:
    if not is_instance_valid(world):
        return
    v31_environment = Node2D.new()
    v31_environment.name = "V31Environment"
    v31_environment.z_index = -110
    v31_environment.set_meta("dark", chapter >= 21)
    world.add_child(v31_environment)

    var wash := Polygon2D.new()
    wash.name = "AtmosphereWash"
    wash.polygon = PackedVector2Array([
        Vector2(0, 0), Vector2(level_width, 0), Vector2(level_width, 720), Vector2(0, 720)
    ])
    wash.color = Color(0.03, 0.06, 0.13, 0.18) if chapter >= 21 else Color(0.36, 0.66, 0.86, 0.055)
    wash.z_index = -20
    v31_environment.add_child(wash)

    v31_far_layer = Node2D.new()
    v31_far_layer.name = "Far"
    v31_far_layer.z_index = -18
    v31_environment.add_child(v31_far_layer)

    v31_mid_layer = Node2D.new()
    v31_mid_layer.name = "Mid"
    v31_mid_layer.z_index = -12
    v31_environment.add_child(v31_mid_layer)

    v31_near_layer = Node2D.new()
    v31_near_layer.name = "Near"
    v31_near_layer.z_index = -6
    v31_environment.add_child(v31_near_layer)

    _v31_build_far_silhouettes()
    _v31_build_mid_structure()
    _v31_build_near_atmosphere()

func _v31_build_far_silhouettes() -> void:
    if not is_instance_valid(v31_far_layer):
        return
    var dark := chapter >= 21
    var base_color := Color(0.12, 0.19, 0.31, 0.34) if dark else Color(0.28, 0.45, 0.58, 0.12)
    var glow_color := Color(V31_PURPLE, 0.09) if dark else Color(V31_BLUE, 0.055)
    var count := maxi(5, int(level_width / 620.0) + 2)
    for i in range(count):
        var x := -180.0 + float(i) * 620.0
        var h := 110.0 + float((i * 47) % 150)
        var w := 170.0 + float((i * 31) % 95)
        var tower := Polygon2D.new()
        tower.position = Vector2(x, 620.0 - h * 0.5)
        tower.polygon = _v31_rect_points(Vector2(w, h))
        tower.color = base_color
        v31_far_layer.add_child(tower)
        var cap := Line2D.new()
        cap.position = tower.position
        cap.width = 2.0
        cap.default_color = glow_color
        cap.points = PackedVector2Array([Vector2(-w * 0.45, -h * 0.5 + 10), Vector2(w * 0.45, -h * 0.5 + 10)])
        v31_far_layer.add_child(cap)

    var horizon := Line2D.new()
    horizon.width = 2.0
    horizon.default_color = Color(V31_CYAN, 0.08 if dark else 0.05)
    horizon.points = PackedVector2Array([Vector2(-300, 612), Vector2(level_width + 300, 612)])
    v31_far_layer.add_child(horizon)

func _v31_build_mid_structure() -> void:
    if not is_instance_valid(v31_mid_layer):
        return
    var dark := chapter >= 21
    var color := Color(V31_CYAN, 0.11) if dark else Color(V31_BLUE, 0.065)
    var count := maxi(6, int(level_width / 760.0) + 2)
    for i in range(count):
        var x := 140.0 + float(i) * 760.0
        var beam := Line2D.new()
        beam.width = 3.0
        beam.default_color = color
        beam.points = PackedVector2Array([
            Vector2(x - 150, 610),
            Vector2(x, 355 - float((i * 29) % 70)),
            Vector2(x + 150, 610)
        ])
        v31_mid_layer.add_child(beam)

        var node := Polygon2D.new()
        node.position = Vector2(x, 390 - float((i * 17) % 55))
        node.polygon = _circle_points(8.0, 14)
        node.color = Color(V31_PURPLE if dark else V31_BLUE, 0.12)
        v31_mid_layer.add_child(node)

func _v31_build_near_atmosphere() -> void:
    if not is_instance_valid(v31_near_layer):
        return
    var dark := chapter >= 21
    var particle_count := 10 if v20_effects_enabled else 6
    for i in range(particle_count):
        var mote := Polygon2D.new()
        mote.name = "Mote%d" % i
        mote.position = Vector2(180.0 + float(i) * (level_width / maxf(1.0, float(particle_count))), 175.0 + float((i * 83) % 360))
        var s := 2.0 + float(i % 3)
        mote.polygon = _circle_points(s, 10)
        mote.color = Color(V31_CYAN if dark else V31_BLUE, 0.15 if dark else 0.08)
        v31_near_layer.add_child(mote)
        if v20_effects_enabled:
            var drift := 18.0 + float((i * 11) % 24)
            var tw := mote.create_tween().set_loops()
            tw.tween_property(mote, "position:y", mote.position.y - drift, 2.8 + float(i % 4) * 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
            tw.tween_property(mote, "position:y", mote.position.y, 2.8 + float(i % 4) * 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

    var fog := Line2D.new()
    fog.name = "FogRibbon"
    fog.width = 30.0
    fog.default_color = Color(0.35, 0.70, 0.86, 0.025 if not dark else 0.035)
    fog.points = PackedVector2Array([
        Vector2(-200, 555), Vector2(level_width * 0.25, 535), Vector2(level_width * 0.55, 560), Vector2(level_width + 200, 530)
    ])
    v31_near_layer.add_child(fog)

func _v31_update_parallax() -> void:
    if not is_instance_valid(camera):
        return
    var cx := camera.position.x
    if is_instance_valid(v31_far_layer):
        v31_far_layer.position.x = cx * 0.075
    if is_instance_valid(v31_mid_layer):
        v31_mid_layer.position.x = cx * 0.038
    if is_instance_valid(v31_near_layer):
        v31_near_layer.position.x = cx * 0.014

func _v31_polish_platform(body: Node2D, size: Vector2, moving: bool) -> void:
    if not is_instance_valid(body) or body.get_node_or_null("V31PlatformSkin") != null:
        return
    var skin := Node2D.new()
    skin.name = "V31PlatformSkin"
    body.add_child(skin)

    var shadow := Polygon2D.new()
    shadow.position = Vector2(5, 7)
    shadow.polygon = _v31_rect_points(Vector2(maxf(8.0, size.x - 4.0), maxf(8.0, size.y - 2.0)))
    shadow.color = Color(0.01, 0.02, 0.04, 0.22)
    shadow.z_index = -5
    skin.add_child(shadow)

    var inner := Polygon2D.new()
    inner.polygon = _v31_rect_points(Vector2(maxf(6.0, size.x - 8.0), maxf(6.0, size.y - 7.0)))
    inner.color = Color(V31_STEEL_LIGHT if chapter >= 21 else V31_BLUE, 0.13 if chapter >= 21 else 0.055)
    inner.z_index = 2
    skin.add_child(inner)

    var top := Line2D.new()
    top.width = 2.2 if moving else 1.8
    top.default_color = Color(V31_CYAN if chapter >= 21 else V31_BLUE, 0.56 if moving else 0.30)
    top.points = PackedVector2Array([
        Vector2(-size.x * 0.5 + 5.0, -size.y * 0.5 + 2.0),
        Vector2(size.x * 0.5 - 5.0, -size.y * 0.5 + 2.0)
    ])
    top.z_index = 5
    skin.add_child(top)

    var bottom := Line2D.new()
    bottom.width = 2.0
    bottom.default_color = Color(0.01, 0.02, 0.05, 0.24)
    bottom.points = PackedVector2Array([
        Vector2(-size.x * 0.5 + 4.0, size.y * 0.5 - 2.0),
        Vector2(size.x * 0.5 - 4.0, size.y * 0.5 - 2.0)
    ])
    bottom.z_index = 4
    skin.add_child(bottom)

    if size.x >= 110.0 and size.x <= 900.0:
        for side in [-1.0, 1.0]:
            var bolt := Polygon2D.new()
            bolt.position = Vector2(side * (size.x * 0.5 - 13.0), 0)
            bolt.polygon = _circle_points(2.4, 10)
            bolt.color = Color(V31_CYAN if moving else V31_STEEL_LIGHT, 0.42)
            bolt.z_index = 6
            skin.add_child(bolt)

    if size.x > 900.0:
        var seams := mini(12, int(size.x / 420.0))
        for i in range(1, seams + 1):
            var x := -size.x * 0.5 + float(i) * size.x / float(seams + 1)
            var seam := Line2D.new()
            seam.width = 1.0
            seam.default_color = Color(V31_STEEL_LIGHT, 0.10)
            seam.points = PackedVector2Array([Vector2(x, -size.y * 0.35), Vector2(x, size.y * 0.35)])
            seam.z_index = 3
            skin.add_child(seam)

func _v31_polish_spikes(area: Area2D, hidden: bool) -> void:
    if not is_instance_valid(area) or area.get_node_or_null("V31SpikeDecor") != null:
        return
    var decor := Node2D.new()
    decor.name = "V31SpikeDecor"
    decor.visible = not hidden
    decor.z_index = 5
    area.add_child(decor)

    for child in area.get_children():
        if child is Polygon2D:
            var tri := child as Polygon2D
            tri.color = V31_RED
            var outline := Line2D.new()
            outline.position = tri.position
            outline.width = 1.4
            outline.closed = true
            outline.default_color = Color(1.0, 0.72, 0.76, 0.52)
            outline.points = tri.polygon
            decor.add_child(outline)

    var base := Line2D.new()
    base.width = 3.0
    base.default_color = Color(V31_RED, 0.28)
    var width := 90.0
    var cs := area.get_child(0) as CollisionShape2D
    if is_instance_valid(cs) and cs.shape is RectangleShape2D:
        width = (cs.shape as RectangleShape2D).size.x
    base.points = PackedVector2Array([Vector2(-width * 0.5, 17), Vector2(width * 0.5, 17)])
    decor.add_child(base)

func _v31_upgrade_player_visual() -> void:
    if not is_instance_valid(player) or player.get_node_or_null("V31PlayerFrame") != null:
        return
    var frame := Node2D.new()
    frame.name = "V31PlayerFrame"
    frame.z_index = 7
    player.add_child(frame)

    var outer := Line2D.new()
    outer.name = "Outer"
    outer.width = 2.2
    outer.closed = true
    outer.default_color = Color(V31_CYAN, 0.82)
    outer.points = PackedVector2Array([
        Vector2(-20.5, -20.5), Vector2(20.5, -20.5), Vector2(20.5, 20.5), Vector2(-20.5, 20.5)
    ])
    frame.add_child(outer)

    var core := Polygon2D.new()
    core.polygon = PackedVector2Array([
        Vector2(-13, 14), Vector2(13, 14), Vector2(9, 18), Vector2(-9, 18)
    ])
    core.color = Color(V31_CYAN if chapter >= 21 else V31_BLUE, 0.52)
    frame.add_child(core)

    var mouth := Line2D.new()
    mouth.width = 1.5
    mouth.default_color = Color(V31_CYAN if chapter >= 21 else V31_BLUE, 0.64)
    mouth.points = PackedVector2Array([Vector2(-5, 8), Vector2(0, 10), Vector2(5, 8)])
    frame.add_child(mouth)

    if v20_effects_enabled:
        var pulse := outer.create_tween().set_loops()
        pulse.tween_property(outer, "modulate:a", 0.56, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        pulse.tween_property(outer, "modulate:a", 1.0, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _v31_find_new_circle_area(before: Dictionary) -> Area2D:
    if not is_instance_valid(world):
        return null
    for child in world.get_children():
        if child is Area2D and not before.has(child.get_instance_id()):
            var area := child as Area2D
            for sub in area.get_children():
                if sub is CollisionShape2D and (sub as CollisionShape2D).shape is CircleShape2D:
                    return area
    return null

func _v31_circle_radius(area: Area2D, fallback: float) -> float:
    for child in area.get_children():
        if child is CollisionShape2D:
            var cs := child as CollisionShape2D
            if cs.shape is CircleShape2D:
                return (cs.shape as CircleShape2D).radius
    return fallback

func _v31_style_boulder(area: Area2D, radius: float, falling: bool) -> void:
    if not is_instance_valid(area) or bool(area.get_meta("v31_boulder", false)):
        return
    area.set_meta("v31_boulder", true)
    area.set_meta("v31_falling", falling)

    var poly: Polygon2D = null
    for child in area.get_children():
        if child is Polygon2D:
            poly = child as Polygon2D
            break
    if is_instance_valid(poly):
        poly.color = V31_ROCK
        var rim := Line2D.new()
        rim.width = 3.0
        rim.closed = true
        rim.default_color = Color(V31_RED, 0.68)
        rim.points = _circle_points(maxf(4.0, radius - 3.0), 28)
        rim.z_index = 3
        poly.add_child(rim)

        var inner := Line2D.new()
        inner.width = 2.0
        inner.closed = true
        inner.default_color = Color(V31_AMBER, 0.18)
        inner.points = _circle_points(radius * 0.62, 22)
        inner.z_index = 2
        poly.add_child(inner)

        for i in range(3):
            var crack := Line2D.new()
            crack.width = 1.6
            crack.default_color = Color(1.0, 0.54, 0.46, 0.34)
            var angle := TAU * float(i) / 3.0 + 0.45
            crack.points = PackedVector2Array([
                Vector2.ZERO,
                Vector2(cos(angle), sin(angle)) * radius * 0.34,
                Vector2(cos(angle + 0.26), sin(angle + 0.26)) * radius * 0.62
            ])
            crack.z_index = 4
            poly.add_child(crack)

    var shadow := Polygon2D.new()
    shadow.name = "V31RockShadow"
    shadow.position = Vector2(7, 10)
    shadow.polygon = _circle_points(radius * 0.92, 24)
    shadow.scale = Vector2(1.0, 0.68)
    shadow.color = Color(V31_ROCK_DARK, 0.30)
    shadow.z_index = -3
    area.add_child(shadow)

func _v31_tick_rocks(delta: float) -> void:
    if v31_rocks.is_empty():
        return
    for id in v31_rocks.keys():
        var state: Dictionary = v31_rocks[id]
        var rock := state.get("node") as Area2D
        if not is_instance_valid(rock):
            v31_rocks.erase(id)
            continue
        var dust_clock := float(state.get("dust", 0.0)) - delta
        if dust_clock <= 0.0:
            dust_clock = 0.12
            if v20_effects_enabled and is_instance_valid(player) and absf(rock.global_position.x - player.global_position.x) < 900.0:
                _v31_rock_dust(rock.global_position, float(state.get("radius", 60.0)), float(state.get("speed", 0.0)))
        state["dust"] = dust_clock

        if not bool(state.get("near_done", false)) and is_instance_valid(player):
            if rock.global_position.distance_to(player.global_position) < float(state.get("radius", 60.0)) + 95.0:
                state["near_done"] = true
                if v20_effects_enabled:
                    _v22_micro_shake(1.6, 0.10)
        v31_rocks[id] = state

func _v31_rock_dust(origin: Vector2, radius: float, speed: float) -> void:
    if not is_instance_valid(world) or not _v27_fx_begin(0.30):
        return
    var direction := -signf(speed)
    if is_zero_approx(direction):
        direction = -1.0
    for i in range(3):
        var bit := Polygon2D.new()
        bit.position = origin + Vector2(direction * radius * 0.55 + float(i) * direction * 7.0, radius * 0.55 + float(i % 2) * 4.0)
        var s := 2.5 + float(i)
        bit.polygon = _circle_points(s, 8)
        bit.color = Color(V31_AMBER, 0.22)
        bit.z_index = 12
        world.add_child(bit)
        var target := bit.position + Vector2(direction * (22.0 + float(i) * 7.0), -10.0 - float(i) * 5.0)
        var tw := bit.create_tween()
        tw.set_parallel(true)
        tw.tween_property(bit, "position", target, 0.26)
        tw.tween_property(bit, "scale", Vector2(1.7, 1.7), 0.26)
        tw.tween_property(bit, "modulate:a", 0.0, 0.26)
        tw.set_parallel(false)
        tw.tween_callback(bit.queue_free)

func _v31_fall_streak(area: Area2D) -> void:
    if not is_instance_valid(area) or not _v27_fx_begin(0.50):
        return
    var streak := Line2D.new()
    streak.name = "V31FallStreak"
    streak.width = 4.0
    streak.default_color = Color(V31_RED, 0.28)
    streak.points = PackedVector2Array([Vector2(0, -110), Vector2(0, -35)])
    streak.z_index = -2
    area.add_child(streak)
    var tw := streak.create_tween()
    tw.tween_property(streak, "modulate:a", 0.0, 0.45)
    tw.tween_callback(streak.queue_free)

func _v31_hazard_snap_fx(origin: Vector2) -> void:
    if not is_instance_valid(world) or not _v27_fx_begin(0.24):
        return
    var flash := Line2D.new()
    flash.position = origin
    flash.width = 3.0
    flash.closed = true
    flash.default_color = Color(V31_RED, 0.52)
    flash.points = _circle_points(22.0, 18)
    flash.scale = Vector2(1.0, 0.35)
    flash.z_index = 20
    world.add_child(flash)
    var tw := flash.create_tween()
    tw.set_parallel(true)
    tw.tween_property(flash, "scale", Vector2(2.35, 0.72), 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tw.tween_property(flash, "modulate:a", 0.0, 0.20)
    tw.set_parallel(false)
    tw.tween_callback(flash.queue_free)

func _v31_mover_activation_fx(origin: Vector2) -> void:
    if not is_instance_valid(world) or not _v27_fx_begin(0.30):
        return
    var pulse := Line2D.new()
    pulse.position = origin
    pulse.width = 2.0
    pulse.closed = true
    pulse.default_color = Color(V31_CYAN, 0.52)
    pulse.points = _circle_points(18.0, 20)
    pulse.scale = Vector2(1.3, 0.35)
    pulse.z_index = 18
    world.add_child(pulse)
    var tw := pulse.create_tween()
    tw.set_parallel(true)
    tw.tween_property(pulse, "scale", Vector2(3.1, 0.65), 0.26)
    tw.tween_property(pulse, "modulate:a", 0.0, 0.26)
    tw.set_parallel(false)
    tw.tween_callback(pulse.queue_free)

func _v31_add_menu_visuals() -> void:
    if not is_instance_valid(hud):
        return
    var badge := Label.new()
    badge.name = "V31MenuBadge"
    badge.position = Vector2(835, 95)
    badge.size = Vector2(350, 32)
    badge.text = "VISUAL OVERHAUL • PHASE 1"
    badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    badge.add_theme_font_size_override("font_size", 12)
    badge.add_theme_color_override("font_color", Color(V31_CYAN, 0.72))
    hud.add_child(badge)

    for i in range(5):
        var line := Line2D.new()
        line.width = 2.0
        line.default_color = Color(V31_PURPLE if i % 2 else V31_CYAN, 0.045 + float(i) * 0.008)
        line.points = PackedVector2Array([
            Vector2(-80 + i * 275, 720),
            Vector2(170 + i * 275, 430),
            Vector2(350 + i * 275, 720)
        ])
        line.z_index = -2
        hud.add_child(line)

func _v31_rect_points(size: Vector2) -> PackedVector2Array:
    return PackedVector2Array([
        Vector2(-size.x * 0.5, -size.y * 0.5),
        Vector2(size.x * 0.5, -size.y * 0.5),
        Vector2(size.x * 0.5, size.y * 0.5),
        Vector2(-size.x * 0.5, size.y * 0.5)
    ])
