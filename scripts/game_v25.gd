extends "res://scripts/game_v24.gd"

const V25_BG := Color("#070b12")
const V25_BG_SOFT := Color("#0b1220")
const V25_PANEL := Color("#111827")
const V25_PLATFORM := Color("#1f2937")
const V25_PLATFORM_ALT := Color("#273449")
const V25_CYAN := Color("#22d3ee")
const V25_BLUE := Color("#3b82f6")
const V25_PURPLE := Color("#8b5cf6")
const V25_GREEN := Color("#34d399")
const V25_AMBER := Color("#f59e0b")
const V25_RED := Color("#fb4b5f")
const V25_MUTED := Color("#94a3b8")
const V25_TEXT := Color("#e5eef8")

var v25_dark_active := false

func _safe_load_progress() -> void:
    super._safe_load_progress()
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return
    var stored_unlock = cfg.get_value("progress", "unlocked_chapter", 1)
    if stored_unlock is int or stored_unlock is float:
        unlocked_chapter = clampi(int(stored_unlock), 1, 22)

func _start_level(c: int, p: int) -> void:
    v25_dark_active = c >= 21
    super._start_level(c, p)
    if c >= 21:
        RenderingServer.set_default_clear_color(V25_BG)
        _v25_add_dark_environment()

func _build_level(c: int, p: int) -> void:
    if c == 21 and p == 1:
        _v25_level_21_1()
    elif c == 21 and p == 2:
        _v25_level_21_2()
    elif c == 21 and p == 3:
        _v25_level_21_3()
    else:
        super._build_level(c, p)

func _build_hud() -> void:
    super._build_hud()
    if chapter < 21 or not is_instance_valid(hud):
        return
    var strip := ColorRect.new()
    strip.position = Vector2(0, 0)
    strip.size = Vector2(1280, 72)
    strip.color = Color(0.02, 0.035, 0.065, 0.88)
    strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
    strip.z_index = -40
    hud.add_child(strip)
    var glow := ColorRect.new()
    glow.position = Vector2(0, 68)
    glow.size = Vector2(1280, 2)
    glow.color = Color(V25_CYAN, 0.44)
    glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    glow.z_index = -39
    hud.add_child(glow)
    var era := Label.new()
    era.position = Vector2(620, 45)
    era.size = Vector2(270, 22)
    era.text = "KARANLIK DÖNEM • 21-40"
    era.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    era.add_theme_font_size_override("font_size", 11)
    era.add_theme_color_override("font_color", V25_CYAN)
    hud.add_child(era)

func _platform(pos: Vector2, size: Vector2, color: Color) -> StaticBody2D:
    if chapter < 21:
        return super._platform(pos, size, color)
    var themed := V25_PLATFORM
    if color == V25_BLUE or color == V25_CYAN or color == C_BLUE:
        themed = V25_PLATFORM_ALT
    var body := super._platform(pos, size, themed)
    if not is_instance_valid(body):
        return body
    var edge := Line2D.new()
    edge.width = 2.0
    edge.default_color = Color(V25_CYAN, 0.46)
    edge.points = PackedVector2Array([
        Vector2(-size.x * 0.5 + 7.0, -size.y * 0.5 + 2.0),
        Vector2(size.x * 0.5 - 7.0, -size.y * 0.5 + 2.0)
    ])
    edge.z_index = 7
    body.add_child(edge)
    return body

func _hazard_block(pos: Vector2, size: Vector2, color: Color) -> Area2D:
    var used_color := V25_RED if chapter >= 21 else color
    var area := super._hazard_block(pos, size, used_color)
    if chapter >= 21 and is_instance_valid(area):
        var outline := Line2D.new()
        outline.width = 2.0
        outline.default_color = Color(1.0, 0.32, 0.42, 0.62)
        outline.closed = true
        outline.points = PackedVector2Array([
            Vector2(-size.x * 0.5, -size.y * 0.5),
            Vector2(size.x * 0.5, -size.y * 0.5),
            Vector2(size.x * 0.5, size.y * 0.5),
            Vector2(-size.x * 0.5, size.y * 0.5)
        ])
        outline.z_index = 5
        area.add_child(outline)
    return area

