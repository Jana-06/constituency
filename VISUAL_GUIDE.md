# 🗺️ ConstituencyConnect - Visual Navigation Map

## User Journey Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                       SPLASH SCREEN                              │
│                    (2.5s fade + scale)                           │
│                  Firebase Auth Check                             │
└─────────────┬───────────────────────────────┬────────────────────┘
              │                               │
         ┌────v─────────┐            ┌────────v──────┐
         │  Authenticated│            │Not Authenticated
         └────┬─────────┘            └────────┬──────┘
              │                               │
         ┌────v──────────────────────────────v──────┐
         │        SIGN IN SCREEN (if not auth)      │
         │  ┌─ Email/Password Login                 │
         │  ├─ Google Sign-In Button                │
         │  └─ Link to Sign Up                      │
         └─────────────┬────────────────────────────┘
                       │
         ┌─────────────v──────────────────┐
         │    MAIN SCAFFOLD (Tab Bar)     │
         │ ┌──────────────────────────┐   │
         │ │ Tab 0  Tab 1 Tab 2 Tab 3 │   │ ← 4 Tabs (bottom nav)
         │ └──────────────────────────┘   │
         │                                 │
         │ ┌─ Tab 0: Constituencies ──┐   │
         │ │  ConstituencySearchScreen │   │
         │ │  - District quick-select  │   │
         │ │  - Constituency search    │   │
         │ │  - Party shortcuts        │   │
         │ └──────────────────────────┘   │
         │                                 │
         │ ┌─ Tab 1: News ────────────┐   │
         │ │  NewsScreen              │   │
         │ │  - Article list          │   │
         │ │  - Category filter       │   │
         │ └──────────────────────────┘   │
         │                                 │
         │ ┌─ Tab 2: Polls ────────────┐  │
         │ │  PollsScreen             │   │
         │ │  - Opinion questions     │   │
         │ │  - Vote submission       │   │
         │ │  - Result charts         │   │
         │ └──────────────────────────┘   │
         │                                 │
         │ ┌─ Tab 3: Profile ─────────┐   │
         │ │  ProfileScreen           │   │
         │ │  - User info             │   │
         │ │  - Edit profile          │   │
         │ │  - Sign out              │   │
         │ └──────────────────────────┘   │
         └─────────────┬──────────────────┘
                       │
      ┌────────────────v────────────────┐
      │ Tab 0: Constituency Search      │
      │ ┌──────────────────────────────┐│
      │ │ • Select District (38 chips) ││
      │ │ • Search Constituency (234)  ││
      │ │ • Popular constituencies    ││
      │ │ • Party shortcuts carousel  ││
      │ └──────────────────────────────┘│
      └────────────────┬────────────────┘
                       │ (Tap constituency)
      ┌────────────────v───────────────────┐
      │ CandidateListScreen               │
      │ ┌───────────────────────────────┐ │
      │ │ Candidate Cards (from web):   │ │
      │ │ • Photo                        │ │
      │ │ • Name & Party                │ │
      │ │ • Police case summary         │ │
      │ │ • "View profile" button       │ │
      │ └───────────────────────────────┘ │
      │ ┌───────────────────────────────┐ │
      │ │ Constituency Message Board:   │ │
      │ │ • Real-time chat bubbles      │ │
      │ │ • Send message input          │ │
      │ │ • Firestore realtime sync     │ │
      │ └───────────────────────────────┘ │
      └────────────────┬───────────────────┘
                       │ (Tap candidate card)
      ┌────────────────v───────────────────┐
      │ CandidateDetailScreen              │
      │ ┌───────────────────────────────┐  │
      │ │ • Candidate photo (large)     │  │
      │ │ • Party badge                 │  │
      │ │ • Constituency & district     │  │
      │ │                               │  │
      │ │ POLICE CASES                  │  │
      │ │ └─ Auto-fetched summary       │  │
      │ │                               │  │
      │ │ GOOD THINGS                   │  │
      │ │ └─ Positive highlights        │  │
      │ │                               │  │
      │ │ AFFIDAVIT SUMMARY             │  │
      │ │ └─ Public source snapshot     │  │
      │ │                               │  │
      │ │ [Open Profile Button]         │  │
      │ │ ↓                             │  │
      │ │ InAppWebViewScreen            │  │
      │ │ (Source URL in WebView)       │  │
      │ └───────────────────────────────┘  │
      └────────────────────────────────────┘
