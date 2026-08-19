extends "res://scripts/game_v21.gd"

const V22_BG := Color("#e6ecf3")
const V22_BG_CH20 := Color("#ece8df")
const V22_INK := Color("#0b1220")
const V22_SLATE := Color("#334155")
const V22_MUTED := Color("#64748b")
const V22_BLUE := Color("#2563eb")
const V22_CYAN := Color("#0891b2")
const V22_GREEN := Color("#16a34a")
const V22_AMBER := Color("#d89a24")
const V22_GOLD := Color("#e5b94a")
const V22_RED := Color("#dc4455")
const V22_PURPLE := Color("#7c3aed")

var v22_sound_enabled := true
var v22_transition_lock := false
var v22_restart_button: Button

func _safe_load_progress() -> void:
    super._safe_load_progress()
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return
    var stored_unlock = cfg.get_value("progress", "unlocked_chapter", 1)
    if stored_unlock is int or stored_unlock is float:
        unlocked_chapter = clampi(int(stored_unlock), 1, 21)
    v22_sound_enabled = bool(cfg.get_value("settings", "sound_enabled", true))

func _save_v22_settings() -> void:
    var cfg := ConfigFile.new()
    cfg.load(SAVE_PATH)
    cfg.set_value("settings", "sound_enabled", v22_sound_enabled)
    cfg.save(SAVE_PATH)

func _toggle_v22_sound() -> void:
    v22_sound_enabled = not v22_sound_enabled
    _save_v22_settings()
    if v22_sound_enabled:
        super._play_tone(620.0, 0.08, 0.10)
    _show_main_menu()

func _play_tone(freq: float, duration: float, gain: float = 0.25) -> void:
    if not v22_sound_enabled:
        return
    super._play_tone(freq, duration, gain)

func _start_level(c: int, p: int) -> void:
    var was_restart := restarting
    v22_transition_lock = true
    super._start_level(c, p)
    if c == 20:
        RenderingServer.set_default_clear_color(V22_BG_CH20)
        _v22_add_chapter20_decor()
    if is_instance_valid(hud):
        _v22_add_level_transition(was_restart)
    v22_transition_lock = false

func _build_level(c: int, p: int) -> void:
    if c == 20 and p == 1:
        _level_20_1()
    elif c == 20 and p == 2:
        _level_20_2()
    elif c == 20 and p == 3:
        _level_20_3()
    else:
        super._build_level(c, p)

func _build_hud() -> void:
    super._build_hud()
    var restart := Button.new()
    restart.position = Vector2(885, 12)
    restart.size = Vector2(105, 44)
    restart.text = "YENİDEN"
    restart.focus_mode = Control.FOCUS_NONE
    restart.add_theme_font_size_override("font_size", 13)
    var rs := StyleBoxFlat.new()
    rs.bg_color = Color(0.07, 0.11, 0.17, 0.08)
    rs.border_color = Color(0.10, 0.44, 0.58, 0.22)
    rs.set_border_width_all(1)
    rs.corner_radius_top_left = 12
    rs.corner_radius_top_right = 12
    rs.corner_radius_bottom_left = 12
    rs.corner_radius_bottom_right = 12
    restart.add_theme_stylebox_override("normal", rs)
    restart.pressed.connect(_v22_quick_restart)
    hud.add_child(restart)
    v22_restart_button = restart

    var sound_chip := Label.new()
    sound_chip.position = Vector2(745, 18)
    sound_chip.size = Vector2(130, 30)
    sound_chip.text = "SES %s" % ("AÇIK" if v22_sound_enabled else "KAPALI")
    sound_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sound_chip.add_theme_font_size_override("font_size", 12)
    sound_chip.add_theme_color_override("font_color", V22_CYAN if v22_sound_enabled else V22_MUTED)
    hud.add_child(sound_chip)

    if chapter == 20:
        var mode := Label.new()
        mode.position = Vector2(675, 45)
        mode.size = Vector2(205, 22)
        mode.text = "İLK DÖNEM FİNALİ"
        mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        mode.add_theme_font_size_override("font_size", 11)
        mode.add_theme_color_override("font_color", V22_AMBER)
        hud.add_child(mode)

func _v22_quick_restart() -> void:
    if restarting or level_finished or v22_transition_lock:
        return
    _start_level(chapter, part)

