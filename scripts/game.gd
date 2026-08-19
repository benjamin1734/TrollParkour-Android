extends Node2D

const PlayerScript := preload("res://scripts/player.gd")
const SAVE_PATH := "user://troll_parkour_save.cfg"
const BG := Color("#f3f4f6")
const INK := Color("#111827")
const RED := Color("#ef4444")
const RED_DARK := Color("#991b1b")
const GREEN := Color("#22c55e")
const YELLOW := Color("#f59e0b")
const BLUE := Color("#3b82f6")
const MUTED := Color("#9ca3af")

var chapter := 1
var part := 1
var deaths := 0
var unlocked_chapter := 1
var player: CharacterBody2D
var world: Node2D
var hud: CanvasLayer
var camera: Camera2D
var level_width := 2800.0
var restarting := false
var level_finished := false
var trigger_state: Dictionary = {}
var music: AudioStreamPlayer

func _ready() -> void:
    RenderingServer.set_default_clear_color(BG)
    _load_save()
    _start_music()
    _start_level(1, 1)

func _start_music() -> void:
    music = AudioStreamPlayer.new()
    music.stream = _make_music()
    music.volume_db = -17.0
    add_child(music)
    music.play()

func _make_music() -> AudioStreamWAV:
    var rate := 11025
    var seconds := 8.0
    var samples := int(rate * seconds)
    var data := PackedByteArray()
    data.resize(samples * 2)
    var notes := [220.0, 277.18, 329.63, 246.94]
    for i in range(samples):
        var t := float(i) / float(rate)
        var note_index := int(t / 0.5) % notes.size()
        var f: float = notes[note_index]
        var pulse := 0.65 + 0.35 * sin(TAU * 2.0 * t)
        var v := sin(TAU * f * t) * 0.09 * pulse
        data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
    var wav := AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = rate
    wav.stereo = false
    wav.data = data
    wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
    wav.loop_begin = 0
    wav.loop_end = samples
    return wav

func _tone(freq: float, duration: float, gain: float = 0.25) -> AudioStreamWAV:
    var rate := 11025
    var samples := maxi(1, int(rate * duration))
    var data := PackedByteArray()
    data.resize(samples * 2)
    for i in range(samples):
        var t := float(i) / float(rate)
        var env := 1.0 - float(i) / float(samples)
        var v := sin(TAU * freq * t) * gain * env
        data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
    var wav := AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = rate
    wav.stereo = false
    wav.data = data
    return wav

func _play_tone(freq: float, duration: float, gain: float = 0.25) -> void:
    var a := AudioStreamPlayer.new()
    a.stream = _tone(freq, duration, gain)
    add_child(a)
    a.finished.connect(a.queue_free)
    a.play()

func _start_level(c: int, p: int) -> void:
    chapter = c
    part = p
    restarting = false
    level_finished = false
    trigger_state.clear()
    if is_instance_valid(world):
        world.queue_free()
    if is_instance_valid(hud):
        hud.queue_free()
    world = Node2D.new()
    world.name = "World"
    add_child(world)
    _build_level(c, p)
    _spawn_player(Vector2(110, 560))
    _build_camera()
    _build_hud()

func _spawn_player(pos: Vector2) -> void:
    player = CharacterBody2D.new()
    player.name = "Player"
    player.set_script(PlayerScript)
    player.position = pos
    player.collision_layer = 1
    player.collision_mask = 1
    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(38, 38)
    cs.shape = shape
    player.add_child(cs)
    var body := Polygon2D.new()
    body.name = "Visual"
    body.polygon = PackedVector2Array([Vector2(-19,-19),Vector2(19,-19),Vector2(19,19),Vector2(-19,19)])
    body.color = INK
    player.add_child(body)
    for x in [-7.0, 6.0]:
        var eye := Polygon2D.new()
        eye.position = Vector2(x, -5)
        eye.polygon = PackedVector2Array([Vector2(-3,-3),Vector2(3,-3),Vector2(3,3),Vector2(-3,3)])
        eye.color = Color.WHITE
        player.add_child(eye)
    player.died.connect(_on_player_died)
    player.jumped.connect(func(): _play_tone(660.0, 0.07, 0.14))
    world.add_child(player)

func _build_camera() -> void:
    camera = Camera2D.new()
    camera.position = Vector2(640, 360)
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 8.0
    camera.limit_left = 0
    camera.limit_right = int(level_width)
    camera.limit_top = 0
    camera.limit_bottom = 720
    world.add_child(camera)
    camera.make_current()

func _process(_delta: float) -> void:
    if is_instance_valid(player) and is_instance_valid(camera):
        camera.position.x = clampf(player.global_position.x + 250.0, 640.0, level_width - 640.0)

