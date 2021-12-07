// line intersections!
const inputFile = @embedFile("./input/day05.txt");
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const assert = std.debug.assert;

fn parseU16(buf: []const u8) std.fmt.ParseIntError!u16 {
    return std.fmt.parseInt(u16, buf, 10);
}

const Point = struct {
    // consts
    const pointShift: u8 = 16;

    // data
    x: u16,
    y: u16,
};

const PointContext = struct {
    // These functions meet the Hash table implementation (it's a bit wonky, but thats how the stdlib does it too)
    pub fn hash(self: @This(), pt: Point) u64 {
        _ = self;
        return (@as(u64, pt.x) << Point.pointShift) + pt.y;
    }
    pub fn eql(self: @This(), p1: Point, p2: Point) bool {
        const v1: u64 = hash(self, p1);
        const v2: u64 = hash(self, p2);
        return v1 == v2;
    }
};

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
        if (startX == endX and startY > endY) {
            std.mem.swap(u16, &startY, &endY);
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

/// End result is that either a1 < b1 or a1 -- a2 encompasses b1 -- b2
fn swapPoints(a1: *u16, a2: *u16, b1: *u16, b2: *u16) void {
    // Leave this comment in: it shows we handle all 3 cases
    // if (*a1 < *b1) return
    if (a1.* > b1.*) {
        std.mem.swap(u16, a1, b1);
        std.mem.swap(u16, a2, b2);
    }
    if (a1.* == b1.* and a2.* < b2.*) {
        std.mem.swap(u16, a2, b2);
    }
}

const LineType = enum {
    Horizontal,
    Vertical,
};

const PointsSet = std.HashMap(Point, void, PointContext, std.hash_map.default_max_load_percentage);

fn countOverlaps(pointsSeen: *PointsSet, a1: u16, a2: u16, b1: u16, b2: u16, l1: LineSegment, l2: LineSegment, lineType: LineType) !void {
    const typeName = switch (lineType) {
        .Vertical => "Vertical",
        .Horizontal => "Horizontal",
    };
    assert(a1 <= b1);
    // Case 0: (no overlap) a2 < b1
    // a1 --------- a2       b1 ---------- b2
    if (a2 < b1) {
        return;
    }
    // Case 1: (partial overlap) b1 <= a2 and a2 < b2
    // a1 --------- b1 ===== a2 ---------- b2
    if (b1 <= a2 and a2 < b2) {
        std.debug.print("{s} Case 1: {d} -- {d} -- {d} -- {d} == {any}, {any}\n", .{ typeName, a1, b1, a2, b2, l1, l2 });
        var b1_ = b1;
        while (b1_ <= a2) : (b1_ += 1) {
            const point = switch (lineType) {
                .Vertical => Point{ .x = l1.startX, .y = b1_ },
                .Horizontal => Point{ .x = b1_, .y = l1.startY },
            };
            std.debug.print("putting point: {any}\n", .{point});
            try pointsSeen.put(point, undefined);
        }
        return;
    }
    // Case 2: (full overlap) b1 < a2 and b2 <= a2
    // a1 --------- b1 ===== b2 ---------- a2
    if (b1 < a2 and b2 <= a2) {
        std.debug.print("{s} Case 2: {d} -- {d} -- {d} -- {d}== {any}, {any}\n", .{ typeName, a1, b1, b2, a2, l1, l2 });
        var b1_ = b1;
        while (b1_ <= b2) : (b1_ += 1) {
            const point = switch (lineType) {
                .Vertical => Point{ .x = l1.startX, .y = b1_ },
                .Horizontal => Point{ .x = b1_, .y = l1.startY },
            };
            std.debug.print("putting point: {any}\n", .{point});
            try pointsSeen.put(point, undefined);
        }
        return;
    }
    unreachable;
}

// Part 1
// Straight lines simplifies this a lot, we now have that only horizontal lines can intersect with vertical lines,
// and we can never have triple intersections
// ^^ actly the above is not strictly true but lets see if it works for now
// The general solution is trickier, and involves doing cross products and there is a NLogN solution i think
// But even if we have to do that, i think the N2 solution is ok, we only have 500 lines.
fn numIntersectionsStraight(horizontalLines: []LineSegment, verticalLines: []LineSegment, allocator: *Allocator) !u32 {
    var pointsSeen = PointsSet.init(allocator);
    defer pointsSeen.deinit();

    // 1) Vertical with vertical
    for (verticalLines) |l1, i| {
        var j: usize = i + 1;
        while (j < verticalLines.len) : (j += 1) {
            var l2 = verticalLines[j];
            if (l1.startX != l2.startX) {
                continue;
            }
            var a1: u16 = l1.startY;
            var a2: u16 = l1.endY;
            var b1: u16 = l2.startY;
            var b2: u16 = l2.endY;
            swapPoints(&a1, &a2, &b1, &b2);
            try countOverlaps(&pointsSeen, a1, a2, b1, b2, l1, l2, .Vertical);
        }
    }

    for (horizontalLines) |horizontalLine, i| {
        // ------------- 2) horizontal with horizontal
        const l1 = horizontalLine; // consistent with naming above
        var j: usize = i + 1;
        while (j < horizontalLines.len) : (j += 1) {
            var l2 = horizontalLines[j];
            if (l1.startY != l2.startY) {
                continue;
            }
            var a1: u16 = l1.startX;
            var a2: u16 = l1.endX;
            var b1: u16 = l2.startX;
            var b2: u16 = l2.endX;
            swapPoints(&a1, &a2, &b1, &b2);
            try countOverlaps(&pointsSeen, a1, a2, b1, b2, l1, l2, .Horizontal);
        }

        //------------- 3) horizontal with vertical
        for (verticalLines) |verticalLine| {
            if (between(horizontalLine.startX, verticalLine.startX, horizontalLine.endX) and
                between(verticalLine.startY, horizontalLine.startY, verticalLine.endY))
            {
                std.debug.print("Case 3: {any}, {any}\n", .{ horizontalLine, verticalLine });
                const p = Point{
                    .x = verticalLine.startX,
                    .y = horizontalLine.startY,
                };
                std.debug.print("putting point: {any}\n", .{p});
                try pointsSeen.put(p, undefined);
            }
        }
    }
    return pointsSeen.count();
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = &gpa.allocator;
    defer std.debug.assert(!gpa.deinit()); // no leaks

    var lines = try parseInput(inputFile, allocator);
    defer lines.deinit();

    var horizontalLines = ArrayList(LineSegment).init(allocator);
    defer horizontalLines.deinit();
    var verticalLines = ArrayList(LineSegment).init(allocator);
    defer verticalLines.deinit();
    // Part 1
    for (lines.items) |line| {
        if (line.isHorizontal()) {
            // std.debug.print("Horizontal line {any}\n", .{line});
            try horizontalLines.append(line);
        } else if (line.isVertical()) {
            // std.debug.print("Vertical line {any}\n", .{line});
            try verticalLines.append(line);
            // } else {
            //     // std.debug.print("Regular line {any}\n", .{line});
        }
    }
    try stdout.print("Part 1 Num points cross: {d}\n", .{try numIntersectionsStraight(horizontalLines.items, verticalLines.items, allocator)});
}

test "Part 1 sample" {
    const input =
        \\0,9 -> 5,9
        \\8,0 -> 0,8
        \\9,4 -> 3,4
        \\2,2 -> 2,1
        \\7,0 -> 7,4
        \\6,4 -> 2,0
        \\0,9 -> 2,9
        \\3,4 -> 1,4
        \\0,0 -> 8,8
        \\5,5 -> 8,2
        \\
    ;
    const allocator = std.testing.allocator;
    var lines = try parseInput(input, allocator);
    defer lines.deinit();

    var horizontalLines = ArrayList(LineSegment).init(allocator);
    defer horizontalLines.deinit();
    var verticalLines = ArrayList(LineSegment).init(allocator);
    defer verticalLines.deinit();
    // Part 1
    for (lines.items) |line| {
        if (line.isHorizontal()) {
            try horizontalLines.append(line);
        } else if (line.isVertical()) {
            try verticalLines.append(line);
        }
    }
    try std.testing.expectEqual(@as(u32, 5), try numIntersectionsStraight(horizontalLines.items, verticalLines.items, allocator));
}

test "Part 1 sample extended" {
    const input =
        \\2,0 -> 2,9
        \\0,9 -> 5,9
        \\8,0 -> 0,8
        \\9,4 -> 3,4
        \\2,2 -> 2,1
        \\7,0 -> 7,4
        \\6,4 -> 2,0
        \\0,9 -> 2,9
        \\3,4 -> 1,4
        \\0,0 -> 8,8
        \\5,5 -> 8,2
        \\
    ;
    const allocator = std.testing.allocator;
    var lines = try parseInput(input, allocator);
    defer lines.deinit();

    var horizontalLines = ArrayList(LineSegment).init(allocator);
    defer horizontalLines.deinit();
    var verticalLines = ArrayList(LineSegment).init(allocator);
    defer verticalLines.deinit();
    // Part 1
    for (lines.items) |line| {
        if (line.isHorizontal()) {
            try horizontalLines.append(line);
        } else if (line.isVertical()) {
            try verticalLines.append(line);
        }
    }
    try std.testing.expectEqual(@as(u32, 8), try numIntersectionsStraight(horizontalLines.items, verticalLines.items, allocator));
}
