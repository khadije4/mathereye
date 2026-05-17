import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../services/prefs_service.dart';
import '../../services/fcm_service.dart';
import 'dashboard_screen.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});
  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  String _code = '';
  bool _loading = false;
  String _error = '';

  void _onKey(String digit) {
    if (_code.length < 6) setState(() { _code += digit; _error = ''; });
    if (_code.length == 6) _pair();
  }

  void _onDelete() {
    if (_code.isNotEmpty) setState(() { _code = _code.substring(0, _code.length - 1); _error = ''; });
  }

  Future<void> _pair() async {
    setState(() { _loading = true; _error = ''; });
    final childId = await FirestoreService.findChildByCode(_code);
    if (childId == null) {
      setState(() { _loading = false; _error = 'Code invalide — رمز غير صحيح'; _code = ''; });
      return;
    }
    await PrefsService.setPairedChildId(childId);
    if (FcmService.token != null) await FirestoreService.saveParentToken(childId, FcmService.token!);
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63D5), Color(0xFF9C94E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(children: [
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.family_restroom_rounded, color: Colors.white, size: 56),
          ),
          const SizedBox(height: 20),
          const Text('Application Parent', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const Text('تطبيق الوالدين', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 32),
          const Text('Entrez le code affiché sur le téléphone de l\'enfant\nأدخل الرمز المعروض على هاتف طفلك',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6)),
          const SizedBox(height: 28),
          // Code display boxes
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(6, (i) {
            final hasDigit = i < _code.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 44, height: 54,
              decoration: BoxDecoration(
                color: hasDigit ? Colors.white : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Center(child: Text(
                hasDigit ? _code[i] : '',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF6C63D5)),
              )),
            );
          })),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(12)),
              child: Text(_error, style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ],
          const Spacer(),
          if (_loading)
            const CircularProgressIndicator(color: Colors.white)
          else
            Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
              ),
              child: Column(children: [
                _numRow(['1', '2', '3']),
                const SizedBox(height: 12),
                _numRow(['4', '5', '6']),
                const SizedBox(height: 12),
                _numRow(['7', '8', '9']),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  const SizedBox(width: 72),
                  _NumKey('0', onTap: () => _onKey('0')),
                  SizedBox(width: 72, height: 60,
                    child: TextButton(
                      onPressed: _onDelete,
                      style: TextButton.styleFrom(shape: const CircleBorder()),
                      child: const Icon(Icons.backspace_outlined, color: Color(0xFF6C63D5), size: 24),
                    )),
                ]),
              ]),
            ),
        ]),
      ),
    ),
  );

  Widget _numRow(List<String> digits) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: digits.map((d) => _NumKey(d, onTap: () => _onKey(d))).toList(),
  );
}

class _NumKey extends StatelessWidget {
  final String digit;
  final VoidCallback onTap;
  const _NumKey(this.digit, {required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 72, height: 60,
    child: TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(backgroundColor: const Color(0xFFF0EEFF), shape: const CircleBorder()),
      child: Text(digit, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF6C63D5))),
    ),
  );
}
