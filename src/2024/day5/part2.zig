const std = @import("std");

pub fn main() !void {
    const input: []const u8 = @embedFile("./input.txt");
    const allocator = std.heap.page_allocator;
    const result = try solve(allocator, input);

    std.debug.print("{d}", .{result});
}

fn solve(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var map = std.AutoHashMap(u32, std.ArrayList(u32)).init(allocator);
    defer {
        var iter = map.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.deinit();
        }
        map.deinit();
    }

    var iter = std.mem.splitSequence(u8, input, "\n\n");
    var rule_lines = std.mem.splitScalar(u8, iter.first(), '\n');
    while (rule_lines.next()) |line| {
        var pages = std.mem.splitScalar(u8, line, '|');

        const first = pages.first();
        const before_page = try std.fmt.parseInt(u32, first, 10);

        const list = std.ArrayList(u32).init(allocator);
        defer list.deinit();
        const entry = try map.getOrPutValue(before_page, list);

        if (pages.next()) |str| {
            const after_page = try std.fmt.parseInt(u32, str, 10);
            try entry.value_ptr.append(after_page);
        }
    }

    var sorted_pages = std.ArrayList([]u32).init(allocator);
    defer {
        for (sorted_pages.items) |value| {
            allocator.free(value);
        }
        sorted_pages.deinit();
    }

    var stack = std.ArrayList(u32).init(allocator);
    defer stack.deinit();

    var temp_stack = std.ArrayList(u32).init(allocator);
    defer temp_stack.deinit();

    const page_lines = iter.next().?;
    var produce_lines = std.mem.splitScalar(u8, page_lines, '\n');
    while (produce_lines.next()) |line| {
        defer stack.clearAndFree();

        if (line.len == 0) {
            break;
        }

        var pages = std.mem.splitScalar(u8, line, ',');
        var is_ordered = true;

        while (pages.next()) |page| {
            if (page.len == 0) {
                break;
            }

            const num = try std.fmt.parseInt(u32, page, 10);
            const after_pages = map.get(num);

            if (after_pages) |list| {
                while (stack.getLastOrNull()) |top| {
                    if (!isValueInList(list.items, top)) {
                        break;
                    }

                    is_ordered = false;

                    const temp = stack.pop().?;
                    try temp_stack.append(temp);
                }
            }

            try stack.append(num);

            while (temp_stack.pop()) |top| {
                try stack.append(top);
            }
        }

        if (is_ordered) {
            continue;
        }

        const items = try stack.toOwnedSlice();
        try sorted_pages.append(items);
    }

    var sum: u32 = 0;

    for (sorted_pages.items) |pages| {
        const mid = pages.len / 2;
        sum += pages[mid];
    }

    return sum;
}

fn isValueInList(list: []u32, value: u32) bool {
    for (list) |num| {
        if (value == num) {
            return true;
        }
    }
    return false;
}

test "day 5 part 2" {
    const input =
        \\47|53
        \\97|13
        \\97|61
        \\97|47
        \\75|29
        \\61|13
        \\75|53
        \\29|13
        \\97|29
        \\53|29
        \\61|53
        \\97|53
        \\61|29
        \\47|13
        \\75|47
        \\97|75
        \\47|61
        \\75|61
        \\47|29
        \\75|13
        \\53|13
        \\
        \\75,47,61,53,29
        \\97,61,53,29,13
        \\75,29,13
        \\75,97,47,61,53
        \\61,13,29
        \\97,13,75,29,47
    ;

    const allocator = std.testing.allocator;
    const result = try solve(allocator, input);

    try std.testing.expectEqual(result, 123);
}
