package com.hits.constituency.presentation.candidates

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.hits.constituency.data.model.CandidateDto
import com.hits.constituency.data.repository.ElectionRepository
import com.hits.constituency.presentation.common.UiState
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class CandidateListViewModel(
    private val repository: ElectionRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow<UiState<List<CandidateDto>>>(UiState.Loading)
    val uiState: StateFlow<UiState<List<CandidateDto>>> = _uiState.asStateFlow()

    fun loadCandidates(constituency: String) {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            runCatching { repository.getCandidates(constituency) }
                .onSuccess { _uiState.value = UiState.Success(it) }
                .onFailure { _uiState.value = UiState.Error(it.message ?: "Unable to load candidates") }
        }
    }
}

