const std = @import("std");
const input: []const u8 = @embedFile("./input.txt");

const MUL = "mul(";
const DO = "do()";
const DONT = "don't()";

pub fn main() !void {
    var sum: u32 = 0;

    var i: usize = 0;
    var shouldMultiply = true;
    while (i < input.len - MUL.len) : (i += 1) {
        if (isDo(input, i)) {
            shouldMultiply = true;
        }

        if (isDont(input, i)) {
            shouldMultiply = false;
        }

        const cur = input[i .. i + MUL.len];

        if (!std.mem.eql(u8, cur, MUL)) {
            continue;
        }

        if (!shouldMultiply) {
            i += MUL.len;
            continue;
        }

        i += MUL.len;

        const left_num = safeParseInt(input, &i);

        if (input[i] != ',') {
            continue;
        }

        i += 1;

        const right_num = safeParseInt(input, &i);

        if (input[i] != ')') {
            continue;
        }

        sum += right_num * left_num;
    }

    std.debug.print("Day 3 Part 2 - FINAL SUM: {d}\n", .{sum});
}

fn safeParseInt(buf: []const u8, index: *usize) u32 {
    var n: u32 = 0;
    while (index.* < buf.len) {
        const d = buf[index.*];
        if (d < '0' or d > '9') {
            break;
        }
        n = n * 10 + d - 48;
        index.* += 1;
    }
    return n;
}

fn isDo(buf: []const u8, index: usize) bool {
    const str = buf[index .. index + DO.len];

    return std.mem.eql(u8, str, DO);
}

fn isDont(buf: []const u8, index: usize) bool {
    if (index + DONT.len > buf.len) {
        return false;
    }

    const str = buf[index .. index + DONT.len];

    return std.mem.eql(u8, str, DONT);
}
