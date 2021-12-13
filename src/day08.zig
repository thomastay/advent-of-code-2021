const inputFile = @embedFile("./input/day08.txt");
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const assert = std.debug.assert;

// 0(6): abcefg
// 1(2): cf
// 2(5): acdeg
// 3(5): acdfg
// 4(4): bcdf
// 5(5): abdfg
// 6(6): abdefg
// 7(3): acf
// 8(7): abcdefg
// 9(6): abcdfg

/// 1(2): cf
/// 4(4): bcdf
/// 7(3): acf
/// 8(7): abcdefg
const digitLengths = struct {
    One: usize = 2,
    Four: usize = 4,
    Seven: usize = 3,
    Eight: usize = 7,
}{};

const PartOneResult = struct {
    n1: u32,
    n4: u32,
    n7: u32,
    n8: u32,
};

pub fn partOne(lines: []Line) PartOneResult {
    var result = std.mem.zeroes(PartOneResult);
    for (lines) |line| {
        for (line.out) |outDigit| {
            switch (outDigit.len) {
                digitLengths.One => result.n1 += 1,
                digitLengths.Four => result.n4 += 1,
                digitLengths.Seven => result.n7 += 1,
                digitLengths.Eight => result.n8 += 1,
                else => continue,
            }
        }
    }
    return result;
}

pub fn partTwo(lines: []Line) u32 {
    var result: u32 = 0;
    const powTens = [_]u32{ 1000, 100, 10, 1 };
    for (lines) |line| {
        const digits = inferDigits(line.digits);
        for (line.out) |outStr, i| {
            for (digits) |digitStr, digit| {
                if (std.mem.eql(u8, digitStr, outStr)) {
                    result += @intCast(u32, digit) * powTens[i];
                    break;
                }
            }
        }
    }
    return result;
}

fn debugPrintInference(digits: [10][]const u8) void {
    std.debug.print("Inferred ", .{});
    for (digits) |digit, i| {
        std.debug.print("{s} - {d} ", .{ digit, i });
    }
    std.debug.print("\n", .{});
}

/// # Algorithm:
/// First, identify all known digits (1, 4, 7, 8)
/// Compare 4 and all 6-len strings. 4 is a subset of 9 only. This gives you 9.
/// Compare the other two 6 length strings and 1. 1 is a subset of 0 only. This gives you 0 and 6.
/// Compare 1 and all 5-len strings. 1 is a subset of 3 only. This gives you 3
/// Compute (8 - 6). The missing character is cc
/// Compare two remaining 5-len strings. The one with cc is 2, the other is 5.
fn inferDigits(digits: [10][]const u8) [10][]const u8 {
    var one: []const u8 = undefined;
    var four: []const u8 = undefined;
    var seven: []const u8 = undefined;
    var eight: []const u8 = undefined;

    var len5: [3][]const u8 = undefined;
    var len6: [3][]const u8 = undefined;

    // Step 1: Identify all known digits
    {
        var len5Count: usize = 0;
        var len6Count: usize = 0;
        for (digits) |digit| {
            switch (digit.len) {
                digitLengths.One => one = digit,
                digitLengths.Four => four = digit,
                digitLengths.Seven => seven = digit,
                digitLengths.Eight => eight = digit,
                6 => {
                    len6[len6Count] = digit;
                    len6Count += 1;
                },
                5 => {
                    len5[len5Count] = digit;
                    len5Count += 1;
                },
                else => unreachable,
            }
        }
        assert(len5Count == 3);
        assert(len6Count == 3);
    }

    // Step 2: Filter out 6 len strings
    const nineIdx = findSubset(len6, four);
    const zeroIdx = blk: {
        for (len6) |slic, i| {
            if (i == nineIdx) continue;
            if (isSubsetOf(one, slic)) break :blk i;
        }
        unreachable;
    };
    const sixIdx = oddOneOut(nineIdx, zeroIdx);
    const six = len6[sixIdx];

    // Step 3: five len strings
    const threeIdx = findSubset(len5, one);
    const twoIdx = blk: {
        const cc = digitDiff(eight, six);
        for (len5) |slic, i| {
            if (i == threeIdx) continue;
            if (contains(slic, cc)) break :blk i;
        }
        unreachable;
    };
    const fiveIdx = oddOneOut(threeIdx, twoIdx);
    return [_][]const u8{
        len6[zeroIdx],
        one,
        len5[twoIdx],
        len5[threeIdx],
        four,
        len5[fiveIdx],
        six,
        seven,
        eight,
        len6[nineIdx],
    };
}

