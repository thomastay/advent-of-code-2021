// Lava Tubes
const inputFile = @embedFile("./input/day09.txt");
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Str = []const u8;
const assert = std.debug.assert;
const tokenize = std.mem.tokenize;
const print = std.debug.print;

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
    print("Grid width is: {d}x{d}\n", .{ nRows, nCols });
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
    try stdout.print("Part1: {d}\n", .{partOne(grid)});
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
