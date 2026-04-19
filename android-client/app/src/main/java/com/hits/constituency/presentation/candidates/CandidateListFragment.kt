package com.hits.constituency.presentation.candidates

import android.os.Bundle
import android.view.View
import android.widget.TextView
import androidx.core.view.isVisible
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import com.airbnb.lottie.LottieAnimationView
import com.google.android.material.button.MaterialButton
import com.google.android.material.snackbar.Snackbar
import com.hits.constituency.R
import com.hits.constituency.data.remote.ApiModule
import com.hits.constituency.data.repository.ElectionRepository
import com.hits.constituency.presentation.common.ElectionViewModelFactory
import com.hits.constituency.presentation.common.UiState
import com.hits.constituency.presentation.poll.PollFragment
import kotlinx.coroutines.launch

class CandidateListFragment : Fragment(R.layout.fragment_candidate_list) {

    private val viewModel by viewModels<CandidateListViewModel> {
        ElectionViewModelFactory(ElectionRepository(ApiModule.electionApiService))
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val constituency = requireArguments().getString(ARG_CONSTITUENCY).orEmpty()
        val title = view.findViewById<TextView>(R.id.constituencyTitle)
        val list = view.findViewById<androidx.recyclerview.widget.RecyclerView>(R.id.candidateRecycler)
        val loading = view.findViewById<LottieAnimationView>(R.id.loadingView)
        val retry = view.findViewById<MaterialButton>(R.id.retryButton)
        val poll = view.findViewById<MaterialButton>(R.id.openPollButton)

        title.text = constituency

        val adapter = CandidateAdapter()
        list.layoutManager = LinearLayoutManager(requireContext())
        list.adapter = adapter

        retry.setOnClickListener { viewModel.loadCandidates(constituency) }
        poll.setOnClickListener {
            parentFragmentManager.beginTransaction()
                .setCustomAnimations(android.R.anim.fade_in, android.R.anim.fade_out)
                .replace(R.id.fragmentContainer, PollFragment.newInstance(constituency))
                .addToBackStack("poll")
                .commit()
        }

        viewLifecycleOwner.lifecycleScope.launch {
            viewModel.uiState.collect { state ->
                when (state) {
                    is UiState.Loading -> {
                        loading.isVisible = true
                        retry.isVisible = false
                    }

                    is UiState.Success -> {
                        loading.isVisible = false
                        retry.isVisible = false
                        adapter.submitList(state.data)
                    }

                    is UiState.Error -> {
                        loading.isVisible = false
                        retry.isVisible = true
                        Snackbar.make(view, state.message, Snackbar.LENGTH_LONG).show()
                    }
                }
            }
        }

        viewModel.loadCandidates(constituency)
    }

    companion object {
        private const val ARG_CONSTITUENCY = "arg_constituency"

        fun newInstance(constituency: String): CandidateListFragment {
            return CandidateListFragment().apply {
                arguments = Bundle().apply {
                    putString(ARG_CONSTITUENCY, constituency)
                }
            }
        }
    }
}

