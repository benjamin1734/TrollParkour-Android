extends "res://scripts/game_v4.gd"

const V5_BG := Color("#f3f4f6")
const V5_BG_CH5 := Color("#e9e2ff")
const V5_INK := Color("#111827")
const V5_RED := Color("#ef4444")
const V5_RED_DARK := Color("#7f1d1d")
const V5_GREEN := Color("#22c55e")
const V5_YELLOW := Color("#f59e0b")
const V5_BLUE := Color("#3b82f6")
const V5_PURPLE := Color("#7c3aed")
const V5_MUTED := Color("#6b7280")

var level_attempts: Dictionary = {}

func _load_save() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) == OK:
        deaths = int(cfg.get_value("progress", "deaths", 0))
        unlocked_chapter = int(cfg.get_value("progress", "unlocked_chapter", 1))
        var stored = cfg.get_value("memory", "level_attempts", {})
        if stored is Dictionary:
            level_attempts = stored

func _save() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("progress", "deaths", deaths)
    cfg.set_value("progress", "unlocked_chapter", unlocked_chapter)
    cfg.set_value("memory", "level_attempts", level_attempts)
    cfg.save(SAVE_PATH)

func _attempt_key(c: int, p: int) -> String:
    return "%d-%d" % [c, p]

func _attempt(c: int = chapter, p: int = part) -> int:
    return int(level_attempts.get(_attempt_key(c, p), 1))

func _start_level(c: int, p: int) -> void:
    var key := _attempt_key(c, p)
    level_attempts[key] = int(level_attempts.get(key, 0)) + 1
    _save()
    super._start_level(c, p)
    if c == 5:
        RenderingServer.set_default_clear_color(V5_BG_CH5)

func _build_level(c: int, p: int) -> void:
    if c == 5 and p == 1:
        _level_5_1()
    elif c == 5 and p == 2:
        _level_5_2()
    elif c == 5 and p == 3:
        _level_5_3()
    else:
        super._build_level(c, p)

func _build_hud() -> void:
    super._build_hud()
    if chapter == 5:
        var memory := Label.new()
        memory.position = Vector2(735, 20)
        memory.size = Vector2(245, 34)
        memory.text = "HAFIZA • DENEME %d" % _attempt()
        memory.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        memory.add_theme_font_size_override("font_size", 17)
        memory.add_theme_color_override("font_color", V5_PURPLE)
        hud.add_child(memory)

func _show_main_menu() -> void:
    RenderingServer.set_default_clear_color(V5_BG)
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
    bg.color = V5_BG
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(bg)

    var top_band := ColorRect.new()
    top_band.size = Vector2(1280, 92)
    top_band.color = V5_INK
    top_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(top_band)

    var version := Label.new()
    version.position = Vector2(24, 27)
    version.size = Vector2(250, 40)
    version.text = "ANDROID • v0.6"
    version.add_theme_font_size_override("font_size", 18)
    version.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(version)

    var title := Label.new()
    title.position = Vector2(180, 125)
    title.size = Vector2(920, 95)
    title.text = "TROLL PARKOUR"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 58)
    title.add_theme_color_override("font_color", V5_INK)
    hud.add_child(title)

    var subtitle := Label.new()
    subtitle.position = Vector2(220, 210)
    subtitle.size = Vector2(840, 55)
    subtitle.text = "Bölüm 5'ten itibaren bazı tuzaklar seni hatırlar."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 23)
    subtitle.add_theme_color_override("font_color", V5_MUTED)
    hud.add_child(subtitle)

    var progress := Label.new()
    progress.position = Vector2(300, 280)
    progress.size = Vector2(680, 44)
    var available := maxi(1, mini(unlocked_chapter, 5))
    var completed_maps := maxi(0, (mini(unlocked_chapter, 6) - 1) * 3)
    progress.text = "AÇIK BÖLÜM: %d / 5     HARİTA: %d / 15     ÖLÜM: %d" % [available, completed_maps, deaths]
    progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    progress.add_theme_font_size_override("font_size", 19)
    progress.add_theme_color_override("font_color", V5_RED_DARK)
    hud.add_child(progress)

    _menu_button("DEVAM ET", Vector2(440, 355), Vector2(400, 72), func():
        _start_level(maxi(1, mini(unlocked_chapter, 5)), 1)
    )
    _menu_button("BÖLÜMLER", Vector2(440, 445), Vector2(400, 72), func():
        _show_chapter_select()
    )
    _menu_button("1. BÖLÜMDEN BAŞLA", Vector2(440, 535), Vector2(400, 72), func():
        _start_level(1, 1)
    )

    var warning := Label.new()
    warning.position = Vector2(250, 635)
    warning.size = Vector2(780, 40)
    warning.text = "İpucu: Dün çalışan çözüm bugün seni öldürebilir."
    warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    warning.add_theme_font_size_override("font_size", 18)
    warning.add_theme_color_override("font_color", V5_MUTED)
    hud.add_child(warning)

