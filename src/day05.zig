// line intersections!
const inputFile = @embedFile("./input/day05.txt");
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const assert = std.debug.assert;

fn parseU16(buf: []const u8) std.fmt.ParseIntError!u16 {
    return std.fmt.parseInt(u16, buf, 10);
}

const LineSegment = struct {
    startX: u16,
    startY: u16,
    endX: u16,
    endY: u16,

    pub fn isStraightLine(self: @This()) bool {
        return self.isHorizontal() or self.isVertical();
    }

    pub fn isHorizontal(self: @This()) bool {
        return self.startY == self.endY;
    }

    pub fn isVertical(self: @This()) bool {
        return self.startX == self.endX;
    }

    // printf implementation
    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("({d} {d}) -> ({d} {d})", .{ self.startX, self.startY, self.endX, self.endY });
    }
};

fn parseInput(input: []const u8, allocator: *Allocator) !ArrayList(LineSegment) {
    var lines = ArrayList(LineSegment).init(allocator);
    errdefer lines.deinit();

    var start: usize = 0;
    while (std.mem.indexOfScalarPos(u8, input, start, '\n') != null) {
        var startX = blk: {
            const end = std.mem.indexOfScalarPos(u8, input, start, ',').?;
            const num = try parseU16(input[start..end]);
            start = end + 1;
            break :blk num;
        };
        var startY = blk: {
            const end = std.mem.indexOfScalarPos(u8, input, start, ' ').?;
            const num = try parseU16(input[start..end]);
            start = end + 1;
            break :blk num;
        };

        // skip arrow
        const arrowLen = "-> ".len;
        start += arrowLen;

        var endX = blk: {
            const end = std.mem.indexOfScalarPos(u8, input, start, ',').?;
            const num = try parseU16(input[start..end]);
            start = end + 1;
            break :blk num;
        };
        var endY = blk: {
            const end = std.mem.indexOfScalarPos(u8, input, start, '\n').?;
            const num = try parseU16(input[start..end]);
            start = end + 1;
            break :blk num;
        };
        // Sort the endpoints to make our lives easier
        if (startX == endX) {
            startY = std.math.min(startY, endY);
            endY = std.math.max(startY, endY);
        } else if (startX > endX) {
            std.mem.swap(u16, &startX, &endX);
            std.mem.swap(u16, &startY, &endY);
        }
        try lines.append(.{
            .startX = startX,
            .startY = startY,
            .endX = endX,
            .endY = endY,
        });
    }
    return lines;
}

fn between(x: u16, y: u16, z: u16) bool {
    if (x < z) {
        return x <= y and y <= z;
    } else {
        return z <= y and y <= x;
    }
}

// Part 1
// Straight lines simplifies this a lot, we now have that only horizontal lines can intersect with vertical lines,
// and we can never have triple intersections
// ^^ actly the above is not strictly true but lets see if it works for now
// The general solution is trickier, and involves doing cross products and there is a NLogN solution i think
// But even if we have to do that, i think the N2 solution is ok, we only have 500 lines.
fn numIntersectionsStraight(horizontalLines: []LineSegment, verticalLines: []LineSegment) u32 {
    var result: u32 = 0;
    for (horizontalLines) |horizontalLine| {
        for (verticalLines) |verticalLine| {
            if (between(horizontalLine.startX, verticalLine.startX, horizontalLine.endX) and
                between(verticalLine.startY, horizontalLine.startY, verticalLine.endY))
            {
                result += 1;
            }
        }
    }
    return result;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = &gpa.allocator;
    defer std.debug.assert(!gpa.deinit()); // no leaks

    var lines = try parseInput(inputFile, allocator);
    defer lines.deinit();

    // Part 1
    var horizontalLines = ArrayList(LineSegment).init(allocator);
    defer horizontalLines.deinit();
    var verticalLines = ArrayList(LineSegment).init(allocator);
    defer verticalLines.deinit();

    for (lines.items) |line| {
        if (line.isHorizontal()) {
            std.debug.print("Horizontal line {any}\n", .{line});
            try horizontalLines.append(line);
        } else if (line.isVertical()) {
            std.debug.print("Vertical line {any}\n", .{line});
            try verticalLines.append(line);
        } else {
            std.debug.print("Regular line {any}\n", .{line});
        }
    }
    try stdout.print("Part 1 Num points cross: {d}\n", .{numIntersectionsStraight(horizontalLines.items, verticalLines.items)});
}
