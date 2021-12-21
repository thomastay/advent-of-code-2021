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

const PacketType = enum {
    Lit,
    Operator,
};
const PacketData = union(PacketType) {
    /// The literal value
    Lit: u64,
    /// Pointers into the Packet array
    Operator: []usize,
};

const Packet = struct {
    version: u3,
    data: PacketData,

    pub fn deinit(self: @This(), allocator: Allocator) void {
        switch (self.data) {
            .Lit => return,
            .Operator => |d| allocator.free(d),
        }
    }
};

const BitStreamWithPos = struct {
    stream: std.io.BitReader(.Big, std.io.FixedBufferStream(Str).Reader),
    numBitsRead: usize,
};

/// The packet parsing forms a state machine
/// parsePackets --> parsePacketInner <--------> parseOperator
///                                  |----------> parseLit
/// TODO write it non recursively
fn parsePackets(input: Input) !usize {
    // Zig comes with bit reading built in :)
    var buf = std.io.fixedBufferStream(input.items);
    var bitStream = .{
        .stream = std.io.bitReader(.Big, buf.reader()),
        .numBitsRead = 0,
    };
    // TODO:For fun, trying to write this parser non-recursively
    // var parsingState = List(PacketType).init(allocator);
    const result = try parsePacketInner(&bitStream);
    return result.versionSum;
}

const PacketParseError = error{PacketIncomplete} || std.io.FixedBufferStream(Str).ReadError;
const ParsePacketResult = struct {
    versionSum: usize,
};
fn parsePacketInner(bitStream: *BitStreamWithPos) PacketParseError!ParsePacketResult {
    var outBits: usize = undefined;
    var version = try bitStream.stream.readBits(usize, 3, &outBits);
    print("version: {d}\n", .{version});
    if (outBits != 3) return error.PacketIncomplete;
    bitStream.numBitsRead += outBits;

    const typeId = try bitStream.stream.readBits(u3, 3, &outBits);
    if (outBits != 3) return error.PacketIncomplete;
    bitStream.numBitsRead += outBits;
    const packetType: PacketType = switch (typeId) {
        4 => .Lit,
        else => .Operator,
    };
    switch (packetType) {
        .Lit => print("Literal: {d}\n", .{try parseLit(bitStream)}),
        .Operator => {
            const result = try parseOperator(bitStream);
            version += result.versionSum;
        },
    }
    return ParsePacketResult{ .versionSum = version };
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

fn parseOperator(bitStream: *BitStreamWithPos) !ParsePacketResult {
    var versionSum: usize = 0;
    var outBits: usize = undefined;

    const lengthTypeId = try bitStream.stream.readBits(u1, 1, &outBits);
    if (outBits != 1) return error.PacketIncomplete;
    bitStream.numBitsRead += outBits;

    if (lengthTypeId == 0) {
        // ============= Parse the next 15 bits as a length ================
        const len = try bitStream.stream.readBits(u15, 15, &outBits);
        if (outBits != 15) return error.PacketIncomplete;
        bitStream.numBitsRead += outBits;
        print("Parsing the next {d} bits as the number of succeeding bits\n", .{len});
        const expectedPos = bitStream.numBitsRead + len;
        while (bitStream.numBitsRead < expectedPos) {
            print("Current pos: {d} \n", .{bitStream.numBitsRead});
            const result = try parsePacketInner(bitStream);
            versionSum += result.versionSum;
        }
        assert(bitStream.numBitsRead == expectedPos);
    } else {
        // ============= Parse the next 11 bits as the number of packets succeeding ================
        const numPackets = try bitStream.stream.readBits(u11, 11, &outBits);
        if (outBits != 11) return error.PacketIncomplete;
        bitStream.numBitsRead += outBits;
        print("Parsing the next {d} packets\n", .{numPackets});
        var i: u11 = 0;
        while (i < numPackets) : (i += 1) {
            print("Parsed {d} packets \n", .{i});
            const result = try parsePacketInner(bitStream);
            versionSum += result.versionSum;
        }
    }
    return ParsePacketResult{ .versionSum = versionSum };
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
    try stdout.print("Part 1: {d}\n", .{try parsePackets(input)});
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
    try std.testing.expectEqual(@as(usize, 9), try parsePackets(input));
}

test "Part 1-2" {
    var allocator = std.testing.allocator;
    const testInput = "EE00D40C823060";

    const input = try parseInput(testInput, allocator);
    defer input.deinit();
    try std.testing.expectEqual(@as(usize, 14), try parsePackets(input));
}

test "Part 1-3" {
    var allocator = std.testing.allocator;
    const testInput = "8A004A801A8002F478";

    const input = try parseInput(testInput, allocator);
    defer input.deinit();
    try std.testing.expectEqual(@as(usize, 16), try parsePackets(input));
}

test "Part 1-4" {
    var allocator = std.testing.allocator;
    const testInput = "620080001611562C8802118E34";

    const input = try parseInput(testInput, allocator);
    defer input.deinit();
    try std.testing.expectEqual(@as(usize, 12), try parsePackets(input));
}

test "Part 1-5" {
    var allocator = std.testing.allocator;
    const testInput = "C0015000016115A2E0802F182340";

    const input = try parseInput(testInput, allocator);
    defer input.deinit();
    try std.testing.expectEqual(@as(usize, 23), try parsePackets(input));
}

test "Part 1-6" {
    var allocator = std.testing.allocator;
    const testInput = "A0016C880162017C3686B18A3D4780";

    const input = try parseInput(testInput, allocator);
    defer input.deinit();
    try std.testing.expectEqual(@as(usize, 31), try parsePackets(input));
}
