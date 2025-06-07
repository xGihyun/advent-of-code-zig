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

const Region = struct { area: u64, perimeter: u64 };
const Position = struct { row: usize, col: usize, plant_type: u8 };

fn solve(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var matrix = std.ArrayList([]const u8).init(allocator);
    defer matrix.deinit();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        try matrix.append(line);
    }

    const rows = matrix.items.len;
    const columns = matrix.items[0].len;

    var sum: u64 = 0;

    var visited: [140][140]bool = undefined;

    for (0..rows) |row| {
        for (0..columns) |col| {
            if (visited[row][col]) {
                continue;
            }

            const c = matrix.items[row][col];
            const pos = Position{ .col = col, .plant_type = c, .row = row };
            const region = try getRegion(allocator, matrix.items, &visited, pos);

            // std.debug.print("{c}: {any}\n", .{ c, region });

            sum += region.area * region.perimeter;
        }
    }

    return sum;
}

fn getRegion(allocator: std.mem.Allocator, matrix: [][]const u8, visited: *[140][140]bool, start_pos: Position) !Region {
    const DELTA_X: [4]i32 = [4]i32{ 1, -1, 0, 0 };
    const DELTA_Y: [4]i32 = [4]i32{ 0, 0, 1, -1 };

    const size = matrix.len;
    var region = Region{ .area = 0, .perimeter = 0 };

    var stack = std.ArrayList(Position).init(allocator);
    defer stack.deinit();

    try stack.append(start_pos);

    while (stack.items.len > 0) {
        const top = stack.pop() orelse break;
        const row = top.row;
        const col = top.col;

        if (visited[row][col]) {
            continue;
        }

        visited[row][col] = true;

        for (0..4) |i| {
            const dx = DELTA_X[i];
            const dy = DELTA_Y[i];
            const new_col: i32 = @as(i32, @intCast(col)) + dx;
            const new_row: i32 = @as(i32, @intCast(row)) + dy;

            if (new_col < 0) {
                region.perimeter += 1;
            }
            if (new_row < 0) {
                region.perimeter += 1;
            }
            if (new_col >= size) {
                region.perimeter += 1;
            }
            if (new_row >= size) {
                region.perimeter += 1;
            }

            if (new_col < 0 or new_row < 0) {
                continue;
            }

            const next_col = @as(usize, @intCast(new_col));
            const next_row = @as(usize, @intCast(new_row));
            if (next_row >= size or next_col >= size) {
                continue;
            }

            if (matrix[next_row][next_col] != start_pos.plant_type) {
                region.perimeter += 1;
                continue;
            }

            if (visited[next_row][next_col]) {
                continue;
            }

            try stack.append(Position{ .col = next_col, .row = next_row, .plant_type = start_pos.plant_type });
        }

        region.area += 1;

        // std.debug.print("{any}\n", .{stack.items});
    }

    return region;
}

const test_allocator = std.testing.allocator;

test solve {
    const input =
        \\AAAA
        \\BBCD
        \\BBCC
        \\EEEC
    ;

    const result = try solve(test_allocator, input);

    try std.testing.expectEqual(140, result);
}

test "solve 2" {
    const input =
        \\RRRRIICCFF
        \\RRRRIICCCF
        \\VVRRRCCFFF
        \\VVRCCCJFFF
        \\VVVVCJJCFE
        \\VVIVCCJJEE
        \\VVIIICJJEE
        \\MIIIIIJJEE
        \\MIIISIJEEE
        \\MMMISSJEEE
    ;

    const result = try solve(test_allocator, input);

    try std.testing.expectEqual(1930, result);
}
