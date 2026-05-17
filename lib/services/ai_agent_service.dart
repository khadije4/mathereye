import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'firestore_service.dart';

class AiAgentService {

  // Returns null on success, error message on failure
  static Future<String?> analyzeActivity({
    required String childId,
    required String rawText,
    required String childAgeHint,
    required List<Map<String, dynamic>> recentReports,
  }) async {
    const apiKey = String.fromEnvironment('GROQ_API_KEY');
    if (apiKey.isEmpty) {
      return 'Clé API manquante — relancez avec --dart-define=GROQ_API_KEY=...';
    }

    final text = rawText.trim().isEmpty
        ? _demoText   // fallback so demo always works
        : rawText;

    final json = await _callGroq(_buildPrompt(text, childAgeHint, recentReports));
    if (json == null) return 'Échec appel API — vérifiez la connexion et la clé Groq';

    await FirestoreService.writeActivityReport(childId, json);
    return null; // success
  }

  // Demo text used when buffer is empty (no OCR capture yet)
  static const _demoText =
      "L'enfant a utilisé une application de messagerie. "
      "Il a regardé des vidéos. "
      "Des recherches sur des jeux en ligne ont été détectées.";


  static String _buildPrompt(String rawText, String ageHint,
      List<Map<String, dynamic>> history) {
    final historySection = history.isEmpty
        ? 'Aucun historique.'
        : history.map((r) {
            final a = r['analysis'] as Map<String, dynamic>? ?? {};
            return '- ${a['summary_fr'] ?? ''} (risque: ${a['riskLevel'] ?? 'safe'})';
          }).join('\n');

    return '''
Tu es un assistant spécialisé en protection de l\'enfance et en psychologie de l\'enfant.
Tu analyses le comportement numérique d\'un enfant ($ageHint) pour aider ses parents en Mauritanie ou dans le monde arabe.

## Texte capturé sur l\'écran de l\'enfant (cette session) :
"""
$rawText
"""

## Historique des dernières sessions :
$historySection

Analyse ce contenu et réponds UNIQUEMENT en JSON valide avec cette structure exacte :

{
  "riskLevel": "safe" | "monitor" | "alert" | "urgent",
  "activityType": "homework" | "entertainment" | "social" | "curiosity" | "risky" | "unknown",
  "summary_fr": "Ce que fait l\'enfant en 1-2 phrases simples pour un parent non-technique",
  "summary_ar": "ما يفعله الطفل في جملة أو جملتين بلغة بسيطة",
  "whyTheyDoIt_fr": "Pourquoi un enfant de cet âge ferait probablement cela — pression des pairs, curiosité normale, besoin émotionnel, influence réseaux sociaux (bienveillant, sans jugement)",
  "whyTheyDoIt_ar": "لماذا يفعل طفل بهذا العمر ذلك على الأرجح — بلطف وبدون حكم",
  "parentExplanation_fr": "Ce que le parent doit savoir: est-ce normal? qu\'est-ce qui est préoccupant? que faire maintenant? (3-4 phrases concrètes)",
  "parentExplanation_ar": "ما يجب أن يعرفه الوالد: هل هذا طبيعي؟ ما المثير للقلق؟ ماذا يفعل الآن؟",
  "specialistRecommendation": {
    "needed": true | false,
    "urgency": "none" | "within_month" | "within_week" | "immediately",
    "type": null | "psychologist" | "school_counselor" | "doctor" | "social_worker" | "imam_counselor",
    "reason_fr": "Pourquoi ce spécialiste? Quels signaux ont déclenché cela? (si needed=true)",
    "reason_ar": "لماذا هذا المختص؟ ما الإشارات التي أدت لهذه التوصية؟",
    "howToApproach_fr": "Script doux pour que le parent aborde le sujet avec l\'enfant (1-2 phrases)",
    "howToApproach_ar": "كيف يقترب الوالد من الموضوع مع طفله بلطف"
  },
  "patternAlert": null | "isolation" | "self_harm_risk" | "grooming_victim" | "radicalization" | "cyberbullying_victim" | "addiction",
  "recommendation_fr": "Conseil pratique immédiat pour le parent (1 phrase actionnable)",
  "recommendation_ar": "نصيحة عملية فورية للوالدين",
  "topics": ["sujets", "détectés"]
}

RÈGLES specialistRecommendation:
- needed=false: devoirs, jeux, curiosité normale, divertissement approprié
- within_month + school_counselor: isolement léger, baisse de motivation, conflits sociaux
- within_week + psychologist: anxiété répétée, tristesse profonde, harcèlement subi
- immediately + psychologist: automutilation, pensées suicidaires, abus détecté, dépression sévère
- imam_counselor: questionnements religieux profonds, conflit de valeurs (combiner avec psychologist si grave)
- doctor: troubles alimentaires, automutilation physique

RÈGLES patternAlert (basé sur l\'historique + session actuelle):
- isolation: contenu mélancolique, refus de sortir, seul répété sur plusieurs sessions
- self_harm_risk: termes liés à douleur, mort, automutilation, vouloir disparaître
- grooming_victim: partage d\'infos personnelles avec inconnus, demandes suspectes d\'adultes
- radicalization: contenu extrémiste, haine, violence idéologique
- cyberbullying_victim: insultes reçues répétées, moqueries en ligne
- addiction: usage compulsif détecté sur plusieurs heures consécutives

CONTEXTE CULTUREL:
- Familles mauritaniennes et arabes — respecte les valeurs islamiques
- Présente la consultation psychologique positivement: "pour aider votre enfant à s\'épanouir"
- Propose imam_counselor quand pertinent culturellement
- Langage bienveillant, jamais alarmiste sans raison

Réponds UNIQUEMENT avec le JSON, sans texte avant ou après.
''';
  }

  static Future<String?> _callGroq(String prompt) async {
    const apiKey = String.fromEnvironment('GROQ_API_KEY');
    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'max_tokens': 1500,
          'temperature': 0.3,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );
      if (response.statusCode == 200) {
        final text =
            (jsonDecode(response.body)['choices'][0]['message']['content'] as String)
                .replaceAll('```json', '')
                .replaceAll('```', '')
                .trim();
        return text;
      } else {
        // Print status + body so you can see what's wrong in flutter logs
        debugPrint('[Groq] Error ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 300))}');
      }
    } catch (e) {
      debugPrint('[Groq] Exception: $e');
    }
    return null;
  }
}
