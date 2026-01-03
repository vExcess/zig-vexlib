const std = @import("std");
const vexlib = @import("./vexlib.zig");

pub fn await(promise: anytype) @TypeOf(promise.result) {
    while (promise.state == PromiseState.pending) {
        // sleep for 4 millis
        std.posix.nanosleep(0, 4 * 1000 * 1000);
    }
    return promise.result;
}

pub fn Resolver(comptime T: type) type {
    return struct {
        promise: *Promise(T),
        
        const Self = @This();

        pub fn resolve(self: *const Self, value: T) void {
            self.promise.state = PromiseState.fulfilled;
            self.promise.result = value;
        }
    };
}

pub const PromiseState = enum {
    pending,
    fulfilled
};

pub fn Promise(comptime T: type) type {
    return struct {
        state: PromiseState,
        result: T,

        const Self = @This();

        pub fn new(executor: fn(resolver: Resolver(T)) void) *Self {
            const allocator = vexlib.allocatorPtr.*;

            const promise = allocator.create(Promise(T)) catch @panic("OOM");
            promise.state = PromiseState.pending;

            const resolver = Resolver(T){
                .promise = promise
            };

            // executor(resolver);
            const thread = std.Thread.spawn(.{}, executor, .{ resolver }) catch @panic("ThreadFail");
            thread.detach();

            return promise;
        }

        pub fn resolve(_result: T) *Self {
            const allocator = vexlib.allocatorPtr.*;

            const promise = allocator.create(Promise(T)) catch @panic("OOM");
            promise.state = PromiseState.fulfilled;
            promise.result = _result;

            return promise;
        }

        pub fn free(self: *Self) void {
            const allocator = vexlib.allocatorPtr.*;
            allocator.destroy(self);
        }

        // pub fn then(self: *Self, callback: fn (result: T) void) *Self {
        //     return self;
        // }
    };
}