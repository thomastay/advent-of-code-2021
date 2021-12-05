// the size of each word in the input file (manually found)
const wordSize: u4 = 12;
const inputFile = @embedFile("./input/day03.txt");
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
// const assert = std.debug.assert;

const MostCommonResult = enum {
    Zero,
    One,
    Equal,
    All,
};

// Returns an array of 0, 1, or 2 (0 if 0 is most common, 1 is 1 is most common, 2 if it's equal)
fn mostCommon(input: []const u8) ![wordSize]MostCommonResult {
    var numOnes = [_]u32{0} ** wordSize;

    // number of lines in the file
    var numWords: i32 = 0;
    var start: usize = 0;
    while (std.mem.indexOfScalarPos(u8, input, start, '\n')) |end| : (start = end + 1) {
        numWords += 1;
        var i: usize = 0;
        while (i < end - start) : (i += 1) {
            const c = input[start + i];
            switch (c) {
                '1' => numOnes[i] += 1,
                '0' => continue,
                else => unreachable,
            }
        }
    }
    const half = @divFloor(numWords, 2);
    var result = [_]MostCommonResult{MostCommonResult.Zero} ** wordSize;
    var i: usize = 0;
    while (i < wordSize) : (i += 1) {
        if (numOnes[i] > half) {
            result[i] = MostCommonResult.One;
        } else if (numOnes[i] == half) {
            result[i] = MostCommonResult.Equal;
        } else {
            result[i] = MostCommonResult.Zero;
        }
    }
    return result;
}

fn calcGamma(input: []const u8) !u32 {
    var gamma: u32 = 0;
    var eps: u32 = 0;
    const commonBit = try mostCommon(input);

    // use typeof here, Zig will ensure absolutely no overflow (cool!)
    var i: @TypeOf(wordSize) = 0;
    while (i < wordSize) : (i += 1) {
        const x = @as(u32, 1) << (wordSize - i - 1);
        if (commonBit[i] == MostCommonResult.One) {
            gamma += x;
        } else {
            eps += x;
        }
    }
    return gamma * eps;
}

// -------------- Part 2 -----------------

fn getSlices(input: []const u8, allocator: *Allocator) !ArrayList([]const u8) {
    var result = ArrayList([]const u8).init(allocator);

    var start: usize = 0;
    while (std.mem.indexOfScalarPos(u8, input, start, '\n')) |end| : (start = end + 1) {
        try result.append(input[start..end]);
    }
    return result;
}

fn co2Rating(input: []const u8, allocator: *Allocator) !u32 {
    var slices = try getSlices(input, allocator);
    defer slices.deinit();

    var i: u32 = 0;
    while (i < wordSize) : (i += 1) {
        // first, check for the most common digit amongst the slices
        // Then, filter out slices that don't meet the most common digit
        const digitWanted = switch (mostCommonDigit(slices, i)) {
            .One, .Equal => @as(u8, '0'),
            .Zero => @as(u8, '1'),
            // if all the digits are the same, ignore this round
            .All => continue,
        };
        filterOut(&slices, i, digitWanted);
        if (slices.items.len == 1) {
            // Found it
            return try parseBinary(slices.items[0]);
        }
    }
    unreachable;
}

fn oxygenRating(input: []const u8, allocator: *Allocator) !u32 {
    var slices = try getSlices(input, allocator);
    defer slices.deinit();

    var i: u32 = 0;
    while (i < wordSize) : (i += 1) {
        // first, check for the most common digit amongst the slices
        // std.debug.print("\nCurrent slices:", .{});
        // for (slices.items) |slice| {
        //     std.debug.print("{s}, ", .{slice});
        // }
        // std.debug.print("\n", .{});

        // Then, filter out slices that don't meet the most common digit
        const digitWanted = switch (mostCommonDigit(slices, i)) {
            // Note: the @as u8 casts are not strictly needed, but are due to this 5 year old issue in the Type checker
            // which causes comptime values returned in if else branches to not be implicitly castable
            // https://github.com/ziglang/zig/issues/137
            .One, .Equal => @as(u8, '1'),
            .Zero => @as(u8, '0'),
            .All => continue,
        };
        filterOut(&slices, i, digitWanted);
        if (slices.items.len == 1) {
            // Found it
            return try parseBinary(slices.items[0]);
        }
    }
    unreachable;
}

// Removes element in slices that don't have the digit at pos
fn filterOut(slices: *ArrayList([]const u8), pos: u32, digit: u8) void {
    var j: u32 = 0;
    for (slices.items) |slice| {
        if (slice[pos] == digit) {
            slices.items[j] = slice;
            j += 1;
        }
    }
    slices.shrinkRetainingCapacity(j);
}

fn mostCommonDigit(slices: ArrayList([]const u8), pos: u32) MostCommonResult {
    var numOnes: i32 = 0;
    for (slices.items) |slice| {
        if (slice[pos] == '1') numOnes += 1;
    }
    const half = @divFloor(slices.items.len, 2);
    if (numOnes == 0 or numOnes == slices.items.len) {
        return .All;
    } else if (numOnes > half) {
        return .One;
    } else if (numOnes == half and 2 * half == slices.items.len) {
        return .Equal;
    } else {
        // if this is an odd number. We round down, so equality means that there are less ones than zeroes.
        return .Zero;
    }
}

fn parseBinary(input: []const u8) std.fmt.ParseIntError!u32 {
    if (input.len > 32) return std.fmt.ParseIntError.Overflow;

    var result: u32 = 0;
    var i: u5 = 0;
    while (i < input.len) : (i += 1) {
        switch (input[i]) {
            '1' =>
            // Safety: input.len is checked above
            result += (@as(u32, 1) << (@intCast(u5, input.len) - i - 1)),
            '0' => continue,
            else => return std.fmt.ParseIntError.InvalidCharacter,
        }
    }
    return result;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = &gpa.allocator;
    defer std.debug.assert(!gpa.deinit()); // no leaks

    try stdout.print("Part 1: Gamma * eps = {d}\nPart2: oxygen * co2: {d}\n", .{ try calcGamma(inputFile), (try oxygenRating(inputFile, allocator)) * try co2Rating(inputFile, allocator) });
}

test "life support" {
    const input =
        \\000000000100
        \\000000011110
        \\000000010110
        \\000000010111
        \\000000010101
        \\000000001111
        \\000000000111
        \\000000011100
        \\000000010000
        \\000000011001
        \\000000000010
        \\000000001010
        \\
    ;
    try std.testing.expectEqual(@as(u32, 23), try oxygenRating(input, std.testing.allocator));
    try std.testing.expectEqual(@as(u32, 10), try co2Rating(input, std.testing.allocator));
}

test "Filter out" {
    var slices = ArrayList([]const u8).init(std.testing.allocator);
    defer slices.deinit();

    try slices.appendSlice(&.{ "000000000000", "100000000000", "101000000000" });
    filterOut(&slices, 0, '1');
    try std.testing.expectEqual(@as(usize, 2), slices.items.len);
}
