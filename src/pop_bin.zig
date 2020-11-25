const std = @import("std");

usingnamespace std.os.windows;

// int MessageBox(
//  HWND    hWnd,
//  LPCTSTR lpText,
//  LPCTSTR lpCaption,
//  UINT    uType
// );

extern "user32" fn MessageBoxA(hWnd :?HWND, lpText :LPCTSTR, lpCaption :LPCTSTR, uType :UINT) callconv(.Stdcall) c_int;

pub fn main() !void {
    _ = MessageBoxA(null,"hello,world!","Zig",0);
}