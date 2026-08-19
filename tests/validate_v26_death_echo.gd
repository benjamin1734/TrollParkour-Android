extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed := load("res://scenes/Main.tscn") as PackedScene
    if packed == null:
        push_error("DEATH_ECHO_VALIDATE: main scene missing")
        quit(1)
        return

    var game := packed.instantiate()
    root.add_child(game)
    await process_frame
    await process_frame

    game._start_level(22, 1)
    await process_frame
    await process_frame
    if not is_instance_valid(game.player):
        push_error("DEATH_ECHO_VALIDATE: player missing")
        quit(1)
        return

    game.player.global_position = Vector2(940, 560)
    game._on_player_died()
    await create_timer(0.70).timeout
    await process_frame

    var found := false
    if is_instance_valid(game.world):
        for child in game.world.get_children():
            if child is Label and child.text == "SON ÖLÜM":
                found = true
                break

    if found:
        print("DEATH_ECHO_OK")
        quit(0)
    else:
        push_error("DEATH_ECHO_VALIDATE: retry marker missing")
        quit(1)
