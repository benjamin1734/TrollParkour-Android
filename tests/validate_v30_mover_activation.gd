extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed := load("res://scenes/Main.tscn") as PackedScene
    if packed == null:
        push_error("MOVER_VALIDATE: main scene missing")
        quit(1)
        return
    var game = packed.instantiate()
    root.add_child(game)
    await process_frame
    await process_frame
    game.v20_effects_enabled = false
    game.v22_sound_enabled = false
    game._start_level(6, 1)
    await process_frame
    await process_frame

    var mover: AnimatableBody2D = null
    for child in game.world.get_children():
        if child is AnimatableBody2D and child.has_meta("v30_lazy_mover"):
            mover = child as AnimatableBody2D
            break
    if mover == null:
        push_error("MOVER_VALIDATE: no lazy mover in 6-1")
        quit(1)
        return

    var start := mover.position
    await create_timer(0.35).timeout
    if mover.position.distance_to(start) > 1.0 or bool(mover.get_meta("v30_mover_activated", false)):
        push_error("MOVER_VALIDATE: platform moved before player approach")
        quit(1)
        return

    game.player.input_enabled = false
    game.player.global_position = Vector2(start.x - 220.0, start.y)
    game.player.velocity.x = 80.0
    await process_frame
    await create_timer(0.12).timeout
    if bool(mover.get_meta("v30_mover_activated", false)):
        push_error("MOVER_VALIDATE: platform activated while player was still 220px away")
        quit(1)
        return

    game.player.global_position = Vector2(start.x - 80.0, start.y)
    game.player.velocity.x = 80.0
    await process_frame
    await create_timer(0.20).timeout
    if not bool(mover.get_meta("v30_mover_activated", false)):
        push_error("MOVER_VALIDATE: platform did not activate at close range")
        quit(1)
        return
    if mover.position.distance_to(start) < 1.0:
        push_error("MOVER_VALIDATE: activated platform did not begin motion")
        quit(1)
        return

    print("MOVER_ACTIVATION_OK")
    quit(0)
