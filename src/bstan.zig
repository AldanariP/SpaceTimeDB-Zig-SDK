const std = @import("std");
const testing = std.testing;

fn writeSlice(w: *std.Io.Writer, slice: []const u8, len_in: ?u32) !void {
    const len: u32 = len_in orelse @intCast(slice.len);
    try w.writeAll(std.mem.asBytes(&len));
    try w.writeAll(slice);
}

const MAX_DEPTH = 10;

pub fn serialize(w: *std.Io.Writer, value: anytype) !void {
    switch (@typeInfo(@TypeOf(value))) {
        .bool, .int, .float, .@"enum", .pointer, .@"struct", .@"union", .array => try serializeInner(w, value, MAX_DEPTH),
        else => return error.UnsupportedType,
    }
}

fn serializeInner(w: *std.Io.Writer, value: anytype, depth: usize) !void {
    switch (@typeInfo(@TypeOf(value))) {
        .bool => try w.writeInt(u8, @as(u8, @intFromBool(value)), .little),
        .int => try w.writeInt(@TypeOf(value), value, .little),
        .float => try w.writeAll(std.mem.asBytes(&value)),
        .@"struct" => try w.writeStruct(value, .little),
        .@"union" => |info| {
            if (info.tag_type) |UnionTagType| {
                inline for (info.fields, 0..) |union_field, tag_idx| {
                    if (value == @field(UnionTagType, union_field.name)) {
                        try w.writeInt(u8, tag_idx, .little);
                        try serializeInner(w, @field(value, union_field.name), depth - 1);
                        return;
                    }
                }
                unreachable;
            }
            return error.UnsupportedType;
        },
        .@"enum" => try w.writeInt(u8, @intFromEnum(value), .little),
        .array => |info| switch (@typeInfo(info.child)) {
            .bool, .int, .float => {
                const slice: []const u8 = std.mem.sliceAsBytes(&value);
                try writeSlice(w, slice, @intCast(value.len));
            },
            .@"struct", .@"union", .array, .pointer => {
                try w.writeInt(u32, value.len, .little);
                for (value) |item| try serializeInner(w, item, depth - 1);
            },
            else => error.UnsupportedType,
        },
        .pointer => |info| switch (info.size) {
            .one, .slice => {
                const slice: []const u8 = value;
                try writeSlice(w, slice, null);
            },
            .many, .c => {
                const slice: [:0]const u8 = std.mem.span(value);
                try writeSlice(w, slice, null);
            },
        },
        else => unreachable,
    }
}

pub fn serializeFlush(w: *std.Io.Writer, value: anytype) !void {
    try serialize(w, value, null);
    try w.flush();
}

test "Serialize bool" {
    var buf: [1]u8 = undefined;
    var fbw: std.Io.Writer = .fixed(&buf);

    try serialize(&fbw, false);
    try testing.expectEqualSlices(u8, &.{0x00}, &buf);

    _ = fbw.consumeAll(); // reset

    try serialize(&fbw, true);
    try testing.expectEqualSlices(u8, &.{0x01}, &buf);
}

test "Serialize Unsigned Int" {
    var buf = [4]u8{ 0, 0, 0, 0 };
    var fbw: std.Io.Writer = .fixed(&buf);

    try serialize(&fbw, @as(u8, 0));
    try testing.expectEqualSlices(u8, &.{ 0, 0, 0, 0 }, &buf);

    _ = fbw.consumeAll();

    try serialize(&fbw, @as(u8, 0xFF));
    try testing.expectEqualSlices(u8, &.{ 0xFF, 0, 0, 0 }, &buf);

    _ = fbw.consumeAll();

    try serialize(&fbw, @as(u32, 0xDEADBEEF));
    try testing.expectEqualSlices(u8, &.{ 0xEF, 0xBE, 0xAD, 0xDE }, &buf);
}

test "Serialize Signed Int" {
    var buf = [4]u8{ 0, 0, 0, 0 };
    var fbw: std.Io.Writer = .fixed(&buf);

    try serialize(&fbw, @as(i8, -1));
    try testing.expectEqualSlices(u8, &.{ 0xFF, 0x00, 0x00, 0x00 }, &buf);

    _ = fbw.consumeAll();

    try serialize(&fbw, @as(i32, -300));
    try testing.expectEqualSlices(u8, &.{ 0xD4, 0xFE, 0xFF, 0xFF }, &buf);
}

test "Serialize Floats" {
    var buf = [8]u8{ 0, 0, 0, 0, 0, 0, 0, 0 };
    var fbw: std.Io.Writer = .fixed(&buf);

    try serialize(&fbw, @as(f32, 1.5));
    try testing.expectEqualSlices(u8, &.{ 0, 0, 0xC0, 0x3F, 0, 0, 0, 0 }, &buf);

    _ = fbw.consumeAll();

    try serialize(&fbw, @as(f64, -0.0));
    try testing.expectEqualSlices(u8, &.{ 0, 0, 0, 0, 0, 0, 0, 0x80 }, &buf);
}

