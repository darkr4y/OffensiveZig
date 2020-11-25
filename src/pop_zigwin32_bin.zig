// https://github.com/GoNZooo/zig-win32
const win32 = @import("zig-win32/src/main.zig");

pub fn main() !void {
    _ = win32.c.MessageBoxA(null,"hello,world!","Zig",0);
}