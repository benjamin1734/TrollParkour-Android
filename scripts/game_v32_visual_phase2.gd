extends "res://scripts/game_v31_visual.gd"

const V32_WHITE := Color("#f8fbff")
const V32_CYAN := Color("#4de6ff")
const V32_BLUE := Color("#5a8fff")
const V32_PURPLE := Color("#ab7cff")
const V32_GREEN := Color("#4ee6a4")
const V32_AMBER := Color("#ffbd59")
const V32_RED := Color("#ff5d73")
const V32_DARK := Color("#07101d")
const V32_MAX_FINISH_FX := 4

var v32_finish_fx_live := 0
var v32_last_player_x := 0.0
var v32_velocity_lean := 0.0
var v32_level_intro_done := false

func _start_level(c: int, p: int) -> void:
    v32_last_player_x = 0.0
    v32_velocity_lean = 0.0
    v32_level_intro_done = false
    super._start_level(c, p)
    if is_instance_valid(player):
        v32_last_player_x = player.global_position.x
        _v32_apply_player_core_light()
    if is_instance_valid(world):
        _v32_add_light_ribbons()
    if is_instance_valid(hud):
        _v32_level_intro_card()

func _process(delta: float) -> void:
    super._process(delta)
    _v32_update_player_motion(delta)
    _v32_update_environment_breath(delta)

func _show_main_menu() -> void:
    super._show_main_menu()
    if not is_instance_valid(hud):
        return
    for child in hud.get_children():
        if child is Label:
            var label := child as Label
            if label.text == "ANDROID • v3.1":
                label.text = "ANDROID • v3.2"
            elif label.text.begins_with("v3.1 GÖRSEL OVERHAUL"):
                label.text = "v3.2 GÖRSEL OVERHAUL • FAZ 2\n\n• Finish kapısı ve tamamlanma burst sistemi\n• Ölüm impact / vignette / parçacık yükseltmesi\n• Karakter hareket lean ve çekirdek ışığı\n• Atmosferik ışık şeritleri ve kısa bölüm geçişleri"
            elif label.text == "VISUAL OVERHAUL • PHASE 1":
                label.text = "VISUAL OVERHAUL • PHASE 2"
                label.add_theme_color_override("font_color", Color(V32_CYAN, 0.84))
    _v32_menu_glow()

func _build_hud() -> void:
    super._build_hud()
    if not is_instance_valid(hud):
        return
    var left_cap := Line2D.new()
    left_cap.name = "V32HUDAccent"
    left_cap.width = 3.0
    left_cap.default_color = Color(V32_CYAN if chapter >= 21 else V32_BLUE, 0.52)
    left_cap.points = PackedVector2Array([Vector2(18, 67), Vector2(210, 67)])
    left_cap.z_index = 45
    hud.add_child(left_cap)

func _finish(pos: Vector2) -> Area2D:
    var area := super._finish(pos)
    if is_instance_valid(area):
        _v32_style_finish(area)
    return area

func _finish_level() -> void:
    if level_finished or restarting:
        return
    _v32_finish_burst()
    _v32_finish_vignette()
    _v32_camera_kick(Vector2(0.0, -3.0), 0.18)
    super._finish_level()

func _on_player_died() -> void:
    if restarting or level_finished:
        return
    _v32_death_burst()
    _v32_death_vignette()
    _v32_camera_kick(Vector2(-4.0 if is_instance_valid(player) and player.velocity.x >= 0.0 else 4.0, 2.0), 0.16)
    super._on_player_died()