func _build_hud() -> void:
    hud = CanvasLayer.new()
    add_child(hud)
    var top := ColorRect.new()
    top.size = Vector2(1280, 70)
    top.color = Color(1,1,1,0.92)
    hud.add_child(top)
    var title := Label.new()
    title.position = Vector2(28, 18)
    title.text = "BÖLÜM %d-%d" % [chapter, part]
    title.add_theme_font_size_override("font_size", 28)
    title.add_theme_color_override("font_color", INK)
    hud.add_child(title)
    var dl := Label.new()
    dl.name = "DeathLabel"
    dl.position = Vector2(1010, 20)
    dl.text = "ÖLÜM: %d" % deaths
    dl.add_theme_font_size_override("font_size", 24)
    dl.add_theme_color_override("font_color", RED_DARK)
    hud.add_child(dl)
    _touch_button("move_left", Vector2(95,615), Vector2(125,90), "◀")
    _touch_button("move_right", Vector2(235,615), Vector2(125,90), "▶")
    _touch_button("jump", Vector2(1100,600), Vector2(150,110), "ZIPLA")

func _touch_button(action: String, center: Vector2, size: Vector2, text: String) -> void:
    var panel := ColorRect.new()
    panel.position = center - size / 2.0
    panel.size = size
    panel.color = Color(0.07,0.09,0.13,0.24)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(panel)
    var label := Label.new()
    label.position = center - Vector2(size.x / 2.0, 22)
    label.size = Vector2(size.x, 44)
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 24 if text == "ZIPLA" else 34)
    label.add_theme_color_override("font_color", Color(0.07,0.09,0.13,0.75))
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

func _build_level(c: int, p: int) -> void:
    if c == 1 and p == 1:
        _level_1_1()
    elif c == 1 and p == 2:
        _level_1_2()
    elif c == 1 and p == 3:
        _level_1_3()
    else:
        _base_floor(2300)
        _text(Vector2(300,470), "YENİ BÖLÜMLER SONRAKİ SÜRÜMDE", 30, INK)
        _finish(Vector2(2000,580))

func _base_floor(width: float) -> void:
    level_width = width
    _platform(Vector2(width / 2.0, 675), Vector2(width, 90), INK)

