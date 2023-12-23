extends Node3D

func generate_path_to(initial_pos: Vector2i, final_pos: Vector2i) -> Array[Vector2i]:
    var path: Array[Vector2i] = []
    var init_pos: Vector2i = initial_pos
    var fin_pos: Vector2i = final_pos

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

    # while loop until reaching the final pos
    while x != fin_pos.x or y != fin_pos.y:
        if not path.has(Vector2i(x, y)):
            path.append(Vector2i(x, y))
        # Can only go right or up
        var choice = randi_range(0, 1)
        match dir_score:
            3, 9:
                if choice == 0 and x < fin_pos.x:
                    x += 1
                elif choice == 1 and y != fin_pos.y:
                    y += 1 if y < fin_pos.y else -1
            6, 12:
                if choice == 0 and x > fin_pos.x:
                    x -= 1
                elif choice == 1 and y != fin_pos.y:
                    y += 1 if y < fin_pos.y else -1
            1, 2, 4, 8:
                choice = randi_range(0, 2)
                if choice == 0 and x != fin_pos.x:
                    x += 1 if x < fin_pos.x else -1
                elif choice == 1 and y != fin_pos.y:
                    y += 1 if y < fin_pos.y else -1

    return path
