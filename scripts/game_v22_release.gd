extends "res://scripts/game_v22.gd"

func _platform(pos: Vector2, size: Vector2, color: Color) -> StaticBody2D:
    var body := StaticBody2D.new()
    body.position = pos
    body.collision_layer = 1

    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = size
    cs.shape = shape
    body.add_child(cs)

    var shadow := Polygon2D.new()
    shadow.position = Vector2(4, 5)
    shadow.polygon = PackedVector2Array([
        Vector2(-size.x / 2.0, -size.y / 2.0), Vector2(size.x / 2.0, -size.y / 2.0),
        Vector2(size.x / 2.0, size.y / 2.0), Vector2(-size.x / 2.0, size.y / 2.0)
    ])
    shadow.color = Color(0.02, 0.04, 0.07, 0.14)
    shadow.z_index = -2
    body.add_child(shadow)

    var poly := Polygon2D.new()
    poly.polygon = PackedVector2Array([
        Vector2(-size.x / 2.0, -size.y / 2.0), Vector2(size.x / 2.0, -size.y / 2.0),
        Vector2(size.x / 2.0, size.y / 2.0), Vector2(-size.x / 2.0, size.y / 2.0)
    ])
    poly.color = color
    body.add_child(poly)

    var edge := Line2D.new()
    edge.width = 1.5
    edge.default_color = Color(0.76, 0.86, 0.93, 0.22)
    edge.points = PackedVector2Array([
        Vector2(-size.x / 2.0 + 8.0, -size.y / 2.0 + 2.0),
        Vector2(size.x / 2.0 - 8.0, -size.y / 2.0 + 2.0)
    ])
    edge.z_index = 3
    body.add_child(edge)

    if size.x >= 150.0 and size.x <= 800.0:
        for side in [-1.0, 1.0]:
            var bolt := Polygon2D.new()
            bolt.position = Vector2(side * (size.x / 2.0 - 14.0), -size.y / 2.0 + 7.0)
            bolt.polygon = _circle_points(2.5, 10)
            bolt.color = Color(0.65, 0.76, 0.84, 0.30)
            bolt.z_index = 4
            body.add_child(bolt)

    world.add_child(body)
    return body
