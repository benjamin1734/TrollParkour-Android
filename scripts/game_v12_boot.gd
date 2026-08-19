extends "res://scripts/game_v12.gd"

const BOOT_BG := Color("#edf1f6")

func _ready() -> void:
    RenderingServer.set_default_clear_color(BOOT_BG)
    _safe_load_progress()
    _show_main_menu()
    print("BOOT_OK:TrollParkour menu ready")
    call_deferred("_boot_audio")

func _safe_load_progress() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return

    var stored_deaths = cfg.get_value("progress", "deaths", 0)
    if stored_deaths is int or stored_deaths is float:
        deaths = maxi(0, int(stored_deaths))

    var stored_unlock = cfg.get_value("progress", "unlocked_chapter", 1)
    if stored_unlock is int or stored_unlock is float:
        unlocked_chapter = clampi(int(stored_unlock), 1, 11)

    var stored_attempts = cfg.get_value("memory", "level_attempts", {})
    if stored_attempts is Dictionary:
        level_attempts = stored_attempts.duplicate(true)

func _boot_audio() -> void:
    await get_tree().process_frame
    await get_tree().create_timer(0.10).timeout
    if not is_instance_valid(music):
        _start_music()
