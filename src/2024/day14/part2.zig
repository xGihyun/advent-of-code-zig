const std = @import("std");

const DIMENSIONS = Position{ .x = 101, .y = 103 };

pub fn main() !void {
    const input: []const u8 = @embedFile("./input.txt");
    const allocator = std.heap.page_allocator;

    var timer = try std.time.Timer.start();
    const result = try solve(allocator, input, DIMENSIONS);

    const elapsed_ns = timer.read();
    const elapsed_ms = @as(f64, @floatFromInt(elapsed_ns)) / std.time.ns_per_ms;

    std.debug.print("\n{d}\n", .{result});
    std.debug.print("Time: {d:.3} ms", .{elapsed_ms});
}

const Position = struct {
    x: i64,
    y: i64,
};

fn solve(_: std.mem.Allocator, input: []const u8, dimensions: Position) !i64 {
    var step: i64 = 1;
    while (step <= 10_000) : (step += 1) {
        var matrix: [103][101]u8 = .{
            .{'.'} ** 101,
        } ** 103;

        var lines_iter = std.mem.tokenizeScalar(u8, input, '\n');
        while (lines_iter.next()) |line| {
            var values_iter = std.mem.tokenizeScalar(u8, line, ' ');

            const init_pos_str = values_iter.next() orelse unreachable;
            const init_pos = try parsePosition(init_pos_str);

            const vector_str = values_iter.next() orelse unreachable;
            const vector = try parsePosition(vector_str);

            const final_pos = Position{ .x = wrap(init_pos.x, vector.x, dimensions.x, step), .y = wrap(init_pos.y, vector.y, dimensions.y, step) };
            const ux = @as(usize, @intCast(final_pos.x));
            const uy = @as(usize, @intCast(final_pos.y));
            matrix[uy][ux] = 'X';
        }

        if (hasLine(matrix)) {
            std.debug.print("Try: {d}\n", .{step});
            try visualize(input, dimensions, step);
            std.debug.print("\n\n", .{});
        }
    }

    return 0;
}

fn hasLine(grid: [DIMENSIONS.y][DIMENSIONS.x]u8) bool {
    const threshold: i64 = 10;

    for (0..101) |x| {
        var count: u64 = 0;
        for (0..103) |y| {
            if (count >= threshold) {
                return true;
            }

            if (grid[y][x] != 'X') {
                count = 0;
                continue;
            }

            count += 1;
        }
    }

    for (0..103) |y| {
        var count: u64 = 0;
        for (0..101) |x| {
            if (count >= threshold) {
                return true;
            }

            if (grid[y][x] != 'X') {
                count = 0;
                continue;
            }

            count += 1;
        }
    }

    return false;
}

fn visualize(input: []const u8, dimensions: Position, time: i64) !void {
    var matrix: [103][101]u8 = .{
        .{'.'} ** 101,
    } ** 103;

    var lines_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines_iter.next()) |line| {
        var values_iter = std.mem.tokenizeScalar(u8, line, ' ');

        const init_pos_str = values_iter.next() orelse unreachable;
        const init_pos = try parsePosition(init_pos_str);

        const vector_str = values_iter.next() orelse unreachable;
        const vector = try parsePosition(vector_str);

        const final_pos = Position{ .x = wrap(init_pos.x, vector.x, dimensions.x, time), .y = wrap(init_pos.y, vector.y, dimensions.y, time) };

        const ux = @as(usize, @intCast(final_pos.x));
        const uy = @as(usize, @intCast(final_pos.y));
        matrix[uy][ux] = 'X';
    }

    for (matrix) |row| {
        std.debug.print("{s}\n", .{row});
    }
}

fn wrap(init_pos: i64, vector: i64, dimension: i64, time: i64) i64 {
    const raw = init_pos + (vector * time);
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
