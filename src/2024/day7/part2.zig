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
    var sum: u64 = 0;

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var iter = std.mem.tokenizeScalar(u8, line, ':');
        const first = iter.next().?;
        const target = try std.fmt.parseInt(u64, first, 10);

        const last = iter.next().?;
        var remaining_iter = std.mem.tokenizeScalar(u8, last, ' ');

        var numbers = std.ArrayList(u64).init(allocator);
        defer numbers.deinit();

        while (remaining_iter.next()) |str| {
            const num = try std.fmt.parseInt(u64, str, 10);
            try numbers.append(num);
        }

        var results = std.ArrayList(u64).init(allocator);
        defer results.deinit();

        try results.append(numbers.items[0]);

        for (numbers.items[1..]) |num| {
            var temp_results = std.ArrayList(u64).init(allocator);
            defer temp_results.deinit();

            for (results.items) |result| {
                // WARN: The reason for high execution times is this `allocPrint` part:
                // const concat_str = try std.fmt.allocPrint(allocator, "{d}{d}", .{ result, num });
                // defer allocator.free(concat_str);

                const concat_num = concatInt(result, num);

                if (result + num <= target) {
                    try temp_results.append(result + num);
                }

                if (result * num <= target) {
                    try temp_results.append(result * num);
                }

                if (concat_num <= target) {
                    try temp_results.append(concat_num);
                }
            }

            results.deinit();
            results = try temp_results.clone();
        }

        for (results.items) |result| {
            if (result == target) {
                sum += target;
                break;
            }
        }
    }

    return sum;
}

// NOTE: Added after solving, test if it improves performance.
// After testing: it does.
fn concatInt(a: u64, b: u64) u64 {
    var multiplier: u64 = 1;
    var temp = b;
    while (temp != 0) : (temp /= 10) {
        multiplier *= 10;
    }
    return a * multiplier + b;
}

const test_allocator = std.testing.allocator;

test "test input" {
    const input =
        \\190: 10 19
        \\3267: 81 40 27
        \\83: 17 5
        \\156: 15 6
        \\7290: 6 8 6 15
        \\161011: 16 10 13
        \\192: 17 8 14
        \\21037: 9 7 18 13
        \\292: 11 6 16 20
    ;
    const result = try solve(test_allocator, input);

    try std.testing.expectEqual(11387, result);
}
