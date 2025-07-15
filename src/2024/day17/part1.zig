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

const Register = struct {
    a: i64,
    b: i64,
    c: i64,
};

fn solve(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    var register = Register{ .a = 0, .b = 0, .c = 0 };

    var block_iter = std.mem.splitSequence(u8, input, "\n\n");
    var registers_iter = std.mem.splitScalar(u8, block_iter.first(), '\n');
    while (registers_iter.next()) |line| {
        var line_iter = std.mem.splitSequence(u8, line, ": ");
        const reg_str = line_iter.next() orelse break;
        const reg_val_str = line_iter.next() orelse break;
        const reg_val = try std.fmt.parseInt(i64, reg_val_str, 10);
        if (std.mem.eql(u8, reg_str, "Register A")) {
            register.a = reg_val;
        } else if (std.mem.eql(u8, reg_str, "Register B")) {
            register.b = reg_val;
        } else {
            register.c = reg_val;
        }
    }

    var program = std.ArrayList(i4).init(allocator);
    defer program.deinit();

    var program_str_iter = std.mem.splitSequence(u8, block_iter.next().?, ": ");
    _ = program_str_iter.next();
    var program_iter = std.mem.splitScalar(u8, program_str_iter.next().?, ',');
    while (program_iter.next()) |str| {
        if (!std.ascii.isDigit(str[0])) {
            break;
        }

        std.debug.print("{s}\n", .{str});

        const num = try std.fmt.parseInt(i4, str, 10);
        try program.append(num);
    }

    std.debug.print("{any}\n", .{register});
    std.debug.print("{any}\n", .{program.items});

    return "";
}

const test_allocator = std.testing.allocator;

test solve {
    const input =
        \\Register A: 729
        \\Register B: 0
        \\Register C: 0
        \\
        \\Program: 0,1,5,4,3,0
    ;
    const result = try solve(test_allocator, input);

    try std.testing.expectEqualStrings("4,6,3,5,6,3,5,2,1,0", result);
}