```

---

## State Management Flow

```
┌────────────────────────────────────────────────────────┐
│ Riverpod Providers (lib/features/candidates/providers)│
└─────────────┬───────────────────────────────────────┬─┘
              │                                       │
      ┌───────v──────────┐              ┌────────────v────────┐
      │candidateRepository │             │ candidatesProvider   │
      │Provider           │             │ (FutureProvider)     │
      │                   │             │                      │
      │ ┌─────────────┐   │             │ Input:               │
      │ │ Searches    │   │             │  CandidateSearchParams
      │ │ web for     │   │             │  - district          │
      │ │ candidates  │   │             │  - constituency      │
      │ │ (Google API)│   │             │  - partyId (optional)
      │ │             │   │             │                      │
      │ │ Returns     │   │             │ Output:              │
      │ │ List<       │   │             │ List<CandidateProfile>
      │ │  Candidate  │   │             │                      │
      │ │  Profile>   │   │             │ Used by:             │
      │ │             │   │             │ • CandidateListScreen
      │ └─────────────┘   │             └──────────────────────┘
      └─────────────────┘
```

---

## Firestore Data Structure

```
Firebase Firestore
├── /users/{uid}
│   ├── uid: string
│   ├── name: string
│   ├── email: string
│   ├── role: "user" | "admin"
│   ├── photoUrl: string
│   ├── homeDistrict: string (optional)
│   ├── homeConstituency: string (optional)
│   ├── isBanned: boolean
│   ├── votedPollIds: [string]
│   └── createdAt: Timestamp
│
├── /messages/{districtId_constituencyId}/items/{docId}
│   ├── uid: string
│   ├── userName: string
│   ├── text: string
│   ├── timestamp: Timestamp
│   ├── isDeleted: boolean
│   ├── district: string
│   └── constituency: string
│
├── /polls/{pollId}
│   ├── question: string
│   ├── options: [string]
│   ├── votes: {optionIndex: count}
│   ├── createdAt: Timestamp
│   ├── expiresAt: Timestamp (optional)
│   └── constituency: "all" | "constituency_name"
│
└── /parties/{partyId}
    └── flagUrl: string
```

---

## Component Hierarchy

```
MyApp (Material 3 Theme)
├── MainScaffold
│   ├── IndexedStack (preserves state)
│   │   ├── [0] ConstituencySearchScreen ← NEW
│   │   ├── [1] NewsScreen
│   │   ├── [2] PollsScreen
│   │   └── [3] ProfileScreen
│   └── NavigationBar (4 destinations)
│       ├── Constituencies
│       ├── News
│       ├── Polls
│       └── Profile
│
├── [Routes]
│   ├── SplashScreen
│   ├── SignInScreen
│   ├── SignUpScreen
│   ├── CandidateListScreen (child of MainScaffold or standalone)
│   ├── CandidateDetailScreen
│   ├── PartyDetailScreen (legacy)
│   └── InAppWebViewScreen
│
└── [Theme]
    ├── ColorScheme (saffron seed)
    ├── TextTheme (Inter + Noto Sans Tamil)
    ├── CardTheme (14px radius, 1px border)
    ├── InputDecorationTheme
    └── NavigationBarTheme
```

---

## Color Palette (Production)

```
┌──────────────────────────────────────────────────┐
│ Light Theme                                      │
├──────────────────────────────────────────────────┤
│ Primary (Seed):     #FF6B35 (Saffron)           │
│ Saffron Accent:     #FF8C42 (warm orange)       │
│ Green (secondary):  #1C8C5E (civic green)       │
│                                                  │
│ Text (primary):     #111111 (true black)        │
│ Text (secondary):   #333333 (dark gray)         │
│ Text (tertiary):    #666666 (medium gray)       │
│                                                  │
│ Scaffold BG:        #FFFCF8 (warm off-white)   │
│ Card BG:            #FFFFFF (pure white)        │
│ Input BG:           #FDF8F3 (light cream)       │
│ Surface hover:      #F7F2EC (subtle)            │
│                                                  │
│ Border:             #E8E1D9 (warm gray)        │
│ Error:              #B3261E (red)               │
│ Success:            #2E7D32 (green)             │
│ Warning:            #F57C00 (orange)            │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│ Dark Theme (system-aware)                        │
├──────────────────────────────────────────────────┤
│ Primary:            #FF8C42 (bright saffron)    │
│ Surface:            #1C1C1C (dark)              │
│ Text (primary):     #FFFFFF (white)             │
│ Text (secondary):   #BDBDBD (light gray)        │
│ Border:             #424242 (dark gray)         │
│ All other colors auto-adjust via ColorScheme   │
└──────────────────────────────────────────────────┘
```

---

## Navigation Routing

```
GoRouter Routes Map:

Root Path: /
├── /splash → SplashScreen (no auth required)
├── /sign-in → SignInScreen (redirect if unauthenticated)
├── /sign-up → SignUpScreen (redirect if unauthenticated)
│
├── /parties → MainScaffold(Tab 0) [HOME]
├── /news → MainScaffold(Tab 1)
├── /polls → MainScaffold(Tab 2)
├── /profile → MainScaffold(Tab 3)
│
├── /candidates → CandidateListScreen
│   Parameters:
│   ├── district: string (required)
│   ├── constituency: string (required)
│   └── partyId?: string (optional, filters by party)
│
├── /candidate/detail → CandidateDetailScreen
│   Parameters:
│   └── candidate: CandidateProfile object (passed as extra)
│
├── /party/detail/:partyId → PartyDetailScreen (legacy)
├── /party/nominees → CandidateListScreen (redirects)
│   Parameters:
│   ├── partyId: string
│   ├── district: string
│   └── constituency: string
│
└── /webview → InAppWebViewScreen
    Parameters:
    ├── url: string (article/profile URL)
    └── title: string (page title)

Auth Redirect Logic:
- If !authenticated → /sign-in
- If authenticated && on auth route → /parties (home)
- If authenticated && on /splash → redirect complete
```

---

## API Integration Points

```
External Services Integration:

1. Google Custom Search API
   ├── Called by: CandidateRepository.searchCandidates()
   ├── Input: party name, constituency name
   ├── Output: 5 candidate results with thumbnails
   ├── Fallback: Static placeholder candidates
   └── Env var: CUSTOM_SEARCH_API_KEY, CUSTOM_SEARCH_ENGINE_ID

2. NewsAPI.org
   ├── Called by: NewsService.fetchNews()
   ├── Query: "Tamil Nadu government OR India government politics"
   ├── Output: 20 latest articles
   ├── Fallback: Placeholder news cards
   └── Env var: NEWS_API_KEY

3. Firebase Auth
   ├── Methods: Google Sign-In, Email/Password
   ├── User creation on first sign-in
   ├── Offline-aware session management
   └── Error handling: SHA-1/SHA-256, API quota

4. Cloud Firestore
   ├── Real-time message board sync
   ├── User profile CRUD
   ├── Poll vote aggregation
   ├── Offline persistence enabled
   └── Security rules: User-scoped read/write

5. Firebase Storage
   ├── User profile photo uploads
   ├── Party flag image caching
   └── CDN delivery via Cache-Control headers

6. Firebase Analytics
   ├── Event: "screen_view" (all tabs)
   ├── Event: "message_sent" (with params)
   ├── Event: "vote_cast" (with params)
   ├── Event: "party_tapped"
   └── Auto-collection: crashes, sessions
```

---

## Build & Deployment

```
Development → Testing → Production

1. Local Development
   flutter run -v --debug

2. Emulator Testing (Pixel 6)
   flutter run --emulator pixel_6 --debug

3. Build Debug APK
   flutter build apk --debug
   └── Output: build/app/outputs/apk/debug/app-debug.apk

4. Build Release APK
   flutter build apk --release
   └── Output: build/app/outputs/apk/release/app-release.apk

5. Deploy to Play Store
   flutter build appbundle --release
   └── Upload to Google Play Console

6. Monitor Analytics
   Firebase Console → Analytics
   └── Track: screen views, events, user retention

File Structure for Distribution:
├── lib/ (Dart source)
├── android/ (Native Android)
├── assets/ (Images, fonts)
├── pubspec.yaml (Dependencies)
├── .env (Secrets - NOT in git)
├── google-services.json (Firebase - .gitignore)
└── README.md (Documentation)
```

---

**This visual map is your complete guide to ConstituencyConnect's architecture and user flows.**

Last Updated: April 1, 2026
Version: 1.0.0-production