func _finish(pos: Vector2) -> Area2D:
    var area := super._finish(pos)
    if chapter >= 21 and is_instance_valid(area):
        var halo := Line2D.new()
        halo.width = 3.0
        halo.closed = true
        halo.default_color = Color(V25_CYAN, 0.58)
        halo.points = _circle_points(43.0, 28)
        halo.z_index = 12
        area.add_child(halo)
        if v20_effects_enabled:
            var tw := create_tween().set_loops()
            tw.tween_property(halo, "modulate:a", 0.28, 0.62)
            tw.tween_property(halo, "modulate:a", 1.0, 0.62)
    return area

func _show_main_menu() -> void:
    v24_dev_session = false
    v25_dark_active = false
    active_map_key = ""
    timer_label = null
    RenderingServer.set_default_clear_color(V25_BG)
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
    bg.color = V25_BG
    hud.add_child(bg)

    for i in range(9):
        var beam := Line2D.new()
        beam.width = 2.0
        beam.default_color = Color(0.14, 0.78, 0.90, 0.025 + float(i % 3) * 0.012)
        beam.points = PackedVector2Array([
            Vector2(-160.0 + float(i) * 185.0, 720.0),
            Vector2(120.0 + float(i) * 185.0, 365.0)
        ])
        hud.add_child(beam)

    var top := ColorRect.new()
    top.size = Vector2(1280, 112)
    top.color = Color("#050810")
    hud.add_child(top)
    var cyan_line := ColorRect.new()
    cyan_line.position = Vector2(0, 108)
    cyan_line.size = Vector2(1280, 4)
    cyan_line.color = V25_CYAN
    hud.add_child(cyan_line)

    var version := Label.new()
    version.position = Vector2(30, 21)
    version.size = Vector2(320, 34)
    version.text = "ANDROID • v2.5"
    version.add_theme_font_size_override("font_size", 20)
    version.add_theme_color_override("font_color", V25_TEXT)
    hud.add_child(version)

    var phase := Label.new()
    phase.position = Vector2(30, 58)
    phase.size = Vector2(500, 28)
    phase.text = "KARANLIK DÖNEM BAŞLADI • BÖLÜM 21"
    phase.add_theme_font_size_override("font_size", 13)
    phase.add_theme_color_override("font_color", V25_CYAN)
    hud.add_child(phase)

    var records := Label.new()
    records.position = Vector2(890, 31)
    records.size = Vector2(360, 42)
    records.text = "REKOR KAYDI  %d / 63" % best_times_ms.size()
    records.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    records.add_theme_font_size_override("font_size", 17)
    records.add_theme_color_override("font_color", Color(0.90, 0.95, 1.0, 0.72))
    hud.add_child(records)

    var title := Label.new()
    title.position = Vector2(92, 145)
    title.size = Vector2(635, 110)
    title.text = "TROLL\nPARKOUR"
    title.add_theme_font_size_override("font_size", 56)
    title.add_theme_color_override("font_color", V25_TEXT)
    hud.add_child(title)

    var subtitle := Label.new()
    subtitle.position = Vector2(98, 267)
    subtitle.size = Vector2(620, 60)
    subtitle.text = "Işık artık bilgi değil. Bazen ipucu, bazen tuzak."
    subtitle.add_theme_font_size_override("font_size", 19)
    subtitle.add_theme_color_override("font_color", V25_MUTED)
    hud.add_child(subtitle)

    var available := maxi(1, mini(unlocked_chapter, 21))
    var completed_maps := maxi(0, (mini(unlocked_chapter, 22) - 1) * 3)
    var panel := Panel.new()
    panel.position = Vector2(785, 146)
    panel.size = Vector2(400, 185)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_theme_stylebox_override("panel", _v25_panel_style(Color(0.05, 0.08, 0.14, 0.92), Color(V25_CYAN, 0.24), 22))
    hud.add_child(panel)

    var stats := Label.new()
    stats.position = Vector2(820, 174)
    stats.size = Vector2(330, 126)
    stats.text = "AÇIK BÖLÜM   %d / 21\nHARİTA        %d / 63\nTOPLAM ÖLÜM   %d" % [available, completed_maps, deaths]
    stats.add_theme_font_size_override("font_size", 18)
    stats.add_theme_color_override("font_color", V25_TEXT)
    hud.add_child(stats)

    var content := Label.new()
    content.position = Vector2(98, 351)
    content.size = Vector2(620, 27)
    content.text = "İÇERİK ÜRETİMİ  63 / 300"
    content.add_theme_font_size_override("font_size", 15)
    content.add_theme_color_override("font_color", V25_MUTED)
    hud.add_child(content)

    var bar_bg := ColorRect.new()
    bar_bg.position = Vector2(98, 386)
    bar_bg.size = Vector2(620, 10)
    bar_bg.color = Color(0.40, 0.52, 0.68, 0.14)
    hud.add_child(bar_bg)
    var bar := ColorRect.new()
    bar.position = Vector2(98, 386)
    bar.size = Vector2(620.0 * 63.0 / 300.0, 10)
    bar.color = V25_CYAN
    hud.add_child(bar)

    var feature := Label.new()
    feature.position = Vector2(98, 430)
    feature.size = Vector2(625, 205)
    feature.text = "v2.5 KARANLIK DÖNEM\n\n• Koyu platform / neon kenar materyali\n• Yeni karanlık HUD ve sahne atmosferi\n• Blackout ve ışık-yönlendirme troll sistemi\n• Developer Tool artık Bölüm 21'i de açabilir"
    feature.add_theme_font_size_override("font_size", 17)
    feature.add_theme_color_override("font_color", V25_MUTED)
    hud.add_child(feature)

    _v25_button("DEVAM ET", Vector2(790, 350), Vector2(390, 60), func(): _start_level(maxi(1, mini(unlocked_chapter, 21)), 1), V25_CYAN)
    _v25_button("BÖLÜMLER", Vector2(790, 422), Vector2(390, 60), func(): _show_chapter_select(), V25_BLUE)
    _v25_button("EFEKTLER: %s" % ("AÇIK" if v20_effects_enabled else "KAPALI"), Vector2(790, 494), Vector2(390, 54), func(): _toggle_v20_effects(), V25_PURPLE)
    _v25_button("SES: %s" % ("AÇIK" if v22_sound_enabled else "KAPALI"), Vector2(790, 560), Vector2(390, 54), func(): _toggle_v22_sound(), V25_GREEN)
    _v25_button("DEV", Vector2(1110, 28), Vector2(120, 48), func(): _v24_open_dev_console(), V25_AMBER)
    _v25_button("1. BÖLÜMDEN BAŞLA", Vector2(790, 626), Vector2(390, 50), func(): _start_level(1, 1), V25_MUTED)

