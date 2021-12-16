// Cave DFS

const inputFile = @embedFile("./input/day11.txt");
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Str = []const u8;
const BitSet = std.DynamicBitSet;
const StrMap = std.StringHashMap;
const assert = std.debug.assert;
const tokenize = std.mem.tokenize;
const print = std.debug.print;
fn sort(comptime T: type, items: []T) void {
    std.sort.sort(T, items, {}, comptime std.sort.asc(T));
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

    const p1 = 0;
    const p2 = 0;
    try stdout.print("{any}\nPart1: {d}\nPart2: {d}", .{ input, p1, p2 });
}

const CaveType = enum { Big, Small };

const Input = struct {
    caves: []CaveType,
    caveNames: []Str,
    edges: [][2]usize,
    start: usize,
    end: usize,

    pub fn deinit(self: @This(), allocator: Allocator) void {
        allocator.free(self.caves);
        allocator.free(self.edges);
        allocator.free(self.caveNames);
    }

    // printf implementation
    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("Start: {s}, End: {s}\n", .{ self.caveNames[self.start], self.caveNames[self.end] });
        for (self.edges) |edge| {
            const from = self.caveNames[edge[0]];
            const to = self.caveNames[edge[1]];
            try writer.print("{s} - {s}\n", .{ from, to });
        }
    }
};

fn parseInput(input: Str, allocator: Allocator) !Input {
    var caves = ArrayList(CaveType).init(allocator);
    errdefer caves.deinit();
    var edges = ArrayList([2]usize).init(allocator);
    errdefer edges.deinit();
    var caveNames = ArrayList(Str).init(allocator);
    errdefer caveNames.deinit();
    var caveNameToNum = StrMap(usize).init(allocator);
    defer caveNameToNum.deinit();

    var start: usize = 0;
    var end: usize = 0;

    var it = tokenize(u8, input, "\n");
    while (it.next()) |line| {
        var caveIt = tokenize(u8, line, "-");
        const first = blk: {
            const name = caveIt.next().?;
            if (caveNameToNum.get(name)) |num| {
                break :blk num;
            } else {
                const num = caveNames.items.len;
                try caveNames.append(name);
                if (std.ascii.isUpper(name[0])) {
                    try caves.append(.Big);
                } else {
                    try caves.append(.Small);
                    if (std.mem.eql(u8, name, "start")) {
                        start = num;
                    } else if (std.mem.eql(u8, name, "end")) {
                        end = num;
                    }
                }
                break :blk num;
            }
        };
        const second = blk: {
            const name = caveIt.next().?;
            if (caveNameToNum.get(name)) |num| {
                break :blk num;
            } else {
                const num = caveNames.items.len;
                try caveNames.append(name);
                if (std.ascii.isUpper(name[0])) {
                    try caves.append(.Big);
                } else {
                    try caves.append(.Small);
                    if (std.mem.eql(u8, name, "start")) {
                        start = num;
                    } else if (std.mem.eql(u8, name, "end")) {
                        end = num;
                    }
                }
                break :blk num;
            }
            assert(caveIt.next() == null);
        };
        const from = std.math.min(first, second);
        const to = std.math.max(first, second);

        try edges.append([2]usize{ from, to });
    }
    return Input{
        .caves = caves.toOwnedSlice(),
        .caveNames = caveNames.toOwnedSlice(),
        .edges = edges.toOwnedSlice(),
        .start = start,
        .end = end,
    };
}

test "parse input" {
    const testInput =
        \\start-A
        \\start-b
        \\A-c
        \\A-b
        \\b-d
        \\A-end
        \\b-end
        \\
    ;
    var allocator = std.testing.allocator;
    const input = try parseInput(testInput, allocator);
    defer input.deinit(allocator);
    print("{any}\n", .{input});
}
