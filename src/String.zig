const std = @import("std");
const vexlib = @import("./vexlib.zig");
const As = @import("./As.zig");
const Int = @import("./Int.zig");
const Uint8Array = vexlib.Uint8Array;
const ArrayList = vexlib.ArrayList;

const String = @This();

viewStart: u32 = 0,
viewEnd: u32 = 0,
bytes: Uint8Array,
isSlice: bool = false,

pub fn alloc(capacity: u32) String {
    const bytes = Uint8Array.alloc(capacity);
    return String{
        .viewStart = 0,
        .viewEnd = 0,
        .bytes = bytes,
        .isSlice = false
    };
}

pub fn allocFrom(data_: anytype) String {
    const dataType = @TypeOf(data_);
    const dataTypeInfo = @typeInfo(dataType);
    if (dataType == String) {
        var data = data_;
        const temp = data.clone();
        return temp;
    } else if (dataTypeInfo == .@"struct") {
        var temp = String.allocFrom(".{\n");
        inline for (dataTypeInfo.@"struct".fields) |field| {
            const value = @field(data_, field.name);
            // const value: u32 = 123;
            if (@typeInfo(@TypeOf(value)) == .@"struct") {
                temp.concat("    .");
                temp.concat(field.name);
                temp.concat(" = ");
                if (@hasField(@TypeOf(value), "isArray") and value.isArray) {
                    var joined = String.allocFrom("PPPPP");
                    defer joined.dealloc();
                    temp.concat(joined);
                } else {
                    var formatted = String.allocFrom(value);
                    defer formatted.dealloc();
                    var splitted = formatted.split("\n");
                    defer splitted.dealloc();
                    var i: u32 = 0; while (i < splitted.len) : (i += 1) {
                        if (i != 0) {
                            temp.concat("    ");
                        }
                        temp.concat(splitted.get(i));
                        temp.concat(",\n");
                    }
                }
            } else {
                temp.concat("    .");
                temp.concat(field.name);
                temp.concat(" = ");
                const allocator = vexlib.allocatorPtr.*;
                const formatted = std.fmt.allocPrint(allocator, "{any}", .{ value }) catch @panic("memory allocation failed");
                defer allocator.free(formatted);
                temp.concat(formatted);
                temp.concat(",\n");
            }
        }
        temp.concat("}");
        return temp;
    } else {
        switch (@TypeOf(data_)) {
            // char
            comptime_int, i8, u8, i16, u16, i32, u32, i64, u64, i128, u128, isize, usize => {
                const temp = Int.toString(data_, 10);
                return temp;
            },
            // const string
            else => {
                const dataLen = @as(u32, @intCast(data_.len));
                var temp = String.alloc(dataLen);
                temp.viewEnd = dataLen;
                temp.bytes.len = dataLen;

                for (data_, 0..) |val, idx| {
                    temp.bytes.buffer[idx] = val;
                }

                return temp;
            },
        }
    }
    
}

pub fn new(capacity: u32) *String {
    const str = String.alloc(capacity);
    var allocator = vexlib.allocatorPtr.*;
    const heapStr = allocator.create(String) catch @panic("memory allocation failed");
    heapStr.* = str;
    return heapStr;
}

pub fn newFrom(data_: anytype) *String {
    const str = String.allocFrom(data_);
    var allocator = vexlib.allocatorPtr.*;
    const heapStr = allocator.create(String) catch @panic("memory allocation failed");
    heapStr.* = str;
    return heapStr;
}

pub fn dealloc(self: *String) void {
    self.bytes.dealloc();
}

pub fn free(self: *String) void {
    self.bytes.dealloc();
    var allocator = vexlib.allocatorPtr.*;
    allocator.destroy(self);
}

pub fn usingArrayList(bytes: Uint8Array) String {
    return String{
        .viewStart = 0,
        .viewEnd = bytes.len,
        .bytes = bytes,
        .isSlice = false
    };
}

pub fn usingSlice(_slice: []const u8) String {
    const bytes = Uint8Array.using(@constCast(_slice));
    return String{
        .viewStart = 0,
        .viewEnd = As.u32(_slice.len),
        .bytes = bytes,
        .isSlice = false
    };
}