test "Serialize String" {
    var buf = [9]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    var fbw: std.Io.Writer = .fixed(&buf);

    try serialize(&fbw, "");
    try testing.expectEqualSlices(u8, &.{ 0, 0, 0, 0, 0, 0, 0, 0, 0 }, &buf);

    _ = fbw.consumeAll();

    try serialize(&fbw, "Hello");
    try testing.expectEqualSlices(u8, &.{ 0x05, 0, 0, 0, 'H', 'e', 'l', 'l', 'o' }, &buf);

    _ = fbw.consumeAll();
    @memset(&buf, 0);

    try serialize(&fbw, std.unicode.utf8EncodeComptime(0x1F9BE)); // 🦎
    try testing.expectEqualSlices(u8, &.{ 0x04, 0, 0, 0, 0xF0, 0x9F, 0xA6, 0xBE, 0 }, &buf);
}

test "Serialize Array" {
    var buf = [_]u8{0} ** 16;
    var fbw: std.Io.Writer = .fixed(&buf);

    {
        const expected: [5]u16 = .{ 1, 2, 3, 4, 5 };
        try serialize(&fbw, expected);
        try testing.expectEqualSlices(u8, &.{ 0x05, 0, 0, 0, 0x01, 0, 0x02, 0, 0x03, 0, 0x04, 0, 0x05, 0, 0, 0 }, &buf);
    }

    _ = fbw.consumeAll();
    @memset(&buf, 0);

    {
        const expected: [2][]const u8 = .{ "W", "Zig" };
        try serialize(&fbw, expected);
        try testing.expectEqualSlices(u8, &.{ 0x02, 0, 0, 0, 0x01, 0, 0, 0, 'W', 0x03, 0, 0, 0, 'Z', 'i', 'g' }, &buf);
    }

    _ = fbw.consumeAll();
    @memset(&buf, 0);

    {
        const expected: [2][]const u8 = .{ &.{ 1, 2 }, &.{} };
        try serialize(&fbw, expected);
        try testing.expectEqualSlices(u8, &.{ 0x02, 0, 0, 0, 0x02, 0, 0, 0, 0x01, 0x02, 0, 0, 0, 0, 0, 0 }, &buf);
    }
}

test "Serialize Struct" {
    var buf: [4]u8 = .{ 0, 0, 0, 0 };
    var fbw: std.Io.Writer = .fixed(&buf);

    const S1 = extern struct {};
    try serialize(&fbw, S1{});
    try testing.expectEqualSlices(u8, &.{ 0, 0, 0, 0 }, &buf);

    _ = fbw.consumeAll();

    const S2 = packed struct { x: u8, y: u16 };
    try serialize(&fbw, S2{ .x = 10, .y = 20 });
    try testing.expectEqualSlices(u8, &.{ 10, 20, 0, 0 }, &buf);
}

test "Serialize Union" {
    var buf: [7]u8 = .{ 0, 0, 0, 0, 0, 0, 0 };
    var fbw: std.Io.Writer = .fixed(&buf);

    const S1 = union(enum) { s: extern struct {}, str: [2]u8 };

    try serialize(&fbw, S1{ .s = .{} });
    try testing.expectEqualSlices(u8, &.{ 0, 0, 0, 0, 0, 0, 0 }, &buf);

    _ = fbw.consumeAll();

    try serialize(&fbw, S1{ .str = "hi".* });
    try testing.expectEqualSlices(u8, &.{ 0x01, 0x02, 0, 0, 0, 0x68, 0x69 }, &buf);
}

fn readSlice(T: type, r: *std.Io.Reader) ![]T {
    const len = try r.takeInt(u32, .little);
    const slice = try r.take(len);
    return std.mem.bytesAsSlice(T, slice);
}

pub fn deserialize(T: type, r: *std.Io.Reader) !T {
    switch (@typeInfo(@TypeOf(T))) {
        .bool, .int, .float, .@"enum", .pointer, .@"struct", .@"union", .array => try deserializeInner(T, r, MAX_DEPTH),
        else => return error.UnsupportedType,
    }
}

fn deserializeInner(T: type, r: *std.Io.Reader, depth: usize) !T {
    return switch (@typeInfo(@TypeOf(T))) {
        .bool => switch (try r.takeByte()) {
            0x00 => false,
            0x01 => true,
            else => error.InvalidValue,  // Maybe offer a version less strict version ?
        },
        .int => try r.takeInt(T, .little),
        .float => |info| blk: {
            const bytes = try r.takeArray(@divExact(info.bits, 8));
            break :blk std.mem.bytesAsValue(T, bytes).*;
        },
        .@"enum" => @as(T, @enumFromInt(try r.takeByte())),
        .@"struct" => try r.takeStruct(T, .little),
        .@"union" => |info| blk: {
            const tag_idx = try r.takeByte();
            inline for (info.fields, 0..) |union_field, i| {
                if (i == tag_idx) {
                    const payload = try deserializeInner(union_field.type, r, depth - 1);
                    break :blk @unionInit(T, union_field, payload);
                }
            }
            unreachable;
        },
        .array => |info| blk: {
            const len = try r.takeInt(u32, .little);
            if (info.len != len) break :blk error.InvalidValue;

            const arr: T = undefined;
            for (arr) |*item| item.* = try deserializeInner(info.child, r, depth - 1);

            break :blk arr;
        },
        .pointer => |info| switch (info.size) {
            .one, .slice => readSlice(info.child, r),
            .many => readSlice(info.child, r).ptr,
            .c => error.UnsupportedType,  // I don't think it's possible to get this kind of values out of STFB as of now...
        },
        else => return error.UnsupportedType,
    };
}
