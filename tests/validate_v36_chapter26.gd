extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed := load("res://scenes/Main.tscn") as PackedScene
    if packed == null:
        push_error("V36_VALIDATE: main scene missing")
        quit(1)
        return
    var game = packed.instantiate()
    root.add_child(game)
    await process_frame
    await process_frame
    game.v20_effects_enabled = false
    game.v22_sound_enabled = false

    for p in range(1, 4):
        game._start_level(26, p)
        await process_frame
        await process_frame
        if not is_instance_valid(game.world):
            push_error("V36_VALIDATE: 26-%d world missing" % p)
            quit(1)
            return
        if not bool(game.world.get_meta("v36_inversion", false)):
            push_error("V36_VALIDATE: 26-%d inversion metadata missing" % p)
            quit(1)
            return
        if int(game.world.get_meta("v36_part", 0)) != p:
            push_error("V36_VALIDATE: 26-%d part metadata wrong" % p)
            quit(1)
            return
        if int(game.world.get_meta("v35_required_movers", -1)) != 0:
            push_error("V36_VALIDATE: 26-%d requires moving platform" % p)
            quit(1)
            return
        var widths = game.world.get_meta("v35_gap_widths", PackedFloat32Array())
        if widths.size() != 2:
            push_error("V36_VALIDATE: 26-%d gap metadata missing" % p)
            quit(1)
            return
        for width in widths:
            if float(width) > 160.0:
                push_error("V36_VALIDATE: 26-%d gap too wide %.1f" % [p, float(width)])
                quit(1)
                return
        var has_inversion := false
        for contract in game.v35_contracts:
            var kind := String(contract.get("kind", ""))
            if kind == "chase":
                push_error("V36_VALIDATE: 26-%d contains chase contract" % p)
                quit(1)
                return
            if kind in ["inverted_visible", "plain_floor", "inverted_pair"]:
                has_inversion = true
            if contract.has("reaction") and kind != "false_alarm":
                var reaction := float(contract.get("reaction", 0.0))
                if reaction < 0.24:
                    push_error("V36_VALIDATE: 26-%d %s reaction %.2f" % [p, kind, reaction])
                    quit(1)
                    return
        if not has_inversion:
            push_error("V36_VALIDATE: 26-%d inversion mechanic missing" % p)
            quit(1)
            return
        if game.v36_jump_state_label == null or not is_instance_valid(game.v36_jump_state_label):
            push_error("V36_VALIDATE: double-jump HUD feedback missing")
            quit(1)
            return

    var next_from_25: Vector2i = game._v34_next_dev_target(25, 3)
    var next_inside_26: Vector2i = game._v34_next_dev_target(26, 1)
    var after_26: Vector2i = game._v34_next_dev_target(26, 3)
    if next_from_25 != Vector2i(26, 1):
        push_error("V36_VALIDATE: dev 25-3 does not continue to 26-1")
        quit(1)
        return
    if next_inside_26 != Vector2i(26, 2):
        push_error("V36_VALIDATE: dev 26-1 does not continue to 26-2")
        quit(1)
        return
    if after_26 != Vector2i(-1, -1):
        push_error("V36_VALIDATE: dev 26-3 should be final current map")
        quit(1)
        return

    game._show_main_menu()
    await process_frame
    game._v24_open_dev_console()
    await process_frame
    game._v24_execute_dev_command("WAREXT")
    await process_frame
    if not is_instance_valid(game.v24_dev_overlay) or game.v24_dev_overlay.name != "V36DevSelector":
        push_error("V36_VALIDATE: WAREXT did not open v3.6 selector")
        quit(1)
        return
    if not _has_button_text(game.v24_dev_overlay, "BÖLÜM 26"):
        push_error("V36_VALIDATE: developer selector missing chapter 26")
        quit(1)
        return

    game._v34_start_dev_map(26, 1)
    await process_frame
    await process_frame
    if not game.v24_dev_session or game.chapter != 26 or game.part != 1:
        push_error("V36_VALIDATE: developer tool could not start 26-1")
        quit(1)
        return
    game._v34_continue_dev()
    await process_frame
    await process_frame
    if game.chapter != 26 or game.part != 2:
        push_error("V36_VALIDATE: developer continue did not advance 26-1 to 26-2")
        quit(1)
        return

    print("V36_CHAPTER26_OK")
    quit(0)

func _has_button_text(node: Node, expected: String) -> bool:
    if node is Button and (node as Button).text == expected:
        return true
    for child in node.get_children():
        if _has_button_text(child, expected):
            return true
    return false
