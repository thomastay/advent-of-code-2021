/// Trick Shot
/// Part 1 of this problem can be solved entirely on a calculator.
/// The trick is to notice that the x coordinates and y coordinates are completely independent
/// So we really only need to consider the initial y velocity in finding the highest y value
/// The second point to note is that the y value increases up until T(initialY), where T(n) is the nth triangular number.
/// Moreover, it decreases at exactly the same rate, which means that it will always hit the y axis.
/// The highest velocity that it can be going when it hits the y axis is the lowest y coordinate of the target box,
/// so that sets an upper bound on the initial velocity, which must be (lowest y coordinate - 1).
/// This upper bound is tight, and to show that I will produce a velocity where initialY = lowestYCoordinate - 1
/// To do so, simply solve for some x where T(x) in [lowestX, highestX]. I claim that the initial of (x, lowestYCoordinate - 1)
/// will always hit the target box as long as (lowestY > x). Simply plot the curve and you will see why.
const partOne = 133 * 134 / 2;

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

const TargetBox = struct {
    startX: i32,
    endX: i32,
    startY: i32,
    endY: i32,
};
const inputFile = TargetBox{
    .startX = 175,
    .endX = 227,
    .startY = -134,
    .endY = -79,
};

/// Solves for the smallest y where T(y) >= x
fn inverseTriangularGeq(x: i32) i32 {
    assert(x >= 0);
    // n^2 + n - 2*x = 0;
    // real solution for n is (-1 + sqrt(1 + 8 * x)) / 2.0
    const n: f32 = (@sqrt(@intToFloat(f32, 1 + 8 * x)) - 1.0) / 2.0;
    return @floatToInt(i32, @ceil(n));
}

/// Simulates a single run of whether 
fn doesHitTargetBox(target: TargetBox, initialX: i32, initialY: i32) bool {
    var x = initialX;
    var vx = initialX;
    var y = initialY;
    var vy = initialY;
    while (true) {
        // bounds check
        if (x > target.endX or y < target.startY) return false;
        if (x >= target.startX and x <= target.endX and y >= target.startY and y <= target.endY) return true;

        if (vx > 0) vx -= 1;
        vy -= 1;
        x += vx;
        y += vy;
    }
}

fn partTwo(target: TargetBox) usize {
    // search in the range that is reachable in min 2 steps
    // the range of 1 step is easily computable

    // we use divTrunc because we want 2x > -135
    const minY = @divTrunc(target.startY + 1, 2);
    const maxY = (abs(target.startY) catch unreachable) - 1;
    const minX = inverseTriangularGeq(target.startX);
    const maxX = @divFloor(target.endX, 2) + 1;

    var result = @intCast(usize, (target.endX - target.startX + 1) * (target.endY - target.startY + 1));
    var x = minX;
    while (x <= maxX) : (x += 1) {
        var y = minY;
        while (y <= maxY) : (y += 1) {
            if (doesHitTargetBox(target, x, y)) {
                result += 1;
            }
        }
    }
    return result;
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

    try stdout.print("Part 1: {d}Part2: {d}\n", .{ partOne, partTwo(inputFile) });
}

test "Part 2" {
    const testInput = TargetBox{
        .startX = 20,
        .endX = 30,
        .startY = -10,
        .endY = -5,
    };
    try std.testing.expectEqual(@as(usize, 112), partTwo(testInput));
}
