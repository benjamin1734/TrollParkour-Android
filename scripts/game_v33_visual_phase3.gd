extends "res://scripts/game_v32_visual_phase2.gd"

const V33_SKY := Color("#8fd8ff")
const V33_ICE := Color("#a8d8ff")
const V33_STEEL := Color("#7390b8")
const V33_CYAN := Color("#50e8ff")
const V33_BLUE := Color("#6199ff")
const V33_PURPLE := Color("#b07cff")
const V33_AMBER := Color("#ffc86a")
const V33_RED := Color("#ff6078")
const V33_GREEN := Color("#54e6ad")
const V33_MAX_AMBIENT_MOTES := 14
const V33_MAX_LIGHT_SHAFTS := 7

var v33_atmosphere: Node2D
var v33_grade: ColorRect
var v33_fog_lines: Array[Line2D] = []
var v33_light_shafts: Array[Polygon2D] = []
var v33_speed_streaks: Array[Line2D] = []
var v33_phase := 0.0
var v33_last_risk := -1

func _start_level(c: int, p: int) -> void:
    v33_atmosphere = null
    v33_grade = null
    v33_fog_lines.clear()
    v33_light_shafts.clear()
    v33_speed_streaks.clear()
    v33_phase = 0.0
    v33_last_risk = -1
    super._start_level(c, p)
    _v33_apply_theme_clear_color()
    _v33_build_atmosphere()
    _v33_build_screen_grade()
    _v33_upgrade_player_shadow()

func _process(delta: float) -> void:
    super._process(delta)
    v33_phase += delta
    _v33_update_atmosphere()
    _v33_update_grade()
    _v33_update_speed_streaks()
    _v33_update_player_shadow()

func _show_main_menu() -> void:
    super._show_main_menu()
    if not is_instance_valid(hud):
        return
    for child in hud.get_children():
        if child is Label:
            var label := child as Label
            if label.text == "ANDROID • v3.2":
                label.text = "ANDROID • v3.3"
            elif label.text.begins_with("v3.2 GÖRSEL OVERHAUL"):
                label.text = "v3.3 GÖRSEL OVERHAUL • FAZ 3\n\n• Üç dönemli tema / atmosfer sistemi\n• Hacimsel sis ve ışık huzmesi hissi\n• Risk seviyesine tepki veren çevresel renk dili\n• Hız çizgileri, zemin gölgesi ve ambient derinlik"
            elif label.text == "VISUAL OVERHAUL • PHASE 2":
                label.text = "VISUAL OVERHAUL • PHASE 3"
                label.add_theme_color_override("font_color", Color(V33_PURPLE, 0.86))
    _v33_add_menu_atmosphere()

func _build_hud() -> void:
    super._build_hud()
    if not is_instance_valid(hud):
        return
    var theme_tag := Label.new()
    theme_tag.name = "V33ThemeTag"
    theme_tag.position = Vector2(910, 46)
    theme_tag.size = Vector2(180, 18)
    theme_tag.text = _v33_theme_name()
    theme_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    theme_tag.add_theme_font_size_override("font_size", 9)
    theme_tag.add_theme_color_override("font_color", Color(_v33_theme_accent(), 0.62))
    theme_tag.z_index = 48
    hud.add_child(theme_tag)

func _v33_theme_band() -> int:
    if chapter <= 10:
        return 0
    if chapter <= 20:
        return 1
    return 2

func _v33_theme_name() -> String:
    var band := _v33_theme_band()
    if band == 0:
        return "TEMİZ / KLASİK"
    if band == 1:
        return "ÇELİK / ALACAKARANLIK"
    return "NEON / KARANLIK"

func _v33_theme_accent() -> Color:
    var band := _v33_theme_band()
    if band == 0:
        return V33_BLUE
    if band == 1:
        return V33_ICE
    return V33_CYAN

func _v33_apply_theme_clear_color() -> void:
    var band := _v33_theme_band()
    if band == 0:
        RenderingServer.set_default_clear_color(Color("#e9f4fb"))
    elif band == 1:
        RenderingServer.set_default_clear_color(Color("#151d2a"))
    else:
        RenderingServer.set_default_clear_color(Color("#030611"))

func _v33_build_atmosphere() -> void:
    if not is_instance_valid(world):
        return
    v33_atmosphere = Node2D.new()
    v33_atmosphere.name = "V33Atmosphere"
    v33_atmosphere.z_index = -90
    v33_atmosphere.set_meta("theme_band", _v33_theme_band())
    world.add_child(v33_atmosphere)
    _v33_build_horizon_glow()
    _v33_build_fog_banks()
    _v33_build_light_shafts()
    _v33_build_ambient_motes()
    _v33_build_speed_streaks()

