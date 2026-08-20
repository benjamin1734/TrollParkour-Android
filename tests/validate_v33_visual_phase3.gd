extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed := load("res://scenes/Main.tscn") as PackedScene
    if packed == null:
        push_error("VISUAL_PHASE3_VALIDATE: main scene missing")
        quit(1)
        return
    var game = packed.instantiate()
    root.add_child(game)
    await process_frame
    await process_frame
    game.v20_effects_enabled = true
    game.v22_sound_enabled = false

    if not await _check_band(game, 1, 0, "TEMİZ / KLASİK"):
        quit(1)
        return
    if not await _check_band(game, 11, 1, "ÇELİK / ALACAKARANLIK"):
        quit(1)
        return
    if not await _check_band(game, 21, 2, "NEON / KARANLIK"):
        quit(1)
        return

    game._start_level(21, 1)
    await process_frame
    await process_frame
    game.v28_risk_level = 3
    game._v33_update_grade()
    if game.v33_last_risk != 3:
        push_error("VISUAL_PHASE3_VALIDATE: risk-reactive grade did not sync")
        quit(1)
        return
    if game.v33_grade == null or game.v33_grade.color.a <= 0.06:
        push_error("VISUAL_PHASE3_VALIDATE: danger grade too weak or missing")
        quit(1)
        return

    game.player.velocity.x = 330.0
    game._v33_update_speed_streaks()
    var streak_visible := false
    for streak in game.v33_speed_streaks:
        if is_instance_valid(streak) and streak.default_color.a > 0.01:
            streak_visible = true
            break
    if not streak_visible:
        push_error("VISUAL_PHASE3_VALIDATE: speed streak response missing")
        quit(1)
        return

    var shadow := game.player.get_node_or_null("V33GroundShadow") as Polygon2D
    if shadow == null:
        push_error("VISUAL_PHASE3_VALIDATE: player ground shadow missing")
        quit(1)
        return

    print("VISUAL_PHASE3_OK")
    quit(0)

func _check_band(game, chapter_id: int, expected_band: int, expected_text: String) -> bool:
    game._start_level(chapter_id, 1)
    await process_frame
    await process_frame
    var atmosphere := game.world.get_node_or_null("V33Atmosphere") as Node2D
    if atmosphere == null:
        push_error("VISUAL_PHASE3_VALIDATE: atmosphere missing for chapter %d" % chapter_id)
        return false
    if int(atmosphere.get_meta("theme_band", -1)) != expected_band:
        push_error("VISUAL_PHASE3_VALIDATE: wrong theme band for chapter %d" % chapter_id)
        return false
    if atmosphere.get_node_or_null("FogBank0") == null or atmosphere.get_node_or_null("LightShaft0") == null:
        push_error("VISUAL_PHASE3_VALIDATE: fog/light shafts missing for chapter %d" % chapter_id)
        return false
    if game.hud.get_node_or_null("V33ScreenGrade") == null:
        push_error("VISUAL_PHASE3_VALIDATE: screen grade missing for chapter %d" % chapter_id)
        return false
    var tag := game.hud.get_node_or_null("V33ThemeTag") as Label
    if tag == null or tag.text != expected_text:
        push_error("VISUAL_PHASE3_VALIDATE: theme tag mismatch for chapter %d" % chapter_id)
        return false
    return true
