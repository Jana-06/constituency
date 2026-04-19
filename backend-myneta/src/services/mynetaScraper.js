import axios from 'axios';
import * as cheerio from 'cheerio';

const cleanText = (value) =>
  value
    ?.replace(/\s+/g, ' ')
    .replace(/[\n\t]/g, ' ')
    .trim() || '';

const slugify = (text) =>
  cleanText(text)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');

const toAbsolute = (baseUrl, href) => {
  if (!href) return null;
  if (href.startsWith('http')) return href;
  return `${baseUrl}${href.startsWith('/') ? '' : '/'}${href}`;
};

const extractTitleMeta = (titleText) => {
  const raw = cleanText(titleText);
  if (!raw) return null;

  // Example: Name(Party):Constituency- CHENNAI NORTH(TAMIL NADU) - Affidavit...
  const match = raw.match(/^(.*?)\((.*?)\)\s*:\s*Constituency-\s*(.*?)\((.*?)\)\s*-/i);
  if (!match) return null;

  return {
    candidateName: cleanText(match[1]),
    partyName: cleanText(match[2]),
    constituencyName: cleanText(match[3]),
    stateName: cleanText(match[4]),
  };
};

const extractLabeledValue = ($, label) => {
  const row = $('tr').filter((_, tr) => {
    const firstCell = cleanText($(tr).find('td').first().text()).toLowerCase();
    return firstCell === label.toLowerCase();
  }).first();

  if (!row.length) return null;
  return cleanText(row.find('td').eq(1).text()) || null;
};

const extractCriminalCases = ($) => {
  const text = cleanText($('body').text());
  if (/no criminal cases/i.test(text)) return 0;

  const exact = text.match(/(\d+)\s+criminal\s+cases?/i);
  if (exact) return Number(exact[1]);
  return null;
};

const parseCandidateProfileDetails = ({ html, profileUrl, fallbackName }) => {
  const $ = cheerio.load(html);
  const titleMeta = extractTitleMeta($('title').first().text());

  return {
    candidateName: titleMeta?.candidateName || fallbackName || cleanText($('h2').first().text()) || null,
    partyName: titleMeta?.partyName || null,
    constituencyName: titleMeta?.constituencyName || null,
    stateName: titleMeta?.stateName || null,
    symbol: null,
    profileUrl,
    criminalCases: extractCriminalCases($),
    assets: extractLabeledValue($, 'Assets:'),
    liabilities: extractLabeledValue($, 'Liabilities:'),
  };
};

const parseCandidatesFromSummaryHtml = ({ html, baseUrl, sourcePath }) => {
  const $ = cheerio.load(html);
  const candidates = [];

  $('table').each((_, table) => {
    const rows = $(table).find('tr');
    if (!rows.length) return;

    rows.each((rowIndex, row) => {
      const cells = $(row).find('td');
      if (cells.length < 4) return;

      const candidateLinkCell = cells
        .filter((_, cell) => $(cell).find('a[href*="candidate.php"]').length > 0)
        .first();

      if (!candidateLinkCell.length) return;

      const candidateName = cleanText($(candidateLinkCell).text());
      const candidateLink = $(candidateLinkCell).find('a[href*="candidate.php"]').first();
      const profileHref = candidateLink.attr('href');

      let constituencyName = cleanText($(cells[2]).text());
      let partyName = cleanText($(cells[3]).text());

      if (!constituencyName || !partyName) {
        const rowText = cleanText($(row).text());
        const parts = rowText.split(' ');
        if (parts.length >= 4 && !constituencyName) {
          constituencyName = parts[2];
        }
      }

      if (!candidateName || !constituencyName || !partyName) return;
      if (rowIndex === 0 && /sno|candidate|constituency|party/i.test(candidateName)) return;

      candidates.push({
        constituencyName,
        candidateName,
        partyName,
        symbol: null,
        profileUrl: toAbsolute(baseUrl, profileHref),
        source: 'myneta',
        sourcePath,
        lastUpdated: new Date(),
      });
    });
  });

  const deduped = new Map();
  for (const item of candidates) {
    const key = `${item.constituencyName}|${item.candidateName}|${item.partyName}`;
    if (!deduped.has(key)) deduped.set(key, item);
  }

  return Array.from(deduped.values());
};

const summaryDirectory = (sourcePath) => {
  const qIndex = sourcePath.indexOf('?');
  const pathOnly = qIndex === -1 ? sourcePath : sourcePath.slice(0, qIndex);
  const slashIndex = pathOnly.lastIndexOf('/');
  return slashIndex === -1 ? '/' : pathOnly.slice(0, slashIndex + 1);
};

const buildSummaryPagePath = (sourcePath, href) => {
  if (!href) return null;
  if (href.startsWith('/')) return href;
  const dir = summaryDirectory(sourcePath);
  return `${dir}${href}`;
};

