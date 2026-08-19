extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed := load("res://scenes/Main.tscn") as PackedScene
    if packed == null:
        push_error("ROUTE_TRACE_VALIDATE: main scene missing")
        quit(1)
        return

    var game := packed.instantiate()
    root.add_child(game)
    await process_frame
    await process_frame

    game._start_level(24, 1)
    await process_frame
    await process_frame
    if not is_instance_valid(game.player):
        push_error("ROUTE_TRACE_VALIDATE: player missing")
        quit(1)
        return

    for i in range(7):
        game.player.global_position = Vector2(500.0 + float(i) * 62.0, 560.0 - float(i % 2) * 18.0)
        await create_timer(0.09).timeout
        await process_frame

    if game.v28_path_samples.size() < 3:
        push_error("ROUTE_TRACE_VALIDATE: route samples missing")
        quit(1)
        return

    game._on_player_died()
    await create_timer(0.72).timeout
    await process_frame
    await process_frame

    if game.v28_last_path.size() < 3:
        push_error("ROUTE_TRACE_VALIDATE: captured path missing")
        quit(1)
        return

    var found := false
    if is_instance_valid(game.world):
        var expected := PackedVector2Array(game.v28_last_path)
        for child in game.world.get_children():
            if child is Line2D:
                var line := child as Line2D
                if line.points.size() == expected.size() and line.points.size() >= 3:
                    var matches := true
                    for j in range(line.points.size()):
                        if line.points[j].distance_to(expected[j]) > 0.5:
                            matches = false
                            break
                    if matches:
                        found = true
                        break

    if found:
        print("ROUTE_TRACE_OK")
        quit(0)
    else:
        push_error("ROUTE_TRACE_VALIDATE: retry trail missing")
        quit(1)
