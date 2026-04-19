package com.hits.constituency.data.remote

import com.hits.constituency.data.model.CandidatesResponse
import com.hits.constituency.data.model.ConstituenciesResponse
import retrofit2.http.GET
import retrofit2.http.Path

interface ElectionApiService {
    @GET("constituencies")
    suspend fun getConstituencies(): ConstituenciesResponse

    @GET("candidates/{constituency}")
    suspend fun getCandidates(@Path("constituency") constituency: String): CandidatesResponse
}

