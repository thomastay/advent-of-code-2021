// Packet parsing

const inputFile = @embedFile("./input/day16.txt");
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
fn sort(comptime T: type, items: []T) void {
    std.sort.sort(T, items, {}, comptime std.sort.asc(T));
}
fn println(x: Str) void {
    print("{s}\n", .{x});
}

const PacketType = enum(u3) {
    Sum,
    Product,
    Minimum,
    Maximum,
    Lit,
    Greater,
    Less,
    Equal,
};

const BitStreamWithPos = struct {
    stream: std.io.BitReader(.Big, std.io.FixedBufferStream(Str).Reader),
    numBitsRead: usize,
};
const ParsePacketResult = struct {
    versionSum: usize,
    val: usize,
};

/// The packet parsing forms a state machine
/// parsePackets --> parsePacketInner <--------> parseOperator
///                                  |----------> parseLit
/// TODO write it non recursively
fn parsePackets(input: Input) !ParsePacketResult {
    // Zig comes with bit reading built in :)
    var buf = std.io.fixedBufferStream(input.items);
    var bitStream = .{
        .stream = std.io.bitReader(.Big, buf.reader()),
        .numBitsRead = 0,
    };
    // TODO:For fun, trying to write this parser non-recursively
    // var parsingState = List(PacketType).init(allocator);
    const result = try parsePacketInner(&bitStream);
    return result;
}

const PacketParseError = error{PacketIncomplete} || std.io.FixedBufferStream(Str).ReadError;
fn parsePacketInner(bitStream: *BitStreamWithPos) PacketParseError!ParsePacketResult {
    var outBits: usize = undefined;
    const version = try bitStream.stream.readBits(usize, 3, &outBits);
    if (outBits != 3) return error.PacketIncomplete;
    bitStream.numBitsRead += outBits;

    const typeId: u3 = try bitStream.stream.readBits(u3, 3, &outBits);
    if (outBits != 3) return error.PacketIncomplete;
    bitStream.numBitsRead += outBits;
    const packetType = @intToEnum(PacketType, typeId);
    switch (packetType) {
        .Lit => {
            const val = try parseLit(bitStream);
            return ParsePacketResult{ .versionSum = version, .val = val };
        },
        else => {
            const result = try parseOperator(bitStream, packetType);
            return ParsePacketResult{ .versionSum = version + result.versionSum, .val = result.val };
        },
    }
}

const litContinueMask: u5 = 0b10000;
fn parseLit(bitStream: *BitStreamWithPos) !u64 {
    var outBits: usize = undefined;
    // read 5 at a time until it starts with 0
    var result: u64 = 0;
    while (true) {
        const num = try bitStream.stream.readBits(u5, 5, &outBits);
        if (outBits != 5) return error.PacketIncomplete;
        bitStream.numBitsRead += outBits;
        const isLastBlock = (litContinueMask & num) == 0;

        // parse
        const data = ~litContinueMask & num;
        result = (result << 4) + data;
        if (isLastBlock) return result;
    }
}

/// So we don't have to allocate memory
const OperatorAccumulator = struct {
    type: PacketType,
    currVal: ?usize,

    const Self = @This();

    pub fn init(pktType: PacketType) Self {
        return Self{
            .type = pktType,
            .currVal = null,
        };
    }

    pub fn accumulate(self: *Self, val: usize) void {
        if (self.currVal) |curr| {
            switch (self.type) {
                .Sum => self.currVal = curr + val,
                .Product => self.currVal = curr * val,
                .Minimum => self.currVal = std.math.min(curr, val),
                .Maximum => self.currVal = std.math.max(curr, val),
                .Lit => unreachable,
                // TODO should find some way to make this panic if given more than two value
                .Greater => self.currVal = if (curr > val) 1 else 0,
                .Less => self.currVal = if (curr < val) 1 else 0,
                .Equal => self.currVal = if (curr == val) 1 else 0,
            }
        } else {
            self.currVal = val;
        }
    }
};

fn parseOperator(bitStream: *BitStreamWithPos, packetType: PacketType) !ParsePacketResult {
    var versionSum: usize = 0;
    var accumulator = OperatorAccumulator.init(packetType);

    var outBits: usize = undefined;
    const lengthTypeId = try bitStream.stream.readBits(u1, 1, &outBits);
    if (outBits != 1) return error.PacketIncomplete;
    bitStream.numBitsRead += outBits;

    if (lengthTypeId == 0) {
        // ============= Parse the next 15 bits as a length ================
        const len = try bitStream.stream.readBits(u15, 15, &outBits);
        if (outBits != 15) return error.PacketIncomplete;
        bitStream.numBitsRead += outBits;
        const expectedPos = bitStream.numBitsRead + len;
        while (bitStream.numBitsRead < expectedPos) {
            const result = try parsePacketInner(bitStream);
            versionSum += result.versionSum;
            accumulator.accumulate(result.val);
        }
        assert(bitStream.numBitsRead == expectedPos);
    } else {
        // ============= Parse the next 11 bits as the number of packets succeeding ================
        const numPackets = try bitStream.stream.readBits(u11, 11, &outBits);
        if (outBits != 11) return error.PacketIncomplete;
        bitStream.numBitsRead += outBits;
        var i: u11 = 0;
        while (i < numPackets) : (i += 1) {
            const result = try parsePacketInner(bitStream);
            versionSum += result.versionSum;
            accumulator.accumulate(result.val);
        }
    }
    return ParsePacketResult{ .versionSum = versionSum, .val = accumulator.currVal.? };
}

