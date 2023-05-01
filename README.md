# Simple C++20 module support for CMake

[![](https://github.com/vitaut/modules/workflows/linux/badge.svg)](https://github.com/vitaut/modules/actions?query=workflow%3Alinux)
[![](https://github.com/vitaut/modules/workflows/windows/badge.svg)](https://github.com/vitaut/modules/actions?query=workflow%3Awindows)

Provides the `add_module_library` CMake function that is a wrapper around `add_library` with additional module-specific rules. 

This module currently supports:
* Clang 15+ 
* GCC 11+
* MSVC 19.28+

This module can also fallback to a non-modular library for compatibility.

Projects using `add_module_library`:

* [{fmt}](https://github.com/fmtlib/fmt): a modern formatting library

## Example

`cat hello.cc`:
```c++
module;

#include <cstdio>

export module hello;

export void hello() { std::printf("Hello, modules!\n"); }
```

`cat main.cc`:
```c++
import hello;

int main() { hello(); }
```

`cat CMakeLists.txt`:
```cmake
cmake_minimum_required(VERSION 3.11)
project(HELLO CXX)

include(simple_module.cmake)

add_module_library(hello example/hello.cc)

add_executable(main example/main.cc)
target_link_libraries(main hello)
```

Building with clang:

```
CXX=clang++ cmake .
make
```

Running:

```
$ ./main
Hello, modules!
```
