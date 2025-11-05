<p align="center">
    <img height="300" alt="OffensiveZig" src="https://github.com/darkr4y/OffensiveZig/assets/24826851/c572ec29-cddc-4c87-80ba-fa37d540d14e">
</p>

# OffensiveZig

The purpose of this project is to do some experiments with [Zig](https://ziglang.org/), and to explore the possibility of using it for implant development and general offensive operations. it is inspired by [@byt3bl33d3r](https://twitter.com/byt3bl33d3r)'s project "[OffensiveNim](https://github.com/byt3bl33d3r/OffensiveNim)".


## Table of Contents

- [OffensiveZig](#offensivezig)
  - [Table of Contents](#table-of-contents)
  - [Why Zig?](#why-zig)
  - [Try to Learn Zig in Y minutes](#try-to-learn-zig-in-y-minutes)
  - [How to play](#how-to-play)
  - [Cross Compiling](#cross-compiling)
  - [Interfacing with C/C++](#interfacing-with-cc)
  - [Creating Windows DLLs with an exported `DllMain`](#creating-windows-dlls-with-an-exported-dllmain)
  - [Optimizing executables for size](#optimizing-executables-for-size)
  - [Opsec Considerations](#opsec-considerations)
  - [Converting C code to Zig](#converting-c-code-to-zig)
  - [Language Bridges](#language-bridges)
  - [Debugging](#debugging)
  - [Setting up a dev environment](#setting-up-a-dev-environment)
  - [Interesting Zig libraries](#interesting-zig-libraries)
  - [Zig for implant dev links](#zig-for-implant-dev-links)
  - [Comparison of Zig and Nim](#comparison-of-zig-and-nim)
  - [Summary](#summary)
  - [Contributors](#contributors)

## Why Zig?

- The Zig toolchain offers the capability to cross-compile C/C++ projects using commands like *zig cc* or *zig c++*. This functionality allows you to efficiently utilize the Zig toolchain for building your pre-existing C/C++ projects.
- Zig operates without relying on a VM/runtime, the static executable is super small.
- Zig boasts a minimal Rust-like syntax while retaining the simplicity of C, enabling swift development of native payloads and prototypes.
- Zig offers seamless integration with C libraries without the need for Foreign Function Interface (FFI) bindings.
- Zig emphasizes manual memory management and transparent control flow, avoiding hidden complexities.
- Zig excels in facilitating cross-compilation without the need for a separate "cross toolchain," and can build for various targets listed [here](https://ziglang.org/documentation/master/#Targets).
- Compiling to WebAssembly and interacting with JavaScript code within a browser is relatively straightforward in Zig [here](https://ziglang.org/documentation/master/#WebAssembly).
- The [community](https://github.com/ziglang/zig/wiki/Community) is known for its approachability, friendliness, and high level of activity. The Zig [Discord](https://discord.gg/zig) server serves as a valuable platform for asking questions and staying informed about the latest developments within the language.

## Try to Learn Zig in Y minutes

If you're eager to learn Zig quickly and effectively, there's a wealth of resources to aid your journey. For a rapid grasp of Zig's syntax and concepts, you can dive into the [Learn Zig in Y Minutes guide](https://learnxinyminutes.com/docs/zig/). To delve deeper into Zig's intricacies, explore the official documentation for various Zig versions [here](https://ziglang.org/documentation/master/). Engage with the vibrant Zig community through [Ziggit](https://ziggit.dev/).

## How to play

**Examples in this project**

| File | Description |
| ---  | --- |
| `keylogger_bin.zig` | Keylogger using `SetWindowsHookEx` |
| `pop_bin.zig` | Call `MessageBox` WinApi *without* using a 3rd-party library |
| `pop_lib.zig` | Example of creating a Windows DLL with an exported `DllMain` |  
| `shellcode_bin.zig` | Creates a suspended process and injects shellcode with `VirtualAllocEx`/`CreateRemoteThread`. | 
| `suspended_thread_injection.nim` | Shellcode execution via suspended thread injection |

I recommend downloading Zig for different CPU architectures directly from Zig's official download page, available at https://ziglang.org/download/. In certain cases within this project, third-party libraries are employed.

## Cross Compiling

See the cross-compilation section in the [Zig compiler usage guide](https://ziglang.org/learn/overview/#cross-compiling-is-a-first-class-use-case), for a lot more details.

Cross compiling to Windows from MacOs/Nix: `zig build-exe -target x86_64-windows src.zig`

## Interfacing with C/C++

Explore the remarkable [Integration with C](https://ziglang.org/learn/overview/#integration-with-c-libraries-without-ffibindings) section in the Zig documentation.

Here's `MessageBox` example

```zig
const std = @import("std");
const win = std.os.windows;
const user32 = win.user32;

const WINAPI = win.WINAPI;
const HWND = win.HWND;
const LPCSTR = win.LPCSTR;
const UINT = win.UINT;


extern "user32" fn MessageBoxA(hWnd: ?HWND, lpText: LPCSTR, lpCaption: LPCSTR, uType: UINT) callconv(WINAPI) i32;

pub fn main() void {
    _ = MessageBoxA(null, "Hello World!", "Zig", 0);
}
```

## Creating Windows DLLs with an exported `DllMain`

As you can see, the code in the example is already very close to what C code looks like, just use `export` keyword.

Example:

```zig
const std = @import("std");
const win = std.os.windows;

const WINAPI = win.WINAPI;
const HINSTANCE = win.HINSTANCE;
const DWORD = win.DWORD;
const LPVOID = win.LPVOID;
const BOOL = win.BOOL;
const HWND = win.HWND;
const LPCSTR = win.LPCSTR;
const UINT = win.UINT;

const DLL_PROCESS_ATTACH: DWORD = 1;
const DLL_THREAD_ATTACH: DWORD = 2;
const DLL_THREAD_DETACH: DWORD = 3;
const DLL_PROCESS_DETACH: DWORD = 0;

extern "user32" fn MessageBoxA(hWnd: ?HWND, lpText: LPCSTR, lpCaption: LPCSTR, uType: UINT) callconv(WINAPI) i32;

pub export fn _DllMainCRTStartup(hinstDLL: HINSTANCE, fdwReason: DWORD, lpReserved: LPVOID) BOOL {
    _ = lpReserved;
    _ = hinstDLL;
    switch (fdwReason) {
        DLL_PROCESS_ATTACH => {
            _ = MessageBoxA(null, "Hello World!", "Zig", 0);
        },
        DLL_THREAD_ATTACH => {},
        DLL_THREAD_DETACH => {},
        DLL_PROCESS_DETACH => {},
        else => {},
    }
    return 1;
}
```

To compile:

```
//To make a static library
zig build-lib test.zig -target x86_64-windows 
//To make a shared library
zig build-lib test.zig -dynamic -target x86_64-windows 
```

## Optimizing executables for size

Taken from the [Build Mode](https://ziglang.org/documentation/master/#Build-Mode)

For the biggest size decrease use the following flags `-O ReleaseSmall -fstrip -fsingle-threaded`

## Opsec Considerations

Most samples are compiled in this mode `zig build-exe src.zig -O ReleaseSmall -fstrip -fsingle-threaded -target x86_64-windows`

Aside from a few specific NT functions found in the import table, I have not been able to find any other significant features that would indicate that they were coded in Zig.

![image](https://user-images.githubusercontent.com/4407382/100207487-9a6b4380-2f42-11eb-8b43-0bbf8d619be7.png)


## Converting C code to Zig

Zig offers the functionality to convert C code to Zig code through the command `zig translate-c`. I haven't personally experimented with this feature yet.

## Language Bridges

Regarding Python modules or Java JNI integration, I haven't had the opportunity to test these aspects yet.

References:

- https://github.com/kristoff-it/zig-cuckoofilter/
- https://github.com/ziglang/zig/issues/5795
- https://lists.sr.ht/~andrewrk/ziglang/%20%3CCACZYt3T8jACL+3Z_NMW8yYvcJ+5oyP%3Dh1s2HHdDL_VxYQH5rzQ%40mail.gmail.com%3E

## Debugging

You can utilize the functions within the `std.debug` namespace to display the call stack. Currently, there is limited IDE support for debugging Zig. If you're using VSCode, you can try the `webfreak.debug` extension. For more information on debugging Zig with VSCode, you can refer to the following links:
- [Reddit post: Debugging Zig in VSCode](https://www.reddit.com/r/Zig/comments/cl0x6k/debugging_zig_in_vscode/)
- [Dev.to article: Debugging Zig with VS Code](https://dev.to/watzon/debugging-zig-with-vs-code-44ca)

These resources should provide you with additional details on setting up and using the webfreak.debug extension for Zig debugging in VSCode.

## Setting up a dev environment

[VSCode](https://code.visualstudio.com/) provides an official Zig extension `ziglang.vscode-zig` to enhance Zig language support, offering more comprehensive functionality compared to earlier extensions such as `tiehuis.zig` and `lorenzopirro.zig-snippets`.

The link to the [Zig Tools](https://ziglang.org/learn/tools/) page on the Zig website will likely provide further information on various tools and resources available for Zig development, including debugging tools and extensions.

## Interesting Zig libraries

- https://github.com/GoNZooo/zig-win32
- https://github.com/Vexu/routez
- https://github.com/ducdetronquito/requestz
- https://github.com/ducdetronquito/h11
- https://github.com/ducdetronquito/http
- https://github.com/MasterQ32/zig-network
- https://github.com/lithdew/pike
- https://github.com/Hejsil/zig-clap
- https://github.com/Vexu/bog
- https://github.com/tiehuis/zig-regex
- https://github.com/alexnask/interface.zig
- https://github.com/marler8997/zig-os-windows
- https://github.com/nrdmn/awesome-zig
- https://github.com/The-Z-Labs/bof-launcher

## Zig for implant dev links

- https://github.com/Sobeston/injector

## Comparison of Zig and Nim

|    	 | Zig	 |  Nim  |
|  ----  | ----  | ----  |
| Syntax Styles  | Rust-like | Python-like |
| Backend  | LLVM or Self-hosted | C Compiler or Self-Hosted |
| Code Generate  | Support in future | Supported |
| Standard Library  | General | Numerous |
| Memory Management  | Manual | Multi-paradigm GC |
| FFI | *Directly* | Support |
| Translate C to *ThisLang*  | Official | Third-Party |
| Package Manager  | Official Package Manager as of Zig 0.11 | Nimble |
| Cross Compile | Convenient | Convenient |
| Learning Curve | Intermediate | Easy |
| Community Resources | Growing | Rich |

## Summary

In conclusion, I am not currently inclined to choose Zig as my primary language for offensive purposes. I've also explored alternative languages like [Vlang](https://vlang.io/), but I haven't initiated practical experimentation with them yet. Comparatively, Nim offers superior community resources and more comprehensible documentation than Zig. While attempting to achieve similar outcomes, deciphering Zig's documentation proved to be a challenging endeavor. The manual memory management aspect may not be particularly user-friendly for those without professional development experience. It's possible that as Zig evolves and stabilizes in the future, I might be more inclined to employ it for specific development tasks within penetration testing.

*P.S.: I am not a professional developer; this project is presented solely from the viewpoint of a penetration testing engineer. The opinions expressed above are my own. Please do correct me if you find any errors.*

## Contributors 

<a href="https://github.com/darkr4y/OffensiveZig/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=darkr4y/OffensiveZig" />
</a>
