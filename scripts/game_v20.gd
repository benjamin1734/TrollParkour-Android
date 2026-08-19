extends "res://scripts/game_v19.gd"

const V20_BG := Color("#e9eef5")
const V20_BG_CH18 := Color("#e5edf3")
const V20_INK := Color("#0f172a")
const V20_SLATE := Color("#334155")
const V20_MUTED := Color("#64748b")
const V20_BLUE := Color("#2563eb")
const V20_CYAN := Color("#0891b2")
const V20_GREEN := Color("#16a34a")
const V20_AMBER := Color("#d97706")
const V20_RED := Color("#dc4455")
const V20_PURPLE := Color("#7c3aed")
const V20_SOFT := Color("#cbd5e1")

var v20_effects_enabled := true
var v20_was_on_floor := false

func _safe_load_progress() -> void:
    super._safe_load_progress()
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return
    var stored_unlock = cfg.get_value("progress", "unlocked_chapter", 1)
    if stored_unlock is int or stored_unlock is float:
        unlocked_chapter = clampi(int(stored_unlock), 1, 19)
    v20_effects_enabled = bool(cfg.get_value("settings", "effects_enabled", true))

func _save_v20_settings() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return
    cfg.set_value("settings", "effects_enabled", v20_effects_enabled)
    cfg.save(SAVE_PATH)

func _toggle_v20_effects() -> void:
    v20_effects_enabled = not v20_effects_enabled
    _save_v20_settings()
    _show_main_menu()

func _start_level(c: int, p: int) -> void:
    super._start_level(c, p)
    if c == 18:
        RenderingServer.set_default_clear_color(V20_BG_CH18)
        _add_chapter18_decor()
    _v20_add_global_environment()
    v20_was_on_floor = false
    if is_instance_valid(player) and not player.jumped.is_connected(_on_v20_jump):
        player.jumped.connect(_on_v20_jump)

func _process(delta: float) -> void:
    super._process(delta)
    if not is_instance_valid(player) or not player.alive:
        v20_was_on_floor = false
        return
    var grounded := player.is_on_floor()
    if grounded and not v20_was_on_floor and v20_effects_enabled:
        _v20_land_fx()
    v20_was_on_floor = grounded

func _build_level(c: int, p: int) -> void:
    if c == 18 and p == 1:
        _level_18_1()
    elif c == 18 and p == 2:
        _level_18_2()
    elif c == 18 and p == 3:
        _level_18_3()
    else:
        super._build_level(c, p)

func _build_hud() -> void:
    super._build_hud()
    var accent := ColorRect.new()
    accent.position = Vector2(0, 68)
    accent.size = Vector2(1280, 3)
    accent.color = Color(0.03, 0.57, 0.70, 0.65)
    accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(accent)

    var chip := Label.new()
    chip.position = Vector2(520, 18)
    chip.size = Vector2(230, 34)
    chip.text = "EFEKTLER %s" % ("AÇIK" if v20_effects_enabled else "KAPALI")
    chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    chip.add_theme_font_size_override("font_size", 14)
    chip.add_theme_color_override("font_color", V20_CYAN if v20_effects_enabled else V20_MUTED)
    hud.add_child(chip)

    if chapter == 18:
        var mode := Label.new()
        mode.position = Vector2(735, 18)
        mode.size = Vector2(260, 34)
        mode.text = "AKIŞ / ZİNCİR"
        mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        mode.add_theme_font_size_override("font_size", 16)
        mode.add_theme_color_override("font_color", V20_PURPLE)
        hud.add_child(mode)

