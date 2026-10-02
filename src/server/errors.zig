const std = @import("std");

pub const HostError = error{
    HOST_CALL_FAILURE,
    NOT_IN_TRANSACTION,
    BSATN_DECODE_ERROR,
    NO_SUCH_TABLE,
    NO_SUCH_INDEX,
    NO_SUCH_ITER,
    NO_SUCH_CONSOLE_TIMER,
    NO_SUCH_BYTES,
    NO_SPACE,
    WRONG_INDEX_ALGO,
    BUFFER_TOO_SMALL,
    UNIQUE_ALREADY_EXISTS,
    SCHEDULER_AT_DELAY_TOO_LONG,
    INDEX_NOT_UNIQUE,
    NO_SUCH_ROW,
    AUTO_INC_OVERFLOW,
    WOULD_BLOCK_TRANSACTION,
    TRANSACTION_NOT_ANONYMOUS,
    TRANSACTION_IS_READ_ONLY,
    TRANSACTION_IS_MUT,
    HTTP_ERROR,
};

fn errFromReturnCode(no: u16) ?HostError {
    return switch (no) {
        1  => .HOST_CALL_FAILURE,
        2  => .NOT_IN_TRANSACTION,
        3  => .BSATN_DECODE_ERROR,
        4  => .NO_SUCH_TABLE,
        5  => .NO_SUCH_INDEX,
        6  => .NO_SUCH_ITER,
        7  => .NO_SUCH_CONSOLE_TIMER,
        8  => .NO_SUCH_BYTES,
        9  => .NO_SPACE,
        10 => .WRONG_INDEX_ALGO,
        11 => .BUFFER_TOO_SMALL,
        12 => .UNIQUE_ALREADY_EXISTS,
        13 => .SCHEDULER_AT_DELAY_TOO_LONG,
        14 => .INDEX_NOT_UNIQUE,
        15 => .NO_SUCH_ROW,
        16 => .AUTO_INC_OVERFLOW,
        17 => .WOULD_BLOCK_TRANSACTION,
        18 => .TRANSACTION_NOT_ANONYMOUS,
        19 => .TRANSACTION_IS_READ_ONLY,
        20 => .TRANSACTION_IS_MUT,
        21 => .HTTP_ERROR,
        else => null
    };
}

/// This function returns an error based on the
pub fn checkErr(
    comptime AllowedErrors: type,
    rc: u16
) (AllowedErrors || error{ HOST_CALL_FAILURE, UnexpectedError, UnknownError })!void {
    if (rc == 0) return;
    if (rc == 1) return error.HOST_CALL_FAILURE;

    const master_err = errFromReturnCode(rc) orelse return error.UnknownError;

    switch (master_err) {
        inline else => |err| {
            const is_allowed = blk: {
                const error_set = @typeInfo(AllowedErrors).ErrorSet orelse @compileError("Must be an error set");
                for (error_set) |allowed_field| {
                    if (std.mem.eql(u8, allowed_field.name, @errorName(err))) {
                        break :blk true;
                    }
                }
                break :blk false;
            };

            return if (is_allowed) @errorCast(err) else error.UnexpectedError;
        }
    }
}
