import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

/// Bridge from the Flutter UI to the C++ brain (libaether.so) via dart:ffi.
/// The C++ side owns all engine logic; Dart only calls into it.
final DynamicLibrary _lib = Platform.isAndroid
    ? DynamicLibrary.open('libaether.so')
    : DynamicLibrary.process();

// aether_init
typedef _CAetherInit = Int32 Function(Pointer<Utf8> workDir);
typedef _DAetherInit = int Function(Pointer<Utf8> workDir);
final _init = _lib.lookupFunction<_CAetherInit, _DAetherInit>('aether_init');

// aether_start_engine
typedef _CAetherStart = Int32 Function(Pointer<Utf8> target);
typedef _DAetherStart = int Function(Pointer<Utf8> target);
final _startEngine = _lib.lookupFunction<_CAetherStart, _DAetherStart>('aether_start_engine');

// aether_is_initialized
typedef _CAetherIsInit = Int32 Function();
typedef _DAetherIsInit = int Function();
final _isInitialized = _lib.lookupFunction<_CAetherIsInit, _DAetherIsInit>('aether_is_initialized');

// aether_version
typedef _CAetherVersion = Pointer<Utf8> Function();
typedef _DAetherVersion = Pointer<Utf8> Function();
final _version = _lib.lookupFunction<_CAetherVersion, _DAetherVersion>('aether_version');

// aether_syscall_raw
typedef _CSyscall = Int64 Function(Int64 n, Int64 a1, Int64 a2, Int64 a3, Int64 a4, Int64 a5, Int64 a6);
typedef _DSyscall = int Function(int n, int a1, int a2, int a3, int a4, int a5, int a6);
final _syscallRaw = _lib.lookupFunction<_CSyscall, _DSyscall>('aether_syscall_raw');

// aether_attach
typedef _CAttach = Int32 Function(Int32 pid);
typedef _DAttach = int Function(int pid);
final _attach = _lib.lookupFunction<_CAttach, _DAttach>('aether_attach');

// aether_find_game
typedef _CFind = Int32 Function(Pointer<Utf8> pkg);
typedef _DFind = int Function(Pointer<Utf8> pkg);
final _findGame = _lib.lookupFunction<_CFind, _DFind>('aether_find_game');

// aether_vm_read
typedef _CRead = Int64 Function(Int64 addr, Pointer<Void> buf, Int64 len);
typedef _DRead = int Function(int addr, Pointer<Void> buf, int len);
final _vmRead = _lib.lookupFunction<_CRead, _DRead>('aether_vm_read');

// aether_vm_write
typedef _CWrite = Int64 Function(Int64 addr, Pointer<Void> buf, Int64 len);
typedef _DWrite = int Function(int addr, Pointer<Void> buf, int len);
final _vmWrite = _lib.lookupFunction<_CWrite, _DWrite>('aether_vm_write');

// aether_self_integrity
typedef _CIntegrity = Int32 Function();
typedef _DIntegrity = int Function();
final _selfIntegrity = _lib.lookupFunction<_CIntegrity, _DIntegrity>('aether_self_integrity');

class AetherEngine {
  /// Boot the brain with a working directory.
  static int initialize(String workDir) => _init(workDir.toNativeUtf8());

  /// Engage the brain for a target package.
  static int startEngine(String targetPackage) => _startEngine(targetPackage.toNativeUtf8());

  static bool get isInitialized => _isInitialized() == 1;
  static String get version => _version().toDartString();

  /// Raw AArch64 syscall (diagnostics / escape hatch).
  static int syscallRaw(int n, [int a1 = 0, int a2 = 0, int a3 = 0, int a4 = 0, int a5 = 0, int a6 = 0]) =>
      _syscallRaw(n, a1, a2, a3, a4, a5, a6);

  /// Attach to a target game process by PID.
  static int attach(int pid) => _attach(pid);

  /// Discover a game's PID by package name (scans /proc).
  static int findGame(String packageName) => _findGame(packageName.toNativeUtf8());

  /// Read `length` bytes from the target at `address`. Returns bytes or null.
  static Uint8List? vmRead(int address, int length) {
    final buf = calloc<Uint8>(length);
    try {
      final n = _vmRead(address, buf.cast(), length);
      if (n < 0) return null;
      return Uint8List.fromList(buf.asTypedList(n));
    } finally {
      calloc.free(buf);
    }
  }

  /// Write `bytes` into the target at `address`. Returns bytes written or -1.
  static int vmWrite(int address, Uint8List bytes) {
    final buf = calloc<Uint8>(bytes.length);
    try {
      buf.asTypedList(bytes.length).setAll(0, bytes);
      return _vmWrite(address, buf.cast(), bytes.length);
    } finally {
      calloc.free(buf);
    }
  }

  /// Self-integrity check (anti-tamper). 0 = clean.
  static int selfIntegrity() => _selfIntegrity();
}
