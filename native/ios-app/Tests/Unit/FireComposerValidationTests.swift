import XCTest
@testable import Fire

final class FireComposerValidationTests: XCTestCase {
    func testCreateTopicAllowsSubmitWithoutPrefetchedCsrfWhenContentIsComplete() {
        let state = FireComposerValidation.submitState(
            route: FireComposerRoute(kind: .createTopic),
            canStartAuthenticatedMutation: true,
            isSubmitting: false,
            trimmedTitle: String(repeating: "题", count: 15),
            trimmedBody: String(repeating: "文", count: 20),
            minimumTitleLength: 15,
            minimumBodyLength: 20,
            selectedCategoryID: 42,
            selectedTagCount: 0,
            minimumRequiredTags: 0,
            recipientCount: 0
        )

        XCTAssertTrue(state.canSubmit)
        XCTAssertNil(state.message)
    }

    func testCreateTopicSurfacesMissingTagRequirement() {
        let state = FireComposerValidation.submitState(
            route: FireComposerRoute(kind: .createTopic),
            canStartAuthenticatedMutation: true,
            isSubmitting: false,
            trimmedTitle: String(repeating: "题", count: 15),
            trimmedBody: String(repeating: "文", count: 20),
            minimumTitleLength: 15,
            minimumBodyLength: 20,
            selectedCategoryID: 42,
            selectedTagCount: 0,
            minimumRequiredTags: 2,
            recipientCount: 0
        )

        XCTAssertFalse(state.canSubmit)
        XCTAssertEqual(state.message, "当前分类至少需要 2 个标签")
    }

    func testPrivateMessageRequiresRecipient() {
        let state = FireComposerValidation.submitState(
            route: FireComposerRoute(kind: .privateMessage(recipients: [], title: nil)),
            canStartAuthenticatedMutation: true,
            isSubmitting: false,
            trimmedTitle: "私信标题",
            trimmedBody: String(repeating: "文", count: 10),
            minimumTitleLength: 2,
            minimumBodyLength: 10,
            selectedCategoryID: nil,
            selectedTagCount: 0,
            minimumRequiredTags: 0,
            recipientCount: 0
        )

        XCTAssertFalse(state.canSubmit)
        XCTAssertEqual(state.message, "请至少添加一个收件人")
    }

    func testAdvancedReplyRequiresMinimumLength() {
        let state = FireComposerValidation.submitState(
            route: FireComposerRoute(
                kind: .advancedReply(
                    topicID: 42,
                    topicTitle: "主题",
                    categoryID: nil,
                    replyToPostNumber: nil,
                    replyToUsername: nil,
                    isPrivateMessage: false
                )
            ),
            canStartAuthenticatedMutation: true,
            isSubmitting: false,
            trimmedTitle: "",
            trimmedBody: "太短",
            minimumTitleLength: 0,
            minimumBodyLength: 15,
            selectedCategoryID: nil,
            selectedTagCount: 0,
            minimumRequiredTags: 0,
            recipientCount: 0
        )

        XCTAssertFalse(state.canSubmit)
        XCTAssertEqual(state.message, "回复至少需要 15 个字")
    }

    func testCategorySheetSummaryIncludesTagGroupsAndTemplate() {
        let category = TopicCategoryState(
            id: 7,
            name: "Rust",
            slug: "rust",
            parentCategoryId: nil,
            colorHex: nil,
            textColorHex: nil,
            topicTemplate: "## 模板",
            minimumRequiredTags: 2,
            requiredTagGroups: [RequiredTagGroupState(name: "platform", minCount: 1)],
            allowedTags: ["swift", "rust"],
            permission: 1,
            notificationLevel: nil
        )

        XCTAssertEqual(
            FireComposerCategoryGuidance.categorySheetSummary(for: category),
            "至少 2 个标签 · platform 至少 1 个 · 自带模板"
        )
    }

    func testSuggestedTagsPreferAllowedTagsAndExcludeSelectedOnes() {
        let category = TopicCategoryState(
            id: 7,
            name: "Rust",
            slug: "rust",
            parentCategoryId: nil,
            colorHex: nil,
            textColorHex: nil,
            topicTemplate: nil,
            minimumRequiredTags: 0,
            requiredTagGroups: [],
            allowedTags: ["swift", "rust", "Swift", "ios"],
            permission: 1,
            notificationLevel: nil
        )

        XCTAssertEqual(
            FireComposerCategoryGuidance.suggestedTags(
                category: category,
                topTags: ["general", "linuxdo"],
                selectedTags: ["rust"]
            ),
            ["swift", "ios"]
        )
    }

    func testMarkdownInsertionWrapsSelectedText() {
        let result = FireMarkdownInsertion.apply(
            .bold,
            text: "hello world",
            selectedRange: NSRange(location: 6, length: 5)
        )

        XCTAssertEqual(result.text, "hello **world**")
        XCTAssertEqual(result.selectedRange, NSRange(location: 8, length: 5))
    }

    func testMarkdownInsertionCreatesOrderedListAcrossSelectedLines() {
        let result = FireMarkdownInsertion.apply(
            .orderedList,
            text: "one\ntwo",
            selectedRange: NSRange(location: 0, length: 7)
        )

        XCTAssertEqual(result.text, "1. one\n2. two")
        XCTAssertEqual(result.selectedRange, NSRange(location: 0, length: 13))
    }

    func testMarkdownInsertionKeepsCursorInsideLinkPlaceholder() {
        let result = FireMarkdownInsertion.apply(
            .link,
            text: "",
            selectedRange: NSRange(location: 0, length: 0)
        )

        XCTAssertEqual(result.text, "[text](url)")
        XCTAssertEqual(result.selectedRange, NSRange(location: 1, length: 4))
    }
}
