// Cave DFS

const inputFile = @embedFile("./input/day12.txt");
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
fn println(x: Str) void {
    print("{s}\n", .{x});
}

/// Perform a DFS on the input
fn partOne(input: Input, allocator: Allocator) !usize {
    var visited = try BitSet.initEmpty(allocator, input.caves.len);
    var path = ArrayList(usize).init(allocator);
    return try dfsRecursive(input, input.start, &visited, &path, 0);
}

/// Perform a DFS on the input
fn partTwo(input: Input, allocator: Allocator) !usize {
    var visited = try BitSet.initEmpty(allocator, input.caves.len);
    defer visited.deinit();
    var path = ArrayList(usize).init(allocator);
    defer path.deinit();
    return try dfsRecursive(input, input.start, &visited, &path, null);
}

fn dfsRecursive(input: Input, n: usize, visited: *BitSet, path: *ArrayList(usize), visitedSmallCaveTwice_: ?usize) error{OutOfMemory}!usize {
    if (n == input.end) {
        // print("Reached with path ", .{});
        // for (path.items) |pathnode| {
        //     print("{s}, ", .{input.caveNames[pathnode]});
        // }
        // println("end");
        return 1;
    }
    var visitedSmallCaveTwice = visitedSmallCaveTwice_;
    if (visited.isSet(n) and input.caves[n] == .Small) {
        if (visitedSmallCaveTwice != null) return 0;
        visitedSmallCaveTwice = n;
    }

    var result: usize = 0;
    visited.set(n);
    try path.append(n);
    for (input.adjacency[n]) |neighbor| {
        result += try dfsRecursive(input, neighbor, visited, path, visitedSmallCaveTwice);
    }
    _ = path.pop();

    // Handle the case when you visited the small cave twice, so don't unpop from visited
    if (visitedSmallCaveTwice) |caveVisited| {
        if (caveVisited == n) {
            return result;
        }
    }
    // In other cases, unpop visited.
    visited.unset(n);
    return result;
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

    const p1 = try partOne(input, allocator);
    const p2 = try partTwo(input, allocator);
    try stdout.print("{any}\nPart1: {d}\nPart2: {d}", .{ input, p1, p2 });
}

const CaveType = enum { Big, Small };
const Input = struct {
    caves: []CaveType,
    caveNames: []Str,
    adjacency: [][]usize,
    start: usize,
    end: usize,
    allocator: Allocator,

    pub fn deinit(self: @This()) void {
        self.allocator.free(self.caves);
        self.allocator.free(self.caveNames);
        for (self.adjacency) |nodes| {
            self.allocator.free(nodes);
        }
        self.allocator.free(self.adjacency);
    }

    // printf implementation
    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        for (self.adjacency) |neighbors, from| {
            try writer.print("{s} ({any}) - ", .{ self.caveNames[from], self.caves[from] });
            for (neighbors) |neighbor| {
                try writer.print("{s}, ", .{self.caveNames[neighbor]});
            }
            try writer.print("\n", .{});
        }
    }
};

fn parseInput(input: Str, allocator: Allocator) !Input {
    var caves = ArrayList(CaveType).init(allocator);
    errdefer caves.deinit();
    var caveNames = ArrayList(Str).init(allocator);
    errdefer caveNames.deinit();
    var caveNameToNum = StrMap(usize).init(allocator);
    defer caveNameToNum.deinit();
    var adjacency = ArrayList(ArrayList(usize)).init(allocator);
    defer adjacency.deinit();
    errdefer for (adjacency.items) |neighbors| {
        neighbors.deinit();
    };

    try caves.append(.Small);
    try caveNames.append("start");
    try caveNameToNum.put("start", 0);
    var start: usize = 0;
    var end: usize = 0;
    var it = tokenize(u8, input, "\n");
    while (it.next()) |line| {
        var caveIt = tokenize(u8, line, "-");
        const first = try getCaveNum(caveIt.next().?, &caveNameToNum, &caveNames, &caves, &start, &end);
        const second = try getCaveNum(caveIt.next().?, &caveNameToNum, &caveNames, &caves, &start, &end);
        assert(caveIt.next() == null);
        const from = std.math.min(first, second);
        const to = std.math.max(first, second);

        if (to >= adjacency.items.len) {
            // allocate and initialize more space
            var i = adjacency.items.len;
            try adjacency.resize(to + 1);
            while (i <= to) : (i += 1) {
                adjacency.items[i] = ArrayList(usize).init(allocator);
            }
        }
        try adjacency.items[from].append(to);
        if (from != start) {
            // one way for start (special cased)
            try adjacency.items[to].append(from);
        }
    }
    const adjacencySlices = try allocator.alloc([]usize, adjacency.items.len);
    for (adjacencySlices) |*slic, i| {
        slic.* = adjacency.items[i].toOwnedSlice();
    }
    // sanity checks
    assert(caves.items.len == caveNames.items.len);
    assert(caves.items.len == adjacencySlices.len);
    return Input{
        .caves = caves.toOwnedSlice(),
        .caveNames = caveNames.toOwnedSlice(),
        .adjacency = adjacencySlices,
        .start = start,
        .end = end,
        .allocator = allocator,
    };
}

// Helper function extracted out
fn getCaveNum(
    name: Str,
    caveNameToNum: *StrMap(usize),
    caveNames: *ArrayList(Str),
    caves: *ArrayList(CaveType),
    start: *usize,
    end: *usize,
) !usize {
    if (caveNameToNum.get(name)) |num| {
        return num;
    }
    const num = caveNames.items.len;
    try caveNames.append(name);
    try caveNameToNum.put(name, num);
    if (std.ascii.isUpper(name[0])) {
        try caves.append(.Big);
    } else {
        try caves.append(.Small);
        if (std.mem.eql(u8, name, "start")) {
            start.* = num;
        } else if (std.mem.eql(u8, name, "end")) {
            end.* = num;
        }
    }
    return num;
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
    defer input.deinit();
    print("\n{any}\n", .{input});
}

test "part 2" {
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
    defer input.deinit();
    try std.testing.expectEqual(@as(usize, 36), try partTwo(input, allocator));
}

test "part 2 Larger" {
    const testInput =
        \\dc-end
        \\HN-start
        \\start-kj
        \\dc-start
        \\dc-HN
        \\LN-dc
        \\HN-end
        \\kj-sa
        \\kj-HN
        \\kj-dc
        \\
    ;
    var allocator = std.testing.allocator;
    const input = try parseInput(testInput, allocator);
    defer input.deinit();
    try std.testing.expectEqual(@as(usize, 103), try partTwo(input, allocator));
}

test "part 2 Larger 2" {
    const testInput =
        \\fs-end
        \\he-DX
        \\fs-he
        \\start-DX
        \\pj-DX
        \\end-zg
        \\zg-sl
        \\zg-pj
        \\pj-he
        \\RW-he
        \\fs-DX
        \\pj-RW
        \\zg-RW
        \\start-pj
        \\he-WI
        \\zg-he
        \\pj-fs
        \\start-RW
        \\
    ;
    var allocator = std.testing.allocator;
    const input = try parseInput(testInput, allocator);
    defer input.deinit();
    try std.testing.expectEqual(@as(usize, 3509), try partTwo(input, allocator));
}