func _touch_button(action: String, center: Vector2, size: Vector2, text: String) -> void:
    var panel := Panel.new()
    panel.position = center - size / 2.0
    panel.size = size
    panel.pivot_offset = size / 2.0
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.05, 0.08, 0.13, 0.22)
    style.border_color = Color(0.08, 0.57, 0.69, 0.28)
    style.set_border_width_all(2)
    style.corner_radius_top_left = 20
    style.corner_radius_top_right = 20
    style.corner_radius_bottom_left = 20
    style.corner_radius_bottom_right = 20
    style.shadow_color = Color(0, 0, 0, 0.14)
    style.shadow_size = 8
    panel.add_theme_stylebox_override("panel", style)
    hud.add_child(panel)

    var label := Label.new()
    label.position = center - Vector2(size.x / 2.0, 24)
    label.size = Vector2(size.x, 48)
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 25 if text == "ZIPLA" else 34)
    label.add_theme_color_override("font_color", Color(0.04, 0.08, 0.13, 0.82))
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(label)

    var touch := TouchScreenButton.new()
    touch.action = action
    touch.position = center
    touch.visibility_mode = TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
    var shape := RectangleShape2D.new()
    shape.size = size
    touch.shape = shape
    hud.add_child(touch)

    touch.pressed.connect(func():
        panel.scale = Vector2(0.94, 0.94)
        panel.modulate = Color(0.82, 0.95, 1.0, 1.0)
        label.modulate = Color(0.10, 0.54, 0.67, 1.0)
    )
    touch.released.connect(func():
        var tw := create_tween()
        tw.set_parallel(true)
        tw.tween_property(panel, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tw.tween_property(panel, "modulate", Color.WHITE, 0.12)
        tw.tween_property(label, "modulate", Color.WHITE, 0.12)
    )

func _show_main_menu() -> void:
    active_map_key = ""
    timer_label = null
    RenderingServer.set_default_clear_color(V20_BG)
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
    bg.color = V20_BG
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(bg)

    var band_a := ColorRect.new()
    band_a.position = Vector2(0, 0)
    band_a.size = Vector2(1280, 110)
    band_a.color = V20_INK
    band_a.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(band_a)

    var glow := ColorRect.new()
    glow.position = Vector2(0, 107)
    glow.size = Vector2(1280, 4)
    glow.color = V20_CYAN
    glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(glow)

    var version := Label.new()
    version.position = Vector2(26, 24)
    version.size = Vector2(260, 34)
    version.text = "ANDROID • v2.0"
    version.add_theme_font_size_override("font_size", 19)
    version.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(version)

    var badge := Label.new()
    badge.position = Vector2(26, 57)
    badge.size = Vector2(320, 28)
    badge.text = "GÖRSEL / EFEKT YENİLEMESİ"
    badge.add_theme_font_size_override("font_size", 13)
    badge.add_theme_color_override("font_color", Color(0.55, 0.90, 0.96, 1.0))
    hud.add_child(badge)

    var records := Label.new()
    records.position = Vector2(910, 34)
    records.size = Vector2(340, 42)
    records.text = "REKOR KAYDI  %d / 54" % best_times_ms.size()
    records.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    records.add_theme_font_size_override("font_size", 17)
    records.add_theme_color_override("font_color", Color(1, 1, 1, 0.76))
    hud.add_child(records)

    var title := Label.new()
    title.position = Vector2(110, 142)
    title.size = Vector2(650, 100)
    title.text = "TROLL\nPARKOUR"
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 54)
    title.add_theme_color_override("font_color", V20_INK)
    hud.add_child(title)

    var subtitle := Label.new()
    subtitle.position = Vector2(115, 248)
    subtitle.size = Vector2(620, 62)
    subtitle.text = "Bölüm 18: Öğrendiğin sistemleri tek bir akış içinde zincirle."
    subtitle.add_theme_font_size_override("font_size", 19)
    subtitle.add_theme_color_override("font_color", V20_MUTED)
    hud.add_child(subtitle)

    var available := maxi(1, mini(unlocked_chapter, 18))
    var completed_maps := maxi(0, (mini(unlocked_chapter, 19) - 1) * 3)

    var stat_panel := Panel.new()
    stat_panel.position = Vector2(790, 145)
    stat_panel.size = Vector2(390, 170)
    stat_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stat_panel.add_theme_stylebox_override("panel", _v20_panel_style(Color(1, 1, 1, 0.76), Color(0.40, 0.50, 0.62, 0.18), 22))
    hud.add_child(stat_panel)

    var stat := Label.new()
    stat.position = Vector2(820, 170)
    stat.size = Vector2(330, 115)
    stat.text = "AÇIK BÖLÜM   %d / 18\nHARİTA        %d / 54\nTOPLAM ÖLÜM   %d" % [available, completed_maps, deaths]
    stat.add_theme_font_size_override("font_size", 18)
    stat.add_theme_color_override("font_color", V20_SLATE)
    hud.add_child(stat)

    var content_label := Label.new()
    content_label.position = Vector2(115, 326)
    content_label.size = Vector2(620, 30)
    content_label.text = "İÇERİK ÜRETİMİ  54 / 300"
    content_label.add_theme_font_size_override("font_size", 15)
    content_label.add_theme_color_override("font_color", V20_MUTED)
    hud.add_child(content_label)

    var bar_bg := ColorRect.new()
    bar_bg.position = Vector2(115, 362)
    bar_bg.size = Vector2(620, 10)
    bar_bg.color = Color(0.38, 0.45, 0.55, 0.16)
    hud.add_child(bar_bg)
    var bar_fill := ColorRect.new()
    bar_fill.position = Vector2(115, 362)
    bar_fill.size = Vector2(620.0 * 54.0 / 300.0, 10)
    bar_fill.color = V20_CYAN
    hud.add_child(bar_fill)

    _menu_button("DEVAM ET", Vector2(790, 350), Vector2(390, 66), func(): _start_level(maxi(1, mini(unlocked_chapter, 18)), 1))
    _menu_button("BÖLÜMLER", Vector2(790, 430), Vector2(390, 66), func(): _show_chapter_select())
    _menu_button("1. BÖLÜMDEN BAŞLA", Vector2(790, 510), Vector2(390, 66), func(): _start_level(1, 1))
    _menu_button("EFEKTLER: %s" % ("AÇIK" if v20_effects_enabled else "KAPALI"), Vector2(790, 590), Vector2(390, 58), func(): _toggle_v20_effects())

    var feature := Label.new()
    feature.position = Vector2(115, 420)
    feature.size = Vector2(590, 190)
    feature.text = "v2.0 YENİLİKLER\n\n• Zıplama ve iniş efektleri\n• Dokunmatik tuş geri bildirimi\n• Katmanlı çevre tasarımı\n• Efekt performans anahtarı"
    feature.add_theme_font_size_override("font_size", 17)
    feature.add_theme_color_override("font_color", V20_SLATE)
    hud.add_child(feature)

