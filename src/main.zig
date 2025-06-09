const std = @import("std");

pub fn main() !void {
    std.debug.print("Don't forget to include an input.txt file on each day!\n", .{});
    std.debug.print("To get started, run the command:\n\n", .{});
    std.debug.print("zig build run -- <year> <day> <part>\n", .{});
}
