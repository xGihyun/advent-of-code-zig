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

fn solve(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var register = Register{ .a = 0, .b = 0, .c = 0 };

    var block_iter = std.mem.splitSequence(u8, input, "\n\n");
    var registers_iter = std.mem.splitScalar(u8, block_iter.first(), '\n');
    while (registers_iter.next()) |line| {
        var line_iter = std.mem.splitSequence(u8, line, ": ");
        const reg_str = line_iter.next() orelse break;
        const reg_char = reg_str[reg_str.len - 1];
        const value = try std.fmt.parseInt(u64, line_iter.next().?, 10);

        switch (reg_char) {
            'A' => register.a = value,
            'B' => register.b = value,
            'C' => register.c = value,
            else => {},
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

    var candidates = std.ArrayList(u64).init(allocator);
    defer candidates.deinit();

    try candidates.append(0);

    var i: usize = program.items.len;
    while (i > 0) {
        i -= 1;
        const target_digit = program.items[i];

        var next_candidates = std.ArrayList(u64).init(allocator);
        defer next_candidates.deinit();

        for (candidates.items) |value| {
            for (0..8) |bits| {
                const temp_a = (value << 3) | bits;
                const output_digit = simulate(register, temp_a, program.items);
                if (output_digit == target_digit) {
                    try next_candidates.append(temp_a);
                }
            }
        }

        candidates.clearAndFree();
        try candidates.appendSlice(next_candidates.items);

        if (candidates.items.len == 0) {
            return 0;
        }
    }

    return std.mem.min(u64, candidates.items);
}

fn simulate(reg: Register, temp_a: u64, program: []const u3) u3 {
    var register = Register{
        .a = temp_a,
        .b = reg.b,
        .c = reg.c,
    };
    var i: usize = 1;
    while (i < program.len) {
        const opcode = program[i - 1];
        const operand = program[i];

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
                return @as(u3, @intCast(res));
            },
            6 => register.b = adv(register, operand),
            7 => register.c = adv(register, operand),
        }

        i += 2;
    }

    return 0;
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
        \\Register A: 2024
        \\Register B: 0
        \\Register C: 0
        \\
        \\Program: 0,3,5,4,3,0
    ;
    const result = try solve(test_allocator, input);

    try std.testing.expectEqual(117440, result);
}
