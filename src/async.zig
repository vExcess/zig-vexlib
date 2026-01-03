const std = @import("std");
const vexlib = @import("./vexlib.zig");

pub fn await(promise: anytype) @TypeOf(promise.result) {
    while (promise.state == PromiseState.pending) {
        // sleep for 4 millis
        std.posix.nanosleep(0, 4 * 1000 * 1000);
    }
    return promise.result;
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

        pub fn new(executor: fn(promise: *Self) void) *Self {
            const allocator = vexlib.allocatorPtr.*;

            const promise = allocator.create(Promise(T)) catch @panic("OOM");
            promise.state = PromiseState.pending;

            // executor(promise);
            const thread = std.Thread.spawn(.{}, executor, .{ promise }) catch @panic("ThreadFail");
            thread.detach();

            return promise;
        }

        pub fn resolve(self: *Self, value: T) void {
            self.result = value;
            self.state = PromiseState.fulfilled;
        }

        pub fn resolved(_result: T) *Self {
            const allocator = vexlib.allocatorPtr.*;

            const promise = allocator.create(Promise(T)) catch @panic("OOM");
            promise.result = _result;
            promise.state = PromiseState.fulfilled;

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