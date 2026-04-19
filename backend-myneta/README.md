# Myneta Tamil Nadu Backend

Node.js + MongoDB service that scrapes constituency-wise candidate data and exposes REST APIs for your Android client.

## Endpoints

- `GET /constituencies`
- `GET /constituency/:name`
- `GET /candidates/:constituency`
- `GET /search?q=tamil+nadu&limit=25`
- `POST /admin/scrape` (requires `x-api-key`)
- `GET /health`

## Quick Start

```bash
cp .env.example .env
npm install
npm run scrape
npm run dev
```

## Data Model

### constituencies

```json
{
  "name": "Perambur",
  "slug": "perambur",
  "state": "Tamil Nadu",
  "district": null,
  "lastUpdated": "2026-04-04T09:00:00.000Z"
}
```

### candidates

```json
{
  "constituencyName": "Perambur",
  "candidateName": "Example Candidate",
  "partyName": "TVK",
  "symbol": "Whistle",
  "profileUrl": "https://www.myneta.info/...",
  "source": "myneta",
  "lastUpdated": "2026-04-04T09:00:00.000Z"
}
```

## Notes

- Myneta pages have minor HTML differences per election year; scraper selectors are defensive.
- If a constituency URL fails parsing, run manual scrape and check that page-specific selector.
- For production, put this service behind a reverse proxy and add rate limits.


