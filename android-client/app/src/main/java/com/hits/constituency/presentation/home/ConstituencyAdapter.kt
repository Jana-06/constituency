package com.hits.constituency.presentation.home

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.animation.AlphaAnimation
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.card.MaterialCardView
import com.hits.constituency.R
import com.hits.constituency.data.model.ConstituencyDto

class ConstituencyAdapter(
    private val onClick: (ConstituencyDto) -> Unit
) : RecyclerView.Adapter<ConstituencyAdapter.ConstituencyViewHolder>() {

    private val items = mutableListOf<ConstituencyDto>()

    fun submitList(newItems: List<ConstituencyDto>) {
        items.clear()
        items.addAll(newItems)
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ConstituencyViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_constituency, parent, false)
        return ConstituencyViewHolder(view, onClick)
    }

    override fun onBindViewHolder(holder: ConstituencyViewHolder, position: Int) {
        holder.bind(items[position])
    }

    override fun getItemCount(): Int = items.size

    class ConstituencyViewHolder(
        itemView: View,
        private val onClick: (ConstituencyDto) -> Unit
    ) : RecyclerView.ViewHolder(itemView) {

        private val card: MaterialCardView = itemView.findViewById(R.id.constituencyCard)
        private val name: TextView = itemView.findViewById(R.id.constituencyName)
        private val updated: TextView = itemView.findViewById(R.id.constituencyUpdated)

        fun bind(item: ConstituencyDto) {
            name.text = item.name
            updated.text = "Last updated: ${item.lastUpdated ?: "N/A"}"
            card.setOnClickListener { onClick(item) }

            val fade = AlphaAnimation(0f, 1f).apply { duration = 280 }
            itemView.startAnimation(fade)
        }
    }
}

