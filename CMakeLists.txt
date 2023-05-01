cmake_minimum_required(VERSION 3.24)
project(HELLO CXX)

include(simple_module.cmake)
add_module_library(hello example/hello.cc)

add_executable(main example/main.cc)
target_link_libraries(main hello)
