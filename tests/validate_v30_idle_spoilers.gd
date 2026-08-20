extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed := load("res://scenes/Main.tscn") as PackedScene
    if packed == null:
        push_error("IDLE_SPOILER_VALIDATE: main scene missing")
        quit(1)
        return
    var game = packed.instantiate()
    root.add_child(game)
    await process_frame
    await process_frame
    game.v20_effects_enabled = false
    game.v22_sound_enabled = false

    var checked := 0
    for c in range(1, 26):
        for p in range(1, 4):
            game._start_level(c, p)
            await process_frame
            await process_frame
            var snapshot: Dictionary = {}
            _collect_collision_positions(game.world, game.player, snapshot)
            await create_timer(0.18).timeout
            for id in snapshot.keys():
                var state: Dictionary = snapshot[id]
                var node := state.get("node") as Node2D
                if not is_instance_valid(node):
                    continue
                var before: Vector2 = state.get("pos", node.global_position)
                if node.global_position.distance_to(before) > 2.5:
                    push_error("IDLE_SPOILER_VALIDATE: %d-%d collider %s moved %.1fpx before player action" % [c, p, node.name, node.global_position.distance_to(before)])
                    quit(1)
                    return
            checked += 1
    if checked != 75:
        push_error("IDLE_SPOILER_VALIDATE: checked %d maps" % checked)
        quit(1)
        return
    print("IDLE_SPOILER_OK:75")
    quit(0)

func _collect_collision_positions(node: Node, player: Node, out: Dictionary) -> void:
    for child in node.get_children():
        if child is CollisionObject2D and child != player:
            var n := child as Node2D
            out[n.get_instance_id()] = {"node": n, "pos": n.global_position}
        _collect_collision_positions(child, player, out)
