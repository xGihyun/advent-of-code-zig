const std = @import("std");

pub fn main() !void {
    const input: []const u8 = @embedFile("./input.txt");
    const allocator = std.heap.page_allocator;

    const result = try solve(allocator, input);

    std.debug.print("\n{d}", .{result});
}

const Direction = enum { Up, Down, Left, Right };

const Movement = struct {
    direction: Direction,
    position: usize,
    size: usize,
    path: []const u8,
    covered_positions: std.AutoHashMap(usize, void),

    fn init(
        allocator: std.mem.Allocator,
        direction: Direction,
        position: usize,
        size: usize,
        path: []const u8,
    ) Movement {
        return Movement{
            .direction = direction,
            .position = position,
            .size = size,
            .path = path,
            .covered_positions = std.AutoHashMap(usize, void).init(allocator),
        };
    }

    fn deinit(self: *Movement) void {
        self.covered_positions.deinit();
    }

    fn isWithinBounds(self: Movement) bool {
        const cur_row = self.position / self.size;
        const cur_col = self.position % self.size;

        switch (self.direction) {
            Direction.Up => {
                if (self.position < self.size or cur_row == 0) {
                    return false;
                }
            },
            Direction.Down => {
                if (self.position + self.size >= self.path.len or cur_row >= self.size) {
                    return false;
                }
            },
            Direction.Left => {
                if (self.position == 0 or cur_col == 0) {
                    return false;
                }
            },
            Direction.Right => {
                if (self.position + 1 >= self.path.len or cur_col >= self.size) {
                    return false;
                }
            },
        }

        return true;
    }

    fn isObstacle(self: Movement) bool {
        var new_position: usize = self.position;
        switch (self.direction) {
            Direction.Up => {
                new_position -= self.size;
            },
            Direction.Down => {
                new_position += self.size;
            },
            Direction.Left => {
                new_position -= 1;
            },
            Direction.Right => {
                new_position += 1;
            },
        }

        const next_char = self.path[new_position];
        return next_char == '#';
    }

    fn moveToDirection(self: *Movement, direction: ?Direction) !void {
        self.direction = direction orelse self.direction;

        switch (self.direction) {
            Direction.Up => {
                self.position -= self.size;
            },
            Direction.Down => {
                self.position += self.size;
            },
            Direction.Left => {
                self.position -= 1;
            },
            Direction.Right => {
                self.position += 1;
            },
        }

        try self.covered_positions.put(self.position, {});
    }
};

fn solve(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        try buffer.appendSlice(line);
    }

    const SIZE: usize = std.math.sqrt(buffer.items.len);
    const position = std.mem.indexOfScalar(u8, buffer.items, '^').?;

    var movement = Movement.init(allocator, Direction.Up, position, SIZE, buffer.items);
    defer movement.deinit();

    try movement.covered_positions.put(position, {});

    while (movement.isWithinBounds()) {
        if (!movement.isObstacle()) {
            try movement.moveToDirection(null);
        } else {
            const new_direction = switch (movement.direction) {
                Direction.Up => Direction.Right,
                Direction.Down => Direction.Left,
                Direction.Left => Direction.Up,
                Direction.Right => Direction.Down,
            };

            try movement.moveToDirection(new_direction);
        }
    }

    return movement.covered_positions.count();
}

test "day 6 part 1" {
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

    const allocator = std.testing.allocator;
    const result = try solve(allocator, input);

    try std.testing.expectEqual(41, result);
}
