import mongoose from 'mongoose';

export const connectMongo = async (mongoUri) => {
  mongoose.set('strictQuery', true);
  await mongoose.connect(mongoUri);
};

