const vexlib = @import("./vexlib.zig");
const As = @import("./As.zig");
const String = @import("./String.zig");
const Int = @import("./Int.zig");
const Float = @import("./Float.zig");

pub fn ArrayList(comptime T: type) type {
    return struct {
        buffer: []T = undefined,
        len: u32 = 0,
        comptime isArray: bool = true,

        const Self = @This();

        pub fn alloc(capacity_: u32) Self {
            var allocator = vexlib.allocatorPtr.*;
            const buffer = allocator.alloc(T, capacity_) catch @panic("memory allocation failed");
            return Self{
                .buffer = buffer
            };
        }

        pub fn new(capacity_: u32) *Self {
            const array = Self.alloc(capacity_);
            var allocator = vexlib.allocatorPtr.*;
            const heapArray = allocator.create(Self) catch @panic("memory allocation failed");
            heapArray.* = array;
            return heapArray;
        }

        pub fn dealloc(self: *Self) void {
            var allocator = vexlib.allocatorPtr.*;
            allocator.free(self.buffer);
        }

        pub fn free(self: *Self) void {
            self.dealloc();
            var allocator = vexlib.allocatorPtr.*;
            allocator.destroy(self);
        }

        pub fn using(buffer: []T) Self {
            return Self{
                .buffer = buffer,
                .len = As.u32(buffer.len)
            };
        }

        pub fn deallocContents(self: *Self) void {
            var allocator = vexlib.allocatorPtr.*;
            var i: usize = 0; while (i < self.len) : (i += 1) {
                const item = self.buffer[i];                
                const itemType = @TypeOf(item);
                const itemTypeInfo = @typeInfo(itemType);
                if (itemTypeInfo == .optional) {
                    const childItemType = itemTypeInfo.optional.child;
                    const childItemTypeInfo = @typeInfo(itemTypeInfo.optional.child);
                    if (item != null) {
                        if (childItemType == String) {
                            item.?.dealloc();
                        } else if (childItemTypeInfo == .@"struct" and @hasField(childItemType, "isArray") and item.?.isArray) {
                            item.?.dealloc();
                        } else {
                            allocator.free(item.?);
                        }
                    }
                } else {
                    if (itemType == String) {
                        item.dealloc();
                    } else if (itemTypeInfo == .@"struct" and @hasField(itemType, "isArray") and item.isArray) {
                        item.dealloc();
                    } else {
                        allocator.free(item);
                    }
                }
            }
        }

        pub fn capacity(self: *const Self) u32 {
            return As.u32(self.buffer.len);
        }

        pub fn get(self: *const Self, idx: u32) T {
            return self.buffer[idx];
        }

        pub fn getPtr(self: *const Self, idx: u32) *T {
            return &self.buffer[idx];
        }

        pub fn set(self: *Self, idx: u32, val: T) void {
            self.buffer[idx] = val;
        }

        fn Array_write8(self: *Self, addr: usize, val: u8) void {
            // use little endian
            self.buffer[addr] = val;
        }
        pub const write8 = switch(T) {
            u8 => Array_write8,
            else => @panic("Not implemented non u8 Arrays"),
        };

        fn Array_read8(self: *Self, addr: usize) u8 {
            // use little endian
            return self.buffer[addr];
        }
        pub const read8 = switch(T) {
            u8 => Array_read8,
            else => @panic("Not implemented non u8 Arrays"),
        };
        
        fn Array_write16(self: *Self, addr: usize, val: u16) void {
            // use little endian
            self.buffer[addr] = @as(u8, @intCast(val & 255));
            self.buffer[addr+1] = @as(u8, @intCast(val >> 8));
        }
        pub const write16 = switch(T) {
            u8 => Array_write16,
            else => @panic("Not implemented non u8 Arrays"),
        };

        fn Array_read16(self: *Self, addr: usize) u16 {
            // use little endian
            const a = @as(u16, @intCast(self.buffer[addr]));
            const b = @as(u16, @intCast(self.buffer[addr + 1]));
            return b << 8 | a;
        }
        pub const read16 = switch(T) {
            u8 => Array_read16,
            else => @panic("Not implemented non u8 Arrays"),
        };

        fn Array_write24(self: *Self, addr: usize, val: u32) void {
            // use little endian
            self.buffer[addr] = @as(u8, @intCast(val & 255));
            self.buffer[addr+1] = @as(u8, @intCast((val >> 8) & 255));
            self.buffer[addr+2] = @as(u8, @intCast(val >> 16));
        }
        pub const write24 = switch(T) {
            u8 => Array_write24,
            else => @panic("Not implemented non u8 Arrays"),
        };

        fn Array_read24(self: *Self, addr: usize) u32 {
            // use little endian
            const a = @as(u32, @intCast(self.buffer[addr]));
            const b = @as(u32, @intCast(self.buffer[addr + 1]));
            const c = @as(u32, @intCast(self.buffer[addr + 2]));
            return c << 16 | b << 8 | a;
        }
        pub const read24 = switch(T) {
            u8 => Array_read24,
            else => @panic("Not implemented non u8 Arrays"),
        };

        fn Array_write32(self: *Self, addr: usize, val: u32) void {
            // use little endian
            self.buffer[addr] = @as(u8, @intCast(val & 255));
            self.buffer[addr+1] = @as(u8, @intCast((val >> 8) & 255));
            self.buffer[addr+2] = @as(u8, @intCast((val >> 16) & 255));
            self.buffer[addr+3] = @as(u8, @intCast(val >> 24));
        }
        pub const write32 = switch(T) {
            u8 => Array_write32,
            else => @panic("Not implemented non u8 Arrays"),
        };

        fn Array_read32(self: *Self, addr: usize) u32 {
            // use little endian
            const a = @as(u32, @intCast(self.buffer[addr]));
            const b = @as(u32, @intCast(self.buffer[addr + 1]));
            const c = @as(u32, @intCast(self.buffer[addr + 2]));
            const d = @as(u32, @intCast(self.buffer[addr + 3]));
            return d << 24 | c << 16 | b << 8 | a;
        }
        pub const read32 = switch(T) {
            u8 => Array_read32,
            else => @panic("Not implemented non u8 Arrays"),
        };

        fn Array_write64(self: *Self, addr: usize, val: u64) void {
            // use little endian
            self.buffer[addr  ] = @as(u8, @intCast( val        & 255));
            self.buffer[addr+1] = @as(u8, @intCast((val >>  8) & 255));
            self.buffer[addr+2] = @as(u8, @intCast((val >> 16) & 255));
            self.buffer[addr+3] = @as(u8, @intCast((val >> 24) & 255));
            self.buffer[addr+4] = @as(u8, @intCast((val >> 32) & 255));
            self.buffer[addr+5] = @as(u8, @intCast((val >> 40) & 255));
            self.buffer[addr+6] = @as(u8, @intCast((val >> 48) & 255));
            self.buffer[addr+7] = @as(u8, @intCast((val >> 56) & 255));
        }
        pub const write64 = switch(T) {
            u8 => Array_write64,
            else => @panic("Not implemented non u8 Arrays"),
        };

        fn Array_read64(self: *Self, addr: usize) u64 {
            // use little endian
            const a = @as(u64, @intCast(self.buffer[addr]));
            const b = @as(u64, @intCast(self.buffer[addr + 1]));
            const c = @as(u64, @intCast(self.buffer[addr + 2]));
            const d = @as(u64, @intCast(self.buffer[addr + 3]));
            const e = @as(u64, @intCast(self.buffer[addr + 4]));
            const f = @as(u64, @intCast(self.buffer[addr + 5]));
            const g = @as(u64, @intCast(self.buffer[addr + 6]));
            const h = @as(u64, @intCast(self.buffer[addr + 7]));
            return h << 56 | g << 48 | f << 40 | e << 32 | d << 24 | c << 16 | b << 8 | a;
        }
        pub const read64 = switch(T) {
            u8 => Array_read64,
            else => @panic("Not implemented non u8 Arrays"),
        };

        pub fn fill(self: *Self, val: T, len_: i32) void {
            const len: u32 = if (len_ == -1) @as(u32, @intCast(self.buffer.len)) else @as(u32, @intCast(len_));
            var i: u32 = 0;
            while (i < len) : (i += 1) {
                self.buffer[i] = val;
            }
            self.len = len;
        }

        pub fn ensureCapacity(self: *Self, _capacity: u32) void {
            if (self.capacity() >= _capacity) {
                return true;
            }
            var newCapacity = self.capacity();
            while (newCapacity < _capacity) {
                newCapacity *= 2;
            }
            self.resize(newCapacity);
        }

        pub fn resize(self: *Self, newCapacity: u32) void {
            var allocator = vexlib.allocatorPtr.*;
            var newBuffer = allocator.alloc(T, newCapacity) catch @panic("memory allocation failed");

            for (self.buffer, 0..) |val, idx| {
                newBuffer[idx] = val;
            }

            allocator.free(self.buffer);
            self.buffer = newBuffer;
        }

        pub fn append(self: *Self, val: T) void {
            const prevLen = self.len;
            const prevCapacity = self.capacity();
            if (prevLen == prevCapacity) {
                if (prevCapacity == 0) {
                    self.resize(2);
                } else {
                    self.resize(prevCapacity * 2);
                }
            }
            self.buffer[prevLen] = val;
            self.len += 1;
        }

        pub fn remove(self: *Self, idx: u32, len: u32) void {
            const buff = self.buffer;
            var i = idx;
            while (i + len < self.len) : (i += 1) {
                buff[i] = buff[i + len];
            }
            self.len -= len;
        }

        pub fn first(self: *Self) ?T {
            return if (self.len > 0) self.buffer[0] else null;
        }

        pub fn last(self: *Self) ?T {
            return if (self.len > 0) self.buffer[self.len - 1] else null;
        }

        pub fn removeFirst(self: *Self) ?T {
            if (self.len == 0) {
                return null;
            }

            const buff = self.buffer;
            const firstItem = buff[0];
            var i: usize = 0; while (i < self.len - 1) : (i += 1) {
                buff[i] = buff[i + 1];
            }
            self.len -= 1;
            return firstItem;
        }

        pub fn removeLast(self: *Self) ?T {
            if (self.len == 0) {
                return null;
            }

            const lastItem = self.get(self.len - 1);
            self.len -= 1;
            return lastItem;
        }

        pub fn indexOf(self: *const Self, val: T) i32 {
            const buff = self.buffer;
            var i: usize = 0;
            while (i < self.len) : (i += 1) {
                if (buff[i] == val) {
                    return @as(i32, @intCast(i));
                }
            }
            return -1;
        }

        pub fn contains(self: *const Self, str: anytype) bool {
            return self.indexOf(str) >= 0;
        }

        pub fn join(self: *const Self, separator_: anytype) String {
            var stringSeparator: String = undefined;
            var needToFreeSeparator = false;
            if (@TypeOf(separator_) == String) {
                stringSeparator = separator_;
            } else {
                stringSeparator = String.allocFrom(separator_);
                needToFreeSeparator = true;
            }
            defer if (needToFreeSeparator) stringSeparator.dealloc();

            var out = String.alloc(0);

            var i: u32 = 0;
            while (i < self.len) : (i += 1) {
                var item: String = undefined;
                const TypeInfo = @typeInfo(T);
                if (TypeInfo == .@"struct" or TypeInfo == .pointer) {
                    if (@hasDecl(T, "toString")) {
                        item = self.get(i).toString();
                    } else {
                        item = String.allocFrom(self.get(i));
                    }
                } else if (TypeInfo == .array) {
                    item = String.alloc(1);
                    const temp = self.get(i);
                    var j: usize = 0; while (j < temp.len) : (j += 1) {
                        var temp2 = vexlib.fmt(temp[j]);
                        defer temp2.dealloc();
                        item.concat(temp2);
                        if (j < temp.len - 1) {
                            item.concat(',');
                        }
                    }
                } else if (TypeInfo == .int) {
                    item = Int.toString(self.get(i), 10);
                } else if (TypeInfo == .float) {
                    item = Float.toString(self.get(i), 10);
                } else if (TypeInfo == .bool) {
                    item = if (self.get(i)) String.allocFrom("true") else String.allocFrom("false");
                }
                defer item.dealloc();
                out.concat(item);
                if (i < self.len - 1) {
                    out.concat(stringSeparator);
                }
            }

            return out;
        }

        pub fn slice(self: *const Self, start_: u32, end_: anytype) Self {
            const start = start_;
            var end: u32 = undefined;

            if (end_ == -1) {
                end = self.len;
            } else {
                end = As.u32(end_);
            }

            return Self{
                .buffer = self.buffer[start..end],
                .len = end - start
            };
        }
    };
}