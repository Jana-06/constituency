import dotenv from 'dotenv';

dotenv.config();

export const env = {
  port: Number(process.env.PORT || 8080),
  mongoUri: process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/hits_constituency',
  mynetaBaseUrl: process.env.MYNETA_BASE_URL || 'https://www.myneta.info',
  mynetaIndexPath:
    process.env.MYNETA_TN_INDEX_PATH || '/TamilNadu2026/index.php?action=summary',
  scrapeCron: process.env.SCRAPE_CRON || '0 */12 * * *',
  apiAdminKey: process.env.API_ADMIN_KEY || '',
};