func _show_chapter_select() -> void:
    timer_label = null
    RenderingServer.set_default_clear_color(V25_BG)
    if is_instance_valid(hud):
        hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)

    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V25_BG
    hud.add_child(bg)
    var top := ColorRect.new()
    top.size = Vector2(1280, 82)
    top.color = Color("#050810")
    hud.add_child(top)
    var cyan := ColorRect.new()
    cyan.position = Vector2(0, 79)
    cyan.size = Vector2(1280, 3)
    cyan.color = V25_CYAN
    hud.add_child(cyan)

    var title := Label.new()
    title.position = Vector2(58, 18)
    title.size = Vector2(500, 46)
    title.text = "BÖLÜM SEÇ"
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", V25_TEXT)
    hud.add_child(title)

    var info := Label.new()
    info.position = Vector2(650, 24)
    info.size = Vector2(570, 36)
    info.text = "21 BÖLÜM • 63 HARİTA • KARANLIK FAZ"
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    info.add_theme_font_size_override("font_size", 16)
    info.add_theme_color_override("font_color", V25_MUTED)
    hud.add_child(info)

    for i in range(1, 22):
        var chapter_id: int = i
        var is_unlocked := chapter_id <= unlocked_chapter
        var col := (i - 1) % 4
        var row := int((i - 1) / 4)
        var pos := Vector2(48 + col * 300, 101 + row * 72)
        var suffix := _v25_chapter_suffix(chapter_id)
        var button_text := "BÖLÜM %d\n%s" % [chapter_id, suffix]
        if not is_unlocked:
            button_text = "BÖLÜM %d\nKİLİTLİ" % chapter_id
        var accent := V25_CYAN if chapter_id >= 21 else Color("#475569")
        var button := _v25_button(button_text, pos, Vector2(276, 56), func(): _start_level(chapter_id, 1), accent)
        button.disabled = not is_unlocked

    var note := Label.new()
    note.position = Vector2(140, 544)
    note.size = Vector2(1000, 42)
    note.text = "Bölüm 21-40: Karanlık dönem • düşük ışık, neon ipuçları ve yeni algı tuzakları"
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    note.add_theme_font_size_override("font_size", 16)
    note.add_theme_color_override("font_color", V25_MUTED)
    hud.add_child(note)
    _v25_button("GERİ", Vector2(490, 610), Vector2(300, 60), func(): _show_main_menu(), V25_CYAN)

