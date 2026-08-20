extends SceneTree

const PlayerScript = preload("res://scripts/player.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed := load("res://scenes/Main.tscn") as PackedScene
    if packed == null:
        push_error("V35_VALIDATE: main scene missing")
        quit(1)
        return
    var game = packed.instantiate()
    root.add_child(game)
    await process_frame
    await process_frame
    game.v20_effects_enabled = false
    game.v22_sound_enabled = false

    var single_height := (PlayerScript.JUMP_VELOCITY * PlayerScript.JUMP_VELOCITY) / (2.0 * PlayerScript.GRAVITY)
    var single_airtime := 2.0 * absf(PlayerScript.JUMP_VELOCITY) / PlayerScript.GRAVITY
    var theoretical_horizontal := PlayerScript.SPEED * single_airtime
    if theoretical_horizontal < 220.0:
        push_error("V35_VALIDATE: unexpected player jump envelope %.1f" % theoretical_horizontal)
        quit(1)
        return

    var checked := 0
    for c in range(1, 27):
        for p in range(1, 4):
            game._start_level(c, p)
            await process_frame
            await process_frame
            if not is_instance_valid(game.world) or not bool(game.world.get_meta("v35_rebuilt", false)):
                push_error("V35_VALIDATE: %d-%d not rebuilt" % [c, p])
                quit(1)
                return
            if String(game.world.get_meta("v35_map_id", "")) != "%d-%d" % [c, p]:
                push_error("V35_VALIDATE: %d-%d wrong map id" % [c, p])
                quit(1)
                return
            if int(game.world.get_meta("v35_required_movers", -1)) != 0:
                push_error("V35_VALIDATE: %d-%d requires a moving platform" % [c, p])
                quit(1)
                return

            var widths = game.world.get_meta("v35_gap_widths", PackedFloat32Array())
            if widths.size() != 2:
                push_error("V35_VALIDATE: %d-%d gap metadata missing" % [c, p])
                quit(1)
                return
            for width in widths:
                if float(width) > 160.0 or float(width) > theoretical_horizontal * 0.70:
                    push_error("V35_VALIDATE: %d-%d unsafe gap %.1f vs jump %.1f" % [c, p, float(width), theoretical_horizontal])
                    quit(1)
                    return

            var route: Array[Node2D] = []
            _collect_route(game.world, route)
            route.sort_custom(func(a: Node2D, b: Node2D): return int(a.get_meta("v35_route_index", 0)) < int(b.get_meta("v35_route_index", 0)))
            if route.size() != 6:
                push_error("V35_VALIDATE: %d-%d route point count %d" % [c, p, route.size()])
                quit(1)
                return
            for i in range(1, route.size()):
                var reach := String(route[i].get_meta("v35_reach", "walk"))
                if reach == "single":
                    var dx := absf(route[i].position.x - route[i - 1].position.x)
                    var rise := route[i - 1].position.y - route[i].position.y
                    if dx > theoretical_horizontal * 0.86 or rise > single_height - 8.0:
                        push_error("V35_VALIDATE: %d-%d unsafe single jump dx=%.1f rise=%.1f" % [c, p, dx, rise])
                        quit(1)
                        return

            for contract in game.v35_contracts:
                var kind := String(contract.get("kind", ""))
                if contract.has("reaction"):
                    var reaction := float(contract.get("reaction", 0.0))
                    if kind != "false_alarm" and reaction < 0.24:
                        push_error("V35_VALIDATE: %d-%d %s reaction %.2f" % [c, p, kind, reaction])
                        quit(1)
                        return
                if contract.has("trigger_x") and contract.has("hazard_x"):
                    var delta := float(contract.get("hazard_x", 0.0)) - float(contract.get("trigger_x", 0.0))
                    if delta < 70.0 or delta > 320.0:
                        push_error("V35_VALIDATE: %d-%d %s off-route trigger delta %.1f" % [c, p, kind, delta])
                        quit(1)
                        return

            if _count_oversized_blocks(game.world) > 0:
                push_error("V35_VALIDATE: %d-%d contains oversized rectangular hazard" % [c, p])
                quit(1)
                return
            checked += 1

    if checked != 78:
        push_error("V35_VALIDATE: checked %d maps" % checked)
        quit(1)
        return

    game._start_level(3, 3)
    await process_frame
    await process_frame
    for contract in game.v35_contracts:
        if String(contract.get("kind", "")) == "chase":
            push_error("V35_VALIDATE: 3-3 still contains mandatory chase")
            quit(1)
            return

    print("V35_FULL_REBUILD_OK:78")
    quit(0)

func _collect_route(node: Node, out: Array[Node2D]) -> void:
    if node == null:
        return
    if node is Node2D and bool(node.get_meta("v35_route_point", false)):
        out.append(node as Node2D)
    for child in node.get_children():
        _collect_route(child, out)

func _count_oversized_blocks(node: Node) -> int:
    if node == null:
        return 0
    var count := 0
    if node is Area2D and bool(node.get_meta("v35_hazard_block", false)):
        var size: Vector2 = node.get_meta("v35_hazard_size", Vector2.ZERO)
        if size.x > 120.1 or size.y > 150.1:
            count += 1
    for child in node.get_children():
        count += _count_oversized_blocks(child)
    return count
