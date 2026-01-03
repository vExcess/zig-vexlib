const std = @import("std");
const vexlib = @import("./vexlib.zig");

const Time = @This();

pub const micros = if (vexlib.wasmFreestanding)
    (struct {
        pub extern fn micros() i64;
    }).micros
else
    (struct {
        fn micros() i64 {
            return std.time.microTimestamp();
        }
    }).micros;

pub fn millis() i64 {
    return @divTrunc(Time.micros(), 1000);
}

pub fn seconds() f64 {
    return @as(f64, @floatFromInt(Time.millis() / 1000));
}