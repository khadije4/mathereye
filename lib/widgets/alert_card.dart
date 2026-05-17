import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AlertCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final String childId;
  final VoidCallback onTap;
  const AlertCard({super.key, required this.doc, required this.childId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final type    = doc['type'] as String;
    final isNsfw  = type == 'nsfw_image';
    final isSpec  = type == 'specialist_urgent';
    final read    = doc['read'] as bool? ?? false;
    final ts      = doc['timestamp'] as Timestamp?;
    final time    = ts != null ? DateFormat('dd/MM • HH:mm').format(ts.toDate()) : '';
    final matched = doc['matchedText'] as String? ?? '';

    final (color, icon, label) = isSpec
        ? (const Color(0xFF9B59B6), Icons.medical_information_rounded, 'Consultation recommandée')
        : isNsfw
            ? (const Color(0xFFFF4757), Icons.image_not_supported_rounded, 'Image suspecte')
            : (const Color(0xFFFF6B35), Icons.chat_bubble_outline_rounded, 'Phrase dangereuse');

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border(left: BorderSide(color: read ? Colors.grey[200]! : color, width: 4)),
          boxShadow: read ? [] : [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (read ? Colors.grey : color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: read ? Colors.grey[400] : color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(label,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                        color: read ? Colors.grey[500] : Colors.grey[800]))),
                if (!read)
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
              ]),
              if (matched.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text('"$matched"',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic)),
              ],
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.access_time_rounded, size: 11, color: Colors.grey[400]),
                const SizedBox(width: 3),
                Text(time, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                if (read) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.done_all_rounded, size: 11, color: Colors.grey[400]),
                ],
              ]),
            ])),
          ]),
        ),
      ),
    );
  }
}