func _show_chapter_select() -> void:
    if is_instance_valid(hud):
        hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)

    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V5_BG
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(240, 55)
    title.size = Vector2(800, 75)
    title.text = "BÖLÜM SEÇ"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 44)
    title.add_theme_color_override("font_color", V5_INK)
    hud.add_child(title)

    var info := Label.new()
    info.position = Vector2(240, 125)
    info.size = Vector2(800, 42)
    info.text = "5 bölüm • 15 harita • Bölüm 5: Troll Hafızası"
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.add_theme_font_size_override("font_size", 19)
    info.add_theme_color_override("font_color", V5_MUTED)
    hud.add_child(info)

    for i in range(1, 6):
        var chapter_id := i
        var is_unlocked := chapter_id <= unlocked_chapter
        var col := (i - 1) % 2
        var row := int((i - 1) / 2)
        var pos := Vector2(250 + col * 410, 190 + row * 105)
        var suffix := "3 HARİTA"
        if chapter_id == 5:
            suffix = "HAFIZA • 3 HARİTA"
        var button_text := "BÖLÜM %d\n%s" % [chapter_id, suffix] if is_unlocked else "BÖLÜM %d\nKİLİTLİ" % chapter_id
        var button := _menu_button(button_text, pos, Vector2(370, 82), func():
            _start_level(chapter_id, 1)
        )
        button.disabled = not is_unlocked

    _menu_button("GERİ", Vector2(490, 535), Vector2(300, 66), func():
        _show_main_menu()
    )

func _show_chapter_result() -> void:
    if is_instance_valid(world):
        world.queue_free()
    world = null
    if is_instance_valid(hud):
        hud.queue_free()
    hud = CanvasLayer.new()
    add_child(hud)

    var bg := ColorRect.new()
    bg.size = Vector2(1280, 720)
    bg.color = V5_INK
    hud.add_child(bg)

    var title := Label.new()
    title.position = Vector2(190, 110)
    title.size = Vector2(900, 285)
    var map_count := mini(chapter * 3, 15)
    title.text = "BÖLÜM %d TAMAMLANDI\n\nTOPLAM ÖLÜM: %d\nTAMAMLANAN HARİTA: %d / 15" % [chapter, deaths, map_count]
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(title)

    if chapter < 5:
        var next_chapter := chapter + 1
        _menu_button("SONRAKİ BÖLÜM", Vector2(440, 430), Vector2(400, 72), func():
            _start_level(next_chapter, 1)
        )
    else:
        var done := Label.new()
        done.position = Vector2(270, 400)
        done.size = Vector2(740, 82)
        done.text = "15 HARİTA TAMAM\nARTIK OYUN SENİN NASIL OYNADIĞINI BİLİYOR."
        done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        done.add_theme_font_size_override("font_size", 22)
        done.add_theme_color_override("font_color", V5_YELLOW)
        hud.add_child(done)

    _menu_button("ANA MENÜ", Vector2(490, 545), Vector2(300, 68), func():
        _show_main_menu()
    )

func _memory_notice(text: String) -> void:
    _troll_popup(text, V5_PURPLE)
    _play_tone(420.0, 0.10, 0.17)

