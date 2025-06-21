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

const Position = struct { row: usize, column: usize };

fn solve(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var grid = std.ArrayList([]const u8).init(allocator);
    defer grid.deinit();

    var lines_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines_iter.next()) |line| {
        try grid.append(line);
    }

    const start_pos = getStartPosition(grid.items) orelse unreachable;
    const score = try bfs(allocator, grid.items, start_pos);

    return score;
}

fn getStartPosition(grid: [][]const u8) ?Position {
    var pos: ?Position = null;
    for (grid, 0..) |line, row| {
        const col = std.mem.indexOfScalar(u8, line, 'S') orelse continue;
        pos = Position{ .column = col, .row = row };
    }

    return pos;
}

const Delta = struct { x: i64, y: i64 };

const DELTA_X = [_]i64{ 1, -1, 0, 0 };
const DELTA_Y = [_]i64{ 0, 0, 1, -1 };
// Index must match the respective delta above
const Direction = enum(usize) { Right = 0, Left = 1, Up = 2, Down = 3 };

const State = struct {
    position: Position,
    direction: Direction,
    score: i64,

    const Self = @This();

    fn lessThan(_: void, a: Self, b: Self) std.math.Order {
        return std.math.order(a.score, b.score);
    }
};

fn bfs(allocator: std.mem.Allocator, grid: [][]const u8, position: Position) !i64 {
    var pq = std.PriorityQueue(State, void, State.lessThan).init(allocator, {});
    defer pq.deinit();

    try pq.add(State{ .direction = .Right, .position = position, .score = 0 });

    // var visited: [141][141][4]bool = undefined;
    var best_scores: [141][141][4]i64 = .{.{.{std.math.maxInt(i64)} ** 4} ** 141} ** 141;
    var predecessors: [141][141][4]std.ArrayList(State) = undefined;

    for (0..141) |row| {
        for (0..141) |col| {
            for (0..4) |d| {
                predecessors[row][col][d] = std.ArrayList(State).init(allocator);
            }
        }
    }

    defer {
        for (0..141) |row| {
            for (0..141) |col| {
                for (0..4) |d| {
                    predecessors[row][col][d].deinit();
                }
            }
        }
    }

    var end_pos: Position = undefined;
    var best_score: i64 = std.math.maxInt(i64);

    while (pq.count() > 0) {
        const vertex = pq.remove();
        // if (visited[vertex.position.row][vertex.position.column][@intFromEnum(vertex.direction)]) {
        //     continue;
        // }

        // visited[vertex.position.row][vertex.position.column][@intFromEnum(vertex.direction)] = true;

        if (grid[vertex.position.row][vertex.position.column] == 'E') {
            if (vertex.score < best_score) {
                best_score = vertex.score;
                end_pos = vertex.position;
            }
            continue;
        }

        const dir_idx: usize = @intFromEnum(vertex.direction);
        const dx = DELTA_X[dir_idx];
        const dy = DELTA_Y[dir_idx];

        const rotations = [_]Direction{
            switch (vertex.direction) {
                .Down => .Left,
                .Right => .Down,
                .Up => .Right,
                .Left => .Up,
            },
            switch (vertex.direction) {
                .Down => .Right,
                .Right => .Up,
                .Up => .Left,
                .Left => .Down,
            },
        };

        for (rotations) |dir| {
            const new_score = vertex.score + 1000;
            const new_state = State{ .direction = dir, .position = vertex.position, .score = new_score };

            if (new_score < best_scores[vertex.position.row][vertex.position.column][@intFromEnum(dir)]) {
                best_scores[vertex.position.row][vertex.position.column][@intFromEnum(dir)] = new_score;
                predecessors[vertex.position.row][vertex.position.column][@intFromEnum(dir)].clearAndFree();
                try predecessors[vertex.position.row][vertex.position.column][@intFromEnum(dir)].append(vertex);
                try pq.add(new_state);
            } else if (new_score == best_scores[vertex.position.row][vertex.position.column][@intFromEnum(dir)]) {
                try predecessors[vertex.position.row][vertex.position.column][@intFromEnum(dir)].append(vertex);
            }
        }

        const new_col: i64 = @as(i64, @intCast(vertex.position.column)) + dx;
        const new_row: i64 = @as(i64, @intCast(vertex.position.row)) + dy;
        if (new_col < 0 or new_row < 0) {
            continue;
        }

        const next_pos = Position{ .column = @as(usize, @intCast(new_col)), .row = @as(usize, @intCast(new_row)) };
        if (next_pos.row >= grid.len or next_pos.column >= grid[0].len) {
            continue;
        }

        if (grid[next_pos.row][next_pos.column] == '#') {
            continue;
        }

        // if (visited[next_pos.row][next_pos.column][dir_idx]) {
        //     continue;
        // }

        const new_score = vertex.score + 1;
        const new_state = State{ .direction = vertex.direction, .position = next_pos, .score = new_score };
        if (new_score < best_scores[next_pos.row][next_pos.column][dir_idx]) {
            best_scores[next_pos.row][next_pos.column][dir_idx] = new_score;
            predecessors[next_pos.row][next_pos.column][dir_idx].clearAndFree();
            try predecessors[next_pos.row][next_pos.column][dir_idx].append(vertex);
            try pq.add(new_state);
        } else if (new_score == best_scores[next_pos.row][next_pos.column][dir_idx]) {
            try predecessors[next_pos.row][next_pos.column][dir_idx].append(vertex);
        }
    }

    var on_best_path: [141][141]bool = undefined;
    var stack = std.ArrayList(State).init(allocator);
    defer stack.deinit();

    for (0..4) |dir_idx| {
        if (best_scores[end_pos.row][end_pos.column][dir_idx] == best_score) {
            try stack.append(State{
                .position = end_pos,
                .direction = @enumFromInt(dir_idx),
                .score = best_score,
            });
        }
    }

    var visited_dfs: [141][141][4]bool = undefined;
    while (stack.items.len > 0) {
        const top = stack.pop() orelse break;
        if (visited_dfs[top.position.row][top.position.column][@intFromEnum(top.direction)]) {
            continue;
        }

        visited_dfs[top.position.row][top.position.column][@intFromEnum(top.direction)] = true;
        on_best_path[top.position.row][top.position.column] = true;

        for (predecessors[top.position.row][top.position.column][@intFromEnum(top.direction)].items) |pred| {
            try stack.append(pred);
        }
    }

    var count: i64 = 0;
    for (0..grid.len) |row| {
        for (0..grid[0].len) |col| {
            if (on_best_path[row][col]) {
                count += 1;
            }
        }
    }

    return count;
}

