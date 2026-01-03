const std = @import("std");
const Prng = std.Random.DefaultPrng;

const Math = @This();

pub var prng: std.Random.DefaultPrng = undefined;

pub const PI: f64 = 3.141592653589793;
pub const E = 2.71828182845904523536028747135266249775724709369995;

pub fn abs(x: anytype) @TypeOf(x) {
    switch (@typeInfo(@TypeOf(x))) {
        .comptime_int, .int => {
            return if (x < 0) -x else x;
        },
        .comptime_float, .float => {
            return if (x < 0.0) -x else x;
        },
        else => @panic("Math.abs only accepts integers and floats")
    }
}

pub fn comptime_pow(comptime x: anytype, comptime y: anytype) @TypeOf(x, y) {
    var out = 1;
    var i = 0; while (i < y) : (i += 1) {
        out *= x;
    }
    return out;
}

pub fn pow(x: anytype, y: anytype) @TypeOf(x, y) {
    return std.math.pow(@TypeOf(x, y), x, y);
}

pub fn loge(n: anytype) @TypeOf(n) {
    return std.math.log(@TypeOf(n), Math.E, n);
}

pub fn log(base: anytype, n: anytype) @TypeOf(n) {
    return std.math.log(@TypeOf(n), base, n);
}

pub fn sqrt(x: anytype) @TypeOf(x) {
    return std.math.sqrt(x);
}

pub fn round(x: anytype) @TypeOf(x) {
    return std.math.round(x);
}

pub fn floor(x: anytype) @TypeOf(x) {
    return std.math.floor(x);
}

pub fn ceil(x: anytype) @TypeOf(x) {
    return std.math.ceil(x);
}

pub inline fn cos(x: anytype) @TypeOf(x) {
    return std.math.cos(x);
}

pub inline fn sin(x: anytype) @TypeOf(x) {
    return std.math.sin(x);
}

pub inline fn sign(x: anytype) @TypeOf(x) {
    if (x == 0) {
        return 0;
    } else if (x < 0) {
        return -1;
    } else {
        return 1;
    }
}

pub fn atan2(y: anytype, x: anytype) @TypeOf(y) {
    return std.math.atan2(y, x);
}

pub fn factorial(x: anytype) @TypeOf(x) {
    var val = x;
    var i = 2;
    while (i < x) : (i += 1) {
        val *= i;
    }
    return val;
}

pub fn min(x: anytype, y: @TypeOf(x)) @TypeOf(x) {
    if (x < y) {
        return x;
    } else {
        return y;
    }
}

pub fn constrain(val: anytype, min_: @TypeOf(val), max_: @TypeOf(val)) @TypeOf(val) {
    if (val > max_) {
        return max_;
    } else if (val < min_) {
        return min_;
    } else {
        return val;
    }
}

pub fn max(x: anytype, y: anytype) @TypeOf(x, y) {
    if (x > y) {
        return x;
    } else {
        return y;
    }
}

pub fn map(value: anytype, istart: @TypeOf(value), istop: @TypeOf(value), ostart: @TypeOf(value), ostop: @TypeOf(value)) @TypeOf(value) {
    return ostart + (ostop - ostart) * ((value - istart) / (istop - istart));
}

pub fn lerp(val1: anytype, val2: anytype, amt: anytype) @TypeOf(val1, val2) {
    const valType = @TypeOf(val1, val2);
    switch (@typeInfo(@TypeOf(val1, val2))) {
        .vector => |vecData| {
            const castedAmt = @as(vecData.child, @floatCast(amt));
            return ((val2 - val1) * @as(valType, @splat(castedAmt))) + val1;
        },
        else => {
            return ((val2 - val1) * @as(valType, @floatCast(amt))) + val1;
        }
    }
}

