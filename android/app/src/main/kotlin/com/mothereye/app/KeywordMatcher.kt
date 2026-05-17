package com.mothereye.app

class KeywordMatcher {

    private val dangerPhrases = listOf(
        // Arabic — explicit / grooming
        "أرسل صورتك", "ارسل صورتك", "أرسلي صورتك",
        "صورة عارية", "صور سكس", "فيديو جنسي",
        "أين تسكن", "اين تسكنين", "وين تسكن",
        "لا تخبر أحد", "لا تقول لأهلك", "سر بيننا",
        "أعطني رقمك", "تعال معي", "تعالي معي", "نلتقي وحدنا",
        // Distress signals — Arabic
        "أريد أن أختفي", "لا أريد أن أكون هنا", "لا أحد يحبني",
        "أكره نفسي", "أريد أن أموت", "كيف أهرب من البيت",
        // French — grooming
        "envoie ta photo", "envoie-moi une photo",
        "viens en privé", "viens me voir",
        "dis-le à personne", "garde ça secret",
        "tu habites où", "c'est notre secret",
        // French — distress
        "je veux disparaître", "personne m'aime", "je suis nul à rien",
        "j'en peux plus", "je veux mourir", "comment fuguer",
        // Franco-arabe / dialectal
        "36ini snap", "36ini numero", "36ini photo",
        "wach nchufek", "nchufek f private",
        "bghit sortak ", "mach t9ol lwaldin",
        // Universal
        "send nudes", "nude", "snap me", "dm me pic",
        // Arabic — manipulation / coercion
        "إذا تحبني أرسل صورة",
        "إذا تثق فيني وريني",
        "ليش خايف", "ليش خايفة",
        "ما راح يعرف أحد",
        "أقسم ما أقول لأحد",
        "بس بيني وبينك",
        "خلينا نتكلم بالليل",
        "رد بسرعة",
        "لا تتجاهلني",
        "ليش ما ترد",
        "أرسل فويس",
        "افتح المايك",
        "خليني أشوفك",
        "تعال خاص الحين",
        "أبغى أشوف جسمك",
        "صور رجلك",
        "صور وجهك",
        "صور غرفتك",
        "وش لابس",
        "وش لابسة",
        "كم عمرك",
        "عمرك الحقيقي كم",
        "هل أنت وحدك",
        "أهلك موجودين",
        "أرسل لوكيشن",
        "وين مدرستك",
        "أقرب مكان لك",
        "تعرف تسوق",
        "نطلع سوا",

        // Arabic — bullying / emotional abuse
        "أنت غبي",
        "أنت فاشل",
        "ما منك فايدة",
        "الكل يكرهك",
        "محد يحبك",
        "أنت قبيح",
        "أنت ضعيف",
        "ليش عايش",
        "روح موت",
        "اقتل نفسك",
        "اختفي أحسن",
        "أنت مشكلة للجميع",

        // French — manipulation / coercion
        "si tu m'aimes envoie une photo",
        "fais-moi confiance",
        "personne ne saura",
        "réponds vite",
        "pourquoi tu réponds pas",
        "active ton micro",
        "je veux te voir",
        "montre-moi ton visage",
        "montre-moi ta chambre",
        "tu es seul chez toi",
        "tes parents sont là",
        "envoie ta localisation",
        "on sort ensemble",

        // French — bullying / distress
        "tu es nul",
        "personne ne t'aime",
        "va mourir",
        "t'es un problème",
        "je me déteste",
        "je veux en finir",
        "je suis inutile",

        // Franco / dialect
        "3lach matradch",
        "jawb daba",
        "warini rask",
        "warini bitk",
        "wach nta بوحدك",
        "fin qraytek",
        "3tini localisation",
        "nta mskin",
        "7yed had lmessage",
        "delete had chat",

        // English — grooming / coercion
        "trust me",
        "prove you trust me",
        "show me more",
        "show your face",
        "show your room",
        "what are you wearing",
        "are you alone",
        "your parents home?",
        "send your location",
        "let's meet tonight",
        "meet in private",
        "keep it between us",
        "don't screenshot",
        "delete our messages",
        "reply now",
        "why are you ignoring me",
        "turn your camera on",
        "send voice message",

        // English — bullying / self-harm indicators
        "nobody cares about you",
        "you are worthless",
        "go kill yourself",
        "everyone hates you",
        "you are useless",
        "i want to end it",
        "i feel empty",
        "i hate my life",
        "i cut myself",
        "i don't want to live anymore",
        "i feel trapped",
        "i want to disappear forever"

    )

    fun findDangerPhrase(text: String): String? {
        val n = normalize(text)
        return dangerPhrases.firstOrNull { n.contains(normalize(it)) }
    }

    private fun normalize(text: String) = text
        .lowercase()
        .replace("أ", "ا").replace("إ", "ا").replace("آ", "ا")
        .replace("ة", "ه").replace("ى", "ي")
        .replace("3", "ع").replace("7", "ح").replace("9", "ق")
        .trim()
}
