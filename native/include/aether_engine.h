#pragma once
#include <cstdint>

#ifdef __cplusplus
extern "C" {
#endif

// C++ BRAIN public API — called from the Flutter UI via dart:ffi.
int32_t aether_init(const char* work_dir);
int32_t aether_start_engine(const char* target_package);
int32_t aether_is_initialized();
const char* aether_version();

#ifdef __cplusplus
}
#endif
