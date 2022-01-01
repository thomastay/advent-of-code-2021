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

    pub fn parent(self: Self) ?*Node {
        return switch (self) {
            .Leaf => |x| x.p,
            .Inner => |x| x.p,
        };
    }

    pub fn setParent(self: *Self, newParent: *Node) void {
        switch (self.*) {
            .Leaf => |*x| x.p = newParent,
            .Inner => |*x| x.p = newParent,
        }
    }

    pub fn isLeaf(self: Self) bool {
        return switch (self) {
            .Leaf => true,
            .Inner => false,
        };
    }
    pub fn isPair(self: Self) bool {
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
    pub fn moveLeft(self: Self) ?*LeafNode {
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

    pub fn moveRight(self: Self) ?*LeafNode {
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

    // ----------- Iterators ---------
    const NodeAndDepth = struct {
        node: *Node,
        depth: u32,
    };

    const TreePreOrderIterator = struct {
        stack: List(NodeAndDepth),

        pub fn next(self: *@This()) !?NodeAndDepth {
            if (self.stack.popOrNull()) |top| {
                switch (top.node) {
                    .Inner => |inn| {
                        try self.stack.append(.{ .node = inn.r, .depth = top.depth + 1 });
                        try self.stack.append(.{ .node = inn.l, .depth = top.depth + 1 });
                    },
                    .Leaf => continue,
                }
                return top;
            } else return null;
        }
    };

    /// Returns an iterator that walks over every node in the tree, as a pre-order traversal.
    fn treePreOrderIterator(root: *Self, allocator: Allocator) !TreePreOrderIterator {
        const stack = List(NodeAndDepth).init(Allocator);
        try stack.append(.{ .node = root, .depth = 0 });
        return TreePreOrderIterator{ .stack = stack };
    }

    pub const PairIterator = struct {
        it: TreePreOrderIterator,
        /// Returns the next pair in tree order, or null if no such pair exists.
        /// When it returns a pair, the depth field on the iterator is a 0-indexed height of the pair
        pub fn next() !?NodeAndDepth {
            while (try it.next()) |pair| {
                if (pair.node.isPair()) return pair;
            } else return null;
        }
    };

    // Iterates over all the pairs in the tree rooted at root
    pub fn pairIterator(root: *Self, allocator: Allocator) !PairIterator {
        return PairIterator{ .it = try treePreOrderIterator(root, allocator) };
    }

    pub const LeafIterator = struct {
        it: TreePreOrderIterator,

        pub fn next() !?*Node {
            while (try it.next()) |pair| {
                if (pair.node.isLeaf()) return pair.node;
            } else return null;
        }
    };

    // Iterates over all the leaves in the tree rooted at root
    pub fn leafIterator(root: *Self, allocator: Allocator) !PairIterator {
        return PairIterator{ .it = try treePreOrderIterator(root, allocator) };
    }
};

///     I                 L
/// L  L L  ----> L+1
///
fn explodePair(self: *Node, allocator: Allocator) void {
    assert(self.isPair());
    const leftVal = self.Inner.l.Leaf.val; // safe since we check above
    const rightVal = self.Inner.r.Leaf.val; // safe since we check above

    if (self.moveLeft()) |lOf| {
        lOf.val += leftVal;
    }
    if (self.moveRight()) |rOf| {
        rOf.val += rightVal;
    }
    const parent = self.Inner.p;
    // free the children
    allocator.destroy(self.Inner.l);
    allocator.destroy(self.Inner.r);
    // Overwrite self. Note that the old self is now invalid!
    self.* = Node{ .Leaf = .{
        .p = parent,
        .val = 0,
    } };
}

fn splitLeaf(self: *Node, allocator: Allocator) !void {
    assert(self.isLeaf());
    const val = self.Leaf.val;
    assert(val >= 10);
    const leftVal = val / 2;
    const rightVal = leftVal + @rem(val, 2);

    const leftLeaf = try makeLeaf(leftVal, allocator);
    const rightLeaf = try makeLeaf(rightVal, allocator);
    const parent = self.Leaf.p;

    // Overwrite self. Note that self.val / self.p are now invalid!
    self.* = Node{ .Inner = .{
        .p = parent,
        .l = leftLeaf,
        .r = rightLeaf,
    } };
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

// ----------------- Parser -----------------------

/// [[1, 0], 0]
fn parseSnailfishNumber(input: Str, allocator: Allocator) !*Node {
    // essentially this is parsing a very limited subset of JSON.
    var reader = std.io.fixedBufferStream(input).reader();
    return parseNode(&reader, allocator);
}

const SnailfishReader = std.io.FixedBufferStream(Str).Reader;

fn parseNode(reader: *SnailfishReader, allocator: Allocator) !*Node {
    const firstByte = try reader.readByte();
    return switch (firstByte) {
        '0'...'9' => try makeLeaf(firstByte - '0', allocator),
        '[' => try parsePair(reader, allocator),
        else => unreachable,
    };
}
fn parsePair(reader: *SnailfishReader, allocator: Allocator) error{ OutOfMemory, EndOfStream }!*Node {
    const firstNode = try parseNode(reader, allocator);
    assert((try reader.readByte()) == ',');
    const secondNode = try parseNode(reader, allocator);
    assert((try reader.readByte()) == ']');
    return makePair(firstNode, secondNode, allocator);
}

test "Parse" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const simple = "[1,[1,0]]";
    const res = try parseSnailfishNumber(simple, allocator);
    try std.testing.expectEqual(@as(u64, 1), res.Inner.l.Leaf.val);
    try std.testing.expectEqual(@as(u64, 1), res.Inner.r.Inner.l.Leaf.val);
    try std.testing.expectEqual(@as(u64, 0), res.Inner.r.Inner.r.Leaf.val);

    const longer = "[[[[6,0],[8,2]],[[9,0],[8,7]]],[3,[6,[8,8]]]]";
    _ = try parseSnailfishNumber(longer, allocator);
}

test "Parsed Explode Pair" {
    //          p                     p
    //       l2  p2   ==>      (l2+l)   0
    //          l  r
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const inputStr = "[7,[3,5]]";
    const p = try parseSnailfishNumber(inputStr, allocator);

    explodePair(p.Inner.r, allocator);
    try std.testing.expectEqual(@as(u64, 3 + 7), p.Inner.l.Leaf.val);
    try std.testing.expectEqual(@as(u64, 0), p.Inner.r.Leaf.val);
}

test "Parsed Split Pair" {
    //          p                     p
    //       l2  p2   ==>      (l2+l)   0
    //          l  r
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const inputStr = "[9,[3,5]]";
    var p = try parseSnailfishNumber(inputStr, allocator);
    p.Inner.l.Leaf.val += 6;

    try splitLeaf(p.Inner.l, allocator);
    try std.testing.expectEqual(@as(u64, 7), p.Inner.l.Inner.l.Leaf.val);
    try std.testing.expectEqual(@as(u64, 8), p.Inner.l.Inner.r.Leaf.val);
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

    explodePair(p2, allocator);
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

    explodePair(p32, allocator);
    try std.testing.expectEqual(@as(u64, 31 + 41), l31.Leaf.val);
    try std.testing.expectEqual(@as(u64, 43 + 42), l43.Leaf.val);
    try std.testing.expectEqual(@as(u64, 0), p21.Inner.r.Leaf.val);
}