const extractSummaryPagePaths = ({ html, sourcePath }) => {
  const matches = [...String(html).matchAll(/index\.php\?action=summary[^"'#\s]*/g)]
    .map((match) => match[0])
    .map((href) => buildSummaryPagePath(sourcePath, href));

  const all = new Set([sourcePath, ...matches]);
  return Array.from(all);
};

const isBrokenElectionPage = (html) => {
  const text = cleanText(html).toLowerCase();
  return text.includes('unable to connect to mysql') || text.includes('unknown database');
};

export const scrapeCandidatesFromSummary = async ({ baseUrl, indexPath }) => {
  // Try requested path first, then known stable fallback pages.
  const pathCandidates = [
    indexPath,
    '/TamilNadu2026/index.php?action=summary',
    '/TamilNadu2021/index.php?action=summary',
  ].filter(Boolean);

  const tried = new Set();

  for (const path of pathCandidates) {
    if (tried.has(path)) continue;
    tried.add(path);

    const url = `${baseUrl}${path}`;

    try {
      const response = await axios.get(url, { timeout: 20000 });
      if (isBrokenElectionPage(response.data)) {
        continue;
      }

      const pagePaths = extractSummaryPagePaths({
        html: response.data,
        sourcePath: path,
      });

      const pageResults = await Promise.allSettled(
        pagePaths.map(async (pagePath) => {
          const pageUrl = `${baseUrl}${pagePath}`;
          const pageResponse = pagePath === path ? response : await axios.get(pageUrl, { timeout: 20000 });
          return parseCandidatesFromSummaryHtml({
            html: pageResponse.data,
            baseUrl,
            sourcePath: pagePath,
          });
        })
      );

      const allCandidates = pageResults.flatMap((result) =>
        result.status === 'fulfilled' ? result.value : []
      );

      const deduped = new Map();
      for (const item of allCandidates) {
        const key = `${item.constituencyName}|${item.candidateName}|${item.partyName}`;
        if (!deduped.has(key)) deduped.set(key, item);
      }

      if (deduped.size > 0) {
        return { candidates: Array.from(deduped.values()), sourcePath: path };
      }
    } catch (_) {
      // Try next fallback URL.
    }
  }

  throw new Error('Unable to scrape candidates from Myneta summary pages.');
};

export const scrapeConstituencies = async ({ baseUrl, indexPath }) => {
  const { candidates, sourcePath } = await scrapeCandidatesFromSummary({
    baseUrl,
    indexPath,
  });

  const unique = new Map();
  for (const item of candidates) {
    const slug = slugify(item.constituencyName);
    if (!unique.has(slug)) {
      unique.set(slug, {
        name: item.constituencyName,
        slug,
        url: `${sourcePath}#${slug}`,
      });
    }
  }

  return Array.from(unique.values()).sort((a, b) => a.name.localeCompare(b.name));
};

export const scrapeCandidatesByConstituency = async ({
  baseUrl,
  constituencyName,
  indexPath,
}) => {
  const { candidates } = await scrapeCandidatesFromSummary({
    baseUrl,
    indexPath,
  });

  return candidates.filter(
    (item) => item.constituencyName.toLowerCase() === cleanText(constituencyName).toLowerCase()
  );
};

export const scrapeCandidatesFromSearch = async ({
  baseUrl,
  query,
  maxResults = 40,
}) => {
  const normalizedQuery = cleanText(query);
  if (!normalizedQuery) {
    throw new Error('Search query is required.');
  }

  const searchUrl = `${baseUrl}/search_myneta.php?q=${encodeURIComponent(normalizedQuery)}`;
  const response = await axios.get(searchUrl, { timeout: 25000 });
  const $ = cheerio.load(response.data);

  const candidates = [];
  const seen = new Set();

  $('a[href*="candidate.php"]').each((_, anchor) => {
    if (candidates.length >= maxResults) return;

    const href = cleanText($(anchor).attr('href'));
    const name = cleanText($(anchor).text());
    if (!href || !name) return;

    const profileUrl = toAbsolute(baseUrl, href);
    if (!profileUrl || seen.has(profileUrl)) return;
    seen.add(profileUrl);

    candidates.push({ profileUrl, candidateName: name });
  });

  const result = [];
  for (const item of candidates) {
    try {
      const detailResponse = await axios.get(item.profileUrl, { timeout: 25000 });
      const details = parseCandidateProfileDetails({
        html: detailResponse.data,
        profileUrl: item.profileUrl,
        fallbackName: item.candidateName,
      });

      result.push({
        ...details,
        source: 'myneta-search',
        sourcePath: `/search_myneta.php?q=${encodeURIComponent(normalizedQuery)}`,
        lastUpdated: new Date(),
      });
    } catch (_) {
      result.push({
        candidateName: item.candidateName,
        constituencyName: null,
        partyName: null,
        stateName: null,
        symbol: null,
        criminalCases: null,
        assets: null,
        liabilities: null,
        profileUrl: item.profileUrl,
        source: 'myneta-search',
        sourcePath: `/search_myneta.php?q=${encodeURIComponent(normalizedQuery)}`,
        lastUpdated: new Date(),
      });
    }
  }

  return {
    query: normalizedQuery,
    sourcePath: `/search_myneta.php?q=${encodeURIComponent(normalizedQuery)}`,
    candidates: result,
  };
};