func _platform(pos: Vector2, size: Vector2, color: Color) -> StaticBody2D:
    var body := super._platform(pos, size, color)
    if not is_instance_valid(body):
        return body
    var edge := Line2D.new()
    edge.position = pos
    edge.width = 1.5
    edge.default_color = Color(0.76, 0.86, 0.93, 0.20)
    edge.points = PackedVector2Array([Vector2(-size.x / 2.0 + 8.0, -size.y / 2.0 + 2.0), Vector2(size.x / 2.0 - 8.0, -size.y / 2.0 + 2.0)])
    edge.z_index = 3
    world.add_child(edge)
    if size.x >= 150.0:
        for side in [-1.0, 1.0]:
            var bolt := Polygon2D.new()
            bolt.position = pos + Vector2(side * (size.x / 2.0 - 14.0), -size.y / 2.0 + 7.0)
            bolt.polygon = _circle_points(2.5, 10)
            bolt.color = Color(0.65, 0.76, 0.84, 0.28)
            bolt.z_index = 4
            world.add_child(bolt)
    return body

func _reveal(area: Area2D) -> void:
    super._reveal(area)
    if v20_effects_enabled:
        _v22_micro_shake(2.2, 0.12)

func _v22_micro_shake(amount: float, duration: float) -> void:
    if not is_instance_valid(camera) or not v20_effects_enabled:
        return
    var base := camera.offset
    camera.offset = base + Vector2(amount, -amount * 0.45)
    var tw := create_tween()
    tw.tween_property(camera, "offset", base + Vector2(-amount * 0.55, amount * 0.25), duration * 0.45)
    tw.tween_property(camera, "offset", base, duration * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _v22_add_level_transition(was_restart: bool) -> void:
    if not is_instance_valid(hud): return
    var curtain := ColorRect.new()
    curtain.size = Vector2(1280, 720)
    curtain.color = Color(0.03, 0.06, 0.10, 0.92 if not was_restart else 0.62)
    curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
    curtain.z_index = 100
    hud.add_child(curtain)
    var label := Label.new()
    label.position = Vector2(390, 285)
    label.size = Vector2(500, 100)
    label.text = "%d-%d" % [chapter, part]
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 44 if not was_restart else 28)
    label.add_theme_color_override("font_color", Color.WHITE)
    label.z_index = 101
    hud.add_child(label)
    var sub := Label.new()
    sub.position = Vector2(390, 365)
    sub.size = Vector2(500, 38)
    sub.text = "TEKRAR" if was_restart else ("İLK DÖNEM FİNALİ" if chapter == 20 else "TROLL PARKOUR")
    sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sub.add_theme_font_size_override("font_size", 14)
    sub.add_theme_color_override("font_color", Color(0.54, 0.88, 0.95, 0.88) if chapter != 20 else Color(0.96, 0.76, 0.32, 0.92))
    sub.z_index = 101
    hud.add_child(sub)
    var tw := create_tween()
    tw.tween_interval(0.08 if was_restart else 0.14)
    tw.set_parallel(true)
    tw.tween_property(curtain, "color:a", 0.0, 0.24 if was_restart else 0.34)
    tw.tween_property(label, "modulate:a", 0.0, 0.20 if was_restart else 0.30)
    tw.tween_property(sub, "modulate:a", 0.0, 0.20 if was_restart else 0.30)
    tw.set_parallel(false)
    tw.tween_callback(curtain.queue_free)
    tw.tween_callback(label.queue_free)
    tw.tween_callback(sub.queue_free)

