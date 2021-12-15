// bracket pairing

const inputFile = @embedFile("./input/day10.txt");
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

const BracketType = enum { Round, Square, Curly, Angle };

const Score = struct {
    const round = 3;
    const square = 57;
    const curly = 1197;
    const angle = 25137;
};

fn corruptedScore(line: Str, allocator: Allocator) !usize {
    var stack = try ArrayList(BracketType).initCapacity(allocator, line.len);
    defer stack.deinit();
    for (line) |c| {
        switch (c) {
            // Opening
            '(' => stack.appendAssumeCapacity(.Round),
            '[' => stack.appendAssumeCapacity(.Square),
            '{' => stack.appendAssumeCapacity(.Curly),
            '<' => stack.appendAssumeCapacity(.Angle),
            // Closing
            ')' => {
                if (stack.popOrNull()) |last| {
                    if (last != .Round) return Score.round;
                } else {
                    return Score.round;
                }
            },
            ']' => {
                if (stack.popOrNull()) |last| {
                    if (last != .Square) return Score.square;
                } else {
                    return Score.square;
                }
            },
            '}' => {
                if (stack.popOrNull()) |last| {
                    if (last != .Curly) return Score.curly;
                } else {
                    return Score.curly;
                }
            },
            '>' => {
                if (stack.popOrNull()) |last| {
                    if (last != .Angle) return Score.angle;
                } else {
                    return Score.angle;
                }
            },
            else => unreachable,
        }
    }
    // No errors
    return 0;
}

fn partOne(input: Str, allocator: Allocator) !usize {
    var result: usize = 0;
    var it = tokenize(u8, input, "\n");
    while (it.next()) |line| {
        const score = try corruptedScore(line, allocator);
        result += score;
    }
    return result;
}

const PartTwoScore = struct {
    const round = 1;
    const square = 2;
    const curly = 3;
    const angle = 4;
};

fn incompleteScore(line: Str, allocator: Allocator) !usize {
    var stack = try ArrayList(BracketType).initCapacity(allocator, line.len);
    defer stack.deinit();
    // this for loop is basically the same as in part 1, just copy-pasted it
    // for simplicity
    for (line) |c| {
        switch (c) {
            // Opening
            '(' => stack.appendAssumeCapacity(.Round),
            '[' => stack.appendAssumeCapacity(.Square),
            '{' => stack.appendAssumeCapacity(.Curly),
            '<' => stack.appendAssumeCapacity(.Angle),
            // Closing
            ')' => {
                if (stack.popOrNull()) |last| {
                    if (last != .Round) return 0; // corrupted
                } else {
                    return 0;
                }
            },
            ']' => {
                if (stack.popOrNull()) |last| {
                    if (last != .Square) return 0;
                } else {
                    return 0;
                }
            },
            '}' => {
                if (stack.popOrNull()) |last| {
                    if (last != .Curly) return 0;
                } else {
                    return 0;
                }
            },
            '>' => {
                if (stack.popOrNull()) |last| {
                    if (last != .Angle) return 0;
                } else {
                    return 0;
                }
            },
            else => unreachable,
        }
    }
    std.mem.reverse(BracketType, stack.items);

    var result: usize = 0;
    for (stack.items) |c| {
        switch (c) {
            .Round => result = result * 5 + PartTwoScore.round,
            .Square => result = result * 5 + PartTwoScore.square,
            .Curly => result = result * 5 + PartTwoScore.curly,
            .Angle => result = result * 5 + PartTwoScore.angle,
        }
    }

    return result;
}

fn partTwo(input: Str, allocator: Allocator) !usize {
    var scores = ArrayList(usize).init(allocator);
    defer scores.deinit();

    var it = tokenize(u8, input, "\n");
    while (it.next()) |line| {
        const score = try incompleteScore(line, allocator);
        if (score != 0) {
            try scores.append(score);
        }
    }
    sort(usize, scores.items);
    return scores.items[scores.items.len / 2];
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

    const p1 = try partOne(inputFile, allocator);
    const p2 = try partTwo(inputFile, allocator);
    try stdout.print("Part1: {d}\nPart2: {d}", .{ p1, p2 });
}

test "part 1" {
    const testInput =
        \\[({(<(())[]>[[{[]{<()<>>
        \\[(()[<>])]({[<{<<[]>>(
        \\{([(<{}[<>[]}>{[]{[(<()>
        \\(((({<>}<{<{<>}{[]{[]{}
        \\[[<[([]))<([[{}[[()]]]
        \\[{[{({}]{}}([{[{{{}}([]
        \\{<[[]]>}<{[{[{[]{()[[[]
        \\[<(<(<(<{}))><([]([]()
        \\<{([([[(<>()){}]>(<<{{
        \\<{([{{}}[<[[[<>{}]]]>[]]
        \\
    ;
    var allocator = std.testing.allocator;
    const p1 = try partOne(testInput, allocator);
    try std.testing.expectEqual(@as(usize, 26397), p1);
}

test "part 2 - single" {
    const testInput = "[({(<(())[]>[[{[]{<()<>>";
    var allocator = std.testing.allocator;
    try std.testing.expectEqual(@as(usize, 288957), try incompleteScore(testInput, allocator));
}

test "part 2 - single" {
    const testInput =
        \\[({(<(())[]>[[{[]{<()<>>
        \\[(()[<>])]({[<{<<[]>>(
        \\{([(<{}[<>[]}>{[]{[(<()>
        \\(((({<>}<{<{<>}{[]{[]{}
        \\[[<[([]))<([[{}[[()]]]
        \\[{[{({}]{}}([{[{{{}}([]
        \\{<[[]]>}<{[{[{[]{()[[[]
        \\[<(<(<(<{}))><([]([]()
        \\<{([([[(<>()){}]>(<<{{
        \\<{([{{}}[<[[[<>{}]]]>[]]
        \\
    ;
    var allocator = std.testing.allocator;
    try std.testing.expectEqual(@as(usize, 288957), try partTwo(testInput, allocator));
}
