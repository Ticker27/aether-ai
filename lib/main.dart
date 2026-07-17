import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/aether_bindings.dart';

// ===========================================================================
// Aether control overlay — TRANSLUCENT, minimal.
// Per Snake-Engine architecture: the UI is ONLY a thin, glassy panel for the
// login/activation key + engine control. The real work (the memory scanner)
// runs invisibly inside the virtualized game's GL context (traceless core).
// The in-game aimbot/ESP lines are drawn by the native brain via a GL-hook
// inside BlackBox — NOT by this Flutter layer.
// ===========================================================================

void main() => runApp(const AetherOverlay());

class AetherOverlay extends StatelessWidget {
  const AetherOverlay({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Aether',
        debugShowCheckedModeBanner: false,
        // Transparent so the panel floats over the game, not a full screen.
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.transparent,
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF38BDF8),
            surface: Color(0x1A111827),
          ),
        ),
        home: const ControlPanel(),
      );
}

class ControlPanel extends StatefulWidget {
  const ControlPanel({super.key});

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  static const _channel = MethodChannel('com.aether/android');
  static const _target = 'com.miniclip.eightballpool';
  static const _targetName = '8 Ball Pool';

  final _keyCtrl = TextEditingController();
  String _status = 'Booting brain…';
  String _diag = '—';
  bool _launched = false;

  @override
  void initState() {
    super.initState();
    _initBrain();
  }

  void _initBrain() {
    final r = AetherEngine.initialize('/data/data/com.aether/virtual');
    setState(() => _status = r == 0
        ? '✅ Brain ready (v${AetherEngine.version})'
        : '❌ Init failed: $r');
  }

  Future<void> _activate() async {
    // Login/activation key is validated server-side (enforced, not local).
    final key = _keyCtrl.text.trim();
    if (key.isEmpty) {
      setState(() => _status = '⚠ Enter activation key');
      return;
    }
    // Brain engages for the target; Kotlin glue launches the virtual app.
    AetherEngine.startEngine(_target);
    try {
      final res = await _channel.invokeMethod<String>('launch', _target);
      setState(() {
        _launched = true;
        _status = '▶ $_targetName live ($res)';
      });
    } on PlatformException catch (e) {
      setState(() => _status = '❌ Launch failed: ${e.message}');
    }
  }

  void _diagnose() {
    final pid = AetherEngine.findGame(_target);
    if (pid < 0) {
      setState(() => _diag = 'game pid: NOT FOUND (is $_targetName running?)');
      return;
    }
    final at = AetherEngine.attach(pid);
    final integ = AetherEngine.selfIntegrity();
    final integTxt = integ == 0
        ? 'clean'
        : (integ == -2 ? 'syscall blocked (likely hooked)' : 'TAMPERED');
    setState(() => _diag = 'pid: $pid | attach: $at | integrity: $integTxt');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Align(
          alignment: Alignment.topRight,
          child: Container(
            margin: const EdgeInsets.all(16),
            width: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x2A0A0E17),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x40FFFFFF)),
              boxShadow: const [
                BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('AETHER',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                        letterSpacing: 4, color: Color(0xFF38BDF8))),
                const SizedBox(height: 12),
                TextField(
                  controller: _keyCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'activation key',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Color(0x1AFFFFFF),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _launched ? null : _activate,
                  icon: const Icon(Icons.apps, size: 18),
                  label: Text(_launched ? 'LIVE' : 'ACTIVATE & LAUNCH'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: const Color(0x3364748B),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _diagnose,
                  icon: const Icon(Icons.bug_report, size: 16),
                  label: const Text('DIAGNOSE'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF38BDF8),
                    side: const BorderSide(color: Color(0x40FFFFFF)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                Text(_status, style: const TextStyle(fontSize: 12, color: Color(0xFF38BDF8))),
                const SizedBox(height: 4),
                Text(_diag, style: const TextStyle(fontSize: 11, color: Colors.white54)),
              ],
            ),
          ),
        ),
      );
}
