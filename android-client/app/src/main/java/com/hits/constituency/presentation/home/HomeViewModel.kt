package com.hits.constituency.presentation.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.hits.constituency.data.model.ConstituencyDto
import com.hits.constituency.data.repository.ElectionRepository
import com.hits.constituency.presentation.common.UiState
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class HomeViewModel(
    private val repository: ElectionRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow<UiState<List<ConstituencyDto>>>(UiState.Loading)
    val uiState: StateFlow<UiState<List<ConstituencyDto>>> = _uiState.asStateFlow()

    fun loadConstituencies() {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            runCatching { repository.getConstituencies() }
                .onSuccess { _uiState.value = UiState.Success(it) }
                .onFailure { _uiState.value = UiState.Error(it.message ?: "Unable to load constituencies") }
        }
    }
}

