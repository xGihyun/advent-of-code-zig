const std = @import("std");
const input = @embedFile("./input.txt");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var lines_iter = std.mem.splitScalar(u8, input, '\n');
    var safe_count: u32 = 0;

    while (lines_iter.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var nums_iter = std.mem.splitScalar(u8, line, ' ');
        var numbers = std.ArrayList(i32).init(allocator);
        defer numbers.deinit();

        while (nums_iter.next()) |num_str| {
            const num = try std.fmt.parseInt(i32, num_str, 10);

            try numbers.append(num);
        }

        if (isValid(numbers.items)) {
            safe_count += 1;
        }
    }

    std.debug.print("Part 1 Safe Count: {d}\n", .{safe_count});
}

fn isValid(numbers: []i32) bool {
    const is_ascending = std.sort.isSorted(i32, numbers, {}, comptime std.sort.asc(i32));
    const is_descending = std.sort.isSorted(i32, numbers, {}, comptime std.sort.desc(i32));

    if (!(is_ascending or is_descending)) {
        return false;
    }

    var i: usize = 0;

    while (i < numbers.len - 1) : (i += 1) {
        const diff = numbers[i] - numbers[i + 1];

        if (@abs(diff) < 1 or @abs(diff) > 3) {
            return false;
        }
    }

    return true;
}
