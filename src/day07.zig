// Find x such that sum of abs(xi - x) is minimized.
// In other words, find a translation such that the weighted L1 norm of the vector is minimized
// Todo: write blog post about this

const inputFile = @embedFile("./input/day07.txt");
const std = @import("std");
const Allocator = std.mem.Allocator;
// const ArrayList = std.ArrayList;
const assert = std.debug.assert;

/// Part 1
/// Simplest solution, no math knowledge required
/// Brute forces from 0 - max,
/// The distance from the current point to each other point
/// Complexity: O(n2)
fn shortestDistanceBF(numCrabsAtDist: []u32) usize {
    var bestPoint: usize = undefined;
    var bestPointFuel: usize = std.math.maxInt(usize);

    for (numCrabsAtDist) |_, i| {
        var dist: usize = 0;
        // compute distance
        for (numCrabsAtDist) |n, j| {
            dist += n * absDiff(i, j);
        }
        if (dist < bestPointFuel) {
            bestPoint = i;
            bestPointFuel = dist;
        }
    }
    return bestPointFuel;
}

/// Part 2
/// Simplest solution, no math knowledge required
/// Brute forces from 0 - max,
/// The distance from the current point to each other point
/// Complexity: O(n2)
fn shortestTriangleDistanceBF(numCrabsAtDist: []u32) usize {
    var bestPoint: usize = undefined;
    var bestPointFuel: usize = std.math.maxInt(usize);

    for (numCrabsAtDist) |_, i| {
        var dist: usize = 0;
        // compute distance
        for (numCrabsAtDist) |n, j| {
            dist += n * triangleDiff(i, j);
        }
        if (dist < bestPointFuel) {
            bestPoint = i;
            bestPointFuel = dist;
            std.debug.print("Updating best point to {d} with fuel {d}\n", .{ bestPoint, bestPointFuel });
        }
    }
    return bestPointFuel;
}

// Absolute difference of two unsigned numbers
// performs branching
fn absDiff(x: usize, y: usize) usize {
    if (x > y) return x - y;
    return y - x;
}

/// Given two numbers, compute the absolute triangle number diff between them
/// e.g. if abs(x - y) = 3, the triangle number diff is T(3) = 1 + 2 + 3 = 6
fn triangleDiff(x: usize, y: usize) usize {
    if (x > y) return triangleDiff(y, x);
    if (x == y) return 0;
    const d = y - x;
    return @divExact(d * (d + 1), 2);
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = &gpa.allocator;
    defer std.debug.assert(!gpa.deinit()); // no leaks

    const numCrabsAtDist = try parseInput(inputFile, allocator);
    defer allocator.free(numCrabsAtDist);

    try stdout.print("Part 1: {d}\nPart2: {d}\n", .{ shortestDistanceBF(numCrabsAtDist), shortestTriangleDistanceBF(numCrabsAtDist) });
}

/// Given a list of numbers
/// Returns a list of counts of each number in the range 0 - max
/// Where the max is whatever is in the input file
/// Caller is responsible for freeing memory
fn parseInput(input: []const u8, allocator: *Allocator) ![]u32 {
    // First pass: find max val
    var max: usize = 0;
    {
        var start: usize = 0;
        while (std.mem.indexOfAnyPos(u8, input, start, &.{ ',', '\n' })) |end| : (start = end + 1) {
            const val = try std.fmt.parseInt(u32, input[start..end], 10);
            if (val > max) max = val;
        }
    }
    // Allocate zeroes from 0 - max
    var result = try allocator.alloc(u32, max + 1);
    std.mem.set(u32, result, 0);
    // Second pass: fill result
    {
        var start: usize = 0;
        while (std.mem.indexOfAnyPos(u8, input, start, &.{ ',', '\n' })) |end| : (start = end + 1) {
            const val = try std.fmt.parseInt(u32, input[start..end], 10);
            result[val] += 1;
        }
    }
    return result;
}
