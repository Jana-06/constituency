package com.hits.constituency.presentation.common

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import com.hits.constituency.data.repository.ElectionRepository
import com.hits.constituency.presentation.candidates.CandidateListViewModel
import com.hits.constituency.presentation.home.HomeViewModel

class ElectionViewModelFactory(
    private val repository: ElectionRepository
) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        return when {
            modelClass.isAssignableFrom(HomeViewModel::class.java) -> HomeViewModel(repository) as T
            modelClass.isAssignableFrom(CandidateListViewModel::class.java) -> CandidateListViewModel(repository) as T
            else -> throw IllegalArgumentException("Unknown ViewModel class: ${modelClass.name}")
        }
    }
}

