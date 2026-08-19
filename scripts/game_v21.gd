extends "res://scripts/game_v20.gd"

const V21_BG := Color("#e7edf4")
const V21_BG_CH19 := Color("#e4ebf2")
const V21_INK := Color("#0b1220")
const V21_SLATE := Color("#334155")
const V21_MUTED := Color("#64748b")
const V21_BLUE := Color("#2563eb")
const V21_CYAN := Color("#0891b2")
const V21_GREEN := Color("#16a34a")
const V21_AMBER := Color("#d97706")
const V21_RED := Color("#dc4455")
const V21_PURPLE := Color("#7c3aed")
const V21_SOFT := Color("#cbd5e1")

var v21_trail_clock := 0.0

func _safe_load_progress() -> void:
    super._safe_load_progress()
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return
    var stored_unlock = cfg.get_value("progress", "unlocked_chapter", 1)
    if stored_unlock is int or stored_unlock is float:
        unlocked_chapter = clampi(int(stored_unlock), 1, 20)

func _start_level(c: int, p: int) -> void:
    v21_trail_clock = 0.0
    super._start_level(c, p)
    if c == 19:
        RenderingServer.set_default_clear_color(V21_BG_CH19)
        _v21_add_chapter19_decor()

func _process(delta: float) -> void:
    super._process(delta)
    if not v20_effects_enabled or not is_instance_valid(player) or not player.alive:
        return
    v21_trail_clock -= delta
    if v21_trail_clock <= 0.0 and (absf(player.velocity.x) > 245.0 or absf(player.velocity.y) > 360.0):
        v21_trail_clock = 0.085
        _v21_motion_trail()

func _build_level(c: int, p: int) -> void:
    if c == 19 and p == 1:
        _level_19_1()
    elif c == 19 and p == 2:
        _level_19_2()
    elif c == 19 and p == 3:
        _level_19_3()
    else:
        super._build_level(c, p)

func _spawn_player(pos: Vector2) -> void:
    super._spawn_player(pos)
    _v21_upgrade_player_visuals()

func _build_hud() -> void:
    super._build_hud()
    var underglow := ColorRect.new()
    underglow.position = Vector2(0, 71)
    underglow.size = Vector2(1280, 2)
    underglow.color = Color(0.18, 0.70, 0.82, 0.22)
    underglow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(underglow)
    if chapter == 19:
        var mode := Label.new()
        mode.position = Vector2(760, 43)
        mode.size = Vector2(225, 24)
        mode.text = "DALGA / AKTİVASYON"
        mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        mode.add_theme_font_size_override("font_size", 12)
        mode.add_theme_color_override("font_color", V21_PURPLE)
        hud.add_child(mode)

func _v20_add_global_environment() -> void:
    super._v20_add_global_environment()
    if not is_instance_valid(world):
        return
    var rail := Line2D.new()
    rail.width = 2.0
    rail.default_color = Color(0.04, 0.28, 0.42, 0.07)
    rail.points = PackedVector2Array([Vector2(0, 606), Vector2(level_width, 606)])
    rail.z_index = -5
    world.add_child(rail)
    for i in range(int(level_width / 760.0) + 1):
        var x := 220.0 + float(i) * 760.0
        var slash := Line2D.new()
        slash.width = 3.0
        slash.default_color = Color(0.05, 0.42, 0.56, 0.035)
        slash.points = PackedVector2Array([
            Vector2(x - 120, 330), Vector2(x - 35, 250), Vector2(x + 70, 330)
        ])
        slash.z_index = -52
        world.add_child(slash)