func _show_main_menu() -> void:
    active_map_key = ""
    timer_label = null
    RenderingServer.set_default_clear_color(V22_BG)
    if is_instance_valid(world): world.queue_free()
    world = null
    if is_instance_valid(hud): hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)
    camera = null
    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V22_BG
    hud.add_child(bg)
    for i in range(6):
        var slash := Line2D.new()
        slash.width = 2.0
        slash.default_color = Color(0.10, 0.43, 0.55, 0.035 + float(i) * 0.005)
        slash.points = PackedVector2Array([Vector2(-120 + i * 245, 720), Vector2(170 + i * 245, 410)])
        hud.add_child(slash)
    var top := ColorRect.new()
    top.size = Vector2(1280, 114)
    top.color = V22_INK
    hud.add_child(top)
    var line := ColorRect.new()
    line.position = Vector2(0, 110)
    line.size = Vector2(1280, 4)
    line.color = V22_GOLD
    hud.add_child(line)
    var version := Label.new()
    version.position = Vector2(28, 22)
    version.size = Vector2(300, 34)
    version.text = "ANDROID • v2.2"
    version.add_theme_font_size_override("font_size", 20)
    version.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(version)
    var badge := Label.new()
    badge.position = Vector2(28, 58)
    badge.size = Vector2(430, 28)
    badge.text = "60 HARİTA EŞİĞİ • İLK DÖNEM FİNALİ"
    badge.add_theme_font_size_override("font_size", 13)
    badge.add_theme_color_override("font_color", Color(0.96, 0.78, 0.38, 1.0))
    hud.add_child(badge)
    var records := Label.new()
    records.position = Vector2(900, 33)
    records.size = Vector2(350, 44)
    records.text = "REKOR KAYDI  %d / 60" % best_times_ms.size()
    records.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    records.add_theme_font_size_override("font_size", 17)
    records.add_theme_color_override("font_color", Color(1, 1, 1, 0.76))
    hud.add_child(records)
    var title := Label.new()
    title.position = Vector2(95, 145)
    title.size = Vector2(630, 108)
    title.text = "TROLL\nPARKOUR"
    title.add_theme_font_size_override("font_size", 56)
    title.add_theme_color_override("font_color", V22_INK)
    hud.add_child(title)
    var subtitle := Label.new()
    subtitle.position = Vector2(100, 260)
    subtitle.size = Vector2(620, 64)
    subtitle.text = "Bölüm 20: İlk 60 haritanın ustalık testi. Sonraki dönem daha karanlık."
    subtitle.add_theme_font_size_override("font_size", 19)
    subtitle.add_theme_color_override("font_color", V22_MUTED)
    hud.add_child(subtitle)
    var available := maxi(1, mini(unlocked_chapter, 20))
    var completed_maps := maxi(0, (mini(unlocked_chapter, 21) - 1) * 3)
    var stat_panel := Panel.new()
    stat_panel.position = Vector2(785, 148)
    stat_panel.size = Vector2(400, 182)
    stat_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stat_panel.add_theme_stylebox_override("panel", _v20_panel_style(Color(1, 1, 1, 0.80), Color(0.55, 0.43, 0.18, 0.20), 22))
    hud.add_child(stat_panel)
    var stat := Label.new()
    stat.position = Vector2(820, 174)
    stat.size = Vector2(330, 125)
    stat.text = "AÇIK BÖLÜM   %d / 20\nHARİTA        %d / 60\nTOPLAM ÖLÜM   %d" % [available, completed_maps, deaths]
    stat.add_theme_font_size_override("font_size", 18)
    stat.add_theme_color_override("font_color", V22_SLATE)
    hud.add_child(stat)
    var content := Label.new()
    content.position = Vector2(100, 348)
    content.size = Vector2(620, 28)
    content.text = "İÇERİK ÜRETİMİ  60 / 300"
    content.add_theme_font_size_override("font_size", 15)
    content.add_theme_color_override("font_color", V22_MUTED)
    hud.add_child(content)
    var bar_bg := ColorRect.new()
    bar_bg.position = Vector2(100, 382)
    bar_bg.size = Vector2(620, 10)
    bar_bg.color = Color(0.36, 0.44, 0.54, 0.16)
    hud.add_child(bar_bg)
    var bar := ColorRect.new()
    bar.position = Vector2(100, 382)
    bar.size = Vector2(620.0 * 60.0 / 300.0, 10)
    bar.color = V22_GOLD
    hud.add_child(bar)
    var feature := Label.new()
    feature.position = Vector2(100, 425)
    feature.size = Vector2(625, 195)
    feature.text = "v2.2 GELİŞTİRMELER\n\n• Akıcı harita giriş/geçiş animasyonu\n• Platform yüzey detayları ve mikro kamera tepkisi\n• Oyun içi hızlı YENİDEN butonu\n• Kalıcı SES AÇIK/KAPALI ayarı"
    feature.add_theme_font_size_override("font_size", 17)
    feature.add_theme_color_override("font_color", V22_SLATE)
    hud.add_child(feature)
    _menu_button("DEVAM ET", Vector2(790, 350), Vector2(390, 60), func(): _start_level(maxi(1, mini(unlocked_chapter, 20)), 1))
    _menu_button("BÖLÜMLER", Vector2(790, 422), Vector2(390, 60), func(): _show_chapter_select())
    _menu_button("EFEKTLER: %s" % ("AÇIK" if v20_effects_enabled else "KAPALI"), Vector2(790, 494), Vector2(390, 54), func(): _toggle_v20_effects())
    _menu_button("SES: %s" % ("AÇIK" if v22_sound_enabled else "KAPALI"), Vector2(790, 560), Vector2(390, 54), func(): _toggle_v22_sound())
    _menu_button("1. BÖLÜMDEN BAŞLA", Vector2(790, 626), Vector2(390, 50), func(): _start_level(1, 1))

