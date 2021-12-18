// Origami

const inputFile = @embedFile("./input/day13.txt");
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Str = []const u8;
const BitSet = std.DynamicBitSet;
const StrMap = std.StringHashMap;
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

const LineDirection = enum { X, Y };
fn run(input: Str, allocator: Allocator, stdout: anytype) !void {
    // ============= Step 1: parse the grid to get max row and col ================
    const colsAndRows = blk: {
        // Wait until Zig has multiple return: https://github.com/ziglang/zig/issues/4335
        var nCols: usize = 0;
        var nRows: usize = 0;
        var it = tokenize(u8, input, "\n");
        while (it.next()) |line| {
            if (line[0] == 'f') {
                break :blk .{ nRows, nCols };
            } else if (std.mem.indexOfScalar(u8, line, ',')) |commaPos| {
                const col = try std.fmt.parseInt(usize, line[0..commaPos], 10);
                const row = try parseInt(usize, line[commaPos + 1 .. line.len], 10);
                if (col >= nCols) {
                    nCols = col + 1;
                }
                if (row >= nRows) {
                    nRows = row + 1;
                }
            } else {
                unreachable;
            }
        }
        unreachable;
    };
    print("{any}\n\n", .{colsAndRows});
    var nRows = colsAndRows[0];
    var nCols = colsAndRows[1];
    const originalNCols = colsAndRows[1];

    // ============= Step 2: Parse the grid to get the dots ================
    var dots = try BitSet.initEmpty(allocator, nRows * nCols);
    defer dots.deinit(); // no defer since we use an arena
    var p1: usize = 0;
    const p2 = 0;

    var it = tokenize(u8, input, "\n");
    while (it.next()) |line| {
        if (line[0] != 'f') {
            const commaPos = std.mem.indexOfScalar(u8, line, ',').?;
            const col = try parseInt(usize, line[0..commaPos], 10);
            const row = try parseInt(usize, line[commaPos + 1 .. line.len], 10);
            dots.set(row * nCols + col);
        } else {
            // try printGrid(stdout, dots, nCols, nRows, originalNCols);
            // ============= Step 3: Process each fold in turn ================
            const foldAlongLen = "fold along ".len;
            const foldDirection: LineDirection = if (line[foldAlongLen] == 'x') .X else .Y;
            const lineNum = try parseInt(usize, line[foldAlongLen + 2 .. line.len], 10);
            foldGrid(&dots, nCols, nRows, originalNCols, foldDirection, lineNum);
            switch (foldDirection) {
                .X => nCols = lineNum,
                .Y => nRows = lineNum,
            }
            p1 = countScore(dots, nCols, nRows, originalNCols);
        }
    }
    try printGrid(stdout, dots, nCols, nRows, originalNCols);
    try stdout.print("Part1: {d}\nPart2: {d}", .{ p1, p2 });
}

pub fn main() !void {
    // Standard boilerplate for Aoc problems
    const stdout = std.io.getStdOut().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var gpaAllocator = gpa.allocator();
    defer assert(!gpa.deinit()); // Check for memory leaks
    var arena = std.heap.ArenaAllocator.init(gpaAllocator);
    defer arena.deinit();
    var allocator = arena.allocator(); // use an arena

    try run(inputFile, allocator, stdout);
}

/// modifies grid
fn foldGrid(
    grid: *BitSet,
    nCols: usize,
    nRows: usize,
    originalNCols: usize,
    foldDirection: LineDirection,
    foldNum: usize,
) void {
    switch (foldDirection) {
        .X => {
            var row: usize = 0;
            while (row < nRows) : (row += 1) {
                var col = foldNum + 1;
                while (col < nCols) : (col += 1) {
                    if (grid.isSet(row * originalNCols + col)) {
                        grid.set(row * originalNCols + (foldNum - (col - foldNum)));
                    }
                }
            }
        },
        .Y => {
            var row: usize = foldNum + 1;
            while (row < nRows) : (row += 1) {
                var col: usize = 0;
                while (col < nCols) : (col += 1) {
                    if (grid.isSet(row * originalNCols + col)) {
                        grid.set((foldNum - (row - foldNum)) * originalNCols + col);
                    }
                }
            }
        },
    }
}

fn countScore(
    grid: BitSet,
    nCols: usize,
    nRows: usize,
    originalNCols: usize,
) usize {
    var result: usize = 0;
    var row: usize = 0;
    while (row < nRows) : (row += 1) {
        var col: usize = 0;
        while (col < nCols) : (col += 1) {
            if (grid.isSet(row * originalNCols + col)) result += 1;
        }
    }
    return result;
}

fn printGrid(writer: anytype, grid: BitSet, nCols: usize, nRows: usize, originalNCols: usize) !void {
    var row: usize = 0;
    while (row < nRows) : (row += 1) {
        var col: usize = 0;
        while (col < nCols) : (col += 1) {
            const x = grid.isSet(row * originalNCols + col);
            if (x) {
                try writer.print("#", .{});
            } else {
                try writer.print(".", .{});
            }
        }
        try writer.print("\n", .{});
    }
    try writer.print("\n", .{});
}

test "Part 1" {
    const testInput =
        \\6,10
        \\0,14
        \\9,10
        \\0,3
        \\10,4
        \\4,11
        \\6,0
        \\6,12
        \\4,1
        \\0,13
        \\10,12
        \\3,4
        \\3,0
        \\8,4
        \\1,10
        \\2,14
        \\8,10
        \\9,0
        \\
        \\fold along y=7
        \\fold along x=5
        \\
    ;
    try run(testInput, std.testing.allocator, std.io.getStdOut().writer());
}
