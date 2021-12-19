// polymer substitution

const inputFile = @embedFile("./input/day14.txt");
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
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

const TemplateKey = struct {
    keyA: u8,
    keyB: u8,

    pub fn asU64(self: @This()) u64 {
        return (@as(u64, self.keyA) << 8) + self.keyB;
    }

    // printf implementation
    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("{c}{c}", .{ self.keyA, self.keyB });
    }
};

const TemplateKeyHasher = struct {
    pub fn eql(_: @This(), left: TemplateKey, right: TemplateKey) bool {
        return left.asU64() == right.asU64();
    }
    pub fn hash(_: @This(), x: TemplateKey) u64 {
        return x.asU64();
    }
};

fn partOne(input: Str, allocator: Allocator) !usize {
    var substitutionRules = HashMap(TemplateKey, u8, TemplateKeyHasher, std.hash_map.default_max_load_percentage).init(allocator);
    defer substitutionRules.deinit();

    // ============= Step 1: parse ================
    var it = tokenize(u8, input, "\n");
    const initialStr = it.next().?; // the string to be substituted

    // substitution rules
    while (it.next()) |line| {
        assert(line[3] == '-'); // sanity check
        const key = TemplateKey{ .keyA = line[0], .keyB = line[1] };
        const valPos = comptime "AA -> ".len;
        const val = line[valPos];
        try substitutionRules.putNoClobber(key, val);
    }
    // ============= Step 2: substitute ================

    // For the initial run, don't need to duplicate memory
    var inStr = try ArrayList(u8).initCapacity(allocator, initialStr.len * 2);
    defer inStr.deinit();
    for (initialStr) |c, i| {
        inStr.appendAssumeCapacity(c);
        if (i == initialStr.len - 1) break;

        const pair = TemplateKey{ .keyA = c, .keyB = initialStr[i + 1] };
        if (substitutionRules.get(pair)) |substitution| {
            inStr.appendAssumeCapacity(substitution);
        }
    }

    var round: usize = 1;
    while (round < 40) : (round += 1) {
        print("Round: {d} with len {d}\n", .{ round, inStr.items.len });
        var outStr = try ArrayList(u8).initCapacity(allocator, inStr.items.len * 2);
        defer outStr.deinit();
        for (inStr.items) |c, i| {
            outStr.appendAssumeCapacity(c);
            if (i == inStr.items.len - 1) break; // we work in pairs

            const pair = TemplateKey{ .keyA = c, .keyB = inStr.items[i + 1] };
            if (substitutionRules.get(pair)) |substitution| {
                outStr.appendAssumeCapacity(substitution);
            }
        }
        // swap and deinit
        std.mem.swap(ArrayList(u8), &inStr, &outStr);
    }
    const finalStr = inStr.items;

    // ============= Step 3: substitute ================
    var counts = Map(u8, usize).init(allocator);
    try counts.ensureTotalCapacity(26);
    defer counts.deinit();

    for (finalStr) |c| {
        const res = counts.getOrPutAssumeCapacity(c - 'A');
        if (res.found_existing) {
            res.value_ptr.* += 1;
        } else {
            res.value_ptr.* = 1;
        }
    }
    var max: usize = 0;
    var min: usize = std.math.maxInt(usize);
    var countsIt = counts.iterator();
    while (countsIt.next()) |res| {
        const val = res.value_ptr.*;
        if (max < val) {
            max = val;
        }
        if (val < min) {
            min = val;
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

    try stdout.print("{d}\n", .{try partOne(inputFile, allocator)});
}

test "Part 1" {
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
    try std.testing.expectEqual(@as(usize, 1588), try partOne(testInput, std.testing.allocator));
}
