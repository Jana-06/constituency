import { Candidate } from '../models/Candidate.js';
import { env } from '../config/env.js';
import { Constituency } from '../models/Constituency.js';
import { scrapeCandidatesFromSearch, scrapeCandidatesFromSummary } from './mynetaScraper.js';

export const syncMynetaData = async ({ baseUrl, indexPath }) => {
  const { candidates, sourcePath } = await scrapeCandidatesFromSummary({
    baseUrl,
    indexPath,
  });

  const constituencyMap = new Map();

  for (const candidate of candidates) {
    const slug = candidate.constituencyName
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '');

    constituencyMap.set(slug, {
      name: candidate.constituencyName,
      slug,
      lastUpdated: new Date(),
    });

    await Candidate.findOneAndUpdate(
      {
        constituencyName: candidate.constituencyName,
        candidateName: candidate.candidateName,
        partyName: candidate.partyName,
      },
      candidate,
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );
  }

  for (const entry of constituencyMap.values()) {
    await Constituency.findOneAndUpdate(
      { slug: entry.slug },
      entry,
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );
  }

  return {
    constituencies: constituencyMap.size,
    candidates: candidates.length,
    sourcePath,
    syncedAt: new Date().toISOString(),
  };
};

export const listConstituencies = async () => {
  return Constituency.find({}, { _id: 0, name: 1, slug: 1, lastUpdated: 1 })
    .sort({ name: 1 })
    .lean();
};

export const getConstituencyByName = async (name) => {
  const normalized = (name || '').trim();
  const constituency = await Constituency.findOne({
    name: new RegExp(`^${normalized}$`, 'i'),
  }).lean();

  if (!constituency) return null;

  const candidates = await Candidate.find(
    { constituencyName: new RegExp(`^${normalized}$`, 'i') },
    { _id: 0, __v: 0 }
  )
    .sort({ partyName: 1, candidateName: 1 })
    .lean();

  return { ...constituency, candidates };
};

export const getCandidatesByConstituency = async (constituencyName) => {
  return Candidate.find(
    { constituencyName: new RegExp(`^${(constituencyName || '').trim()}$`, 'i') },
    { _id: 0, __v: 0 }
  )
    .sort({ partyName: 1, candidateName: 1 })
    .lean();
};

export const getCandidatesBySearchQuery = async (query, limit = 25) => {
  const max = Number.isFinite(Number(limit)) ? Math.max(1, Math.min(100, Number(limit))) : 25;
  const result = await scrapeCandidatesFromSearch({
    baseUrl: env.mynetaBaseUrl,
    query,
    maxResults: max,
  });

  return result;
};


