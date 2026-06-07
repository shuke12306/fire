import Foundation
import UIKit

struct FirePostLayoutTraitSignature: Hashable, Sendable {
    let contentWidthPixels: Int
    let contentSizeCategory: String
}

struct FirePostCellLayoutKey: Hashable, Sendable {
    let postID: UInt64
    let depth: Int
    let showsThreadLine: Bool
    let showsDivider: Bool
    let replyTargetPostNumber: UInt32?
    let replyContext: String?
    let textContentID: String
    let imageSignature: [String]
    let pollSignature: [String]
    let boostSignature: [String]
    let hasReactions: Bool
    let replyShortcutCount: UInt32?
    let textExpansionState: FirePostTextExpansionState
    let acceptedAnswer: Bool
    let hasAuthorMetadata: Bool
    let trait: FirePostLayoutTraitSignature
}

struct FirePostCellLayout: Equatable, Sendable {
    let key: FirePostCellLayoutKey
    let totalHeight: CGFloat
    let avatarFrame: CGRect
    let threadLineFrame: CGRect?
    let metaFrame: CGRect
    let textFrame: CGRect?
    let textContainerSize: CGSize
    let textExpansionFrame: CGRect?
    let imageFrames: [CGRect]
    let pollFrames: [CGRect]
    let boostFrames: [CGRect]
    let replyShortcutFrame: CGRect?
    let reactionsFrame: CGRect?
    let menuFrame: CGRect?
    let dividerFrame: CGRect?
}

enum FirePostReactionDisplayPolicy {
    static let replyVisibleReactionLimit = 3
    static let wrappedReactionMaxLines = 2

    static func visibleReactions(
        from reactions: [TopicReactionState],
        depth: Int
    ) -> [TopicReactionState] {
        guard depth > 0 else {
            return reactions
        }
        return Array(reactions.prefix(replyVisibleReactionLimit))
    }

    static func allowsWrapping(depth: Int) -> Bool {
        depth == 0
    }
}

enum FirePostBoostDisplay {
    static func displayLine(for boost: TopicPostBoostState) -> String {
        let username = cleaned(boost.user.username)
        let displayName = cleaned(boost.user.name)
        let author = username.map { "@\($0)" }
            ?? displayName
            ?? "User \(boost.user.id)"
        let text = cleaned(boost.displayText)
        guard let text else { return author }
        return "\(author): \(text)"
    }

    static func contentToken(for boosts: [TopicPostBoostState]) -> String {
        boosts.map { boost in
            [
                String(boost.id),
                boost.user.username,
                boost.user.name ?? "",
                boost.displayText,
                String(boost.canDelete),
                String(boost.canFlag),
            ].joined(separator: "\u{1E}")
        }.joined(separator: "\u{1D}")
    }

