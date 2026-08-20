extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed := load("res://scenes/Main.tscn") as PackedScene
    if packed == null:
        push_error("RISK_SYNC_VALIDATE: main scene missing")
        quit(1)
        return

    var game := packed.instantiate()
    root.add_child(game)
    await process_frame
    await process_frame

    game._start_level(25, 1)
    await process_frame
    await process_frame

    if not is_instance_valid(game.v28_risk_label):
        push_error("RISK_SYNC_VALIDATE: risk label missing")
        quit(1)
        return

    game._v28_set_risk(2, 0.55)
    game._v28_set_risk(3, 0.22)
    await process_frame

    if game.v28_risk_level != 3 or not game.v28_risk_label.text.contains("YÜKSEK"):
        push_error("RISK_SYNC_VALIDATE: high risk did not win active stack")
        quit(1)
        return

    await create_timer(0.30).timeout
    await process_frame
    await process_frame

    if game.v28_risk_level != 2 or not game.v28_risk_label.text.contains("ORTA"):
        push_error("RISK_SYNC_VALIDATE: medium risk did not remain after high risk expiry")
        quit(1)
        return

    await create_timer(0.36).timeout
    await process_frame
    await process_frame

    if game.v28_risk_level != 0:
        push_error("RISK_SYNC_VALIDATE: risk did not fully expire")
        quit(1)
        return

    print("RISK_SYNC_OK")
    quit(0)
