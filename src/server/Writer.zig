const std = @import("std");
const bindings = @import("bindings.zig");

const ByteSinkWriter = @This();

handle: u32,
err: ?bindings.SinkError,
interface: std.Io.Writer,

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


pub fn drain(w: *ByteSinkWriter, data: []const []const u8, splat: usize) std.Io.Writer.Error!usize {
    if (data.len == 0) return 0;
    var written = bindings.bytesSinkWrite(w.handle, w.interface.buffered()) catch |err| {
        w.err = err;
        return error.WriteFailed;
    };
    w.interface.consume(written);

    for (data[0.. data.len - 1]) |bytes| {
        
    }
}