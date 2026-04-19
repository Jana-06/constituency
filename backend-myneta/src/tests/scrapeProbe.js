import { env } from '../config/env.js';
import {
  scrapeConstituencies,
  scrapeCandidatesByConstituency,
  scrapeCandidatesFromSummary,
} from '../services/mynetaScraper.js';

const run = async () => {
  const summary = await scrapeCandidatesFromSummary({
    baseUrl: env.mynetaBaseUrl,
    indexPath: env.mynetaIndexPath,
  });

  console.log(`Summary source path used: ${summary.sourcePath}`);

  const constituencies = await scrapeConstituencies({
    baseUrl: env.mynetaBaseUrl,
    indexPath: env.mynetaIndexPath,
  });

  console.log(`Constituencies found: ${constituencies.length}`);
  if (constituencies.length === 0) {
    throw new Error('No constituencies parsed. Update selectors or source URL.');
  }

  const sample = constituencies[0];
  console.log(`Sample constituency: ${sample.name}`);

  const candidates = await scrapeCandidatesByConstituency({
    baseUrl: env.mynetaBaseUrl,
    indexPath: env.mynetaIndexPath,
    constituencyName: sample.name,
  });

  console.log(`Candidates parsed for ${sample.name}: ${candidates.length}`);
  console.log(candidates.slice(0, 5));
};

run().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
