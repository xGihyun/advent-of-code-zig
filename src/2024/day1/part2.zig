const std = @import("std");
const input = @embedFile("./input.txt");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var lines = std.mem.splitScalar(u8, input, '\n');

    var left_list = std.ArrayList(i32).init(allocator);
    defer left_list.deinit();

    var right_list = std.ArrayList(i32).init(allocator);
    defer right_list.deinit();

    while (lines.next()) |line| {
        var iter = std.mem.splitSequence(u8, line, "   ");

        if (iter.next()) |n1| {
            if (n1.len == 0) continue;

            const value = try std.fmt.parseInt(i32, n1, 10);
            try left_list.append(value);
        }

        if (iter.next()) |n2| {
            const value = try std.fmt.parseInt(i32, n2, 10);
            try right_list.append(value);
        }
    }

    const left_slice = try left_list.toOwnedSlice();
    const right_slice = try right_list.toOwnedSlice();

    var map = std.AutoHashMap(i32, i32).init(allocator);
    defer map.deinit();

    for (right_slice) |num| {
        const entry = try map.getOrPutValue(num, 0);

        entry.value_ptr.* += 1;
    }

    var sum: i32 = 0;

    for (left_slice) |num| {
        const entry = map.get(num);

        if (entry) |value| {
            sum += num * value;
        }
    }

    std.debug.print("{d}\n", .{sum});
}
