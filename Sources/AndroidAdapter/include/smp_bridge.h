/**
 * smp_bridge.h – Public C API exported by the SMPAndroid Swift target.
 *
 * These symbols are called from Kotlin via JNI or via the Swift SDK for
 * Android (SwiftJava / JavaKit) interop layer.
 *
 * Naming convention:  SMP_<Domain>_<Action>
 */

#pragma once
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// ─────────────────────────────────────────────────────────────────────────────
// Lifecycle
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Initialise the SMP runtime.  Must be the first call.
 *
 * @param baseURL  Null-terminated UTF-8 base URL string (e.g. "https://api.example.com/")
 */
void SMP_configure(const char * _Nonnull baseURL);

// ─────────────────────────────────────────────────────────────────────────────
// Auth
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Asynchronous login.  Kotlin/JVM calls this on a background thread; the
 * result is delivered via the supplied callback on the same thread.
 *
 * @param username   Null-terminated UTF-8 string
 * @param password   Null-terminated UTF-8 string
 * @param context    Opaque pointer forwarded unchanged to the callback
 * @param callback   Called with (context, error_message_or_NULL)
 *                   A NULL error_message indicates success.
 */
void SMP_auth_login(
    const char * _Nonnull username,
    const char * _Nonnull password,
    void * _Nullable context,
    void (* _Nonnull callback)(void * _Nullable context, const char * _Nullable errorMessage)
);

/** Synchronously clears the session. */
void SMP_auth_logout(void);

// ─────────────────────────────────────────────────────────────────────────────
// Auth state query (synchronous, main-actor safe snapshot)
// ─────────────────────────────────────────────────────────────────────────────

/** Returns 1 if the user is currently authenticated, 0 otherwise. */
int32_t SMP_auth_isAuthenticated(void);

/**
 * Copies the current user's display name into @p buf (up to @p bufLen bytes).
 * @return  Number of bytes written (excluding NUL), or -1 if not authenticated.
 */
int32_t SMP_auth_currentDisplayName(char * _Nonnull buf, int32_t bufLen);

#ifdef __cplusplus
}
#endif