func _show_chapter_result() -> void:
    if chapter != 21:
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
    bg.color = V25_BG
    hud.add_child(bg)
    var line := ColorRect.new()
    line.size = Vector2(1280, 4)
    line.color = V25_CYAN
    hud.add_child(line)

    var title := Label.new()
    title.position = Vector2(140, 70)
    title.size = Vector2(1000, 220)
    title.text = "BÖLÜM 21 TAMAMLANDI\n\nKARANLIK DÖNEME GİRDİN"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 38)
    title.add_theme_color_override("font_color", V25_TEXT)
    hud.add_child(title)

    var stats := Label.new()
    stats.position = Vector2(100, 310)
    stats.size = Vector2(1080, 150)
    stats.text = "21-1  %s / %s ölüm     21-2  %s / %s ölüm     21-3  %s / %s ölüm\n\nIŞIĞA GÜVENME. KARANLIĞA DA GÜVENME." % [_best_time_text(21, 1), _best_deaths_text(21, 1), _best_time_text(21, 2), _best_deaths_text(21, 2), _best_time_text(21, 3), _best_deaths_text(21, 3)]
    stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    stats.add_theme_font_size_override("font_size", 19)
    stats.add_theme_color_override("font_color", V25_CYAN)
    hud.add_child(stats)

    var milestone := Label.new()
    milestone.position = Vector2(180, 485)
    milestone.size = Vector2(920, 45)
    milestone.text = "21 / 100 BÖLÜM   •   63 / 300 HARİTA   •   %21 İÇERİK"
    milestone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    milestone.add_theme_font_size_override("font_size", 18)
    milestone.add_theme_color_override("font_color", V25_MUTED)
    hud.add_child(milestone)
    _v25_button("ANA MENÜ", Vector2(490, 565), Vector2(300, 64), func(): _show_main_menu(), V25_CYAN)

func _v24_open_dev_console() -> void:
    super._v24_open_dev_console()
    if not is_instance_valid(v24_dev_overlay):
        return
    for panel_child in v24_dev_overlay.get_children():
        for child in panel_child.get_children():
            if child is Label and child.text.begins_with("Komut biçimi:"):
                child.text = "Komut biçimi: WAREXT 21-3\nBölüm 1-21 • Kısım 1-3"

func _v24_execute_dev_command(command: String) -> void:
    var raw := command.strip_edges().to_upper()
    if not raw.begins_with("WAREXT "):
        _v24_dev_error("Kod WAREXT ile başlamalı. Örnek: WAREXT 21-3")
        return
    var target := raw.trim_prefix("WAREXT ").strip_edges()
    var pieces := target.split("-")
    if pieces.size() != 2:
        _v24_dev_error("Biçim hatalı. Örnek: WAREXT 12-2")
        return
    var chapter_text := String(pieces[0]).strip_edges()
    var part_text := String(pieces[1]).strip_edges()
    if not chapter_text.is_valid_int() or not part_text.is_valid_int():
        _v24_dev_error("Bölüm ve kısım sayı olmalı.")
        return
    var target_chapter: int = int(chapter_text)
    var target_part: int = int(part_text)
    if target_chapter < 1 or target_chapter > 21:
        _v24_dev_error("Bölüm 1 ile 21 arasında olmalı.")
        return
    if target_part < 1 or target_part > 3:
        _v24_dev_error("Kısım 1 ile 3 arasında olmalı.")
        return
    _v24_close_dev_console()
    v24_dev_session = true
    _start_level(target_chapter, target_part)

func _v25_button(text: String, pos: Vector2, size: Vector2, action: Callable, accent: Color) -> Button:
    var button := Button.new()
    button.position = pos
    button.size = size
    button.text = text
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 17)
    button.add_theme_color_override("font_color", V25_TEXT)
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color(0.055, 0.085, 0.14, 0.96)
    normal.border_color = Color(accent, 0.42)
    normal.set_border_width_all(1)
    normal.corner_radius_top_left = 12
    normal.corner_radius_top_right = 12
    normal.corner_radius_bottom_left = 12
    normal.corner_radius_bottom_right = 12
    button.add_theme_stylebox_override("normal", normal)
    var hover := normal.duplicate()
    hover.bg_color = Color(0.075, 0.12, 0.19, 0.98)
    hover.border_color = Color(accent, 0.82)
    button.add_theme_stylebox_override("hover", hover)
    var pressed := normal.duplicate()
    pressed.bg_color = Color(accent, 0.20)
    pressed.border_color = accent
    button.add_theme_stylebox_override("pressed", pressed)
    button.pressed.connect(action)
    hud.add_child(button)
    return button

