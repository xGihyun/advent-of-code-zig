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

fn solve(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var blocks = std.ArrayList(i16).init(allocator);
    defer blocks.deinit();

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
            continue;
        }

        for (0..num) |_| {
            try blocks.append(-1);
        }
    }

    var l: usize = 0;
    var r: usize = blocks.items.len - 1;

    while (l < r) {
        if (blocks.items[l] == -1) {
            blocks.items[l] ^= blocks.items[r];
            blocks.items[r] ^= blocks.items[l];
            blocks.items[l] ^= blocks.items[r];
        }

        while (blocks.items[r] == -1) {
            r -= 1;
        }

        l += 1;
    }

    var sum: u64 = 0;

    // Since all "dots" (-1) are already on the right side, 
    // the last valid block would be on blocks.items[r]
    for (blocks.items[0 .. r + 1], 0..) |value, i| {
        const product: usize = @as(usize, @intCast(value)) * i;
        sum += @as(u64, @intCast(product));
    }

    return sum;
}

const test_allocator = std.testing.allocator;

test solve {
    const input = "2333133121414131402";
    const result = try solve(test_allocator, input);

    try std.testing.expectEqual(1928, result);
}

test "solve 2" {
    const input = "12345";
    const result = try solve(test_allocator, input);

    try std.testing.expectEqual(60, result);
}
