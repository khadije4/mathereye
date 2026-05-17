import 'package:flutter/material.dart';
import '../../services/prefs_service.dart';
import 'setup_screen.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});
  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _pin1 = '';
  String _pin2 = '';
  bool _confirming = false;
  String _error = '';

  void _onKey(String digit) {
    setState(() {
      _error = '';
      if (!_confirming) {
        if (_pin1.length < 4) {
          _pin1 += digit;
          if (_pin1.length == 4) {
            Future.delayed(const Duration(milliseconds: 250), () {
              if (mounted) setState(() => _confirming = true);
            });
          }
        }
      } else {
        if (_pin2.length < 4) {
          _pin2 += digit;
          if (_pin2.length == 4) {
            Future.delayed(const Duration(milliseconds: 250), _validate);
          }
        }
      }
    });
  }

  void _onDelete() {
    setState(() {
      _error = '';
      if (_confirming) {
        if (_pin2.isNotEmpty) _pin2 = _pin2.substring(0, _pin2.length - 1);
      } else {
        if (_pin1.isNotEmpty) _pin1 = _pin1.substring(0, _pin1.length - 1);
      }
    });
  }

  Future<void> _validate() async {
    if (_pin1 != _pin2) {
      setState(() {
        _error = 'Codes différents — الرمزان مختلفان';
        _pin2 = '';
        _confirming = false;
        _pin1 = '';
      });
      return;
    }
    await PrefsService.setPin(_pin1);
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SetupScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _confirming ? _pin2 : _pin1;
    return Scaffold(
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
            const Icon(Icons.shield_outlined, color: Colors.white, size: 56),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _confirming ? 'Confirmer le code\nتأكيد الرمز' : 'Créer un code parental\nأنشئ رمز الوالدين',
                key: ValueKey(_confirming),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, height: 1.4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _confirming ? 'Retapez votre code' : 'Mémorisez-le — ce code désactive la protection',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < current.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? Colors.white : Colors.transparent,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                );
              }),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_error, style: const TextStyle(color: Colors.white, fontSize: 13),
                    textAlign: TextAlign.center),
              ),
            ],
            const Spacer(),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
              ),
              child: Column(children: [
                _numRow(['1', '2', '3']),
                const SizedBox(height: 14),
                _numRow(['4', '5', '6']),
                const SizedBox(height: 14),
                _numRow(['7', '8', '9']),
                const SizedBox(height: 14),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  const SizedBox(width: 72),
                  _NumKey('0', onTap: () => _onKey('0')),
                  SizedBox(
                    width: 72, height: 72,
                    child: TextButton(
                      onPressed: _onDelete,
                      style: TextButton.styleFrom(shape: const CircleBorder()),
                      child: const Icon(Icons.backspace_outlined, color: Color(0xFF6C63D5), size: 26),
                    ),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

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
    width: 72, height: 72,
    child: TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFFF0EEFF),
        shape: const CircleBorder(),
      ),
      child: Text(digit,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF6C63D5))),
    ),
  );
}
