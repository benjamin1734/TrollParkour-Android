extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed := load("res://scenes/Main.tscn") as PackedScene
    if packed == null:
        push_error("VISUAL_VALIDATE: main scene missing")
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
    if not is_instance_valid(game.world):
        push_error("VISUAL_VALIDATE: world missing")
        quit(1)
        return
    var env := game.world.get_node_or_null("V31Environment")
    if env == null or env.get_node_or_null("Far") == null or env.get_node_or_null("Mid") == null or env.get_node_or_null("Near") == null:
        push_error("VISUAL_VALIDATE: layered environment missing")
        quit(1)
        return
    if not _has_named_descendant(game.world, "V31PlatformSkin"):
        push_error("VISUAL_VALIDATE: platform skin missing")
        quit(1)
        return
    if not is_instance_valid(game.player) or game.player.get_node_or_null("V31PlayerFrame") == null:
        push_error("VISUAL_VALIDATE: player visual frame missing")
        quit(1)
        return
    if game.hud == null or game.hud.get_node_or_null("V31HUDGlow") == null or game.hud.get_node_or_null("V31MapProgress") == null:
        push_error("VISUAL_VALIDATE: HUD polish missing")
        quit(1)
        return

    var hidden_spike = game._spikes(Vector2(780, 612), 3, true)
    await process_frame
    var spike_decor := hidden_spike.get_node_or_null("V31SpikeDecor")
    if spike_decor == null or spike_decor.visible:
        push_error("VISUAL_VALIDATE: hidden spike decor leaks before reveal")
        quit(1)
        return
    game._reveal(hidden_spike)
    await process_frame
    if not spike_decor.visible:
        push_error("VISUAL_VALIDATE: spike decor missing after reveal")
        quit(1)
        return
    game._hide(hidden_spike)
    await process_frame
    if spike_decor.visible:
        push_error("VISUAL_VALIDATE: spike decor remains visible after hide")
        quit(1)
        return

    var mover = game._moving_platform(Vector2(900, 510), Vector2(180, 24), Vector2(1120, 455), 1.2, Color("#2563eb"))
    await process_frame
    if mover.get_node_or_null("V31PlatformSkin") == null:
        push_error("VISUAL_VALIDATE: moving platform skin missing")
        quit(1)
        return
    if bool(mover.get_meta("v30_mover_activated", false)):
        push_error("VISUAL_VALIDATE: visual pass activated mover early")
        quit(1)
        return

    game._boulder(Vector2(920, 560), -350.0, 60.0)
    await process_frame
    if not _has_boulder(game.world):
        push_error("VISUAL_VALIDATE: boulder visual skin missing")
        quit(1)
        return

    game._start_level(21, 1)
    await process_frame
    await process_frame
    var dark_env := game.world.get_node_or_null("V31Environment")
    if dark_env == null or not bool(dark_env.get_meta("dark", false)):
        push_error("VISUAL_VALIDATE: dark-era environment flag missing")
        quit(1)
        return

    print("VISUAL_OVERHAUL_OK")
    quit(0)

func _has_named_descendant(node: Node, wanted: String) -> bool:
    for child in node.get_children():
        if child.name == wanted:
            return true
        if _has_named_descendant(child, wanted):
            return true
    return false

func _has_boulder(node: Node) -> bool:
    for child in node.get_children():
        if child is Area2D and bool(child.get_meta("v31_boulder", false)):
            return true
        if _has_boulder(child):
            return true
    return false
