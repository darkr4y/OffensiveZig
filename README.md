<p align="center">
    <img height="300" alt="OffensiveZig" src="https://user-images.githubusercontent.com/4407382/100193701-41de7b00-2f2f-11eb-830d-eaf152476dc1.gif">
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

## Why Zig?

- Zig's backend using LLVM and also can be as a C compiler, Nim can use it to compile. [ [wikipedia](https://en.wikipedia.org/wiki/Zig_(programming_language)) ]
- The feature about generation of human-readable C code may be supported in the future. [ [issue #3772](https://github.com/ziglang/zig/issues/3772) ] 
- Zig doesn't rely on a VM/runtime, the static executable is super small.
- Rust inspired syntax, allows rapid native payload creation & prototyping.
- Integration with C libraries without FFI/bindings.
- Manual memory management, no hidden control flow.
- Its very easy to do cross-compile things and can build for any of the targets from [here](https://ziglang.org/#Support-Table), no "cross toolchain" needs to be installed or anything like that.
- To Learn `zig zen`: together we serve the users.

## Try to Learn Zig in Y minutes

If you're eager to learn Zig quickly and effectively, there's a wealth of resources to aid your journey. For a rapid grasp of Zig's syntax and concepts, you can dive into the Learn Zig in Y Minutes guide. To delve deeper into Zig's intricacies, explore the official documentation for various Zig versions at Zig's official documentation. Engage with the vibrant Zig community through the Zig Community Forum, where valuable learning content and discussions await. Additionally, the Zig main developer's YouTube channel, Andrew Kelley, offers insightful videos and discussions.

## How to play

**Examples in this project**

| File | Description |
| ---  | --- |
| `pop_bin.zig` | Call `MessageBox` WinApi *without* using a 3rd-party library |
| `pop_lib.zig` | Example of creating a Windows DLL with an exported `DllMain` |  
| `shellcode_bin.zig` | Creates a suspended process and injects shellcode with `VirtualAllocEx`/`CreateRemoteThread`. Also demonstrates the usage of compile time definitions to detect arch, os etc..| 

I recommend downloading Zig for different CPU architectures directly from Zig's official download page, available at https://ziglang.org/download/. In certain cases within this project, third-party libraries are employed. Although Zig now features an official package manager as of version 0.11, it's still in its early stages of development. For guidance on utilizing these third-party libraries, consult the project's README.md.

## Cross Compiling

See the cross-compilation section in the [Zig compiler usage guide](https://ziglang.org/#Cross-compiling-is-a-first-class-use-case), for a lot more details.

Cross compiling to Windows from MacOs/Nix: `zig build-exe -target x86_64-windows src.zig`

## Interfacing with C/C++

See the insane [Integration with C](https://ziglang.org/#Integration-with-C-libraries-without-FFIbindings) section in the Zig document.

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

See the insane [Building a library](https://ziglang.org/documentation/master/#Building-a-Library) section.

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

const DLL_PROCESS_DETACH: DWORD = 0;
const DLL_PROCESS_ATTACH: DWORD = 1;
const DLL_THREAD_ATTACH: DWORD = 2;
const DLL_THREAD_DETACH: DWORD = 3;

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

For the biggest size decrease use the following flags `--release-small --strip --single-threaded`

a full example for compile windows executable on Macos: `zig build-exe src.zig -O ReleaseSmall --strip --single-threaded -target x86_64-windows`

## Opsec Considerations

All samples are compiled in this mode `zig build-exe src.zig -O ReleaseSmall --strip --single-threaded -target x86_64-windows`

Aside from a few specific NT functions found in the import table, I have not been able to find any other significant features that would indicate that they were coded in Zig.

![image](https://user-images.githubusercontent.com/4407382/100207487-9a6b4380-2f42-11eb-8b43-0bbf8d619be7.png)


## Converting C code to Zig

Zig already provides the ability to translate C to Zig code, just try `zig translate-c`

Used it to translate a bunch of small C snippets, I haven't tried using this feature yet.

## Language Bridges

About python module or Java JNI, I have not tried it yet.

Ref:

- https://github.com/kristoff-it/zig-cuckoofilter/
- https://github.com/ziglang/zig/issues/5795
- https://lists.sr.ht/~andrewrk/ziglang/%20%3CCACZYt3T8jACL+3Z_NMW8yYvcJ+5oyP%3Dh1s2HHdDL_VxYQH5rzQ%40mail.gmail.com%3E

## Debugging

Use the function of `std.debug` namespace to show the call stack, and there is no IDE has good support for Zig's Debugging yet. If you use VSCode, try this extension ( `webfreak.debug` ), plz check this link[ [1](https://www.reddit.com/r/Zig/comments/cl0x6k/debugging_zig_in_vscode/) ][ [2](https://dev.to/watzon/debugging-zig-with-vs-code-44ca) ]for more details.



## Setting up a dev environment

VSCode provides an official Zig extension (ziglang.vscode-zig) to enhance Zig language support, offering more comprehensive functionality compared to earlier extensions such as 'tiehuis.zig' and 'lorenzopirro.zig-snippets'.

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

## Zig for implant dev links

- https://github.com/Sobeston/injector

## Comparison of Zig and Nim

|    	 | Zig	 |  Nim  |
|  ----  | ----  | ----  |
| Syntax Styles  | like Rust | like Python |
| Backend  | LLVM or Self-hosted | Others C Compiler or Self-Hosted |
| Code Generate  | Support in future | Supported |
| Standard Library  | General | Numerous |
| Memory Management  | Manual | Multi-paradigm GC |
| FFI | *Directly* | Support |
| Translate C to *ThisLang*  | Official | Third-Party |
| Package Manager  | N/A | Nimble |
| Cross Compile | Convenient | Convenient |
| Executable Size (windows x86 debug mode) | ~200K | ~300K |
| Learning Curve | Not so easy | Easy |
| Community Resources | Poor | Rich |

## Summary

In summary, I wouldn't be willing to use Zig as my primary Offensive language at this time，I've also looked at similar languages, such as [Vlang](https://vlang.io/), but still haven't started trying them out. Nim has better community resources and clearer documentation than Zig, reading the documentation became a pain when trying to get Zig to do the same job. Manual memory management is not very friendly for non-professional developers, so maybe when Zig stabilizes in the future, I'll be more willing to use it for some development work in penetration testing.

*P.S.: I am not a professional developer; this project is presented solely from the viewpoint of a penetration testing engineer. The opinions expressed above are my own. Please do correct me if you find any errors.*