func _show_chapter_select() -> void:
    timer_label = null
    RenderingServer.set_default_clear_color(V20_BG)
    if is_instance_valid(hud):
        hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)

    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V20_BG
    hud.add_child(bg)

    var top := ColorRect.new()
    top.size = Vector2(1280, 82)
    top.color = V20_INK
    hud.add_child(top)

    var title := Label.new()
    title.position = Vector2(70, 18)
    title.size = Vector2(500, 46)
    title.text = "BÖLÜM SEÇ"
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(title)

    var info := Label.new()
    info.position = Vector2(720, 24)
    info.size = Vector2(490, 36)
    info.text = "18 BÖLÜM • 54 HARİTA"
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    info.add_theme_font_size_override("font_size", 17)
    info.add_theme_color_override("font_color", Color(1, 1, 1, 0.72))
    hud.add_child(info)

    for i in range(1, 19):
        var chapter_id := i
        var is_unlocked := chapter_id <= unlocked_chapter
        var col := (i - 1) % 4
        var row := int((i - 1) / 4)
        var pos := Vector2(55 + col * 300, 105 + row * 76)
        var suffix := "3 HARİTA"
        if chapter_id == 5: suffix = "HAFIZA"
        elif chapter_id == 6: suffix = "HAREKET"
        elif chapter_id == 7: suffix = "GÜVEN"
        elif chapter_id == 8: suffix = "ZAMAN"
        elif chapter_id == 9: suffix = "ROTA"
        elif chapter_id == 10: suffix = "MİNİ FİNAL"
        elif chapter_id == 11: suffix = "REAKTİF"
        elif chapter_id == 12: suffix = "TEMPO"
        elif chapter_id == 13: suffix = "KAYAN GÜVEN"
        elif chapter_id == 14: suffix = "ALGI"
        elif chapter_id == 15: suffix = "SES"
        elif chapter_id == 16: suffix = "GİRDİ"
        elif chapter_id == 17: suffix = "ALIŞKANLIK"
        elif chapter_id == 18: suffix = "AKIŞ"
        var button_text := "BÖLÜM %d\n%s" % [chapter_id, suffix] if is_unlocked else "BÖLÜM %d\nKİLİTLİ" % chapter_id
        var button := _menu_button(button_text, pos, Vector2(270, 58), func(): _start_level(chapter_id, 1))
        button.disabled = not is_unlocked

    var note := Label.new()
    note.position = Vector2(145, 505)
    note.size = Vector2(990, 40)
    note.text = "v2.0: Menü, HUD, dokunmatik kontroller ve hareket efektleri tüm bölümlerde yenilendi."
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    note.add_theme_font_size_override("font_size", 16)
    note.add_theme_color_override("font_color", V20_MUTED)
    hud.add_child(note)

    _menu_button("GERİ", Vector2(490, 565), Vector2(300, 60), func(): _show_main_menu())

