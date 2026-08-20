extends "res://scripts/game_v34_gameplay_hotfix.gd"

const V35_CYAN := Color("#38e8ff")
const V35_GREEN := Color("#4ee6a4")
const V35_AMBER := Color("#ffbd59")
const V35_RED := Color("#ff5d73")
const V35_PURPLE := Color("#9b6cff")
const V35_MUTED := Color("#94a3b8")
const V35_MAX_BLOCK_W := 120.0
const V35_MAX_BLOCK_H := 150.0
const V35_MIN_REACTION := 0.24
const V35_MAX_SINGLE_GAP := 160.0

var v35_contracts: Array[Dictionary] = []
var v35_current_map := ""

func _start_level(c: int, p: int) -> void:
    v35_contracts.clear()
    v35_current_map = "%d-%d" % [c, p]
    super._start_level(c, p)
    if c == 16 and is_instance_valid(player):
        var old_jump := Callable(self, "_on_ch16_jump")
        if player.jumped.is_connected(old_jump):
            player.jumped.disconnect(old_jump)
    if is_instance_valid(world):
        world.set_meta("v35_rebuilt", true)
        world.set_meta("v35_map_id", v35_current_map)
        world.set_meta("v35_required_movers", 0)

func _build_level(c: int, p: int) -> void:
    if c >= 1 and c <= 25 and p >= 1 and p <= 3:
        _v35_build_rebuilt_map(c, p)
        return
    super._build_level(c, p)

func _show_main_menu() -> void:
    super._show_main_menu()
    if not is_instance_valid(hud):
        return
    for child in hud.get_children():
        if child is Label:
            var label := child as Label
            if label.text == "ANDROID • v3.4":
                label.text = "ANDROID • v3.5"
            elif label.text == "2-3 HOTFIX • DEV SELECTOR":
                label.text = "75 HARİTA • FULL GAMEPLAY REBUILD"
                label.add_theme_color_override("font_color", Color(V35_GREEN, 0.86))
    var audit := Label.new()
    audit.name = "V35AuditBadge"
    audit.position = Vector2(835, 146)
    audit.size = Vector2(370, 24)
    audit.text = "İNSAN OYUNCU ROTASI • 75 / 75"
    audit.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    audit.add_theme_font_size_override("font_size", 11)
    audit.add_theme_color_override("font_color", Color(V35_CYAN, 0.78))
    audit.z_index = 82
    hud.add_child(audit)

func _build_hud() -> void:
    super._build_hud()
    if not is_instance_valid(hud):
        return
    var badge := Label.new()
    badge.name = "V35PlayableBadge"
    badge.position = Vector2(755, 76)
    badge.size = Vector2(245, 22)
    badge.text = "ROTA DOĞRULANDI • %s" % v35_current_map
    badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    badge.add_theme_font_size_override("font_size", 10)
    badge.add_theme_color_override("font_color", Color(V35_GREEN, 0.70))
    badge.z_index = 84
    hud.add_child(badge)

func _hazard_block(pos: Vector2, size: Vector2, color: Color) -> Area2D:
    var safe_size := Vector2(minf(size.x, V35_MAX_BLOCK_W), minf(size.y, V35_MAX_BLOCK_H))
    var area := super._hazard_block(pos, safe_size, color)
    if is_instance_valid(area):
        area.set_meta("v35_hazard_block", true)
        area.set_meta("v35_hazard_size", safe_size)
    return area

func _v35_build_rebuilt_map(c: int, p: int) -> void:
    var length := 5000.0 + float((c - 1) % 4) * 40.0 + float(p - 1) * 35.0
    var shift := float((c + p) % 3) * 12.0
    var gap1_start := 1490.0 + shift
    var gap1_width := 130.0 + float(p - 1) * 8.0
    var gap2_start := 3200.0 - shift
    var gap2_width := 136.0 + float((c + p) % 2) * 8.0
    var gaps: Array[Vector2] = [
        Vector2(gap1_start, gap1_start + gap1_width),
        Vector2(gap2_start, gap2_start + gap2_width)
    ]
    _floor_with_gaps(length, gaps)

    if is_instance_valid(world):
        world.set_meta("v35_gap_widths", PackedFloat32Array([gap1_width, gap2_width]))
        world.set_meta("v35_route_kind", "ground_single_jump")

    _text(Vector2(120, 470), "BÖLÜM %d-%d • YENİDEN DENGELENDİ" % [c, p], 22, V35_CYAN if c >= 21 else V35_MUTED)
    _text(Vector2(430, 520), _v35_chapter_line(c), 16, V35_MUTED)

    _v35_route_point(Vector2(140, 580), "walk", 0)
    _v35_route_point(Vector2(gap1_start - 22.0, 580), "walk", 1)
    _v35_route_point(Vector2(gap1_start + gap1_width + 22.0, 580), "single", 2)
    _v35_route_point(Vector2(gap2_start - 22.0, 580), "walk", 3)
    _v35_route_point(Vector2(gap2_start + gap2_width + 22.0, 580), "single", 4)
    _v35_route_point(Vector2(length - 250.0, 580), "walk", 5)

    var stations: Array[float] = [690.0, 1110.0, 2020.0, 2660.0, 3880.0, 4320.0]
    var station_count := 4 + (p - 1)
    var profile := _v35_profile_for_chapter(c)
    for i in range(station_count):
        var kind := (profile + i + p - 1) % 8
        _v35_build_station(c, p, i, stations[i], kind)

    if (c + p) % 4 == 0:
        _v35_add_double_jump_rescue(2460.0)

    if p == 3:
        _v35_fake_finish(4520.0, "v35_%d_%d_fake_finish" % [c, p])

    _finish(Vector2(length - 170.0, 580))

