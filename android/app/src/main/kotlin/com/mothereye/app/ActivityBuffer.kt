package com.mothereye.app

import java.util.concurrent.CopyOnWriteArrayList

object ActivityBuffer {
    private val fragments    = CopyOnWriteArrayList<String>()
    private var sessionStart = System.currentTimeMillis()
    private val AUTO_FLUSH_MS = 10 * 60 * 1000L

    fun add(text: String) {
        if (text.isBlank()) return
        fragments.add(text.take(300))
        if (System.currentTimeMillis() - sessionStart > AUTO_FLUSH_MS) flush()
    }

    fun flush(): String {
        val combined = fragments.joinToString("\n---\n").take(4000)
        fragments.clear()
        sessionStart = System.currentTimeMillis()
        return combined
    }

    fun isEmpty() = fragments.isEmpty()
}
