extends "res://scripts/game_v7.gd"

# Touch balance pass: no normal floor spike row should require clearing more than 3 spikes.
# Inverted/ceiling special setups keep their authored counts.
func _spikes(pos: Vector2, count: int, hidden: bool, inverted: bool = false) -> Area2D:
    var balanced_count := count
    if not inverted and count > 3:
        balanced_count = 3
    return super._spikes(pos, balanced_count, hidden, inverted)
