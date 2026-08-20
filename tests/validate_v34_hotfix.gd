extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://scenes/Main.tscn") as PackedScene
    if packed == null:
        push_error("V34_VALIDATE: main scene missing")
        quit(1)
        return

    var game: Node = packed.instantiate()
    root.add_child(game)
    await process_frame
    await process_frame
    game.v22_sound_enabled = false
    game.v20_effects_enabled = false

    game._start_level(2, 3)
    await process_frame
    await process_frame
    if not is_instance_valid(game.world) or not bool(game.world.get_meta("v35_rebuilt", false)):
        push_error("V34_VALIDATE: 2-3 is not using rebuilt gameplay")
        quit(1)
        return

    game._show_main_menu()
    await process_frame
    game._v24_open_dev_console()
    await process_frame
    game._v24_execute_dev_command("WAREXT")
    await process_frame
    if not is_instance_valid(game.v24_dev_overlay) or not String(game.v24_dev_overlay.name).ends_with("DevSelector"):
        push_error("V34_VALIDATE: WAREXT did not open chapter selector")
        quit(1)
        return

    game.unlocked_chapter = 2
    game._v34_start_dev_map(3, 1)
    await process_frame
    await process_frame
    if not game.v24_dev_session or game.chapter != 3 or game.part != 1:
        push_error("V34_VALIDATE: dev map 3-1 did not start")
        quit(1)
        return

    var next_same: Vector2i = game._v34_next_dev_target(3, 1)
    var next_chapter: Vector2i = game._v34_next_dev_target(3, 3)
    if next_same != Vector2i(3, 2) or next_chapter != Vector2i(4, 1):
        push_error("V34_VALIDATE: dev next-target mapping is wrong")
        quit(1)
        return

    game._v34_continue_dev()
    await process_frame
    await process_frame
    if not game.v24_dev_session or game.chapter != 3 or game.part != 2:
        push_error("V34_VALIDATE: dev continue fell back to saved progression")
        quit(1)
        return
    if game.unlocked_chapter != 2:
        push_error("V34_VALIDATE: dev flow changed normal progression")
        quit(1)
        return

    print("V34_HOTFIX_OK")
    quit(0)