func _show_chapter_result() -> void:
    if chapter != 18:
        super._show_chapter_result()
        return
    timer_label = null
    if is_instance_valid(world):
        world.queue_free()
    world = null
    if is_instance_valid(hud):
        hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)

    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V20_INK
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(160, 72)
    title.size = Vector2(960, 260)
    title.text = "BÖLÜM 18 TAMAMLANDI\n\n54 HARİTA TAMAM\nTOPLAM ÖLÜM: %d" % deaths
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 38)
    title.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(title)

    var stats := Label.new()
    stats.position = Vector2(120, 340)
    stats.size = Vector2(1040, 150)
    stats.text = "18-1  %s / %s ölüm     18-2  %s / %s ölüm     18-3  %s / %s ölüm\n\nv2.0 GÖRSEL / EFEKT PAKETİ AKTİF" % [
        _best_time_text(18, 1), _best_deaths_text(18, 1),
        _best_time_text(18, 2), _best_deaths_text(18, 2),
        _best_time_text(18, 3), _best_deaths_text(18, 3)
    ]
    stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    stats.add_theme_font_size_override("font_size", 19)
    stats.add_theme_color_override("font_color", Color(0.47, 0.89, 0.96, 1.0))
    hud.add_child(stats)

    _menu_button("ANA MENÜ", Vector2(490, 555), Vector2(300, 64), func(): _show_main_menu())

func _v20_panel_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = border
    style.set_border_width_all(1)
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    style.shadow_color = Color(0, 0, 0, 0.10)
    style.shadow_size = 10
    return style