    private static func cleaned(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct FirePostTextExpansionState: Hashable, Sendable {
    static let collapsedLineLimit = 4

    let isCollapsible: Bool
    let isExpanded: Bool

    static let disabled = FirePostTextExpansionState(
        isCollapsible: false,
        isExpanded: true
    )

    var isCollapsed: Bool {
        isCollapsible && !isExpanded
    }
}

struct FirePostCellRenderPayload {
    let post: TopicPostState
    let renderContent: FireTopicPostRenderContent
    let baseURLString: String
    let canWriteInteractions: Bool
    let isMutating: Bool
    let replyContext: String?
    let replyTargetPostNumber: UInt32?
    let replyShortcutCount: UInt32?
    let isLoadingReplyContext: Bool
    let textExpansionState: FirePostTextExpansionState
    let showsDivider: Bool
    let layoutWidth: CGFloat
    let layout: FirePostCellLayout?
    let layoutKey: FirePostCellLayoutKey?

    init(
        post: TopicPostState,
        renderContent: FireTopicPostRenderContent,
        baseURLString: String,
        canWriteInteractions: Bool,
        isMutating: Bool,
        replyContext: String?,
        replyTargetPostNumber: UInt32?,
        replyShortcutCount: UInt32?,
        isLoadingReplyContext: Bool,
        textExpansionState: FirePostTextExpansionState,
        showsDivider: Bool,
        layoutWidth: CGFloat,
        layout: FirePostCellLayout? = nil,
        layoutKey: FirePostCellLayoutKey? = nil
    ) {
        self.post = post
        self.renderContent = renderContent
        self.baseURLString = baseURLString
        self.canWriteInteractions = canWriteInteractions
        self.isMutating = isMutating
        self.replyContext = replyContext
        self.replyTargetPostNumber = replyTargetPostNumber
        self.replyShortcutCount = replyShortcutCount
        self.isLoadingReplyContext = isLoadingReplyContext
        self.textExpansionState = textExpansionState
        self.showsDivider = showsDivider
        self.layoutWidth = layoutWidth
        self.layout = layout
        self.layoutKey = layoutKey
    }
}

struct FirePostCellCallbacks {
    let onLinkTapped: (URL) -> Void
    let onOpenImage: (FireCookedImage) -> Void
    let onToggleLike: (TopicPostState) -> Void
    let onSelectReaction: (TopicPostState, String) -> Void
    let onEditPost: (TopicPostState) -> Void
    let onBookmarkPost: (TopicPostState) -> Void
    let onDeletePost: (TopicPostState) -> Void
    let onRecoverPost: (TopicPostState) -> Void
    let onFlagPost: (TopicPostState) -> Void
    let onOpenReplyTarget: (UInt32) -> Void
    let onOpenReplies: (TopicPostState) -> Void
    let onExpandText: (TopicPostState) -> Void
    let onVotePoll: (TopicPostState, PollState, [String]) -> Void
    let onUnvotePoll: (TopicPostState, PollState) -> Void
    let onSwipeReply: (TopicPostState) -> Void
}

enum FirePostAuthorMetadataDisplay {
    static func displayName(for post: TopicPostState) -> String {
        cleaned(post.name) ?? cleaned(post.username) ?? "Unknown"
    }

    static func metadataParts(for post: TopicPostState) -> [String] {
        let metadata = post.authorMetadata
        let username = cleaned(post.username)
        let displayName = displayName(for: post)

        let title = cleaned(metadata.userTitle)
        let group = cleaned(metadata.primaryGroupName)
        let flair = cleaned(metadata.flairName)
        let statusDescription = cleaned(metadata.userStatusDescription)
        let statusEmoji = cleaned(metadata.userStatusEmoji).map { ":\($0):" }
        let hasMetadataBeyondUsername = title != nil
            || group != nil
            || flair != nil
            || metadata.admin
            || metadata.moderator
            || metadata.groupModerator
            || statusDescription != nil
            || statusEmoji != nil

        var parts: [String] = []
        if let username {
            let showsUsername = displayName.caseInsensitiveCompare(username) != .orderedSame
                || hasMetadataBeyondUsername
            if showsUsername {
                parts.append("@\(username)")
            }
        }
        if let title {
            parts.append(title)
        }
        if let group {
            parts.append(group)
        }
        if let flair,
           flair.caseInsensitiveCompare(group ?? "") != .orderedSame {
            parts.append(flair)
        }
        if metadata.admin {
            parts.append("管理员")
        }
        if metadata.moderator {
            parts.append("版主")
        }
        if metadata.groupModerator {
            parts.append("组版主")
        }
        if let statusDescription {
            parts.append(statusDescription)
        } else if let statusEmoji {
            parts.append(statusEmoji)
        }
        return parts
    }

    static func hasVisibleMetadata(_ post: TopicPostState) -> Bool {
        !metadataParts(for: post).isEmpty
    }

    static func contentToken(for post: TopicPostState) -> String {
        let metadata = post.authorMetadata
        var parts: [String] = []
        parts.reserveCapacity(10)
        parts.append(displayName(for: post))
        parts.append(metadataParts(for: post).joined(separator: "|"))
        parts.append(metadata.userId.map(String.init) ?? "")
        parts.append(metadata.flairUrl ?? "")
        parts.append(metadata.flairBgColor ?? "")
        parts.append(metadata.flairColor ?? "")
        parts.append(metadata.flairGroupId.map(String.init) ?? "")
        parts.append(String(metadata.admin))
        parts.append(String(metadata.moderator))
        parts.append(String(metadata.groupModerator))
        return parts.joined(separator: "\u{1F}")
    }

    private static func cleaned(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
