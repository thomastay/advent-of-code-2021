// Lava Tubes
const inputFile = @embedFile("./input/day09.txt");
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Str = []const u8;
const BitSet = std.DynamicBitSet;
const assert = std.debug.assert;
const tokenize = std.mem.tokenize;
const print = std.debug.print;
fn sort(comptime T: type, items: []T) void {
    std.sort.sort(T, items, {}, comptime std.sort.asc(T));
}

fn partOne(grid: Input) usize {
    var result: usize = 0;
    for (grid.items) |d, i| {
        const row = i / grid.nCols;
        const col = i % grid.nCols;
        // left, right
        if (col > 0 and d >= grid.items[i - 1]) continue;
        if (col < grid.nCols - 1 and d >= grid.items[i + 1]) continue;
        // top, bottom
        if (row > 0 and d >= grid.items[i - grid.nCols]) continue;
        if (row < grid.nRows - 1 and d >= grid.items[i + grid.nCols]) continue;
        result += 1 + d;
    }
    return result;
}

fn partTwo(grid: Input, allocator: *Allocator) !usize {
    var visited = try BitSet.initEmpty(grid.items.len, allocator);
    defer visited.deinit();

    // the last 3 are the top 3 basins, the first one is scratch space
    var basins = [4]usize{ 0, 0, 0, 0 };
    for (grid.items) |d, i| {
        const row = i / grid.nCols;
        const col = i % grid.nCols;
        // Find a low point, same as part 1
        if (col > 0 and d >= grid.items[i - 1]) continue;
        if (col < grid.nCols - 1 and d >= grid.items[i + 1]) continue;
        if (row > 0 and d >= grid.items[i - grid.nCols]) continue;
        if (row < grid.nRows - 1 and d >= grid.items[i + grid.nCols]) continue;

        // from the low point, expand outwards
        const basinSize = findBasinSize(grid, i, &visited);
        basins[0] = basinSize;
        sort(usize, &basins);
    }
    return basins[1] * basins[2] * basins[3];
}

fn findBasinSize(grid: Input, pt: usize, visited: *BitSet) usize {
    if (visited.isSet(pt) or grid.items[pt] == 9) return 0;

    var result: usize = 1;
    visited.set(pt);

    const row = pt / grid.nCols;
    const col = pt % grid.nCols;
    const d = grid.items[pt];
    if (col > 0 and d < grid.items[pt - 1]) {
        result += findBasinSize(grid, pt - 1, visited);
    }
    if (col < grid.nCols - 1 and d < grid.items[pt + 1]) {
        result += findBasinSize(grid, pt + 1, visited);
    }
    if (row > 0 and d < grid.items[pt - grid.nCols]) {
        result += findBasinSize(grid, pt - grid.nCols, visited);
    }
    if (row < grid.nRows - 1 and d < grid.items[pt + grid.nCols]) {
        result += findBasinSize(grid, pt + grid.nCols, visited);
    }
    return result;
}

const Input = struct {
    items: Str,
    nRows: usize,
    nCols: usize,
};
fn parseInput(input: Str, allocator: *Allocator) !Input {
    var lines = ArrayList(u8).init(allocator);
    errdefer lines.deinit();
    const nCols = std.mem.indexOfScalar(u8, input, '\n').?;

    var nRows: usize = 0;
    var it = tokenize(u8, input, "\n");
    while (it.next()) |line| : (nRows += 1) {
        for (line) |c| {
            try lines.append(c - '0');
        }
    }
    return Input{ .items = lines.toOwnedSlice(), .nRows = nRows, .nCols = nCols };
}

pub fn main() !void {
    // Standard boilerplate for Aoc problems
    const stdout = std.io.getStdOut().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var gpaAllocator = &gpa.allocator;
    defer assert(!gpa.deinit()); // Check for memory leaks
    var arena = std.heap.ArenaAllocator.init(gpaAllocator);
    defer arena.deinit();
    var allocator = &arena.allocator; // use an arena

    const grid = try parseInput(inputFile, allocator);
    try stdout.print("Part1: {d}\nPart2: {d}", .{ partOne(grid), try partTwo(grid, allocator) });
}

test "part 1" {
    const testInput =
        \\2199943210
        \\3987894921
        \\9856789892
        \\8767896789
        \\9899965678
        \\7829965671
        \\
    ;
    var allocator = std.testing.allocator;
    const grid = try parseInput(testInput, allocator);
    defer allocator.free(grid.items);
    try std.testing.expectEqual(@as(usize, 22), partOne(grid));
}

test "part 2" {
    const testInput =
        \\2199943210
        \\3987894921
        \\9856789892
        \\8767896789
        \\9899965678
        \\
    ;
    var allocator = std.testing.allocator;
    const grid = try parseInput(testInput, allocator);
    defer allocator.free(grid.items);
    try std.testing.expectEqual(@as(usize, 1134), try partTwo(grid, allocator));
}
