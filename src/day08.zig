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
};

/// Caller is responsible for freeing memory
fn parseInput(input: []const u8, allocator: *Allocator) ![]Line {
    var start: usize = 0;
    var lines = ArrayList(Line).init(allocator);
    while (std.mem.indexOfScalarPos(u8, input, start, '\n')) |lineEnd| : (start = lineEnd + 1) {
        // A line consists of exactly 10 slices then a | then four more slices
        var digits: [10][]const u8 = undefined;
        {
            var inputCount: u32 = 0;
            while (inputCount < 10) : (inputCount += 1) {
                const sliceEnd = std.mem.indexOfScalarPos(u8, input, start, ' ').?;
                defer start = sliceEnd + 1;
                digits[inputCount] = input[start..sliceEnd];
            }
        }
        assert(input[start] == '|');
        assert(input[start + 1] == ' ');
        start += 2;
        var out: [4][]const u8 = undefined;
        {
            var inputCount: u32 = 0;
            while (inputCount < 4) : (inputCount += 1) {
                const sliceEnd = std.mem.indexOfAnyPos(u8, input, start, &.{ ' ', '\n' }).?;
                defer start = sliceEnd + 1;
                out[inputCount] = input[start..sliceEnd];
            }
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
    const d = try parseInput(input, allocator);
    defer allocator.free(d);

    const part1 = partOne(d);
    const part1Total = part1.n1 + part1.n4 + part1.n7 + part1.n8;
    try std.testing.expectEqual(@as(u32, 26), part1Total);
}
