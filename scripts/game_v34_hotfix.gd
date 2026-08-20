extends "res://scripts/game_v33_visual_phase3.gd"

const V34_PANEL := Color("#08111f")
const V34_PANEL_2 := Color("#111c2f")
const V34_CYAN := Color("#4de6ff")
const V34_GREEN := Color("#4ee6a4")
const V34_AMBER := Color("#ffbd59")
const V34_RED := Color("#ff5d73")
const V34_TEXT := Color("#f8fbff")
const V34_MUTED := Color("#94a3b8")

var v34_dev_chapter := 1
var v34_dev_part := 1
var v34_dev_result_overlay: Control

func _build_level(c: int, p: int) -> void:
    if c == 2 and p == 3:
        _v34_level_2_3()
    else:
        super._build_level(c, p)

func _show_main_menu() -> void:
    super._show_main_menu()
    if not is_instance_valid(hud):
        return
    for child in hud.get_children():
        if child is Label:
            var label := child as Label
            if label.text == "ANDROID • v3.3":
                label.text = "ANDROID • v3.4"
    var hotfix := Label.new()
    hotfix.name = "V34HotfixBadge"
    hotfix.position = Vector2(875, 122)
    hotfix.size = Vector2(330, 26)
    hotfix.text = "2-3 HOTFIX • DEV SELECTOR"
    hotfix.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    hotfix.add_theme_font_size_override("font_size", 11)
    hotfix.add_theme_color_override("font_color", Color(V34_AMBER, 0.82))
    hotfix.z_index = 80
    hud.add_child(hotfix)

func _build_hud() -> void:
    super._build_hud()
    if not is_instance_valid(hud):
        return
    if v24_dev_session:
        var next := _v34_next_dev_target(chapter, part)
        var info := Label.new()
        info.name = "V34DevNext"
        info.position = Vector2(880, 45)
        info.size = Vector2(360, 20)
        info.text = "DEV SONRAKİ: %d-%d" % [int(next.x), int(next.y)] if int(next.x) > 0 else "DEV SON HARİTA"
        info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        info.add_theme_font_size_override("font_size", 10)
        info.add_theme_color_override("font_color", Color(V34_CYAN, 0.76))
        info.z_index = 82
        hud.add_child(info)

func _finish_level() -> void:
    if not v24_dev_session:
        super._finish_level()
        return
    if level_finished or restarting:
        return
    level_finished = true
    if is_instance_valid(player):
        player.input_enabled = false
    if v20_effects_enabled:
        _v32_finish_burst()
        _v32_finish_vignette()
        _v32_camera_kick(Vector2(0, -2.0), 0.14)
    _play_tone(880.0, 0.15, 0.16)
    await get_tree().create_timer(0.48).timeout
    _v34_show_dev_result()

func _v24_open_dev_console() -> void:
    if is_instance_valid(v24_dev_overlay) or not is_instance_valid(hud):
        return
    var overlay := ColorRect.new()
    overlay.name = "V34DevConsole"
    overlay.position = Vector2.ZERO
    overlay.size = Vector2(1280, 720)
    overlay.color = Color(0.01, 0.02, 0.04, 0.90)
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    overlay.z_index = 300
    hud.add_child(overlay)
    v24_dev_overlay = overlay

    var panel := ColorRect.new()
    panel.position = Vector2(315, 170)
    panel.size = Vector2(650, 380)
    panel.color = V34_PANEL
    overlay.add_child(panel)

    var title := Label.new()
    title.position = Vector2(40, 28)
    title.size = Vector2(570, 52)
    title.text = "DEVELOPER TOOL"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 29)
    title.add_theme_color_override("font_color", V34_TEXT)
    panel.add_child(title)

    var help := Label.new()
    help.position = Vector2(55, 92)
    help.size = Vector2(540, 76)
    help.text = "WAREXT yaz ve Enter'a bas.\nArdından bölüm ve kısımı ekrandan seç."
    help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    help.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    help.add_theme_font_size_override("font_size", 18)
    help.add_theme_color_override("font_color", V34_MUTED)
    panel.add_child(help)

    var input := LineEdit.new()
    input.position = Vector2(100, 185)
    input.size = Vector2(450, 58)
    input.placeholder_text = "WAREXT"
    input.max_length = 24
    input.add_theme_font_size_override("font_size", 22)
    input.text_submitted.connect(func(_text: String): _v24_execute_dev_command(input.text))
    panel.add_child(input)
    v24_dev_input = input

    var open_selector := _v34_button("HARİTA SEÇİMİNİ AÇ", Vector2(100, 262), Vector2(450, 54), V34_CYAN)
    open_selector.pressed.connect(func():
        if input.text.strip_edges().is_empty():
            input.text = "WAREXT"
        _v24_execute_dev_command(input.text)
    )
    panel.add_child(open_selector)

    var close := _v34_button("KAPAT", Vector2(225, 325), Vector2(200, 44), V34_RED)
    close.pressed.connect(_v24_close_dev_console)
    panel.add_child(close)

    var error := Label.new()
    error.position = Vector2(55, 316)
    error.size = Vector2(540, 28)
    error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    error.add_theme_font_size_override("font_size", 14)
    error.add_theme_color_override("font_color", V34_RED)
    panel.add_child(error)
    v24_dev_error = error
    input.grab_focus()

