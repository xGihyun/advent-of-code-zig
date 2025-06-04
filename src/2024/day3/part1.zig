const std = @import("std");
const input: []const u8 = @embedFile("./input.txt");

pub fn main() !void {
    const MUL = "mul(";

    var sum: u32 = 0;

    var l: usize = 0;
    var r: usize = MUL.len;
    while (r < input.len) {
        const cur = input[l..r];

        if (!std.mem.eql(u8, cur, MUL)) {
            l += 1;
            r += 1;
            continue;
        }

        const left_num = safeParseInt(input, &r);

        if (input[r] != ',') {
            l = r + 1;
            r = l + MUL.len;
            continue;
        }

        r += 1;

        const right_num = safeParseInt(input, &r);

        if (input[r] != ')') {
            l = r + 1;
            r = l + MUL.len;
            continue;
        }

        sum += right_num * left_num;

        l = r + 1;
        r = l + MUL.len;
    }

    std.debug.print("Day 3 Part 1 - FINAL SUM: {d}\n", .{sum});
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
