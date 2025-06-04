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

const Direction = enum { Up, Left, Down, Right };
const MovementState = struct { position: usize, direction: Direction };

// Code is not efficient.
// Time: 7~ seconds.
fn solve(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        try buffer.appendSlice(line);
    }

    const SIZE: usize = std.math.sqrt(buffer.items.len);
    const position = std.mem.indexOfScalar(u8, buffer.items, '^').?;

    const init_state = MovementState{
        .direction = Direction.Up,
        .position = position,
    };
    var guard_path_state = init_state;

    var loop_count: u32 = 0;

    var obstacle_positions = std.AutoHashMap(usize, void).init(allocator);
    defer obstacle_positions.deinit();

    var visited = std.AutoHashMap(MovementState, void).init(allocator);
    defer visited.deinit();

    while (getNextPosition(buffer.items, guard_path_state, SIZE)) |cur| {
        // Skip if:
        // - Obstacle has been previously placed in this position or;
        // - Current position is the guard's start position
        if (obstacle_positions.contains(cur.position) or cur.position == init_state.position) {
            guard_path_state = cur;
            continue;
        }

        buffer.items[cur.position] = '#';

        var temp_state = guard_path_state;
        while (getNextPosition(buffer.items, temp_state, SIZE)) |temp_cur| {
            if (visited.contains(temp_cur)) {
                loop_count += 1;
                break;
            }

            try visited.put(temp_cur, {});
            temp_state = temp_cur;
        }

        buffer.items[cur.position] = '.';
        guard_path_state = cur;

        try obstacle_positions.put(cur.position, {});
        visited.clearAndFree();
    }

    return loop_count;
}

fn isInBounds(state: MovementState, size: usize) bool {
    const row = state.position / size;
    const col = state.position % size;

    switch (state.direction) {
        Direction.Up => {
            return row != 0;
        },
        Direction.Down => {
            return row != size - 1;
        },
        Direction.Left => {
            return col != 0;
        },
        Direction.Right => {
            return col != size - 1;
        },
    }
}

fn getNextPosition(buffer: []const u8, state: MovementState, size: usize) ?MovementState {
    if (!isInBounds(state, size)) {
        return null;
    }

    var new_state = state;
    switch (new_state.direction) {
        Direction.Up => {
            new_state.position -= size;
        },
        Direction.Down => {
            new_state.position += size;
        },
        Direction.Left => {
            new_state.position -= 1;
        },
        Direction.Right => {
            new_state.position += 1;
        },
    }

    while (buffer[new_state.position] == '#') {
        new_state = MovementState{ .position = state.position, .direction = new_state.direction };
        new_state.direction = switch (new_state.direction) {
            Direction.Up => Direction.Right,
            Direction.Right => Direction.Down,
            Direction.Down => Direction.Left,
            Direction.Left => Direction.Up,
        };

        switch (new_state.direction) {
            Direction.Up => {
                new_state.position -= size;
            },
            Direction.Down => {
                new_state.position += size;
            },
            Direction.Left => {
                new_state.position -= 1;
            },
            Direction.Right => {
                new_state.position += 1;
            },
        }
    }

    return new_state;
}

const test_allocator = std.testing.allocator;

test "day 6 part 2" {
    const input =
        \\....#.....
        \\.........#
        \\..........
        \\..#.......
        \\.......#..
        \\..........
        \\.#..^.....
        \\........#.
        \\#.........
        \\......#...
    ;

    const result = try solve(test_allocator, input);

    try std.testing.expectEqual(6, result);
}

test "day 6 part 2 edge case" {
    const input =
        \\....
        \\..#.
        \\#^..
        \\.#..
    ;

    const result = try solve(test_allocator, input);

    try std.testing.expectEqual(1, result);
}

test "day 6 part 2 edge case 2" {
    const input =
        \\....
        \\#...
        \\.^#.
        \\.#..
    ;

    // const allocator = std.testing.allocator;
    const result = try solve(test_allocator, input);

    try std.testing.expectEqual(0, result);
}
