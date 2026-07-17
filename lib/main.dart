import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/aether_bindings.dart';

void main() => runApp(const AetherApp());

class AetherApp extends StatelessWidget {
  const AetherApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Aether',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0A0E17),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF38BDF8),
            surface: Color(0xFF111827),
          ),
        ),
        home: const HomeScreen(),
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // MethodChannel → Kotlin glue (Android execution only).
  static const _channel = MethodChannel('com.aether/android');

  // Hardcoded target — flexible later.
  static const _target = 'com.miniclip.eightballpool';
  static const _targetName = '8 Ball Pool';

  String _status = 'Initializing…';
  String _version = '';

  @override
  void initState() {
    super.initState();
    _initBrain();
  }

  void _initBrain() {
    final r = AetherEngine.initialize('/data/data/com.aether/virtual');
    setState(() {
      _version = AetherEngine.version;
      _status = r == 0
          ? '✅ Brain Ready (v$_version)'
          : '❌ Init Failed: $r';
    });
  }

  Future<void> _launch() async {
    // 1) Brain engages for the target (logic lives in C++).
    AetherEngine.startEngine(_target);
    // 2) Android glue actually launches the app (OS call).
    try {
      final res = await _channel.invokeMethod<String>('launch', _target);
      setState(() => _status = '▶ Launched $_targetName ($res)');
    } on PlatformException catch (e) {
      setState(() => _status = '❌ Launch failed: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.layers_outlined, size: 80, color: Color(0xFF38BDF8)),
              const SizedBox(height: 24),
              const Text(
                'AETHER',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Virtualization Engine',
                style: TextStyle(fontSize: 14, color: Colors.white54, letterSpacing: 2),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Text(
                  _status,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF38BDF8)),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _launch,
                icon: const Icon(Icons.apps),
                label: const Text('LAUNCH 8 BALL POOL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
