import * as admin from "firebase-admin";
import axios from "axios";
import * as cheerio from "cheerio";
import {setGlobalOptions} from "firebase-functions";
import {onRequest} from "firebase-functions/https";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
setGlobalOptions({ maxInstances: 10 });

// Initialize Firebase Admin SDK
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const CANDIDATES_COLLECTION = "candidates";
const CANDIDATE_SYNC_STATUS_COLLECTION = "candidate_sync_status";
const STALE_MINUTES = 180;

type ScrapedCandidate = {
  name: string;
  partyName: string;
  partyId: string;
  partyAbbreviation: string;
  partyFlagUrl?: string;
  symbol?: string;
  sourceUrl: string;
  affidavitUrl?: string;
  goodThingsUrl?: string;
};

const partyAliasMap: Record<string, {id: string; name: string}> = {
  dmk: {id: "dmk", name: "Dravida Munnetra Kazhagam"},
  "dravida munnetra kazhagam": {id: "dmk", name: "Dravida Munnetra Kazhagam"},
  aiadmk: {id: "aiadmk", name: "All India Anna Dravida Munnetra Kazhagam"},
  "all india anna dravida munnetra kazhagam": {id: "aiadmk", name: "All India Anna Dravida Munnetra Kazhagam"},
  admk: {id: "aiadmk", name: "All India Anna Dravida Munnetra Kazhagam"},
  bjp: {id: "bjp", name: "Bharatiya Janata Party"},
  "bharatiya janata party": {id: "bjp", name: "Bharatiya Janata Party"},
  inc: {id: "inc", name: "Indian National Congress"},
  congress: {id: "inc", name: "Indian National Congress"},
  tvk: {id: "tvk", name: "Tamilaga Vettri Kazhagam"},
  ntk: {id: "ntk", name: "Naam Tamilar Katchi"},
  dmdk: {id: "dmdk", name: "Desiya Murpokku Dravida Kazhagam"},
  "desiya murpokku dravida kazhagam": {id: "dmdk", name: "Desiya Murpokku Dravida Kazhagam"},
  pmk: {id: "pmk", name: "Pattali Makkal Katchi"},
  "pattali makkal katchi": {id: "pmk", name: "Pattali Makkal Katchi"},
  vck: {id: "vck", name: "Viduthalai Chiruthaigal Katchi"},
  "viduthalai chiruthaigal katchi": {id: "vck", name: "Viduthalai Chiruthaigal Katchi"},
  mnm: {id: "mnm", name: "Makkal Needhi Maiam"},
  "makkal needhi maiam": {id: "mnm", name: "Makkal Needhi Maiam"},
  mdmk: {id: "mdmk", name: "Marumalarchi Dravida Munnetra Kazhagam"},
  "marumalarchi dravida munnetra kazhagam": {id: "mdmk", name: "Marumalarchi Dravida Munnetra Kazhagam"},
};

const partyAbbreviationMap: Record<string, string> = {
  dmk: "DMK",
  aiadmk: "AIADMK",
  bjp: "BJP",
  inc: "INC",
  tvk: "TVK",
  ntk: "NTK",
  dmdk: "DMDK",
  pmk: "PMK",
  vck: "VCK",
  mnm: "MNM",
  mdmk: "MDMK",
  ind: "IND",
};

function normalizeKey(value: string): string {
  return value.toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(/^_+|_+$/g, "");
}

function extractParty(text: string): {id: string; name: string} {
  const lower = text.toLowerCase();
  const explicit = lower.match(/party\s*:?\s*([a-z .&()\-]{2,80})/i);
  const raw = (explicit?.[1] ?? "").trim().toLowerCase();
  if (raw && partyAliasMap[raw]) {
    return partyAliasMap[raw];
  }

  for (const [alias, mapped] of Object.entries(partyAliasMap)) {
    if (lower.includes(alias)) {
      return mapped;
    }
  }

  return {id: "ind", name: "Independent"};
}

function toAbbreviation(partyId: string): string {
  return partyAbbreviationMap[partyId] ?? partyId.toUpperCase();
}

