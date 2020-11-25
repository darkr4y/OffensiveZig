//! Top-level doc comment 
// This is normal comment
// There are no multiline comments in Zig (e.g. like /* */ comments in C).
/// Doc comments


const std = @import("std");
//for zig testing, use command `zig test main.zig` and expect keyword
const expect = @import("std").testing.expect;

// like go must have main function
// in Zig '!' means that the function may return an error, '?' is for declaring a maybe type
// Zig hates \t use 4 space
pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Hello, {}!\n", .{"world"});
    // Assignment expr: var some_variable: i32 = 5;
    var some_variable: i32 = 5;
    // const
    const some_constant: i32 = 5;
    // Type Inference
    var some_variable_one = @as(i32, 5);
    const some_constant_one = @as(i32, 5);
    // Something like C's void 
    var x: u8 = undefined;
    // Ignore the variable, like Go
    _ = 10;
    // Defining Arrays
    var a = [_]u8{ 1, 2, 3 };
    const b = [3]u8{ 1, 2, 3};

    simpleFunc(1);
    testDefer();
    failFn();
}

//function
fn simpleFunc(x: u32) u32 {
    const print = @import("std").debug.print;
    print("Hello, simpleFunc {}\n", .{x});
}


//if statement
test "if statement" {
    const a = true;
    var x: u16 = 0;
    if (a) {
        x += 1;
    } else {
        x += 2;
    }
    expect(x == 1);

    // Another representation
    // x += if (a) 1 else 2;
    // expect(x == 1);
}

//while statement
test "while statement" {
    var sum: u8 = 0;
    var i: u8 = 0;
    while (i <= 3) : (i += 1) {
        if (i == 1) continue;
        if (i == 2) break;
        sum += i;
    }
    expect(sum == 1);
}

//defer like go
fn testDefer() void {
    const print = @import("std").debug.print;
    defer print("Hello, defer!\n", .{});
    print("Hello!\n", .{});
}


//error handle and try catch
fn failFn() error{Oops}!i32 {
    try failingFunction();
    return 12;
}

test "try" {
    var v = failFn() catch |err| {
        expect(err == error.Oops);
        return;
    };
    expect(v == 12); // is never reached
}