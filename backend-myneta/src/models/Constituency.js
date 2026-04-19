import mongoose from 'mongoose';

const constituencySchema = new mongoose.Schema(
  {
    name: { type: String, required: true, unique: true, trim: true },
    slug: { type: String, required: true, unique: true, trim: true },
    state: { type: String, default: 'Tamil Nadu' },
    district: { type: String, default: null },
    lastUpdated: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

export const Constituency = mongoose.model('Constituency', constituencySchema);