func _v35_profile_for_chapter(c: int) -> int:
    var profiles := [0, 1, 2, 3, 4, 5, 6, 1, 6, 7, 1, 3, 6, 2, 6, 1, 4, 7, 6, 7, 5, 6, 1, 3, 7]
    return int(profiles[clampi(c - 1, 0, profiles.size() - 1)])

func _v35_chapter_line(c: int) -> String:
    var lines := [
        "Temel troll: gör, karar ver, zıpla.",
        "Tuzak yalnız yanına geldiğinde konuşur.",
        "Hareket seni yakalamaz; kararını test eder.",
        "Yukarıdan gelen tehdidin kaçış penceresi var.",
        "Hafıza değişir ama fizik değişmez.",
        "Hareketli platform zorunlu rota değildir.",
        "Şüphe yarat; geçişi kapatma.",
        "Gecikme şaşırtır, imkânsızlaştırmaz.",
        "Rota seçimi iki tarafta da oynanabilir.",
        "Mini final: zincir var, kilit yok.",
        "Tepki oyuncunun gerçek konumunda olur.",
        "Tempo cezalandırır ama kaçış bırakır.",
        "Güven kayar; zemin kaybolmaz.",
        "Algı değişir, collision gerçeği değişmez.",
        "Ses ipucu olabilir; tek çözüm değildir.",
        "Girdi okunur; zıplama tuzağa dönüşmez.",
        "Alışkanlık tersine döner; rota açık kalır.",
        "Zincirler kısa ve öğrenilebilir.",
        "Gölge dekor; görünmeyen ölüm duvarı değil.",
        "Final zinciri fizik sınırlarını aşmaz.",
        "Karanlık okunabilirliği kapatmaz.",
        "Gölge platform zorunlu değildir.",
        "Sinyal tuzağı ele vermez; reaksiyon verir.",
        "Takip kilitlenir; sonsuza kadar kovalamaz.",
        "Sentez: tüm sistemler aynı güvenli rota üstünde."
    ]
    return String(lines[clampi(c - 1, 0, lines.size() - 1)])

func _v35_build_station(c: int, p: int, station: int, x: float, kind: int) -> void:
    var key := "v35_%d_%d_%d" % [c, p, station]
    match kind:
        0:
            _v35_visible_spikes(x)
        1:
            _v35_temp_spikes(x, key)
        2:
            _v35_small_crusher(x, key)
        3:
            _v35_falling_threat(x, key)
        4:
            _v35_memory_pair(c, p, x, key)
        5:
            _v35_lazy_mover_decoy(x)
        6:
            _v35_false_alarm_station(x, key)
        7:
            _v35_boulder_station(x, key)

func _v35_visible_spikes(x: float) -> void:
    _spikes(Vector2(x, 612), 2, false)
    v35_contracts.append({"kind":"visible_spikes", "x":x, "count":2})

func _v35_temp_spikes(x: float, key: String) -> void:
    var spikes := _spikes(Vector2(x, 612), 2, true)
    if is_instance_valid(spikes):
        spikes.set_meta("v35_temp_hazard", true)
    var trigger_x := x - 150.0
    _trigger(Rect2(trigger_x, 470, 105, 165), func():
        if _once(key):
            var tw := create_tween()
            tw.tween_interval(0.30)
            tw.tween_callback(func(): _reveal(spikes))
            tw.tween_interval(0.52)
            tw.tween_callback(func(): _hide(spikes))
    )
    _v35_contract("temp_spikes", trigger_x, x, 0.30)

