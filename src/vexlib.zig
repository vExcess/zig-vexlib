// vexlib - v0.1.2
//
// ABOUT
//   vexlib is a "standard" library for writing Web Assembly compatible
//   programs in Zig. Unlike Zig's official standard library, vexlib
//   has no issues compiling to freestanding Web Assembly. In addition
//   because most people writing freestanding wasm code will be web
//   developers I have architected the library to be similiar to 
//   JavaScript's built in APIs
// 
// DESIGN NOTES
//   - Because wasm is 32 bit rather than 64 bit like most native code
//     these days, vexlib tends to use u32 instead of usize in order to
//     ensure that the library will function the same in wasm as when
//     running natively
//   - Zig dislikes memory allocations that aren't explicitly done by the
//     programmer using allocators, however my assumption is that most web
//     devs want to worry as little about memory management as possible.
//     Therefore I have made the entire library share a single allocator
//     and objects are managed using a simple .alloc + .dealloc pattern like so:
//     var myString = String.allocFrom("Hello World");
//     defer myString.dealloc();
//   - Because wasm doesn't work with top level functions that return 
//     errors as values vexlib avoids functions returning errors
// 
// When compiling to wasm freestanding instead of native simply set the
// wasmFreestanding boolean below to true
// 

pub const wasmFreestanding: bool = false;


const std = @import("std");
const http = std.http;

pub const ArrayList = @import("./ArrayList.zig").ArrayList;

pub const As = @import("./As.zig");

pub const async = @import("./async.zig");
pub const await = async.await;
pub const PromiseState = async.PromiseState;
pub const Promise = async.Promise;

pub const Float = @import("./Float.zig");

pub const Int = @import("./Int.zig");

pub const Math = @import("./Math.zig");

pub const String = @import("./String.zig");

pub const Time = @import("./Time.zig");



pub var allocatorPtr: *const std.mem.Allocator = undefined;

pub fn init(allocator: *const std.mem.Allocator) void {
    allocatorPtr = allocator;
    Math.prng = std.Random.DefaultPrng.init(@intFromPtr(allocator));
}



pub const stdio = if (wasmFreestanding)
    (struct {
        pub extern fn stdio(id: i32, addr: usize, len: u32) void;
    }).stdio
else
    (struct {
        fn stdio(id: i32, addr: usize, len: u32) void {
            const manyPtr: [*]u8 = @ptrFromInt(addr);
            const slice: []u8 = manyPtr[0..len];

            if (id == 1) {
                std.debug.print("{s}\n", .{slice});
            }
        }
    }).stdio;

pub fn fmt(data_: anytype) String {
    if (@TypeOf(data_) == String) {
        return String.allocFrom(data_);
    } else {
        var outString: String = undefined;
        
        switch (@typeInfo(@TypeOf(data_))) {
            .@"struct" => {
                outString = String.allocFrom(data_);
            },
            .array, .pointer => {
                const contentType = std.meta.Elem(@TypeOf(data_));
                if (contentType == u8) {
                    // handle const strings
                    outString = String.allocFrom(data_);
                } else {
                    // handle other slices
                    outString = String.allocFrom("[]");
                    outString.concat(@typeName(contentType));
                    outString.concat("{");
                    var i: usize = 0; while (i < data_.len) : (i += 1) {
                        var temp = fmt(data_[i]);
                        defer temp.dealloc();
                        outString.concat(temp);
                        if (i < data_.len - 1) {
                            outString.concat(", ");
                        }
                    }
                    outString.concat("}");
                }
            },
            .vector => |vecData| {
                outString = String.allocFrom("@Vector<");
                outString.concat(@typeName(vecData.child));
                outString.concat(">{");
                var i: usize = 0; while (i < vecData.len) : (i += 1) {
                    var numStr = Float.toString(data_[i], 10);
                    defer numStr.dealloc();
                    outString.concat(numStr);
                    if (i < vecData.len - 1) {
                        outString.concat(", ");
                    }
                }
                outString.concat("}");
            },
            else => {
                switch (@TypeOf(data_)) {
                    comptime_int, i8, u8, i16, u16, i32, u32, i64, u64, i128, u128, isize, usize => {
                        outString = Int.toString(data_, 10);
                    },
                    comptime_float, f16, f32, f64, f80, f128 => {
                        outString = Float.toString(data_, 10);
                    },
                    bool => {
                        if (data_) {
                            outString = String.allocFrom("true");
                        } else {
                            outString = String.allocFrom("false");
                        }
                    },
                    @TypeOf(null) => {
                        outString = String.allocFrom("null");
                    },
                    @TypeOf(void) => {
                        outString = String.allocFrom("void");
                    },
                    else => {
                        if (wasmFreestanding) {
                            outString = String.allocFrom("error: unreachable code has been reached");
                        } else {
                            @panic("attempted to print unsupported type of data");
                        }
                    }
                }
            },
        }

        return outString;
    }
}

