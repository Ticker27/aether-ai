cmake_minimum_required(VERSION 3.22.1)
project(aether_engine CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Produces libaether.so (the brain), bundled into the APK by Flutter's
# externalNativeBuild and loaded from Dart via DynamicLibrary.open().
add_library(aether SHARED
    src/aether_engine.cpp)

# Header lives in include/ (separate from src/).
target_include_directories(aether PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
