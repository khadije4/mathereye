import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReportCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  const ReportCard({super.key, required this.doc});
  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final a            = (widget.doc['analysis'] as Map<String, dynamic>?) ?? {};
    final risk         = a['riskLevel'] as String? ?? 'safe';
    final summaryFr    = a['summary_fr'] as String? ?? '';
    final summaryAr    = a['summary_ar'] as String? ?? '';
    final whyFr        = a['whyTheyDoIt_fr'] as String? ?? '';
    final explainFr    = a['parentExplanation_fr'] as String? ?? '';
    final recFr        = a['recommendation_fr'] as String? ?? '';
    final patternAlert = a['patternAlert'] as String?;
    final spec         = a['specialistRecommendation'] as Map<String, dynamic>?;
    final ts           = widget.doc['timestamp'] as Timestamp?;
    final time         = ts != null ? DateFormat('dd/MM • HH:mm').format(ts.toDate()) : '';

    final (riskColor, riskIcon, riskLabel) = switch (risk) {
      'urgent'  => (const Color(0xFFFF4757), Icons.emergency_rounded,       'URGENT'),
      'alert'   => (const Color(0xFFFF6B35), Icons.warning_rounded,          'Alerte'),
      'monitor' => (const Color(0xFFFFA502), Icons.visibility_rounded,       'À surveiller'),
      _         => (const Color(0xFF2ED573), Icons.verified_user_rounded,    'Sûr'),
    };

    final specialistNeeded = spec != null && spec['needed'] == true;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          // Card header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(riskIcon, color: riskColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: riskColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                    child: Text(riskLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: riskColor)),
                  ),
                  if (patternAlert != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFF9B59B6).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                      child: Text(patternAlert, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF9B59B6))),
                    ),
                  ],
                ]),
                const SizedBox(height: 5),
                Text(summaryFr, maxLines: _expanded ? 10 : 2,
                    overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.4)),
              ])),
              const SizedBox(width: 8),
              Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey[400]),
            ]),
          ),

          // Expanded content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (summaryAr.isNotEmpty) ...[
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text(summaryAr, textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF444444), height: 1.5)),
                  const SizedBox(height: 12),
                ],
                if (whyFr.isNotEmpty) _Section(icon: Icons.psychology_outlined, color: const Color(0xFF6C63D5), label: 'Pourquoi?', text: whyFr),
                if (explainFr.isNotEmpty) _Section(icon: Icons.info_outline_rounded, color: const Color(0xFF3498DB), label: 'Pour le parent', text: explainFr),
                if (recFr.isNotEmpty) _Section(icon: Icons.tips_and_updates_outlined, color: const Color(0xFF2ED573), label: 'Conseil', text: recFr),

                if (specialistNeeded) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9B59B6).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF9B59B6).withValues(alpha: 0.3)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.medical_services_rounded, color: Color(0xFF9B59B6), size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          '${_specialistLabel(spec['type'] as String?)} — ${_urgencyLabel(spec['urgency'] as String?)}',
                          style: const TextStyle(color: Color(0xFF9B59B6), fontWeight: FontWeight.w700, fontSize: 13),
                        )),
                      ]),
                      if ((spec['reason_fr'] as String?)?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 6),
                        Text(spec['reason_fr'] as String,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF9B59B6), height: 1.4)),
                      ],
                      if ((spec['howToApproach_fr'] as String?)?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 6),
                        Text('💬 ${spec['howToApproach_fr']}',
                            style: TextStyle(fontSize: 12, color: Colors.purple[300], fontStyle: FontStyle.italic, height: 1.4)),
                      ],
                    ]),
                  ),
                ],

                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.access_time_rounded, size: 12, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(time, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ]),
              ]),
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ]),
      ),
    );
  }

  String _specialistLabel(String? type) => switch (type) {
    'psychologist'     => 'Psychologue',
    'school_counselor' => 'Conseiller scolaire',
    'doctor'           => 'Médecin',
    'social_worker'    => 'Travailleur social',
    'imam_counselor'   => 'Conseiller religieux',
    _                  => 'Spécialiste',
  };

  String _urgencyLabel(String? urgency) => switch (urgency) {
    'immediately'  => '🔴 IMMÉDIATEMENT',
    'within_week'  => '🟠 Cette semaine',
    'within_month' => '🟡 Ce mois',
    _              => '',
  };
}

class _Section extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, text;
  const _Section({required this.icon, required this.color, required this.label, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 14, color: color),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF444444), height: 1.45)),
      ])),
    ]),
  );
}
