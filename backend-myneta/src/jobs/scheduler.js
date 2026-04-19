import cron from 'node-cron';
import { env } from '../config/env.js';
import { syncMynetaData } from '../services/electionService.js';

export const startScheduler = () => {
  if (!env.scrapeCron) return;

  cron.schedule(env.scrapeCron, async () => {
    try {
      await syncMynetaData({
        baseUrl: env.mynetaBaseUrl,
        indexPath: env.mynetaIndexPath,
      });
      // Keep logs simple and parseable in cloud providers.
      console.log(`[CRON] Myneta sync complete at ${new Date().toISOString()}`);
    } catch (error) {
      console.error('[CRON] Myneta sync failed:', error.message);
    }
  });
};