pub fn print(data_: anytype) void {
    const write = std.debug.print;

    if (@TypeOf(data_) == String and !wasmFreestanding) {
        var temp = data_;
        write("{s}", .{temp.raw()});
    } else {
        var outString: String = fmt(data_);
        defer outString.dealloc();
        if (wasmFreestanding) {
            stdio(1, @intFromPtr(outString.bytes.buffer.ptr), outString.len());
        } else {
            // var temp = ArrayList(u8).using(outString.raw());
            // temp.len = As.u32(outString.raw().len);
            // var temp2 = temp.join(",");
            // defer temp2.dealloc();
            // write("!!!{}!!!", .{temp2});
            write("{s}", .{outString.raw()});
        }
    }              
}
pub fn println(data: anytype) void {
    print(data);
    print("\n");
}

const stdin = std.io.getStdIn().reader();
pub fn readln(maxLen: u32) String {
    var out = String.alloc(maxLen);
    if (try stdin.readUntilDelimiterOrEof(out.bytes.buffer, '\n')) |user_input| {
        return out.slice(0, @as(u32, @intCast(user_input.len)));
    } else {
        return String.alloc(0);
    }
}

pub const HTTPResponse = struct {
    allocatorPtr: *const std.mem.Allocator = undefined,
    body: []u8 = undefined,
    // headers = .{},
    ok: bool = undefined,
    redirected: bool = undefined,
    status: bool = undefined,
    statusText: []u8 = undefined,
    url: String = undefined,
    
    pub fn text(self: *HTTPResponse) String {
        return String.allocFrom(self.body);
    }

    pub fn dealloc(self: *HTTPResponse) void {
        var allocator = self.allocatorPtr.*;
        allocator.free(self.body);
        self.url.dealloc();
    }
};

pub fn fetch(url_: anytype, options: anytype) !HTTPResponse {
    // create String url
    var url: String = undefined;
    switch (@TypeOf(url_)) {
        // String
        String => {
            url = url_.clone();
        },
        // const string
        else => {
            url = String.allocFrom(url_);
        },
    }

    var method = http.Method.GET;
    var hasBody = false;

    const Client = std.http.Client;
    const Value = Client.Request.Headers.Value;
    var headers = Client.Request.Headers{};
    headers.accept_encoding = Value.omit;
    headers.connection = Value.omit;

    inline for (@typeInfo(@TypeOf(options)).@"struct".fields) |field| {
        const value = @field(options, field.name);
        if (@typeInfo(@TypeOf(value)) == .@"struct") {
            if (std.mem.eql(u8, field.name, "headers")) {
                inline for (@typeInfo(@TypeOf(value)).@"struct".fields) |subfield| {
                    const subValue = @field(value, subfield.name);
                    if (std.mem.eql(u8, subfield.name, "content_type")) {
                        headers.content_type = Value{ .override = subValue };
                    }
                }
            }
        } else {
            if (std.mem.eql(u8, field.name, "method")) {
                if (std.mem.eql(u8, value, "POST")) {
                    method = http.Method.POST;
                }
            } else if (std.mem.eql(u8, field.name, "body")) {
                method = http.Method.POST;
                hasBody = true;
            }
        }
    }

    const allocator = allocatorPtr.*;

    // create http client
    var httpClient = http.Client{ .allocator = allocator };
    defer httpClient.deinit();

    // create uri object
    const uri = try std.Uri.parse(url.raw());
    var server_header_buffer: [16 * 1024]u8 = undefined;

    var req = try httpClient.open(method, uri, .{
        .server_header_buffer = &server_header_buffer,
        .redirect_behavior = .unhandled,
        .headers = headers,
        // .extra_headers = options.extra_headers,
        // .privileged_headers = options.privileged_headers,
        // .keep_alive = options.keep_alive,
    });
    defer req.deinit();
    req.transfer_encoding = Client.RequestTransfer{ .content_length = options.body.len };

    try req.send(); // send headers
    if (hasBody) {
        try req.writeAll(options.body);  
    } 
    try req.finish(); // finish body
    try req.wait(); // wait for response

    const res = try req.reader().readAllAlloc(allocator, 1024);

    return HTTPResponse{
        .allocatorPtr = allocatorPtr,
        .body = res,
        // .headers = .{},
        .ok = req.response.status.class() == .success,
        // .redirected = false,
        // .status = 200,
        // .statusText = "",
        // .type = "",
        .url = url,
    };
}

