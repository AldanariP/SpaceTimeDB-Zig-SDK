const std = @import("std");

const errors = @import("errors.zig");
const c = @import("c.zig");

// ------------ 10.0 ------------
const TableError = error{NOT_IN_TRANSACTION, NO_SUCH_TABLE};
const IndexError = error{NOT_IN_TRANSACTION, NO_SUCH_INDEX};

pub inline fn tableIdFromName(name: []const u8) TableError!u32 {
    var id: u32 = undefined;
    const rc = c.table_id_from_name(name.ptr, name.len, &id);
    try errors.checkErr(TableError, rc);
    return id;
}

pub inline fn indexIdFromName(name: []const u8) IndexError!u32 {
    var id: u32 = undefined;
    const rc = c.index_id_from_name(name.ptr, name.len, &id);
    try errors.checkErr(IndexError, rc);
    return id;
}

pub inline fn tableRowCount(table_id: u32) TableError!u64 {
    var count: u64 = undefined;
    const rc = c.datastore_table_row_count(table_id, &count);
    try errors.checkErr(TableError, rc);
    return count;
}

pub inline fn tableScanBsatn(table_id: u32) TableError!u32 {
    var iter_handle: u32 = undefined;
    const rc = c.datastore_table_scan_bsatn(table_id, &iter_handle);
    try errors.checkErr(TableError, rc);
    return iter_handle;
}

const IndexScanError = IndexError || error{WRONG_INDEX_ALGO, BSATN_DECODE_ERROR};
pub inline fn iterIndexScanRangeBsatn(
    index_id: u32,
    prefix: []const u8,
    prefix_elems: u32,
    rstart: []const u8,
    rend: []const u8,
) IndexScanError!u32 {
    var iter_handle: u32 = undefined;
    const rc = c.datastore_index_scan_range_bsatn(
        index_id,
        prefix.ptr, prefix.len,
        prefix_elems,
        rstart.ptr, rstart.len,
        rend.ptr, rend.len,
        &iter_handle,
    );
    try errors.checkErr(IndexScanError, rc);
    return iter_handle;
}

pub inline fn deleteByIndexScanRangeBsatn(
    index_id: u32,
    prefix: []const u8,
    prefix_elems: u32,
    rstart: []const u8,
    rend: []const u8,
) IndexScanError!u32 {
    var row_count: u32 = undefined;
    const rc = c.datastore_delete_by_index_scan_range_bsatn(
        index_id,
        prefix.ptr, prefix.len,
        prefix_elems,
        rstart.ptr, rstart.len,
        rend.ptr, rend.len,
        &row_count,
    );
    try errors.checkErr(IndexScanError, rc);
    return row_count;
}

const MutationError = TableError || error{BSATN_DECODE_ERROR};
pub inline fn deleteAllByEqBsatn(table_id: u32, rel: []const u8) !u32 {
    var row_count: u32 = undefined;
    const rc = c.datastore_delete_all_by_eq_bsatn(
        table_id,
        rel.ptr, rel.len,
        &row_count
    );
    try errors.checkErr(MutationError, rc);
    return row_count;
}

const IterError = error{NO_SUCH_ITER};
const IterAdvanceError = IterError || error{BUFFER_TOO_SMALL};

pub inline fn rowIterBsatnAdvance(
    iter_id: u32,
    buffer: []u8
) (IterAdvanceError || error{ITER_EXHAUSTED})!void {
    const rc = c.row_iter_bsatn_advance(iter_id, buffer.ptr, &buffer.len);
    if (rc < 0) return error.ITER_EXHAUSTED;
    try errors.checkErr(IterAdvanceError, @intCast(rc));
}

pub inline fn rowIterBsatnClose(iter_id: u32) IterError!void {
    const rc = c.row_iter_bsatn_close(iter_id);
    try errors.checkErr(IterError, rc);
}

const InsertError = MutationError || error{UNIQUE_ALREADY_EXISTS, SCHEDULE_AT_DELAY_TOO_LONG};
pub inline fn insertBsatn(table_id: u32, row: []u8) InsertError!void {
    const rc = c.datastore_insert_bsatn(table_id, row.ptr, &row.len);
    try errors.checkErr(InsertError, rc);
}

const UpdateError = InsertError || error{NO_SUCH_INDEX, INDEX_NOT_UNIQUE, NO_SUCH_ROW};
pub inline fn updateBsatn(table_id: u32, index_id: u32, row: []u8) UpdateError!void {
    const rc = c.datastore_update_bsatn(table_id, index_id, row.ptr, &row.len);
    try errors.checkErr(UpdateError, rc);
}

pub inline fn volatileNonAtomicScheduleImmediate(name: []const u8, args: []const u8) void {
    c.volatile_nonatomic_schedule_immediate(name.ptr, name.len, args.ptr, args.len);
}

const BytesError = error{NO_SUCH_BYTES};
pub const SinkError = BytesError || error{NO_SPACE};
pub inline fn bytesSinkWrite(sink_id: u32, buffer: []const u8) SinkError!u32 {
    var written: u32 = @intCast(buffer.len);
    const rc = c.bytes_sink_write(sink_id, buffer.ptr, &written);
    try errors.checkErr(SinkError, rc);
    return written;
}

