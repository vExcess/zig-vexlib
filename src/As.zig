inline fn genCastFn(comptime T: type, trunc: bool) fn(anytype) T {
    return struct {
        fn func(num: anytype) T {
            switch (@typeInfo(@TypeOf(num))) {
                .comptime_int, .int => {
                    // input is integer
                    switch (@typeInfo(T)) {
                        .int => {
                            // output is integer
                            if (trunc) {
                                return @truncate(num);
                            } else {
                                return @intCast(num);
                            }
                        },
                        .float => {
                            // output is float
                            return @floatFromInt(num);
                        },
                        else => @compileError("Cast only accepts numbers")
                    }
                },
                .comptime_float, .float => {
                    // input is float
                    switch (@typeInfo(T)) {
                        .int => {
                            // output is integer
                            if (trunc) {
                                return @truncate(num);
                            } else {
                                return @intFromFloat(num);
                            }
                        },
                        .float => {
                            // output is float
                            return @floatCast(num);
                        },
                        else => @compileError("Cast only accepts numbers")
                    }
                },
                else => @compileError("Cast only accepts numbers")
            }
        }
    }.func;
}

pub const @"f16"  = genCastFn(f16, false);
pub const @"f32"  = genCastFn(f32, false);
pub const @"f64"  = genCastFn(f64, false);
pub const @"f80"  = genCastFn(f80, false);
pub const @"f128" = genCastFn(f128, false);

pub const @"u8"  = genCastFn(u8, false);
pub const @"u16" = genCastFn(u16, false);
pub const @"u32" = genCastFn(u32, false);
pub const @"u64" = genCastFn(u64, false);
pub const @"usize" = genCastFn(usize, false);

pub const @"i8"  = genCastFn(i8, false);
pub const @"i16" = genCastFn(i16, false);
pub const @"i32" = genCastFn(i32, false);
pub const @"i64" = genCastFn(i64, false);

pub const @"u8T"  = genCastFn(u8, true);
pub const @"u16T" = genCastFn(u16, true);
pub const @"u32T" = genCastFn(u32, true);
pub const @"u64T" = genCastFn(u64, true);

pub const @"i8T"  = genCastFn(i8, true);
pub const @"i16T" = genCastFn(i16, true);
pub const @"i32T" = genCastFn(i32, true);
pub const @"i64T" = genCastFn(i64, true);

pub fn sliceCast(comptime newChildType: type, slc: anytype) []newChildType {
    const slcTypeInfo = @typeInfo(@TypeOf(slc));
    const newChildTypeInfo = @typeInfo(newChildType);
    var newLen: usize = 0;
    switch (@TypeOf(slc)) {
        []i8, []u8, []i16, []u16, []i32, []u32, []i64, []u64, []i128, []u128, []isize, []usize => {
            const slcChildTypeInfo = @typeInfo(slcTypeInfo.pointer.child);
            newLen = slc.len * slcChildTypeInfo.int.bits / switch (newChildTypeInfo) {
                .int => newChildTypeInfo.int.bits,
                .float => newChildTypeInfo.float.bits,
                else => @panic("sliceCast doesn't support the provided types")
            };
        },
        []f32, []f64 => {
            const slcChildTypeInfo = @typeInfo(slcTypeInfo.pointer.child);
            newLen = slc.len * slcChildTypeInfo.float.bits / switch (newChildTypeInfo) {
                .int => newChildTypeInfo.int.bits,
                .float => newChildTypeInfo.float.bits,
                else => @panic("sliceCast doesn't support the provided types")
            };
        },
        else => {
            @panic("sliceCast doesn't support the provided types");
        }
    }
    const newSlc = @as([*]newChildType, @ptrCast(@alignCast(slc.ptr)))[0..newLen];
    return newSlc;
}