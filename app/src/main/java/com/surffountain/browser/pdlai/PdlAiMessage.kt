package com.surffountain.browser.pdlai

enum class PdlAiRole { USER, ASSISTANT }

data class PdlAiMessage(
    val id: String,
    val role: PdlAiRole,
    val text: String
)