pub inline fn bytesSourceRead(
    source_id: u32,
    buffer: []u8
) (BytesError || error{BYTES_SOURCE_EXHAUSTED})!void {
    const rc = c.bytes_source_read(source_id, buffer.ptr, &buffer.len);
    if (rc < 0) return error.BYTES_SOURCE_EXHAUSTED;
    try errors.checkErr(BytesError, @intCast(rc));
}

pub const LogLevel = enum(u8) {
    ERROR = 0,
    WARN,
    INFO,
    DEBUG,
    TRACE,
    PANIC = 101
};
pub inline fn log(level: LogLevel,
    scope: @EnumLiteral(),
    filename: []const u8,
    line_number: u32,
    message: []const u8,
) void {
    const tagname = @tagName(scope);
    c.console_log(
        @intFromEnum(level),
        tagname.ptr, tagname.len,
        filename.ptr, filename.len,
        line_number,
        message.ptr, message.len
    );
}

pub inline fn timerStart(name: []const u8) u32 {
    return c.console_timer_start(name.ptr, name.len);
}

const TimerError = error{NO_SUCH_CONSOLE_TIMER};
pub inline fn timerEnd(timer_id: u32) TimerError!void {
    const rc = c.console_timer_end(timer_id);
    try errors.checkErr(TimerError, rc);
}

pub inline fn identity() u32 {
    var id: u32 = undefined;
    c.identity(&id);
    return id;
}

// ------------ 10.1 ------------
pub inline fn bytesSourceRemaingingLength(source_id: u32) BytesError!u32 {
    var remaining_length: u32 = undefined;
    // the doc is ambiguous about this one, it doesn't appear to be a case where
    // it returns -1, because when a source is exhausted, it will instead throw a
    // NO_SUCH_BYTES error, so even if it's return type is i16, casting should be safe ?
    const rc = c.bytes_source_remaining_length(source_id, &remaining_length);
    try errors.checkErr(BytesError, @intCast(rc));
    return remaining_length;
}

// ------------ 10.2 ------------
const TransactionError = error{NOT_IN_TRANSACTION};
pub inline fn getJWT(connection_id: u64) TransactionError!?u32 {
    var handle: u32 = undefined;
    // even more ambiguous, I don't see why it would return -1 in any case
    const rc = c.get_jwt(&connection_id, &handle);
    try errors.checkErr(TransactionError, @intCast(rc));
    return if (handle == 0) null else handle;
}

// ------------ 10.3 ------------
pub inline fn sleepUntil(wake_at: std.Io.Timestamp) std.Io.Timestamp {
    const wake_up_time = c.procedure_sleep_until(wake_at.toMicroseconds());
    return .{ .nanoseconds = wake_up_time * std.time.ns_per_us };
}

const StartTransactionError = error{WOULD_BLOCK_TRANSACTION};
pub inline fn startMutTx() StartTransactionError!std.Io.Timestamp {
    var trans_start_time: i64 = undefined;
    const rc = c.procedure_start_mut_tx(&trans_start_time);
    try errors.checkErr(StartTransactionError, rc);
    return .{ .nanoseconds = trans_start_time * std.time.ns_per_us };
}

const TransationControlError = error{TRANSACTION_NOT_ANONYMOUS, TRANSACTION_IS_READ_ONLY};
pub inline fn commitMutTx() TransationControlError!void {
    const rc = c.procedure_commit_mut_tx();
    try errors.checkErr(TransationControlError, rc);
}

pub inline fn abortMutTx() TransationControlError!void {
    const rc = c.procedure_abort_mut_tx();
    try errors.checkErr(TransationControlError, rc);
}

const HttpError = StartTransactionError || error{BSATN_DECODE_ERROR, HTTP_ERROR};
/// Volontarly not managing the result for the caller, caller must manager their ressources.
pub inline fn httpRequest(
    request: []const u8,
    body: []const u8,
    bytes_sources: *[2]u32
) HttpError!void {
    const rc = c.procedure_http_request(
        request.ptr, request.len,
        body.ptr, body.len,
        bytes_sources
    );
    try errors.checkErr(HttpError, rc);
}

// ------------ 10.4 ------------
pub inline fn iterIndexScanPointBsatn(index_id: u32, point: []const u8) IndexScanError!u32 {
    var iter_id: u32 = undefined;
    const rc = c._index_scan_point_bstan(index_id, point.ptr, point.len, &iter_id);
    try errors.checkErr(IndexScanError, rc);
    return iter_id;
}
pub inline fn deleteByIndexScanPointBsatn(index_id: u32, point: []const u8) IndexScanError!u32 {
    var iter_id: u32 = undefined;
    const rc = c.datastore_delete_by_index_scan_point_bsatn(index_id, point.ptr, point.len, &iter_id);
    try errors.checkErr(IndexScanError, rc);
    return iter_id;
}

// ------------ 10.5 ------------
pub inline fn clearTable(table_id: u32) TableError!u64 {
    var row_count: u64 = undefined;
    const rc = c.datastore_clear(table_id, &row_count);
    try errors.checkErr(TableError, rc);
    return row_count;
}

// ------------ 10.6 ------------
const EnvError = error{HOST_CALL_FAILURE,NO_SPACE,NOT_IN_TRANSACTION};
pub inline fn envGet(key: []const u8) EnvError!?u32 {
    var source_handle: u32 = undefined;
    const rc = c.env_get(key.ptr, key.len, &source_handle);
    try errors.checkErr(EnvError, rc);
    return if (source_handle == 0) null else source_handle;
}