const test_allocator = std.testing.allocator;

test solve {
    const input =
        \\###############
        \\#.......#....E#
        \\#.#.###.#.###.#
        \\#.....#.#...#.#
        \\#.###.#####.#.#
        \\#.#.#.......#.#
        \\#.#.#####.###.#
        \\#...........#.#
        \\###.#.#####.#.#
        \\#...#.....#.#.#
        \\#.#.#.###.#.#.#
        \\#.....#...#.#.#
        \\#.###.#.#.#.#.#
        \\#S..#.....#...#
        \\###############
    ;
    const result = try solve(test_allocator, input);

    try std.testing.expectEqual(45, result);
}

test "solve big" {
    const input =
        \\#################
        \\#...#...#...#..E#
        \\#.#.#.#.#.#.#.#.#
        \\#.#.#.#...#...#.#
        \\#.#.#.#.###.#.#.#
        \\#...#.#.#.....#.#
        \\#.#.#.#.#.#####.#
        \\#.#...#.#.#.....#
        \\#.#.#####.#.###.#
        \\#.#.#.......#...#
        \\#.#.###.#####.###
        \\#.#.#...#.....#.#
        \\#.#.#.#####.###.#
        \\#.#.#.........#.#
        \\#.#.#.#########.#
        \\#S#.............#
        \\#################
    ;
    const result = try solve(test_allocator, input);

    try std.testing.expectEqual(64, result);
}
