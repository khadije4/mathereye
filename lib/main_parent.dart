import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/parent/pairing_screen.dart';
import 'screens/parent/dashboard_screen.dart';
import 'services/prefs_service.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FcmService.init();
  runApp(const ParentApp());
}

class ParentApp extends StatelessWidget {
  const ParentApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MotherEye Parent',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7F77DD)), useMaterial3: true),
    home: const _ParentRouter(),
  );
}

class _ParentRouter extends StatefulWidget {
  const _ParentRouter();
  @override
  State<_ParentRouter> createState() => _ParentRouterState();
}

class _ParentRouterState extends State<_ParentRouter> {
  bool _loading = true, _paired = false;

  @override
  void initState() {
    super.initState();
    PrefsService.getPairedChildId().then((id) => setState(() { _paired = id != null; _loading = false; }));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return _paired ? const DashboardScreen() : const PairingScreen();
  }
}
