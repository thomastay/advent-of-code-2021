// flashing octopi!

const inputFile = @embedFile("./input/day11.txt");
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

// Mutates input, returning the number of flashes
fn runRound(input: Input) usize {
    // We just do the simple thing
    // inc each octopus
    var nFlashes: usize = 0;

    for (input.items) |*octopus| {
        octopus.* += 1;
    }
    // check for octopi above 9
    for (input.items) |octopus, i| {
        if (octopus > 9) {
            nFlashes += propagateFlash(input, i);
        }
    }
    print("{any}\n", .{input});
    // Reset flashed octopi
    for (input.items) |*octopus| {
        if (octopus.* < 0) octopus.* = 0;
    }
    return nFlashes;
}

/// An octopus has at most 8 neighbors, so its score can increase by max 8 only.
/// This way, flashed octopi will always be negative (and will show up when printed!)
const flashedOctopus: i8 = -9;

/// At position pos, a flash occurs
/// increment the 
fn propagateFlash(input: Input, pos: usize) usize {
    if (input.items[pos] < 9) {
        input.items[pos] += 1;
        return 0;
    }

    var res: usize = 1;
    input.items[pos] = flashedOctopus;

    const row = pos / input.nCols;
    const col = pos % input.nCols;
    // zig fmt: off
    // left, right
    if (col > 0)                    res += propagateFlash(input, pos - 1);
    if (col < input.nCols - 1)      res += propagateFlash(input, pos + 1);
    // up, up L, up R
    if (row > 0)                    res += propagateFlash(input, pos - input.nCols);
    if (row > 0 
        and col > 0)                res += propagateFlash(input, pos - input.nCols - 1);
    if (row > 0
        and col < input.nCols - 1)  res += propagateFlash(input, pos - input.nCols + 1);
    // down, down L, down R
    if (row < input.nRows - 1)      res += propagateFlash(input, pos + input.nCols);
    if (row < input.nRows - 1 
        and col > 0)                res += propagateFlash(input, pos + input.nCols - 1);
    if (row < input.nRows - 1
        and col < input.nCols - 1)  res += propagateFlash(input, pos + input.nCols + 1);
    // zig fmt: on

    return res;
}

fn partOne(input: Input, nRounds: usize) usize {
    var res: usize = 0;
    var round: usize = 1;
    while (round <= nRounds) : (round += 1) {
        res += runRound(input);
    }
    return res;
}

fn partTwo(input: Input) usize {
    var round: usize = 1;
    print("{any}\n", .{input});
    while (true) : (round += 1) {
        print("Round {d}\n", .{round});
        if (runRound(input) == input.items.len) {
            // All flashed!
            return round;
        }
    }
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

    var input = try parseInput(inputFile, allocator);
    var input2 = try input.clone(allocator);

    const p1 = partOne(input, 100);
    const p2 = partTwo(input2);
    try stdout.print("Part1: {d}\nPart2: {d}", .{ p1, p2 });
}

const Input = struct {
    items: []i8,
    nRows: usize,
    nCols: usize,

    pub fn clone(self: @This(), allocator: Allocator) !@This() {
        const items = try allocator.dupe(i8, self.items);
        return @This(){ .items = items, .nRows = self.nRows, .nCols = self.nCols };
    }

    pub fn deinit(self: @This(), allocator: Allocator) void {
        allocator.free(self.items);
    }

    // printf implementation
    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        assert(self.items.len == (self.nRows * self.nCols));
        var row: usize = 0;
        while (row < self.nRows) : (row += 1) {
            var col: u32 = 0;
            while (col < self.nCols) : (col += 1) {
                const x = self.items[row * self.nCols + col];
                if (x < 0) {
                    try writer.print("*", .{});
                } else {
                    try writer.print("{d}", .{x});
                }
            }
            try writer.print("\n", .{});
        }
        try writer.print("\n", .{});
    }
};

fn parseInput(input: Str, allocator: Allocator) !Input {
    var lines = ArrayList(i8).init(allocator);
    errdefer lines.deinit();
    const nCols = std.mem.indexOfScalar(u8, input, '\n').?;

    var nRows: usize = 0;
    var it = tokenize(u8, input, "\n");
    while (it.next()) |line| : (nRows += 1) {
        for (line) |c| {
            try lines.append(@intCast(i8, c - '0'));
        }
    }
    return Input{ .items = lines.toOwnedSlice(), .nRows = nRows, .nCols = nCols };
}

test "Part 1 simple" {
    const testInput =
        \\11111
        \\19991
        \\19191
        \\19991
        \\11111
        \\
    ;
    var allocator = std.testing.allocator;
    const input = try parseInput(testInput, allocator);
    defer input.deinit(allocator);
    try std.testing.expectEqual(@as(usize, 9), partOne(input, 3));
}

test "Part 1" {
    const testInput =
        \\5483143223
        \\2745854711
        \\5264556173
        \\6141336146
        \\6357385478
        \\4167524645
        \\2176841721
        \\6882881134
        \\4846848554
        \\5283751526
        \\
    ;
    var allocator = std.testing.allocator;
    const input = try parseInput(testInput, allocator);
    defer input.deinit(allocator);
    try std.testing.expectEqual(@as(usize, 204), partOne(input, 10));
    try std.testing.expectEqual(@as(usize, 1656 - 204), partOne(input, 90));
}

test "Part 2" {
    const testInput =
        \\5483143223
        \\2745854711
        \\5264556173
        \\6141336146
        \\6357385478
        \\4167524645
        \\2176841721
        \\6882881134
        \\4846848554
        \\5283751526
        \\
    ;
    var allocator = std.testing.allocator;
    const input = try parseInput(testInput, allocator);
    defer input.deinit(allocator);
    try std.testing.expectEqual(@as(usize, 195), partTwo(input));
}
