extends SceneTree

const PlayerScript = preload("res://scripts/player.gd")

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

    var corridor: StaticBody2D = _find_meta_body(game.world, "v34_required_corridor")
    if corridor == null:
        push_error("V34_VALIDATE: 2-3 corridor platform missing")
        quit(1)
        return

    var cs: CollisionShape2D = null
    for child in corridor.get_children():
        if child is CollisionShape2D:
            cs = child as CollisionShape2D
            break
    if cs == null or not (cs.shape is RectangleShape2D):
        push_error("V34_VALIDATE: corridor collision missing")
        quit(1)
        return

    var platform_shape := cs.shape as RectangleShape2D
    var floor_top := 630.0
    var player_half := 19.0
    var standing_center := floor_top - player_half
    var landing_center := corridor.position.y - platform_shape.size.y * 0.5 - player_half
    var required_rise := standing_center - landing_center
    var jump_height := (PlayerScript.JUMP_VELOCITY * PlayerScript.JUMP_VELOCITY) / (2.0 * PlayerScript.GRAVITY)
    if required_rise > jump_height - 8.0:
        push_error("V34_VALIDATE: 2-3 corridor exceeds safe jump rise %.2f > %.2f" % [required_rise, jump_height - 8.0])
        quit(1)
        return

    game._show_main_menu()
    await process_frame
    game._v24_open_dev_console()
    await process_frame
    game._v24_execute_dev_command("WAREXT")
    await process_frame
    if not is_instance_valid(game.v24_dev_overlay) or game.v24_dev_overlay.name != "V34DevSelector":
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

    game._v34_show_dev_result()
    await process_frame
    if not is_instance_valid(game.v34_dev_result_overlay) or game.v34_dev_result_overlay.name != "V34DevResult":
        push_error("V34_VALIDATE: dev result screen missing")
        quit(1)
        return

    print("V34_HOTFIX_OK")
    quit(0)

func _find_meta_body(node: Node, key: String) -> StaticBody2D:
    if node == null:
        return null
    if node is StaticBody2D and bool(node.get_meta(key, false)):
        return node as StaticBody2D
    for child in node.get_children():
        var found := _find_meta_body(child, key)
        if found != null:
            return found
    return null
