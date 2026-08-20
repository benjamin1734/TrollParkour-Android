extends SceneTree

const PlayerScript = preload("res://scripts/player.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://scenes/Main.tscn") as PackedScene
    if packed == null:
        push_error("V34_GAMEPLAY_VALIDATE: main scene missing")
        quit(1)
        return

    var game: Node = packed.instantiate()
    root.add_child(game)
    await process_frame
    await process_frame
    game.v22_sound_enabled = false
    game.v20_effects_enabled = false

    if not await _validate_double_jump():
        quit(1)
        return

    game._start_level(6, 1)
    await process_frame
    await process_frame
    if game.v30_pending_movers.is_empty():
        push_error("V34_GAMEPLAY_VALIDATE: no lazy mover available for activation test")
        quit(1)
        return

    var mover_id = game.v30_pending_movers.keys()[0]
    var state: Dictionary = game.v30_pending_movers[mover_id]
    var mover = state.get("node")
    if mover == null or not is_instance_valid(mover):
        push_error("V34_GAMEPLAY_VALIDATE: pending mover node invalid")
        quit(1)
        return
    var start: Vector2 = state.get("start", mover.position)
    game.player.input_enabled = false
    game.player.global_position = Vector2(start.x - 300.0, start.y)
    game._v30_tick_pending_movers()
    if bool(mover.get_meta("v30_mover_activated", false)):
        push_error("V34_GAMEPLAY_VALIDATE: mover activated 300px before player reached it")
        quit(1)
        return

    game.player.global_position = Vector2(start.x - 80.0, start.y)
    game._v30_tick_pending_movers()
    if not bool(mover.get_meta("v30_mover_activated", false)):
        push_error("V34_GAMEPLAY_VALIDATE: mover did not activate when player reached platform")
        quit(1)
        return

    game._start_level(2, 2)
    await process_frame
    await process_frame
    var oversized := _count_oversized_hazard_rects(game.world)
    if oversized > 0:
        push_error("V34_GAMEPLAY_VALIDATE: chapter 2 still contains %d oversized rectangular hazards" % oversized)
        quit(1)
        return

    game.player.global_position = Vector2(1000.0, 560.0)
    var head_on := absf(game._v30_balanced_boulder_speed(Vector2(1500.0, 560.0), -600.0, 70.0))
    var chase := absf(game._v30_balanced_boulder_speed(Vector2(500.0, 560.0), 600.0, 70.0))
    var cross := absf(game._v30_balanced_boulder_speed(Vector2(1000.0, 300.0), 600.0, 55.0))
    if head_on > 282.1 or chase > 238.1 or cross > 258.1:
        push_error("V34_GAMEPLAY_VALIDATE: boulder caps wrong %.1f / %.1f / %.1f" % [head_on, chase, cross])
        quit(1)
        return

    print("V34_GAMEPLAY_OK")
    quit(0)

func _validate_double_jump() -> bool:
    var arena := Node2D.new()
    arena.name = "DoubleJumpArena"
    root.add_child(arena)

    var floor := StaticBody2D.new()
    floor.position = Vector2(0.0, 100.0)
    floor.collision_layer = 1
    floor.collision_mask = 1
    var floor_shape := CollisionShape2D.new()
    var floor_rect := RectangleShape2D.new()
    floor_rect.size = Vector2(500.0, 30.0)
    floor_shape.shape = floor_rect
    floor.add_child(floor_shape)
    arena.add_child(floor)

    var test_player := PlayerScript.new()
    test_player.position = Vector2(0.0, 60.0)
    test_player.collision_layer = 1
    test_player.collision_mask = 1
    var player_shape := CollisionShape2D.new()
    var player_rect := RectangleShape2D.new()
    player_rect.size = Vector2(38.0, 38.0)
    player_shape.shape = player_rect
    test_player.add_child(player_shape)
    arena.add_child(test_player)

    for i in range(6):
        await physics_frame
    if not test_player.is_on_floor():
        push_error("V34_GAMEPLAY_VALIDATE: double-jump test player did not settle on floor")
        arena.queue_free()
        return false

    Input.action_press("jump")
    await physics_frame
    Input.action_release("jump")
    await physics_frame
    if test_player._jumps_used != 1:
        push_error("V34_GAMEPLAY_VALIDATE: first jump count is %d" % test_player._jumps_used)
        arena.queue_free()
        return false

    await physics_frame
    Input.action_press("jump")
    await physics_frame
    Input.action_release("jump")
    await physics_frame
    if test_player._jumps_used != 2 or test_player.velocity.y > -520.0:
        push_error("V34_GAMEPLAY_VALIDATE: second jump failed count=%d vy=%.1f" % [test_player._jumps_used, test_player.velocity.y])
        arena.queue_free()
        return false

    await physics_frame
    Input.action_press("jump")
    await physics_frame
    Input.action_release("jump")
    await physics_frame
    if test_player._jumps_used != 2:
        push_error("V34_GAMEPLAY_VALIDATE: third jump changed jump count to %d" % test_player._jumps_used)
        arena.queue_free()
        return false

    arena.queue_free()
    await process_frame
    return true

func _count_oversized_hazard_rects(node: Node) -> int:
    if node == null:
        return 0
    var count := 0
    if node is Area2D:
        var area := node as Area2D
        if area.collision_layer == 2:
            for child in area.get_children():
                if child is CollisionShape2D:
                    var cs := child as CollisionShape2D
                    if cs.shape is RectangleShape2D:
                        var size := (cs.shape as RectangleShape2D).size
                        if size.x > 180.0 or size.y > 220.0:
                            count += 1
    for child in node.get_children():
        count += _count_oversized_hazard_rects(child)
    return count
