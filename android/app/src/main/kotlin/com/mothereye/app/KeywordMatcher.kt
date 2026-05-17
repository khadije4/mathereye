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
        "3tini snap", "3tini numero", "3tini foto",
        "wach nchufek", "nchufek f private",
        "bghit tswira dyalek", "mach t9ol lwaldin",
        // Universal
        "send nudes", "nude", "snap me", "dm me pic"
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
