extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed := load("res://scenes/Main.tscn") as PackedScene
    if packed == null:
        push_error("BOULDER_VALIDATE: main scene missing")
        quit(1)
        return
    var game = packed.instantiate()
    root.add_child(game)
    await process_frame
    await process_frame
    game.v20_effects_enabled = false
    game.v22_sound_enabled = false
    game._start_level(1, 1)
    await process_frame
    await process_frame
    game.player.global_position = Vector2(1000, 560)

    game._boulder(Vector2(1500, 560), -600.0, 60.0)
    var head_on := absf(game.v30_last_boulder_speed)
    if game.v30_last_boulder_mode != "head_on" or head_on > 282.1:
        push_error("BOULDER_VALIDATE: head-on speed %.1f mode %s" % [head_on, game.v30_last_boulder_mode])
        quit(1)
        return

    game._boulder(Vector2(600, 560), 620.0, 60.0)
    var chase := absf(game.v30_last_boulder_speed)
    if game.v30_last_boulder_mode != "chase" or chase > 238.1:
        push_error("BOULDER_VALIDATE: chase speed %.1f mode %s" % [chase, game.v30_last_boulder_mode])
        quit(1)
        return

    game._boulder(Vector2(1500, 300), 600.0, 60.0)
    var cross := absf(game.v30_last_boulder_speed)
    if game.v30_last_boulder_mode != "cross" or cross > 258.1:
        push_error("BOULDER_VALIDATE: cross speed %.1f mode %s" % [cross, game.v30_last_boulder_mode])
        quit(1)
        return

    print("BOULDER_BALANCE_OK")
    quit(0)
