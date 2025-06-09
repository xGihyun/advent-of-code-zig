const std = @import("std");

pub fn main() !void {
    const input: []const u8 = @embedFile("./input.txt");
    const allocator = std.heap.page_allocator;

    var timer = try std.time.Timer.start();
    const result = try solve(allocator, input);

    const elapsed_ns = timer.read();
    const elapsed_ms = @as(f64, @floatFromInt(elapsed_ns)) / std.time.ns_per_ms;

    std.debug.print("\n{d}\n", .{result});
    std.debug.print("Time: {d:.3} ms", .{elapsed_ms});
}

const Position = struct { x: i64, y: i64 };

fn solve(_: std.mem.Allocator, input: []const u8) !i64 {
    var sum: i64 = 0;

    var machines_iter = std.mem.tokenizeSequence(u8, input, "\n\n");
    while (machines_iter.next()) |str| {
        var movements: [2]Position = undefined;
        var target: Position = undefined;

        var i: usize = 0;
        var lines = std.mem.tokenizeScalar(u8, str, '\n');
        while (lines.next()) |line| {
            var iter = std.mem.tokenizeScalar(u8, line, ':');
            _ = iter.next();

            const eql = std.mem.indexOfScalar(u8, line, '=');
            if (eql != null) {
                const values = try getValues(iter.rest(), '=');
                target = values;
                break;
            }

            if (i > 1) {
                break;
            }

            const values = try getValues(iter.rest(), '+');
            movements[i] = values;

            i += 1;
        }

        const result = try getMinimumTokens(movements, target);

        if (result > 0) {
            sum += result;
            // std.debug.print("{d}\n", .{sum});
        }
    }

    return sum;
}

fn getMinimumTokens(movements: [2]Position, target: Position) !i64 {
    const movement_a = movements[0];
    const movement_b = movements[1];

    const det = movement_a.x * movement_b.y - movement_a.y * movement_b.x;

    if (det == 0) {
        std.debug.print("Determinant is 0\n", .{});
        return 0;
    }

    const a_num = target.x * movement_b.y - target.y * movement_b.x;
    const b_num = target.y * movement_a.x - target.x * movement_a.y;

    // We only divide `a` and `b` by the determinant if there's no remainder.
    // Otherwise, it would return an error.
    if (@mod(a_num, det) == 0 and @mod(b_num, det) == 0) {
        const a = @divExact(a_num, det);
        const b = @divExact(b_num, det);

        if (a >= 0 and b >= 0) {
            // For debugging only
            if (a > 100 or b > 100) {
                std.debug.print("Greater than 100 presses!\n", .{});
            }

            return 3 * a + b;
        }
    }

    return 0;
}

fn getValues(str: []const u8, delimiter: u8) !Position {
    var iter = std.mem.tokenizeSequence(u8, str, ", ");
    const first_str = iter.next() orelse unreachable;
    const second_str = iter.next() orelse unreachable;

    const numbers = [2]i64{ try getNumber(first_str, delimiter), try getNumber(second_str, delimiter) };

    return Position{
        .x = numbers[0],
        .y = numbers[1],
    };
}

fn getNumber(str: []const u8, delimiter: u8) !i64 {
    var value_iter = std.mem.tokenizeScalar(u8, str, delimiter);
    _ = value_iter.next();

    const num_str = value_iter.next() orelse unreachable;
    const num = try std.fmt.parseInt(i64, num_str, 10);

    return num;
}

const test_allocator = std.testing.allocator;

test solve {
    const input =
        \\Button A: X+94, Y+34
        \\Button B: X+22, Y+67
        \\Prize: X=8400, Y=5400
        \\
        \\Button A: X+26, Y+66
        \\Button B: X+67, Y+21
        \\Prize: X=12748, Y=12176
        \\
        \\Button A: X+17, Y+86
        \\Button B: X+84, Y+37
        \\Prize: X=7870, Y=6450
        \\
        \\Button A: X+69, Y+23
        \\Button B: X+27, Y+71
        \\Prize: X=18641, Y=10279
    ;

    const result = try solve(test_allocator, input);

    try std.testing.expectEqual(480, result);
}
