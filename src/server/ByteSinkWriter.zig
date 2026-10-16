const std = @import("std");
const Writer = std.Io.Writer;
const bindings = @import("bindings.zig");

const ByteSinkWriter = @This();

handle: u32,
err: ?bindings.SinkError,
interface: Writer,

pub fn init(handle: u32, buffer: []u8) ByteSinkWriter {
    return .{
        .handle = handle,
        .interface = .{
            .vtable = &.{
                .drain = drain
            },
            .buffer = buffer,
        }
    };
}

/// This functions doesn't try to minimize the number of sink calls, maybe optimized in the future
pub fn drain(w: *Writer, data: []const []const u8, splat: usize) Writer.Error!usize {
    const self: *ByteSinkWriter = @alignCast(@fieldParentPtr("interface", w));

    const buffered = w.buffered();
    if (buffered.len != 0) {
        const written = try self.sinkWrite(buffered);
        return w.consume(written);
    }

    for (data[0 .. data.len - 1]) |bytes| {
        if (bytes.len == 0) continue;
        return self.sinkWrite(bytes);
    }

    const pattern =  data[data.len - 1];
    if (pattern.len == 0 or splat == 0) return 0;
    return self.sinkWrite(pattern);
}

fn sinkWrite(self: *ByteSinkWriter, bytes: []const u8) Writer.Error!usize {
    const written = bindings.bytesSinkWrite(self.handle, bytes) catch |err| {
        self.err = err;
        return error.WriteFailed;
    };
    return @intCast(written); // Safe on WASM
}