pub fn Stack(comptime T: type) type {
    return struct {
        items: ArrayList(T) = undefined,
        
        const Self = @This();

        pub fn alloc(_capacity: u32) Self {
            return Self{
                .items = ArrayList(T).alloc(_capacity)
            };
        }

        fn push(self: *Self, item: T) void {
            self.items.add(item);
        }

        fn pop(self: *Self) ?T {
            return self.items.removeLast();
        }

        fn top(self: *Self) ?T {
            return self.items.last();
        }

        fn size(self: *Self) u32 {
            return self.items.len;
        }
    };
}

pub fn zeroArray(arr: anytype) void {
    const t = @TypeOf(arr);
    switch (t) {
        []comptime_int, []i8, []u8, []i16, []u16, []i32, []u32, []i64, []u64, []i128, []u128, []isize, []usize => {
            {var i: usize = 0; while (i < arr.len) : (i += 1) {
                arr[i] = 0;
            }}
        },
        else => {
            @panic("zeroArray doesn't support given data type");
        }
    }
}

pub const Uint8Array = ArrayList(u8);
pub const Int8Array = ArrayList(i8);
pub const Uint16Array = ArrayList(u16);
pub const Int16Array = ArrayList(i16);
pub const Uint32Array = ArrayList(u32);
pub const Int32Array = ArrayList(i32);
pub const Uint64Array = ArrayList(u64);
pub const Int64Array = ArrayList(i64);
pub const Float32Array = ArrayList(f32);
pub const Float64Array = ArrayList(f64);

pub const Hash = struct {
    fn FNV1a(key: []const u8) u32 {
        var hash: u32 = 2166136261;
        var i: u32 = 0;
        while (i < key.len) : (i += 1) {
            hash ^= As.u8T(key[i]);
            hash *%= 16777619;
        }
        return hash;
    }
};

pub fn MapIterator(comptime MapType: type) type {
    return struct {
        idx: u32 = 0,
        map: *const MapType,
        key: MapType.KeyType = undefined,
        value: MapType.ValueType = undefined,

        const Self = @This();
        
        pub fn next(self: *Self) bool {
            const hasCurrent = self.idx < self.map.buckets.len;
            if (hasCurrent) {
                const entry = self.map.buckets.get(self.idx);
                self.key = entry.key;
                self.value = entry.value;
                self.idx += 1;
            }
            return hasCurrent;
        }
    };
}

pub fn ListMapEntry(comptime KeyType: type, comptime ValueType: type) type {
    return struct {
        key: KeyType,
        value: ValueType,
    };
}

pub fn ListMap(comptime KeyType_: type, comptime ValueType_: type) type {
    return struct {
        const KeyType = KeyType_;
        const ValueType = ValueType_;
        const Entry = ListMapEntry(KeyType, ValueType);

        buckets: ArrayList(Entry),

        const Self = @This();

        pub fn alloc(capacity_: u32) Self {
            return Self{
                .buckets = ArrayList(Entry).alloc(capacity_)
            };
        }

        pub fn dealloc(self: *Self) void {
            self.buckets.dealloc();
        }

        pub fn grow(self: *Self, newCapacity: u32) void {
            self.buckets.resize(newCapacity);
        }

        fn keyEql(a: KeyType, b: KeyType) bool {
            return switch (KeyType) {
                String => a.equals(b),
                []const u8 => std.mem.eql(u8, a, b),
                else => a == b
            };
        }

        pub fn set(self: *Self, key: KeyType, value: ValueType) void {
            // update existing key if exists
            {var i: u32 = 0; while (i < self.buckets.len) : (i += 1) {
                if (keyEql(self.buckets.get(i).key, key)) {
                    self.buckets.buffer[As.usize(i)].value = value;
                    return;
                }
            }}
            // otherwise add key
            self.buckets.append(Entry{
                .key = key,
                .value = value
            });
        }

        pub fn get(self: *const Self, key: KeyType) ?ValueType {
            {var i: u32 = 0; while (i < self.buckets.len) : (i += 1) {
                if (keyEql(self.buckets.buffer[i].key, key)) {
                    return self.buckets.buffer[i].value;
                }
            }}
            return null;
        }

        pub fn has(self: *const Self, key: KeyType) bool {
            {var i: u32 = 0; while (i < self.buckets.len) : (i += 1) {
                if (keyEql(self.buckets.buffer[i].key, key)) {
                    return true;
                }
            }}
            return false;
        }
        
        pub fn entries(self: *const Self) MapIterator(Self) {
            return MapIterator(Self){
                .map = self
            };
        }
    };
}