function extractSymbol(text: string): string | undefined {
  const symbol = text.match(/symbol\s*:?\s*([a-z0-9 .&()\-]{2,60})/i)?.[1]?.trim();
  return symbol && symbol.length > 1 ? symbol : undefined;
}

function absoluteMynetaUrl(pathOrUrl: string): string {
  if (pathOrUrl.startsWith("http://") || pathOrUrl.startsWith("https://")) {
    return pathOrUrl;
  }
  return `https://www.myneta.info/${pathOrUrl.replace(/^\/+/, "")}`;
}

function validName(value: string): boolean {
  if (value.length < 3 || value.length > 100) {
    return false;
  }
  const lower = value.toLowerCase();
  if (lower.includes("myneta") || lower.includes("search")) {
    return false;
  }
  return /[a-z]/i.test(value);
}

function normalizeForMatch(value: string): string {
  return value.toLowerCase().replace(/[^a-z0-9]/g, "");
}

function constituencyMatches(expected: string, actual: string): boolean {
  const a = normalizeForMatch(expected);
  const b = normalizeForMatch(actual);
  return a.length > 0 && b.length > 0 && (a.includes(b) || b.includes(a));
}

function extractFieldByLabel(pageText: string, label: string): string {
  const regex = new RegExp(`${label}\\s*:?\\s*([^|\\n\\r]{2,160})`, "i");
  const value = pageText.match(regex)?.[1]?.trim() ?? "";
  return value.replace(/\s+/g, " ");
}

async function parseCandidatePage(url: string, expectedConstituency: string): Promise<ScrapedCandidate | null> {
  const response = await axios.get<string>(url, {
    timeout: 25000,
    headers: {
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
      "Accept-Language": "en-IN,en;q=0.9",
    },
  });

  const $ = cheerio.load(response.data);
  const pageText = $.text().replace(/\s+/g, " ").trim();

  const constituency =
    extractFieldByLabel(pageText, "Constituency") ||
    extractFieldByLabel(pageText, "Constituency Name") ||
    extractFieldByLabel(pageText, "AC Name");

  if (!constituency || !constituencyMatches(expectedConstituency, constituency)) {
    return null;
  }

  const heading = $("h2, h3, h1").first().text().replace(/\s+/g, " ").trim();
  const nameFromHeading = heading.split("(")[0]?.trim() ?? "";
  const name = validName(nameFromHeading) ? nameFromHeading : extractFieldByLabel(pageText, "Name");
  if (!validName(name)) {
    return null;
  }

  const partyRaw =
    extractFieldByLabel(pageText, "Party") ||
    extractFieldByLabel(pageText, "Party Name") ||
    extractFieldByLabel(pageText, "Political Party");
  const party = extractParty(partyRaw.length > 0 ? partyRaw : pageText);
  const symbol = extractFieldByLabel(pageText, "Symbol Name") || extractSymbol(pageText) || "";

  return {
    name,
    partyName: party.name,
    partyId: party.id,
    partyAbbreviation: toAbbreviation(party.id),
    symbol: symbol.length > 0 ? symbol : undefined,
    sourceUrl: url,
  };
}

async function loadPartyFlagMap(db: admin.firestore.Firestore): Promise<Record<string, string>> {
  const snapshot = await db.collection("parties").get();
  const map: Record<string, string> = {};
  for (const doc of snapshot.docs) {
    const data = doc.data();
    const url = data["flagUrl"];
    if (typeof url === "string" && url.trim().length > 0) {
      map[doc.id.toLowerCase()] = url.trim();
    }
  }
  return map;
}

function buildMynetaSearchUrl(constituency: string): string {
  const q = constituency.trim().toLowerCase();
  return `https://www.myneta.info/search_myneta.php?q=${encodeURIComponent(q)}`;
}