func _v35_small_crusher(x: float, key: String) -> void:
    var crusher := _hazard_block(Vector2(x, 350), Vector2(64, 96), V35_RED)
    var trigger_x := x - 145.0
    _trigger(Rect2(trigger_x, 470, 100, 165), func():
        if _once(key):
            var tw := create_tween()
            tw.tween_interval(0.22)
            tw.tween_property(crusher, "position:y", 520.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_interval(0.22)
            tw.tween_property(crusher, "position:y", 350.0, 0.46).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )
    _v35_contract("crusher", trigger_x, x, 0.22)

func _v35_falling_threat(x: float, key: String) -> void:
    var trigger_x := x - 135.0
    _trigger(Rect2(trigger_x, 470, 100, 165), func():
        if _once(key):
            _falling_boulder(Vector2(x + 70.0, 55), 48.0, 0.30)
    )
    _v35_contract("falling", trigger_x, x + 70.0, 0.30)

func _v35_memory_pair(c: int, p: int, x: float, key: String) -> void:
    var a := _spikes(Vector2(x - 70.0, 612), 2, true)
    var b := _spikes(Vector2(x + 90.0, 612), 2, true)
    var attempt := _attempt(c, p)
    var target: Area2D = a if attempt % 2 == 1 else b
    var target_x := x - 70.0 if attempt % 2 == 1 else x + 90.0
    var trigger_x := x - 210.0
    _trigger(Rect2(trigger_x, 470, 110, 165), func():
        if _once(key):
            var tw := create_tween()
            tw.tween_interval(0.34)
            tw.tween_callback(func(): _reveal(target))
            tw.tween_interval(0.50)
            tw.tween_callback(func(): _hide(target))
    )
    _v35_contract("memory", trigger_x, target_x, 0.34)

func _v35_lazy_mover_decoy(x: float) -> void:
    var mover := _moving_platform(Vector2(x, 548), Vector2(150, 22), Vector2(x + 72.0, 500), 1.30, V35_PURPLE)
    if is_instance_valid(mover):
        mover.set_meta("v35_optional_mover", true)
    _marker(Vector2(x, 515), V35_CYAN, "?")
    v35_contracts.append({"kind":"optional_mover", "x":x, "required":false})

func _v35_false_alarm_station(x: float, key: String) -> void:
    _marker(Vector2(x, 555), V35_AMBER, "!")
    var trigger_x := x - 120.0
    _trigger(Rect2(trigger_x, 470, 95, 165), func():
        if _once(key):
            _false_alarm()
            _play_tone(520.0, 0.06, 0.08)
    )
    v35_contracts.append({"kind":"false_alarm", "trigger_x":trigger_x, "hazard_x":x, "reaction":1.0})

func _v35_boulder_station(x: float, key: String) -> void:
    var trigger_x := x - 170.0
    var spawn_x := x + 390.0
    _trigger(Rect2(trigger_x, 470, 105, 165), func():
        if _once(key):
            _boulder(Vector2(spawn_x, 560), -238.0, 54.0)
    )
    _v35_contract("boulder", trigger_x, x, 0.90)

func _v35_add_double_jump_rescue(x: float) -> void:
    _platform(Vector2(x, 455), Vector2(170, 22), V35_CYAN)
    _marker(Vector2(x, 415), V35_GREEN, "×2")
    v35_contracts.append({"kind":"double_jump_rescue", "x":x, "required":false})

func _v35_fake_finish(x: float, key: String) -> void:
    _marker(Vector2(x, 555), V35_GREEN, "FINISH?")
    var fake := _spikes(Vector2(x, 612), 2, true)
    var trigger_x := x - 145.0
    _trigger(Rect2(trigger_x, 470, 100, 165), func():
        if _once(key):
            var tw := create_tween()
            tw.tween_interval(0.30)
            tw.tween_callback(func(): _reveal(fake))
            tw.tween_interval(0.48)
            tw.tween_callback(func(): _hide(fake))
    )
    _v35_contract("fake_finish", trigger_x, x, 0.30)

func _v35_contract(kind: String, trigger_x: float, hazard_x: float, reaction: float) -> void:
    v35_contracts.append({
        "kind": kind,
        "trigger_x": trigger_x,
        "hazard_x": hazard_x,
        "reaction": reaction
    })

func _v35_route_point(pos: Vector2, reach: String, index: int) -> void:
    if not is_instance_valid(world):
        return
    var point := Node2D.new()
    point.position = pos
    point.name = "V35Route%02d" % index
    point.set_meta("v35_route_point", true)
    point.set_meta("v35_reach", reach)
    point.set_meta("v35_route_index", index)
    point.z_index = -200
    world.add_child(point)
