
const win32 = @import("buildin");
const win32 = @import("zig-win32/src/main.zig");

export fn hello(data: *c_void, size: i32) i32 {
    _ = win32.c.MessageBoxA(null,"hello,world!","Zig",0);
    return 0;
}

pub export fn DllMain(hInstance: HINSTANCE, ul_reason_for_call: DWORD, lpReserved: LPVOID) BOOL {
    switch(ul_reason_for_call) {
        DLL_PROCESS_ATTACH => {
            _ = win32.c.MessageBoxA(null,"hello,world!","Zig",0);
        },
        DLL_THREAD_ATTACH => {},
        DLL_THREAD_DETACH => {},
        DLL_PROCESS_DETACH =>{},
        else => {},
    }
    return 1;
}