fn contains(x: []const u8, c: u8) bool {
    for (x) |xc| {
        if (xc == c) return true;
    }
    return false;
}

// Returns the char present in x not in y
fn digitDiff(x: []const u8, y: []const u8) u8 {
    assert(x.len - y.len == 1);

    for (x) |c, i| {
        if (i == x.len - 1 or y[i] != c) return c;
    }
    unreachable;
}

// from 0 - 2, return the one that's not a or b
fn oddOneOut(a: usize, b: usize) usize {
    var i: usize = 0;
    while (i < 3) : (i += 1) {
        if (i != a and i != b) return i;
    }
    unreachable;
}

fn findSubset(arr: [3][]const u8, subset: []const u8) usize {
    for (arr) |slic, i| {
        if (isSubsetOf(subset, slic)) return i;
    }
    unreachable;
}

// x, y are sorted and x.len < y.len
fn isSubsetOf(x: []const u8, y: []const u8) bool {
    assert(x.len < y.len);

    var yi: usize = 0;
    for (x) |xc| {
        // Try to scan forward and find the char
        while (true) {
            if (yi == y.len) return false;
            if (y[yi] == xc) break;
            yi += 1;
        }
    }
    return true;
}

test "isSubsetOf" {
    try std.testing.expect(isSubsetOf("afg", "abcfsdg"));
    try std.testing.expect(!isSubsetOf("afgh", "abcfsdg"));
    try std.testing.expect(!isSubsetOf("agh", "abcfsdg"));
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

    // don't free, will be freed in arena
    const lines = try parseInput(inputFile, allocator);
    const part1 = partOne(lines);
    const part1Total = part1.n1 + part1.n4 + part1.n7 + part1.n8;
    try stdout.print("Part 1: {any}, total: {d}\n", .{ part1, part1Total });
    try stdout.print("Part 2: {d}\n", .{partTwo(lines)});
}

const Line = struct {
    digits: [10][]const u8,
    out: [4][]const u8,

    pub fn deinit(self: @This(), allocator: Allocator) void {
        for (self.digits) |digit| {
            allocator.free(digit);
        }
        for (self.out) |x| {
            allocator.free(x);
        }
    }
};
const ascU8 = std.sort.asc(u8); // somehow std.sort.asc_u8 isn't exported?

/// Caller is responsible for freeing memory
/// Since this creates a lot of small allocations (we sort the input strings),
/// caller is recommended to use a Arena Allocator
fn parseInput(input: []const u8, allocator: Allocator) ![]Line {
    var start: usize = 0;
    var lines = ArrayList(Line).init(allocator);
    errdefer lines.deinit();
    errdefer for (lines.items) |line| {
        line.deinit(allocator);
    };

    // A line consists of exactly 10 slices then a | then four more slices
    while (std.mem.indexOfScalarPos(u8, input, start, '\n')) |lineEnd| : (start = lineEnd + 1) {
        //
        // Fill in Digits
        //
        var digits: [10][]const u8 = undefined;
        // Number of allocated digits so far (could fail at any point)
        var digitsCount: usize = 0;
        errdefer while (digitsCount > 0) {
            digitsCount -= 1;
            allocator.free(digits[digitsCount]);
        };
        while (digitsCount < 10) : (digitsCount += 1) {
            const sliceEnd = std.mem.indexOfScalarPos(u8, input, start, ' ').?;
            defer start = sliceEnd + 1;
            const slice = try allocator.dupe(u8, input[start..sliceEnd]);
            std.sort.sort(u8, slice, {}, ascU8);
            digits[digitsCount] = slice;
        }

        assert(input[start] == '|');
        assert(input[start + 1] == ' ');
        start += 2;

        //
        // Fill in out
        //
        var out: [4][]const u8 = undefined;
        var outCount: usize = 0;
        errdefer while (outCount > 0) {
            outCount -= 1;
            allocator.free(out[outCount]);
        };
        while (outCount < 4) : (outCount += 1) {
            const sliceEnd = std.mem.indexOfAnyPos(u8, input, start, &.{ ' ', '\n' }).?;
            defer start = sliceEnd + 1;
            const slice = try allocator.dupe(u8, input[start..sliceEnd]);
            std.sort.sort(u8, slice, {}, ascU8);
            out[outCount] = slice;
        }

        try lines.append(Line{
            .digits = digits,
            .out = out,
        });
    }
    return lines.toOwnedSlice();
}

