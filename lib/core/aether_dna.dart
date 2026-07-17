import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'core/aether_bindings.dart';

/// Dynamic DNA coordinator (Dart side).
///
/// Reads the versioned DNA handbook (target.json), parses pointer-chains, and
/// drives the C++ brain's memory primitives. The brain stays a PURE memory
/// engine (read/write/chain); DNA parsing + OTA coordination lives here.
///
/// OTA model: replace the file in app storage -> reload on next call.
/// No APK rebuild, no process restart. The engine "upgrades itself" when the
/// game ships a new version — only this small JSON changes, never libaether.so.
class AetherDna {
  static const String _appPath = '/data/data/com.aether/dna/target.json';
  static const String _assetPath = 'dna/target.json';

  Map<String, dynamic>? _doc;
  String? game;
  List<String> versionOk = const [];
  bool telemetryOnly = true;
  int readPollMs = 800;

  /// Load DNA: app storage first (OTA target), fallback to bundled asset.
  Future<bool> load() async {
    String raw;
    final f = File(_appPath);
    if (await f.exists()) {
      raw = await f.readAsString();
    } else {
      raw = await rootBundle.loadString(_assetPath);
    }
    try {
      _doc = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return false;
    }
    game = _doc?['game'] as String?;
    versionOk = List<String>.from(_doc?['version_ok'] ?? []);
    telemetryOnly = _doc?['telemetry_only'] ?? true;
    readPollMs = _doc?['read_poll_ms'] ?? 800;
    return true;
  }

  /// Resolve a named chain's hex offsets into ints.
  List<int>? chainOffsets(String name) {
    final chains = _doc?['chains'] as Map<String, dynamic>?;
    final c = chains?[name] as Map<String, dynamic>?;
    if (c == null) return null;
    final offs = (c['offsets_hex'] as List?)?.map((e) => int.parse(e.toString(), radix: 16)).toList();
    return offs?.cast<int>();
  }

  String? chainBaseModule(String name) {
    final chains = _doc?['chains'] as Map<String, dynamic>?;
    return (chains?[name] as Map<String, dynamic>?)?['base_module'] as String?;
  }

  String? readKind(String name) {
    final chains = _doc?['chains'] as Map<String, dynamic>?;
    return (chains?[name] as Map<String, dynamic>?)?['read_as'] as String?;
  }

  /// Walk a named chain. [baseAddr] = module base (resolved by caller).
  int? walk(String name, int baseAddr) {
    final offs = chainOffsets(name);
    if (offs == null || offs.isEmpty) return null;
    return AetherEngine.resolveChain(baseAddr, offs);
  }

  /// Lightweight module-base resolver: read /proc/<pid>/maps (coordination
  /// task, not a brain primitive). Returns the load base of [module] in [pid].
  static int? moduleBase(int pid, String module) {
    try {
      final maps = File('/proc/$pid/maps').readAsLinesSync();
      for (final line in maps) {
        if (line.contains(module) && line.contains('r-xp')) {
          final hex = line.split(' ').first.split('-').first;
          return int.parse(hex, radix: 16);
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
