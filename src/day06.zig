// Lantern fish <3

const inputFile = @embedFile("./input/day06.txt");
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const assert = std.debug.assert;

// Returns a list of ages
// The input is a comma separated list of ages
fn parseInput(input: []const u8, allocator: *Allocator) !ArrayList(u8) {
    var result = ArrayList(u8).init(allocator);
    var start: usize = 0;
    while (std.mem.indexOfAnyPos(u8, input, start, &.{ ',', '\n' })) |end| : (start = end + 1) {
        const age = try std.fmt.parseInt(u8, input[start..end], 10);
        if (age < 0 or age > 8) return error.InputError;
        try result.append(age);
    }
    return result;
}
const maxLaternfishAge = 8; // 0, 1, ... 8;

// Given a list of initial lanternfish ages,
fn numLaternfishAfter(noofDays: u32, initialAges: []const u8) u64 {
    var ages = [_]u64{0} ** (maxLaternfishAge + 1);
    // partition
    for (initialAges) |age| {
        ages[age] += 1;
    }
    var day: u32 = 0;
    while (day < noofDays) : (day += 1) {
        std.mem.rotate(u64, &ages, 1);
        // all those from day 0 go to day 6 too
        ages[6] += ages[8];
    }
    // sum
    var result: u64 = 0;
    for (ages) |numInAge, age| {
        std.debug.print("For age {d}, there are {d} lanternfish\n", .{ age, numInAge });
        result += numInAge;
    }
    return result;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = &gpa.allocator;
    defer std.debug.assert(!gpa.deinit()); // no leaks

    const ages = try parseInput(inputFile, allocator);
    defer ages.deinit();
    try stdout.print("Part 1 Num lantern fish: {d}\nPart 2: {d}\n", .{ numLaternfishAfter(80, ages.items), numLaternfishAfter(256, ages.items) });
}

test "Part 1" {
    const input =
        \\3,4,3,1,2
        \\
    ;
    const ages = try parseInput(input, std.testing.allocator);
    defer ages.deinit();
    try std.testing.expectEqual(@as(u64, 26), numLaternfishAfter(18, ages.items));
    try std.testing.expectEqual(@as(u64, 5934), numLaternfishAfter(80, ages.items));
    try std.testing.expectEqual(@as(u64, 26984457539), numLaternfishAfter(256, ages.items));
}