func _v24_execute_dev_command(command: String) -> void:
    var raw := command.strip_edges().to_upper()
    if raw == "WAREXT":
        _v34_show_dev_selector()
        return
    if raw.begins_with("WAREXT "):
        var target := raw.trim_prefix("WAREXT ").strip_edges()
        var pieces := target.split("-")
        if pieces.size() == 2:
            var chapter_text := String(pieces[0]).strip_edges()
            var part_text := String(pieces[1]).strip_edges()
            if chapter_text.is_valid_int() and part_text.is_valid_int():
                var target_chapter := int(chapter_text)
                var target_part := int(part_text)
                if target_chapter >= 1 and target_chapter <= 25 and target_part >= 1 and target_part <= 3:
                    _v34_start_dev_map(target_chapter, target_part)
                    return
    _v24_dev_error("Sadece WAREXT yaz. Haritayı ekrandan seçeceksin.")

func _v34_show_dev_selector() -> void:
    _v34_replace_dev_overlay("V34DevSelector")
    var overlay := v24_dev_overlay
    if not is_instance_valid(overlay):
        return

    var title := Label.new()
    title.position = Vector2(130, 30)
    title.size = Vector2(1020, 54)
    title.text = "DEV HARİTA SEÇİMİ"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 30)
    title.add_theme_color_override("font_color", V34_TEXT)
    overlay.add_child(title)

    var sub := Label.new()
    sub.position = Vector2(130, 82)
    sub.size = Vector2(1020, 30)
    sub.text = "Önce bölüm seç • Kayıt, kilit ve rekor etkilenmez"
    sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sub.add_theme_font_size_override("font_size", 15)
    sub.add_theme_color_override("font_color", V34_MUTED)
    overlay.add_child(sub)

    for i in range(25):
        var chapter_id := i + 1
        var col := i % 5
        var row := int(i / 5)
        var pos := Vector2(132 + col * 205, 135 + row * 88)
        var button := _v34_button("BÖLÜM %02d" % chapter_id, pos, Vector2(176, 60), V34_CYAN if chapter_id >= 21 else V34_GREEN)
        button.pressed.connect(func(): _v34_show_part_selector(chapter_id))
        overlay.add_child(button)

    var close := _v34_button("KAPAT", Vector2(490, 610), Vector2(300, 54), V34_RED)
    close.pressed.connect(_v24_close_dev_console)
    overlay.add_child(close)

func _v34_show_part_selector(chapter_id: int) -> void:
    _v34_replace_dev_overlay("V34DevPartSelector")
    var overlay := v24_dev_overlay
    if not is_instance_valid(overlay):
        return

    var title := Label.new()
    title.position = Vector2(180, 85)
    title.size = Vector2(920, 70)
    title.text = "BÖLÜM %d\nKISIM SEÇ" % chapter_id
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 32)
    title.add_theme_color_override("font_color", V34_TEXT)
    overlay.add_child(title)

    for p in range(1, 4):
        var part_id := p
        var button := _v34_button("%d-%d" % [chapter_id, part_id], Vector2(260 + (p - 1) * 270, 250), Vector2(220, 150), V34_CYAN)
        button.add_theme_font_size_override("font_size", 32)
        button.pressed.connect(func(): _v34_start_dev_map(chapter_id, part_id))
        overlay.add_child(button)

    var back := _v34_button("BÖLÜMLERE DÖN", Vector2(350, 475), Vector2(280, 58), V34_AMBER)
    back.pressed.connect(_v34_show_dev_selector)
    overlay.add_child(back)
    var close := _v34_button("KAPAT", Vector2(650, 475), Vector2(280, 58), V34_RED)
    close.pressed.connect(_v24_close_dev_console)
    overlay.add_child(close)