func _finish(pos: Vector2) -> Area2D:
    var area := super._finish(pos)
    if not is_instance_valid(area):
        return area
    var outer := Line2D.new()
    outer.width = 2.0
    outer.default_color = Color(0.14, 0.78, 0.39, 0.38)
    outer.closed = true
    outer.points = _circle_points(62.0, 30)
    outer.z_index = -1
    area.add_child(outer)
    var inner := Line2D.new()
    inner.width = 2.0
    inner.default_color = Color(0.35, 0.95, 0.62, 0.26)
    inner.closed = true
    inner.points = _circle_points(48.0, 26)
    inner.z_index = -1
    area.add_child(inner)
    if v20_effects_enabled:
        var tw := create_tween().set_loops()
        tw.set_parallel(true)
        tw.tween_property(outer, "rotation", TAU, 3.2)
        tw.tween_property(inner, "rotation", -TAU, 2.6)
        tw.set_parallel(false)
        var pulse := create_tween().set_loops()
        pulse.tween_property(outer, "modulate:a", 0.30, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        pulse.tween_property(outer, "modulate:a", 1.0, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    area.body_entered.connect(func(body):
        if body == player and v20_effects_enabled and not area.has_meta("v21_finish_burst"):
            area.set_meta("v21_finish_burst", true)
            _v21_finish_burst(area.global_position)
    )
    return area

func _reveal(area: Area2D) -> void:
    super._reveal(area)
    if v20_effects_enabled and is_instance_valid(area):
        _v21_hazard_activation_fx(area.global_position)

func _hide(area: Area2D) -> void:
    if v20_effects_enabled and is_instance_valid(area):
        _v21_hazard_dissolve_fx(area.global_position)
    super._hide(area)

func _on_player_died() -> void:
    if restarting or level_finished:
        return
    if v20_effects_enabled:
        _v21_death_flash()
    super._on_player_died()

func _v21_upgrade_player_visuals() -> void:
    if not is_instance_valid(player):
        return
    var shadow := Polygon2D.new()
    shadow.name = "V21Shadow"
    shadow.position = Vector2(4, 5)
    shadow.polygon = PackedVector2Array([
        Vector2(-20, -20), Vector2(20, -20), Vector2(20, 20), Vector2(-20, 20)
    ])
    shadow.color = Color(0.02, 0.05, 0.09, 0.20)
    shadow.z_index = -3
    player.add_child(shadow)

    var outline := Line2D.new()
    outline.name = "V21Outline"
    outline.width = 2.5
    outline.default_color = Color(0.35, 0.82, 0.92, 0.72)
    outline.closed = true
    outline.points = PackedVector2Array([
        Vector2(-20, -20), Vector2(20, -20), Vector2(20, 20), Vector2(-20, 20)
    ])
    outline.z_index = 4
    player.add_child(outline)

    var crest := Polygon2D.new()
    crest.name = "V21Crest"
    crest.position = Vector2(0, -14)
    crest.polygon = PackedVector2Array([
        Vector2(-11, -2), Vector2(11, -2), Vector2(8, 2), Vector2(-8, 2)
    ])
    crest.color = Color(0.24, 0.83, 0.94, 0.70)
    crest.z_index = 3
    player.add_child(crest)

    for x in [-6.0, 7.0]:
        var pupil := Polygon2D.new()
        pupil.position = Vector2(x, -5)
        pupil.polygon = PackedVector2Array([
            Vector2(-1.3, -1.3), Vector2(1.3, -1.3), Vector2(1.3, 1.3), Vector2(-1.3, 1.3)
        ])
        pupil.color = V21_INK
        pupil.z_index = 4
        player.add_child(pupil)

func _v21_motion_trail() -> void:
    if not is_instance_valid(world) or not is_instance_valid(player):
        return
    var ghost := Polygon2D.new()
    ghost.position = player.global_position
    ghost.polygon = PackedVector2Array([
        Vector2(-18, -18), Vector2(18, -18), Vector2(18, 18), Vector2(-18, 18)
    ])
    ghost.color = Color(0.05, 0.55, 0.68, 0.14)
    ghost.z_index = 8
    world.add_child(ghost)
    var drift := Vector2(-signf(player.velocity.x) * 18.0, 3.0)
    var tw := create_tween()
    tw.set_parallel(true)
    tw.tween_property(ghost, "position", ghost.position + drift, 0.20)
    tw.tween_property(ghost, "scale", Vector2(0.72, 0.72), 0.20)
    tw.tween_property(ghost, "modulate:a", 0.0, 0.20)
    tw.set_parallel(false)
    tw.tween_callback(ghost.queue_free)

func _v21_finish_burst(origin: Vector2) -> void:
    if not is_instance_valid(world):
        return
    _play_tone(1040.0, 0.13, 0.16)
    for ring_i in range(2):
        var ring := Line2D.new()
        ring.position = origin
        ring.width = 3.0 - float(ring_i)
        ring.default_color = Color(0.15, 0.82, 0.42, 0.48 - float(ring_i) * 0.12)
        ring.closed = true
        ring.points = _circle_points(28.0 + float(ring_i) * 12.0, 28)
        ring.z_index = 24
        world.add_child(ring)
        var twr := create_tween()
        twr.set_parallel(true)
        twr.tween_property(ring, "scale", Vector2(2.8, 2.8), 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        twr.tween_property(ring, "modulate:a", 0.0, 0.38)
        twr.set_parallel(false)
        twr.tween_callback(ring.queue_free)
    for i in range(10):
        var shard := Polygon2D.new()
        shard.position = origin
        var s := 3.0 + float(i % 3)
        shard.polygon = PackedVector2Array([
            Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s)
        ])
        shard.color = V21_GREEN if i % 2 == 0 else V21_CYAN
        shard.z_index = 25
        world.add_child(shard)
        var angle := TAU * float(i) / 10.0
        var target := origin + Vector2(cos(angle), sin(angle)) * (58.0 + float(i % 3) * 14.0)
        var tw := create_tween()
        tw.set_parallel(true)
        tw.tween_property(shard, "position", target, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tw.tween_property(shard, "rotation", angle + 1.4, 0.34)
        tw.tween_property(shard, "modulate:a", 0.0, 0.34)
        tw.set_parallel(false)
        tw.tween_callback(shard.queue_free)
    if is_instance_valid(camera):
        var base_zoom := camera.zoom
        camera.zoom = base_zoom * 0.985
        create_tween().tween_property(camera, "zoom", base_zoom, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _v21_hazard_activation_fx(origin: Vector2) -> void:
    if not is_instance_valid(world):
        return
    var ring := Line2D.new()
    ring.position = origin
    ring.width = 2.0
    ring.default_color = Color(0.86, 0.22, 0.31, 0.42)
    ring.closed = true
    ring.points = _circle_points(24.0, 22)
    ring.z_index = 21
    world.add_child(ring)
    var tr := create_tween()
    tr.set_parallel(true)
    tr.tween_property(ring, "scale", Vector2(2.2, 1.35), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tr.tween_property(ring, "modulate:a", 0.0, 0.18)
    tr.set_parallel(false)
    tr.tween_callback(ring.queue_free)
    for i in range(4):
        var bit := Polygon2D.new()
        bit.position = origin + Vector2(-24.0 + float(i) * 16.0, 0)
        bit.polygon = PackedVector2Array([
            Vector2(-3, -3), Vector2(3, -3), Vector2(3, 3), Vector2(-3, 3)
        ])
        bit.color = Color(V21_RED.r, V21_RED.g, V21_RED.b, 0.56)
        bit.z_index = 22
        world.add_child(bit)
        var t := create_tween()
        t.set_parallel(true)
        t.tween_property(bit, "position:y", bit.position.y - 24.0 - float(i % 2) * 8.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        t.tween_property(bit, "modulate:a", 0.0, 0.20)
        t.set_parallel(false)
        t.tween_callback(bit.queue_free)

func _v21_hazard_dissolve_fx(origin: Vector2) -> void:
    if not is_instance_valid(world):
        return
    for i in range(3):
        var bit := Polygon2D.new()
        bit.position = origin + Vector2(-15.0 + float(i) * 15.0, 0)
        bit.polygon = PackedVector2Array([
            Vector2(-2, -2), Vector2(2, -2), Vector2(2, 2), Vector2(-2, 2)
        ])
        bit.color = Color(0.42, 0.49, 0.58, 0.28)
        bit.z_index = 20
        world.add_child(bit)
        var tw := create_tween()
        tw.set_parallel(true)
        tw.tween_property(bit, "position", bit.position + Vector2(0, 16.0 + float(i) * 3.0), 0.18)
        tw.tween_property(bit, "modulate:a", 0.0, 0.18)
        tw.set_parallel(false)
        tw.tween_callback(bit.queue_free)

func _v21_death_flash() -> void:
    if not is_instance_valid(hud):
        return
    var flash := ColorRect.new()
    flash.size = Vector2(1280, 720)
    flash.color = Color(0.75, 0.05, 0.12, 0.0)
    flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(flash)
    var tw := create_tween()
    tw.tween_property(flash, "color:a", 0.13, 0.05)
    tw.tween_property(flash, "color:a", 0.0, 0.14)
    tw.tween_callback(flash.queue_free)

func _v21_menu_decor() -> void:
    for i in range(5):
        var line := Line2D.new()
        line.width = 2.0
        line.default_color = Color(0.05, 0.48, 0.62, 0.05 + float(i) * 0.008)
        line.points = PackedVector2Array([
            Vector2(40 + i * 205, 690), Vector2(250 + i * 205, 470)
        ])
        hud.add_child(line)

func _show_main_menu() -> void:
    active_map_key = ""
    timer_label = null
    RenderingServer.set_default_clear_color(V21_BG)
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
    bg.color = V21_BG
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(bg)
    _v21_menu_decor()

    var top := ColorRect.new()
    top.size = Vector2(1280, 112)
    top.color = V21_INK
    hud.add_child(top)
    var cyan_line := ColorRect.new()
    cyan_line.position = Vector2(0, 109)
    cyan_line.size = Vector2(1280, 3)
    cyan_line.color = V21_CYAN
    hud.add_child(cyan_line)

    var version := Label.new()
    version.position = Vector2(28, 23)
    version.size = Vector2(280, 34)
    version.text = "ANDROID • v2.1"
    version.add_theme_font_size_override("font_size", 20)
    version.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(version)
    var badge := Label.new()
    badge.position = Vector2(28, 58)
    badge.size = Vector2(390, 28)
    badge.text = "EFEKT / KARAKTER / FINISH YENİLEMESİ"
    badge.add_theme_font_size_override("font_size", 13)
    badge.add_theme_color_override("font_color", Color(0.56, 0.91, 0.96, 1.0))
    hud.add_child(badge)

    var records := Label.new()
    records.position = Vector2(900, 33)
    records.size = Vector2(350, 44)
    records.text = "REKOR KAYDI  %d / 57" % best_times_ms.size()
    records.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    records.add_theme_font_size_override("font_size", 17)
    records.add_theme_color_override("font_color", Color(1, 1, 1, 0.76))
    hud.add_child(records)

    var title := Label.new()
    title.position = Vector2(100, 145)
    title.size = Vector2(620, 105)
    title.text = "TROLL\nPARKOUR"
    title.add_theme_font_size_override("font_size", 56)
    title.add_theme_color_override("font_color", V21_INK)
    hud.add_child(title)

    var subtitle := Label.new()
    subtitle.position = Vector2(105, 258)
    subtitle.size = Vector2(610, 64)
    subtitle.text = "Bölüm 19: Tehlike tek noktada değil, dalga halinde çalışıyor."
    subtitle.add_theme_font_size_override("font_size", 19)
    subtitle.add_theme_color_override("font_color", V21_MUTED)
    hud.add_child(subtitle)

    var available := maxi(1, mini(unlocked_chapter, 19))
    var completed_maps := maxi(0, (mini(unlocked_chapter, 20) - 1) * 3)

    var stat_panel := Panel.new()
    stat_panel.position = Vector2(785, 150)
    stat_panel.size = Vector2(400, 178)
    stat_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stat_panel.add_theme_stylebox_override("panel", _v20_panel_style(Color(1, 1, 1, 0.78), Color(0.21, 0.45, 0.58, 0.20), 22))
    hud.add_child(stat_panel)
    var stat := Label.new()
    stat.position = Vector2(820, 177)
    stat.size = Vector2(330, 120)
    stat.text = "AÇIK BÖLÜM   %d / 19\nHARİTA        %d / 57\nTOPLAM ÖLÜM   %d" % [available, completed_maps, deaths]
    stat.add_theme_font_size_override("font_size", 18)
    stat.add_theme_color_override("font_color", V21_SLATE)
    hud.add_child(stat)

    var content := Label.new()
    content.position = Vector2(105, 345)
    content.size = Vector2(610, 28)
    content.text = "İÇERİK ÜRETİMİ  57 / 300"
    content.add_theme_font_size_override("font_size", 15)
    content.add_theme_color_override("font_color", V21_MUTED)
    hud.add_child(content)
    var bar_bg := ColorRect.new()
    bar_bg.position = Vector2(105, 380)
    bar_bg.size = Vector2(610, 10)
    bar_bg.color = Color(0.36, 0.44, 0.54, 0.16)
    hud.add_child(bar_bg)
    var bar := ColorRect.new()
    bar.position = Vector2(105, 380)
    bar.size = Vector2(610.0 * 57.0 / 300.0, 10)
    bar.color = V21_CYAN
    hud.add_child(bar)

    var feature := Label.new()
    feature.position = Vector2(105, 425)
    feature.size = Vector2(610, 190)
    feature.text = "v2.1 GELİŞTİRMELER\n\n• Animasyonlu finish + bitiş patlaması\n• Tuzak aktivasyon/dissolve efektleri\n• Karakter outline, yüz ve hareket izi\n• Daha katmanlı sahne derinliği"
    feature.add_theme_font_size_override("font_size", 17)
    feature.add_theme_color_override("font_color", V21_SLATE)
    hud.add_child(feature)

    _menu_button("DEVAM ET", Vector2(790, 365), Vector2(390, 64), func(): _start_level(maxi(1, mini(unlocked_chapter, 19)), 1))
    _menu_button("BÖLÜMLER", Vector2(790, 442), Vector2(390, 64), func(): _show_chapter_select())
    _menu_button("1. BÖLÜMDEN BAŞLA", Vector2(790, 519), Vector2(390, 64), func(): _start_level(1, 1))
    _menu_button("EFEKTLER: %s" % ("AÇIK" if v20_effects_enabled else "KAPALI"), Vector2(790, 596), Vector2(390, 56), func(): _toggle_v20_effects())

func _show_chapter_select() -> void:
    timer_label = null
    RenderingServer.set_default_clear_color(V21_BG)
    if is_instance_valid(hud):
        hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)
    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V21_BG
    hud.add_child(bg)
    var top := ColorRect.new()
    top.size = Vector2(1280, 82)
    top.color = V21_INK
    hud.add_child(top)
    var title := Label.new()
    title.position = Vector2(70, 18)
    title.size = Vector2(500, 46)
    title.text = "BÖLÜM SEÇ"
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(title)
    var info := Label.new()
    info.position = Vector2(700, 24)
    info.size = Vector2(510, 36)
    info.text = "19 BÖLÜM • 57 HARİTA • EFEKTLER %s" % ("AÇIK" if v20_effects_enabled else "KAPALI")
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    info.add_theme_font_size_override("font_size", 16)
    info.add_theme_color_override("font_color", Color(1, 1, 1, 0.72))
    hud.add_child(info)

    for i in range(1, 20):
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
        var button_text := "BÖLÜM %d\n%s" % [chapter_id, suffix] if is_unlocked else "BÖLÜM %d\nKİLİTLİ" % chapter_id
        var button := _menu_button(button_text, pos, Vector2(270, 58), func(): _start_level(chapter_id, 1))
        button.disabled = not is_unlocked

    var note := Label.new()
    note.position = Vector2(135, 505)
    note.size = Vector2(1010, 40)
    note.text = "v2.1 finish, tuzak aktivasyonu, karakter ve sahne efektlerini tüm eski bölümlere de uygular."
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    note.add_theme_font_size_override("font_size", 16)
    note.add_theme_color_override("font_color", V21_MUTED)
    hud.add_child(note)
    _menu_button("GERİ", Vector2(490, 565), Vector2(300, 60), func(): _show_main_menu())

func _show_chapter_result() -> void:
    if chapter != 19:
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
    bg.color = V21_INK
    hud.add_child(bg)
    var title := Label.new()
    title.position = Vector2(160, 70)
    title.size = Vector2(960, 270)
    title.text = "BÖLÜM 19 TAMAMLANDI\n\n57 HARİTA TAMAM\nTOPLAM ÖLÜM: %d" % deaths
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 38)
    title.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(title)
    var stats := Label.new()
    stats.position = Vector2(115, 345)
    stats.size = Vector2(1050, 150)
    stats.text = "19-1  %s / %s ölüm     19-2  %s / %s ölüm     19-3  %s / %s ölüm\n\nEFEKT / KARAKTER / FINISH PAKETİ AKTİF" % [
        _best_time_text(19, 1), _best_deaths_text(19, 1),
        _best_time_text(19, 2), _best_deaths_text(19, 2),
        _best_time_text(19, 3), _best_deaths_text(19, 3)
    ]
    stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    stats.add_theme_font_size_override("font_size", 19)
    stats.add_theme_color_override("font_color", Color(0.47, 0.89, 0.96, 1.0))
    hud.add_child(stats)
    _menu_button("ANA MENÜ", Vector2(490, 555), Vector2(300, 64), func(): _show_main_menu())

func _v21_add_chapter19_decor() -> void:
    if not is_instance_valid(world):
        return
    for i in range(int(level_width / 430.0) + 1):
        var x := 120.0 + float(i) * 430.0
        var wave := Line2D.new()
        wave.width = 2.0
        wave.default_color = Color(0.12, 0.46, 0.63, 0.07)
        wave.points = PackedVector2Array([
            Vector2(x - 55, 410), Vector2(x - 25, 390), Vector2(x, 420), Vector2(x + 28, 390), Vector2(x + 58, 410)
        ])
        wave.z_index = -20
        world.add_child(wave)

func _v21_safe_pulse(pos: Vector2, tint: Color = V21_CYAN) -> void:
    if not is_instance_valid(world):
        return
    var ring := Line2D.new()
    ring.position = pos
    ring.width = 3.0
    ring.default_color = Color(tint.r, tint.g, tint.b, 0.42)
    ring.closed = true
    ring.points = _circle_points(28.0, 24)
    ring.z_index = 18
    world.add_child(ring)
    _play_tone(600.0, 0.06, 0.08)
    var tw := create_tween()
    tw.set_parallel(true)
    tw.tween_property(ring, "scale", Vector2(2.7, 1.7), 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tw.tween_property(ring, "modulate:a", 0.0, 0.30)
    tw.set_parallel(false)
    tw.tween_callback(ring.queue_free)

func _v21_wave_three(a: Area2D, b: Area2D, c: Area2D, key: String, reverse: bool = false) -> void:
    if not _once(key):
        return
    var first := c if reverse else a
    var third := a if reverse else c
    var tw := create_tween()
    tw.tween_interval(0.10)
    tw.tween_callback(func(): _reveal(first))
    tw.tween_interval(0.28)
    tw.tween_callback(func(): _hide(first))
    tw.tween_callback(func(): _reveal(b))
    tw.tween_interval(0.28)
    tw.tween_callback(func(): _hide(b))
    tw.tween_callback(func(): _reveal(third))
    tw.tween_interval(0.28)
    tw.tween_callback(func(): _hide(third))

func _v21_wave_middle(a: Area2D, b: Area2D, c: Area2D, key: String) -> void:
    if not _once(key):
        return
    var tw := create_tween()
    tw.tween_interval(0.10)
    tw.tween_callback(func(): _reveal(b))
    tw.tween_interval(0.26)
    tw.tween_callback(func(): _hide(b))
    tw.tween_callback(func(): _reveal(a))
    tw.tween_interval(0.26)
    tw.tween_callback(func(): _hide(a))
    tw.tween_callback(func(): _reveal(c))
    tw.tween_interval(0.26)
    tw.tween_callback(func(): _hide(c))

func _level_19_1() -> void:
    _floor_with_gaps(6900, [Vector2(2100, 2260), Vector2(4480, 4640)])
    _text(Vector2(120, 470), "BÖLÜM 19: TUZAK ARTIK DALGA HALİNDE.", 23, V21_CYAN)
    _text(Vector2(430, 520), "TEK NOKTAYI DEĞİL, SIRAYI OKU.", 18, V21_MUTED)

    var s1 := _spikes(Vector2(1120, 612), 2, true)
    var s2 := _spikes(Vector2(1480, 612), 2, true)
    var s3 := _spikes(Vector2(1840, 612), 3, true)
    _trigger(Rect2(760, 390, 120, 240), func(): _v21_wave_three(s1, s2, s3, "191_wave"))

    _moving_platform(Vector2(2180, 555), Vector2(150, 24), Vector2(2220, 470), 1.34, V21_BLUE)

    _trigger(Rect2(2660, 390, 120, 240), func():
        if _once("191_safe_pulse"):
            _v21_safe_pulse(Vector2(2920, 560))
            _false_alarm()
    )

    var gate := _hazard_block(Vector2(3540, 215), Vector2(150, 72), V21_RED)
    _trigger(Rect2(3190, 390, 120, 240), func():
        if _once("191_gate"):
            var tw := create_tween()
            tw.tween_interval(0.34)
            tw.tween_property(gate, "position:y", 500.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_interval(0.16)
            tw.tween_property(gate, "position:y", 215.0, 0.48).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

    _moving_platform(Vector2(4560, 555), Vector2(145, 24), Vector2(4600, 470), 1.30, V21_CYAN)

    _trigger(Rect2(4950, 390, 120, 240), func():
        if _once("191_rock"):
            var tw := create_tween()
            tw.tween_interval(0.36)
            tw.tween_callback(func(): _boulder(Vector2(5530, 560), -365.0, 68.0))
    )

    var last := _spikes(Vector2(5940, 612), 3, true)
    _trigger(Rect2(5660, 390, 120, 240), func(): _timed_hazard(last, 0.30, 0.44, "191_last"))
    _finish(Vector2(6560, 580))

func _level_19_2() -> void:
    _floor_with_gaps(7400, [Vector2(1600, 1760), Vector2(3950, 4110), Vector2(6020, 6180)])
    _text(Vector2(120, 470), "HER DALGA TEHLİKE DEĞİL.", 23, V21_PURPLE)
    _text(Vector2(430, 520), "GÖRSEL PATLAMA BAZEN SADECE GÖRSEL.", 18, V21_MUTED)

    _trigger(Rect2(650, 390, 120, 240), func():
        if _once("192_fake_open"):
            _v21_safe_pulse(Vector2(930, 560), V21_AMBER)
            _play_tone(820.0, 0.08, 0.10)
    )

    _moving_platform(Vector2(1680, 555), Vector2(150, 24), Vector2(1720, 470), 1.34, V21_BLUE)

    var w1 := _spikes(Vector2(2240, 612), 2, true)
    var w2 := _spikes(Vector2(2540, 612), 3, true)
    var w3 := _spikes(Vector2(2840, 612), 2, true)
    _trigger(Rect2(1940, 390, 120, 240), func(): _v21_wave_three(w1, w2, w3, "192_wave", true))

    var safe := _safe_pad(Vector2(3310, 548), 190.0)
    _trigger(Rect2(3040, 390, 120, 240), func():
        if _once("192_safe"):
            _v21_safe_pulse(Vector2(3310, 545), V21_GREEN)
            create_tween().tween_property(safe, "position:y", 545.0, 0.12)
    )

    _moving_platform(Vector2(4030, 555), Vector2(145, 24), Vector2(4070, 470), 1.28, V21_CYAN)

    var wait_spikes := _spikes(Vector2(4740, 612), 3, true)
    _trigger(Rect2(4420, 390, 300, 240), func():
        _wait_check(4600.0, 145.0, 0.94, func():
            _v21_safe_pulse(Vector2(4720, 560), V21_RED)
            _reveal(wait_spikes)
            var tw := create_tween()
            tw.tween_interval(0.42)
            tw.tween_callback(func(): _hide(wait_spikes))
        , "192_wait")
    )

    _trigger(Rect2(5160, 390, 120, 240), func():
        if _once("192_loud_safe"):
            _play_tone(900.0, 0.10, 0.12)
            _v21_safe_pulse(Vector2(5430, 560), V21_AMBER)
            _false_alarm()
    )

    _moving_platform(Vector2(6100, 555), Vector2(145, 24), Vector2(6140, 470), 1.30, V21_BLUE)
    var silent := _spikes(Vector2(6650, 612), 3, true)
    _trigger(Rect2(6380, 390, 120, 240), func(): _timed_hazard(silent, 0.32, 0.44, "192_silent"))
    _finish(Vector2(7080, 580))

func _level_19_3() -> void:
    _floor_with_gaps(8100, [Vector2(1750, 1910), Vector2(3980, 4140), Vector2(6250, 6410)])
    var a := _attempt(19, 3)
    _text(Vector2(120, 470), "DALGANIN SIRASINI HATIRLIYORUM.", 24, V21_PURPLE)
    _text(Vector2(430, 520), "DENEME %d — DESEN DEĞİŞİR, RASTGELE DEĞİL." % a, 18, V21_MUTED)

    var a1 := _spikes(Vector2(1040, 612), 2, true)
    var a2 := _spikes(Vector2(1320, 612), 2, true)
    var a3 := _spikes(Vector2(1600, 612), 3, true)
    _trigger(Rect2(690, 390, 120, 240), func():
        if a % 3 == 1:
            _v21_wave_three(a1, a2, a3, "193_wave_a")
        elif a % 3 == 2:
            _v21_wave_three(a1, a2, a3, "193_wave_a", true)
        else:
            _v21_wave_middle(a1, a2, a3, "193_wave_a")
    )

    _moving_platform(Vector2(1830, 555), Vector2(150, 24), Vector2(1870, 470), 1.30, V21_CYAN)

    _trigger(Rect2(2360, 390, 120, 240), func():
        if _once("193_signal"):
            if a % 2 == 0:
                _v21_safe_pulse(Vector2(2630, 560), V21_GREEN)
                _false_alarm()
            else:
                var spike := _spikes(Vector2(2700, 612), 3, true)
                _v21_safe_pulse(Vector2(2630, 560), V21_AMBER)
                _timed_hazard(spike, 0.28, 0.42, "193_signal_spike")
    )

    var drop := _safe_pad(Vector2(3300, 548), 190.0)
    _trigger(Rect2(3010, 390, 120, 240), func():
        if _once("193_drop"):
            if a % 3 == 0:
                _delayed_platform_drop(drop, 0.52, 280.0)
            else:
                _v21_safe_pulse(Vector2(3300, 545), V21_CYAN)
    )

    _moving_platform(Vector2(4060, 555), Vector2(145, 24), Vector2(4100, 470), 1.28, V21_BLUE)

    var b1 := _spikes(Vector2(4740, 612), 2, true)
    var b2 := _spikes(Vector2(5050, 612), 3, true)
    var b3 := _spikes(Vector2(5360, 612), 2, true)
    _trigger(Rect2(4420, 390, 120, 240), func():
        if a % 2 == 0:
            _v21_wave_three(b1, b2, b3, "193_wave_b", true)
        else:
            _v21_wave_middle(b1, b2, b3, "193_wave_b")
    )

    _trigger(Rect2(5680, 390, 120, 240), func():
        if _once("193_reverse"):
            if a % 4 == 0:
                _reverse_controls(0.64)
                _v21_safe_pulse(Vector2(5910, 560), V21_PURPLE)
            else:
                _false_alarm()
    )

    _moving_platform(Vector2(6330, 555), Vector2(145, 24), Vector2(6370, 470), 1.28, V21_CYAN)

    _trigger(Rect2(6760, 390, 120, 240), func():
        if _once("193_final"):
            if a % 2 == 0:
                _boulder(Vector2(7340, 560), -360.0, 68.0)
            else:
                var last := _spikes(Vector2(7160, 612), 3, true)
                _timed_hazard(last, 0.34, 0.44, "193_last")
    )

    _finish(Vector2(7750, 580))
