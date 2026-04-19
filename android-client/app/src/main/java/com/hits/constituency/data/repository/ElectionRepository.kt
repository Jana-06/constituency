package com.hits.constituency.data.repository

import com.hits.constituency.data.model.CandidateDto
import com.hits.constituency.data.model.ConstituencyDto
import com.hits.constituency.data.remote.ElectionApiService

class ElectionRepository(
    private val api: ElectionApiService
) {
    suspend fun getConstituencies(): List<ConstituencyDto> = api.getConstituencies().items

    suspend fun getCandidates(constituency: String): List<CandidateDto> =
        api.getCandidates(constituency).items
}

