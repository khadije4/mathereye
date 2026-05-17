import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/firestore_service.dart';
import '../../services/prefs_service.dart';
import '../../services/ai_agent_service.dart';
import 'setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static const _method = MethodChannel('com.mothereye/detection');
  static const _events = EventChannel('com.mothereye/alerts');

  bool _active = false;
  bool _analyzing = false;
  String? _childId;
  final List<Map<String, dynamic>> _recentAlerts = [];
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnim = Tween(begin: 1.0, end: 1.12).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    PrefsService.getChildId().then((id) => setState(() => _childId = id));
    _events.receiveBroadcastStream().listen((event) async {
      final map = Map<String, dynamic>.from(event as Map);
      final type = map['type'] as String;
      final matched = map['matchedText'] as String? ?? '';
      setState(() {
        _recentAlerts.insert(0, {'type': type, 'text': matched, 'time': DateTime.now()});
        if (_recentAlerts.length > 3) _recentAlerts.removeLast();
      });
      if (_childId != null) await FirestoreService.writeAlert(_childId!, type, matched);
    });
  }

  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  Future<void> _toggle(bool val) async {
    if (val) {
      final ok = await _method.invokeMethod<bool>('requestScreenCapture') ?? false;
      if (ok) setState(() => _active = true);
    } else {
      await _method.invokeMethod('stopDetection');
      setState(() => _active = false);
    }
  }

  Future<void> _analyze() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _analyzing = true);
    final raw = await _method.invokeMethod<String>('flushActivityBuffer') ?? '';
    if (raw.isEmpty || _childId == null) {
      setState(() => _analyzing = false);
      messenger.showSnackBar(const SnackBar(content: Text('Pas encore assez de données')));
      return;
    }
    final recent = await FirestoreService.getRecentReports(_childId!, limit: 5);
    await AiAgentService.analyzeActivity(childId: _childId!, rawText: raw, childAgeHint: '8-16 ans', recentReports: recent);
    setState(() => _analyzing = false);
    if (mounted) {
      messenger.showSnackBar(const SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Rapport envoyé aux parents'),
        ]),
        backgroundColor: Color(0xFF6C63D5),
      ));
    }
  }

  Future<void> _deactivate() async {
    final pin = await PrefsService.getPin();
    if (!mounted) return;
    final entered = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String typed = '';
        return StatefulBuilder(builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Column(children: [
            Icon(Icons.lock_outline, color: Color(0xFF6C63D5), size: 40),
            SizedBox(height: 8),
            Text('Code parental', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700)),
            Text('رمز الوالدين', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) {
              final filled = i < typed.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16, height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? const Color(0xFF6C63D5) : Colors.transparent,
                  border: Border.all(color: const Color(0xFF6C63D5), width: 2),
                ),
              );
            })),
            const SizedBox(height: 20),
            ...['1 2 3', '4 5 6', '7 8 9', '  0  '].map((row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: row.trim().split(' ')
                .where((d) => d.isNotEmpty)
                .map((d) => SizedBox(width: 60, height: 48,
                  child: TextButton(
                    onPressed: () {
                      if (typed.length < 4) {
                        setS(() => typed += d);
                        if (typed.length == 4) {
                          final nav = Navigator.of(ctx);
                          Future.delayed(const Duration(milliseconds: 200), () => nav.pop(typed));
                        }
                      }
                    },
                    style: TextButton.styleFrom(backgroundColor: const Color(0xFFF0EEFF), shape: const CircleBorder()),
                    child: Text(d, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF6C63D5))),
                  ))).toList()),
            )),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler'))],
        ));
      },
    );
    if (entered == null || !mounted) return;
    if (entered == pin) {
      await _method.invokeMethod('stopDetection');
      await PrefsService.clearChildData();
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SetupScreen()));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Code incorrect — رمز خاطئ'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F4FF),
    body: SafeArea(
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF6C63D5), Color(0xFF9C94E8)]),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Row(children: [
            const Icon(Icons.shield, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('MotherEye', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              Text('عين الأم', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
            const Spacer(),
            IconButton(
              onPressed: _deactivate,
              icon: const Icon(Icons.lock_open_outlined, color: Colors.white),
              tooltip: 'Désactiver',
            ),
          ]),
        ),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const SizedBox(height: 12),

            // Shield status card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: const Color(0xFF6C63D5).withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: Column(children: [
                if (_active)
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63D5).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield, color: Color(0xFF6C63D5), size: 72),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                    child: Icon(Icons.shield_outlined, color: Colors.grey[400], size: 72),
                  ),
                const SizedBox(height: 20),
                Text(
                  _active ? 'Protection active' : 'Protection inactive',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                      color: _active ? const Color(0xFF6C63D5) : Colors.grey[600]),
                ),
                Text(
                  _active ? 'الحماية نشطة' : 'الحماية غير نشطة',
                  style: TextStyle(fontSize: 14, color: _active ? const Color(0xFF9C94E8) : Colors.grey[400]),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => _toggle(!_active),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 80, height: 40,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: _active ? const Color(0xFF6C63D5) : Colors.grey[300],
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 300),
                      alignment: _active ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(width: 32, height: 32, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // Recent alerts
            if (_recentAlerts.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Alertes récentes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF3D3D3D))),
              ),
              const SizedBox(height: 10),
              ..._recentAlerts.map((a) => _LocalAlertTile(alert: a)),
              const SizedBox(height: 16),
            ],

            // Analyze button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _analyzing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.psychology_rounded),
                label: Text(_analyzing ? 'Analyse en cours...' : 'Analyser l\'activité — تحليل النشاط'),
                onPressed: (_active && !_analyzing) ? _analyze : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63D5),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[200],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ]),
        )),
      ]),
    ),
  );
}

class _LocalAlertTile extends StatelessWidget {
  final Map<String, dynamic> alert;
  const _LocalAlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final isNsfw = alert['type'] == 'nsfw_image';
    final color = isNsfw ? Colors.red : Colors.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(children: [
        Icon(isNsfw ? Icons.image_not_supported_rounded : Icons.chat_bubble_outline_rounded,
            color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(
          isNsfw ? 'Image suspecte détectée' : '"${alert['text']}"',
          style: TextStyle(fontSize: 13, color: Colors.grey[800]),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        )),
      ]),
    );
  }
}
