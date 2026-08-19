extends "res://scripts/game_v2.gd"

# Balance pass: four-wide floor spike rows were too punishing on touch controls.
# Keep special/inverted spike setups intact, but clamp normal floor rows to 3.
func _spikes(pos: Vector2, count: int, hidden: bool, inverted: bool = false) -> Area2D:
    var balanced_count := count
    if count == 4 and not inverted:
        balanced_count = 3
    return super._spikes(pos, balanced_count, hidden, inverted)