func _level_5_1() -> void:
    _floor_with_gaps(5000, [Vector2(1450, 1590), Vector2(3260, 3410)])
    var a := _attempt(5, 1)
    _text(Vector2(120, 470), "BÖLÜM 5: OYUN SENİ HATIRLIYOR.", 24, V5_PURPLE)
    _text(Vector2(430, 520), "DENEME %d — AYNI HARİTA. BELKİ." % a, 20, V5_MUTED)

    var memory_spike_a := _spikes(Vector2(850, 612), 3, true)
    var memory_spike_b := _spikes(Vector2(1110, 612), 3, true)
    _trigger(Rect2(620, 390, 120, 240), func():
        if _once("51_memory_spikes"):
            if a % 2 == 1:
                _reveal(memory_spike_a)
                _memory_notice("BUNU HATIRLA")
            else:
                _reveal(memory_spike_b)
                _memory_notice("YANLIŞ YERİ HATIRLADIN")
    )

    var bait := _platform(Vector2(1930, 545), Vector2(200, 26), V5_BLUE)
    var ceiling := _hazard_block(Vector2(1930, 220), Vector2(180, 70), V5_RED_DARK)
    _trigger(Rect2(1700, 380, 135, 250), func():
        if _once("51_platform_memory"):
            if a % 2 == 1:
                create_tween().tween_property(bait, "position:y", 830.0, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
                _memory_notice("PLATFORM ÇÖKER")
            else:
                var tw := create_tween()
                tw.tween_interval(0.20)
                tw.tween_property(ceiling, "position:y", 500.0, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
                tw.tween_interval(0.22)
                tw.tween_property(ceiling, "position:y", 220.0, 0.45)
                _memory_notice("BU SEFER PLATFORM DEĞİL")
    )

    _trigger(Rect2(2440, 390, 120, 240), func():
        if _once("51_teleport_memory"):
            player.velocity = Vector2.ZERO
            if a % 2 == 1:
                player.set_deferred("global_position", Vector2(2180, 560))
                _memory_notice("GERİ")
            else:
                player.set_deferred("global_position", Vector2(2920, 560))
                _memory_notice("BU SEFER İLERİ")
    )

    _trigger(Rect2(3520, 390, 120, 240), func():
        if _once("51_rock"):
            _boulder(Vector2(4070, 560), -510.0, 74.0)
    )

    _spikes(Vector2(4040, 612), 3, false)
    var goal := _finish(Vector2(4680, 580))
    _trigger(Rect2(4430, 390, 120, 240), func():
        if _once("51_goal") and a % 2 == 1:
            create_tween().tween_property(goal, "position:x", 4820.0, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
            _memory_notice("İLK DENEMEDE KAÇARIM")
    )

func _level_5_2() -> void:
    _floor_with_gaps(5400, [Vector2(1740, 1885), Vector2(2890, 3040), Vector2(4290, 4440)])
    var a := _attempt(5, 2)
    _text(Vector2(120, 470), "ŞİMDİ OYUN SENİN ŞÜPHENİ KULLANIYOR.", 24, V5_PURPLE)
    _text(Vector2(430, 520), "DENEME %d", 20, V5_MUTED)

    _marker(Vector2(760, 555), V5_GREEN, "SAFE")
    var safe_laser := _hidden_hazard(Vector2(760, 545), Vector2(260, 24), V5_RED)
    _trigger(Rect2(560, 390, 120, 240), func():
        if _once("52_safe"):
            if a % 2 == 0:
                _reveal(safe_laser)
                var tw := create_tween()
                tw.tween_interval(0.42)
                tw.tween_callback(func(): _hide(safe_laser))
                _memory_notice("ARTIK SAFE DEĞİL")
            else:
                _memory_notice("EVET. GERÇEKTEN SAFE.")
    )

    var bridge_a := _platform(Vector2(1300, 545), Vector2(170, 24), V5_BLUE)
    var bridge_b := _platform(Vector2(1500, 485 if a % 2 == 0 else 545), Vector2(150, 24), V5_BLUE)
    _trigger(Rect2(1080, 380, 120, 250), func():
        if _once("52_bridge") and a % 2 == 1:
            create_tween().tween_property(bridge_a, "position:x", 1440.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    )

    var pop_left := _spikes(Vector2(2310, 612), 3, true)
    var pop_right := _spikes(Vector2(2610, 612), 3, true)
    _trigger(Rect2(2070, 390, 120, 240), func():
        if _once("52_choice"):
            if a % 2 == 1:
                _reveal(pop_left)
            else:
                _reveal(pop_right)
            _memory_notice("TARAF DEĞİŞTİ")
    )

    var crusher := _hazard_block(Vector2(3470, 160), Vector2(100, 190), V5_RED_DARK)
    _trigger(Rect2(3210, 390, 120, 240), func():
        if _once("52_crusher"):
            var tw := create_tween()
            tw.tween_interval(0.15 if a % 2 == 1 else 0.32)
            tw.tween_property(crusher, "position:y", 510.0, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_interval(0.20)
            tw.tween_property(crusher, "position:y", 160.0, 0.48)
    )

    _trigger(Rect2(3820, 390, 120, 240), func():
        if _once("52_rocks"):
            _falling_boulder(Vector2(4020, 10), 62.0, 0.0)
            if a % 2 == 0:
                _falling_boulder(Vector2(4200, -20), 54.0, 0.32)
    )

    var final_spikes := _spikes(Vector2(4780, 612), 3, true)
    _trigger(Rect2(4580, 390, 120, 240), func():
        if _once("52_final"):
            _reveal(final_spikes)
            var tw := create_tween()
            tw.tween_interval(0.34)
            tw.tween_callback(func(): _hide(final_spikes))
    )
    _finish(Vector2(5150, 580))

func _level_5_3() -> void:
    _floor_with_gaps(6100, [Vector2(1500, 1640), Vector2(3360, 3510), Vector2(4880, 5040)])
    var a := _attempt(5, 3)
    var phase := ((a - 1) % 3) + 1
    _text(Vector2(120, 470), "HAFIZA TESTİ: ÇÖZÜMÜN DE TUZAK OLABİLİR.", 24, V5_PURPLE)
    _text(Vector2(430, 520), "DENEME %d • HAFIZA FAZI %d/3" % [a, phase], 20, V5_MUTED)

    var floor_spikes := _spikes(Vector2(880, 612), 3, true)
    var ceiling_spikes := _spikes(Vector2(910, 305), 3, true, true)
    _trigger(Rect2(650, 380, 120, 250), func():
        if _once("53_opening"):
            if phase == 1:
                _reveal(floor_spikes)
                _memory_notice("ZIPLAMAYI ÖĞRENDİN")
            elif phase == 2:
                _reveal(ceiling_spikes)
                _memory_notice("ZIPLAMAYI BEKLİYORDUM")
            else:
                _reveal(floor_spikes)
                var tw := create_tween()
                tw.tween_interval(0.26)
                tw.tween_callback(func(): _hide(floor_spikes))
                _memory_notice("ŞİMDİ KARAR VER")
    )

    var chase := _hazard_block(Vector2(300, 500), Vector2(82, 300), V5_RED_DARK)
    _trigger(Rect2(1150, 390, 120, 240), func():
        if _once("53_chase"):
            create_tween().tween_property(chase, "position:x", 4200.0, 10.0 - float(phase) * 0.35).set_trans(Tween.TRANS_LINEAR)
    )

    var memory_platform := _platform(Vector2(2060, 545), Vector2(190, 26), V5_BLUE)
    _trigger(Rect2(1830, 390, 120, 240), func():
        if _once("53_platform"):
            if phase == 1:
                create_tween().tween_property(memory_platform, "position:y", 830.0, 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            elif phase == 2:
                create_tween().tween_property(memory_platform, "position:x", 2310.0, 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
            else:
                _memory_notice("BU KEZ DOKUNMADIM")
    )

    _trigger(Rect2(2580, 390, 120, 240), func():
        if _once("53_teleport"):
            player.velocity = Vector2.ZERO
            if phase == 1:
                player.set_deferred("global_position", Vector2(2380, 560))
            elif phase == 2:
                player.set_deferred("global_position", Vector2(3090, 560))
            else:
                player.set_deferred("global_position", Vector2(2700, 430))
            _memory_notice("FAZ %d" % phase)
    )

    _trigger(Rect2(3700, 390, 120, 240), func():
        if _once("53_rain"):
            _falling_boulder(Vector2(3920, 0), 68.0, 0.0)
            _falling_boulder(Vector2(4170, -20), 58.0, 0.34)
            if phase == 3:
                _falling_boulder(Vector2(4420, -30), 52.0, 0.66)
    )

    var laser := _hidden_hazard(Vector2(4620, 545), Vector2(310, 24), V5_RED)
    _trigger(Rect2(4390, 390, 120, 240), func():
        if _once("53_laser"):
            var tw := create_tween()
            tw.tween_interval(0.15 + float(phase) * 0.07)
            tw.tween_callback(func(): _reveal(laser))
            tw.tween_interval(0.36)
            tw.tween_callback(func(): _hide(laser))
    )

    _marker(Vector2(5350, 555), V5_GREEN, "FINISH")
    var fake_finish := _spikes(Vector2(5350, 612), 3, true)
    _trigger(Rect2(5160, 390, 120, 240), func():
        if _once("53_fake_finish") and phase == 1:
            _reveal(fake_finish)
            _memory_notice("İLK FAZDA DEĞİL")
    )

    var goal := _finish(Vector2(5800, 580))
    _trigger(Rect2(5560, 390, 120, 240), func():
        if _once("53_goal"):
            if phase == 2:
                create_tween().tween_property(goal, "position:y", 445.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
                _memory_notice("İKİNCİ FAZDA KAÇAR")
            elif phase == 3:
                _memory_notice("TAMAM. BU KEZ GERÇEK.")
    )
