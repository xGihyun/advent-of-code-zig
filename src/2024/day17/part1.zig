const std = @import("std");

pub fn main() !void {
    const input: []const u8 = @embedFile("./input.txt");
    const allocator = std.heap.page_allocator;

    var timer = try std.time.Timer.start();
    const result = try solve(allocator, input);
    defer allocator.free(result);

    const elapsed_ns = timer.read();
    const elapsed_ms = @as(f64, @floatFromInt(elapsed_ns)) / std.time.ns_per_ms;

    std.debug.print("\n{s}\n", .{result});
    std.debug.print("Time: {d:.3} ms", .{elapsed_ms});
}

const Register = struct {
    a: u64,
    b: u64,
    c: u64,

    fn getCombo(self: Register, operand: u3) u64 {
        return switch (operand) {
            0...3 => @as(u64, @intCast(operand)),
            4 => self.a,
            5 => self.b,
            6 => self.c,
            else => unreachable,
        };
    }
};

fn solve(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    var register = Register{ .a = 0, .b = 0, .c = 0 };

    var block_iter = std.mem.splitSequence(u8, input, "\n\n");
    var registers_iter = std.mem.splitScalar(u8, block_iter.first(), '\n');
    while (registers_iter.next()) |line| {
        var line_iter = std.mem.splitSequence(u8, line, ": ");
        const reg_str = line_iter.next() orelse break;
        const reg_val_str = line_iter.next() orelse break;
        const reg_val = try std.fmt.parseInt(u64, reg_val_str, 10);
        if (std.mem.eql(u8, reg_str, "Register A")) {
            register.a = reg_val;
        } else if (std.mem.eql(u8, reg_str, "Register B")) {
            register.b = reg_val;
        } else {
            register.c = reg_val;
        }
    }

    var program = std.ArrayList(u3).init(allocator);
    defer program.deinit();

    var program_str_iter = std.mem.splitSequence(u8, block_iter.next().?, ": ");
    _ = program_str_iter.next();

    const program_str = std.mem.trim(u8, program_str_iter.next().?, " \n\r");
    var program_iter = std.mem.splitScalar(u8, program_str, ',');
    while (program_iter.next()) |str| {
        const num = try std.fmt.parseInt(u3, str, 10);
        try program.append(num);
    }

    var output = std.ArrayList(u3).init(allocator);
    defer output.deinit();

    var i: usize = 1;
    while (i < program.items.len) {
        const opcode = program.items[i - 1];
        const operand = program.items[i];

        switch (opcode) {
            0 => register.a = adv(register, operand),
            1 => register.b = xl(register.b, operand),
            2 => register.b = mod(register, operand),
            3 => {
                const res = jnz(register, operand, i);
                if (res) |j| {
                    i = j;
                    continue;
                }
            },
            4 => register.b = bxc(register),
            5 => {
                const res = mod(register, operand);
                try output.append(@as(u3, @intCast(res)));
            },
            6 => register.b = adv(register, operand),
            7 => register.c = adv(register, operand),
        }

        i += 2;
    }

    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    for (output.items, 0..) |num, j| {
        if (j != 0) {
            try buffer.append(',');
        }
        const num_str = try std.fmt.allocPrint(allocator, "{d}", .{num});
        defer allocator.free(num_str);

        try buffer.appendSlice(num_str);
    }

    const slice = try buffer.toOwnedSlice();
    return slice;
}

fn adv(register: Register, operand: u3) u64 {
    const combo = register.getCombo(operand);
    const denom = std.math.pow(u64, 2, combo);
    return @divTrunc(register.a, denom);
}

fn xl(value: u64, operand: u3) u64 {
    return value ^ @as(u64, @intCast(operand));
}

fn mod(register: Register, operand: u3) u64 {
    const combo = register.getCombo(operand);
    return combo % 8;
}

fn jnz(register: Register, operand: u3, pointer: usize) ?usize {
    if (register.a == 0) {
        return null;
    }

    const u_operand = @as(usize, @intCast(operand));
    if (pointer == u_operand) {
        return null;
    }

    if (u_operand % 2 == 0) {
        return u_operand + 1;
    }

    return u_operand;
}

fn bxc(register: Register) u64 {
    return register.b ^ register.c;
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
    defer test_allocator.free(result);

    try std.testing.expectEqualStrings("4,6,3,5,6,3,5,2,1,0", result);
}

test "solve A=2024" {
    const input =
        \\Register A: 2024
        \\Register B: 0
        \\Register C: 0
        \\
        \\Program: 0,1,5,4,3,0
    ;
    const result = try solve(test_allocator, input);
    defer test_allocator.free(result);

    try std.testing.expectEqualStrings("4,2,5,6,7,7,7,7,3,1,0", result);
}
