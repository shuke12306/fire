package com.fire.app.ui.home

import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import uniffi.fire_uniffi_topics.TopicDetailState
import uniffi.fire_uniffi_types.TopicRowState

data class HomeTopicDetailPatch(
    val topicId: ULong,
    val postsCount: UInt,
    val replyCount: UInt,
    val views: UInt,
    val lastReadPostNumber: UInt?,
    val highestPostNumber: UInt,
) {
    companion object {
        fun from(detail: TopicDetailState): HomeTopicDetailPatch {
            return HomeTopicDetailPatch(
                topicId = detail.id,
                postsCount = detail.postsCount,
                replyCount = detail.replyCount,
                views = detail.views,
                lastReadPostNumber = detail.lastReadPostNumber,
                highestPostNumber = detail.highestPostNumber,
            )
        }
    }
}

object HomeTopicDetailPatchRepository {
    private val _patches = MutableSharedFlow<HomeTopicDetailPatch>(
        extraBufferCapacity = 32,
        onBufferOverflow = BufferOverflow.DROP_OLDEST,
    )
    val patches = _patches.asSharedFlow()

    fun publish(detail: TopicDetailState) {
        _patches.tryEmit(HomeTopicDetailPatch.from(detail))
    }
}

object HomeTopicDetailPatcher {
    fun patch(row: TopicRowState, patch: HomeTopicDetailPatch): TopicRowState? {
        if (row.topic.id != patch.topicId) {
            return null
        }
        val topic = row.topic
        if (topic.postsCount == patch.postsCount &&
            topic.replyCount == patch.replyCount &&
            topic.views == patch.views &&
            topic.lastReadPostNumber == patch.lastReadPostNumber &&
            topic.highestPostNumber == patch.highestPostNumber
        ) {
            return null
        }

        return row.copy(
            topic = topic.copy(
                postsCount = patch.postsCount,
                replyCount = patch.replyCount,
                views = patch.views,
                lastReadPostNumber = patch.lastReadPostNumber,
                highestPostNumber = patch.highestPostNumber,
            ),
        )
    }
}
