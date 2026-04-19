# ConstituencyConnect - Civic Engagement Platform for Tamil Nadu

## 🎯 New User Flow (April 2026 Release)

The app now follows a **Constituency-First** model, replacing the old party-centric navigation:

### Authentication
1. **Splash Screen** → Auto-navigation based on auth state (2.5s fade+scale animation)
2. **Sign In** → Email/password or Google Sign-In (with improved error handling)
3. **Sign Up** → Full name, email, password with terms acceptance

### Main Navigation (Post-Auth)
After login, users land on the main app with 4 tabs:

#### **Tab 0: Constituencies** (was "Parties")
**Search & Compare Candidates**
- District selection with chip-based quick filter
- Full-text search across 234 TN constituencies
- Popular constituencies widget with quick access
- Party shortcuts carousel showing all 12 TN political parties

**Candidate List Screen** → Once a constituency is selected:
- Real-time candidate data fetched from web (Google Custom Search API)
- Cards show: photo, name, party, constituency badge, police case summary
- Tap to view full candidate profile

**Candidate Detail Screen**:
- Full candidate photo with hero animation
- Party chips, district, constituency, leader name
- **Police Cases** - automated summary from search results
- **Good Things** - positive highlights derived from candidate's party profile
- **Affidavit Summary** - fetched from live search snapshot
- "Open profile" button → In-app WebView to the original source

**Constituency Message Board** (per constituency):
- Real-time chat scoped to a specific district_constituency
- Chat bubbles (saffron for current user, gray for others)
- Soft-delete for moderators
- Firestore realtime sync

#### **Tab 1: News** (unchanged)
- Tamil Nadu government & politics news from NewsAPI.org
- Category filter: All, Politics, Economy, Infrastructure, Health
- Pull-to-refresh
- In-app WebView for articles

#### **Tab 2: Polls** (enhanced)
- Statewide & constituency-scoped opinion polls
- Radio button selection with animated vote submission
- Live bar charts showing vote distribution
- One vote per user per poll (locked after voting)
- Total votes badge

#### **Tab 3: Profile**
- User avatar (Google photo or uploaded)
- Edit profile: name, photo, home constituency
- My messages: 10 recent constituency messages with delete option
- Sign out button (with confirmation)
- App version info

---

## 🏗️ Architecture

### Folder Structure
```
lib/
├── core/
│   ├── theme.dart                    # Material 3 with saffron/green, black text
│   ├── router.dart                   # Go Router with all 6 routes
│   ├── constants/
│   │   └── app_constants.dart
│   └── firebase/
│       └── firebase_providers.dart
├── features/
│   ├── auth/                         # Sign In, Sign Up, Splash
│   │   ├── data/
│   │   │   └── auth_service.dart    # Firebase Auth + user doc creation
│   │   ├── providers/
│   │   │   └── auth_provider.dart
│   │   └── ui/screens/
│   │       ├── splash_screen.dart
│   │       ├── sign_in_screen.dart
│   │       └── sign_up_screen.dart
│   ├── candidates/                   # NEW: Main flow
│   │   ├── data/
│   │   │   └── candidate_repository.dart  # Web search + party metadata
│   │   ├── models/
│   │   │   └── candidate_profile.dart    # CandidateProfile class
│   │   ├── providers/
│   │   │   └── candidate_providers.dart  # candidatesProvider
│   │   └── ui/screens/
│   │       ├── constituency_search_screen.dart # Home screen
│   │       ├── candidate_list_screen.dart      # List + message board
│   │       └── candidate_detail_screen.dart    # Full profile
│   ├── parties/                      # Party list & detail (secondary routes)
│   ├── news/                         # News feed
│   ├── polls/                        # Citizen polls
│   ├── profile/                      # User profile
│   ├── admin/                        # Admin dashboard (gated)
│   └── shared/
│       ├── ui/
│       │   ├── main_scaffold.dart    # Updated: Tab 0 = ConstituencySearchScreen
│       │   └── in_app_webview_screen.dart
│       └── widgets/
│           ├── shimmer_box.dart
│           ├── empty_state_illustration.dart
│           ├── app_snackbar.dart
│           └── ...
├── shared/
│   ├── models/
│   │   ├── poll.dart
│   │   ├── news_article.dart
│   │   ├── party.dart
│   │   └── app_user.dart
│   └── widgets/
│       └── ...
├── main.dart                         # Updated: Offline persistence enabled
└── firebase_options.dart
```

---

## 🎨 Design System (Polished Production Quality)

### Colors
- **Seed**: `#FF6B35` (Saffron-Orange)
- **Saffron**: `#FF8C42` (Accent)
- **Green**: `#1C8C5E` (Secondary)
- **Text**: Black (`#111111`) on light backgrounds
- **Scaffold BG**: `#FFFCF8` (Warm off-white)
- **Card BG**: White with subtle border
- **Input BG**: `#FDF8F3` (Light cream)

### Typography
- **Heading**: Inter 800 (bold, black)
- **Body**: Inter 400-600 (clean, high contrast)
- **Fallback Tamil**: Noto Sans Tamil

### Shapes
- **Cards**: 14px borderRadius, 0px elevation, 1px border
- **Buttons**: 10px borderRadius
- **Chips**: 10px borderRadius
- **Input**: 12px borderRadius, 14px padding