func _v25_panel_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = border
    style.set_border_width_all(1)
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    return style

func _v25_chapter_suffix(chapter_id: int) -> String:
    if chapter_id == 5: return "HAFIZA"
    if chapter_id == 6: return "HAREKET"
    if chapter_id == 7: return "GÜVEN"
    if chapter_id == 8: return "ZAMAN"
    if chapter_id == 9: return "ROTA"
    if chapter_id == 10: return "MİNİ FİNAL"
    if chapter_id == 11: return "REAKTİF"
    if chapter_id == 12: return "TEMPO"
    if chapter_id == 13: return "KAYAN GÜVEN"
    if chapter_id == 14: return "ALGI"
    if chapter_id == 15: return "SES"
    if chapter_id == 16: return "GİRDİ"
    if chapter_id == 17: return "ALIŞKANLIK"
    if chapter_id == 18: return "AKIŞ"
    if chapter_id == 19: return "DALGA"
    if chapter_id == 20: return "EŞİK / FİNAL"
    if chapter_id == 21: return "KARANLIK"
    return "3 HARİTA"

func _v25_add_dark_environment() -> void:
    if not is_instance_valid(world):
        return
    var backdrop := Polygon2D.new()
    backdrop.polygon = PackedVector2Array([
        Vector2(-600, -500),
        Vector2(level_width + 600, -500),
        Vector2(level_width + 600, 720),
        Vector2(-600, 720)
    ])
    backdrop.color = V25_BG_SOFT
    backdrop.z_index = -120
    world.add_child(backdrop)

    for i in range(18):
        var x := 120.0 + float(i) * 420.0
        if x > level_width:
            break
        var pillar := Line2D.new()
        pillar.width = 2.0
        pillar.default_color = Color(0.13, 0.72, 0.88, 0.055)
        pillar.points = PackedVector2Array([Vector2(x, 100), Vector2(x, 610)])
        pillar.z_index = -110
        world.add_child(pillar)
        var cross := Line2D.new()
        cross.width = 1.0
        cross.default_color = Color(0.37, 0.45, 0.61, 0.045)
        cross.points = PackedVector2Array([Vector2(x - 120, 430), Vector2(x + 120, 430)])
        cross.z_index = -109
        world.add_child(cross)

func _v25_light_beacon(pos: Vector2, color: Color, label_text: String = "") -> void:
    if not is_instance_valid(world):
        return
    var stem := Line2D.new()
    stem.width = 3.0
    stem.default_color = Color(color, 0.56)
    stem.points = PackedVector2Array([Vector2(pos.x, pos.y + 70), Vector2(pos.x, pos.y - 25)])
    stem.z_index = -4
    world.add_child(stem)
    for r in [18.0, 28.0, 40.0]:
        var ring := Line2D.new()
        ring.width = 2.0
        ring.closed = true
        ring.default_color = Color(color, 0.34 - (r - 18.0) * 0.006)
        ring.position = Vector2(pos.x, pos.y - 34)
        ring.points = _circle_points(r, 24)
        ring.z_index = -3
        world.add_child(ring)
    if not label_text.is_empty():
        _text(Vector2(pos.x - 75, pos.y + 78), label_text, 15, color)

