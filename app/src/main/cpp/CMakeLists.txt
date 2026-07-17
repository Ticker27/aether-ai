cmake_minimum_required(VERSION 3.22.1)
project(aether_engine CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(aether SHARED
    src/aether_engine.cpp)

find_library(log-lib log)
target_link_libraries(aether ${log-lib})
