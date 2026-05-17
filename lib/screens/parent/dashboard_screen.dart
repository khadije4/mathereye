import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../services/prefs_service.dart';
import '../../widgets/alert_card.dart';
import '../../widgets/report_card.dart';
import 'pairing_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  String? _childId;
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    PrefsService.getPairedChildId().then((id) => setState(() => _childId = id));
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(children: [
          Icon(Icons.logout_rounded, color: Color(0xFF6C63D5), size: 36),
          SizedBox(height: 8),
          Text('Déconnexion', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700)),
          Text('تسجيل الخروج', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey)),
        ]),
        content: const Text(
          'Vous serez redirigé vers l\'écran de couplage.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63D5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await PrefsService.clearParentData();
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PairingScreen()));
  }

  @override
  Widget build(BuildContext context) {
    if (_childId == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4FF),
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF6C63D5), Color(0xFF9C94E8)]),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.shield, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('MotherEye', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    Text('عين الأم — Tableau de bord', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                  const Spacer(),
                  IconButton(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    tooltip: 'Déconnexion',
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tab,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.warning_amber_rounded, size: 20), text: 'Alertes'),
                  Tab(icon: Icon(Icons.psychology_rounded, size: 20), text: 'Rapports IA'),
                ],
              ),
            ]),
          ),

          Expanded(child: TabBarView(
            controller: _tab,
            children: [
              _AlertsTab(childId: _childId!),
              _ReportsTab(childId: _childId!),
            ],
          )),
        ]),
      ),
    );
  }
}

class _AlertsTab extends StatelessWidget {
  final String childId;
  const _AlertsTab({required this.childId});

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot>(
    stream: FirestoreService.alertStream(childId),
    builder: (ctx, snap) {
      final docs = snap.data?.docs ?? [];
      final unread = docs.where((d) => d['read'] == false).length;
      final safe = unread == 0;
      return Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: safe ? const Color(0xFFE8FFF0) : const Color(0xFFFFF0F0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: safe ? const Color(0xFF2ED573) : const Color(0xFFFF4757), width: 1.5),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: safe ? const Color(0xFF2ED573).withValues(alpha: 0.15) : const Color(0xFFFF4757).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(safe ? Icons.verified_user_rounded : Icons.warning_amber_rounded,
                    color: safe ? const Color(0xFF2ED573) : const Color(0xFFFF4757), size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(safe ? 'Enfant en sécurité' : '$unread alerte(s) non lue(s)',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                        color: safe ? const Color(0xFF1DB954) : const Color(0xFFFF4757))),
                Text(safe ? 'طفلك بأمان — aucune menace détectée' : 'يرجى المراجعة الآن',
                    style: TextStyle(fontSize: 12, color: safe ? Colors.green[400] : Colors.red[300])),
              ])),
            ]),
          ),
        ),
        Expanded(
          child: docs.isEmpty
              ? _emptyState(Icons.notifications_none_rounded, 'Aucune alerte', 'لا توجد تنبيهات')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) => AlertCard(
                      doc: docs[i], childId: childId,
                      onTap: () => FirestoreService.markAlertRead(childId, docs[i].id)),
                ),
        ),
      ]);
    },
  );
}

class _ReportsTab extends StatelessWidget {
  final String childId;
  const _ReportsTab({required this.childId});

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot>(
    stream: FirestoreService.reportStream(childId),
    builder: (ctx, snap) {
      final docs = snap.data?.docs ?? [];
      return Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EEFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF6C63D5)),
              SizedBox(width: 8),
              Expanded(child: Text(
                'Ces analyses sont indicatives uniquement — لأغراض توجيهية فقط',
                style: TextStyle(fontSize: 11, color: Color(0xFF6C63D5)),
              )),
            ]),
          ),
        ),
        Expanded(
          child: docs.isEmpty
              ? _emptyState(Icons.psychology_rounded, 'Aucun rapport IA', 'استخدم زر التحليل على هاتف الطفل')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) => ReportCard(doc: docs[i]),
                ),
        ),
      ]);
    },
  );
}

Widget _emptyState(IconData icon, String title, String sub) => Center(
  child: Padding(
    padding: const EdgeInsets.all(40),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 64, color: Colors.grey[300]),
      const SizedBox(height: 16),
      Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[500])),
      const SizedBox(height: 6),
      Text(sub, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey[400])),
    ]),
  ),
);