///
/// TESTING
///
const testInput =
    \\be cfbegad cbdgef fgaecd cgeb fdcge agebfd fecdb fabcd edb | fdgacbe cefdb cefbgd gcbe
    \\edbfga begcd cbg gc gcadebf fbgde acbgfd abcde gfcbed gfec | fcgedb cgb dgebacf gc
    \\fgaebd cg bdaec gdafb agbcfd gdcbef bgcad gfac gcb cdgabef | cg cg fdcagb cbg
    \\fbegcd cbd adcefb dageb afcb bc aefdc ecdab fgdeca fcdbega | efabcd cedba gadfec cb
    \\aecbfdg fbg gf bafeg dbefa fcge gcbea fcaegb dgceab fcbdga | gecf egdcabf bgf bfgea
    \\fgeab ca afcebg bdacfeg cfaedg gcfdb baec bfadeg bafgc acf | gebdcfa ecba ca fadegcb
    \\dbcfg fgd bdegcaf fgec aegbdf ecdfab fbedc dacgb gdcebf gf | cefg dcbef fcge gbcadfe
    \\bdfegc cbegaf gecbf dfcage bdacg ed bedf ced adcbefg gebcd | ed bcgafe cdgba cbgef
    \\egadfb cdbfeg cegd fecab cgb gbdefca cg fgcdab egfdb bfceg | gbdfcae bgc cg cgb
    \\gcafb gcf dcaebfg ecagb gf abcdeg gaef cafbge fdbac fegbdc | fgae cfgab fg bagce
    \\
;

test "Part 1" {
    var allocator = std.testing.allocator;
    const lines = try parseInput(testInput, allocator);
    defer {
        for (lines) |line| {
            line.deinit(allocator);
        }
        allocator.free(lines);
    }

    const part1 = partOne(lines);
    const part1Total = part1.n1 + part1.n4 + part1.n7 + part1.n8;
    try std.testing.expectEqual(@as(u32, 26), part1Total);
}

test "Parsing with failing allocator" {
    var failNums: usize = 0;
    while (failNums < 200) : (failNums += 4) {
        var allocator = std.testing.FailingAllocator.init(std.testing.allocator, failNums).allocator();
        const linesOrErr = parseInput(testInput, allocator);
        if (linesOrErr) |lines| {
            for (lines) |line| {
                line.deinit(allocator);
            }
            allocator.free(lines);
        } else |err| {
            try std.testing.expectEqual(error.OutOfMemory, err);
        }
    }
}

test "part 2 single" {
    const singleTestInput =
        \\acedgfb cdfbe gcdfa fbcad dab cefabd cdfgeb eafb cagedb ab | cdfeb fcadb cdfeb cdbaf
        \\
    ;
    var allocator = std.testing.allocator;
    const lines = try parseInput(singleTestInput, allocator);
    defer {
        for (lines) |line| {
            line.deinit(allocator);
        }
        allocator.free(lines);
    }

    const part2 = partTwo(lines);
    try std.testing.expectEqual(@as(u32, 5353), part2);
}

test "part 2" {
    var allocator = std.testing.allocator;
    const lines = try parseInput(testInput, allocator);
    defer {
        for (lines) |line| {
            line.deinit(allocator);
        }
        allocator.free(lines);
    }

    const part2 = partTwo(lines);
    try std.testing.expectEqual(@as(u32, 61229), part2);
}
