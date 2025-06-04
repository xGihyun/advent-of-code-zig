const std = @import("std");
const input: []const u8 = @embedFile("./input.txt");

const TARGET_WORD = "XMAS";

pub fn main() !void {
    const allocator = std.heap.page_allocator;

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

    for (0..ROWS) |row| {
        for (0..COLUMNS) |col| {
            total_found += getFoundCount(matrix, row, col);
        }
    }

    std.debug.print("{d}", .{total_found});
}

fn getFoundCount(matrix: std.ArrayList([]u8), row: usize, col: usize) u32 {
    var count: u32 = 0;
    const X = [8]i32{ -1, -1, -1, 0, 0, 1, 1, 1 };
    const Y = [8]i32{ -1, 0, 1, 1, -1, -1, 0, 1 };

    if (TARGET_WORD[0] != matrix.items[row][col]) {
        return count;
    }

    for (0..8) |dir| {
        var k: usize = 1;
        var cur_x: i32 = @as(i32, @intCast(row));
        var cur_y: i32 = @as(i32, @intCast(col));

        while (k < TARGET_WORD.len) : (k += 1) {
            cur_x += X[dir];
            cur_y += Y[dir];
            if (cur_x >= matrix.items.len or cur_x < 0 or cur_y >= matrix.items[0].len or cur_y < 0) {
                break;
            }

            const x = @as(usize, @intCast(cur_x));
            const y = @as(usize, @intCast(cur_y));
            if (matrix.items[x][y] != TARGET_WORD[k]) {
                break;
            }
        }

        if (k == TARGET_WORD.len) {
            count += 1;
        }
    }

    return count;
}
