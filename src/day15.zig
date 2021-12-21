// Shortest path in grid

const inputFile = @embedFile("./input/day15.txt");
const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Str = []const u8;
const BitSet = std.DynamicBitSet;
const StrMap = std.StringHashMap;
const HashMap = std.HashMap;
const Map = std.AutoHashMap;
const PriorityQueue = std.PriorityQueue;
const assert = std.debug.assert;
const tokenize = std.mem.tokenize;
const print = std.debug.print;
const parseInt = std.fmt.parseInt;
fn sort(comptime T: type, items: []T) void {
    std.sort.sort(T, items, {}, comptime std.sort.asc(T));
}
fn println(x: Str) void {
    print("{s}\n", .{x});
}

const QueueDatum = struct {
    size: u32,
    pos: u32,

    pub fn compare(a: @This(), b: @This()) std.math.Order {
        const ord = std.math.order(a.size, b.size);
        if (ord == .eq) {
            return std.math.order(a.pos, b.pos); // heuristic: favor items with bigger pos
        } else {
            return ord;
        }
    }
};

fn gridDjikstra(input: Input, allocator: Allocator) !u32 {
    var visited = try BitSet.initEmpty(allocator, input.items.len);
    defer visited.deinit();
    var queue = PriorityQueue(QueueDatum, QueueDatum.compare).init(allocator);
    defer queue.deinit();
    const nCols = @intCast(u32, input.nCols);

    // ============= Step 1: initialize start and kick off the queue ================
    // (0, 0) is start
    const startPos = 0;
    visited.set(startPos); // ensures it doesn't get re-visited
    // (0, 1) and (1, 0)
    try queue.add(.{ .size = input.items[startPos + 1], .pos = startPos + 1 });
    try queue.add(.{ .size = input.items[startPos + nCols], .pos = startPos + nCols });

    // ============= Step 2: Run djikstra ================
    while (queue.removeOrNull()) |datum| {
        const pos = datum.pos;
        const w = datum.size;
        if (pos == input.items.len - 1) {
            // reached the end!
            return w;
        }
        if (!visited.isSet(pos)) {
            // mark the node as visited and mark it with the current size
            visited.set(pos);
            // add all of the children to the queue
            const row = pos / nCols;
            const col = pos % nCols;
            // left, right, up, down
            // zig fmt: off
            if (col > 0)                try queue.add(.{ .size = w + input.items[pos - 1],     .pos = pos - 1 });
            if (col < nCols - 1)        try queue.add(.{ .size = w + input.items[pos + 1],     .pos = pos + 1 });
            if (row > 0)                try queue.add(.{ .size = w + input.items[pos - nCols], .pos = pos - nCols });
            if (row < input.nRows - 1)  try queue.add(.{ .size = w + input.items[pos + nCols], .pos = pos + nCols });
            // zig fmt: on
        }
    }
    unreachable;
}

pub fn main() !void {
    // Standard boilerplate for Aoc problems
    const stdout = std.io.getStdOut().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var gpaAllocator = gpa.allocator();
    defer assert(!gpa.deinit()); // Check for memory leaks
    var arena = std.heap.ArenaAllocator.init(gpaAllocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const input = try parseInput(inputFile, allocator);
    try stdout.print("Part 1: {d}\n", .{try gridDjikstra(input, allocator)});
    const expandedInput = try expandInput(input, 5);
    try stdout.print("Part 2: {d}\n", .{try gridDjikstra(expandedInput, allocator)});
}

const Input = struct {
    items: Str,
    nRows: usize,
    nCols: usize,
    allocator: Allocator,

    pub fn deinit(self: @This()) void {
        self.allocator.free(self.items);
    }
};
fn parseInput(input: Str, allocator: Allocator) !Input {
    var lines = try List(u8).initCapacity(allocator, 100 * 100);
    errdefer lines.deinit();
    const nCols = std.mem.indexOfScalar(u8, input, '\n').?;

    var nRows: usize = 0;
    var it = tokenize(u8, input, "\n");
    while (it.next()) |line| : (nRows += 1) {
        for (line) |c| {
            try lines.append(c - '0');
        }
    }
    return Input{ .items = lines.toOwnedSlice(), .nRows = nRows, .nCols = nCols, .allocator = allocator };
}

// Returns a new copy of input with the same allocator, expanded n times
fn expandInput(input: Input, numExpand: usize) !Input {
    const allocator = input.allocator;
    var items = try allocator.alloc(u8, input.items.len * numExpand * numExpand);
    errdefer allocator.free(items);
    const nCols = input.nCols * numExpand;
    const nRows = input.nRows * numExpand;

    var row: usize = 0;
    while (row < nRows) : (row += 1) {
        var col: usize = 0;
        while (col < nCols) : (col += 1) {
            // wrap around
            const rowIncrement = row / input.nRows;
            const colIncrement = col / input.nCols;
            const inc = rowIncrement + colIncrement;

            const originalRow = row % input.nRows;
            const originalCol = col % input.nCols;

            items[row * nCols + col] = wrapAround(input.items[originalRow * input.nCols + originalCol], inc);
        }
    }
    return Input{ .items = items, .nRows = nRows, .nCols = nCols, .allocator = allocator };
}

/// 5 + 5 -> 10 -> 1
fn wrapAround(x: u8, inc: usize) u8 {
    assert(x != 0);
    const inc_ = @intCast(u8, inc);
    return ((x + inc_ - 1) % 9) + 1;
}

test "part 2" {
    var allocator = std.testing.allocator;
    const input = try parseInput(inputFile, allocator);
    defer input.deinit();
    const expandedInput = try expandInput(input, 5);
    defer expandedInput.deinit();
    try std.testing.expectEqual(@as(usize, 2825), try gridDjikstra(expandedInput, allocator));
}
