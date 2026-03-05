import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:the_swing_dad/data/datasources/deriv_websocket_services.dart';
import 'package:the_swing_dad/presentation/controllers/auth_controller.dart';
import 'package:the_swing_dad/presentation/controllers/report_controller.dart';
import 'package:the_swing_dad/presentation/controllers/settings_controller.dart';
import 'package:the_swing_dad/presentation/controllers/trading_controller.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  _initDependencies();
  runApp(const SpemetraMasterTrader());
}

void _initDependencies() {
  Get.put(DerivWebSocketService(), permanent: true);
  Get.put(AuthController(), permanent: true);
  Get.put(SettingsController(), permanent: true);
  Get.put(TradingController(), permanent: true);
  Get.put(ReportController(), permanent: true);
}

class SpemetraMasterTrader extends StatelessWidget {
  const SpemetraMasterTrader({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Spemetra Master Trader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