pub fn Infinity(val: type) val {
    const inf_u16: u16 = 0x7C00;
    const inf_u32: u32 = 0x7F800000;
    const inf_u64: u64 = 0x7FF0000000000000;
    const inf_u80: u80 = 0x7FFF8000000000000000;
    const inf_u128: u128 = 0x7FFF0000000000000000000000000000;

    return switch (val) {
        f16 => @as(f16, @bitCast(inf_u16)),
        f32 => @as(f32, @bitCast(inf_u32)),
        f64 => @as(f64, @bitCast(inf_u64)),
        f80 => @as(f80, @bitCast(inf_u80)),
        f128 => @as(f128, @bitCast(inf_u128)),
        else => @panic("Math.Infinity only exists for f16, f32, f64, f80, f128")
    };
}

pub fn randomInt(T: type) T {
    return prng.random().int(T);
}

pub fn random(T: type, min_: T, max_: T) T {
    const num = prng.random().float(T);
    return num * (max_ - min_) + min_;
}

var gaussianf32Y2: f32 = 0;
var gaussianf64Y2: f64 = 0;
var gaussianf32Previous = false;
var gaussianf64Previous = false;
pub fn randomGaussian(T: type) T {
    var y1: T = undefined;
    var x1: T = undefined;
    var x2: T = undefined;
    var w: T = undefined;

    switch (T) {
        f32 => {
            if (gaussianf32Previous) {
                y1 = gaussianf32Y2;
                gaussianf32Previous = false;
            } else {
                x1 = Math.random(T, -1, 1);
                x2 = Math.random(T, -1, 1);
                w = x1 * x1 + x2 * x2;
                while (w >= 1) {
                    x1 = Math.random(T, -1, 1);
                    x2 = Math.random(T, -1, 1);
                    w = x1 * x1 + x2 * x2;
                }
                w = Math.sqrt(-2 * Math.loge(w) / w);
                y1 = x1 * w;
                gaussianf32Y2 = x2 * w;
                gaussianf32Previous = true;
            }
        },
        f64 => {
            if (gaussianf64Previous) {
                y1 = gaussianf64Y2;
                gaussianf64Previous = false;
            } else {
                x1 = Math.random(T, -1, 1);
                x2 = Math.random(T, -1, 1);
                w = x1 * x1 + x2 * x2;
                while (w >= 1) {
                    x1 = Math.random(T, -1, 1);
                    x2 = Math.random(T, -1, 1);
                    w = x1 * x1 + x2 * x2;
                }
                w = Math.sqrt(-2 * Math.loge(w) / w);
                y1 = x1 * w;
                gaussianf64Y2 = x2 * w;
                gaussianf64Previous = true;
            }
        },
        else => @panic("Math.randomGaussian only accepts f32 or f64")
    }

    return y1;
}

// vector maths
pub fn mag(v: anytype) @TypeOf(v[0]) {
    const sqd = v * v;
    switch (@typeInfo(@TypeOf(v))) {
        .vector => |vecData| {
            switch (vecData.len) {
                2 => return Math.sqrt(sqd[0] + sqd[1]),
                3 => return Math.sqrt(sqd[0] + sqd[1] + sqd[2]),
                4 => return Math.sqrt(sqd[0] + sqd[1] + sqd[2] + sqd[3]),
                else => @panic("unsupported vector length")
            }
        },
        else => @panic("Math.mag only accepts vectors")
    }
}

pub fn normalize(v: anytype) @TypeOf(v) {
    const m = Math.mag(v);
    if (m > 0.0) {
        return v / @as(@TypeOf(v), @splat(m));
    }
    return v;
}

pub fn dot(v1: anytype, v2: anytype) @TypeOf(v1[0]) {
    switch (@typeInfo(@TypeOf(v1, v2))) {
        .vector => |vecData| {
            switch (vecData.len) {
                2 => return v1[0] * v2[0] + v1[1] * v2[1],
                3 => return v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2],
                4 => return v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2] + v1[3] * v2[3],
                else => @panic("unsupported vector length")
            }
        },
        else => @panic("Math.dot only accepts vectors")
    }
}

pub fn cross(v1: anytype, v2: anytype) @TypeOf(v1, v2) {
    return .{
        v1[1] * v2[2] - v1[2] * v2[1],
        v1[2] * v2[0] - v1[0] * v2[2],
        v1[0] * v2[1] - v1[1] * v2[0]
    };
}