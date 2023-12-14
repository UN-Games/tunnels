extends Object
class_name PathGenerator

var _path: Array[Vector2i]

func _init() -> void:
    pass

func generate_path(initial_pos: Vector2i, final_pos: Vector2i) -> Array[Vector2i]:
    var init_pos: Vector2i = initial_pos
    var fin_pos: Vector2i = final_pos

    _path.clear()
    var dir_score: int = 0;
    # decide which algorithm to use, if the final pos is left, right, up or down from the initial pos
    if fin_pos.x > init_pos.x:
        dir_score += 1
    if fin_pos.y > init_pos.y:
        dir_score += 2
    if fin_pos.x < init_pos.x:
        dir_score += 4
    if fin_pos.y < init_pos.y:
        dir_score += 8

    var x: int = init_pos.x
    var y: int = init_pos.y

    if dir_score == 3:
        # while loop unitl reaching the final pos
        while x != fin_pos.x or y != fin_pos.y:
            if not _path.has(Vector2i(x, y)):
                _path.append(Vector2i(x, y))
            # Can only go right or up
            var choice = randi_range(0, 1)

            if choice == 0 and x < fin_pos.x:
                x += 1
            elif choice == 1 and y < fin_pos.y:
                y += 1

    print("Path generated: ", _path)

    return _path