async function scrapeMynetaCandidates(constituency: string): Promise<ScrapedCandidate[]> {
  const url = buildMynetaSearchUrl(constituency);

  const response = await axios.get<string>(url, {
    timeout: 30000,
    headers: {
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
      "Accept-Language": "en-IN,en;q=0.9",
    },
  });

  const $ = cheerio.load(response.data);
  const candidateLinks: string[] = [];
  const dedupe = new Set<string>();

  $("a[href*='candidate.php'], a[href*='myneta.info']").each((_, element) => {
    const href = ($(element).attr("href") ?? "").trim();
    if (!href) {
      return;
    }
    const absolute = absoluteMynetaUrl(href);
    if (!candidateLinks.includes(absolute)) {
      candidateLinks.push(absolute);
    }
  });

  const candidates: ScrapedCandidate[] = [];
  logger.info("Myneta constituency search", {constituency, url});
  for (const link of candidateLinks.slice(0, 30)) {
    try {
      const parsed = await parseCandidatePage(link, constituency);
      if (parsed == null) {
        continue;
      }
      const key = `${normalizeKey(parsed.name)}_${parsed.partyId}`;
      if (dedupe.has(key)) {
        continue;
      }
      dedupe.add(key);
      candidates.push(parsed);
    } catch {
      // Skip failed candidate page parse and continue with other links.
    }
  }

  return candidates.slice(0, 40);
}

async function writeCandidateSnapshot(
  district: string,
  constituency: string,
  scraped: ScrapedCandidate[],
  partyFlags: Record<string, string>,
): Promise<number> {
  const db = admin.firestore();
  const constituencyKey = normalizeKey(`${district}_${constituency}`);
  const now = admin.firestore.FieldValue.serverTimestamp();

  const existing = await db.collection(CANDIDATES_COLLECTION)
    .where("constituencyKey", "==", constituencyKey)
    .get();

  const deleteBatch = db.batch();
  for (const doc of existing.docs) {
    deleteBatch.delete(doc.ref);
  }
  if (!existing.empty) {
    await deleteBatch.commit();
  }

  if (scraped.length === 0) {
    return 0;
  }

  const chunks: ScrapedCandidate[][] = [];
  for (let i = 0; i < scraped.length; i += 400) {
    chunks.push(scraped.slice(i, i + 400));
  }

  for (const chunk of chunks) {
    const batch = db.batch();
    for (const candidate of chunk) {
      const id = normalizeKey(`${constituencyKey}_${candidate.partyId}_${candidate.name}`);
      const ref = db.collection(CANDIDATES_COLLECTION).doc(id);
      batch.set(ref, {
        id,
        district,
        constituency,
        constituencyKey,
        name: candidate.name,
        partyName: candidate.partyName,
        partyId: candidate.partyId,
        partyAbbreviation: candidate.partyAbbreviation,
        partyFlagUrl: partyFlags[candidate.partyId] ?? null,
        symbol: candidate.symbol ?? null,
        photoUrl: null,
        sourceUrl: candidate.sourceUrl,
        affidavitUrl: candidate.affidavitUrl ?? candidate.sourceUrl,
        goodThingsUrl: candidate.goodThingsUrl ?? candidate.sourceUrl,
        source: "myneta",
        updatedAt: now,
      }, {merge: true});
    }
    await batch.commit();
  }

  return scraped.length;
}

