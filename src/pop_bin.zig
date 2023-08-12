const std = @import("std");
const win = std.os.windows;
const user32 = win.user32;

// Types
const WINAPI = win.WINAPI;
const HWND = win.HWND;
const LPCSTR = win.LPCSTR;
const UINT = win.UINT;

// Alternatively we can use the MessageBoxA function directly from "std.os.windows"
extern "user32" fn MessageBoxA(hWnd: ?HWND, lpText: LPCSTR, lpCaption: LPCSTR, uType: UINT) callconv(WINAPI) i32;

pub fn main() void {
    // The return value is discarded by using "_ ="
    _ = MessageBoxA(null, "Hello World!", "Zig", 0);
}
