//! Translated by Claude (this is a prototype, not the final implementation):
//!
//! Zig translation of `RawModuleDefV10` and every type reachable from it.
//!
//! These types are not layout-compatible with the Rust ones. They are shaped so that
//! a generic, reflection-driven BSATN serializer following the rules below
//! produces the same bytes as the Rust `bsatn::to_vec`.
//!
//! Field and variant ORDER is part of the ABI. Names are not serialized.

/// Rust: `RawIdentifier` / `String` / `Box<str>`. A UTF-8 string.
pub const RawIdentifier = []const u8;

/// Rust: `AlgebraicTypeRef(u32)`. An index into the `Typespace`.
pub const AlgebraicTypeRef = u32;

/// Rust: `ColId(u16)`. The position of a column within a table.
pub const ColId = u16;

/// Rust: `ColList`. Serialized as an array of `ColId`.
pub const ColList = []const ColId;

/// Rust: `RawSql = Box<str>`.
pub const RawSql = []const u8;

/// Tag of the `V10` variant in the outer Rust `RawModuleDef` enum
/// (`V8BackCompat = 0`, `V9 = 1`, `V10 = 2`).
///
/// `__describe_module__` returns a `RawModuleDef`, so the BSATN of a
/// `RawModuleDefV10` must be prefixed with this byte.
pub const raw_module_def_v10_tag: u8 = 2;

// ---------------------------------------------------------------------------
// SATS type system
// ---------------------------------------------------------------------------

pub const AlgebraicType = union(enum(u8)) {
    ref: AlgebraicTypeRef,
    sum: SumType,
    product: ProductType,
    array: ArrayType,
    string,
    bool,
    i8,
    u8,
    i16,
    u16,
    i32,
    u32,
    i64,
    u64,
    i128,
    u128,
    i256,
    u256,
    f32,
    f64,
};

pub const SumType = struct {
    /// The order defines the tags of the variants at runtime.
    variants: []const SumTypeVariant,
};

pub const SumTypeVariant = struct {
    name: ?RawIdentifier,
    algebraic_type: AlgebraicType,
};

pub const ProductType = struct {
    elements: []const ProductTypeElement,
};

pub const ProductTypeElement = struct {
    name: ?RawIdentifier,
    algebraic_type: AlgebraicType,
};

/// Rust serializes `ArrayType` transparently as its element type.
pub const ArrayType = struct {
    elem_ty: *const AlgebraicType,
};

pub const Typespace = struct {
    /// The types that can be referred to with `AlgebraicTypeRef`s.
    types: []const AlgebraicType,
};

// ---------------------------------------------------------------------------
// Module definition
// ---------------------------------------------------------------------------

pub const RawModuleDefV10 = struct {
    /// Sections can appear in any order and are optional.
    sections: []const RawModuleDefV10Section,
};

/// New variants MUST be added to the END of this union, to maintain ABI compatibility.
pub const RawModuleDefV10Section = union(enum(u8)) {
    typespace: Typespace,
    types: []const RawTypeDefV10,
    tables: []const RawTableDefV10,
    reducers: []const RawReducerDefV10,
    procedures: []const RawProcedureDefV10,
    views: []const RawViewDefV10,
    schedules: []const RawScheduleDefV10,
    life_cycle_reducers: []const RawLifeCycleReducerDefV10,
    row_level_security: []const RawRowLevelSecurityDefV10,
    case_conversion_policy: CaseConversionPolicy,
    explicit_names: ExplicitNames,
    http_handlers: []const RawHttpHandlerDefV10,
    http_routes: []const RawHttpRouteDefV10,
    view_primary_keys: []const RawViewPrimaryKeyDefV10,
    submodules: []const RawSubmoduleV10,
    environment: []const RawEnvironmentDeclarationV10,
};

// --- Types ------------------------------------------------------------------

pub const RawTypeDefV10 = struct {
    source_name: RawScopedTypeNameV10,
    /// Must point to a `product` or `sum` in the module's typespace.
    ty: AlgebraicTypeRef,
    custom_ordering: bool,
};

/// A scoped type name, in the form `scope0::scope1::...::scopeN::name`.
pub const RawScopedTypeNameV10 = struct {
    scope: []const RawIdentifier,
    source_name: RawIdentifier,
};

// --- Tables -----------------------------------------------------------------

pub const RawTableDefV10 = struct {
    source_name: RawIdentifier,
    /// A reference to a `ProductType` containing the columns of this table.
    product_type_ref: AlgebraicTypeRef,
    /// Length 0 means no primary key. Length >1 is not supported.
    primary_key: ColList,
    indexes: []const RawIndexDefV10,
    constraints: []const RawConstraintDefV10,
    sequences: []const RawSequenceDefV10,
    table_type: TableType,
    table_access: TableAccess,
    default_values: []const RawColumnDefaultValueV10,
    is_event: bool,
};

pub const TableType = enum(u8) {
    system,
    user,
};

