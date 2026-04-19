import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import { electionRouter } from './routes/electionRoutes.js';

export const createApp = () => {
  const app = express();

  app.use(cors());
  app.use(express.json({ limit: '1mb' }));
  app.use(morgan('dev'));

  app.use('/', electionRouter);

  app.use((error, _req, res, _next) => {
    console.error(error);
    res.status(500).json({
      message: 'Internal server error',
      error: error.message,
    });
  });

  return app;
};