func _v25_blackout(duration: float = 0.34, strength: float = 0.80) -> void:
    if not v20_effects_enabled or not is_instance_valid(hud):
        return
    var veil := ColorRect.new()
    veil.size = Vector2(1280, 720)
    veil.color = Color(0.0, 0.0, 0.0, strength)
    veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
    veil.z_index = 80
    hud.add_child(veil)
    var tw := create_tween()
    tw.tween_interval(maxf(0.08, duration * 0.45))
    tw.tween_property(veil, "color:a", 0.0, maxf(0.10, duration * 0.55)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tw.tween_callback(veil.queue_free)

func _v25_pulse_notice(text: String, color: Color = V25_CYAN) -> void:
    _troll_popup(text, color)
    _play_tone(390.0, 0.08, 0.10)

func _v25_level_21_1() -> void:
    _base_floor(6200)
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

    _floor_with_gaps(6200, [Vector2(2190, 2350), Vector2(3840, 4000)])
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

func _v25_level_21_2() -> void:
    _floor_with_gaps(6800, [Vector2(1520, 1680), Vector2(3520, 3680), Vector2(5240, 5400)])
    _text(Vector2(120, 470), "AYDINLIK OLAN HER ŞEY GÜVENLİ DEĞİL.", 23, V25_CYAN)
    _v25_light_beacon(Vector2(760, 490), V25_GREEN, "A")
    _v25_light_beacon(Vector2(1120, 490), V25_RED, "B")

    var lit_safe := _platform(Vector2(790, 550), Vector2(170, 26), V25_GREEN)
    var dark_safe := _platform(Vector2(1160, 550), Vector2(170, 26), V25_RED)
    _trigger(Rect2(590, 390, 120, 240), func():
        if _once("212_a"):
            _false_alarm()
            create_tween().tween_property(lit_safe, "position:y", 547.0, 0.12)
    )
    _trigger(Rect2(960, 390, 120, 240), func():
        if _once("212_b"):
            _false_alarm()
            create_tween().tween_property(dark_safe, "position:y", 547.0, 0.12)
    )

    _moving_platform(Vector2(1600, 555), Vector2(145, 24), Vector2(1640, 470), 1.40, V25_CYAN)

    var light_gate := _hazard_block(Vector2(2220, 220), Vector2(130, 72), V25_RED)
    _trigger(Rect2(1900, 390, 140, 240), func():
        if _once("212_gate"):
            _v25_pulse_notice("IŞIK AÇILDI")
            var tw := create_tween()
            tw.tween_interval(0.30)
            tw.tween_property(light_gate, "position:y", 515.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_interval(0.40)
            tw.tween_property(light_gate, "position:y", 220.0, 0.52).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

    _platform(Vector2(2900, 485), Vector2(300, 24), V25_BLUE)
    var ceiling := _spikes(Vector2(2900, 345), 3, true, true)
    _trigger(Rect2(2630, 350, 150, 280), func():
        if _once("212_ceiling"):
            _v25_blackout(0.26, 0.62)
            var tw := create_tween()
            tw.tween_interval(0.34)
            tw.tween_callback(func(): _reveal(ceiling))
            tw.tween_interval(0.56)
            tw.tween_callback(func(): _hide(ceiling))
    )

    _moving_platform(Vector2(3600, 555), Vector2(145, 24), Vector2(3640, 474), 1.36, V25_BLUE)

    _route_hint(Vector2(4300, 485), "IŞIK")
    _route_hint(Vector2(4300, 385), "GÖLGE")
    _platform(Vector2(4390, 455), Vector2(230, 24), V25_PLATFORM_ALT)
    _trigger(Rect2(4150, 310, 240, 180), func():
        if _choose_route("shadow"):
            _v25_pulse_notice("GÖLGE")
    )
    _trigger(Rect2(4150, 490, 240, 150), func():
        if _choose_route("light"):
            _v25_pulse_notice("IŞIK")
    )

    var route_trap := _spikes(Vector2(4810, 612), 3, true)
    _trigger(Rect2(4580, 390, 120, 240), func():
        if _once("212_route"):
            if route_choice == "light":
                var tw := create_tween()
                tw.tween_interval(0.34)
                tw.tween_callback(func(): _reveal(route_trap))
                tw.tween_interval(0.50)
                tw.tween_callback(func(): _hide(route_trap))
            else:
                _false_alarm()
    )

    _moving_platform(Vector2(5320, 555), Vector2(145, 24), Vector2(5360, 470), 1.42, V25_CYAN)
    _trigger(Rect2(5680, 390, 120, 240), func():
        if _once("212_rock"):
            _v25_blackout(0.24, 0.58)
            var tw := create_tween()
            tw.tween_interval(0.42)
            tw.tween_callback(func(): _boulder(Vector2(6320, 560), -350.0, 68.0))
    )
    _finish(Vector2(6500, 580))

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

    var route_bad := (attempt % 2 == 0 and route_choice == "bright") or (attempt % 2 == 1 and route_choice == "dim")
    var route_spikes := _spikes(Vector2(5190, 612), 3, true)
    _trigger(Rect2(4940, 390, 120, 240), func():
        if _once("213_route"):
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

func _v23_run_validation() -> void:
    await get_tree().process_frame
    var failures: int = 0
    var checked: int = 0
    for c in range(1, 22):
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
    if failures == 0 and checked == 63:
        print("ALL_LEVELS_OK:63")
        get_tree().quit(0)
    else:
        print("ALL_LEVELS_FAILED:%d:%d" % [checked, failures])
        get_tree().quit(1)
