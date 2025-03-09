# Vexlib Documentation
This documentation was last updated for vexlib v0.0.22

## add to build.zig
```ts
const module_vexlib = b.createModule(.{
    .root_source_file = b.path("PATH_TO_VEXLIB_DIRECTORY"++"src/vexlib.zig"),
    .target = target,
    .optimize = optimize
});
exe.root_module.addImport("vexlib", module_vexlib);
```
OR
## add to build.json5
```ts
$importAll: [{
    local: "../vexlib",
    remote: "https://github.com/vExcess/zig-vexlib"
}]
```

## Import
```ts
const vexlib = @import("vexlib");
```

## init
Vexlib needs to be initialized with an allocator
before it can be used
```ts
// setup allocator
var generalPurposeAllocator = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = generalPurposeAllocator.allocator();
vexlib.init(&allocator);
```

## wasm
To compile to wasm set `wasmFreestanding` in the top of the vexlib library to true
```ts
pub const wasmFreestanding: bool = true;
```

## As
`As` is used for casting numbers. The `As` methods accept
any number type and cast that number to the specified
type. Below are all the allowed conversions. Methods
ending with `T` truncate the input when casting to the
desired type.
```ts
As.f16(123.456)
As.f32(123.456)
As.f64(123.456)
As.f80(123.456)
As.f128(123.456)
As.u8(123.456)
As.u16(123.456)
As.u32(123.456)
As.u64(123.456)
As.i8(123.456)
As.i16(123.456)
As.i32(123.456)
As.i64(123.456)
As.u8T(123.456)
As.u16T(123.456)
As.u32T(123.456)
As.u64T(123.456)
As.i8T(123.456)
As.i16T(123.456)
As.i32T(123.456)
As.i64T(123.456)
```

## Math

### Math.PI
Contains value of pi
```ts
PI: f64 = 3.141592653589793
```

### Math.E
Contains value of e for natural logarithm
```ts
E = 2.71828182845904523536028747135266249775724709369995
```

### Math.abs
Returns the absolute value of an integer or float
```rs
fn abs(x: .Int | .Float) @TypeOf(x)
```

### Math.pow
Returns x to the power of y
```rs
fn pow(x: .Int | .Float, y: .Int | .Float) @TypeOf(x, y)
```

### Math.loge
Returns the natural logarithm of n
```rs
fn loge(n: .Int | .Float) @TypeOf(n)
```

### Math.log
Returns the base log of n
```rs
fn log(base: .Int | .Float, n: .Int | .Float) @TypeOf(n)
```

### Math.sqrt
Returns the square root of x
```rs
fn sqrt(x: .Int | .Float) @TypeOf(x)
```

### Math.round
Returns x rounded to the closest integer
```rs
fn round(x: .Int | .Float) @TypeOf(x)
```

### Math.floor
Returns x rounded down to the next lowest integer
```rs
fn floor(x: .Int | .Float) @TypeOf(x)
```

### Math.cos
Returns the cosine of x
```rs
fn cos(x: .Int | .Float) @TypeOf(x)
```

### Math.sin
Returns the sine of x
```rs
fn sin(x: .Int | .Float) @TypeOf(x)
```

### Math.atan2
Returns the arc tangent of x
```rs
fn atan2(y: .Int | .Float, x: .Int | .Float) @TypeOf(y)
```

### Math.factorial
Returns the factorial of x
```rs
fn factorial(x: .Int | .Float) @TypeOf(x)
```

### Math.min
Returns the lower of two numbers
```rs
fn min(x: .Int | .Float, y: @TypeOf(x)) @TypeOf(x)
```

### Math.max
Returns the greater of two numbers
```rs
fn max(x: .Int | .Float, y: @TypeOf(x)) @TypeOf(x)
```

### Math.constrain
Returns a number confined between a minimum and maximum
```rs
fn constrain(val: .Int | .Float, min_: @TypeOf(val), max_: @TypeOf(val)) @TypeOf(val)
```

