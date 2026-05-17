import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../services/firestore_service.dart';
import '../../services/prefs_service.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> with SingleTickerProviderStateMixin {
  String _code = '';
  bool _loading = true;
  late AnimationController _pulse;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _scaleAnim = Tween(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    _generate();
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  Future<void> _generate() async {
    final childId = const Uuid().v4().substring(0, 8);
    final code = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
    await FirestoreService.createChild(childId, code);
    await PrefsService.setChildId(childId);
    setState(() { _code = code; _loading = false; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63D5), Color(0xFF9C94E8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Column(children: [
                const SizedBox(height: 48),
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield, color: Colors.white, size: 70),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('MotherEye',
                    style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: 1)),
                const Text('عين الأم',
                    style: TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.w500)),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(children: [
                    const Text(
                      'Donnez ce code à vos parents pour activer la surveillance\nأعطِ هذا الرمز لوالديك لتفعيل المراقبة',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 32, offset: const Offset(0, 12)),
                        ],
                      ),
                      child: Column(children: [
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(color: Color(0xFF6C63D5), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          const Text('CODE DE COUPLAGE',
                              style: TextStyle(color: Color(0xFF9C94E8), fontSize: 12,
                                  fontWeight: FontWeight.w700, letterSpacing: 2)),
                        ]),
                        const SizedBox(height: 20),
                        Text(_code,
                            style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w800,
                                letterSpacing: 12, color: Color(0xFF6C63D5))),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _code));
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Code copié dans le presse-papiers')));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0EEFF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.copy_rounded, size: 14, color: Color(0xFF6C63D5)),
                              SizedBox(width: 6),
                              Text('Copier le code', style: TextStyle(fontSize: 12,
                                  color: Color(0xFF6C63D5), fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6C63D5),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pushReplacement(
                            context, MaterialPageRoute(builder: (_) => const HomeScreen())),
                        child: const Text('Activer la protection — تفعيل الحماية',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ]),
      ),
    ),
  );
}
