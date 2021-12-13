// bingo!
const inputFile = @embedFile("./input/day04.txt");
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const assert = std.debug.assert;

fn parseU32(buf: []const u8) std.fmt.ParseIntError!u32 {
    return std.fmt.parseInt(u32, buf, 10);
}

const BingoBoard = struct {
    const rowLen = 5;
    const boardLen = rowLen * rowLen;

    nums: [boardLen]u32,
    hits: [boardLen]bool = [_]bool{false} ** boardLen,

    // Returns true if the hit caused a win condition
    pub fn hit(self: *@This(), val: u32) bool {
        for (self.nums) |num, i| {
            if (num == val) {
                self.hits[i] = true;
                return self.checkWin(i);
            }
        }
        return false;
    }

    pub fn checkWin(self: @This(), x: usize) bool {
        const row = @divFloor(x, rowLen);
        const col = x % rowLen;
        // Check row
        const rowHit = std.mem.allEqual(bool, self.hits[(row * rowLen) .. (row + 1) * rowLen], true);
        if (rowHit) return true;
        // Check col
        var result = true;
        var i: usize = 0;
        while (i < rowLen) : (i += 1) {
            if (!self.hits[i * rowLen + col]) {
                result = false;
            }
        }
        if (result) return true;
        return false;
    }

    pub fn countUnmarked(self: @This()) u32 {
        // Count unmarked values * val
        var result: u32 = 0;
        for (self.nums) |num, i| {
            if (!self.hits[i]) {
                result += num;
            }
        }
        return result;
    }

    // printf implementation
    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        // print it in a board
        try writer.writeByte('\n');
        var row: usize = 0;
        while (row < rowLen) : (row += 1) {
            var col: usize = 0;
            while (col < rowLen) : (col += 1) {
                const isHit = self.hits[row * rowLen + col];
                const c = if (isHit) @as(u8, '.') else @as(u8, ' ');
                try std.fmt.format(writer, "{d: <2}{c} ", .{ self.nums[row * rowLen + col], c });
            }
            try writer.writeByte('\n');
        }
    }
};

const BingoInput = struct {
    nums: ArrayList(u32),
    boards: ArrayList(BingoBoard),

    pub fn deinit(self: @This()) void {
        self.nums.deinit();
        self.boards.deinit();
    }
};

fn parseInput(input: []const u8, allocator: Allocator) !BingoInput {
    var nums = ArrayList(u32).init(allocator);
    errdefer nums.deinit();
    var boards = ArrayList(BingoBoard).init(allocator);
    errdefer boards.deinit();

    // --------- Step 1: Parse a set of numbers ----------
    // First line of input is a comma separated list of numbers
    var start: usize = 0;
    while (true) {
        // must succeed if not there is a bug in input
        const end = std.mem.indexOfAnyPos(u8, input, start, &.{ '\n', ',' }).?;
        defer start = end + 1;
        if (input[end] == '\n') break;
        // comma
        // std.debug.print("Parsing: {s} start {d} end {d} endChar {c}\n", .{ input[start..end], start, end, input[end] });
        const num = try parseU32(input[start..end]);
        try nums.append(num);
    }
    // skip the extra newline that is here
    assert(input[start] == '\n');
    start += 1;

    // --------- Step 2: Parse the boards ----------
    // now that nums is filled out, begin parsing each board
    while (start < input.len) {
        // Parse a single board in this loop
        var boardNums = [_]u32{1000} ** 25;
        var row: usize = 0;
        var col: usize = 0;

        while (row < 5) {
            switch (input[start]) {
                ' ' => start += 1,
                '\n' => {
                    start += 1;
                    row += 1;
                    col = 0;
                },
                '0'...'9' => {
                    // a number is anything that is not a space
                    // start with a non space, skip to the space, then parse
                    const end = std.mem.indexOfAnyPos(u8, input, start, &.{ '\n', ' ' }).?;
                    const num = try parseU32(input[start..end]);
                    boardNums[row * 5 + col] = num;
                    col += 1;
                    start = end; // next round, start on the delimter and let the loop take care of it
                },
                else => unreachable,
            }
        }
        const board = BingoBoard{ .nums = boardNums };
        try boards.append(board);

        // final newline
        if (start == input.len) break;

        // skip the extra newline at the end of each board
        assert(input[start] == '\n');
        start += 1;
    }
    return BingoInput{
        .nums = nums,
        .boards = boards,
    };
}

fn playBingo(bingo: *BingoInput, returnFirstWinner: bool) u32 {
    for (bingo.nums.items) |num| {
        // Each round of bingo

        var boardNum: usize = 0;
        while (boardNum < bingo.boards.items.len) {
            var board = &bingo.boards.items[boardNum];
            if (board.hit(num)) {
                if (returnFirstWinner) {
                    const unmarked = board.countUnmarked();
                    return unmarked * num;
                } else if (bingo.boards.items.len == 1) {
                    // Final board
                    const unmarked = board.countUnmarked();
                    return unmarked * num;
                } else {
                    _ = bingo.boards.orderedRemove(boardNum);
                    // don't increment boardNum
                }
            } else {
                boardNum += 1;
            }
        }
    }
    @panic("Bingo must have a winner, right...? haha");
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = &gpa.allocator;
    defer std.debug.assert(!gpa.deinit()); // no leaks

    var bingo = try parseInput(inputFile, allocator);
    defer bingo.deinit();

    // try stdout.print("Part 1: sum unmarked * final num: {d}\n", .{ playBingo(&bingo, true), playBingo(&bingo, false) });
    try stdout.print("Part2: sum unmarked * final num: {d}\n", .{playBingo(&bingo, false)});
}

test "Final winner" {
    const input =
        \\7,4,9,5,11,17,23,2,0,14,21,24,10,16,13,6,15,25,12,22,18,20,8,19,3,26,1
        \\
        \\22 13 17 11  0
        \\ 8  2 23  4 24
        \\21  9 14 16  7
        \\ 6 10  3 18  5
        \\ 1 12 20 15 19
        \\
        \\ 3 15  0  2 22
        \\ 9 18 13 17  5
        \\19  8  7 25 23
        \\20 11 10 24  4
        \\14 21 16 12  6
        \\
        \\14 21 17 24  4
        \\10 16 15  9 19
        \\18  8 23 26 20
        \\22 11 13  6  5
        \\ 2  0 12  3  7
        \\
    ;
    var bingo = try parseInput(input, std.testing.allocator);
    defer bingo.deinit();
    try std.testing.expectEqual(@as(u32, 1924), playBingo(&bingo, false));
}
