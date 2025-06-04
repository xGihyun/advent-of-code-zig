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

// NOTE: Not efficient, but it works.
fn solve(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var blocks = std.ArrayList(i16).init(allocator);
    defer blocks.deinit();

    var max_id: usize = 0;

    for (input, 0..) |c, i| {
        if (!std.ascii.isDigit(c)) {
            break;
        }

        const num: u8 = c - '0';
        const id: usize = i / 2;

        if (i % 2 == 0) {
            for (0..num) |_| {
                try blocks.append(@as(i16, @intCast(id)));
            }

            max_id = @max(max_id, id);
            continue;
        }

        for (0..num) |_| {
            try blocks.append(-1);
        }
    }

    while (max_id > 0) {
        const file = getFile(blocks.items, max_id) orelse {
            max_id -= 1;
            continue;
        };

        const space = getBiggestFreeSpaceLeft(blocks.items, file.size, file.start_pos) orelse {
            max_id -= 1;
            continue;
        };

        var r: usize = file.start_pos + file.size - 1;
        for (space.start_pos..space.start_pos + file.size) |i| {
            blocks.items[i] = @as(i16, @intCast(max_id));
            blocks.items[r] = -1;

            r -= 1;
        }

        max_id -= 1;
    }

    var sum: u64 = 0;

    // Since all "dots" (-1) are already on the right side,
    // the last valid block would be on blocks.items[r]
    for (blocks.items, 0..) |value, i| {
        if (value < 0) {
            continue;
        }

        const product: usize = @as(usize, @intCast(value)) * i;
        sum += @as(u64, @intCast(product));
    }

    // std.debug.print("\n{any}\n", .{blocks.items});

    return sum;
}

const Space = struct { size: usize, start_pos: usize };

fn getBiggestFreeSpaceLeft(blocks: []i16, size: usize, end: usize) ?Space {
    var i: usize = 0;

    while (i < end) {
        if (blocks[i] != -1) {
            i += 1;
            continue;
        }

        var j = i;
        var count: usize = 0;
        while (j < blocks.len and blocks[j] == -1) : (j += 1) {
            count += 1;
        }

        if (count >= size) {
            return Space{ .size = count, .start_pos = i };
        }

        i = j;
    }

    return null;
}

fn getFile(blocks: []i16, id: usize) ?Space {
    var start_pos: ?usize = null;
    var size: usize = 0;

    for (blocks, 0..) |value, i| {
        if (value < 0) {
            continue;
        }

        const cur_id = @as(usize, @intCast(value));
        if (cur_id == id) {
            if (start_pos == null) {
                start_pos = i;
            }
            size += 1;
        } else if (start_pos != null) {
            break;
        }
    }

    if (start_pos != null and size > 0) {
        return Space{ .size = size, .start_pos = start_pos.? };
    }

    return null;
}

const test_allocator = std.testing.allocator;

test solve {
    const input = "2333133121414131402";
    const result = try solve(test_allocator, input);

    try std.testing.expectEqual(2858, result);
}

test "test 2" {
    const input = "1313165";
    const result = try solve(test_allocator, input);

    try std.testing.expectEqual(169, result);
}

test "test 3" {
    const input = "9953877292941";
    const result = try solve(test_allocator, input);

    try std.testing.expectEqual(5768, result);
}

test "test 4" {
    const input = "2333133121414131499";
    const result = try solve(test_allocator, input);

    try std.testing.expectEqual(6204, result);
}

test "test 5" {
    const input = "29702";
    const result = try solve(test_allocator, input);

    try std.testing.expectEqual(59, result);
}