pub fn usingCString(_cstring: [*c]const u8) String {
    var strLen: usize = 0;
    while (_cstring[strLen] != 0) {
        strLen += 1;
    }
    const zstring = _cstring[0..strLen : 0];
    return usingZigString(zstring);
}

pub fn usingZigString(_zstring: [:0]const u8) String {
    var bytes = Uint8Array.using(@constCast(_zstring));
    bytes.len = As.u32(_zstring.len + 1);
    bytes.buffer.len += 1;
    return String{
        .viewStart = 0,
        .viewEnd = As.u32(_zstring.len),
        .bytes = bytes,
        .isSlice = false
    };
}

pub fn len(self: *const String) u32 {
    return self.viewEnd - self.viewStart;
}

pub fn charAt(self: *const String, idx: u32) u8 {
    return self.bytes.get(self.viewStart + idx);
}

pub fn charCodeAt(self: *const String, idx: u32) u8 {
    return self.bytes.get(self.viewStart + idx);
}

pub fn setChar(self: *String, idx: u32, val: u8) void {
    self.bytes.set(self.viewStart + idx, val);
}

pub fn concat(self: *String, data: anytype) void {
    if (self.isSlice) {
        unreachable;
    }
    switch (@TypeOf(data)) {
        // char
        comptime_int, i8, u8, i16, u16, i32, u32, i64, u64, i128, u128, isize, usize => {
            self.bytes.append(data);
            self.viewEnd = self.bytes.len;
            return;
        },
        // String
        *String, String => {
            var i: u32 = data.viewStart;
            while (i < data.viewEnd) : (i += 1) {
                self.bytes.append(data.bytes.buffer[i]);
                self.viewEnd = self.bytes.len;
            }
            return;
        },
        // const string
        else => {
            for (data, 0..) |val, idx| {
                _ = idx;
                self.bytes.append(val);
                self.viewEnd = self.bytes.len;
            }
            return;
        },
    }
}

pub fn equals(self: *const String, str: anytype) bool {
    var temp: String = undefined;
    var needsFreeing = false;
    switch (@TypeOf(str)) {
        String => {
            temp = str;
        },
        else => {
            temp = String.allocFrom(str);
            needsFreeing = true;
        }
    }

    var out = true;
    const buf1 = self.bytes.buffer;
    const buf2 = temp.bytes.buffer;
    if (buf1.ptr == buf2.ptr and self.viewStart == temp.viewStart and self.viewEnd == temp.viewEnd) {
        // out is already true so no need to set it
        // out = true;
    } else if (temp.len() != self.len()) {
        out = false;
    } else {
        var i: u32 = 0;
        while (i < self.len()) : (i += 1) {
            if (self.charAt(i) != temp.charAt(i)) {
                out = false;
                break;
            }
        }
    }

    defer if (needsFreeing) temp.dealloc();
    
    return out;
}

pub fn toSlice(self: *const String, start_: u32, end_: u32) String {
    const start = start_;
    var end = end_;

    if (end == 0) {
        end = self.len();
    }
    var bytes = Uint8Array.alloc(end - start);
    bytes.len = end - start;

    var i: u32 = 0;
    while (i < bytes.len) : (i += 1) {
        bytes.buffer[i] = self.bytes.buffer[start + i];
    }

    return String{
        .viewStart = 0,
        .viewEnd = bytes.len,
        .bytes = bytes,
        .isSlice = false
    };
}

pub fn slice(self: *const String, start_: u32, end_: anytype) String {
    const start = start_;
    var end: u32 = undefined;

    if (end_ == -1) {
        end = self.len();
    } else {
        end = As.u32(end_);
    }

    return String{
        .viewStart = self.viewStart + start,
        .viewEnd = self.viewStart + end,
        .bytes = self.bytes,
        .isSlice = true
    };
}

pub fn trimStart(self: *const String) String {
    var start = self.viewStart;
    const end = self.viewEnd;
    const buff = self.bytes.buffer;

    // trim start
    while (
        start < end and
        (buff[start] == 9 or 
        buff[start] == 10 or
        buff[start] == 11 or
        buff[start] == 12 or
        buff[start] == 13 or
        buff[start] == 32)
    ) {
        start += 1;
    }

    return String{
        .viewStart = start,
        .viewEnd = end,
        .bytes = self.bytes,
        .isSlice = true
    };
}