func _show_chapter_select() -> void:
    timer_label = null
    RenderingServer.set_default_clear_color(V22_BG)
    if is_instance_valid(hud): hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)
    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V22_BG
    hud.add_child(bg)
    var top := ColorRect.new()
    top.size = Vector2(1280, 82)
    top.color = V22_INK
    hud.add_child(top)
    var gold := ColorRect.new()
    gold.position = Vector2(0, 79)
    gold.size = Vector2(1280, 3)
    gold.color = V22_GOLD
    hud.add_child(gold)
    var title := Label.new()
    title.position = Vector2(70, 18)
    title.size = Vector2(500, 46)
    title.text = "BÖLÜM SEÇ"
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(title)
    var info := Label.new()
    info.position = Vector2(660, 24)
    info.size = Vector2(550, 36)
    info.text = "20 BÖLÜM • 60 HARİTA • SES %s" % ("AÇIK" if v22_sound_enabled else "KAPALI")
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    info.add_theme_font_size_override("font_size", 16)
    info.add_theme_color_override("font_color", Color(1, 1, 1, 0.72))
    hud.add_child(info)
    for i in range(1, 21):
        var chapter_id := i
        var is_unlocked := chapter_id <= unlocked_chapter
        var col := (i - 1) % 4
        var row := int((i - 1) / 4)
        var pos := Vector2(55 + col * 300, 104 + row * 76)
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
        elif chapter_id == 19: suffix = "DALGA"
        elif chapter_id == 20: suffix = "EŞİK / FİNAL"
        var button_text := "BÖLÜM %d\n%s" % [chapter_id, suffix] if is_unlocked else "BÖLÜM %d\nKİLİTLİ" % chapter_id
        var button := _menu_button(button_text, pos, Vector2(270, 58), func(): _start_level(chapter_id, 1))
        button.disabled = not is_unlocked
    var note := Label.new()
    note.position = Vector2(130, 505)
    note.size = Vector2(1020, 40)
    note.text = "Bölüm 20 ilk 60 haritanın finalidir. Bölüm 21 ile karanlık tema dönemi başlayacak."
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    note.add_theme_font_size_override("font_size", 16)
    note.add_theme_color_override("font_color", V22_MUTED)
    hud.add_child(note)
    _menu_button("GERİ", Vector2(490, 565), Vector2(300, 60), func(): _show_main_menu())

func _show_chapter_result() -> void:
    if chapter != 20:
        super._show_chapter_result()
        return
    timer_label = null
    if is_instance_valid(world): world.queue_free()
    world = null
    if is_instance_valid(hud): hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)
    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V22_INK
    hud.add_child(bg)
    var gold := ColorRect.new()
    gold.size = Vector2(1280, 5)
    gold.color = V22_GOLD
    hud.add_child(gold)
    var title := Label.new()
    title.position = Vector2(140, 58)
    title.size = Vector2(1000, 260)
    title.text = "BÖLÜM 20 TAMAMLANDI\n\n60 HARİTA TAMAM\nİLK DÖNEM BİTTİ"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 39)
    title.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(title)
    var stats := Label.new()
    stats.position = Vector2(95, 315)
    stats.size = Vector2(1090, 155)
    stats.text = "20-1  %s / %s ölüm     20-2  %s / %s ölüm     20-3  %s / %s ölüm\n\nSIRADAKİ DÖNEM: KARANLIK TEMA + DAHA BİRLİKTE ÇALIŞAN TUZAKLAR" % [_best_time_text(20, 1), _best_deaths_text(20, 1), _best_time_text(20, 2), _best_deaths_text(20, 2), _best_time_text(20, 3), _best_deaths_text(20, 3)]
    stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    stats.add_theme_font_size_override("font_size", 19)
    stats.add_theme_color_override("font_color", V22_GOLD)
    hud.add_child(stats)
    var milestone := Label.new()
    milestone.position = Vector2(180, 485)
    milestone.size = Vector2(920, 45)
    milestone.text = "20 / 100 BÖLÜM   •   60 / 300 HARİTA   •   %20 İÇERİK"
    milestone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    milestone.add_theme_font_size_override("font_size", 18)
    milestone.add_theme_color_override("font_color", Color(1, 1, 1, 0.70))
    hud.add_child(milestone)
    _menu_button("ANA MENÜ", Vector2(490, 565), Vector2(300, 64), func(): _show_main_menu())

