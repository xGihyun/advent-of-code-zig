const std = @import("std");

pub fn main() !void {
    const input: []const u8 = @embedFile("./input.txt");
    const allocator = std.heap.page_allocator;

    var timer = try std.time.Timer.start();
    const result = try solve(allocator, input);

    const elapsed_ns = timer.read();
    const elapsed_s = @as(f64, @floatFromInt(elapsed_ns)) / std.time.ns_per_s;

    std.debug.print("\n{d}\n", .{result});
    std.debug.print("Time: {d:.3} seconds", .{elapsed_s});
}

const Position = struct {
    row: usize,
    col: usize,
    target: u8,
};

fn solve(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var matrix = std.ArrayList([]const u8).init(allocator);
    defer matrix.deinit();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        try matrix.append(line);
    }

    const rows = matrix.items.len;
    const columns = matrix.items[0].len;

    var count: u64 = 0;

    for (0..rows) |row| {
        for (0..columns) |col| {
            const c = matrix.items[row][col];
            const pos = Position{ .col = col, .row = row, .target = c };
            if (c == '0') {
                count += try countValidPath(allocator, matrix.items, pos);
            }
        }
    }

    return count;
}

fn countValidPath(allocator: std.mem.Allocator, matrix: [][]const u8, start_pos: Position) !u64 {
    const DELTA_X: [4]i32 = [4]i32{ 1, -1, 0, 0 };
    const DELTA_Y: [4]i32 = [4]i32{ 0, 0, 1, -1 };
    const rows = matrix.len;
    const columns = matrix[0].len;
    var count: u64 = 0;

    var stack = std.ArrayList(Position).init(allocator);
    defer stack.deinit();

    try stack.append(start_pos);

    // var visited: [50][50]bool = undefined;

    while (stack.items.len > 0) {
        const top = stack.pop() orelse break;
        const row = top.row;
        const col = top.col;

        // if (visited[row][col]) {
        //     continue;
        // }
        //
        // visited[row][col] = true;

        if (top.target == '9') {
            count += 1;
            continue;
        }

        const next_target = top.target + 1;

        for (0..4) |i| {
            const dx = DELTA_X[i];
            const dy = DELTA_Y[i];
            const new_col: i32 = @as(i32, @intCast(col)) + dx;
            const new_row: i32 = @as(i32, @intCast(row)) + dy;
            if (new_col < 0 or new_row < 0) {
                continue;
            }

            const next_col = @as(usize, @intCast(new_col));
            const next_row = @as(usize, @intCast(new_row));
            if (next_row >= rows or next_col >= columns) {
                continue;
            }

            // if (visited[next_row][next_col]) {
            //     continue;
            // }

            if (matrix[next_row][next_col] == next_target) {
                try stack.append(Position{
                    .col = next_col,
                    .row = next_row,
                    .target = next_target,
                });
            }
        }
    }

    return count;
}

const test_allocator = std.testing.allocator;

test solve {
    const input =
        \\0123
        \\1234
        \\8765
        \\9876
    ;

    const result = try solve(test_allocator, input);

    try std.testing.expectEqual(16, result);
}

test "solve 2" {
    const input =
        \\89010123
        \\78121874
        \\87430965
        \\96549874
        \\45678903
        \\32019012
        \\01329801
        \\10456732
    ;

    const result = try solve(test_allocator, input);

    try std.testing.expectEqual(81, result);
}
