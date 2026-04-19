package com.hits.constituency.data.model

data class ConstituencyDto(
    val name: String,
    val slug: String,
    val lastUpdated: String?
)

data class ConstituenciesResponse(
    val count: Int,
    val items: List<ConstituencyDto>
)

data class CandidateDto(
    val constituencyName: String,
    val candidateName: String,
    val partyName: String,
    val symbol: String?
)

data class CandidatesResponse(
    val constituency: String,
    val count: Int,
    val items: List<CandidateDto>
)

