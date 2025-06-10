const std = @import("std");

pub fn main() !void {
    const input: []const u8 = @embedFile("./input.txt");
    const allocator = std.heap.page_allocator;

    const dimensions = Position{ .x = 101, .y = 103 };
    var timer = try std.time.Timer.start();
    const result = try solve(allocator, input, dimensions);

    const elapsed_ns = timer.read();
    const elapsed_ms = @as(f64, @floatFromInt(elapsed_ns)) / std.time.ns_per_ms;

    std.debug.print("\n{d}\n", .{result});
    std.debug.print("Time: {d:.3} ms", .{elapsed_ms});
}

const TIME_IN_SECONDS: i64 = 100;

const Position = struct {
    x: i64,
    y: i64,
};

fn solve(_: std.mem.Allocator, input: []const u8, dimensions: Position) !i64 {
    var count: i64 = 1;

    const midpoint = Position{ .x = @divTrunc(dimensions.x, 2), .y = @divTrunc(dimensions.y, 2) };
    var quadrants: [4]i64 = .{0} ** 4;

    var lines_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines_iter.next()) |line| {
        var values_iter = std.mem.tokenizeScalar(u8, line, ' ');

        const init_pos_str = values_iter.next() orelse unreachable;
        const init_pos = try parsePosition(init_pos_str);

        const vector_str = values_iter.next() orelse unreachable;
        const vector = try parsePosition(vector_str);

        const final_pos = Position{ .x = wrap(init_pos.x, vector.x, dimensions.x), .y = wrap(init_pos.y, vector.y, dimensions.y) };

        if (final_pos.x < midpoint.x and final_pos.y < midpoint.y) {
            quadrants[0] += 1;
        } else if (final_pos.x > midpoint.x and final_pos.y < midpoint.y) {
            quadrants[1] += 1;
        } else if (final_pos.x < midpoint.x and final_pos.y > midpoint.y) {
            quadrants[2] += 1;
        } else if (final_pos.x > midpoint.x and final_pos.y > midpoint.y) {
            quadrants[3] += 1;
        } else {
            // std.debug.print("Robot in the middle!\n", .{});
        }
    }

    for (quadrants) |value| {
        count *= value;
    }

    return count;
}

fn wrap(init_pos: i64, vector: i64, dimension: i64) i64 {
    const raw = init_pos + (vector * TIME_IN_SECONDS);
    const final = @mod(raw, dimension);

    return final;
}

fn parsePosition(buffer: []const u8) !Position {
    var params_iter = std.mem.tokenizeScalar(u8, buffer, '=');
    _ = params_iter.next();

    const position_str = params_iter.next() orelse unreachable;
    var position_iter = std.mem.tokenizeScalar(u8, position_str, ',');

    const x_str = position_iter.next() orelse unreachable;
    const x = try std.fmt.parseInt(i64, x_str, 10);

    const y_str = position_iter.next() orelse unreachable;
    const y = try std.fmt.parseInt(i64, y_str, 10);

    return Position{ .x = x, .y = y };
}

const test_allocator = std.testing.allocator;

test solve {
    const input =
        \\p=0,4 v=3,-3
        \\p=6,3 v=-1,-3
        \\p=10,3 v=-1,2
        \\p=2,0 v=2,-1
        \\p=0,0 v=1,3
        \\p=3,0 v=-2,-2
        \\p=7,6 v=-1,-3
        \\p=3,0 v=-1,-2
        \\p=9,3 v=2,3
        \\p=7,3 v=-1,2
        \\p=2,4 v=2,-3
        \\p=9,5 v=-3,-3
    ;
    const dimensions = Position{ .x = 11, .y = 7 };

    const result = try solve(test_allocator, input, dimensions);

    try std.testing.expectEqual(12, result);
}