pub const TableAccess = enum(u8) {
    public,
    private,
};

pub const RawIndexDefV10 = struct {
    /// Must be supplied as `{table_name}_{column_names}_idx_{algorithm}`.
    source_name: ?RawIdentifier,
    accessor_name: ?RawIdentifier,
    algorithm: RawIndexAlgorithm,
};

/// New variants MUST be added to the END of this union, to maintain ABI compatibility.
pub const RawIndexAlgorithm = union(enum(u8)) {
    btree: struct { columns: ColList },
    hash: struct { columns: ColList },
    direct: struct { column: ColId },
};

pub const RawConstraintDefV10 = struct {
    source_name: ?RawIdentifier,
    data: RawConstraintDataV10,
};

/// Rust: `RawConstraintDataV9`.
pub const RawConstraintDataV10 = union(enum(u8)) {
    unique: RawUniqueConstraintDataV10,
};

/// Rust: `RawUniqueConstraintDataV9`.
pub const RawUniqueConstraintDataV10 = struct {
    columns: ColList,
};

pub const RawSequenceDefV10 = struct {
    source_name: ?RawIdentifier,
    column: ColId,
    /// Deprecated; should be `null`.
    start: ?i128 = null,
    /// Deprecated; should be `null`.
    min_value: ?i128 = null,
    /// Deprecated; should be `null`.
    max_value: ?i128 = null,
    /// Deprecated; should be `1`.
    increment: i128 = 1,
};

pub const RawColumnDefaultValueV10 = struct {
    col_id: ColId,
    /// A BSATN-encoded `AlgebraicValue` valid at the column's type.
    value: []const u8,
};

// --- Functions --------------------------------------------------------------

pub const FunctionVisibility = enum(u8) {
    private,
    client_callable,
};

pub const RawReducerDefV10 = struct {
    source_name: RawIdentifier,
    params: ProductType,
    visibility: FunctionVisibility,
    ok_return_type: AlgebraicType,
    err_return_type: AlgebraicType,
};

pub const RawProcedureDefV10 = struct {
    source_name: RawIdentifier,
    params: ProductType,
    return_type: AlgebraicType,
    visibility: FunctionVisibility,
};

pub const RawViewDefV10 = struct {
    source_name: RawIdentifier,
    /// The index of the view in the module's list of views.
    index: u32,
    is_public: bool,
    is_anonymous: bool,
    params: ProductType,
    return_type: AlgebraicType,
};

pub const RawViewPrimaryKeyDefV10 = struct {
    view_source_name: RawIdentifier,
    columns: []const RawIdentifier,
};

pub const RawScheduleDefV10 = struct {
    source_name: ?RawIdentifier,
    table_name: RawIdentifier,
    schedule_at_col: ColId,
    function_name: RawIdentifier,
};

pub const Lifecycle = enum(u8) {
    init,
    on_connect,
    on_disconnect,
};

pub const RawLifeCycleReducerDefV10 = struct {
    lifecycle_spec: Lifecycle,
    function_name: RawIdentifier,
};

/// Rust: `RawRowLevelSecurityDefV9`.
pub const RawRowLevelSecurityDefV10 = struct {
    sql: RawSql,
};

// --- Naming -----------------------------------------------------------------

pub const CaseConversionPolicy = enum(u8) {
    none,
    /// The SpacetimeDB default.
    snake_case,
};

pub const NameMapping = struct {
    source_name: RawIdentifier,
    canonical_name: RawIdentifier,
};

pub const ExplicitNameEntry = union(enum(u8)) {
    table: NameMapping,
    function: NameMapping,
    index: NameMapping,
    namespace: NameMapping,
};

pub const ExplicitNames = struct {
    entries: []const ExplicitNameEntry,
};

// --- HTTP -------------------------------------------------------------------

pub const RawHttpHandlerDefV10 = struct {
    source_name: RawIdentifier,
};

pub const RawHttpRouteDefV10 = struct {
    handler_function: RawIdentifier,
    method: MethodOrAny,
    path: RawIdentifier,
};

pub const MethodOrAny = union(enum(u8)) {
    any,
    method: Method,
};

/// Rust: `http::Method` (SATS name `HttpMethod`).
pub const Method = union(enum(u8)) {
    get,
    head,
    post,
    put,
    delete,
    connect,
    options,
    trace,
    patch,
    extension: []const u8,
};

// --- Submodules & environment -------------------------------------------------

pub const RawSubmoduleV10 = struct {
    /// The namespace as written in the parent module's source.
    namespace: []const u8,
    module: RawModuleDefV10,
};

pub const RawEnvVarTypeV10 = union(enum(u8)) {
    string,
    string_literal: []const u8,
    @"union": []const []const u8,
};

pub const RawEnvironmentDeclarationV10 = struct {
    name: []const u8,
    ty: RawEnvVarTypeV10,
    optional: bool,
};

test {
    @import("std").testing.refAllDecls(@This());
}
