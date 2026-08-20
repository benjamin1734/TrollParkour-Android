extends "res://scripts/game_v35_full_rebuild.gd"

func _on_ch16_jump() -> void:
    return

func _v20_ch18_jump_logic(_x: float) -> void:
    return

func _v35_small_crusher(x: float, key: String) -> void:
    var crusher := _hazard_block(Vector2(x, 350), Vector2(64, 96), V35_RED)
    var trigger_x := x - 145.0
    _trigger(Rect2(trigger_x, 470, 100, 165), func():
        if _once(key):
            var tw := create_tween()
            tw.tween_interval(0.28)
            tw.tween_property(crusher, "position:y", 520.0, 0.44).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
            tw.tween_interval(0.22)
            tw.tween_property(crusher, "position:y", 350.0, 0.46).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    )
    _v35_contract("crusher", trigger_x, x, 0.28)
