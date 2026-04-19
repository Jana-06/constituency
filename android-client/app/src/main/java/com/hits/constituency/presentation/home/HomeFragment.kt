package com.hits.constituency.presentation.home

import android.os.Bundle
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import androidx.core.view.isVisible
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout
import com.airbnb.lottie.LottieAnimationView
import com.google.android.material.button.MaterialButton
import com.google.android.material.snackbar.Snackbar
import com.hits.constituency.R
import com.hits.constituency.data.remote.ApiModule
import com.hits.constituency.data.repository.ElectionRepository
import com.hits.constituency.presentation.candidates.CandidateListFragment
import com.hits.constituency.presentation.common.ElectionViewModelFactory
import com.hits.constituency.presentation.common.UiState
import kotlinx.coroutines.launch

class HomeFragment : Fragment(R.layout.fragment_home) {

    private val viewModel by viewModels<HomeViewModel> {
        ElectionViewModelFactory(ElectionRepository(ApiModule.electionApiService))
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val logo = view.findViewById<ImageView>(R.id.clgLogo)
        val title = view.findViewById<TextView>(R.id.homeTitle)
        val list = view.findViewById<androidx.recyclerview.widget.RecyclerView>(R.id.constituencyRecycler)
        val swipe = view.findViewById<SwipeRefreshLayout>(R.id.swipeRefresh)
        val loading = view.findViewById<LottieAnimationView>(R.id.loadingView)
        val retry = view.findViewById<MaterialButton>(R.id.retryButton)

        logo.setImageResource(R.drawable.clg_logo)
        title.text = getString(R.string.hits_title)

        val adapter = ConstituencyAdapter { constituency ->
            parentFragmentManager.beginTransaction()
                .setCustomAnimations(
                    android.R.anim.slide_in_left,
                    android.R.anim.slide_out_right,
                    android.R.anim.slide_in_left,
                    android.R.anim.slide_out_right
                )
                .replace(R.id.fragmentContainer, CandidateListFragment.newInstance(constituency.name))
                .addToBackStack("candidates")
                .commit()
        }

        list.layoutManager = LinearLayoutManager(requireContext())
        list.adapter = adapter

        swipe.setOnRefreshListener { viewModel.loadConstituencies() }
        retry.setOnClickListener { viewModel.loadConstituencies() }

        viewLifecycleOwner.lifecycleScope.launch {
            viewModel.uiState.collect { state ->
                swipe.isRefreshing = false
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

        viewModel.loadConstituencies()
    }
}