pub fn Map(comptime KeyType: type, comptime ValueType: type) type {
    return struct {
        pub const Entry = struct {
            key: ?KeyType,
            value: ValueType,
            hash: u32
        };
        
        size: u32 = 0,
        buckets: []Entry = undefined,

        const MAX_LOAD: f64 = 0.66;

        const Self = @This();

        pub fn alloc() Self {
            var allocator = allocatorPtr.*;
            const buckets = allocator.alloc(Entry, 4) catch @panic("memory allocation failed");
            var i: u32 = 0;
            while (i < buckets.len) : (i += 1) {
                buckets[i] = Entry{
                    .key = null,
                    .value = undefined,
                    .hash = undefined
                };
            }
            return Self{
                .buckets = buckets
            };
        }

        pub fn dealloc(self: *Self) void {
            var allocator = allocatorPtr.*;
            allocator.free(self.buckets);
        }

        pub fn grow(self: *Self) void {
            var allocator = allocatorPtr.*;
            const newBuckets = allocator.alloc(Entry, self.buckets.len * 2) catch @panic("memory allocation failed");
            var i: u32 = 0;
            while (i < newBuckets.len) : (i += 1) {
                newBuckets[i] = Entry{
                    .key = null,
                    .value = undefined,
                    .hash = undefined
                };
            }

            const oldBuckets = self.buckets;
            self.buckets = newBuckets;
            i = 0;
            while (i < oldBuckets.len) : (i += 1) {
                const bucket = oldBuckets[i];
                if (bucket.key != null) {
                    self.setPreHashed(bucket.key.?, bucket.hash, bucket.value);
                }
            }
            
            allocator.free(oldBuckets);
        }

        fn keyEql(a: KeyType, b: KeyType) bool {
            return switch (KeyType) {
                String => a.equals(b),
                []const u8 => std.mem.eql(u8, a, b),
                else => a == b
            };
        }

        pub fn setPreHashed(self: *Self, key: KeyType, hash: u32, value: ValueType) void {
            const idx = As.u32(hash & (self.buckets.len - 1));
            var bucket = self.buckets[idx];
            var isEmpty = bucket.key == null;
            if (isEmpty or Self.keyEql(bucket.key.?, key)) {
                // if bucket is empty or is same key, set value
                self.buckets[idx] = Entry{
                    .key = key,
                    .value = value,
                    .hash = hash
                };
                if (!isEmpty) {
                    self.size += 1;
                }
            } else {
                // go to next bucket or wrap around
                var i: u32 = if (idx + 1 == self.buckets.len) 0 else idx + 1;
                while (i < self.buckets.len) {
                    bucket = self.buckets[i];
                    isEmpty = bucket.key == null;
                    if (isEmpty or Self.keyEql(bucket.key.?, key)) {
                        // if bucket is empty or is same key, set value
                        self.buckets[i] = Entry{
                            .key = key,
                            .value = value,
                            .hash = hash
                        };
                        if (!isEmpty) {
                            self.size += 1;
                        }
                        break;
                    } else {
                        i += 1;
                        if (i == self.buckets.len) {
                            // wrap around to start if out of bounds
                            i = 0;
                        } else if (i == idx) {
                            // if we end up back where we started we are 
                            // todo resize
                            self.grow();
                        }
                    }
                }
            }
        }

        pub fn set(self: *Self, key: KeyType, value: ValueType) void {
            const hash = switch (KeyType) {
                String => Hash.FNV1a(key.raw()),
                else => switch(@typeInfo(KeyType)) {
                    .int => Hash.FNV1a(&@as([@typeInfo(KeyType).int.bits / 8]u8, @bitCast(key))),
                    else => unreachable
                }
            };
            self.setPreHashed(key, hash, value);
        }

        pub fn get(self: *const Self, key: KeyType) ?ValueType {
            const hash = switch (KeyType) {
                String => Hash.FNV1a(key.raw()),
                else => switch(@typeInfo(KeyType)) {
                    .int => Hash.FNV1a(&@as([@typeInfo(KeyType).int.bits / 8]u8, @bitCast(key))),
                    else => unreachable
                }
            };
            const idx = hash & (self.buckets.len - 1);
            if (self.buckets[idx].key != null) {
                return self.buckets[idx].value;
                // var i: u32 = 0;
                // while (i < self.buckets.len) {
                //     if (self.buckets[idx].key) {
                //         break;
                //     } else if (i + 1 < self.buckets.len) {
                //         i += 1;
                //     } else {
                //         i = 0;
                //     }
                // }
            }
            return null;
        }
    };
}

