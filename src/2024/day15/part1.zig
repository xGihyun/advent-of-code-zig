const std = @import("std");

pub fn main() !void {
    const input: []const u8 = @embedFile("./input.txt");
    const allocator = std.heap.page_allocator;

    var timer = try std.time.Timer.start();
    const result = try solve(allocator, input);

    const elapsed_ns = timer.read();
    const elapsed_ms = @as(f64, @floatFromInt(elapsed_ns)) / std.time.ns_per_ms;

    std.debug.print("\n{d}\n", .{result});
    std.debug.print("Time: {d:.3} ms", .{elapsed_ms});
}

const Position = struct { row: usize, column: usize };

fn solve(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var parts_iter = std.mem.tokenizeSequence(u8, input, "\n\n");
    const map_str = parts_iter.next() orelse unreachable;

    var grid = std.ArrayList([]u8).init(allocator);
    defer {
        for (grid.items) |value| {
            allocator.free(value);
        }
        grid.deinit();
    }

    var start_pos: Position = Position{ .row = 0, .column = 0 };
    var start_col: ?usize = null;
    var start_row: usize = 0;
    var lines_iter = std.mem.tokenizeScalar(u8, map_str, '\n');
    while (lines_iter.next()) |line| {
        const buffer = try allocator.alloc(u8, line.len);
        std.mem.copyForwards(u8, buffer, line);
        try grid.append(buffer);

        const col = std.mem.indexOfScalar(u8, line, '@');
        if (col) |i| {
            start_col = i;
        }

        if (start_col == null) {
            start_row += 1;
        }
    }

    const SIZE: usize = grid.items.len;

    if (start_col == null) {
        return 0;
    }

    start_pos = Position{ .column = start_col.?, .row = start_row };

    const moves_str = parts_iter.next() orelse unreachable;
    for (moves_str) |c| {
        if (c == '\n') {
            continue;
        }

        var temp_pos = start_pos;
        var can_move = false;

        var box_positions = std.ArrayList(Position).init(allocator);
        defer box_positions.deinit();

        switch (c) {
            '^' => {
                while (temp_pos.row > 0) {
                    if (grid.items[temp_pos.row][temp_pos.column] == '.') {
                        can_move = true;
                        break;
                    }

                    if (grid.items[temp_pos.row][temp_pos.column] == 'O') {
                        try box_positions.append(temp_pos);
                    }

                    if (grid.items[temp_pos.row][temp_pos.column] == '#') {
                        break;
                    }

                    temp_pos.row -= 1;
                }

                if (start_pos.row > 0 and can_move) {
                    while (box_positions.items.len > 0) {
                        const top = box_positions.pop() orelse break;

                        grid.items[top.row - 1][top.column] = 'O';
                    }

                    grid.items[start_pos.row][start_pos.column] = '.';
                    start_pos.row -= 1;
                    grid.items[start_pos.row][start_pos.column] = '@';
                }
            },
            'v' => {
                while (temp_pos.row < SIZE - 1) {
                    if (grid.items[temp_pos.row][temp_pos.column] == '.') {
                        can_move = true;
                        break;
                    }

                    if (grid.items[temp_pos.row][temp_pos.column] == 'O') {
                        try box_positions.append(temp_pos);
                    }

                    if (grid.items[temp_pos.row][temp_pos.column] == '#') {
                        break;
                    }

                    temp_pos.row += 1;
                }

                if (start_pos.row < SIZE - 1 and can_move) {
                    while (box_positions.items.len > 0) {
                        const top = box_positions.pop() orelse break;

                        grid.items[top.row + 1][top.column] = 'O';
                    }

                    grid.items[start_pos.row][start_pos.column] = '.';
                    start_pos.row += 1;
                    grid.items[start_pos.row][start_pos.column] = '@';
                }
            },
            '>' => {
                while (temp_pos.column < SIZE - 1) {
                    if (grid.items[temp_pos.row][temp_pos.column] == '.') {
                        can_move = true;
                        break;
                    }

                    if (grid.items[temp_pos.row][temp_pos.column] == 'O') {
                        try box_positions.append(temp_pos);
                    }

                    if (grid.items[temp_pos.row][temp_pos.column] == '#') {
                        break;
                    }

                    temp_pos.column += 1;
                }

                if (start_pos.column < SIZE - 1 and can_move) {
                    while (box_positions.items.len > 0) {
                        const top = box_positions.pop() orelse break;

                        grid.items[top.row][top.column + 1] = 'O';
                    }

                    grid.items[start_pos.row][start_pos.column] = '.';
                    start_pos.column += 1;
                    grid.items[start_pos.row][start_pos.column] = '@';
                }
            },
            '<' => {
                while (temp_pos.column > 0) {
                    if (grid.items[temp_pos.row][temp_pos.column] == '.') {
                        can_move = true;
                        break;
                    }

                    if (grid.items[temp_pos.row][temp_pos.column] == 'O') {
                        try box_positions.append(temp_pos);
                    }

                    if (grid.items[temp_pos.row][temp_pos.column] == '#') {
                        break;
                    }

                    temp_pos.column -= 1;
                }

                if (start_pos.column > 0 and can_move) {
                    while (box_positions.items.len > 0) {
                        const top = box_positions.pop() orelse break;

                        grid.items[top.row][top.column - 1] = 'O';
                    }

                    grid.items[start_pos.row][start_pos.column] = '.';
                    start_pos.column -= 1;
                    grid.items[start_pos.row][start_pos.column] = '@';
                }
            },
            else => unreachable,
        }

        // std.debug.print("{any}\n", .{start_pos});
        // std.debug.print("{c}\n", .{c});
        // for (grid.items) |value| {
        //     std.debug.print("{s}\n", .{value});
        // }
        // std.debug.print("\n", .{});
    }

    var sum: i64 = 0;

    for (grid.items, 0..) |line, row| {
        for (line, 0..) |c, col| {
            if (c != 'O') {
                continue;
            }

            const irow = @as(i64, @intCast(row));
            const icol = @as(i64, @intCast(col));

            sum += irow * 100 + icol;
        }
    }

    return sum;
}

const test_allocator = std.testing.allocator;

test solve {
    const input =
        \\########
        \\#..O.O.#
        \\##@.O..#
        \\#...O..#
        \\#.#.O..#
        \\#...O..#
        \\#......#
        \\########
        \\
        \\<^^>>>vv<v>>v<<
    ;
    const result = try solve(test_allocator, input);

    try std.testing.expectEqual(2028, result);
}

test "solve big input" {
    const input =
        \\##########
        \\#..O..O.O#
        \\#......O.#
        \\#.OO..O.O#
        \\#..O@..O.#
        \\#O#..O...#
        \\#O..O..O.#
        \\#.OO.O.OO#
        \\#....O...#
        \\##########
        \\
        \\<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
        \\vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
        \\><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
        \\<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
        \\^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
        \\^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
        \\>^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^
        \\<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>
        \\^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>
        \\v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^
    ;
    const result = try solve(test_allocator, input);

    try std.testing.expectEqual(10092, result);
}
