const std = @import("std");

pub fn main() !void {
    const input: []const u8 = @embedFile("./input.txt");
    const allocator = std.heap.page_allocator;

    var timer = try std.time.Timer.start();
    const result = try solve(allocator, input);
    defer allocator.free(result);

    const elapsed_ns = timer.read();
    const elapsed_ms = @as(f64, @floatFromInt(elapsed_ns)) / std.time.ns_per_ms;

    std.debug.print("\n{s}\n", .{result});
    std.debug.print("Time: {d:.3} ms", .{elapsed_ms});
}

const Position = struct { x: usize, y: usize };

const DIMENSIONS = Position{ .x = 71, .y = 71 };
const BYTES_COUNT = 1024;

fn solve(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    var corrupted = std.ArrayList(Position).init(allocator);
    defer corrupted.deinit();

    var lines_iter = std.mem.splitScalar(u8, input, '\n');
    while (lines_iter.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var coord_str = std.mem.splitScalar(u8, line, ',');
        const x = try std.fmt.parseUnsigned(usize, coord_str.next().?, 10);
        const y = try std.fmt.parseUnsigned(usize, coord_str.next().?, 10);
        const position = Position{ .x = x, .y = y };

        try corrupted.append(position);
    }

    var byte_idx: usize = BYTES_COUNT + 1;
    for (corrupted.items[byte_idx..]) |_| {
        const pos = try bfs(allocator, corrupted.items[0..byte_idx]);
        if (pos) |p| {
            const coord = try std.fmt.allocPrint(allocator, "{d},{d}", .{p.x, p.y});
            return coord;
        }

        byte_idx += 1;
    }

    return "";
}

const DELTA_X = [_]i64{ 1, -1, 0, 0 };
const DELTA_Y = [_]i64{ 0, 0, 1, -1 };

fn bfs(allocator: std.mem.Allocator, corrupted: []const Position) !?Position {
    var queue = std.fifo.LinearFifo(Position, .Dynamic).init(allocator);
    defer queue.deinit();

    var visited: [DIMENSIONS.x][DIMENSIONS.y]bool = undefined;

    var prev = std.AutoHashMap(Position, Position).init(allocator);
    defer prev.deinit();

    const start_pos = Position{ .x = 0, .y = 0 };
    try queue.writeItem(start_pos);

    while (queue.count > 0) {
        const vertex = queue.readItem() orelse break;
        if (visited[vertex.x][vertex.y]) {
            continue;
        }

        visited[vertex.x][vertex.y] = true;

        if (vertex.x == DIMENSIONS.x - 1 and vertex.y == DIMENSIONS.y - 1) {
            break;
        }

        for (0..4) |i| {
            const dx = DELTA_X[i];
            const dy = DELTA_Y[i];
            const next_x = @as(i64, @intCast(vertex.x)) + dx;
            const next_y = @as(i64, @intCast(vertex.y)) + dy;

            if (next_x < 0 or next_y < 0) {
                continue;
            }

            const pos = Position{ .x = @as(usize, @intCast(next_x)), .y = @as(usize, @intCast(next_y)) };
            if (pos.x >= DIMENSIONS.x or pos.y >= DIMENSIONS.y) {
                continue;
            }

            const is_corrupted = contains(Position, corrupted, pos);
            if (is_corrupted) {
                continue;
            }

            if (visited[pos.x][pos.y]) {
                continue;
            }

            try queue.writeItem(pos);
            try prev.put(pos, vertex);
        }
    }

    const end_pos = Position{
        .x = DIMENSIONS.x - 1,
        .y = DIMENSIONS.y - 1,
    };

    const prev_pos = prev.get(end_pos);
    if (prev_pos == null) {
        return corrupted[corrupted.len - 1];
    }

    return null;
}

fn contains(comptime T: type, slice: []const T, value: T) bool {
    for (slice) |elem| {
        if (std.meta.eql(value, elem)) {
            return true;
        }
    }
    return false;
}

const test_allocator = std.testing.allocator;

test solve {
    const input =
        \\5,4
        \\4,2
        \\4,5
        \\3,0
        \\2,1
        \\6,3
        \\2,4
        \\1,5
        \\0,6
        \\3,3
        \\2,6
        \\5,1
        \\1,2
        \\5,5
        \\2,5
        \\6,5
        \\1,4
        \\0,4
        \\6,4
        \\1,1
        \\6,1
        \\1,0
        \\0,5
        \\1,6
        \\2,0
    ;
    const result = try solve(test_allocator, input);
    defer test_allocator.free(result);

    try std.testing.expectEqualStrings("6,1", result);
}
