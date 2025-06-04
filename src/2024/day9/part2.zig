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

    // TODO: Finish this, brain not working right now
    for (0..blocks.items.len) |_| {
        var r: usize = blocks.items.len - 1;

        while (r > 0) {
            std.debug.print("{d}\n", .{r});

            const space = getBiggestFreeSpace(blocks.items, 0);
            const file_size = getFileSize(blocks.items, r);

            if (space.size < file_size) {
                r -= file_size;

                while (blocks.items[r] == -1) {
                    r -= 1;
                }
                continue;
            }

            for (space.start_pos..space.start_pos + space.size) |i| {
                blocks.items[i] ^= blocks.items[r];
                blocks.items[r] ^= blocks.items[i];
                blocks.items[i] ^= blocks.items[r];

                if (r == 0) {
                    break;
                }

                r -= 1;
            }

            while (blocks.items[r] == -1) {
                if (r == 0) {
                    break;
                }

                r -= 1;
            }
        }
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

    std.debug.print("{any}\n", .{blocks.items});

    return sum;
}

const Space = struct { size: usize, start_pos: usize };

fn getBiggestFreeSpace(blocks: []i16, position: usize) Space {
    var space: Space = Space{ .size = 0, .start_pos = position };

    for (blocks[position..], position..) |_, i| {
        if (blocks[i] >= 0) {
            continue;
        }

        var j = i;
        var count: usize = 0;
        while (blocks[j] == -1 and j < blocks.len - 1) : (j += 1) {
            count += 1;
        }

        if (count > space.size) {
            space.start_pos = i;
            space.size = count;
        }
    }

    return space;
}

fn getFileSize(blocks: []i16, position: usize) usize {
    const last_block = blocks[position];
    var cur = position;
    var count: usize = 0;

    while (blocks[cur] >= 0 and cur > 0 and blocks[cur] == last_block) : (cur -= 1) {
        count += 1;
    }

    return count;
}

const test_allocator = std.testing.allocator;

test solve {
    const input = "2333133121414131402";
    const result = try solve(test_allocator, input);

    try std.testing.expectEqual(2858, result);
}
