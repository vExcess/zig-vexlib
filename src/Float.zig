const std = @import("std");
const String = @import("./String.zig");
const Math = @import("./Math.zig");
const Int = @import("./Int.zig");
const As = @import("./As.zig");

const Float = @This();

var base10 = "0123456789";

pub fn toString(num_: anytype, base: u32) String {
    if (Float.isNaN(num_)) {
        return String.allocFrom("NaN");
    }

    switch (@typeInfo(@TypeOf(num_))) {
        .float, .comptime_float => {
            var num: f64 = @as(f64, @floatCast(num_));
            const negative = num < 0;
            num = Math.abs(num);
            const leading = @as(u32, @intFromFloat(num));
            const ten: f64 = 10;
            const six: f64 = 6;
            var f64Trailing = (num - @as(f64, @floatFromInt(leading))) * Math.pow(ten, six);
            var trailing = @as(u32, @intFromFloat(f64Trailing));
            f64Trailing = @as(f64, @floatFromInt(trailing));

            if (trailing > 0) {
                while ((f64Trailing / 10) - Math.floor(f64Trailing / 10) == 0) {
                    f64Trailing /= 10.0;
                }
                trailing = @as(u32, @intFromFloat(f64Trailing));
            }

            var trailStr = Int.toString(trailing, base);
            defer trailStr.dealloc();

            var temp = if (negative) String.allocFrom("-") else String.alloc(0);
            var temp2 = Int.toString(leading, base);
            defer temp2.dealloc();
            temp.concat(temp2);
            temp.concat('.');
            temp.concat(trailStr);
            return temp;
        },
        else => @panic("Float.toString only accepts floats")
    }
}

pub fn toFixed(num: anytype, digits: u32) String {
    var out = Float.toString(num, 10);
    const dotIdx = As.u32(out.indexOf("."));
    const decimalDigitCount = out.len() - dotIdx - 1;
    if (decimalDigitCount >= digits) {
        return out.slice(0, dotIdx + digits + 1);
    } else {
        out.padEnd(dotIdx + digits + 1, "0");
        return out;
    }
}

pub fn parse(data_: anytype, base: u32) f64 {
    var str: String = undefined;
    var createdString = false;
    switch (@TypeOf(data_)) {
        // String
        String => {
            str = data_;
        },
        // const string
        else => {
            str = String.allocFrom(data_);
            createdString = true;
        }
    }

    const dotIdx = @as(u32, @bitCast(str.indexOf('.')));
    const front = str.slice(0, dotIdx);
    var back = str.slice(dotIdx + 1, -1);
    const frontNum = @as(f64, @floatFromInt(Int.parse(front, base)));
    const backNum = @as(f64, @floatFromInt(Int.parse(back, base)));
    const floatLen = @as(f64, @floatFromInt(back.len()));
    const divider = Math.pow(@as(f64, 10.0), floatLen);

    defer if (createdString) str.dealloc();

    return frontNum + (backNum / divider);
}

pub fn NaN(val: type) val {
    return std.math.nan(val);
}

pub fn isNaN(val: anytype) bool {
    return std.math.isNan(val);
}