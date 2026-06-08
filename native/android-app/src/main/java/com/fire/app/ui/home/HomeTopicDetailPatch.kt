package com.fire.app.ui.home

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
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
    private val _patches = MutableStateFlow<Map<ULong, HomeTopicDetailPatch>>(emptyMap())
    val patches = _patches.asStateFlow()

    fun publish(detail: TopicDetailState) {
        publishPatch(HomeTopicDetailPatch.from(detail))
    }

    fun publishPatch(patch: HomeTopicDetailPatch) {
        _patches.value = _patches.value + (patch.topicId to patch)
    }
}

object HomeTopicDetailPatcher {
    fun patch(row: TopicRowState, patch: HomeTopicDetailPatch): TopicRowState? {
        if (row.topic.id != patch.topicId) {
            return null
        }
        val topic = row.topic
        val nextHasUnreadPosts = patch.lastReadPostNumber
            ?.let { it < patch.highestPostNumber }
            ?: row.hasUnreadPosts
        val nextUnreadPosts = if (nextHasUnreadPosts) topic.unreadPosts else 0u
        val nextNewPosts = if (nextHasUnreadPosts) topic.newPosts else 0u
        if (topic.postsCount == patch.postsCount &&
            topic.replyCount == patch.replyCount &&
            topic.views == patch.views &&
            topic.lastReadPostNumber == patch.lastReadPostNumber &&
            topic.highestPostNumber == patch.highestPostNumber &&
            topic.unreadPosts == nextUnreadPosts &&
            topic.newPosts == nextNewPosts &&
            row.hasUnreadPosts == nextHasUnreadPosts
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
                unreadPosts = nextUnreadPosts,
                newPosts = nextNewPosts,
            ),
            hasUnreadPosts = nextHasUnreadPosts,
        )
    }
}