func _v33_build_horizon_glow() -> void:
    if not is_instance_valid(v33_atmosphere):
        return
    var accent := _v33_theme_accent()
    var band := _v33_theme_band()
    for i in range(4):
        var line := Line2D.new()
        line.name = "Horizon%d" % i
        line.width = 10.0 + float(i) * 15.0
        line.default_color = Color(accent, (0.026 if band < 2 else 0.038) / float(i + 1))
        var y := 560.0 - float(i) * 34.0
        line.points = PackedVector2Array([Vector2(-250, y), Vector2(level_width + 250, y - 12.0)])
        v33_atmosphere.add_child(line)

func _v33_build_fog_banks() -> void:
    if not is_instance_valid(v33_atmosphere):
        return
    var band := _v33_theme_band()
    var accent := V33_SKY if band == 0 else (V33_STEEL if band == 1 else V33_PURPLE)
    for i in range(3):
        var fog := Line2D.new()
        fog.name = "FogBank%d" % i
        fog.width = 46.0 + float(i) * 19.0
        fog.default_color = Color(accent, 0.025 + float(i) * 0.006)
        var y := 505.0 + float(i) * 48.0
        fog.points = PackedVector2Array([Vector2(-300, y), Vector2(level_width * 0.24, y - 18.0), Vector2(level_width * 0.52, y + 11.0), Vector2(level_width * 0.78, y - 14.0), Vector2(level_width + 300, y + 4.0)])
        fog.z_index = -7 + i
        v33_atmosphere.add_child(fog)
        v33_fog_lines.append(fog)

func _v33_build_light_shafts() -> void:
    if not is_instance_valid(v33_atmosphere):
        return
    var band := _v33_theme_band()
    var count := mini(V33_MAX_LIGHT_SHAFTS, maxi(3, int(level_width / 1500.0) + 2))
    var accent := V33_SKY if band == 0 else (V33_ICE if band == 1 else V33_CYAN)
    for i in range(count):
        var shaft := Polygon2D.new()
        shaft.name = "LightShaft%d" % i
        var x := 520.0 + float(i) * maxf(760.0, level_width / maxf(1.0, float(count)))
        shaft.position = Vector2(x, 280.0 + float((i * 37) % 90))
        var top_w := 18.0 + float(i % 3) * 8.0
        var bottom_w := 70.0 + float(i % 4) * 18.0
        shaft.polygon = PackedVector2Array([Vector2(-top_w, -250), Vector2(top_w, -250), Vector2(bottom_w, 300), Vector2(-bottom_w, 300)])
        shaft.color = Color(accent, 0.022 if band < 2 else 0.032)
        shaft.z_index = -10
        v33_atmosphere.add_child(shaft)
        v33_light_shafts.append(shaft)