export const syncCandidates = onCall({timeoutSeconds: 120, memory: "512MiB"}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const district = String(request.data?.district ?? "").trim();
  const constituency = String(request.data?.constituency ?? "").trim();
  const force = request.data?.force == true;

  if (!district || !constituency) {
    throw new HttpsError("invalid-argument", "district and constituency are required.");
  }

  const db = admin.firestore();
  const constituencyKey = normalizeKey(`${district}_${constituency}`);
  const statusRef = db.collection(CANDIDATE_SYNC_STATUS_COLLECTION).doc(constituencyKey);
  const statusSnap = await statusRef.get();

  if (!force && statusSnap.exists) {
    const data = statusSnap.data();
    const syncedAt = data?.["lastSyncedAt"] as admin.firestore.Timestamp | undefined;
    if (syncedAt) {
      const ageMinutes = (Date.now() - syncedAt.toMillis()) / 60000;
      if (ageMinutes < STALE_MINUTES) {
        return {
          synced: false,
          reason: "fresh_cache",
          lastSyncedAt: syncedAt.toDate().toISOString(),
        };
      }
    }
  }

  await statusRef.set({
    district,
    constituency,
    constituencyKey,
    status: "syncing",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});

  try {
    const candidates = await scrapeMynetaCandidates(constituency);
    const partyFlags = await loadPartyFlagMap(db);
    const count = await writeCandidateSnapshot(district, constituency, candidates, partyFlags);

    await statusRef.set({
      district,
      constituency,
      constituencyKey,
      status: "ready",
      usedFallback: false,
      candidateCount: count,
      lastSyncedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

    logger.info("Candidate sync complete", {district, constituency, count});
    return {
      synced: true,
      count,
      usedFallback: false,
    };
  } catch (error) {
    logger.error("Candidate sync failed", {district, constituency, error});
    await statusRef.set({
      district,
      constituency,
      constituencyKey,
      status: "failed",
      error: String(error),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
    throw new HttpsError("internal", "Could not sync candidates right now.");
  }
});

const tnDistrictConstituencies: Record<string, string[]> = {
  "Ariyalur": ["Ariyalur", "Jayankondam", "Kunnam", "Andimadam", "Sendurai", "Udayarpalayam"],
  "Chengalpattu": ["Chengalpattu", "Pallavaram", "Tambaram", "Thiruporur", "Cheyyur", "Madurantakam"],
  "Chennai": ["Kolathur", "Chepauk-Thiruvallikeni", "Thousand Lights", "T. Nagar", "Mylapore", "Velachery"],
  "Coimbatore": ["Coimbatore North", "Coimbatore South", "Singanallur", "Sulur", "Kavundampalayam", "Kinathukadavu"],
  "Cuddalore": ["Cuddalore", "Kurinjipadi", "Panruti", "Neyveli", "Bhuvanagiri", "Chidambaram"],
  "Dharmapuri": ["Dharmapuri", "Pennagaram", "Palacode", "Pappireddippatti", "Harur", "Morappur"],
  "Dindigul": ["Dindigul", "Nilakottai", "Athoor", "Natham", "Oddanchatram", "Palani"],
  "Erode": ["Erode East", "Erode West", "Gobichettipalayam", "Bhavani", "Perundurai", "Modakkurichi"],
  "Kallakurichi": ["Kallakurichi", "Rishivandiyam", "Sankarapuram", "Ulundurpet", "Gangavalli", "Attur"],
  "Kancheepuram": ["Kancheepuram", "Uthiramerur", "Sriperumbudur", "Kundrathur", "Maduravoyal", "Poonamallee"],
  "Kanyakumari": ["Nagercoil", "Colachel", "Kanniyakumari", "Padmanabhapuram", "Vilavancode", "Killiyoor"],
  "Karur": ["Karur", "Aravakurichi", "Krishnarayapuram", "Kulithalai", "Paramathi Velur", "Vedasandur"],
  "Krishnagiri": ["Krishnagiri", "Bargur", "Veppanahalli", "Uthangarai", "Hosur", "Thalli"],
  "Madurai": ["Madurai East", "Madurai West", "Madurai North", "Madurai South", "Thiruparankundram", "Melur"],
  "Mayiladuthurai": ["Mayiladuthurai", "Poompuhar", "Sirkazhi", "Kuthalam", "Nannilam", "Thiruvidaimarudur"],
  "Nagapattinam": ["Nagapattinam", "Kilvelur", "Vedaranyam", "Thiruthuraipoondi", "Mannargudi", "Thiruvarur"],
  "Namakkal": ["Namakkal", "Rasipuram", "Senthamangalam", "Paramathi Velur", "Tiruchengode", "Kumarapalayam"],
  "Nilgiris": ["Udhagamandalam", "Gudalur", "Coonoor", "Mettupalayam", "Avanashi", "Tiruppur North"],
  "Perambalur": ["Perambalur", "Veppanthattai", "Lalgudi", "Musiri", "Thuraiyur", "Manachanallur"],
  "Pudukkottai": ["Pudukkottai", "Aranthangi", "Thirumayam", "Alangudi", "Gandarvakottai", "Viralimalai"],
  "Ramanathapuram": ["Ramanathapuram", "Paramakudi", "Mudukulathur", "Tiruvadanai", "Manamadurai", "Sivaganga"],
  "Ranipet": ["Arakkonam", "Sholinghur", "Walajah", "Arcot", "Anaikattu", "Katpadi"],
  "Salem": ["Salem North", "Salem South", "Salem West", "Omalur", "Edappadi", "Mettur"],
  "Sivaganga": ["Sivaganga", "Karaikudi", "Tiruppattur", "Manamadurai", "Ilayangudi", "Thirumayam"],
  "Tenkasi": ["Tenkasi", "Alangulam", "Vasudevanallur", "Kadayanallur", "Sankarankovil", "Ambasamudram"],
  "Thanjavur": ["Thanjavur", "Orathanadu", "Pattukkottai", "Peravurani", "Kumbakonam", "Papanasam"],
  "Theni": ["Theni", "Periyakulam", "Bodinayakanur", "Cumbum", "Andipatti", "Usilampatti"],
  "Thoothukudi": ["Thoothukudi", "Tiruchendur", "Srivaikuntam", "Kovilpatti", "Ottapidaram", "Vilathikulam"],
  "Tiruchirappalli": ["Tiruchirappalli West", "Tiruchirappalli East", "Srirangam", "Thiruverumbur", "Lalgudi", "Manapparai"],
  "Tirunelveli": ["Tirunelveli", "Palayamkottai", "Nanguneri", "Radhapuram", "Ambasamudram", "Thisayanvilai"],
  "Tirupathur": ["Tirupattur", "Jolarpet", "Ambur", "Vaniyambadi", "Bargur", "Uthangarai"],
  "Tiruppur": ["Tiruppur North", "Tiruppur South", "Palladam", "Avanashi", "Dharapuram", "Kangeyam"],
  "Tiruvallur": ["Thiruvallur", "Ponneri", "Gummidipoondi", "Avadi", "Madavaram", "Tiruttani"],
  "Tiruvannamalai": ["Tiruvannamalai", "Arani", "Cheyyar", "Polur", "Kalasapakkam", "Chengam"],
  "Tiruvarur": ["Tiruvarur", "Mannargudi", "Nannilam", "Thiruthuraipoondi", "Needamangalam", "Valangaiman"],
  "Vellore": ["Vellore", "Katpadi", "Anaikattu", "Gudiyattam", "Kilvaithinankuppam", "Ambur"],
  "Viluppuram": ["Viluppuram", "Vikravandi", "Thiruvennainallur", "Vanur", "Mailam", "Tindivanam"],
  "Virudhunagar": ["Virudhunagar", "Sattur", "Aruppukkottai", "Sivakasi", "Rajapalayam", "Srivilliputhur"],
};

type MessageRoom = {
  district: string;
  constituency: string;
  roomId: string;
};

function toRoomId(district: string, constituency: string): string {
  return `${district}_${constituency}`.replace(/ /g, "_").toLowerCase();
}

function buildMessageRooms(): MessageRoom[] {
  const rooms: MessageRoom[] = [];
  for (const [district, constituencies] of Object.entries(tnDistrictConstituencies)) {
    for (const constituency of constituencies) {
      rooms.push({
        district,
        constituency,
        roomId: toRoomId(district, constituency),
      });
    }
  }
  return rooms;
}

export const seedMessagingConstituencies = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({error: "Use POST for seeding."});
    return;
  }

  const dryRun = req.query.dryRun === "true";
  const rooms = buildMessageRooms();

  if (dryRun) {
    res.status(200).json({
      totalRooms: rooms.length,
      sample: rooms.slice(0, 10),
    });
    return;
  }

  const db = admin.firestore();
  const chunks: MessageRoom[][] = [];
  for (let i = 0; i < rooms.length; i += 400) {
    chunks.push(rooms.slice(i, i + 400));
  }

  for (const chunk of chunks) {
    const batch = db.batch();
    for (const room of chunk) {
      const ref = db.collection("messages").doc(room.roomId);
      batch.set(
        ref,
        {
          district: room.district,
          constituency: room.constituency,
          roomId: room.roomId,
          state: "Tamil Nadu",
          active: true,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
    }
    await batch.commit();
  }

  logger.info("Seeded messaging constituencies", {count: rooms.length});
  res.status(200).json({seeded: rooms.length});
});
