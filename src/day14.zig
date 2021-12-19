// polymer substitution

const inputFile = @embedFile("./input/day14.txt");
const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Str = []const u8;
const BitSet = std.DynamicBitSet;
const StrMap = std.StringHashMap;
const HashMap = std.HashMap;
const Map = std.AutoHashMap;
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

const TwoCharSubstitution = struct {
    substitute: u8,
    count: u64,

    // printf implementation
    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        if (self.count > 0 or self.substitute != 0) {
            try writer.print("({d}) -> {c}", .{ self.count, self.substitute });
        }
    }
};

const numUppercaseLetters = 26;

fn toIndex(charA: u8, charB: u8) usize {
    return (@as(usize, (charA - 'A')) * numUppercaseLetters) + (charB - 'A');
}

fn toIndexZeroBased(charA: u8, charB: u8) usize {
    return (@as(usize, charA) * numUppercaseLetters) + charB;
}

fn fromIndex(pos: usize) struct { a: u8, b: u8 } {
    const a = @intCast(u8, pos / 26) + 'A';
    const b = @intCast(u8, pos % 26) + 'A';
    return .{ .a = a, .b = b };
}

fn printSubstitutions(substitutions: []TwoCharSubstitution) void {
    for (substitutions) |sub, pos| {
        if (sub.count > 0) {
            const temp = fromIndex(pos);
            const a = temp.a;
            const b = temp.b;

            print("{c}{c}({d}) -> {c}\n", .{ a, b, sub.count, sub.substitute });
        }
    }
}

/// New algorithm thanks to my friend VVHack
/// See the old algorithm in the Git history prior to this commit
fn runSubstitutions(input: Str, allocator: Allocator, nRounds: u32) !usize {
    var substitutions = try allocator.alloc(TwoCharSubstitution, numUppercaseLetters * numUppercaseLetters);
    defer allocator.free(substitutions);
    std.mem.set(TwoCharSubstitution, substitutions, .{ .substitute = 0, .count = 0 });

    // ============= Step 1: parse ================
    var it = tokenize(u8, input, "\n");
    const initialStr = it.next().?; // the string to be substituted

    // substitution rules
    while (it.next()) |line| {
        assert(line[3] == '-'); // sanity check
        const idx = toIndex(line[0], line[1]);
        const valPos = comptime "AA -> ".len;
        substitutions[idx].substitute = line[valPos];
    }

    // ============= Step 2: generate counts ================
    const lastChar = initialStr[initialStr.len - 1]; // special case the last char as it never gets substituted
    for (initialStr) |c, i| {
        // chunk every two char
        if (i == initialStr.len - 1) break;
        const idx = toIndex(c, initialStr[i + 1]);
        substitutions[idx].count += 1;
    }

    // ============= Step 3: substitute ================
    var round: usize = 0;
    while (round < nRounds) : (round += 1) {
        // for each two character list, run the substitution and add it to the substitutionsNew
        var substitutionsNew = try allocator.dupe(TwoCharSubstitution, substitutions);
        defer allocator.free(substitutionsNew);

        for (substitutions) |substitution, pos| {
            if (substitution.count > 0 and substitution.substitute != 0) {
                // make the substitution
                const temp = fromIndex(pos);
                const charA = temp.a;
                const charB = temp.b;

                substitutionsNew[pos].count -= substitution.count;
                substitutionsNew[toIndex(charA, substitution.substitute)].count += substitution.count;
                substitutionsNew[toIndex(substitution.substitute, charB)].count += substitution.count;
            }
        }
        std.mem.swap([]TwoCharSubstitution, &substitutions, &substitutionsNew);
        // print("After round {d}\n", .{round + 1});
        // printSubstitutions(substitutions);
    }

    // ============= Step 4: count min max ================
    var counts = try allocator.alloc(usize, numUppercaseLetters);
    defer allocator.free(counts);
    std.mem.set(usize, counts, 0);

    for (substitutions) |substitute, pos| {
        const temp = fromIndex(pos);
        const charA = temp.a - 'A';
        counts[charA] += substitute.count;
    }
    counts[lastChar - 'A'] += 1;

    var max: usize = 0;
    var min: usize = std.math.maxInt(usize);
    for (counts) |val| {
        if (val != 0) {
            if (max < val) {
                max = val;
            }
            if (val < min) {
                min = val;
            }
        }
    }
    return max - min;
}

pub fn main() !void {
    // Standard boilerplate for Aoc problems
    const stdout = std.io.getStdOut().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var gpaAllocator = gpa.allocator();
    defer assert(!gpa.deinit()); // Check for memory leaks
    // var arena = std.heap.ArenaAllocator.init(gpaAllocator);
    // defer arena.deinit();
    var allocator = gpaAllocator;

    try stdout.print("Part 2:{d}\n", .{try runSubstitutions(inputFile, allocator, 40)});
}

test "Part 1 and 2" {
    const testInput =
        \\NNCB
        \\
        \\CH -> B
        \\HH -> N
        \\CB -> H
        \\NH -> C
        \\HB -> C
        \\HC -> B
        \\HN -> C
        \\NN -> C
        \\BH -> H
        \\NC -> B
        \\NB -> B
        \\BN -> B
        \\BB -> N
        \\BC -> B
        \\CC -> N
        \\CN -> C
        \\
    ;
    try std.testing.expectEqual(@as(usize, 5), try runSubstitutions(testInput, std.testing.allocator, 2));
    try std.testing.expectEqual(@as(usize, 1588), try runSubstitutions(testInput, std.testing.allocator, 10));
    try std.testing.expectEqual(@as(usize, 480563), try runSubstitutions(testInput, std.testing.allocator, 18));
}