pub fn trimEnd(self: *const String) String {
    const start = self.viewStart;
    var end = self.viewEnd;
    const buff = self.bytes.buffer;

    // trim end
    var endMinusOne: isize = end - 1;
    while (
        end > start and
        (buff[@as(usize, @bitCast(endMinusOne))] == 9 or 
        buff[@as(usize, @bitCast(endMinusOne))] == 10 or
        buff[@as(usize, @bitCast(endMinusOne))] == 11 or
        buff[@as(usize, @bitCast(endMinusOne))] == 12 or
        buff[@as(usize, @bitCast(endMinusOne))] == 13 or
        buff[@as(usize, @bitCast(endMinusOne))] == 32)
    ) {
        endMinusOne -= 1;
        end -= 1;
    }

    return String{
        .viewStart = start,
        .viewEnd = end,
        .bytes = self.bytes,
        .isSlice = true
    };
}

pub fn trim(self: *const String) String {
    var start = self.viewStart;
    var end = self.viewEnd;
    const buff = self.bytes.buffer;

    // trim start
    while (
        start < end and
        (buff[start] == 9 or 
        buff[start] == 10 or
        buff[start] == 11 or
        buff[start] == 12 or
        buff[start] == 13 or
        buff[start] == 32)
    ) {
        start += 1;
    }
    
    // trim end
    var endMinusOne = end - 1;
    while (
        (buff[endMinusOne] == 9 or 
        buff[endMinusOne] == 10 or
        buff[endMinusOne] == 11 or
        buff[endMinusOne] == 12 or
        buff[endMinusOne] == 13 or
        buff[endMinusOne] == 32)
        and end > start
    ) {
        endMinusOne -= 1;
        end -= 1;
    }

    return String{
        .viewStart = start,
        .viewEnd = end,
        .bytes = self.bytes,
        .isSlice = true
    };
}

pub fn split(self: *const String, str: anytype) ArrayList(String) {
    var delimiter: String = undefined;
    var needsFreeing = false;
    var out = ArrayList(String).alloc(0);
    switch (@TypeOf(str)) {
        String => {
            delimiter = str;
        },
        else => {
            delimiter = String.allocFrom(str);
            needsFreeing = true;
        }
    }

    var selfCopy = self.*;
    var idx = selfCopy.indexOf(delimiter);
    while (idx != -1) {
        const slc = selfCopy.slice(0, @as(u32, @bitCast(idx)));
        out.append(slc);
        selfCopy = selfCopy.slice(@as(u32, @bitCast(idx)) + delimiter.len(), -1);
        idx = selfCopy.indexOf(delimiter);
    }

    if (selfCopy.len() > 0) {
        out.append(selfCopy);
    }

    defer if (needsFreeing) delimiter.dealloc();
    
    return out;
}

pub fn repeat(self: *String, amt: u32) void {
    if (self.isSlice) {
        @panic("cannot repeat a slice");
    }
    var selfClone = self.clone();
    defer selfClone.dealloc();
    var i: u32 = 0;
    while (i < amt - 1) : (i += 1) {
        self.concat(selfClone);
    }
}

pub fn padStart(self: *String, width: u32, str: anytype) void {
    if (self.isSlice) {
        @panic("cannot pad a slice");
    }
    const padAmount = width - self.len();
    if (padAmount > 0) {
        var temp = String.alloc(width);
        temp.concat(str);
        temp.repeat(padAmount / temp.len());
        temp.concat(self.*);
        temp = temp.slice(0, width);

        self.dealloc();
        self.bytes = temp.bytes;
        self.viewStart = temp.viewStart;
        self.viewEnd = temp.viewEnd;
    }
}

pub fn padEnd(self: *String, width: u32, str: anytype) void {
    if (self.isSlice) {
        @panic("cannot pad a slice");
    }
    const padAmount = As.i32(width) - As.i32(self.len());
    if (padAmount > 0) {
        var temp = String.alloc(width);
        defer temp.dealloc();
        temp.concat(str);
        temp.repeat(As.u32(padAmount) / temp.len());
        self.concat(temp.slice(0, As.u32(padAmount)));
    }
}

