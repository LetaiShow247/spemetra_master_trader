import 'package:get/get.dart';
import 'package:the_swing_dad/presentation/screens/auth/market_selection_screen.dart';
import 'package:the_swing_dad/presentation/screens/auth/sign_in_screen.dart';
import 'package:the_swing_dad/presentation/screens/home/home_screen.dart';
import 'package:the_swing_dad/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:the_swing_dad/presentation/screens/splash/splash_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const signIn = '/sign-in';
  static const marketSelection = '/market-selection';
  static const home = '/home';

  static final pages = [
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(name: onboarding, page: () => const OnboardingScreen()),
    GetPage(name: signIn, page: () => const SignInScreen()),
    GetPage(name: marketSelection, page: () => const MarketSelectionScreen()),
    GetPage(name: home, page: () => const HomeScreen()),
  ];
}
