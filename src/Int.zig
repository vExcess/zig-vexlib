const Math = @import("./Math.zig");
const String = @import("./String.zig");

const Int = @This();

pub const MAX = struct {
    pub const @"u8"  = Math.comptime_pow(2, 8) - 1;
    pub const @"u16" = Math.comptime_pow(2, 16) - 1;
    pub const @"u32" = Math.comptime_pow(2, 32) - 1;
    pub const @"u64" = Math.comptime_pow(2, 64) - 1;

    pub const @"i8"  = Math.comptime_pow(2, 8 - 1) - 1;
    pub const @"i16" = Math.comptime_pow(2, 16 - 1) - 1;
    pub const @"i32" = Math.comptime_pow(2, 32 - 1) - 1;
    pub const @"i64" = Math.comptime_pow(2, 64 - 1) - 1;
};

pub const MIN = struct {
    pub const @"u8"  = 0;
    pub const @"u16" = 0;
    pub const @"u32" = 0;
    pub const @"u64" = 0;

    pub const @"i8"  = -Math.comptime_pow(2, 8 - 1);
    pub const @"i16" = -Math.comptime_pow(2, 16 - 1);
    pub const @"i32" = -Math.comptime_pow(2, 32 - 1);
    pub const @"i64" = -Math.comptime_pow(2, 64 - 1);
};

pub const SIZE = struct {
    pub const BYTES = struct {
        pub const @"u8"  = @typeInfo(u8).int.bits / 8;
        pub const @"u16" = @typeInfo(u16).int.bits / 8;
        pub const @"u32" = @typeInfo(u32).int.bits / 8;
        pub const @"u64" = @typeInfo(u64).int.bits / 8;

        pub const @"i8"  = @typeInfo(i8).int.bits / 8;
        pub const @"i16" = @typeInfo(i16).int.bits / 8;
        pub const @"i32" = @typeInfo(i32).int.bits / 8;
        pub const @"i64" = @typeInfo(i64).int.bits / 8;

        pub const @"f32" = @typeInfo(f32).float.bits / 8;
        pub const @"f64" = @typeInfo(f64).float.bits / 8;
    };
    
    pub const BITS = struct {
        pub const @"u8"  = @typeInfo(u8).int.bits;
        pub const @"u16" = @typeInfo(u16).int.bits;
        pub const @"u32" = @typeInfo(u32).int.bits;
        pub const @"u64" = @typeInfo(u64).int.bits;

        pub const @"i8"  = @typeInfo(i8).int.bits;
        pub const @"i16" = @typeInfo(i16).int.bits;
        pub const @"i32" = @typeInfo(i32).int.bits;
        pub const @"i64" = @typeInfo(i64).int.bits;

        pub const @"f32" = @typeInfo(f32).float.bits;
        pub const @"f64" = @typeInfo(f64).float.bits;
    };
};

var base10 = "0123456789";
var base64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
var codeKey = "0123456789abcdefghijklmnopqrstuvwxyz";

pub fn toString(num_: anytype, base: u32) String {
    switch (@typeInfo(@TypeOf(num_))) {
        .int, .comptime_int => {
            const key = if (base == 10) Int.base10 else Int.codeKey;

            // calculate length
            const num = @as(u64, @intCast(Math.abs(num_)));
            var placeValues: u32 = 1;
            while (Math.pow(@as(u64, @intCast(base)), placeValues) < num + 1) {
                placeValues += 1;
            }

            const negative = num_ < 0;
            var encoded = if (negative) String.alloc(placeValues + 1) else String.alloc(placeValues);
            encoded.bytes.len = encoded.bytes.capacity();
            encoded.viewEnd = encoded.bytes.capacity();
            
            var i = placeValues;
            var strIdx: u32 = 0;

            if (negative) {
                encoded.setChar(0, '-');
                strIdx = 1;
            }

            var f64num = @as(f64, @floatFromInt(num));
            while (i > 0) {
                const factor: f64 = Math.pow(@as(f64, @floatFromInt(base)), @as(f64, @floatFromInt(i - 1)));
                const digit = Math.floor(f64num / factor);
                encoded.setChar(strIdx, key[@as(usize, @intFromFloat(digit))]);
                strIdx += 1;
                f64num -= digit * factor;
                i -= 1;
            }

            return encoded;
        },
        else => @panic("Int.toString only accepts integers")
    }
}

pub fn parse(data: anytype, base_: u32) i64 {
    var key = if (base_ == 10) String.allocFrom(Int.base10) else String.allocFrom(Int.codeKey);
    defer key.dealloc();
    const base = @as(i64, @intCast(base_));

    var str: String = undefined;
    var createdString = false;
    switch (@TypeOf(data)) {
        // String
        String => {
            str = data;
        },
        // const string
        else => {
            str = String.allocFrom(data);
            createdString = true;
        }
    }

    var num: i64 = 0;
    var i = @as(i32, @intCast(str.len() - 1));
    var power: i64 = 0;
    while (i >= 0) : (i -= 1) {
        const ch = str.charAt(@as(u32, @bitCast(i)));
        var idx = key.indexOf(ch);
        if (idx == -1) {
            idx = key.indexOf(ch + 32);
        }
        num += @as(i64, @intCast(idx)) * Math.pow(base, power);
        power += 1;
    }

    defer if (createdString) str.dealloc();

    return num;
}