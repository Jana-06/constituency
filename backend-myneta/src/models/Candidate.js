import mongoose from 'mongoose';

const candidateSchema = new mongoose.Schema(
  {
    constituencyName: { type: String, required: true, index: true },
    candidateName: { type: String, required: true, trim: true },
    partyName: { type: String, required: true, trim: true },
    symbol: { type: String, default: null },
    profileUrl: { type: String, default: null },
    stateName: { type: String, default: null },
    criminalCases: { type: Number, default: null },
    assets: { type: String, default: null },
    liabilities: { type: String, default: null },
    source: { type: String, default: 'myneta' },
    lastUpdated: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

candidateSchema.index(
  { constituencyName: 1, candidateName: 1, partyName: 1 },
  { unique: true }
);

export const Candidate = mongoose.model('Candidate', candidateSchema);


