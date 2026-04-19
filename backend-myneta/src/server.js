import { env } from './config/env.js';
import { connectMongo } from './db/mongoose.js';
import { startScheduler } from './jobs/scheduler.js';
import { createApp } from './app.js';

const bootstrap = async () => {
  await connectMongo(env.mongoUri);
  const app = createApp();

  app.listen(env.port, () => {
    console.log(`API running on http://localhost:${env.port}`);
  });

  startScheduler();
};

bootstrap().catch((error) => {
  console.error('Startup failed:', error);
  process.exit(1);
});

