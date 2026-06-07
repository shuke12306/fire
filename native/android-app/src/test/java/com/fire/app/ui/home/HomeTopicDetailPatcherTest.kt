package com.fire.app.ui.home

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import uniffi.fire_uniffi_types.TopicRowState
import uniffi.fire_uniffi_types.TopicSummaryState

class HomeTopicDetailPatcherTest {
    @Test
    fun patch_updatesLoadedTopicCountsFromDetailHeader() {
        val row = topicRow(topicId = 42uL, postsCount = 2u, replyCount = 1u, views = 10u)
        val patched = HomeTopicDetailPatcher.patch(
            row,
            HomeTopicDetailPatch(
                topicId = 42uL,
                postsCount = 9u,
                replyCount = 8u,
                views = 321u,
                lastReadPostNumber = 8u,
                highestPostNumber = 9u,
            ),
        )

        requireNotNull(patched)
        assertEquals(9u, patched.topic.postsCount)
        assertEquals(8u, patched.topic.replyCount)
        assertEquals(321u, patched.topic.views)
        assertEquals(8u, patched.topic.lastReadPostNumber)
        assertEquals(9u, patched.topic.highestPostNumber)
    }

    @Test
    fun patch_ignoresOtherTopicsAndNoopsWhenContentMatches() {
        val row = topicRow(topicId = 42uL, postsCount = 9u, replyCount = 8u, views = 321u)

        assertNull(
            HomeTopicDetailPatcher.patch(
                row,
                HomeTopicDetailPatch(
                    topicId = 7uL,
                    postsCount = 9u,
                    replyCount = 8u,
                    views = 321u,
                    lastReadPostNumber = 8u,
                    highestPostNumber = 9u,
                ),
            ),
        )
        assertNull(
            HomeTopicDetailPatcher.patch(
                row,
                HomeTopicDetailPatch(
                    topicId = 42uL,
                    postsCount = 9u,
                    replyCount = 8u,
                    views = 321u,
                    lastReadPostNumber = 8u,
                    highestPostNumber = 9u,
                ),
            ),
        )
    }

    private fun topicRow(
        topicId: ULong,
        postsCount: UInt,
        replyCount: UInt,
        views: UInt,
    ): TopicRowState {
        return TopicRowState(
            topic = TopicSummaryState(
                id = topicId,
                title = "Topic",
                slug = "topic",
                postsCount = postsCount,
                replyCount = replyCount,
                views = views,
                likeCount = 1u,
                excerpt = null,
                createdAt = null,
                lastPostedAt = null,
                lastPosterUsername = null,
                categoryId = null,
                pinned = false,
                visible = true,
                closed = false,
                archived = false,
                tags = emptyList(),
                posters = emptyList(),
                participants = emptyList(),
                unseen = false,
                unreadPosts = 0u,
                newPosts = 0u,
                lastReadPostNumber = 8u,
                highestPostNumber = 9u,
                bookmarkedPostNumber = null,
                bookmarkId = null,
                bookmarkName = null,
                bookmarkReminderAt = null,
                bookmarkableType = null,
                hasAcceptedAnswer = false,
                canHaveAnswer = false,
            ),
            excerptText = null,
            originalPosterUsername = "alice",
            originalPosterAvatarTemplate = null,
            tagNames = emptyList(),
            statusLabels = emptyList(),
            isPinned = false,
            isClosed = false,
            isArchived = false,
            hasAcceptedAnswer = false,
            hasUnreadPosts = false,
            createdTimestampUnixMs = null,
            activityTimestampUnixMs = null,
            lastPosterUsername = null,
        )
    }
}
