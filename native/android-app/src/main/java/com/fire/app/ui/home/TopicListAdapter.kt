package com.fire.app.ui.home

import android.view.ViewGroup
import androidx.paging.PagingDataAdapter
import androidx.recyclerview.widget.DiffUtil
import uniffi.fire_uniffi_types.TopicRowState

class TopicListAdapter(
    private val onTagClick: (String) -> Unit = {},
    private val onTopicClick: (TopicRowState) -> Unit,
) : PagingDataAdapter<TopicRowState, TopicRowViewHolder>(TopicRowDiffCallback) {
    private val detailPatchesByTopicId = mutableMapOf<ULong, HomeTopicDetailPatch>()

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): TopicRowViewHolder {
        return TopicRowViewHolder.create(parent)
    }

    override fun onBindViewHolder(holder: TopicRowViewHolder, position: Int) {
        val row = getItem(position) ?: return
        val displayRow = detailPatchesByTopicId[row.topic.id]
            ?.let { HomeTopicDetailPatcher.patch(row, it) }
            ?: row
        holder.bind(displayRow, onTopicClick, onTagClick)
    }

    fun clearDetailPatches() {
        if (detailPatchesByTopicId.isEmpty()) {
            return
        }
        detailPatchesByTopicId.clear()
        notifyItemRangeChanged(0, itemCount)
    }

    fun applyDetailPatch(patch: HomeTopicDetailPatch): Boolean {
        detailPatchesByTopicId[patch.topicId] = patch
        var changed = false
        for (index in 0 until itemCount) {
            val row = peek(index) ?: continue
            if (HomeTopicDetailPatcher.patch(row, patch) != null) {
                notifyItemChanged(index)
                changed = true
            }
        }
        return changed
    }

    companion object {
        private val TopicRowDiffCallback = object : DiffUtil.ItemCallback<TopicRowState>() {
            override fun areItemsTheSame(oldItem: TopicRowState, newItem: TopicRowState): Boolean =
                oldItem.topic.id == newItem.topic.id

            override fun areContentsTheSame(oldItem: TopicRowState, newItem: TopicRowState): Boolean =
                oldItem == newItem
        }
    }
}