func _level_1_1() -> void:
    _base_floor(2800)
    _text(Vector2(120,470), "HER ŞEYE GÜVENME.", 24, MUTED)
    var s1 := _spikes(Vector2(690,612), 3, true)
    _trigger(Rect2(560,500,130,150), func():
        if _once("11_spike"):
            _reveal(s1)
    )
    _spikes(Vector2(930,612), 2, false)
    var drop := _platform(Vector2(1110,570), Vector2(170,28), BLUE)
    _trigger(Rect2(1010,440,170,180), func():
        if _once("11_drop"):
            var tw := create_tween()
            tw.tween_interval(0.15)
            tw.tween_property(drop, "position:y", 840.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    )
    _platform(Vector2(1480,445), Vector2(280,24), INK)
    _spikes(Vector2(1480,486), 5, false, true)
    _text(Vector2(1360,365), "KOLAY.", 22, MUTED)
    var goal := _finish(Vector2(2450,580))
    _trigger(Rect2(2180,430,180,230), func():
        if _once("11_goal"):
            create_tween().tween_property(goal, "position:x", 2660.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )

func _level_1_2() -> void:
    _base_floor(3200)
    _text(Vector2(120,470), "ARTIK BİLİYORSUN, DEĞİL Mİ?", 24, MUTED)
    _text(Vector2(500,530), "SAFE", 22, GREEN)
    _platform(Vector2(580,615), Vector2(220,28), GREEN)
    var s1 := _spikes(Vector2(1080,612), 4, true)
    _trigger(Rect2(850,390,150,240), func():
        if _once("12_air"):
            var tw := create_tween()
            tw.tween_interval(0.24)
            tw.tween_callback(func(): _reveal(s1))
    )
    _marker(Vector2(1450,575), YELLOW, "?")
    _trigger(Rect2(1380,430,120,200), func():
        if _once("12_rock"):
            _boulder(Vector2(1050,560), 420.0, 78.0)
    )
    var runaway := _platform(Vector2(2050,575), Vector2(260,26), BLUE)
    _trigger(Rect2(1860,390,140,220), func():
        if _once("12_run"):
            create_tween().tween_property(runaway, "position:x", 2390.0, 0.58).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
    )
    var last := _spikes(Vector2(2820,612), 4, true)
    _trigger(Rect2(2630,420,110,220), func():
        if _once("12_last"):
            _reveal(last)
    )
    _finish(Vector2(3020,580))

func _level_1_3() -> void:
    _base_floor(3500)
    _text(Vector2(120,470), "OYUN DA SENİ TANIYOR.", 24, MUTED)
    var bait := _spikes(Vector2(760,612), 3, true)
    _trigger(Rect2(560,420,150,220), func():
        if _once("13_bait"):
            _reveal(bait)
            var tw := create_tween()
            tw.tween_interval(1.1)
            tw.tween_callback(func(): _hide(bait))
    )
    var lift := _platform(Vector2(1320,590), Vector2(210,28), BLUE)
    _spikes(Vector2(1320,390), 4, false, true)
    _trigger(Rect2(1190,450,160,180), func():
        if _once("13_lift"):
            create_tween().tween_property(lift, "position:y", 470.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    )
    var wall := _platform(Vector2(1850,250), Vector2(40,350), RED_DARK)
    _trigger(Rect2(1680,430,120,210), func():
        if _once("13_wall"):
            create_tween().tween_property(wall, "position:y", 500.0, 0.38).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
    )
    _trigger(Rect2(2200,410,100,220), func():
        if _once("13_rock"):
            _boulder(Vector2(2820,560), -430.0, 92.0)
    )
    _marker(Vector2(3040,560), GREEN, "FINISH")
    var fake := _spikes(Vector2(3050,612), 4, true)
    _trigger(Rect2(2900,420,100,210), func():
        if _once("13_fake"):
            _reveal(fake)
    )
    _finish(Vector2(3340,580))

func _once(key: String) -> bool:
    if trigger_state.get(key, false):
        return false
    trigger_state[key] = true
    return true

func _platform(pos: Vector2, size: Vector2, color: Color) -> StaticBody2D:
    var body := StaticBody2D.new()
    body.position = pos
    body.collision_layer = 1
    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = size
    cs.shape = shape
    body.add_child(cs)
    var poly := Polygon2D.new()
    poly.polygon = PackedVector2Array([Vector2(-size.x/2,-size.y/2),Vector2(size.x/2,-size.y/2),Vector2(size.x/2,size.y/2),Vector2(-size.x/2,size.y/2)])
    poly.color = color
    body.add_child(poly)
    world.add_child(body)
    return body

func _spikes(pos: Vector2, count: int, hidden: bool, inverted: bool = false) -> Area2D:
    var area := Area2D.new()
    area.position = pos
    area.collision_layer = 2
    area.collision_mask = 1
    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(float(count * 44), 34)
    cs.shape = shape
    cs.disabled = hidden
    area.add_child(cs)
    for i in range(count):
        var tri := Polygon2D.new()
        tri.position.x = (float(i) - float(count - 1) / 2.0) * 44.0
        tri.polygon = PackedVector2Array([Vector2(-21,-18),Vector2(21,-18),Vector2(0,20)]) if inverted else PackedVector2Array([Vector2(-21,18),Vector2(21,18),Vector2(0,-20)])
        tri.color = RED
        tri.visible = not hidden
        area.add_child(tri)
    area.body_entered.connect(func(body):
        if body == player and player.alive:
            player.die()
    )
    world.add_child(area)
    return area

func _reveal(area: Area2D) -> void:
    if not is_instance_valid(area):
        return
    (area.get_child(0) as CollisionShape2D).set_deferred("disabled", false)
    for child in area.get_children():
        if child is Polygon2D:
            child.visible = true
            child.scale = Vector2(1.0, 0.05)
            create_tween().tween_property(child, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    _play_tone(190.0, 0.10, 0.25)

func _hide(area: Area2D) -> void:
    if not is_instance_valid(area):
        return
    (area.get_child(0) as CollisionShape2D).set_deferred("disabled", true)
    for child in area.get_children():
        if child is Polygon2D:
            child.visible = false

func _trigger(rect: Rect2, callback: Callable) -> Area2D:
    var area := Area2D.new()
    area.position = rect.position + rect.size / 2.0
    area.collision_mask = 1
    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = rect.size
    cs.shape = shape
    area.add_child(cs)
    area.body_entered.connect(func(body):
        if body == player:
            callback.call()
    )
    world.add_child(area)
    return area

func _boulder(pos: Vector2, speed: float, radius: float) -> void:
    var area := Area2D.new()
    area.position = pos
    area.collision_layer = 2
    area.collision_mask = 1
    var cs := CollisionShape2D.new()
    var shape := CircleShape2D.new()
    shape.radius = radius
    cs.shape = shape
    area.add_child(cs)
    var poly := Polygon2D.new()
    var points := PackedVector2Array()
    for i in range(24):
        var a := TAU * float(i) / 24.0
        points.append(Vector2(cos(a), sin(a)) * radius)
    poly.polygon = points
    poly.color = RED_DARK
    area.add_child(poly)
    area.body_entered.connect(func(body):
        if body == player and player.alive:
            player.die()
    )
    world.add_child(area)
    _play_tone(90.0, 0.25, 0.25)
    var travel := 1400.0
    var duration := travel / absf(speed)
    var tw := create_tween()
    tw.set_parallel(true)
    tw.tween_property(area, "position:x", pos.x + signf(speed) * travel, duration)
    tw.tween_property(poly, "rotation", signf(speed) * TAU * 7.0, duration)
    tw.chain().tween_callback(area.queue_free)

func _finish(pos: Vector2) -> Area2D:
    var area := Area2D.new()
    area.position = pos
    area.collision_mask = 1
    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(90,120)
    cs.shape = shape
    area.add_child(cs)
    var pole := Polygon2D.new()
    pole.polygon = PackedVector2Array([Vector2(-38,60),Vector2(-30,60),Vector2(-30,-60),Vector2(-38,-60)])
    pole.color = INK
    area.add_child(pole)
    var flag := Polygon2D.new()
    flag.polygon = PackedVector2Array([Vector2(-30,-58),Vector2(40,-42),Vector2(-30,-20)])
    flag.color = GREEN
    area.add_child(flag)
    area.body_entered.connect(func(body):
        if body == player:
            _finish_level()
    )
    world.add_child(area)
    return area

func _marker(pos: Vector2, color: Color, text: String) -> void:
    var panel := Polygon2D.new()
    panel.position = pos
    panel.polygon = PackedVector2Array([Vector2(-60,-40),Vector2(60,-40),Vector2(60,40),Vector2(-60,40)])
    panel.color = color
    world.add_child(panel)
    _text(pos + Vector2(-45,-18), text, 20, INK)

func _text(pos: Vector2, text: String, size: int, color: Color) -> void:
    var label := Label.new()
    label.position = pos
    label.text = text
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", color)
    world.add_child(label)

func _on_player_died() -> void:
    if restarting or level_finished:
        return
    restarting = true
    deaths += 1
    _save()
    var dl := hud.get_node_or_null("DeathLabel") as Label
    if dl:
        dl.text = "ÖLÜM: %d" % deaths
    _play_tone(110.0, 0.22, 0.30)
    var visual := player.get_node_or_null("Visual") as Polygon2D
    if visual:
        var tw := create_tween()
        tw.set_parallel(true)
        tw.tween_property(visual, "scale", Vector2(0.05,0.05), 0.28)
        tw.tween_property(visual, "rotation", PI * 1.5, 0.28)
    await get_tree().create_timer(0.42).timeout
    _start_level(chapter, part)

func _finish_level() -> void:
    if level_finished or restarting:
        return
    level_finished = true
    player.input_enabled = false
    _play_tone(880.0, 0.20, 0.20)
    var banner := Label.new()
    banner.position = Vector2(390,250)
    banner.size = Vector2(500,120)
    banner.text = "KISIM TAMAMLANDI!"
    banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    banner.add_theme_font_size_override("font_size", 42)
    banner.add_theme_color_override("font_color", GREEN)
    hud.add_child(banner)
    await get_tree().create_timer(0.9).timeout
    if part < 3:
        _start_level(chapter, part + 1)
    else:
        unlocked_chapter = maxi(unlocked_chapter, chapter + 1)
        _save()
        _chapter_complete()

func _chapter_complete() -> void:
    if is_instance_valid(world):
        world.queue_free()
    var overlay := ColorRect.new()
    overlay.size = Vector2(1280,720)
    overlay.color = INK
    hud.add_child(overlay)
    var label := Label.new()
    label.position = Vector2(240,170)
    label.size = Vector2(800,260)
    label.text = "BÖLÜM 1 TAMAMLANDI\n\nÖLÜM: %d\n\nİLK 3 HARİTA TAMAM" % deaths
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 34)
    label.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(label)
    var replay := Button.new()
    replay.position = Vector2(490,470)
    replay.size = Vector2(300,70)
    replay.text = "TEKRAR OYNA"
    replay.add_theme_font_size_override("font_size", 22)
    replay.pressed.connect(func(): _start_level(1,1))
    hud.add_child(replay)

func _save() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("progress", "deaths", deaths)
    cfg.set_value("progress", "unlocked_chapter", unlocked_chapter)
    cfg.save(SAVE_PATH)

func _load_save() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) == OK:
        deaths = int(cfg.get_value("progress", "deaths", 0))
        unlocked_chapter = int(cfg.get_value("progress", "unlocked_chapter", 1))