func _v20_add_global_environment() -> void:
    if not is_instance_valid(world):
        return
    var horizon := Line2D.new()
    horizon.width = 2.0
    horizon.default_color = Color(0.10, 0.38, 0.52, 0.055)
    horizon.points = PackedVector2Array([Vector2(0, 438), Vector2(level_width, 438)])
    horizon.z_index = -48
    world.add_child(horizon)

    for i in range(int(level_width / 520.0) + 1):
        var x := 90.0 + float(i) * 520.0
        var tower := Polygon2D.new()
        tower.position = Vector2(x, 372)
        var h := 95.0 + float((i % 4) * 24)
        tower.polygon = PackedVector2Array([
            Vector2(-42, 0), Vector2(42, 0), Vector2(32, -h), Vector2(-32, -h)
        ])
        tower.color = Color(0.13, 0.28, 0.42, 0.028 + float(i % 3) * 0.008)
        tower.z_index = -50
        world.add_child(tower)

    if v20_effects_enabled:
        var pulse := Line2D.new()
        pulse.width = 3.0
        pulse.default_color = Color(0.04, 0.55, 0.68, 0.08)
        pulse.points = PackedVector2Array([Vector2(0, 442), Vector2(level_width, 442)])
        pulse.z_index = -47
        world.add_child(pulse)
        var tw := create_tween().set_loops()
        tw.tween_property(pulse, "modulate:a", 0.28, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        tw.tween_property(pulse, "modulate:a", 1.0, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_v20_jump() -> void:
    if v20_effects_enabled:
        _v20_jump_fx()
    if chapter == 18 and is_instance_valid(player):
        _v20_ch18_jump_logic(player.global_position.x)

func _v20_jump_fx() -> void:
    if not is_instance_valid(player) or not is_instance_valid(world):
        return
    _v20_emit_dust(player.global_position + Vector2(0, 18), -1.0)
    _v20_squash(Vector2(1.08, 0.88), 0.09)

func _v20_land_fx() -> void:
    if not is_instance_valid(player) or not is_instance_valid(world):
        return
    _v20_emit_dust(player.global_position + Vector2(0, 19), 1.0)
    _v20_squash(Vector2(1.14, 0.82), 0.08)
    if is_instance_valid(camera):
        var base := camera.offset
        camera.offset = base + Vector2(0, 3)
        create_tween().tween_property(camera, "offset", base, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _v20_emit_dust(origin: Vector2, vertical_sign: float) -> void:
    for i in range(4):
        var dust := Polygon2D.new()
        dust.position = origin + Vector2(-18.0 + float(i) * 12.0, 0)
        var s := 4.0 + float(i % 2) * 2.0
        dust.polygon = PackedVector2Array([Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s)])
        dust.color = Color(0.20, 0.33, 0.45, 0.30)
        dust.z_index = 15
        world.add_child(dust)
        var dx := -22.0 + float(i) * 15.0
        var dy := (8.0 + float(i % 2) * 4.0) * vertical_sign
        var tw := create_tween()
        tw.set_parallel(true)
        tw.tween_property(dust, "position", dust.position + Vector2(dx, dy), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tw.tween_property(dust, "modulate:a", 0.0, 0.28)
        tw.set_parallel(false)
        tw.tween_callback(func():
            if is_instance_valid(dust):
                dust.queue_free()
        )

func _v20_squash(target: Vector2, duration: float) -> void:
    if not is_instance_valid(player):
        return
    for child in player.get_children():
        if child is Polygon2D:
            var poly := child as Polygon2D
            var tw := create_tween()
            tw.tween_property(poly, "scale", target, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
            tw.tween_property(poly, "scale", Vector2.ONE, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _add_chapter18_decor() -> void:
    if not is_instance_valid(world):
        return
    for i in range(int(level_width / 420.0) + 1):
        var x := 140.0 + float(i) * 420.0
        var mark := Line2D.new()
        mark.width = 2.0
        mark.default_color = Color(0.08, 0.47, 0.60, 0.075)
        mark.points = PackedVector2Array([
            Vector2(x - 55, 408), Vector2(x - 25, 390), Vector2(x + 5, 420), Vector2(x + 55, 390)
        ])
        mark.z_index = -21
        world.add_child(mark)

func _v20_chain_notice(text: String, color: Color = V20_CYAN) -> void:
    _troll_popup(text, color)
    _play_tone(560.0, 0.07, 0.10)

func _v20_ch18_jump_logic(x: float) -> void:
    if part == 2 and x >= 4300.0 and x <= 4750.0 and _once("182_jump"):
        _v20_chain_notice("ZIPLAMA ZİNCİRE EKLENDİ", V20_PURPLE)
        var spikes := _spikes(Vector2(5050, 612), 3, true)
        _timed_hazard(spikes, 0.28, 0.42, "182_jump_spikes")
    elif part == 3 and x >= 5150.0 and x <= 5550.0 and _once("183_jump"):
        var a := _attempt(18, 3)
        if a % 3 == 0:
            _v20_chain_notice("ZİNCİR YÖNÜ DEĞİŞTİ", V20_PURPLE)
            _reverse_controls(0.64)
        else:
            _false_alarm()

func _level_18_1() -> void:
    _floor_with_gaps(6900, [Vector2(1850, 2010), Vector2(4310, 4470)])
    _text(Vector2(120, 470), "BÖLÜM 18: TEK TUZAK DEĞİL, AKIŞ.", 23, V20_CYAN)
    _text(Vector2(430, 520), "BİR TEPKİ DİĞERİNİ HAZIRLAYABİLİR.", 18, V20_MUTED)

    var safe := _safe_pad(Vector2(820, 548), 190.0)
    _trigger(Rect2(590, 390, 120, 240), func():
        if _once("181_safe"):
            _false_alarm()
            create_tween().tween_property(safe, "position:y", 545.0, 0.12)
    )

    var first := _spikes(Vector2(1310, 612), 3, true)
    _trigger(Rect2(1030, 390, 120, 240), func():
        _timed_hazard(first, 0.30, 0.44, "181_first")
    )

    _moving_platform(Vector2(1930, 555), Vector2(150, 24), Vector2(1970, 470), 1.34, V20_BLUE)

    _trigger(Rect2(2390, 390, 120, 240), func():
        if _once("181_chain_audio"):
            _v20_chain_notice("1 / 3")
            var tw := create_tween()
            tw.tween_interval(0.48)
            tw.tween_callback(func(): _falling_boulder(Vector2(2890, 10), 54.0, 0.0))
    )

    var middle := _safe_pad(Vector2(3320, 548), 180.0)
    _trigger(Rect2(3090, 390, 120, 240), func():
        if _once("181_middle"):
            _v20_chain_notice("2 / 3", V20_AMBER)
            create_tween().tween_property(middle, "position:x", 3327.0, 0.14)
            _false_alarm()
    )

    var second := _spikes(Vector2(3820, 612), 3, true)
    _trigger(Rect2(3560, 390, 120, 240), func():
        if _once("181_second"):
            _v20_chain_notice("3 / 3", V20_PURPLE)
            _timed_hazard(second, 0.26, 0.42, "181_second_live")
    )

    _moving_platform(Vector2(4390, 555), Vector2(145, 24), Vector2(4430, 470), 1.28, V20_CYAN)

    _trigger(Rect2(4920, 390, 120, 240), func():
        if _once("181_rock"):
            var tw := create_tween()
            tw.tween_interval(0.40)
            tw.tween_callback(func(): _boulder(Vector2(5520, 560), -360.0, 68.0))
    )

    var end_safe := _safe_pad(Vector2(5900, 548), 180.0)
    _trigger(Rect2(5660, 390, 120, 240), func():
        if _once("181_end_safe"):
            _false_alarm()
            create_tween().tween_property(end_safe, "position:y", 544.0, 0.12)
    )

    _finish(Vector2(6550, 580))

func _level_18_2() -> void:
    _floor_with_gaps(7400, [Vector2(1580, 1740), Vector2(3600, 3760), Vector2(5560, 5720)])
    _text(Vector2(120, 470), "AKIŞTA ROTA DA VAR.", 23, V20_CYAN)
    _text(Vector2(430, 520), "HER DOĞRU KARAR AYNI TEMPOYU İSTEMEZ.", 18, V20_MUTED)

    _moving_platform(Vector2(1660, 555), Vector2(150, 24), Vector2(1700, 470), 1.32, V20_BLUE)

    _route_hint(Vector2(2250, 500), "A")
    _route_hint(Vector2(2250, 390), "B")
    _platform(Vector2(2370, 465), Vector2(230, 24), V20_BLUE)
    _platform(Vector2(2660, 435), Vector2(210, 24), V20_BLUE)
    _trigger(Rect2(2130, 315, 220, 175), func():
        if _choose_route("upper"):
            _play_tone(760.0, 0.08, 0.10)
            _false_alarm()
    )
    _trigger(Rect2(2130, 500, 220, 150), func():
        if _choose_route("lower"):
            var route_spikes := _spikes(Vector2(3030, 612), 3, true)
            _timed_hazard(route_spikes, 0.34, 0.42, "182_route")
    )

    _moving_platform(Vector2(3680, 555), Vector2(145, 24), Vector2(3720, 470), 1.30, V20_CYAN)

    _trigger(Rect2(4050, 390, 300, 240), func():
        _wait_check(4230.0, 145.0, 0.92, func():
            _v20_chain_notice("BEKLEME ALGILANDI", V20_AMBER)
            _false_alarm()
        , "182_wait")
    )

    var silent := _spikes(Vector2(5200, 612), 3, true)
    _trigger(Rect2(4930, 390, 120, 240), func():
        _timed_hazard(silent, 0.30, 0.44, "182_silent")
    )

    _moving_platform(Vector2(5640, 555), Vector2(145, 24), Vector2(5680, 470), 1.28, V20_BLUE)

    var last_safe := _safe_pad(Vector2(6300, 548), 185.0)
    _trigger(Rect2(6070, 390, 120, 240), func():
        if _once("182_last_safe"):
            _false_alarm()
            create_tween().tween_property(last_safe, "position:x", 6305.0, 0.12)
    )

    _finish(Vector2(7040, 580))

func _level_18_3() -> void:
    _floor_with_gaps(8200, [Vector2(1900, 2060), Vector2(4200, 4360), Vector2(6500, 6660)])
    var a := _attempt(18, 3)
    _text(Vector2(120, 470), "ZİNCİRİ HATIRLIYORUM.", 24, V20_PURPLE)
    _text(Vector2(430, 520), "DENEME %d — SIRA DEĞİŞİR, KURAL DEĞİL." % a, 18, V20_MUTED)

    var open_a := _spikes(Vector2(1120, 612), 3, true)
    var open_b := _spikes(Vector2(1450, 612), 3, true)
    _trigger(Rect2(780, 390, 120, 240), func():
        if _once("183_open"):
            var target := open_a if a % 2 == 1 else open_b
            _timed_hazard(target, 0.28, 0.42, "183_open_live")
    )

    _moving_platform(Vector2(1980, 555), Vector2(150, 24), Vector2(2020, 470), 1.32, V20_CYAN)

    _route_hint(Vector2(2550, 500), "A")
    _route_hint(Vector2(2550, 390), "B")
    _platform(Vector2(2670, 465), Vector2(230, 24), V20_BLUE)
    _platform(Vector2(2960, 435), Vector2(210, 24), V20_BLUE)
    _trigger(Rect2(2430, 315, 220, 175), func():
        if _choose_route("upper"):
            _false_alarm()
    )
    _trigger(Rect2(2430, 500, 220, 150), func():
        if _choose_route("lower"):
            _v20_chain_notice("ROTA A", V20_CYAN)
    )

    var route_gate := _spikes(Vector2(3500, 612), 3, true)
    _trigger(Rect2(3260, 390, 120, 240), func():
        if _once("183_route"):
            var punish := (route_choice == "upper" and a % 3 == 0) or (route_choice == "lower" and a % 3 != 0)
            if punish:
                _timed_hazard(route_gate, 0.30, 0.42, "183_route_live")
            else:
                _false_alarm()
    )

    _moving_platform(Vector2(4280, 555), Vector2(145, 24), Vector2(4320, 470), 1.28, V20_BLUE)

    _trigger(Rect2(4720, 390, 120, 240), func():
        if _once("183_audio"):
            _play_tone(820.0, 0.09, 0.11)
            if a % 2 == 0:
                var audio_spikes := _spikes(Vector2(5030, 612), 3, true)
                _timed_hazard(audio_spikes, 0.34, 0.42, "183_audio_live")
            else:
                _false_alarm()
    )

    _trigger(Rect2(5750, 390, 300, 240), func():
        _wait_check(5920.0, 145.0, 0.88, func():
            if a % 3 == 2:
                _false_alarm()
            else:
                _reverse_controls(0.62)
        , "183_wait")
    )

    _moving_platform(Vector2(6580, 555), Vector2(145, 24), Vector2(6620, 470), 1.28, V20_CYAN)

    _trigger(Rect2(7000, 390, 120, 240), func():
        if _once("183_end"):
            if a % 2 == 0:
                var tw := create_tween()
                tw.tween_interval(0.40)
                tw.tween_callback(func(): _boulder(Vector2(7580, 560), -355.0, 68.0))
            else:
                var final_spikes := _spikes(Vector2(7340, 612), 3, true)
                _timed_hazard(final_spikes, 0.30, 0.42, "183_end_spikes")
    )

    _finish(Vector2(7900, 580))
