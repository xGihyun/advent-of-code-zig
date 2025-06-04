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
    x: i32,
    y: i32,
};

const SIZE: usize = 50;

fn solve(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var map = std.AutoHashMap(u8, std.ArrayList(Position)).init(allocator);
    defer {
        var iter = map.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.deinit();
        }
        map.deinit();
    }

    var row: usize = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| : (row += 1) {
        for (line, 0..) |c, col| {
            if (!std.ascii.isAlphanumeric(c)) {
                continue;
            }

            var positions = std.ArrayList(Position).init(allocator);
            defer positions.deinit();

            const entry = try map.getOrPutValue(c, positions);
            const position = Position{ .y = @as(i32, @intCast(row)), .x = @as(i32, @intCast(col)) };
            try entry.value_ptr.append(position);
        }
    }

    var antinodes_positions: [SIZE][SIZE]bool = undefined;
    var antinodes_count: u32 = 0;

    var map_iter = map.iterator();
    while (map_iter.next()) |entry| {
        // std.debug.print("{c}\n", .{entry.key_ptr.*});
        for (entry.value_ptr.items[0 .. entry.value_ptr.items.len - 1], 0..) |cur_pos, i| {
            for (i + 1..entry.value_ptr.items.len) |j| {
                const pair_pos = entry.value_ptr.items[j];
                // std.debug.print("Pair: {any} {any}\n", .{ cur_pos, pair_pos });

                const cur_vec = Position{
                    .x = pair_pos.x - cur_pos.x,
                    .y = pair_pos.y - cur_pos.y,
                };

                const cur_antinode_pos = Position{
                    .x = cur_pos.x - cur_vec.x,
                    .y = cur_pos.y - cur_vec.y,
                };
                const pair_antinode_pos = Position{
                    .x = pair_pos.x - cur_vec.x * -1,
                    .y = pair_pos.y - cur_vec.y * -1,
                };

                if (cur_antinode_pos.x < SIZE and cur_antinode_pos.x >= 0 and
                    cur_antinode_pos.y < SIZE and cur_antinode_pos.y >= 0)
                {
                    const x = @as(usize, @intCast(cur_antinode_pos.x));
                    const y = @as(usize, @intCast(cur_antinode_pos.y));
                    if (!antinodes_positions[x][y]) {
                        antinodes_positions[x][y] = true;
                        antinodes_count += 1;
                    }
                }

                if (pair_antinode_pos.x < SIZE and pair_antinode_pos.x >= 0 and
                    pair_antinode_pos.y < SIZE and pair_antinode_pos.y >= 0)
                {
                    const x = @as(usize, @intCast(pair_antinode_pos.x));
                    const y = @as(usize, @intCast(pair_antinode_pos.y));
                    if (!antinodes_positions[x][y]) {
                        antinodes_positions[x][y] = true;
                        antinodes_count += 1;
                    }
                }
            }
        }
    }

    return antinodes_count;
}

const test_allocator = std.testing.allocator;

test "day 8 part 1" {
    const input =
        \\............
        \\........0...
        \\.....0......
        \\.......0....
        \\....0.......
        \\......A.....
        \\............
        \\............
        \\........A...
        \\.........A..
        \\............
        \\............
    ;
    const result = try solve(test_allocator, input);

    try std.testing.expectEqual(14, result);
}
