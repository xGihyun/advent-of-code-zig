const std = @import("std");

// NOTE: Tried to optimize my code further with the help of AI.
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
        const target_str = iter.next() orelse continue;
        const numbers_str = iter.next() orelse continue;

        const target = try std.fmt.parseInt(u64, target_str, 10);

        var numbers = std.ArrayList(u64).init(allocator);
        defer numbers.deinit();

        var numbers_iter = std.mem.tokenizeScalar(u8, numbers_str, ' ');
        while (numbers_iter.next()) |str| {
            const num = try std.fmt.parseInt(u64, str, 10);
            try numbers.append(num);
        }

        if (isValid(numbers.items, target)) {
            sum += target;
        }
    }

    return sum;
}

const State = struct {
    index: usize,
    value: u64,
};

fn isValid(numbers: []const u64, target: u64) bool {
    const MAX_STACK_SIZE = 1024;
    var stack: [MAX_STACK_SIZE]State = undefined;
    var stack_len: usize = 0;

    if (numbers.len == 0) {
        return false;
    }

    stack[stack_len] = State{ .index = 1, .value = numbers[0] };
    stack_len += 1;

    while (stack_len > 0) {
        stack_len -= 1;
        const state = stack[stack_len];

        if (state.index == numbers.len) {
            if (state.value == target) {
                return true;
            }
            continue;
        }

        const next = numbers[state.index];

        const sum = state.value + next;
        if (sum <= target and stack_len < MAX_STACK_SIZE) {
            stack[stack_len] = State{ .index = state.index + 1, .value = sum };
            stack_len += 1;
        }

        const product = state.value * next;
        if (product <= target and stack_len < MAX_STACK_SIZE) {
            stack[stack_len] = State{ .index = state.index + 1, .value = product };
            stack_len += 1;
        }

        const concat = concatInt(state.value, next);
        if (concat <= target and stack_len < MAX_STACK_SIZE) {
            stack[stack_len] = State{ .index = state.index + 1, .value = concat };
            stack_len += 1;
        }
    }

    return false;
}

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
