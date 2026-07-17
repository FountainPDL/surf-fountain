package com.surffountain.browser.pdlai

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.surffountain.browser.data.preferences.SettingsDataStore
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

/**
 * A real, working chat UI wired to a stub model layer — see sendMessage.
 * "just there for now" per the brief: the UI/state machine is genuine,
 * the model connection is the explicitly-not-done part. Swapping the stub
 * reply for a real API call is the only thing that changes when that
 * lands; nothing about the UI or state layer needs to move.
 */
@HiltViewModel
class PdlAiViewModel @Inject constructor(
    private val settingsDataStore: SettingsDataStore
) : ViewModel() {

    private val _messages = MutableStateFlow<List<PdlAiMessage>>(emptyList())
    val messages: StateFlow<List<PdlAiMessage>> = _messages.asStateFlow()

    private val _isSending = MutableStateFlow(false)
    val isSending: StateFlow<Boolean> = _isSending.asStateFlow()

    val apiKey: StateFlow<String> = settingsDataStore.pdlAiApiKey.stateIn(
        viewModelScope, SharingStarted.WhileSubscribed(5_000), ""
    )

    fun setApiKey(key: String) {
        viewModelScope.launch { settingsDataStore.setPdlAiApiKey(key) }
    }

    fun sendMessage(text: String) {
        val trimmed = text.trim()
        if (trimmed.isEmpty() || _isSending.value) return

        _messages.update { it + PdlAiMessage(UUID.randomUUID().toString(), PdlAiRole.USER, trimmed) }
        _isSending.value = true

        viewModelScope.launch {
            val reply = if (apiKey.value.isBlank()) {
                NO_KEY_REPLY
            } else {
                NOT_WIRED_UP_REPLY
            }
            _messages.update { it + PdlAiMessage(UUID.randomUUID().toString(), PdlAiRole.ASSISTANT, reply) }
            _isSending.value = false
        }
    }

    companion object {
        private const val NO_KEY_REPLY =
            "I don't have an API key configured yet — add one in Settings \u2192 PDL AI to enable real " +
                "responses. This chat itself is fully working; the model connection is the part " +
                "that isn't wired up yet."
        private const val NOT_WIRED_UP_REPLY =
            "Thanks for the key! The actual model connection isn't wired up yet, though — this reply " +
                "is a placeholder so the chat UI has something real to show. See docs/ROADMAP.md for " +
                "where this is headed."
    }
}