func _v33_build_ambient_motes() -> void:
    if not is_instance_valid(v33_atmosphere):
        return
    var count := V33_MAX_AMBIENT_MOTES if v20_effects_enabled else 7
    var accent := _v33_theme_accent()
    for i in range(count):
        var mote := Polygon2D.new()
        mote.name = "AmbientMote%d" % i
        var x := 130.0 + float(i) * (level_width / maxf(1.0, float(count)))
        mote.position = Vector2(x, 120.0 + float((i * 79) % 430))
        var radius := 1.4 + float(i % 4) * 0.65
        mote.polygon = _circle_points(radius, 8)
        mote.color = Color(accent, 0.11 if _v33_theme_band() < 2 else 0.16)
        mote.z_index = -2
        v33_atmosphere.add_child(mote)
        if v20_effects_enabled:
            var base_y := mote.position.y
            var drift := 10.0 + float((i * 13) % 22)
            var tw := mote.create_tween().set_loops()
            tw.tween_property(mote, "position:y", base_y - drift, 3.2 + float(i % 4) * 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
            tw.tween_property(mote, "position:y", base_y, 3.2 + float(i % 4) * 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _v33_build_speed_streaks() -> void:
    if not is_instance_valid(v33_atmosphere):
        return
    var accent := _v33_theme_accent()
    for i in range(5):
        var streak := Line2D.new()
        streak.name = "SpeedStreak%d" % i
        streak.width = 1.5 + float(i % 2)
        streak.default_color = Color(accent, 0.0)
        streak.points = PackedVector2Array([Vector2(-52, 0), Vector2(52, 0)])
        streak.position = Vector2(0, 170.0 + float(i) * 83.0)
        streak.z_index = 6
        v33_atmosphere.add_child(streak)
        v33_speed_streaks.append(streak)

func _v33_build_screen_grade() -> void:
    if not is_instance_valid(hud):
        return
    v33_grade = ColorRect.new()
    v33_grade.name = "V33ScreenGrade"
    v33_grade.position = Vector2.ZERO
    v33_grade.size = Vector2(1280, 720)
    v33_grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    v33_grade.z_index = -30
    var band := _v33_theme_band()
    if band == 0:
        v33_grade.color = Color(V33_SKY, 0.018)
    elif band == 1:
        v33_grade.color = Color(V33_STEEL, 0.040)
    else:
        v33_grade.color = Color(V33_PURPLE, 0.052)
    hud.add_child(v33_grade)

func _v33_update_atmosphere() -> void:
    if not is_instance_valid(camera):
        return
    var cx := camera.position.x
    if is_instance_valid(v33_atmosphere):
        v33_atmosphere.position.x = cx * 0.006
    for i in range(v33_fog_lines.size()):
        var fog := v33_fog_lines[i]
        if not is_instance_valid(fog):
            continue
        var wave := sin(v33_phase * (0.24 + float(i) * 0.05) + float(i) * 1.7)
        fog.position.x = wave * (15.0 + float(i) * 7.0)
        fog.modulate.a = 0.82 + 0.18 * sin(v33_phase * 0.31 + float(i))
    for i in range(v33_light_shafts.size()):
        var shaft := v33_light_shafts[i]
        if not is_instance_valid(shaft):
            continue
        shaft.rotation = sin(v33_phase * 0.18 + float(i)) * 0.012
        shaft.modulate.a = 0.78 + 0.22 * sin(v33_phase * 0.34 + float(i) * 0.8)

func _v33_update_grade() -> void:
    if not is_instance_valid(v33_grade):
        return
    var risk := clampi(v28_risk_level, 0, 3)
    var band := _v33_theme_band()
    var base := V33_SKY if band == 0 else (V33_STEEL if band == 1 else V33_PURPLE)
    var alpha := 0.018 if band == 0 else (0.040 if band == 1 else 0.052)
    if risk == 1:
        base = base.lerp(V33_GREEN, 0.18)
        alpha += 0.008
    elif risk == 2:
        base = base.lerp(V33_AMBER, 0.28)
        alpha += 0.018
    elif risk >= 3:
        base = base.lerp(V33_RED, 0.42)
        alpha += 0.030
    v33_last_risk = risk
    var pulse := 1.0
    if risk >= 2:
        pulse = 0.88 + 0.12 * sin(v33_phase * 6.0)
    v33_grade.color = Color(base, alpha * pulse)

func _v33_update_speed_streaks() -> void:
    if v33_speed_streaks.is_empty() or not is_instance_valid(player) or not is_instance_valid(camera):
        return
    var speed_ratio := clampf(absf(player.velocity.x) / 330.0, 0.0, 1.0)
    var alpha := 0.0
    if v20_effects_enabled and speed_ratio > 0.72:
        alpha = (speed_ratio - 0.72) / 0.28 * 0.085
    var direction := -signf(player.velocity.x)
    if is_zero_approx(direction):
        direction = -1.0
    for i in range(v33_speed_streaks.size()):
        var streak := v33_speed_streaks[i]
        if not is_instance_valid(streak):
            continue
        streak.default_color = Color(_v33_theme_accent(), alpha * (0.70 + float(i) * 0.06))
        streak.scale.x = 0.65 + speed_ratio * 0.75
        streak.position.x = camera.position.x + direction * (420.0 + float(i) * 105.0)

func _v33_upgrade_player_shadow() -> void:
    if not is_instance_valid(player) or player.get_node_or_null("V33GroundShadow") != null:
        return
    var shadow := Polygon2D.new()
    shadow.name = "V33GroundShadow"
    shadow.position = Vector2(0, 24)
    shadow.polygon = _circle_points(18.0, 20)
    shadow.scale = Vector2(1.25, 0.28)
    shadow.color = Color(0.0, 0.0, 0.0, 0.22)
    shadow.z_index = -8
    player.add_child(shadow)

func _v33_update_player_shadow() -> void:
    if not is_instance_valid(player):
        return
    var shadow := player.get_node_or_null("V33GroundShadow") as Polygon2D
    if not is_instance_valid(shadow):
        return
    var air := absf(player.velocity.y)
    var scale_drop := clampf(air / 900.0, 0.0, 0.50)
    shadow.scale = Vector2(1.25 - scale_drop * 0.35, 0.28 - scale_drop * 0.08)
    shadow.modulate.a = 1.0 - scale_drop * 0.45

func _v33_add_menu_atmosphere() -> void:
    if not is_instance_valid(hud) or hud.get_node_or_null("V33MenuAtmosphere") != null:
        return
    var layer := Control.new()
    layer.name = "V33MenuAtmosphere"
    layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.z_index = -10
    hud.add_child(layer)
    for i in range(8):
        var line := Line2D.new()
        line.width = 18.0 + float(i) * 3.0
        line.default_color = Color(V33_PURPLE if i % 2 else V33_CYAN, 0.018 + float(i) * 0.002)
        var y := 130.0 + float(i) * 72.0
        line.points = PackedVector2Array([Vector2(-80, y), Vector2(1360, y - 35.0)])
        layer.add_child(line)
