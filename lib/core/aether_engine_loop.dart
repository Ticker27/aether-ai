import 'dart:async';
import 'core/aether_bindings.dart';
import 'core/aether_dna.dart';

/// Processed scan result — small, telemetry-only. Never carries raw game
/// memory; only the derived values the consumer (render/AI, later) needs.
class AetherFrame {
  final double aimAngle;
  final double cueAngle;
  final int ballCount;
  final int tick;
  AetherFrame({
    required this.aimAngle,
    required this.cueAngle,
    required this.ballCount,
    required this.tick,
  });
}

/// Tiny LRU for resolved chain addresses. Module base is stable while the
/// game runs, so we cache the final address and read directly (fluid: skips
/// the per-tick pointer walk). On an unreadable link we invalidate and
/// re-walk next tick (traceless: no stale pointers, no dumps).
class _AddrCache {
  final int _cap;
  final Map<String, int> _m = {};
  _AddrCache(this._cap);
  int? get(String k) {
    final v = _m.remove(k);
    if (v != null) _m[k] = v; // touch -> MRU
    return v;
  }

  void put(String k, int v) {
    if (_m.length >= _cap && _m.isNotEmpty) _m.remove(_m.keys.first);
    _m[k] = v;
  }

  void invalidate() => _m.clear();
}

/// The DNA Processing Thread (L2). Scans via the C++ brain, processes the
/// read values, and emits a small AetherFrame. This is the "scan -> process
/// -> send onward" heart: it never dumps game memory, only forwards derived
/// data.
///
/// Game version changed? Ship a new dna/target.json (OTA) — this loop picks
/// it up on the next tick without a rebuild or restart.
Stream<AetherFrame> startDnaLoop(AetherDna dna) async* {
  final pid = AetherEngine.findGame(dna.game ?? '');
  if (pid < 0) return; // game not running -> empty stream
  AetherEngine.attach(pid);

  final cache = _AddrCache(8);
  var tick = 0;

  int? resolve(String name, int base) {
    final cached = cache.get(name);
    if (cached != null && cached > 0) return cached;
    final addr = dna.walk(name, base);
    if (addr != null && addr > 0) cache.put(name, addr);
    return addr;
  }

  while (true) {
    tick++;
    final baseMod = dna.chainBaseModule('aim_angle') ?? '';
    final base = AetherDna.moduleBase(pid, baseMod);
    if (base == null) {
      cache.invalidate();
      await Future.delayed(Duration(milliseconds: dna.readPollMs));
      continue;
    }

    final aimAddr = resolve('aim_angle', base);
    final cueAddr = resolve('cue_angle', base);
    final ballAddr = resolve('ball_table_base', base);

    if (aimAddr == null || aimAddr <= 0 || cueAddr == null || cueAddr <= 0) {
      cache.invalidate(); // re-walk next tick
      await Future.delayed(Duration(milliseconds: dna.readPollMs));
      continue;
    }

    final aim = AetherEngine.readF32(aimAddr);
    final cue = AetherEngine.readF32(cueAddr);
    final ballCount = (ballAddr != null && ballAddr > 0)
        ? AetherEngine.readI32(ballAddr)
        : 0;

    yield AetherFrame(
      aimAngle: aim,
      cueAngle: cue,
      ballCount: ballCount,
      tick: tick,
    );

    await Future.delayed(Duration(milliseconds: dna.readPollMs));
  }
}
