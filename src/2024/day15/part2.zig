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
        var buffer = std.ArrayList(u8).init(allocator);
        defer buffer.deinit();

        for (line) |c| {
            const new_tile = switch (c) {
                '#' => "##",
                'O' => "[]",
                '.' => "..",
                '@' => "@.",
                else => unreachable,
            };
            try buffer.appendSlice(new_tile);
        }

        const buffer_slice = try buffer.toOwnedSlice();
        try grid.append(buffer_slice);

        const col = std.mem.indexOfScalar(u8, buffer_slice, '@');
        if (col) |i| {
            start_col = i;
        }

        if (start_col == null) {
            start_row += 1;
        }
    }

    const WIDTH: usize = grid.items[0].len;
    // const HEIGHT: usize = grid.items.len;

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
                const boxes = try bfs(allocator, grid.items, temp_pos, .Up);
                if (boxes) |b| {
                    defer allocator.free(b);
                    std.mem.sort(Position, b, {}, ascRow);

                    for (b) |pos| {
                        const ch = grid.items[pos.row][pos.column];
                        grid.items[pos.row][pos.column] = '.';
                        grid.items[pos.row - 1][pos.column] = ch;
                    }

                    grid.items[start_pos.row][start_pos.column] = '.';
                    start_pos.row -= 1;
                    grid.items[start_pos.row][start_pos.column] = '@';
                } else {
                    if (canMove(grid.items, start_pos, .Up)) {
                        grid.items[start_pos.row][start_pos.column] = '.';
                        start_pos.row -= 1;
                        grid.items[start_pos.row][start_pos.column] = '@';
                    }
                }
            },
            'v' => {
                const boxes = try bfs(allocator, grid.items, start_pos, .Down);
                if (boxes) |b| {
                    defer allocator.free(b);
                    std.mem.sort(Position, b, {}, descRow);

                    for (b) |pos| {
                        const ch = grid.items[pos.row][pos.column];
                        grid.items[pos.row][pos.column] = '.';
                        grid.items[pos.row + 1][pos.column] = ch;
                    }

                    grid.items[start_pos.row][start_pos.column] = '.';
                    start_pos.row += 1;
                    grid.items[start_pos.row][start_pos.column] = '@';
                } else {
                    if (canMove(grid.items, start_pos, .Down)) {
                        grid.items[start_pos.row][start_pos.column] = '.';
                        start_pos.row += 1;
                        grid.items[start_pos.row][start_pos.column] = '@';
                    }
                }
            },
            '>' => {
                while (temp_pos.column < WIDTH - 2) {
                    const cur = grid.items[temp_pos.row][temp_pos.column];
                    if (cur == '.') {
                        can_move = true;
                        break;
                    }

                    if (cur == '[') {
                        try box_positions.append(temp_pos);
                    }

                    if (cur == '#') {
                        break;
                    }

                    temp_pos.column += 1;
                }

                if (start_pos.column < WIDTH - 2 and can_move) {
                    while (box_positions.items.len > 0) {
                        const top = box_positions.pop() orelse break;

                        grid.items[top.row][top.column + 1] = '[';
                        grid.items[top.row][top.column + 2] = ']';
                    }

                    grid.items[start_pos.row][start_pos.column] = '.';
                    start_pos.column += 1;
                    grid.items[start_pos.row][start_pos.column] = '@';
                }
            },
            '<' => {
                while (temp_pos.column > 1) {
                    const cur = grid.items[temp_pos.row][temp_pos.column];
                    if (cur == '.') {
                        can_move = true;
                        break;
                    }

                    if (cur == ']') {
                        try box_positions.append(temp_pos);
                    }

                    if (cur == '#') {
                        break;
                    }

                    temp_pos.column -= 1;
                }

                if (start_pos.column > 1 and can_move) {
                    while (box_positions.items.len > 0) {
                        const top = box_positions.pop() orelse break;

                        grid.items[top.row][top.column - 1] = ']';
                        grid.items[top.row][top.column - 2] = '[';
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
            if (c != '[') {
                continue;
            }

            const irow = @as(i64, @intCast(row));
            const icol = @as(i64, @intCast(col));

            sum += irow * 100 + icol;
        }
    }

    return sum;
}

