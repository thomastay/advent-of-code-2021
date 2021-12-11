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

// 1(2): cf
// 4(4): bcdf
// 7(3): acf
// 8(7): abcdefg

const PartOneResult = struct {
    n1: u32,
    n4: u32,
    n7: u32,
    n8: u32,
};

pub fn partOne(_: []Line) PartOneResult {
    return PartOneResult{
        .n1 = 0,
        .n4 = 0,
        .n7 = 0,
        .n8 = 0,
    };
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = &gpa.allocator;
    defer std.debug.assert(!gpa.deinit()); // no leaks

    const input = try parseInput(inputFile, allocator);
    defer allocator.free(input);

    try stdout.print("Part 1: {any}\n", .{partOne(input)});
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
                std.debug.print("{s} ", .{digits[inputCount]});
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
                std.debug.print("{s} ", .{out[inputCount]});
            }
        }
        try lines.append(Line{
            .digits = digits,
            .out = out,
        });
        std.debug.print("\n", .{});
    }
    return lines.toOwnedSlice();
}
