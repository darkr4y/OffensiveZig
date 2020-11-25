<p align="center">
    <img height="300" alt="OffensiveZig" src="https://user-images.githubusercontent.com/4407382/100193701-41de7b00-2f2f-11eb-830d-eaf152476dc1.gif">
</p>

# OffensiveZig

The purpose of this project is to do some experiments with [Zig](https://ziglang.org/) to explore the possibility of using it for implant development and general offensive operations. it is inspired from [@byt3bl33d3r](https://twitter.com/byt3bl33d3r)'s project "[OffensiveNim](https://github.com/byt3bl33d3r/OffensiveNim)".


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
  - [Executable size difference when using the 3rd-party windows library vs without](#executable-size-difference-when-using-the-3rd-party-windows-library-vs-without)
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

Nim tutorials are available at [Learn X in Y Minutes](https://learnxinyminutes.com/docs/nim/) and it also has a [Book](https://livebook.manning.com/book/nim-in-action) named *Nim in Action*, but Zig dont't. You can find lots of content referenced from https://ziglearn.org & Zig's main developer youtube channel https://www.youtube.com/channel/UCUICU6mgcyGy61pojwuWyHA* 

## How to play

**Examples in this project**

| File | Description |
| ---  | --- |
| `pop_bin.zig` | Call `MessageBox` WinApi *without* using the 3rd-party library |
| `pop_zigwin32_bin.zig` | Call `MessageBox` *with* the [Zig-win32](https://github.com/GoNZooo/zig-win32) libary |
| `pop_zigwin32_lib.zig` | Example of creating a Windows DLL with an exported `DllMain` |  
| `wmiquery_bin.zig` | Queries running processes and installed AVs using using WMI |
| `shellcode_bin.zig` | Creates a suspended process and injects shellcode with `VirtualAllocEx`/`CreateRemoteThread`. Also demonstrates the usage of compile time definitions to detect arch, os etc..| 
| `http_request_bin.zig` | Demonstrates a couple of ways of making HTTP requests |

I recommand [install zig from a Package Manager](https://github.com/ziglang/zig/wiki/Install-Zig-from-a-Package-Manager). Some of the examples in this project use third-party libraries, unfortunately Zig does not provide official package management at the moment, You need to follow the README.md for using of the third library, or use a package management tool that is in the prototype stage called [zkg](https://github.com/mattnite/zkg). 

## Cross Compiling

See the cross-compilation section in the [Zig compiler usage guide](https://ziglang.org/#Cross-compiling-is-a-first-class-use-case), for a lot more details.

Cross compiling to Windows from MacOs/Nix: `zig build-exe -target x86_64-windows src.zig`

## Interfacing with C/C++

See the insane [Integration with C](https://ziglang.org/#Integration-with-C-libraries-without-FFIbindings) section in the Zig document.

Here's `MessageBox` example

```zig
const std = @import("std");
usingnamespace std.os.windows;

extern "user32" fn MessageBoxA(hWnd: ?HANDLE, lpText: ?LPCTSTR, lpCaption: ?LPCTSTR, uType: UINT) callconv(.Stdcall) c_int;

pub fn main() void {
    _ = MessageBoxA(null, "hello,world!", "title", 0);
}
```

## Creating Windows DLLs with an exported `DllMain`

See the insane [Building a library](https://ziglang.org/documentation/master/#Building-a-Library) section.

As you can see, the code in the example is already very close to what C code looks like, just use `export` keyword.

Example:

```zig
const std = @import("std");
const builtin = @import("builtin");

usingnamespace std.os.windows;

extern "user32" fn MessageBoxA(hWnd: ?HANDLE, lpText: ?LPCTSTR, lpCaption: ?LPCTSTR, uType: UINT) c_int;

const DLL_PROCESS_ATTACH = 1;
const DLL_THREAD_ATTACH = 2;
const DLL_THREAD_DETACH = 3;
const DLL_PROCESS_DETACH = 0;

export fn hello(data: *c_void, size: i32) i32 {
    _ = MessageBoxA(null, "hello, Im in Exported Function", "title", 0);
    return 0;
}
pub export fn DllMain(hInstance: HINSTANCE, ul_reason_for_call: DWORD, lpReserved: LPVOID) BOOL {
    switch(ul_reason_for_call) {
        DLL_PROCESS_ATTACH => {
            _ = MessageBoxA(null, "hello, Im in DllMain", "title", 0);
        },
        DLL_THREAD_ATTACH => {},
        DLL_THREAD_DETACH => {},
        DLL_PROCESS_DETACH =>{},
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

To Check:
```
dumpbin.exe /exports test.dll
Microsoft (R) COFF/PE Dumper Version 14.28.29334.0
Copyright (C) Microsoft Corporation.  All rights reserved.


Dump of file test.dll

File Type: DLL

  Section contains the following exports for test.dll

    00000000 characteristics
           0 time date stamp
        0.00 version
           0 ordinal base
          10 number of functions
           9 number of names

    ordinal hint RVA      name

          1    0 00001AA0 DllMain
          2    1 00001B20 _DllMainCRTStartup
          3    2 00041000 __xl_a
          4    3 00041008 __xl_z
          5    4 00042010 _tls_end
          6    5 0003D018 _tls_index
          7    6 00042000 _tls_start
          8    7 0003A270 _tls_used
          9    8 00001A50 hello

 ......
```

## Optimizing executables for size

Taken from the [Build Mode](https://ziglang.org/documentation/master/#Build-Mode)

For the biggest size decrease use the following flags `--release-small --strip --single-threaded`

a full example for compile windows executable on Macos: `zig build-exe src.zig -O ReleaseSmall --strip --single-threaded -target x86_64-windows`

## Executable size difference when using the 3rd-party windows library vs without

Incredibly enough the size difference is pretty negligible. Especially when you apply the size optimizations outlined above.

Zig has own build system, it provides a cross-platform, dependency-free way to declare the logic required to build a project. use `zig init-exe` command will generate `build.zig` file is automatically. for using 3rd-party lib "[Zig-win32](https://github.com/GoNZooo/zig-win32)", edit your `build.zig`，or copy the zig-win32 folder to the root folder your zig source code, Zig cannot import module from the parent folder of src.

The two examples `pop_bin.zig` and `pop_zigwin32_bin.zig` were created for this purpose. lets have a look:

```
% ll
 - rwx r-x r-x  darkray staff 253.50K 25.Nov'20 15:42 >_ pop_bin.exe
 - rwx r-x r-x  darkray staff 253.50K 25.Nov'20 16:18 >_ pop_zigwin32_bin.exe
```

There seems to be no difference in size from the above results.

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

VSCode also provides two extensions ( `tiehuis.zig`  & `lorenzopirro.zig-snippets` ) to support Zig, although the functionality is very limited at this time.

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

*ps: I am not a pro developer, this project is only from the perspective of a penetration testing engineer. The above opinions are my own,  plz correct me if theres any errors :)*