func _v32_style_finish(area: Area2D) -> void:
    if area.get_node_or_null("V32FinishVisual") != null:
        return
    var visual := Node2D.new()
    visual.name = "V32FinishVisual"
    visual.z_index = 12
    area.add_child(visual)

    var shadow := Polygon2D.new()
    shadow.position = Vector2(8, 10)
    shadow.polygon = PackedVector2Array([
        Vector2(-53, -67), Vector2(53, -67), Vector2(53, 67), Vector2(-53, 67)
    ])
    shadow.color = Color(0.01, 0.02, 0.04, 0.22)
    shadow.z_index = -6
    visual.add_child(shadow)

    var frame := Line2D.new()
    frame.name = "Frame"
    frame.width = 4.0
    frame.closed = true
    frame.default_color = Color(V32_GREEN, 0.82)
    frame.points = PackedVector2Array([
        Vector2(-48, 58), Vector2(-48, -58), Vector2(48, -58), Vector2(48, 58)
    ])
    visual.add_child(frame)

    var inner := Line2D.new()
    inner.name = "Inner"
    inner.width = 2.0
    inner.closed = true
    inner.default_color = Color(V32_CYAN if chapter >= 21 else V32_BLUE, 0.42)
    inner.points = PackedVector2Array([
        Vector2(-39, 50), Vector2(-39, -50), Vector2(39, -50), Vector2(39, 50)
    ])
    visual.add_child(inner)

    var top_bar := Line2D.new()
    top_bar.width = 5.0
    top_bar.default_color = Color(V32_WHITE, 0.26)
    top_bar.points = PackedVector2Array([Vector2(-33, -50), Vector2(33, -50)])
    visual.add_child(top_bar)

    var core := Polygon2D.new()
    core.name = "Core"
    core.position = Vector2(0, -2)
    core.polygon = _circle_points(11.0, 18)
    core.color = Color(V32_GREEN, 0.32)
    visual.add_child(core)

    var core_ring := Line2D.new()
    core_ring.width = 2.0
    core_ring.closed = true
    core_ring.default_color = Color(V32_GREEN, 0.68)
    core_ring.points = _circle_points(18.0, 22)
    visual.add_child(core_ring)

    for side in [-1.0, 1.0]:
        var foot := Line2D.new()
        foot.width = 4.0
        foot.default_color = Color(V32_GREEN, 0.48)
        foot.points = PackedVector2Array([
            Vector2(side * 48.0, 54.0), Vector2(side * 59.0, 62.0)
        ])
        visual.add_child(foot)

    if v20_effects_enabled:
        var pulse := core_ring.create_tween().set_loops()
        pulse.tween_property(core_ring, "scale", Vector2(1.22, 1.22), 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        pulse.tween_property(core_ring, "scale", Vector2.ONE, 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        var glow := frame.create_tween().set_loops()
        glow.tween_property(frame, "modulate:a", 0.58, 0.90).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        glow.tween_property(frame, "modulate:a", 1.0, 0.90).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _v32_finish_burst() -> void:
    if not v20_effects_enabled or not is_instance_valid(player) or not is_instance_valid(world):
        return
    if v32_finish_fx_live >= V32_MAX_FINISH_FX or not _v27_fx_begin(0.55):
        return
    v32_finish_fx_live += 1
    var timer := get_tree().create_timer(0.62)
    timer.timeout.connect(func(): v32_finish_fx_live = maxi(0, v32_finish_fx_live - 1))
    var origin := player.global_position

    for radius in [22.0, 38.0, 56.0]:
        var ring := Line2D.new()
        ring.position = origin
        ring.width = 3.0 if radius < 40.0 else 2.0
        ring.closed = true
        ring.default_color = Color(V32_GREEN if radius < 50.0 else V32_CYAN, 0.62)
        ring.points = _circle_points(radius, 28)
        ring.z_index = 70
        world.add_child(ring)
        ring.scale = Vector2(0.45, 0.45)
        var tw := ring.create_tween()
        tw.set_parallel(true)
        tw.tween_property(ring, "scale", Vector2(1.65, 1.65), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tw.tween_property(ring, "modulate:a", 0.0, 0.42)
        tw.set_parallel(false)
        tw.tween_callback(ring.queue_free)

    for i in range(12):
        var spark := Polygon2D.new()
        spark.position = origin
        var s := 2.5 + float(i % 3)
        spark.polygon = _circle_points(s, 8)
        spark.color = V32_GREEN if i % 3 != 0 else V32_CYAN
        spark.z_index = 72
        world.add_child(spark)
        var angle := TAU * float(i) / 12.0 + 0.12 * float(i % 2)
        var distance := 62.0 + float((i * 13) % 45)
        var target := origin + Vector2(cos(angle), sin(angle)) * distance
        var tw := spark.create_tween()
        tw.set_parallel(true)
        tw.tween_property(spark, "position", target, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tw.tween_property(spark, "scale", Vector2(0.25, 0.25), 0.38)
        tw.tween_property(spark, "modulate:a", 0.0, 0.38)
        tw.set_parallel(false)
        tw.tween_callback(spark.queue_free)

func _v32_death_burst() -> void:
    if not v20_effects_enabled or not is_instance_valid(player) or not is_instance_valid(world):
        return
    if not _v27_fx_begin(0.34):
        return
    var origin := player.global_position
    var ring := Line2D.new()
    ring.position = origin
    ring.width = 4.0
    ring.closed = true
    ring.default_color = Color(V32_RED, 0.66)
    ring.points = _circle_points(22.0, 22)
    ring.z_index = 75
    world.add_child(ring)
    var rt := ring.create_tween()
    rt.set_parallel(true)
    rt.tween_property(ring, "scale", Vector2(2.9, 2.9), 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    rt.tween_property(ring, "modulate:a", 0.0, 0.26)
    rt.set_parallel(false)
    rt.tween_callback(ring.queue_free)

    for i in range(8):
        var slash := Line2D.new()
        slash.position = origin
        slash.width = 2.2
        slash.default_color = Color(V32_RED if i % 2 == 0 else V32_AMBER, 0.55)
        var angle := TAU * float(i) / 8.0
        var a := Vector2(cos(angle), sin(angle))
        slash.points = PackedVector2Array([a * 22.0, a * 62.0])
        slash.z_index = 74
        world.add_child(slash)
        var st := slash.create_tween()
        st.set_parallel(true)
        st.tween_property(slash, "scale", Vector2(1.45, 1.45), 0.24)
        st.tween_property(slash, "modulate:a", 0.0, 0.24)
        st.set_parallel(false)
        st.tween_callback(slash.queue_free)

func _v32_finish_vignette() -> void:
    _v32_screen_flash(Color(V32_GREEN, 0.12), 0.30, "V32FinishVignette")

func _v32_death_vignette() -> void:
    _v32_screen_flash(Color(V32_RED, 0.18), 0.22, "V32DeathVignette")

func _v32_screen_flash(color: Color, duration: float, node_name: String) -> void:
    if not v20_effects_enabled or not is_instance_valid(hud) or not _v27_fx_begin(duration + 0.05):
        return
    var flash := ColorRect.new()
    flash.name = node_name
    flash.position = Vector2.ZERO
    flash.size = Vector2(1280, 720)
    flash.color = color
    flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    flash.z_index = 180
    hud.add_child(flash)
    var tw := flash.create_tween()
    tw.tween_property(flash, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tw.tween_callback(flash.queue_free)

func _v32_camera_kick(offset: Vector2, duration: float) -> void:
    if not v20_effects_enabled or not is_instance_valid(camera):
        return
    var start := camera.offset
    var tw := camera.create_tween()
    tw.tween_property(camera, "offset", start + offset, duration * 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tw.tween_property(camera, "offset", start, duration * 0.66).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _v32_apply_player_core_light() -> void:
    if not is_instance_valid(player) or player.get_node_or_null("V32CoreLight") != null:
        return
    var glow := Line2D.new()
    glow.name = "V32CoreLight"
    glow.width = 3.0
    glow.closed = true
    glow.default_color = Color(V32_CYAN if chapter >= 21 else V32_BLUE, 0.20)
    glow.points = PackedVector2Array([
        Vector2(-24, -24), Vector2(24, -24), Vector2(24, 24), Vector2(-24, 24)
    ])
    glow.z_index = 5
    player.add_child(glow)
    if v20_effects_enabled:
        var tw := glow.create_tween().set_loops()
        tw.tween_property(glow, "scale", Vector2(1.08, 1.08), 0.82).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        tw.tween_property(glow, "scale", Vector2.ONE, 0.82).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _v32_update_player_motion(delta: float) -> void:
    if not is_instance_valid(player):
        return
    var frame := player.get_node_or_null("V31PlayerFrame") as Node2D
    if not is_instance_valid(frame):
        return
    var desired := clampf(player.velocity.x / 9000.0, -0.045, 0.045)
    v32_velocity_lean = lerpf(v32_velocity_lean, desired, clampf(delta * 8.0, 0.0, 1.0))
    frame.rotation = v32_velocity_lean
    v32_last_player_x = player.global_position.x

func _v32_add_light_ribbons() -> void:
    if not is_instance_valid(v31_environment) or v31_environment.get_node_or_null("V32LightRibbons") != null:
        return
    var layer := Node2D.new()
    layer.name = "V32LightRibbons"
    layer.z_index = -4
    v31_environment.add_child(layer)
    var dark := chapter >= 21
    var count := maxi(4, int(level_width / 1100.0) + 2)
    for i in range(count):
        var x := 260.0 + float(i) * 1100.0
        var ribbon := Line2D.new()
        ribbon.width = 10.0 if dark else 7.0
        ribbon.default_color = Color(V32_PURPLE if dark and i % 2 else V32_CYAN, 0.035 if dark else 0.022)
        ribbon.points = PackedVector2Array([
            Vector2(x - 180, 170 + float((i * 37) % 95)),
            Vector2(x, 115 + float((i * 53) % 80)),
            Vector2(x + 190, 205 + float((i * 29) % 110))
        ])
        layer.add_child(ribbon)

func _v32_update_environment_breath(_delta: float) -> void:
    if not is_instance_valid(v31_environment):
        return
    var ribbons := v31_environment.get_node_or_null("V32LightRibbons") as Node2D
    if not is_instance_valid(ribbons):
        return
    var alpha := 0.86 + sin(v31_environment_phase * 0.72) * 0.10
    ribbons.modulate.a = alpha if v20_effects_enabled else 0.92

func _v32_level_intro_card() -> void:
    if v32_level_intro_done or not is_instance_valid(hud):
        return
    v32_level_intro_done = true
    var card := ColorRect.new()
    card.name = "V32IntroCard"
    card.position = Vector2(500, 84)
    card.size = Vector2(280, 42)
    card.color = Color(V32_DARK, 0.74)
    card.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.z_index = 100
    hud.add_child(card)
    var label := Label.new()
    label.position = Vector2.ZERO
    label.size = card.size
    label.text = "BÖLÜM %d-%d" % [chapter, part]
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 15)
    label.add_theme_color_override("font_color", V32_WHITE)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_child(label)
    card.modulate.a = 0.0
    var tw := card.create_tween()
    tw.tween_property(card, "modulate:a", 1.0, 0.10)
    tw.tween_interval(0.34)
    tw.tween_property(card, "modulate:a", 0.0, 0.18)
    tw.tween_callback(card.queue_free)

func _v32_menu_glow() -> void:
    if not is_instance_valid(hud) or hud.get_node_or_null("V32MenuGlow") != null:
        return
    var line := Line2D.new()
    line.name = "V32MenuGlow"
    line.width = 5.0
    line.default_color = Color(V32_CYAN, 0.10)
    line.points = PackedVector2Array([Vector2(210, 130), Vector2(1070, 130)])
    line.z_index = 3
    hud.add_child(line)
