import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

/// Bridge from the Flutter UI to the C++ brain (libaether.so) via dart:ffi.
/// The C++ side owns all engine logic; Dart only calls into it.
final DynamicLibrary _lib = Platform.isAndroid
    ? DynamicLibrary.open('libaether.so')
    : DynamicLibrary.process();

// aether_init
typedef _CAetherInit = Int32 Function(Pointer<Utf8> workDir);
typedef _DAetherInit = int Function(Pointer<Utf8> workDir);
final _init = _lib
    .lookup<NativeFunction<_CAetherInit>>('aether_init')
    .asFunction<_DAetherInit>();

// aether_start_engine
typedef _CAetherStart = Int32 Function(Pointer<Utf8> target);
typedef _DAetherStart = int Function(Pointer<Utf8> target);
final _startEngine = _lib
    .lookup<NativeFunction<_CAetherStart>>('aether_start_engine')
    .asFunction<_DAetherStart>();

// aether_is_initialized
typedef _CAetherIsInit = Int32 Function();
typedef _DAetherIsInit = int Function();
final _isInitialized = _lib
    .lookup<NativeFunction<_CAetherIsInit>>('aether_is_initialized')
    .asFunction<_DAetherIsInit>();

// aether_version
typedef _CAetherVersion = Pointer<Utf8> Function();
typedef _DAetherVersion = Pointer<Utf8> Function();
final _version = _lib
    .lookup<NativeFunction<_CAetherVersion>>('aether_version')
    .asFunction<_DAetherVersion>();

class AetherEngine {
  /// Boot the brain with a working directory.
  static int initialize(String workDir) => _init(workDir.toNativeUtf8());

  /// Engage the brain for a target package (8 Ball Pool now).
  static int startEngine(String targetPackage) =>
      _startEngine(targetPackage.toNativeUtf8());

  static bool get isInitialized => _isInitialized() == 1;

  static String get version => _version().toDartString();
}