func _v22_add_chapter20_decor() -> void:
    if not is_instance_valid(world): return
    var horizon := Line2D.new()
    horizon.width = 2.0
    horizon.default_color = Color(0.72, 0.52, 0.14, 0.10)
    horizon.points = PackedVector2Array([Vector2(0, 438), Vector2(level_width, 438)])
    horizon.z_index = -23
    world.add_child(horizon)
    for i in range(int(level_width / 520.0) + 1):
        var x := 150.0 + float(i) * 520.0
        var diamond := Line2D.new()
        diamond.width = 2.0
        diamond.default_color = Color(0.75, 0.55, 0.16, 0.055)
        diamond.closed = true
        diamond.points = PackedVector2Array([Vector2(x, 375), Vector2(x + 36, 410), Vector2(x, 445), Vector2(x - 36, 410)])
        diamond.z_index = -22
        world.add_child(diamond)

func _v22_exam_beacon(pos: Vector2, label_text: String) -> void:
    var stem := Line2D.new()
    stem.position = pos
    stem.width = 3.0
    stem.default_color = Color(0.67, 0.49, 0.14, 0.38)
    stem.points = PackedVector2Array([Vector2(0, 0), Vector2(0, -78)])
    world.add_child(stem)
    var ring := Line2D.new()
    ring.position = pos + Vector2(0, -88)
    ring.width = 3.0
    ring.default_color = Color(0.88, 0.67, 0.24, 0.62)
    ring.closed = true
    ring.points = _circle_points(15.0, 22)
    world.add_child(ring)
    _text(pos + Vector2(-28, -128), label_text, 15, V22_AMBER)
    if v20_effects_enabled:
        var tw := create_tween().set_loops()
        tw.tween_property(ring, "scale", Vector2(1.15, 1.15), 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        tw.tween_property(ring, "scale", Vector2.ONE, 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _v22_safe_flash(pos: Vector2) -> void:
    if not v20_effects_enabled or not is_instance_valid(world): return
    var ring := Line2D.new()
    ring.position = pos
    ring.width = 2.0
    ring.default_color = Color(0.14, 0.74, 0.38, 0.32)
    ring.closed = true
    ring.points = _circle_points(25.0, 22)
    ring.z_index = 20
    world.add_child(ring)
    var tw := create_tween()
    tw.set_parallel(true)
    tw.tween_property(ring, "scale", Vector2(2.3, 2.3), 0.28)
    tw.tween_property(ring, "modulate:a", 0.0, 0.28)
    tw.set_parallel(false)
    tw.tween_callback(ring.queue_free)

func _level_20_1() -> void:
    _floor_with_gaps(7200, [Vector2(1880, 2040), Vector2(4380, 4540)])
    _text(Vector2(120, 470), "BÖLÜM 20: İLK SINAVIN SON HALİ.", 23, V22_AMBER)
    _text(Vector2(430, 520), "GÖRÜNÜŞ, SES VE ZAMANLAMAYI BİRLİKTE OKU.", 18, V22_MUTED)
    _v22_exam_beacon(Vector2(520, 610), "I")
    var safe_plate := _safe_pad(Vector2(910, 548), 190.0)
    _trigger(Rect2(650, 390, 130, 240), func():
        if _once("201_safe"):
            _play_tone(760.0, 0.08, 0.10)
            _v22_safe_flash(safe_plate.global_position)
    )
    var delayed := _spikes(Vector2(1460, 612), 3, true)
    _trigger(Rect2(1180, 390, 120, 240), func(): _timed_hazard(delayed, 0.32, 0.44, "201_delayed"))
    _moving_platform(Vector2(1960, 555), Vector2(150, 24), Vector2(2000, 468), 1.34, V22_BLUE)
    _v22_exam_beacon(Vector2(2350, 610), "II")
    _trigger(Rect2(2530, 390, 120, 240), func():
        if _once("201_sound_fake"):
            _play_tone(880.0, 0.08, 0.12)
            _false_alarm()
    )
    var silent := _spikes(Vector2(3190, 612), 3, true)
    _trigger(Rect2(2860, 390, 120, 240), func():
        if _once("201_silent"):
            var tw := create_tween()
            tw.tween_interval(0.30)
            tw.tween_callback(func(): _reveal(silent))
            tw.tween_interval(0.44)
            tw.tween_callback(func(): _hide(silent))
    )
    var upper := _platform(Vector2(3710, 470), Vector2(220, 24), V22_BLUE)
    _route_hint(Vector2(3580, 430), "ÜST")
    _route_hint(Vector2(3580, 545), "ALT")
    _trigger(Rect2(3490, 320, 200, 175), func():
        if _choose_route("upper"): _v22_safe_flash(upper.global_position)
    )
    _trigger(Rect2(3490, 500, 200, 150), func():
        if _choose_route("lower"): _false_alarm()
    )
    _moving_platform(Vector2(4460, 555), Vector2(145, 24), Vector2(4500, 470), 1.30, V22_CYAN)
    _v22_exam_beacon(Vector2(4830, 610), "III")
    _spikes(Vector2(5350, 612), 2, false)
    _trigger(Rect2(5650, 390, 120, 240), func():
        if _once("201_rock"):
            var tw := create_tween()
            tw.tween_interval(0.38)
            tw.tween_callback(func(): _boulder(Vector2(6260, 560), -360.0, 68.0))
    )
    _finish(Vector2(6860, 580))

func _level_20_2() -> void:
    _floor_with_gaps(7800, [Vector2(1680, 1840), Vector2(3950, 4110), Vector2(6070, 6230)])
    _text(Vector2(120, 470), "KURALLARI TEK TEK DEĞİL, ZİNCİR HALİNDE KULLAN.", 22, V22_AMBER)
    _text(Vector2(430, 520), "HIZLI OLMAK HER ZAMAN DOĞRU DEĞİL.", 18, V22_MUTED)
    _v22_exam_beacon(Vector2(480, 610), "A")
    var first := _spikes(Vector2(1120, 612), 3, true)
    _trigger(Rect2(800, 390, 120, 240), func(): _timed_hazard(first, 0.34, 0.42, "202_first"))
    _moving_platform(Vector2(1760, 555), Vector2(150, 24), Vector2(1800, 470), 1.34, V22_BLUE)
    _trigger(Rect2(2280, 390, 120, 240), func():
        if _once("202_reverse"): _reverse_controls(0.64)
    )
    var safe_after_reverse := _safe_pad(Vector2(2740, 548), 180.0)
    _trigger(Rect2(2490, 390, 120, 240), func():
        if _once("202_safe_reverse"): _v22_safe_flash(safe_after_reverse.global_position)
    )
    _v22_exam_beacon(Vector2(3250, 610), "B")
    _moving_platform(Vector2(4030, 555), Vector2(145, 24), Vector2(4070, 465), 1.28, V22_CYAN)
    var gate := _hazard_block(Vector2(4740, 220), Vector2(150, 72), V22_RED)
    _trigger(Rect2(4420, 390, 120, 240), func():
        if _once("202_gate"):
            var tw := create_tween()
            tw.tween_interval(0.28)
            tw.tween_property(gate, "position:y", 520.0, 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_interval(0.18)
            tw.tween_property(gate, "position:y", 220.0, 0.48).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )
    var wait_spikes := _spikes(Vector2(5460, 612), 3, true)
    _trigger(Rect2(5100, 390, 300, 240), func(): _wait_check(5280.0, 145.0, 0.95, func(): _timed_hazard(wait_spikes, 0.08, 0.42, "202_wait_spikes"), "202_wait"))
    _moving_platform(Vector2(6150, 555), Vector2(145, 24), Vector2(6190, 470), 1.30, V22_BLUE)
    _v22_exam_beacon(Vector2(6550, 610), "C")
    _trigger(Rect2(6730, 390, 120, 240), func():
        if _once("202_final_fake"):
            _play_tone(920.0, 0.08, 0.10)
            _false_alarm()
    )
    _finish(Vector2(7480, 580))

func _level_20_3() -> void:
    _floor_with_gaps(8800, [Vector2(1760, 1920), Vector2(4100, 4260), Vector2(6480, 6640)])
    var a := _attempt(20, 3)
    _text(Vector2(120, 470), "60. HARİTA: BİLDİĞİN HER ŞEY BURADA.", 24, V22_GOLD)
    _text(Vector2(430, 520), "DENEME %d — DESEN DEĞİŞİR, AMA RASTGELE DEĞİL." % a, 18, V22_MUTED)
    _v22_exam_beacon(Vector2(470, 610), "SEKTÖR 1")
    var opener := _spikes(Vector2(1260, 612), 3, true)
    _trigger(Rect2(850, 390, 120, 240), func():
        if _once("203_open"):
            if a % 2 == 0:
                _false_alarm()
                _v22_safe_flash(Vector2(1260, 590))
            else:
                _timed_hazard(opener, 0.30, 0.44, "203_open_spikes")
    )
    _moving_platform(Vector2(1840, 555), Vector2(150, 24), Vector2(1880, 470), 1.32, V22_BLUE)
    _v22_exam_beacon(Vector2(2320, 610), "SEKTÖR 2")
    _route_hint(Vector2(2570, 420), "ÜST")
    _route_hint(Vector2(2570, 548), "ALT")
    var upper := _platform(Vector2(2790, 470), Vector2(230, 24), V22_BLUE)
    _platform(Vector2(3080, 440), Vector2(210, 24), V22_BLUE)
    var route_gate := _hazard_block(Vector2(3510, 220), Vector2(150, 72), V22_RED)
    _trigger(Rect2(2450, 315, 210, 175), func():
        if _choose_route("upper"):
            if a % 3 == 0:
                var tw := create_tween()
                tw.tween_interval(0.34)
                tw.tween_property(route_gate, "position:y", 520.0, 0.42)
            else:
                _v22_safe_flash(upper.global_position)
    )
    _trigger(Rect2(2450, 500, 210, 150), func():
        if _choose_route("lower"):
            if a % 3 == 1:
                var spikes := _spikes(Vector2(3300, 612), 3, true)
                _timed_hazard(spikes, 0.34, 0.42, "203_lower")
            else:
                _false_alarm()
    )
    _moving_platform(Vector2(4180, 555), Vector2(145, 24), Vector2(4220, 466), 1.28, V22_CYAN)
    _v22_exam_beacon(Vector2(4630, 610), "SEKTÖR 3")
    _trigger(Rect2(4870, 390, 120, 240), func():
        if _once("203_reverse"):
            if a % 4 < 2: _reverse_controls(0.66)
            else: _false_alarm()
    )
    var wait := _spikes(Vector2(5610, 612), 3, true)
    _trigger(Rect2(5260, 390, 300, 240), func():
        _wait_check(5440.0, 145.0, 0.92, func():
            if a % 3 == 2: _false_alarm()
            else: _timed_hazard(wait, 0.08, 0.42, "203_wait_hazard")
        , "203_wait")
    )
    _moving_platform(Vector2(6560, 555), Vector2(145, 24), Vector2(6600, 468), 1.28, V22_BLUE)
    _v22_exam_beacon(Vector2(7000, 610), "FİNAL")
    _spikes(Vector2(7420, 612), 2, false)
    _trigger(Rect2(7680, 390, 120, 240), func():
        if _once("203_final"):
            if a % 2 == 0:
                var tw := create_tween()
                tw.tween_interval(0.36)
                tw.tween_callback(func(): _boulder(Vector2(8350, 560), -355.0, 68.0))
            else:
                var final_spikes := _spikes(Vector2(8020, 612), 3, true)
                _timed_hazard(final_spikes, 0.34, 0.44, "203_final_spikes")
    )
    _finish(Vector2(8500, 580))
