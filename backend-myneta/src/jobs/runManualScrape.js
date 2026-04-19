import { connectMongo } from '../db/mongoose.js';
import { env } from '../config/env.js';
import { syncMynetaData } from '../services/electionService.js';

const run = async () => {
  await connectMongo(env.mongoUri);
  const report = await syncMynetaData({
    baseUrl: env.mynetaBaseUrl,
    indexPath: env.mynetaIndexPath,
  });
  console.log(JSON.stringify(report, null, 2));
  process.exit(0);
};

run().catch((error) => {
  console.error(error);
  process.exit(1);
});

