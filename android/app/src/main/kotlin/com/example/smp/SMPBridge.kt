// ──────────────────────────────────────────────────────────────────────────────
// SMPBridge.kt
// Kotlin JNI wrapper around the Swift SMP C-bridge (libSMPAndroid.so).
// ──────────────────────────────────────────────────────────────────────────────

package com.example.smp

import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

object SMPBridge {

    init {
        System.loadLibrary("SMPAndroid")   // loads libSMPAndroid.so
    }

    // ── Lifecycle ────────────────────────────────────────────────────────────

    /** Must be called once before any other SMPBridge method. */
    external fun configure(baseURL: String)

    // ── Auth (raw JNI) ───────────────────────────────────────────────────────

    /**
     * Async login – calls back on the thread that processes the Swift event loop.
     * Prefer the coroutine wrapper [login] for normal Kotlin usage.
     */
    private external fun nativeLogin(
        username: String,
        password: String,
        callback: LoginCallback
    )

    external fun logout()
    external fun isAuthenticated(): Boolean
    external fun currentDisplayName(): String?

    // ── Coroutine helpers ────────────────────────────────────────────────────

    /** Suspending login – safe to call from any coroutine. */
    suspend fun login(username: String, password: String): Unit =
        suspendCancellableCoroutine { cont ->
            nativeLogin(username, password, object : LoginCallback {
                override fun onResult(error: String?) {
                    if (error == null) cont.resume(Unit)
                    else cont.resumeWithException(SMPException(error))
                }
            })
        }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting types
// ─────────────────────────────────────────────────────────────────────────────

/** Callback interface invoked by the Swift C-bridge on login completion. */
interface LoginCallback {
    /** @param error  Non-null string means failure; null means success. */
    fun onResult(error: String?)
}

class SMPException(message: String) : Exception(message)