func _v34_start_dev_map(target_chapter: int, target_part: int) -> void:
    _v24_close_dev_console()
    if is_instance_valid(v34_dev_result_overlay):
        v34_dev_result_overlay.queue_free()
    v34_dev_result_overlay = null
    v24_dev_session = true
    v34_dev_chapter = target_chapter
    v34_dev_part = target_part
    _start_level(target_chapter, target_part)

func _v34_show_dev_result() -> void:
    if not is_instance_valid(hud):
        return
    if is_instance_valid(v34_dev_result_overlay):
        v34_dev_result_overlay.queue_free()
    var overlay := ColorRect.new()
    overlay.name = "V34DevResult"
    overlay.position = Vector2.ZERO
    overlay.size = Vector2(1280, 720)
    overlay.color = Color(0.015, 0.025, 0.045, 0.94)
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    overlay.z_index = 320
    hud.add_child(overlay)
    v34_dev_result_overlay = overlay

    var title := Label.new()
    title.position = Vector2(190, 115)
    title.size = Vector2(900, 150)
    title.text = "DEV TEST TAMAMLANDI\n%d-%d\nKAYIT / REKOR DEĞİŞTİRİLMEDİ" % [chapter, part]
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 30)
    title.add_theme_color_override("font_color", V34_GREEN)
    overlay.add_child(title)

    var next := _v34_next_dev_target(chapter, part)
    var continue_text := "DEVAM ET → %d-%d" % [int(next.x), int(next.y)] if int(next.x) > 0 else "SON HARİTA"
    var cont := _v34_button(continue_text, Vector2(385, 315), Vector2(510, 66), V34_CYAN)
    cont.disabled = int(next.x) <= 0
    cont.pressed.connect(_v34_continue_dev)
    overlay.add_child(cont)

    var choose := _v34_button("HARİTA SEÇ", Vector2(385, 405), Vector2(245, 60), V34_AMBER)
    choose.pressed.connect(_v34_show_dev_selector)
    overlay.add_child(choose)

    var menu := _v34_button("ANA MENÜ", Vector2(650, 405), Vector2(245, 60), V34_RED)
    menu.pressed.connect(_v34_exit_dev_to_menu)
    overlay.add_child(menu)

func _v34_continue_dev() -> void:
    var next := _v34_next_dev_target(chapter, part)
    if int(next.x) <= 0:
        _v34_show_dev_selector()
        return
    _v34_start_dev_map(int(next.x), int(next.y))

func _v34_next_dev_target(c: int, p: int) -> Vector2i:
    if p < 3:
        return Vector2i(c, p + 1)
    if c < 25:
        return Vector2i(c + 1, 1)
    return Vector2i(-1, -1)

func _v34_exit_dev_to_menu() -> void:
    v24_dev_session = false
    if is_instance_valid(v34_dev_result_overlay):
        v34_dev_result_overlay.queue_free()
    v34_dev_result_overlay = null
    _show_main_menu()

func _v34_replace_dev_overlay(node_name: String) -> void:
    if not is_instance_valid(hud):
        return
    if is_instance_valid(v24_dev_overlay):
        v24_dev_overlay.queue_free()
    var overlay := ColorRect.new()
    overlay.name = node_name
    overlay.position = Vector2.ZERO
    overlay.size = Vector2(1280, 720)
    overlay.color = Color(0.01, 0.02, 0.04, 0.94)
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    overlay.z_index = 330
    hud.add_child(overlay)
    v24_dev_overlay = overlay
    v24_dev_input = null
    v24_dev_error = null

func _v34_button(text: String, pos: Vector2, size: Vector2, accent: Color) -> Button:
    var button := Button.new()
    button.position = pos
    button.size = size
    button.text = text
    button.add_theme_font_size_override("font_size", 17)
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color(V34_PANEL_2, 0.97)
    normal.border_width_left = 2
    normal.border_width_top = 2
    normal.border_width_right = 2
    normal.border_width_bottom = 2
    normal.border_color = Color(accent, 0.58)
    normal.corner_radius_top_left = 10
    normal.corner_radius_top_right = 10
    normal.corner_radius_bottom_left = 10
    normal.corner_radius_bottom_right = 10
    var hover := normal.duplicate() as StyleBoxFlat
    hover.bg_color = Color(accent, 0.15)
    hover.border_color = Color(accent, 0.90)
    var pressed := normal.duplicate() as StyleBoxFlat
    pressed.bg_color = Color(accent, 0.24)
    button.add_theme_stylebox_override("normal", normal)
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", pressed)
    button.add_theme_color_override("font_color", V34_TEXT)
    button.add_theme_color_override("font_hover_color", Color.WHITE)
    return button