pub fn main() !void {
    // Standard boilerplate for Aoc problems
    const stdout = std.io.getStdOut().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var gpaAllocator = gpa.allocator();
    defer assert(!gpa.deinit()); // Check for memory leaks
    var arena = std.heap.ArenaAllocator.init(gpaAllocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const input = try parseInput(inputFile, allocator);
    const result = try parsePackets(input);
    try stdout.print("Part 1: {d}Part2: {d}\n", .{ result.versionSum, result.val });
}

const Input = struct {
    items: Str,
    allocator: Allocator,

    pub fn deinit(self: @This()) void {
        self.allocator.free(self.items);
    }
};
fn parseInput(input: Str, allocator: Allocator) !Input {
    var inputTrimmed = std.mem.trim(u8, input, "\n");
    var items = try allocator.alloc(u8, inputTrimmed.len / 2);
    errdefer allocator.free(items);

    // Zig comes with this built in :)
    items = try std.fmt.hexToBytes(items, inputTrimmed);
    return Input{ .items = items, .allocator = allocator };
}

test "Part 1-1" {
    var allocator = std.testing.allocator;
    const testInput = "38006F45291200";

    const input = try parseInput(testInput, allocator);
    defer input.deinit();
    try std.testing.expectEqual(@as(usize, 9), (try parsePackets(input)).versionSum);
}

test "Part 1-2" {
    var allocator = std.testing.allocator;
    const testInput = "EE00D40C823060";

    const input = try parseInput(testInput, allocator);
    defer input.deinit();
    try std.testing.expectEqual(@as(usize, 14), (try parsePackets(input)).versionSum);
}

test "Part 1-3" {
    var allocator = std.testing.allocator;
    const testInput = "8A004A801A8002F478";

    const input = try parseInput(testInput, allocator);
    defer input.deinit();
    try std.testing.expectEqual(@as(usize, 16), (try parsePackets(input)).versionSum);
}

test "Part 1-4" {
    var allocator = std.testing.allocator;
    const testInput = "620080001611562C8802118E34";

    const input = try parseInput(testInput, allocator);
    defer input.deinit();
    try std.testing.expectEqual(@as(usize, 12), (try parsePackets(input)).versionSum);
}

test "Part 1-5" {
    var allocator = std.testing.allocator;
    const testInput = "C0015000016115A2E0802F182340";

    const input = try parseInput(testInput, allocator);
    defer input.deinit();
    try std.testing.expectEqual(@as(usize, 23), (try parsePackets(input)).versionSum);
}

test "Part 1-6" {
    var allocator = std.testing.allocator;
    const testInput = "A0016C880162017C3686B18A3D4780";

    const input = try parseInput(testInput, allocator);
    defer input.deinit();
    try std.testing.expectEqual(@as(usize, 31), (try parsePackets(input)).versionSum);
}

test "Part 2-1" {
    var allocator = std.testing.allocator;
    const testInput = "C200B40A82";

    const input = try parseInput(testInput, allocator);
    defer input.deinit();
    try std.testing.expectEqual(@as(usize, 3), (try parsePackets(input)).val);
}

test "Part 2-2" {
    var allocator = std.testing.allocator;
    const testInput = "04005AC33890";

    const input = try parseInput(testInput, allocator);
    defer input.deinit();
    try std.testing.expectEqual(@as(usize, 54), (try parsePackets(input)).val);
}

test "Part 2-3" {
    var allocator = std.testing.allocator;
    const testInput = "880086C3E88112";

    const input = try parseInput(testInput, allocator);
    defer input.deinit();
    try std.testing.expectEqual(@as(usize, 7), (try parsePackets(input)).val);
}

test "Part 2-4" {
    var allocator = std.testing.allocator;
    const testInput = "CE00C43D881120";

    const input = try parseInput(testInput, allocator);
    defer input.deinit();
    try std.testing.expectEqual(@as(usize, 9), (try parsePackets(input)).val);
}

test "Part 2-5" {
    var allocator = std.testing.allocator;
    const testInput = "D8005AC2A8F0";

    const input = try parseInput(testInput, allocator);
    defer input.deinit();
    try std.testing.expectEqual(@as(usize, 1), (try parsePackets(input)).val);
}

test "Part 2-6" {
    var allocator = std.testing.allocator;
    const testInput = "F600BC2D8F";

    const input = try parseInput(testInput, allocator);
    defer input.deinit();
    try std.testing.expectEqual(@as(usize, 0), (try parsePackets(input)).val);
}

test "Part 2-7" {
    var allocator = std.testing.allocator;
    const testInput = "9C005AC2F8F0";

    const input = try parseInput(testInput, allocator);
    defer input.deinit();
    try std.testing.expectEqual(@as(usize, 0), (try parsePackets(input)).val);
}

test "Part 2-8" {
    var allocator = std.testing.allocator;
    const testInput = "9C0141080250320F1802104A08";

    const input = try parseInput(testInput, allocator);
    defer input.deinit();
    try std.testing.expectEqual(@as(usize, 1), (try parsePackets(input)).val);
}
