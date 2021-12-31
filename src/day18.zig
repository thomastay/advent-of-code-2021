/// Snailfish
/// This problem is actually a binary tree problem, despite not looking exactly like one
const inputFile = @embedFile("./input/day18.txt");
const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Str = []const u8;
const BitSet = std.DynamicBitSet;
const StrMap = std.StringHashMap;
const HashMap = std.HashMap;
const Map = std.AutoHashMap;
const PriorityQueue = std.PriorityQueue;
const assert = std.debug.assert;
const tokenize = std.mem.tokenize;
const print = std.debug.print;
const parseInt = std.fmt.parseInt;
const abs = std.math.absInt;
fn sort(comptime T: type, items: []T) void {
    std.sort.sort(T, items, {}, comptime std.sort.asc(T));
}
fn println(x: Str) void {
    print("{s}\n", .{x});
}

// Valid trees:
// L
//
//  I
// L L
//
//   I
//  I L
// L L

const LeafNode = struct {
    p: ?*Node,
    val: u64,
};
const InnerNode = struct {
    p: ?*Node,
    /// We are guaranteed a full binary tree, no inner node can have only one leaf.
    l: *Node,
    r: *Node,
};

const Node = union(enum) {
    Leaf: LeafNode,
    Inner: InnerNode,

    const Self = @This();

    fn parent(self: Self) ?*Node {
        return switch (self) {
            .Leaf => |x| x.p,
            .Inner => |x| x.p,
        };
    }

    fn setParent(self: *Self, newParent: *Node) void {
        switch (self.*) {
            .Leaf => |*x| x.p = newParent,
            .Inner => |*x| x.p = newParent,
        }
    }

    fn isLeaf(self: Self) bool {
        return switch (self) {
            .Leaf => true,
            .Inner => false,
        };
    }
    fn isPair(self: Self) bool {
        switch (self) {
            .Leaf => return false,
            .Inner => |inn| {
                return inn.l.isLeaf() and inn.r.isLeaf();
            },
        }
    }
    fn rightOf(self: *Self) *LeafNode {
        var x = self;
        while (true) {
            switch (x.*) {
                .Leaf => |*leaf| return leaf,
                .Inner => |inn| x = inn.r,
            }
        }
    }

    fn leftOf(self: *Self) *LeafNode {
        var x = self;
        while (true) {
            switch (x.*) {
                .Leaf => |*leaf| return leaf,
                .Inner => |inn| x = inn.l,
            }
        }
    }

    /// If this returns null, means that the node is currently the leftmost node
    fn moveLeft(self: Self) ?*LeafNode {
        // Walk up the parent chain until you reach the first parent with a different left child
        // from that left child, walk rightwards until you hit the end.
        var curr = &self;
        var p = self.parent();
        const leftOfParent: *Node = while (p) |x| {
            if (curr != x.Inner.l) break x.Inner.l;
            p = x.Inner.p;
            curr = x;
        } else return null; // reached the root and no left child, so return null
        return rightOf(leftOfParent);
    }

    fn moveRight(self: Self) ?*LeafNode {
        // same as moveLeft, but mirrored
        var curr = &self;
        var p = self.parent();
        const rightOfParent: *Node = while (p) |x| {
            if (curr != x.Inner.r) break x.Inner.r;
            p = x.Inner.p;
            curr = x;
        } else return null;
        return leftOf(rightOfParent);
    }
};

///     I                 L
/// L  L L  ----> L+1
///
fn explodePair(self: *Node, allocator: Allocator) !void {
    assert(self.isPair());
    const leftVal = self.Inner.l.Leaf.val; // safe since we check above
    const rightVal = self.Inner.r.Leaf.val; // safe since we check above

    if (self.moveLeft()) |lOf| {
        lOf.val += leftVal;
    }
    if (self.moveRight()) |rOf| {
        rOf.val += rightVal;
    }
    const parent = self.Inner.p.?; // exploding pairs must have a parent
    const newNode = try makeLeaf(0, allocator);

    if (self == parent.Inner.l) {
        parent.Inner.l = newNode;
    } else {
        parent.Inner.r = newNode;
    }
    // free the current node
    allocator.destroy(self);
}

fn partOne(_: Str) usize {
    return 0;
}

fn partTwo(_: Str) usize {
    return 0;
}

pub fn main() !void {
    // Standard boilerplate for Aoc problems
    const stdout = std.io.getStdOut().writer();
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // var gpaAllocator = gpa.allocator();
    // defer assert(!gpa.deinit()); // Check for memory leaks
    // var arena = std.heap.ArenaAllocator.init(gpaAllocator);
    // defer arena.deinit();
    // var allocator = arena.allocator();

    try stdout.print("Part 1: {d}Part2: {d}\n", .{ partOne(inputFile), partTwo(inputFile) });
}

fn makePair(left: *Node, right: *Node, allocator: Allocator) !*Node {
    assert(left.parent() == null);
    assert(right.parent() == null);
    var newParent = try allocator.create(Node);
    newParent.* = Node{ .Inner = .{ .p = null, .l = left, .r = right } };
    left.setParent(newParent);
    right.setParent(newParent);
    return newParent;
}

fn makeLeaf(val: u64, allocator: Allocator) !*Node {
    var x = try allocator.create(Node);
    x.* = Node{ .Leaf = .{ .p = null, .val = val } };
    return x;
}

test "Explode Pair" {
    //          p                     p
    //       l2  p2   ==>      (l2+l)   0
    //          l  r
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const l = try makeLeaf(3, allocator);
    const r = try makeLeaf(5, allocator);
    const p2 = try makePair(l, r, allocator);
    const l2 = try makeLeaf(7, allocator);
    const p = try makePair(l2, p2, allocator);

    try explodePair(p2, allocator);
    try std.testing.expectEqual(@as(u64, 3 + 7), p.Inner.l.Leaf.val);
    try std.testing.expectEqual(@as(u64, 0), p.Inner.r.Leaf.val);
}

test "Explode Pair complex" {
    //                p11
    //          p21               p22
    //       l31   p32         p33  l34
    //          l41  l42   l43   l44
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const l41 = try makeLeaf(41, allocator);
    const l42 = try makeLeaf(42, allocator);
    const p32 = try makePair(l41, l42, allocator);

    const l43 = try makeLeaf(43, allocator);
    const l44 = try makeLeaf(44, allocator);
    const p33 = try makePair(l43, l44, allocator);

    const l31 = try makeLeaf(31, allocator);
    const p21 = try makePair(l31, p32, allocator);

    const l34 = try makeLeaf(34, allocator);
    const p22 = try makePair(p33, l34, allocator);

    _ = try makePair(p21, p22, allocator);

    try explodePair(p32, allocator);
    try std.testing.expectEqual(@as(u64, 31 + 41), l31.Leaf.val);
    try std.testing.expectEqual(@as(u64, 43 + 42), l43.Leaf.val);
    try std.testing.expectEqual(@as(u64, 0), p21.Inner.r.Leaf.val);
}