func _v34_level_2_3() -> void:
    _base_floor(4550)
    _text(Vector2(120, 470), "SON TEST: DURMA. AMA ÇOK DA KOŞMA.", 24, C_MUTED)

    var chase_wall := _hazard_block(Vector2(250, 500), Vector2(84, 286), C_RED_DARK)
    _trigger(Rect2(410, 390, 110, 250), func():
        if _once("23_chase_v34"):
            create_tween().tween_property(chase_wall, "position:x", 2780.0, 12.4).set_trans(Tween.TRANS_LINEAR)
    )

    var floor_trap1 := _spikes(Vector2(900, 612), 3, true)
    var floor_trap2 := _spikes(Vector2(1260, 612), 3, true)
    _trigger(Rect2(700, 410, 120, 230), func():
        if _once("23_floor_v34"):
            _reveal(floor_trap1)
            var tw := create_tween()
            tw.tween_interval(0.58)
            tw.tween_callback(func(): _hide(floor_trap1))
            tw.tween_interval(0.12)
            tw.tween_callback(func(): _reveal(floor_trap2))
            tw.tween_interval(0.62)
            tw.tween_callback(func(): _hide(floor_trap2))
    )

    var moving := _platform(Vector2(1710, 560), Vector2(220, 24), C_BLUE)
    _trigger(Rect2(1590, 430, 90, 205), func():
        if _once("23_move_v34"):
            var tw := create_tween()
            tw.tween_interval(0.08)
            tw.tween_property(moving, "position", Vector2(1840, 515), 0.62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
            tw.tween_interval(0.34)
            tw.tween_property(moving, "position", Vector2(1710, 560), 0.60).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    )

    _text(Vector2(2050, 455), "ACELE ETME.", 15, C_MUTED)
    _spikes(Vector2(2300, 612), 3, false)
    var corridor := _platform(Vector2(2300, 550), Vector2(270, 26), C_INK)
    corridor.set_meta("v34_required_corridor", true)
    var ceiling_spikes := _spikes(Vector2(2300, 370), 3, true, true)
    _trigger(Rect2(2070, 360, 135, 270), func():
        if _once("23_ceiling_v34"):
            var tw := create_tween()
            tw.tween_interval(0.38)
            tw.tween_callback(func(): _reveal(ceiling_spikes))
            tw.tween_interval(0.46)
            tw.tween_callback(func(): _hide(ceiling_spikes))
    )

    _marker(Vector2(3000, 555), C_GREEN, "BİTTİ")
    _trigger(Rect2(2830, 400, 120, 230), func():
        if _once("23_not_done_v34"):
            _boulder(Vector2(3500, 555), -355.0, 72.0)
            _play_tone(120.0, 0.22, 0.22)
    )

    var final_bridge: Array[StaticBody2D] = []
    for i in range(6):
        final_bridge.append(_platform(Vector2(3370 + i * 145, 565), Vector2(124, 22), C_PURPLE))
    _trigger(Rect2(3220, 400, 110, 225), func():
        if _once("23_final_bridge_v34"):
            for i in range(final_bridge.size()):
                if i == 2 or i == 5:
                    var tw := create_tween()
                    tw.tween_interval(0.42 + float(i) * 0.06)
                    tw.tween_property(final_bridge[i], "position:y", 765.0, 0.54).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
                    tw.tween_interval(0.48)
                    tw.tween_property(final_bridge[i], "position:y", 565.0, 0.56).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    )

    var last_spikes := _spikes(Vector2(4170, 612), 3, true)
    _trigger(Rect2(3950, 400, 110, 230), func():
        if _once("23_last_v34"):
            var tw := create_tween()
            tw.tween_interval(0.34)
            tw.tween_callback(func(): _reveal(last_spikes))
            tw.tween_interval(0.58)
            tw.tween_callback(func(): _hide(last_spikes))
    )
    _finish(Vector2(4390, 580))
