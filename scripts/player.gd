extends CharacterBody2D

signal died
signal jumped

const SPEED := 330.0
const ACCELERATION := 2200.0
const AIR_ACCELERATION := 1500.0
const FRICTION := 2600.0
const GRAVITY := 1850.0
const JUMP_VELOCITY := -650.0
const COYOTE_TIME := 0.10
const JUMP_BUFFER := 0.12

var alive := true
var input_enabled := true
var _coyote := 0.0
var _jump_buffer := 0.0

func _physics_process(delta: float) -> void:
    if not alive:
        return
    if is_on_floor():
        _coyote = COYOTE_TIME
    else:
        _coyote = maxf(0.0, _coyote - delta)
        velocity.y += GRAVITY * delta
    if Input.is_action_just_pressed("jump"):
        _jump_buffer = JUMP_BUFFER
    else:
        _jump_buffer = maxf(0.0, _jump_buffer - delta)
    if input_enabled and _jump_buffer > 0.0 and _coyote > 0.0:
        velocity.y = JUMP_VELOCITY
        _jump_buffer = 0.0
        _coyote = 0.0
        jumped.emit()
    var axis := Input.get_axis("move_left", "move_right") if input_enabled else 0.0
    var accel := ACCELERATION if is_on_floor() else AIR_ACCELERATION
    velocity.x = move_toward(velocity.x, axis * SPEED, accel * delta) if absf(axis) > 0.01 else move_toward(velocity.x, 0.0, FRICTION * delta)
    move_and_slide()
    if global_position.y > 900.0:
        die()

func die() -> void:
    if not alive:
        return
    alive = false
    input_enabled = false
    velocity = Vector2.ZERO
    died.emit()
