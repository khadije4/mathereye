import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/child/pin_setup_screen.dart';
import 'screens/child/setup_screen.dart';
import 'screens/child/home_screen.dart';
import 'services/prefs_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ChildApp());
}

class ChildApp extends StatelessWidget {
  const ChildApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MotherEye',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7F77DD)), useMaterial3: true),
    home: const _AppRouter(),
  );
}

class _AppRouter extends StatefulWidget {
  const _AppRouter();
  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  bool _loading = true;
  bool _hasPin = false;
  bool _hasChild = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pin = await PrefsService.getPin();
    final id  = await PrefsService.getChildId();
    setState(() {
      _hasPin   = pin != null;
      _hasChild = id != null;
      _loading  = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!_hasPin) return const PinSetupScreen();
    return _hasChild ? const HomeScreen() : const SetupScreen();
  }
}
