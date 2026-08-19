extends "res://scripts/game_v23_release.gd"

const V24_BG := Color("#e6ecf3")
const V24_PANEL := Color("#111827")
const V24_CYAN := Color("#22d3ee")
const V24_GREEN := Color("#22c55e")
const V24_RED := Color("#ef4444")

var v24_dev_session := false
var v24_dev_overlay: Control
var v24_dev_input: LineEdit
var v24_dev_error: Label

func _build_level(c: int, p: int) -> void:
    if c == 2 and p == 3:
        _v24_level_2_3()
    else:
        super._build_level(c, p)

func _show_main_menu() -> void:
    v24_dev_session = false
    super._show_main_menu()
    if not is_instance_valid(hud):
        return
    for child in hud.get_children():
        if child is Label:
            if child.text == "ANDROID • v2.3":
                child.text = "ANDROID • v2.4"
            elif child.text == "v2.3 • OYNANIŞ DENGE / HATA TARAMASI":
                child.text = "v2.4 • 2-3 HOTFIX / DEVELOPER TOOL"
            elif child.text.begins_with("v2.3 OYNANIŞ DÜZELTMELERİ"):
                child.text = "v2.4 DÜZELTMELERİ\n\n• 2-3 yeniden dengelendi\n• Kalıcı tuzaklar geçici hale getirildi\n• Dar koridor güvenli açıklığa kavuştu\n• Developer komut konsolu eklendi"
    var dev := Button.new()
    dev.position = Vector2(1154, 24)
    dev.size = Vector2(96, 44)
    dev.text = "DEV"
    dev.add_theme_font_size_override("font_size", 15)
    dev.pressed.connect(_v24_open_dev_console)
    hud.add_child(dev)

func _build_hud() -> void:
    super._build_hud()
    if not is_instance_valid(hud):
        return
    for child in hud.get_children():
        if child is Label and child.text == "DENGE v2.3":
            child.text = "HOTFIX v2.4"
    if v24_dev_session:
        var dev_label := Label.new()
        dev_label.position = Vector2(1010, 18)
        dev_label.size = Vector2(235, 30)
        dev_label.text = "DEV %d-%d • KAYIT KAPALI" % [chapter, part]
        dev_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        dev_label.add_theme_font_size_override("font_size", 12)
        dev_label.add_theme_color_override("font_color", V24_CYAN)
        hud.add_child(dev_label)

func _finish_level() -> void:
    if not v24_dev_session:
        super._finish_level()
        return
    if level_finished or restarting:
        return
    level_finished = true
    if is_instance_valid(player):
        player.input_enabled = false
    _play_tone(880.0, 0.15, 0.16)
    var banner := Label.new()
    banner.position = Vector2(300, 210)
    banner.size = Vector2(680, 180)
    banner.text = "DEV TEST TAMAMLANDI\n%d-%d\nKAYIT / REKOR DEĞİŞTİRİLMEDİ" % [chapter, part]
    banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    banner.add_theme_font_size_override("font_size", 28)
    banner.add_theme_color_override("font_color", V24_GREEN)
    hud.add_child(banner)
    await get_tree().create_timer(0.85).timeout
    _show_main_menu()

func _v24_open_dev_console() -> void:
    if is_instance_valid(v24_dev_overlay) or not is_instance_valid(hud):
        return
    var overlay := ColorRect.new()
    overlay.position = Vector2.ZERO
    overlay.size = Vector2(1280, 720)
    overlay.color = Color(0.02, 0.03, 0.05, 0.86)
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    hud.add_child(overlay)
    v24_dev_overlay = overlay

    var panel := ColorRect.new()
    panel.position = Vector2(300, 155)
    panel.size = Vector2(680, 405)
    panel.color = V24_PANEL
    overlay.add_child(panel)

    var title := Label.new()
    title.position = Vector2(50, 35)
    title.size = Vector2(580, 55)
    title.text = "DEVELOPER TOOL"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 30)
    title.add_theme_color_override("font_color", Color.WHITE)
    panel.add_child(title)

    var help := Label.new()
    help.position = Vector2(60, 100)
    help.size = Vector2(560, 72)
    help.text = "Komut biçimi: WAREXT 2-3\nBölüm 1-20 • Kısım 1-3"
    help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    help.add_theme_font_size_override("font_size", 18)
    help.add_theme_color_override("font_color", Color("#94a3b8"))
    panel.add_child(help)

    var input := LineEdit.new()
    input.position = Vector2(90, 185)
    input.size = Vector2(500, 58)
    input.placeholder_text = "WAREXT 2-3"
    input.max_length = 24
    input.add_theme_font_size_override("font_size", 22)
    input.text_submitted.connect(func(_text: String): _v24_execute_dev_command(input.text))
    panel.add_child(input)
    v24_dev_input = input

    var go := Button.new()
    go.position = Vector2(90, 265)
    go.size = Vector2(240, 58)
    go.text = "GİT"
    go.add_theme_font_size_override("font_size", 19)
    go.pressed.connect(func(): _v24_execute_dev_command(input.text))
    panel.add_child(go)

    var close := Button.new()
    close.position = Vector2(350, 265)
    close.size = Vector2(240, 58)
    close.text = "KAPAT"
    close.add_theme_font_size_override("font_size", 19)
    close.pressed.connect(_v24_close_dev_console)
    panel.add_child(close)

    var error := Label.new()
    error.position = Vector2(70, 335)
    error.size = Vector2(540, 42)
    error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    error.add_theme_font_size_override("font_size", 16)
    error.add_theme_color_override("font_color", V24_RED)
    panel.add_child(error)
    v24_dev_error = error
    input.grab_focus()

