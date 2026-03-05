import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_routes.dart';

class AuthController extends GetxController {
  final _box = GetStorage();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  bool get isOnboardingDone =>
      _box.read(AppConstants.onboardingDoneKey) ?? false;

  void completeOnboarding() {
    _box.write(AppConstants.onboardingDoneKey, true);
    Get.offNamed(AppRoutes.home);
  }

  Future<void> signIn(String username, String password) async {
    if (username.trim().isEmpty || password.trim().isEmpty) {
      errorMessage.value = 'Please enter your credentials.';
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate auth

    if (username.trim() == AppConstants.adminUsername &&
        password.trim() == AppConstants.adminPassword) {
      isLoading.value = false;
      Get.offNamed(AppRoutes.marketSelection);
    } else {
      isLoading.value = false;
      errorMessage.value = 'Invalid credentials. Contact your admin.';
    }
  }

  void signOut() {
    Get.offAllNamed(AppRoutes.signIn);
  }
}
