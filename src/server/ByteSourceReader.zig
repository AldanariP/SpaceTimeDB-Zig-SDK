const std = @import("std");
const Writer = std.Io.Writer;
const Reader = std.Io.Reader;
const Limit = std.Io.Limit;
const Allocator = std.mem.Allocator;

const bindings = @import("bindings.zig");

const ByteSourceReader = @This();

handle: u32,
interface: Reader,

pub fn init(handle: u32, buffer: []u8) ByteSourceReader {
    return .{
        .handle = handle,
        .interface = .{
            .vtable = .{
                .stream = stream
            },
            .buffer = buffer,
            .seek = 0,
            .end = 0,
        }
    };
}

/// If this function succeeds, you should be able to read the entire payload in one read,
/// which can't fail, unless you to mess with it intentionnaly.
/// The caller is responsible for freeing the allocated reader's buffer
pub fn initAlloc(handle: u32, alloc: Allocator) !ByteSourceReader {
    // FIXME: Is there cases where this function isn't available in the host module (e.g. not latest version) ?
    const remaining = try bindings.bytesSourceRemaingingLength(handle);
    const buffer = try alloc.alloc(u8, @intCast(remaining));
    return .init(handle, buffer);
}

/// This method will hit an assert if you pass an unbuffered writer.
/// There is a workaround but at this point what are you even doing ?
pub fn stream(r: *Reader, w: *Writer, limit: Limit) Reader.StreamError!usize {
    const self: *ByteSourceReader = @alignCast(@fieldParentPtr("interface", r));
    const dest = limit.slice(try w.writableSliceGreedy(1));

    var out = dest;
    bindings.bytesSourceRead(self.handle, &out) catch |err| switch (err) {
        .NO_SUCH_BYTES => return error.ReadFailed,
        .BYTES_SOURCE_EXHAUSTED => return error.EndOfStream
    };

    w.advance(out.len);
    return out.len;
}