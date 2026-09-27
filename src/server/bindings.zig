// up to date doc is here: https://github.com/clockworklabs/SpacetimeDB/blob/master/crates/bindings-sys/src/lib.rs

/// SPACETIME_10.0
extern "spacetime_10.0" fn table_id_from_name(name_ptr: u32, name_len: u32, out_id_ptr: u32) u16;
extern "spacetime_10.0" fn index_id_from_name(name_ptr: u32, name_len: u32, out_id_ptr: u32) u16;

extern "spacetime_10.0" fn datastore_table_row_count(table_id: u32, out_count: u64) u16;
extern "spacetime_10.0" fn datastore_table_scan_bsatn(table_id: u32, out_row_iter_ptr: u32) u16;
extern "spacetime_10.0" fn datastore_index_scan_range_bsatn(index_id: u32, prefix_ptr: u32, prefix_len: u32, prefix_elem: u32, rstart_ptr: u32, rstart_len: u32, rend_ptr: u32, rend_len: u32, out_row_iter_ptr: u32) u16;
extern "spacetime_10.0" fn datastore_delete_by_index_scan_range_bsatn(index_id: u32, prefix_ptr: u32, prefix_len: u32, prefix_elem: u32, rstart_ptr: u32, rstart_len: u32, rend_ptr: u32, rend_len: u32, out_row_iter_ptr: u32) u16;
extern "spacetime_10.0" fn datastore_delete_all_by_eq_bsatn(table_id: u32, rel_ptr: u32, rel_len: u32, out_row_count_ptr: u32) u16;
extern "spacetime_10.0" fn datastore_insert_bsatn(table_id: u32, row_ptr: u32, row_len_ptr: u32) u16;
extern "spacetime_10.0" fn datastore_update_bsatn(table_id: u32, index_id: u32, row_ptr: u32, row_len_ptr: u32) u16;

extern "spacetime_10.0" fn row_iter_bsatn_advance(iter_ptr: u32, buffer_ptr: u32, buffer_len_ptr: u32) i16;
extern "spacetime_10.0" fn row_iter_bsatn_close(iter_ptr: u32) u16;

extern "spacetime_10.0" fn bytes_sink_write(sink_ptr: u32, buffer_ptr: u32, buffer_len_ptr: u32, args_len: u32) i16;
extern "spacetime_10.0" fn bytes_source_read(source_ptr: u32, buffer_ptr: u32, buffer_len_ptr: u32, args_len: u32) i16;

extern "spacetime_10.0" fn console_log(level: u8, target_ptr: u32, target_len: u32, filename_ptr: u32, filename_len: u32, line_number: u32, message_ptr: u32, message_len: u32) void;
extern "spacetime_10.0" fn console_timer_start(name_ptr: u8, name_len: u32) u32;
extern "spacetime_10.0" fn console_timer_end(timer_id: u8) u16;

extern "spacetime_10.0" fn identity(out_ptr: u32) void;

extern "spacetime_10.0" fn volatille_nonatomic_schedule_immediate(name_ptr: u32, name_len: u32, args_ptr: u32, args_len: u32) void;

/// SPACETIME 10.1
extern "spacetime_10.1" fn bytes_source_remaining_length(source_ptr: u32, out_ptr: u32) i16;

/// SPACETIME 10.2
extern "spacetime_10.2" fn get_jwt(connection_id_ptr: u32, byte_source_id: u32) i16;

/// SPACETIME 10.3
extern "spacetime_10.3" fn procedure_sleep_until(wake_at_micros_since_unix_epoch: i64) i64;
extern "spacetime_10.3" fn procedure_start_mut_tx(out: i64) u16;
extern "spacetime_10.3" fn procedure_commit_mut_tx() u16;
extern "spacetime_10.3" fn procedure_abort_mut_tx() u16;
extern "spacetime_10.3" fn procedure_http_request(request_ptr: u32, request_len: u32, body_ptr: u32, body_len: u32, out_ptr1: u32, out_ptr2: u32) u16;

/// SPACETIME 10.4
extern "spacetime_10.4" fn datastore_index_scan_point_bsatn(index_id: u32, point_ptr: u32, point_len: u32, out_row_iter_ptr: u32) u16;
extern "spacetime_10.4" fn datastore_delete_by_index_scan_point_bsatn(index_id: u32, point_ptr: u32, point_len: u32, out_row_iter_ptr: u32) u16;

/// SPACETIME 10.5
extern "spacetime_10.5" fn datastore_clear(table_id: u32, out_row_count_ptr: u32) u16;

/// SPACETIME 10.6
extern "spacetime_10.6" fn env_get(key_ptr: u32, key_len: u32, out_bytes_soucre_ptr: u32) u16;
