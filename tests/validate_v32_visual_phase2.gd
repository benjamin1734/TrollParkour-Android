extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://scenes/Main.tscn") as PackedScene
    if packed == null:
        push_error("VISUAL_PHASE2_VALIDATE: main scene missing")
        quit(1)
        return

    var game: Node = packed.instantiate()
    root.add_child(game)
    await process_frame
    await process_frame
    game.v22_sound_enabled = false
    game.v20_effects_enabled = false

    game._start_level(1, 1)
    await process_frame
    await process_frame

    if not is_instance_valid(game.world) or not is_instance_valid(game.player) or not is_instance_valid(game.hud):
        push_error("VISUAL_PHASE2_VALIDATE: runtime scene missing")
        quit(1)
        return

    if game.player.get_node_or_null("V32CoreLight") == null:
        push_error("VISUAL_PHASE2_VALIDATE: player core light missing")
        quit(1)
        return

    var environment: Node = game.world.get_node_or_null("V31Environment")
    if environment == null or environment.get_node_or_null("V32LightRibbons") == null:
        push_error("VISUAL_PHASE2_VALIDATE: light ribbons missing")
        quit(1)
        return

    if game.hud.get_node_or_null("V32HUDAccent") == null:
        push_error("VISUAL_PHASE2_VALIDATE: HUD accent missing")
        quit(1)
        return

    if not _has_finish_visual(game.world):
        push_error("VISUAL_PHASE2_VALIDATE: finish visual missing")
        quit(1)
        return

    var frame: Node2D = game.player.get_node_or_null("V31PlayerFrame") as Node2D
    if frame == null:
        push_error("VISUAL_PHASE2_VALIDATE: v31 player frame missing")
        quit(1)
        return
    game.player.velocity.x = 330.0
    game._v32_update_player_motion(0.20)
    if absf(frame.rotation) <= 0.0001:
        push_error("VISUAL_PHASE2_VALIDATE: player lean inactive")
        quit(1)
        return

    game.v20_effects_enabled = true
    game._v32_death_burst()
    game._v32_death_vignette()
    await process_frame
    if game.hud.get_node_or_null("V32DeathVignette") == null:
        push_error("VISUAL_PHASE2_VALIDATE: death vignette missing")
        quit(1)
        return

    game._v32_finish_burst()
    game._v32_finish_vignette()
    await process_frame
    if game.hud.get_node_or_null("V32FinishVignette") == null:
        push_error("VISUAL_PHASE2_VALIDATE: finish vignette missing")
        quit(1)
        return

    game.v20_effects_enabled = false
    game._start_level(21, 1)
    await process_frame
    await process_frame
    var dark_environment: Node = game.world.get_node_or_null("V31Environment")
    if dark_environment == null or dark_environment.get_node_or_null("V32LightRibbons") == null:
        push_error("VISUAL_PHASE2_VALIDATE: dark phase light ribbons missing")
        quit(1)
        return
    if not _has_finish_visual(game.world):
        push_error("VISUAL_PHASE2_VALIDATE: dark phase finish visual missing")
        quit(1)
        return

    print("VISUAL_PHASE2_OK")
    quit(0)

func _has_finish_visual(node: Node) -> bool:
    for child in node.get_children():
        if child is Area2D and child.get_node_or_null("V32FinishVisual") != null:
            return true
        if _has_finish_visual(child):
            return true
    return false