pub fn toLowerCase(self: *String) String {
    var str = self.clone();
    var i: u32 = 0;
    while (i < str.len()) : (i += 1) {
        const c = str.charAt(i);
        if (c >= 'A' and c <= 'Z') {
            str.setChar(i, c + 32);
        }
    }
    return str;
}

pub fn lowerCase(self: *String) void {
    var i: u32 = 0;
    while (i < self.len()) : (i += 1) {
        const c = self.charAt(i);
        if (c >= 'A' and c <= 'Z') {
            self.setChar(i, c + 32);
        }
    }
}

pub fn upperCase(self: *String) void {
    var i: u32 = 0;
    while (i < self.len()) : (i += 1) {
        const c = self.charAt(i);
        if (c >= 'a' and c <= 'z') {
            self.setChar(i, c - 32);
        }
    }
}

pub fn indexOfPos(self: *const String, str: anytype, pos: u32) i32 {
    var temp: String = undefined;
    var isChar = false;
    var charVal: u8 = 0;
    var needsFreeing = false;
    switch (@TypeOf(str)) {
        comptime_int, u8 => {
            isChar = true;
            charVal = str;
        },
        String => {
            temp = str;
        },
        else => {
            temp = String.allocFrom(str);
            if (temp.len() == 1) {
                isChar = true;
                charVal = temp.charAt(0);
                defer temp.dealloc();
            } else {
                needsFreeing = true;
            }
        }
    }
    
    if (isChar) {
        var i: u32 = pos;
        while (i < self.len()) : (i += 1) {
            if (self.charAt(i) == charVal) {
                return @as(i32, @bitCast(i));
            }
        }
    } else {
        var i: u32 = pos;
        while (i < self.len()) : (i += 1) {
            var j: u32 = 0;
            while (j < temp.len()) : (j += 1) {
                if (self.charAt(i + j) == temp.charAt(j)) {
                    if (j == temp.len() - 1) {
                        defer if (needsFreeing) temp.dealloc();
                        return @as(i32, @bitCast(i));
                    }
                } else {
                    break;
                }
            }
        }

        defer if (needsFreeing) temp.dealloc();
    }

    return -1;
}

pub fn indexOf(self: *const String, str: anytype) i32 {
    return self.indexOfPos(str, 0);
}

pub fn contains(self: *const String, str: anytype) bool {
    return self.indexOf(str) >= 0;
}

pub fn startsWith(self: *const String, str: anytype) bool {
    var temp: String = undefined;
    var needsFreeing = false;
    var out = true;
    switch (@TypeOf(str)) {
        String => {
            temp = str;
        },
        else => {
            temp = String.allocFrom(str);
            needsFreeing = true;
        }
    }

    if (temp.len() > self.len()) {
        out = false;
    } else {
        var i: u32 = 0;
        while (i < temp.len()) : (i += 1) {
            if (self.charAt(i) != temp.charAt(i)) {
                out = false;
                break;
            }
        }
    }

    defer if (needsFreeing) temp.dealloc();
    
    return out;
}

pub fn endsWith(self: *const String, str: anytype) bool {
    var temp: String = undefined;
    var needsFreeing = false;
    var out = true;
    switch (@TypeOf(str)) {
        String => {
            temp = str;
        },
        else => {
            temp = String.allocFrom(str);
            needsFreeing = true;
        }
    }

    if (temp.len() > self.len()) {
        out = false;
    } else {
        var i: u32 = 0;
        const offset = self.len() - temp.len();
        while (i < temp.len()) : (i += 1) {
            if (self.charAt(offset + i) != temp.charAt(i)) {
                out = false;
                break;
            }
        }
    }

    defer if (needsFreeing) temp.dealloc();
    
    return out;
}

pub fn raw(self: *const String) []u8 {
    return self.bytes.buffer[self.viewStart..self.viewEnd];
}

pub fn cstring(self: *const String) [*c]u8 {
    const buff = self.bytes.buffer;
    if (buff[self.viewEnd] == 0) {
        return buff[self.viewStart..self.viewEnd :0];
    } else {
        @panic("String is not null terminated");
    }
}

pub fn clone(self: *const String) String {
    return String.allocFrom(self.raw());
}

pub const toString = clone;