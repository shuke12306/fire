package com.fire.app.session

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

object FireSessionStoreRepository {
    @Volatile
    private var shared: FireSessionStore? = null
    @Volatile
    private var challengeHandler: FireCloudflareChallengeRuntimeHandler? = null

    suspend fun get(context: Context): FireSessionStore = withContext(Dispatchers.IO) {
        getOrCreateBlocking(context.applicationContext)
    }

    fun getIfInitialized(): FireSessionStore? = shared

    private fun getOrCreateBlocking(context: Context): FireSessionStore {
        return shared ?: synchronized(this) {
            shared ?: FireSessionStore(context.applicationContext).also { store ->
                if (challengeHandler == null) {
                    challengeHandler = FireCloudflareChallengeRuntimeHandler(
                        context.applicationContext,
                    )
                }
                challengeHandler?.let(store::registerCloudflareChallengeHandler)
                shared = store
            }
        }
    }
}