fn descRow(_: void, a: Position, b: Position) bool {
    return a.row > b.row;
}

fn ascRow(_: void, a: Position, b: Position) bool {
    return a.row < b.row;
}

const Direction = enum { Up, Down };

fn canMove(grid: [][]u8, pos: Position, dir: Direction) bool {
    const DELTA_Y: i64 = if (dir == .Down) 1 else -1;
    const width = grid[0].len;
    const height = grid.len;

    const f_row: i64 = @as(i64, @intCast(pos.row)) + DELTA_Y;
    const f_col: i64 = @as(i64, @intCast(pos.column));
    if (f_row <= 0 or f_col <= 1) {
        return false;
    }

    const first_col = @as(usize, @intCast(f_col));
    const first_row = @as(usize, @intCast(f_row));
    if (first_row >= height - 1 or first_col >= width - 2) {
        return false;
    }

    const first_ch = grid[first_row][first_col];
    return first_ch == '.';
}

fn bfs(allocator: std.mem.Allocator, grid: [][]u8, start_pos: Position, direction: Direction) !?[]Position {
    const DELTA_Y: i64 = if (direction == .Down) 1 else -1;
    const width = grid[0].len;
    const height = grid.len;

    const f_row: i64 = @as(i64, @intCast(start_pos.row)) + DELTA_Y;
    const f_col: i64 = @as(i64, @intCast(start_pos.column));
    if (f_row <= 0 or f_col <= 1) {
        return null;
    }

    const first_col = @as(usize, @intCast(f_col));
    const first_row = @as(usize, @intCast(f_row));
    if (first_row >= height - 1 or first_col >= width - 2) {
        return null;
    }

    const first_ch = grid[first_row][first_col];
    if (first_ch == '.' or first_ch == '#') {
        return null;
    }

    var queue = std.fifo.LinearFifo(Position, .Dynamic).init(allocator);
    defer queue.deinit();

    if (first_ch == '[') {
        try queue.writeItem(Position{ .row = first_row, .column = first_col });
        try queue.writeItem(Position{ .row = first_row, .column = first_col + 1 });
    } else if (first_ch == ']') {
        try queue.writeItem(Position{ .row = first_row, .column = first_col });
        try queue.writeItem(Position{ .row = first_row, .column = first_col - 1 });
    }

    var visited = std.AutoHashMap(Position, void).init(allocator);
    defer visited.deinit();

    while (queue.count > 0) {
        const vertex = queue.readItem() orelse break;
        if (visited.contains(vertex)) {
            continue;
        }

        try visited.put(vertex, {});

        const new_row: i64 = @as(i64, @intCast(vertex.row)) + DELTA_Y;
        const new_col: i64 = @as(i64, @intCast(vertex.column));
        if (new_row <= 0 or new_col <= 1) {
            return null;
        }

        const next_col = @as(usize, @intCast(new_col));
        const next_row = @as(usize, @intCast(new_row));
        if (next_row >= height - 1 or next_col >= width - 2) {
            return null;
        }

        const next_ch = grid[next_row][next_col];
        if (next_ch == '#') {
            return null;
        }

        if (next_ch == '[' or next_ch == ']') {
            try queue.writeItem(Position{ .column = next_col, .row = next_row });

            if (next_ch == '[') {
                try queue.writeItem(Position{ .column = next_col + 1, .row = next_row });
            } else {
                try queue.writeItem(Position{ .column = next_col - 1, .row = next_row });
            }
        }
    }

    var list = std.ArrayList(Position).init(allocator);
    defer list.deinit();

    var iter = visited.keyIterator();
    while (iter.next()) |pos| {
        try list.append(pos.*);
    }

    const slice = try list.toOwnedSlice();
    return slice;
}

const test_allocator = std.testing.allocator;

// test solve {
//     const input =
//         \\########
//         \\#..O.O.#
//         \\##@.O..#
//         \\#...O..#
//         \\#.#.O..#
//         \\#...O..#
//         \\#......#
//         \\########
//         \\
//         \\<^^>>>vv<v>>v<<
//     ;
//     const result = try solve(test_allocator, input);
//
//     try std.testing.expectEqual(2028, result);
// }

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

    try std.testing.expectEqual(9021, result);
}
