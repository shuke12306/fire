package com.fire.app.ui.composer

import org.junit.Assert.assertEquals
import org.junit.Test

class MarkdownInsertionTest {
    @Test
    fun apply_wrapsSelectedText() {
        val result = MarkdownInsertion.apply(
            action = MarkdownFormatAction.BOLD,
            text = "hello world",
            selectionStart = 6,
            selectionEnd = 11,
        )

        assertEquals("hello **world**", result.text)
        assertEquals(8, result.selectionStart)
        assertEquals(13, result.selectionEnd)
    }

    @Test
    fun apply_createsOrderedListAcrossSelectedLines() {
        val result = MarkdownInsertion.apply(
            action = MarkdownFormatAction.ORDERED_LIST,
            text = "one\ntwo",
            selectionStart = 0,
            selectionEnd = 7,
        )

        assertEquals("1. one\n2. two", result.text)
        assertEquals(0, result.selectionStart)
        assertEquals(13, result.selectionEnd)
    }

    @Test
    fun apply_keepsCursorInsideLinkPlaceholder() {
        val result = MarkdownInsertion.apply(
            action = MarkdownFormatAction.LINK,
            text = "",
            selectionStart = 0,
            selectionEnd = 0,
        )

        assertEquals("[text](url)", result.text)
        assertEquals(1, result.selectionStart)
        assertEquals(5, result.selectionEnd)
    }
}
