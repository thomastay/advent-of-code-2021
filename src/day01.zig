const std = @import("std");
// "cheat" by literally embedding the file in at compile time
// The input file
const input1 = @embedFile("./input/day01-1.txt");

fn numIncreases() !i32 {
    var start: usize = 0;
    var count: i32 = 0;
    var prevNum: i32 = std.math.maxInt(i32);
    while (std.mem.indexOfScalarPos(u8, input1, start, '\n')) |end| {
        const num = try std.fmt.parseInt(i32, input1[start..end], 10);
        if (prevNum < num) {
            count += 1;
        }
        start = end + 1;
        prevNum = num;
    }
    return count;
}

fn numIncreasesSlidingWindow(input: []const u8) !i32 {
    var start: usize = 0;
    var count: i32 = 0;
    var i: usize = 0;
    var prevSum: i32 = 0;
    var slidingWindow = [3]i32{ 0, 0, 0 };

    while (std.mem.indexOfScalarPos(u8, input, start, '\n')) |end| : (i += 1) {
        const num = try std.fmt.parseInt(i32, input[start..end], 10);
        defer start = end + 1;
        if (i < 3) {
            // initialization
            slidingWindow[i] = num;
            prevSum += num;
        } else {
            const newSum = prevSum - slidingWindow[0] + num;
            if (prevSum < newSum) count += 1;

            // slide
            slidingWindow[0] = slidingWindow[1];
            slidingWindow[1] = slidingWindow[2];
            slidingWindow[2] = num;
            prevSum = newSum;
        }
    }
    return count;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const first = try numIncreases();
    try stdout.print("Num increased: {d}\n", .{first});
    const second = try numIncreasesSlidingWindow(input1);
    try stdout.print("Sliding window increased: {d}\n", .{second});
}

test "sliding window demo" {
    // trailing newline is necessary!
    const demo =
        \\199
        \\200
        \\208
        \\210
        \\200
        \\207
        \\240
        \\269
        \\260
        \\263
        \\
    ;
    try std.testing.expectEqual(@as(i32, 5), try numIncreasesSlidingWindow(demo));
}