pub fn Set(comptime KeyType: type) type {
    return Map(KeyType, void);
}

pub fn Queue(comptime T: type) type {
    // NOTE: Can only store 2^31 items. Sign bit is used as a queue state flag
    return struct {
        arr: []T = undefined,
        fields: packed struct { front: u31, end: u31, lastOp: u1 } = .{
            .front = 0,
            .end = 0,
            .lastOp = 0,
        },

        const ADD: u1 = 1;
        const REMOVE: u1 = 0;

        const Self = @This();

        pub fn alloc(_capacity: u32) Self {
            const allocator = allocatorPtr.*;
            return Self{
                .arr = allocator.alloc(T, _capacity) catch @panic("Queue mem alloc fail"),
            };
        }

        pub fn dealloc(self: *Self) void {
            const allocator = allocatorPtr.*;
            allocator.free(self.arr);
        }

        fn front(self: *Self) u32 {
            return As.u32(self.fields.front);
        }

        fn end(self: *Self) u32 {
            return As.u32(self.fields.end);
        }

        pub fn lastOperation(self: *Self) u1 {
            return self.fields.lastOp;
        }

        pub fn size(self: *Self) u32 {
            if (self.front() == self.end()) {
                return switch (self.lastOperation()) {
                    Self.REMOVE => 0,
                    Self.ADD => As.u32(self.arr.len)
                };
            } else if (self.front() < self.end()) {
                return self.end() - self.front();
            } else { // end < front, meaning it wrapped around
                return As.u32(self.arr.len) - self.front() + self.end();
            }
        }

        pub fn capacity(self: *Self) u32 {
            return As.u32(self.arr.len);
        }

        pub fn isEmpty(self: *Self) bool {
            return self.front() == self.end() and self.lastOperation() == Self.REMOVE;
        }

        pub fn isFull(self: *Self) bool {
            return self.front() == self.end() and self.lastOperation() == Self.ADD;
        }

        pub fn add(self: *Self, item: T) void {
            if (self.isFull()) {
                const allocator = allocatorPtr.*;
                const old = self.arr;
                const oldCapacity = old.len;
                self.arr = allocator.alloc(T, oldCapacity * 2) catch @panic("Queue mem alloc fail");
                
                var i = As.usize(self.front());
                var newIdx: usize = 0;
                while (newIdx < oldCapacity) {
                    self.arr[newIdx] = old[i];
                    i = (i + 1) % oldCapacity;
                    newIdx += 1;
                }
                self.fields.front = 0;
                self.fields.end = @as(u31, @intCast(newIdx));

                allocator.free(old);
            }
            self.arr[As.usize(self.end())] = item;
            self.fields.end = @as(u31, @intCast((self.end() + 1) % As.u32(self.arr.len)));
            self.fields.lastOp = Self.ADD;
        }

        pub fn remove(self: *Self) ?T {
            if (self.isEmpty()) {
                return null;
            }
            const item = self.arr[As.usize(self.front())];
            self.fields.front = @as(u31, @intCast((self.front() + 1) % As.u32(self.arr.len)));
            self.fields.lastOp = Self.REMOVE;
            return item;
        }

        pub fn peek(self: *Self) ?T {
            if (self.isEmpty()) {
                return null;
            }
            return self.arr[As.usize(self.front())];
        }

        pub fn deallocContents(self: *Self) void {
            var allocator = allocatorPtr.*;
            
            var i = As.usize(self.front());
            while (i != self.end()) {
                allocator.free(self.arr[i]);
                i = (i + 1) % self.arr.len;
            }
        }

        pub fn toString(self: *Self) String {
            var out = String.alloc(self.size() * 5);
            
            var i = As.usize(self.front());
            while (i != self.end()) {
                var temp = fmt(self.arr[i]);
                defer temp.dealloc();
                temp.concat(", ");
                out.concat(temp);

                i = (i + 1) % self.arr.len;
            }
            
            return out;
        }
    };
}
