const std = @import("std");

pub fn main() !void {
    const input: []const u8 = @embedFile("./input.txt");
    const allocator = std.heap.page_allocator;

    var timer = try std.time.Timer.start();
    const result = try solve(allocator, input, 75);

    const elapsed_ns = timer.read();
    const elapsed_s = @as(f64, @floatFromInt(elapsed_ns)) / std.time.ns_per_s;

    std.debug.print("\n{d}\n", .{result});
    std.debug.print("Time: {d:.3} seconds", .{elapsed_s});
}

fn solve(allocator: std.mem.Allocator, input: []const u8, blinks: u64) !u64 {
    var stones = std.AutoHashMap(u64, u64).init(allocator);
    defer stones.deinit();

    var numbers_str = std.mem.tokenizeScalar(u8, input, ' ');
    while (numbers_str.next()) |str| {
        const trimmed = std.mem.trim(u8, str, " \n\r");
        if (trimmed.len == 0) continue;

        const num = try std.fmt.parseInt(u64, trimmed, 10);
        const entry = try stones.getOrPutValue(num, 0);
        entry.value_ptr.* += 1;
    }

    for (0..blinks) |_| {
        var next_stones = std.AutoHashMap(u64, u64).init(allocator);
        defer next_stones.deinit();

        var iter = stones.iterator();
        while (iter.next()) |entry| {
            const num = entry.key_ptr.*;
            const count = entry.value_ptr.*;

            if (num == 0) {
                const next_entry = try next_stones.getOrPutValue(1, 0);
                next_entry.value_ptr.* += count;
            } else if (countDigits(num) % 2 == 0) {
                const split = splitNumber(num);
                const left = try next_stones.getOrPutValue(split[0], 0);
                left.value_ptr.* += count;

                const right = try next_stones.getOrPutValue(split[1], 0);
                right.value_ptr.* += count;
            } else {
                const next_entry = try next_stones.getOrPutValue(num * 2024, 0);
                next_entry.value_ptr.* += count;
            }
        }

        stones.deinit();
        stones = try next_stones.clone();
    }

    var sum: u64 = 0;
    var iter = stones.iterator();
    while (iter.next()) |entry| {
        sum += entry.value_ptr.*;
    }

    return sum;
}

fn splitNumber(n: u64) [2]u64 {
    var temp = n;
    var digits: u64 = 0;

    if (temp == 0) {
        digits = 1;
    } else {
        while (temp > 0) {
            temp /= 10;
            digits += 1;
        }
    }

    const mid = digits / 2;
    var divisor: u64 = 1;
    var i: u32 = 0;
    while (i < mid) {
        divisor *= 10;
        i += 1;
    }

    const left = n / divisor;
    const right = n % divisor;

    return [2]u64{ left, right };
}

fn countDigits(n: u64) u64 {
    if (n == 0) {
        return 1;
    }

    return @as(u64, @intCast(std.math.log10(n))) + 1;
}

const test_allocator = std.testing.allocator;

test "solve 5 blinks" {
    const input = "125 17";

    const result = try solve(test_allocator, input, 5);

    try std.testing.expectEqual(13, result);
}

test "solve 25 blinks" {
    const input = "125 17";

    const result = try solve(test_allocator, input, 25);

    try std.testing.expectEqual(55312, result);
}

test countDigits {
    const result = countDigits(12345);

    try std.testing.expectEqual(5, result);
}
