const std = @import("std");

// NOTE: My initial brute-force solution (extremely inefficient)
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
    const OPERATORS = "+*|";
    var sum: u64 = 0;

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var iter = std.mem.tokenizeScalar(u8, line, ':');
        const first = iter.next().?;
        const test_value = try std.fmt.parseInt(u64, first, 10);

        const last = iter.next().?;
        var remaining_iter = std.mem.tokenizeScalar(u8, last, ' ');

        var numbers_str = std.ArrayList([]const u8).init(allocator);
        defer numbers_str.deinit();

        while (remaining_iter.next()) |str| {
            try numbers_str.append(str);
        }

        const permutations = try generateOperatorPermutations(allocator, OPERATORS, numbers_str.items.len - 1);
        defer {
            for (permutations) |perm| {
                allocator.free(perm);
            }
            allocator.free(permutations);
        }

        for (permutations) |perm| {
            var result = try std.fmt.parseInt(u64, numbers_str.items[0], 10);

            for (numbers_str.items[1..], 0..) |str, i| {
                const op = perm[i];
                switch (op) {
                    '+' => {
                        const num = try std.fmt.parseInt(u64, str, 10);

                        // std.debug.print("{d} + {d} = {d}\n", .{ result, num, result + num });

                        result += num;
                    },
                    '*' => {
                        const num = try std.fmt.parseInt(u64, str, 10);

                        // std.debug.print("{d} * {d} = {d}\n", .{ result, num, result * num });

                        result *= num;
                    },
                    '|' => {
                        const result_str = try std.fmt.allocPrint(allocator, "{d}{s}", .{ result, str });
                        defer allocator.free(result_str);

                        // std.debug.print("{d} || {s} = {s}\n", .{ result, str, result_str });

                        const num = try std.fmt.parseInt(u64, result_str, 10);
                        result = num;
                    },
                    else => std.debug.print("That's illegal!\n", .{}),
                }

                if (result > test_value) {
                    break;
                }
            }

            if (result == test_value) {
                sum += result;
                std.debug.print("+ {d}\n", .{result});
                std.debug.print("Sum: {d}\n", .{sum});
                break;
            }

            // std.debug.print("\n", .{});
        }
    }

    return sum;
}

fn generateOperatorPermutations(allocator: std.mem.Allocator, operators: []const u8, n: usize) ![][]const u8 {
    if (n == 0) {
        const empty_slice = &[_][]const u8{""};
        var result = try allocator.alloc([]const u8, 1);
        result[0] = empty_slice[0];
        return result;
    }

    var result = std.ArrayList([]const u8).init(allocator);
    defer result.deinit();

    const permutations = try generateOperatorPermutations(allocator, operators, n - 1);
    defer {
        for (permutations) |perm| {
            allocator.free(perm);
        }
        allocator.free(permutations);
    }

    for (permutations) |combo| {
        for (operators) |op| {
            const new_combo = try appendCharToString(allocator, combo, op);
            try result.append(new_combo);
        }
    }

    return result.toOwnedSlice();
}

fn appendCharToString(allocator: std.mem.Allocator, original: []const u8, c: u8) ![]u8 {
    var buffer = try allocator.alloc(u8, original.len + 1);
    std.mem.copyForwards(u8, buffer[0..original.len], original);
    buffer[original.len] = c;

    return buffer;
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