### Math.map
Returns a number mapped from one range to another
```rs
fn map(value: .Int | .Float, istart: @TypeOf(value), istop: @TypeOf(value), ostart: @TypeOf(value), ostop: @TypeOf(value)) @TypeOf(value)
```

### Math.lerp
Linearly interpolates between val1 and val2 given an amount between 0.0 and 1.0. Math.lerp works with both
numbers and vectors
```rs
fn lerp(val1: .Int | .Float | .Vector, val2: @TypeOf(val1), amt: .Int | .Float) @TypeOf(val1, val2)
```

### Math.Infinity
Returns the Infinity value of a float. Val must be one of
f16, f32, f64, f80, or f128
```rs
fn Infinity(val: type) val
```

### Math.randomInt
Returns a random integer of type `T`
```rs
fn randomInt(T: type) T
```

### Math.random
Returns a random floating point number of type `T`
between min_ (inclusive) and max_ exclusive. Note that
`T` must be of type `.Float`
```rs
fn random(T: type, min_: T, max_: T) T
```

### Math.randomGaussian
Returns a random floating point number of type `T` according to a gaussian distribution where
`T` must be of type `f32` or `f64`
```rs
fn randomGaussian(T: type) T
```

### Math.mag
Returns the magnitude of a .Vector
```rs
fn mag(v: .Vector) @TypeOf(v[0])
```

### Math.normalize
Returns a normalized vector
```rs
fn normalize(v: .Vector) @TypeOf(v)
```

### Math.dot
Returns the dot product of two vectors
```rs
fn dot(v1: .Vector, v2: .Vector) @TypeOf(v1[0])
```

### Math.dot
Returns the cross product of two vectors
```rs
fn cross(v1: .Vector, v2: .Vector) @TypeOf(v1, v2)
```

## Time

### Time.micros
Returns the current time since EPOC in microseconds
```rs
fn micros() i64
```

### Time.millis
Returns the current time since EPOC in milliseconds
```rs
fn millis() i64
```

### Time.seconds
Returns the current time since EPOC in seconds
```rs
fn seconds() f64
```

## fmt
formats structs, arrays, slices, vectors, integers,
floating point numbers, booleans, null, void, and string literals into an instance of `String`
```rs
fn fmt(data_: anytype) String
```
```ts
fmt(null) // String{"null"}
fmt(1 + 2) // String{"3"}
```

## print
formats and then prints data NOT followed by a newline character
```rs
fn print(data_: anytype) void
```
```ts
print("Hello World");
```

## println
formats and then prints data followed by a newline character
```rs
fn println(data_: anytype) void
```
```ts
println("Hello World");
```

## readln
reads a line from standard input. Limited to reading maxLen
characters. NOTE: readln will likely be removed in later
releases of vexlib. NOTE: readln is not web assembly
compatible.
```rs
fn readln(maxLen: u32) String
```
```ts
println("What is your name?");
var name = readln(100);
print("Hello ");
println(name);
print("!");

name.dealloc();
```

## fetch
fetches an http resource. NOTE: Currently is not supported
in web assembly.
```rs
fn fetch(url_: anytype, options: anytype) !HTTPResponse
```
```ts
var payload = String.allocFrom("Hello World!");
var res = try fetch("http://example.com", .{
    .method = "POST",
    .headers = .{
        .content_type = "application/json"
    },
    .body = payload.raw()
});
var responseContent = res.text();
print("Received response from server: ");
println(responseContent);

payload.dealloc();
res.dealloc();
responseContent.dealloc();
```

## Array
Note that in the following documentation `.prototype.` is not a field that actually exists, but exists merely to 
demonstrate which methods belong to Array and which belong to instances of Array.

create a dynamicly sized array of type T
```rs
fn Array(comptime T: type) type
```
```rs
var names = Array([]const u8).alloc(0);
names.append("Alice");
names.append("Bob");
names.append("Eve");
names.append("John");
```

