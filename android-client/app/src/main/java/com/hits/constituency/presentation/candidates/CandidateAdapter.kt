package com.hits.constituency.presentation.candidates

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.animation.AlphaAnimation
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.hits.constituency.R
import com.hits.constituency.data.model.CandidateDto

class CandidateAdapter : RecyclerView.Adapter<CandidateAdapter.CandidateViewHolder>() {

    private val items = mutableListOf<CandidateDto>()

    fun submitList(newItems: List<CandidateDto>) {
        items.clear()
        items.addAll(newItems)
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): CandidateViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_candidate, parent, false)
        return CandidateViewHolder(view)
    }

    override fun onBindViewHolder(holder: CandidateViewHolder, position: Int) {
        holder.bind(items[position])
    }

    override fun getItemCount(): Int = items.size

    class CandidateViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val candidateName: TextView = itemView.findViewById(R.id.candidateName)
        private val partyName: TextView = itemView.findViewById(R.id.partyName)
        private val symbol: TextView = itemView.findViewById(R.id.symbolName)

        fun bind(item: CandidateDto) {
            candidateName.text = item.candidateName
            partyName.text = item.partyName
            symbol.text = item.symbol ?: "Symbol: Not available"

            val fade = AlphaAnimation(0f, 1f).apply { duration = 300 }
            itemView.startAnimation(fade)
        }
    }
}