### Animations
- Splash: 2.5s fade+scale
- Page transitions: SlideUp + FadeIn (300ms)
- Vote bars: TweenAnimationBuilder (350ms)

---

## 🔗 Routes

```dart
/splash                    → SplashScreen
/sign-in                   → SignInScreen
/sign-up                   → SignUpScreen
/parties                   → MainScaffold(Tab 0: ConstituencySearchScreen)
/news                      → MainScaffold(Tab 1: NewsScreen)
/polls                     → MainScaffold(Tab 2: PollsScreen)
/profile                   → MainScaffold(Tab 3: ProfileScreen)
/candidates                → CandidateListScreen (district, constituency, partyId?)
/party/detail/:partyId     → PartyDetailScreen (legacy route, still available)
/party/nominees            → CandidateListScreen (redirects here from party detail)
/candidate/detail          → CandidateDetailScreen (extra: CandidateProfile object)
/webview                   → InAppWebViewScreen (extra: url, title)
```

---

## 🔐 Firebase Setup

### Collections

#### `/users/{uid}`
```json
{
  "uid": "string",
  "name": "string",
  "email": "string",
  "role": "user" | "admin",
  "photoUrl": "string (optional)",
  "homeDistrict": "string (optional)",
  "homeConstituency": "string (optional)",
  "isBanned": false,
  "votedPollIds": ["string"],
  "createdAt": Timestamp
}
```

#### `/messages/{districtId_constituencyId}/items/{docId}`
```json
{
  "uid": "string",
  "userName": "string",
  "text": "string",
  "timestamp": Timestamp,
  "isDeleted": false,
  "district": "string",
  "constituency": "string"
}
```

#### `/polls/{pollId}`
```json
{
  "question": "string",
  "options": ["A", "B", "C", "D"],
  "votes": {"0": 100, "1": 75, ...},
  "createdAt": Timestamp,
  "expiresAt": Timestamp (optional),
  "constituency": "all" | "constituency_name"
}
```

#### `/parties/{partyId}`
```json
{
  "flagUrl": "https://firestore-url"
}
```

---

## 📦 Dependencies (Key)

- **firebase_core**, **firebase_auth**, **cloud_firestore**, **firebase_storage**, **firebase_analytics**
- **flutter_riverpod** (state management)
- **go_router** (navigation)
- **google_sign_in** (auth)
- **cached_network_image** (image loading)
- **dio** (HTTP API calls)
- **webview_flutter** (in-app web views)
- **flutter_dotenv** (env vars)
- **shimmer**, **animations**, **animate_do** (UX polish)
- **connectivity_plus** (offline detection)
- **google_fonts** (typography)
- **intl**, **timeago** (i18n & time formatting)

---

## 🚀 Getting Started

### 1. Environment Setup
```bash
flutter pub get
```

### 2. Firebase Configuration
- Ensure `google-services.json` is in `android/app/`
- Add SHA-1 and SHA-256 fingerprints in Firebase Console for Google Sign-In
- Enable Authentication (Google + Email/Password)
- Enable Cloud Firestore
- Enable Firebase Storage
- Enable Firebase Analytics

### 3. Environment Variables (`.env`)
```
NEWS_API_KEY=your_newsapi_key
CUSTOM_SEARCH_API_KEY=your_google_custom_search_key
CUSTOM_SEARCH_ENGINE_ID=your_search_engine_id
```

### 4. Run
```bash
flutter run -v
# or
flutter run --release
```

---

## ✨ Highlights (Production Quality)

✅ **Material 3 Design** with saffron/green Indian civic theme  
✅ **Polished UI** — black text, warm surfaces, consistent 14px cards  
✅ **Real-time Messaging** — Firestore StreamBuilder per constituency  
✅ **Web Search Integration** — Google Custom Search API for candidates  
✅ **Offline Support** — Firestore persistence enabled  
✅ **Error Handling** — Graceful fallbacks, improved Google Sign-In messages  
✅ **Analytics** — Firebase Analytics on key actions  
✅ **Animations** — Smooth transitions, shimmer loaders, animated charts  
✅ **Responsive** — Tested on Pixel 6+ (Android) emulator  

---

## 🐛 Known Limitations & Future Work

- **Candidate affidavit data** is auto-generated from search results; real affidavit DB integration pending
- **Police cases & good things** are seeded based on party/candidate profiles; live scraping not yet enabled
- **Admin dashboard** is structured but not fully wired in this release
- **Poll analytics** show basic bar charts; more advanced visualizations pending
- **Tamil language support** — UI framework ready, content localization pending

---

## 📝 Development Notes

### Adding a New Route
1. Create screen in `lib/features/{feature}/ui/screens/`
2. Add `GoRoute` in `lib/core/router.dart`
3. Update navigation reference in relevant screens

### Adding a New Feature
1. Create folder under `lib/features/{feature_name}/`
2. Follow structure: `data/`, `models/`, `providers/`, `ui/screens/`
3. Implement repository, provider, then UI

### Theming
- All colors in `lib/core/theme.dart`
- Override via `copyWith()` on `AppTheme.light()` or `.dark()`
- Text colors default to black on light theme

---

## 📞 Support & Contact

Built with ❤️ for Tamil Nadu civic engagement.  
Questions? Check Firebase logs and Dart analysis output: `flutter analyze`

**Last Updated**: April 1, 2026  
**Version**: 1.0.0-production

