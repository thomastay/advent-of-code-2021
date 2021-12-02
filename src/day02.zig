const std = @import("std");
const inputFile = @embedFile("./input/day02.txt");

const forwardLen: usize = "forward ".len;
const upLen: usize = "up ".len;
const downLen: usize = "down ".len;

fn calcPosition(input: []const u8) !i32 {
    var start: usize = 0;
    var x: i32 = 0;
    var y: i32 = 0;
    while (std.mem.indexOfScalarPos(u8, input, start, '\n')) |end| : (start = end + 1) {
        const c = input[start];
        switch (c) {
            'f' => x += try std.fmt.parseInt(i32, input[start + forwardLen .. end], 10),
            'u' => y -= try std.fmt.parseInt(i32, input[start + upLen .. end], 10),
            'd' => y += try std.fmt.parseInt(i32, input[start + downLen .. end], 10),
            else => unreachable,
        }
    }
    return x * y;
}

fn calcPositionAim(input: []const u8) !i32 {
    var start: usize = 0;
    var x: i32 = 0;
    var y: i32 = 0;
    var aim: i32 = 0;
    while (std.mem.indexOfScalarPos(u8, input, start, '\n')) |end| : (start = end + 1) {
        const c = input[start];
        switch (c) {
            'f' => {
                const forward = try std.fmt.parseInt(i32, input[start + forwardLen .. end], 10);
                x += forward;
                y += forward * aim;
            },
            'u' => aim -= try std.fmt.parseInt(i32, input[start + upLen .. end], 10),
            'd' => aim += try std.fmt.parseInt(i32, input[start + downLen .. end], 10),
            else => unreachable,
        }
    }
    return x * y;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Height * depth = {d}\nWith aim: {d}", .{ try calcPosition(inputFile), try calcPositionAim(inputFile) });
}

test "calcPosition" {
    const input =
        \\forward 5
        \\down 5
        \\forward 8
        \\up 3
        \\down 8
        \\forward 2
        \\
    ;
    try std.testing.expectEqual(@as(i32, 150), try calcPosition(input));
}

test "calcPositionAim" {
    const input =
        \\forward 5
        \\down 5
        \\forward 8
        \\up 3
        \\down 8
        \\forward 2
        \\
    ;
    try std.testing.expectEqual(@as(i32, 900), try calcPositionAim(input));
}
