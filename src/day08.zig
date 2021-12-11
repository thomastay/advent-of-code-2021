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
const DigitLengths = struct {
    One: usize = 2,
    Four: usize = 4,
    Seven: usize = 3,
    Eight: usize = 7,
};
const digitLengths = DigitLengths{};

const PartOneResult = struct {
    n1: u32,
    n4: u32,
    n7: u32,
    n8: u32,
};

pub fn partOne(lines: []Line) PartOneResult {
    var result = std.mem.zeroes(PartOneResult);
    for (lines) |line| {
        // var one: []const u8 = undefined;
        // var four: []const u8 = undefined;
        // var seven: []const u8 = undefined;
        // var eight: []const u8 = undefined;
        // for (line.digits) |digit| {
        //     switch (digit.len) {
        //         digitLengths.One => one = digit,
        //         digitLengths.Four => four = digit,
        //         digitLengths.Seven => seven = digit,
        //         digitLengths.Eight => eight = digit,
        //         else => continue,
        //     }
        // }
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

/// # Algorithm:
/// First, identify all known digits (1, 4, 7, 8)
/// Compare 4 and all 6-len strings. 4 is a subset of 9 only. This gives you 9.
/// Compare the other two 6 length strings and 1. 1 is a subset of 0 only. This gives you 0 and 6.
/// Compare 1 and all 5-len strings. 1 is a subset of 3 only. This gives you 3
/// Compute (8 - 6). The missing character is cc
/// Compare two remaining 5-len strings. The one with cc is 2, the other is 5.
pub fn partTwo(lines: []Line) PartOneResult {
    var result = std.mem.zeroes(PartOneResult);
    for (lines) |line| {
        // var one: []const u8 = undefined;
        // var four: []const u8 = undefined;
        // var seven: []const u8 = undefined;
        // var eight: []const u8 = undefined;
        // for (line.digits) |digit| {
        //     switch (digit.len) {
        //         digitLengths.One => one = digit,
        //         digitLengths.Four => four = digit,
        //         digitLengths.Seven => seven = digit,
        //         digitLengths.Eight => eight = digit,
        //         else => continue,
        //     }
        // }
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

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = &gpa.allocator;
    defer std.debug.assert(!gpa.deinit()); // no leaks

    const input = try parseInput(inputFile, allocator);
    defer allocator.free(input);

    const part1 = partOne(input);
    const part1Total = part1.n1 + part1.n4 + part1.n7 + part1.n8;
    try stdout.print("Part 1: {any}, total: {d}\n", .{ part1, part1Total });
}

const Line = struct {
    digits: [10][]const u8,
    out: [4][]const u8,

    pub fn deinit(self: @This(), allocator: *Allocator) void {
        for (self.digits) |digit| {
            allocator.free(digit);
        }
        for (self.out) |x| {
            allocator.free(x);
        }
    }
};
const ascU8 = std.sort.asc(u8);

/// Caller is responsible for freeing memory
/// Since this creates a lot of small allocations (we sort the input strings),
/// caller is recommended to use a Arena Allocator
fn parseInput(input: []const u8, allocator: *Allocator) ![]Line {
    var start: usize = 0;
    var lines = ArrayList(Line).init(allocator);
    errdefer {
        for (lines.items) |line| {
            line.deinit(allocator);
        }
        lines.deinit();
    }

    // A line consists of exactly 10 slices then a | then four more slices
    while (std.mem.indexOfScalarPos(u8, input, start, '\n')) |lineEnd| : (start = lineEnd + 1) {

        //
        // Fill in Digits
        //
        var digits: [10][]const u8 = undefined;
        // Number of allocated digits so far (could fail at any point)
        var digitsCount: usize = 0;
        errdefer {
            var i: usize = 0;
            while (i < digitsCount) : (i += 1) {
                allocator.free(digits[i]);
            }
        }
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
        errdefer {
            var i: usize = 0;
            while (i < outCount) : (i += 1) {
                allocator.free(out[i]);
            }
        }
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

test "Part 1" {
    const input =
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
    var allocator = std.testing.allocator;
    const lines = try parseInput(input, allocator);
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
    const input =
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
    var failNums: usize = 0;
    while (failNums < 200) : (failNums += 4) {
        var allocator = &std.testing.FailingAllocator.init(std.testing.allocator, failNums).allocator;
        const linesOrErr = parseInput(input, allocator);
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
