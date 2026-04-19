import { Router } from 'express';
import {
  getCandidatesBySearchQuery,
  getCandidatesByConstituency,
  getConstituencyByName,
  listConstituencies,
  syncMynetaData,
} from '../services/electionService.js';
import { env } from '../config/env.js';

export const electionRouter = Router();

electionRouter.get('/health', (_, res) => {
  res.json({ ok: true, service: 'myneta-tn-backend', timestamp: new Date().toISOString() });
});

electionRouter.get('/constituencies', async (_, res, next) => {
  try {
    const data = await listConstituencies();
    res.json({ count: data.length, items: data });
  } catch (error) {
    next(error);
  }
});

electionRouter.get('/constituency/:name', async (req, res, next) => {
  try {
    const data = await getConstituencyByName(req.params.name);
    if (!data) {
      return res.status(404).json({ message: 'Constituency not found' });
    }
    res.json(data);
  } catch (error) {
    next(error);
  }
});

electionRouter.get('/candidates/:constituency', async (req, res, next) => {
  try {
    const items = await getCandidatesByConstituency(req.params.constituency);
    res.json({ constituency: req.params.constituency, count: items.length, items });
  } catch (error) {
    next(error);
  }
});

electionRouter.get('/search', async (req, res, next) => {
  try {
    const query = String(req.query.q || '').trim();
    if (!query) {
      return res.status(400).json({ message: 'q query parameter is required' });
    }

    const limit = String(req.query.limit || '25');
    const result = await getCandidatesBySearchQuery(query, limit);
    res.json({
      query: result.query,
      sourcePath: result.sourcePath,
      count: result.candidates.length,
      items: result.candidates,
    });
  } catch (error) {
    next(error);
  }
});

electionRouter.post('/admin/scrape', async (req, res, next) => {
  try {
    const token = req.headers['x-api-key'];
    if (!env.apiAdminKey || token !== env.apiAdminKey) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const report = await syncMynetaData({
      baseUrl: env.mynetaBaseUrl,
      indexPath: env.mynetaIndexPath,
    });

    res.json(report);
  } catch (error) {
    next(error);
  }
});


