const std = @import("std");
const input: []const u8 = @embedFile("./input.txt");

const TARGET_WORD = "MAS";
const allocator = std.heap.page_allocator;

// NOTE: Horrible solution

pub fn main() !void {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var matrix = std.ArrayList([]u8).init(allocator);
    defer matrix.deinit();

    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var chars = std.ArrayList(u8).init(allocator);

        for (line) |c| {
            try chars.append(c);
        }

        try matrix.append(chars.items);
    }

    const ROWS = matrix.items.len;
    const COLUMNS = matrix.items[0].len;

    var total_found: u32 = 0;

    var map = std.AutoHashMap(Direction, void).init(allocator);
    defer map.deinit();

    for (0..ROWS) |row| {
        for (0..COLUMNS) |col| {
            total_found += try getFoundCount(matrix, &map, row, col);
        }
    }

    std.debug.print("{d}", .{total_found});
}

fn getFoundCount(matrix: std.ArrayList([]u8), map: *std.AutoHashMap(Direction, void), row: usize, col: usize) !u32 {
    var count: u32 = 0;
    const X = [4]i32{ -1, -1, 1, 1 };
    const Y = [4]i32{ -1, 1, -1, 1 };

    if (TARGET_WORD[0] != matrix.items[row][col]) {
        return count;
    }

    for (0..4) |dir| {
        var k: usize = 1;
        var cur_x: i32 = @as(i32, @intCast(col));
        var cur_y: i32 = @as(i32, @intCast(row));
        const dir_x = X[dir];
        const dir_y = Y[dir];

        while (k < TARGET_WORD.len) : (k += 1) {
            cur_x += X[dir];
            cur_y += Y[dir];
            if (cur_y >= matrix.items.len or cur_y < 0 or cur_x >= matrix.items[0].len or cur_x < 0) {
                break;
            }

            const x = @as(usize, @intCast(cur_x));
            const y = @as(usize, @intCast(cur_y));
            if (matrix.items[y][x] != TARGET_WORD[k]) {
                break;
            }
        }

        if (k != TARGET_WORD.len) {
            continue;
        }

        const start_at = Point{
            .x = @as(i32, @intCast(col)),
            .y = @as(i32, @intCast(row)),
        };
        const end_at = Point{
            .x = cur_x,
            .y = cur_y,
        };
        const word_dir = Direction{
            .start_at = start_at,
            .end_at = end_at,
        };

        try map.put(word_dir, {});

        const len = @as(i32, @intCast(TARGET_WORD.len));

        if ((dir_x == 1 and dir_y == -1) or (dir_x == -1 and dir_y == -1)) {
            const pair_dir1 = Direction{
                .start_at = Point{
                    .x = word_dir.start_at.x,
                    .y = word_dir.start_at.y - len + 1,
                },
                .end_at = Point{
                    .x = word_dir.end_at.x,
                    .y = word_dir.end_at.y + len - 1,
                },
            };

            const pair_dir2 = Direction{
                .start_at = pair_dir1.end_at,
                .end_at = pair_dir1.start_at,
            };

            if (map.contains(pair_dir1) or map.contains(pair_dir2)) {
                count += 1;
            }
        }

        if (dir_x == -1 and dir_y == 1) {
            const pair_dir1 = Direction{
                .start_at = Point{
                    .x = word_dir.start_at.x - len + 1,
                    .y = word_dir.start_at.y,
                },
                .end_at = Point{
                    .x = word_dir.end_at.x + len - 1,
                    .y = word_dir.end_at.y,
                },
            };

            const pair_dir2 = Direction{
                .start_at = pair_dir1.end_at,
                .end_at = pair_dir1.start_at,
            };

            if (map.contains(pair_dir1) or map.contains(pair_dir2)) {
                count += 1;
            }
        }

        if (dir_x == 1 and dir_y == 1) {
            const pair_dir1 = Direction{
                .start_at = Point{
                    .x = word_dir.start_at.x + len - 1,
                    .y = word_dir.start_at.y,
                },
                .end_at = Point{
                    .x = word_dir.end_at.x - len + 1,
                    .y = word_dir.end_at.y,
                },
            };

            const pair_dir2 = Direction{
                .start_at = pair_dir1.end_at,
                .end_at = pair_dir1.start_at,
            };

            if (map.contains(pair_dir1) or map.contains(pair_dir2)) {
                count += 1;
            }
        }
    }

    return count;
}

const Point = struct {
    x: i32,
    y: i32,
};

const Direction = struct {
    start_at: Point,
    end_at: Point,
};
