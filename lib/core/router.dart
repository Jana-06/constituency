import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/ui/screens/sign_in_screen.dart';
import '../features/auth/ui/screens/sign_up_screen.dart';
import '../features/auth/ui/screens/splash_screen.dart';
import '../features/parties/ui/party_detail_screen.dart';
import '../features/candidates/ui/screens/candidate_detail_screen.dart';
import '../features/candidates/ui/screens/candidate_list_screen.dart';
import '../features/shared/ui/main_scaffold.dart';
import '../shared/widgets/in_app_webview_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final path = state.matchedLocation;
      final isAuthRoute = path == '/sign-in' || path == '/sign-up';

      if (authState.isLoading) {
        return path == '/splash' ? null : '/splash';
      }

      if (authState.hasError) {
        return isAuthRoute ? null : '/sign-in';
      }

      final isAuthenticated = authState.value != null;

      if (!isAuthenticated) {
        return isAuthRoute ? null : '/sign-in';
      }

      if (path == '/splash' || isAuthRoute || path == '/') {
        return '/parties';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/parties'),
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/sign-in', builder: (context, state) => const SignInScreen()),
      GoRoute(path: '/sign-up', builder: (context, state) => const SignUpScreen()),
      GoRoute(path: '/parties', builder: (context, state) => const MainScaffold(initialRoute: '/parties')),
      GoRoute(path: '/news', builder: (context, state) => const MainScaffold(initialRoute: '/news')),
      GoRoute(path: '/polls', builder: (context, state) => const MainScaffold(initialRoute: '/polls')),
      GoRoute(path: '/profile', builder: (context, state) => const MainScaffold(initialRoute: '/profile')),
      GoRoute(
        path: '/candidates',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CandidateListScreen(
            district: extra['district'] as String,
            constituency: extra['constituency'] as String,
            partyId: extra['partyId'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/party/detail/:partyId',
        builder: (context, state) => PartyDetailScreen(partyId: state.pathParameters['partyId']!),
      ),
      GoRoute(
        path: '/party/nominees',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CandidateListScreen(
            partyId: extra['partyId'] as String?,
            district: extra['district'] as String,
            constituency: extra['constituency'] as String,
          );
        },
      ),
      GoRoute(
        path: '/candidate/detail',
        builder: (context, state) => CandidateDetailScreen(candidate: state.extra as dynamic),
      ),
      GoRoute(
        path: '/webview',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return InAppWebViewScreen(
            url: extra['url'] as String,
            title: (extra['title'] as String?) ?? 'Article',
          );
        },
      ),
    ],
  );
});

