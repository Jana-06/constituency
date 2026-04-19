package com.hits.constituency.presentation.poll

import android.animation.ObjectAnimator
import android.content.Context
import android.os.Bundle
import android.view.View
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.RadioButton
import android.widget.RadioGroup
import android.widget.TextView
import androidx.fragment.app.Fragment
import com.google.android.material.button.MaterialButton
import com.google.android.material.snackbar.Snackbar
import com.hits.constituency.R

class PollFragment : Fragment(R.layout.fragment_poll) {

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        val constituency = requireArguments().getString(ARG_CONSTITUENCY).orEmpty()

        val question = view.findViewById<TextView>(R.id.pollQuestion)
        val optionsGroup = view.findViewById<RadioGroup>(R.id.pollOptionsGroup)
        val voteButton = view.findViewById<MaterialButton>(R.id.voteButton)
        val resultsContainer = view.findViewById<LinearLayout>(R.id.resultsContainer)

        question.text = "Who do you think will win $constituency constituency?"

        voteButton.isEnabled = !hasVoted(constituency)

        voteButton.setOnClickListener {
            val checkedId = optionsGroup.checkedRadioButtonId
            if (checkedId == View.NO_ID) {
                Snackbar.make(view, "Select one option", Snackbar.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            val selected = optionsGroup.findViewById<RadioButton>(checkedId).text.toString()
            storeVote(constituency, selected)
            markVoted(constituency)
            voteButton.isEnabled = false
            Snackbar.make(view, "Vote submitted", Snackbar.LENGTH_SHORT).show()
            renderResults(resultsContainer, constituency)
        }

        renderResults(resultsContainer, constituency)
    }

    private fun renderResults(container: LinearLayout, constituency: String) {
        container.removeAllViews()

        val votes = getVotes(constituency)
        if (votes.isEmpty()) return

        val totalVotes = votes.values.sum().coerceAtLeast(1)
        votes.entries.forEach { entry ->
            val item = layoutInflater.inflate(R.layout.item_poll_result, container, false)
            val label = item.findViewById<TextView>(R.id.resultLabel)
            val percent = item.findViewById<TextView>(R.id.resultPercent)
            val bar = item.findViewById<ProgressBar>(R.id.resultBar)

            val score = ((entry.value * 100f) / totalVotes).toInt()
            label.text = entry.key
            percent.text = "$score%"
            ObjectAnimator.ofInt(bar, "progress", 0, score).apply {
                duration = 500
                start()
            }
            container.addView(item)
        }
    }

    private fun storeVote(constituency: String, option: String) {
        val prefs = requireContext().getSharedPreferences(POLL_PREFS, Context.MODE_PRIVATE)
        val key = "$constituency::$option"
        val current = prefs.getInt(key, 0)
        prefs.edit().putInt(key, current + 1).apply()
    }

    private fun getVotes(constituency: String): Map<String, Int> {
        val prefs = requireContext().getSharedPreferences(POLL_PREFS, Context.MODE_PRIVATE)
        return DEFAULT_OPTIONS.associateWith { option ->
            prefs.getInt("$constituency::$option", 0)
        }
    }

    private fun hasVoted(constituency: String): Boolean {
        val prefs = requireContext().getSharedPreferences(POLL_PREFS, Context.MODE_PRIVATE)
        return prefs.getBoolean("$constituency::voted", false)
    }

    private fun markVoted(constituency: String) {
        val prefs = requireContext().getSharedPreferences(POLL_PREFS, Context.MODE_PRIVATE)
        prefs.edit().putBoolean("$constituency::voted", true).apply()
    }

    companion object {
        private const val ARG_CONSTITUENCY = "arg_constituency"
        private const val POLL_PREFS = "poll_prefs"
        private val DEFAULT_OPTIONS = listOf("DMK", "AIADMK", "TVK", "NTK")

        fun newInstance(constituency: String): PollFragment {
            return PollFragment().apply {
                arguments = Bundle().apply { putString(ARG_CONSTITUENCY, constituency) }
            }
        }
    }
}