func _v24_close_dev_console() -> void:
    if is_instance_valid(v24_dev_overlay):
        v24_dev_overlay.queue_free()
    v24_dev_overlay = null
    v24_dev_input = null
    v24_dev_error = null

func _v24_execute_dev_command(command: String) -> void:
    var raw := command.strip_edges().to_upper()
    if not raw.begins_with("WAREXT "):
        _v24_dev_error("Kod WAREXT ile başlamalı. Örnek: WAREXT 2-3")
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
    if target_chapter < 1 or target_chapter > 20:
        _v24_dev_error("Bölüm 1 ile 20 arasında olmalı.")
        return
    if target_part < 1 or target_part > 3:
        _v24_dev_error("Kısım 1 ile 3 arasında olmalı.")
        return
    _v24_close_dev_console()
    v24_dev_session = true
    _start_level(target_chapter, target_part)

func _v24_dev_error(text: String) -> void:
    if is_instance_valid(v24_dev_error):
        v24_dev_error.text = text

func _v24_level_2_3() -> void:
    _base_floor(4550)
    _text(Vector2(120, 470), "SON TEST: DURMA. AMA ÇOK DA KOŞMA.", 24, C_MUTED)

    var chase_wall := _hazard_block(Vector2(250, 500), Vector2(86, 292), C_RED_DARK)
    _trigger(Rect2(400, 390, 120, 250), func():
        if _once("23_chase_v24"):
            create_tween().tween_property(chase_wall, "position:x", 2920.0, 12.8).set_trans(Tween.TRANS_LINEAR)
    )

    var floor_trap1 := _spikes(Vector2(900, 612), 3, true)
    var floor_trap2 := _spikes(Vector2(1260, 612), 3, true)
    _trigger(Rect2(700, 410, 120, 230), func():
        if _once("23_floor_v24"):
            _reveal(floor_trap1)
            var tw := create_tween()
            tw.tween_interval(0.52)
            tw.tween_callback(func(): _hide(floor_trap1))
            tw.tween_interval(0.10)
            tw.tween_callback(func(): _reveal(floor_trap2))
            tw.tween_interval(0.58)
            tw.tween_callback(func(): _hide(floor_trap2))
    )

    var moving := _platform(Vector2(1710, 540), Vector2(220, 26), C_BLUE)
    _trigger(Rect2(1500, 390, 120, 230), func():
        if _once("23_move_v24"):
            var tw := create_tween()
            tw.tween_property(moving, "position:x", 1860.0, 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
            tw.tween_property(moving, "position:y", 485.0, 0.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
            tw.tween_interval(0.30)
            tw.tween_property(moving, "position", Vector2(1710, 540), 0.58).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    )

    _spikes(Vector2(2325, 612), 3, false)
    _platform(Vector2(2325, 500), Vector2(390, 24), C_INK)
    var ceiling_spikes := _spikes(Vector2(2325, 340), 3, true, true)
    _trigger(Rect2(2080, 350, 140, 280), func():
        if _once("23_ceiling_v24"):
            var tw := create_tween()
            tw.tween_interval(0.24)
            tw.tween_callback(func(): _reveal(ceiling_spikes))
            tw.tween_interval(0.62)
            tw.tween_callback(func(): _hide(ceiling_spikes))
    )

    _marker(Vector2(3000, 555), C_GREEN, "BİTTİ")
    _trigger(Rect2(2820, 400, 120, 230), func():
        if _once("23_not_done_v24"):
            _boulder(Vector2(3520, 555), -390.0, 74.0)
            _play_tone(120.0, 0.22, 0.22)
    )

    var final_bridge: Array[StaticBody2D] = []
    for i in range(6):
        final_bridge.append(_platform(Vector2(3370 + i * 145, 560), Vector2(122, 24), C_PURPLE))
    _trigger(Rect2(3210, 390, 120, 230), func():
        if _once("23_final_bridge_v24"):
            for i in range(final_bridge.size()):
                if i == 1 or i == 4:
                    var tw := create_tween()
                    tw.tween_interval(0.38 + float(i) * 0.08)
                    tw.tween_property(final_bridge[i], "position:y", 800.0, 0.52).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
                    tw.tween_interval(0.52)
                    tw.tween_property(final_bridge[i], "position:y", 560.0, 0.54).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    )

    var last_spikes := _spikes(Vector2(4170, 612), 3, true)
    _trigger(Rect2(3950, 400, 110, 230), func():
        if _once("23_last_v24"):
            var tw := create_tween()
            tw.tween_interval(0.28)
            tw.tween_callback(func(): _reveal(last_spikes))
            tw.tween_interval(0.52)
            tw.tween_callback(func(): _hide(last_spikes))
    )
    _finish(Vector2(4390, 580))