## Array.alloc
Create an instance of Array(T) with a capacity of given number of elements
```rs
fn alloc(capacity_: u32) Self
```
```ts
// creates array of strings with a capacity of 4
Array(String).alloc(4)
```

## Array.new
Create a heap allocated instance of Array(T) with a capacity of given number of elements
```rs
fn new(capacity_: u32) *Self
```
```ts
// creates array of strings allocated on the heap with a capacity of 4
Array(String).new(4)
```

## Array.prototype.dealloc
Deallocate the array
```rs
fn dealloc(self: *Self) void
```
```ts
var arr = Array(String).alloc(4);
arr.dealloc(); // frees the used memory
```

## Array.prototype.free
Deallocate the array and then free the array itself. `.free` us only used for arrays that are heap allocated (that is created with `.new`)
```rs
fn free(self: *Self) void
```
```ts
var arr = Array(String).new(4);
arr.free(); // frees the used memory
```

## Array.using
Create an array using an existing buffer in memory rather
that allocated new memory
```rs
fn using(buffer: []T) Self
```
```ts
// I already have this buffer
const buffer = allocator.alloc(String, 4) catch @panic("memory allocation failed");
defer allocator.free(buffer);

// no memory is allocated on the following line
var arr = Array(String).using(buffer);
```

## Array.prototype.deallocContents
Call dealloc on all items in the array
```rs
fn deallocContents(self: *Self) void
```
```ts
var arr = Array(String).alloc(4);
arr.append(String.allocFrom("Hello"));
arr.append(String.allocFrom("World"));
arr.append(String.allocFrom("!"));
// no need to free each string individually
arr.deallocContents();
arr.dealloc();
```

## Array.prototype.capacity
Returns the capacity of the array
```rs
fn capacity(self: *const Self) u32
```
```ts
var arr = Array(String).alloc(123);
arr.capacity() // 123
```

## Array.prototype.get
Returns an item at an index in the array. If the item is a struct a pointer is returned rather than a copy of the struct. Beware that .get does not perfom bounds checks to ensure that you are not accessing invalid data.
```rs
fn get(self: *const Self, idx: u32) if (@typeInfo(T) == .Struct) *T else T
```
```ts
var arr = Array(i32).alloc(3);
arr.append(12);
arr.append(34);
arr.append(56);
arr.get(0) // 12
arr.get(1) // 34
arr.get(2) // 56
```

## Array.prototype.getCopy
Behaves the same as .get except .getCopy will copy a struct rather than returning a pointer to it
```rs
fn getCopy(self: *const Self, idx: u32) T
```

## Array.prototype.set
Set an item in an array. Beware that .set does not not perform bounds checks nor update the length of the array.
```rs
fn set(self: *Self, idx: u32, val: T) void
```
```ts
var arr = Array(i32).alloc(1);
arr.append(1);
arr.get(0) // 1
arr.set(0, 2);
arr.get(0) // 2
```

## Array.prototype.write8
## Array.prototype.write16
## Array.prototype.write24
## Array.prototype.write32
## Array.prototype.write64
These methods are only implemented on Array(u8). They write 8, 16, 24, 32, and 64 bits respectively to the u8 array at a specified index given a value containing those bits that is of type u8, u16, u32, or u64 whichever is the smallest that can fit the number of bits. The bits are written in little endian order. Beware bounds checks are not performed on writes.
```rs
fn write8(self: *Self, addr: usize, val: u8) void
fn write16(self: *Self, addr: usize, val: u16) void
fn write24(self: *Self, addr: usize, val: u32) void
fn write32(self: *Self, addr: usize, val: u32) void
fn write64(self: *Self, addr: usize, val: u64) void
```
```ts
var arr = Uint8Array.alloc();
// [0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
arr.write8(0, 1);
// [0x01, 0x02, 0x02, 0x00, 0x00, 0x00]
arr.write16(1, 514);

```
