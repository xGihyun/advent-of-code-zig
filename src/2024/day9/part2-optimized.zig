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

const Block = struct { id: usize, size: usize, start_pos: usize };

// NOTE: Optimized solution.
fn solve(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var blocks = std.ArrayList(i16).init(allocator);
    defer blocks.deinit();

    var files: [10000]?Block = .{null} ** 10000;
    var spaces: [10000]?Block = .{null} ** 10000;

    var max_id: usize = 0;
    var start_pos: usize = 0;

    for (input, 0..) |c, i| {
        if (!std.ascii.isDigit(c)) {
            break;
        }

        const num: usize = c - '0';
        const id: usize = i / 2;

        if (i % 2 == 0) {
            for (0..num) |_| {
                try blocks.append(@as(i16, @intCast(id)));
            }

            if (files[id] == null) {
                files[id] = Block{ .id = id, .size = num, .start_pos = start_pos };
            }

            max_id = @max(max_id, id);
            start_pos += num;
            continue;
        }

        for (0..num) |_| {
            try blocks.append(-1);
        }

        if (spaces[id] == null) {
            spaces[id] = Block{ .id = id, .size = num, .start_pos = start_pos };
        }

        start_pos += num;
    }

    while (max_id > 0) {
        const file = files[max_id] orelse {
            max_id -= 1;
            continue;
        };

        const space = getSpace(spaces, file.size, file.start_pos) orelse {
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

        var space_ptr = &(spaces[space.id] orelse continue);
        if (space_ptr.size < file.size) {
            continue;
        }

        space_ptr.size -= file.size;
        space_ptr.start_pos += file.size;

        if (space_ptr.size == 0) {
            spaces[space.id] = null;
        }
    }

    var sum: u64 = 0;

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

fn getSpace(spaces: [10000]?Block, size: usize, end: usize) ?Block {
    for (spaces) |value| {
        const space = value orelse continue;
        if (space.start_pos > end) {
            return null;
        }

        if (space.size >= size) {
            return space;
        }
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
