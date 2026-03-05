class AppConstants {
  // Deriv WebSocket URL
  static const String derivWsUrl =
      'wss://ws.binaryws.com/websockets/v3?app_id=1089';

  // App
  static const String appName = 'DerivAI Trader';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String apiTokenKey = 'deriv_api_token';
  static const String stakeAmountKey = 'stake_amount';
  static const String dailyTargetKey = 'daily_target';
  static const String stopLossKey = 'stop_loss';
  static const String onboardingDoneKey = 'onboarding_done';
  static const String adminCredKey = 'admin_credentials';

  // Default Risk Parameters
  static const double defaultStake = 1.00;
  static const double defaultDailyTarget = 10.00;
  static const double defaultStopLoss = 5.00;

  // AI Parameters
  static const int patternLookback = 20;
  static const double highConfidenceThreshold = 0.75;
  static const double mediumConfidenceThreshold = 0.55;

  // Trading Intervals
  static const int analysisIntervalMs = 2000;
  static const int tickBufferSize = 100;
  static const int contractDuration = 1; // ticks

  // Admin Credentials (set by admin - changeable)
  static const String adminUsername = 'trader';
  static const String adminPassword = 'deriv2024';

  // Markets
  static const List<Map<String, String>> availableMarkets = [
    {'symbol': 'R_10', 'name': 'Volatility 10 Index', 'short': 'V10'},
    {'symbol': 'R_25', 'name': 'Volatility 25 Index', 'short': 'V25'},
    {'symbol': 'R_50', 'name': 'Volatility 50 Index', 'short': 'V50'},
    {'symbol': 'R_75', 'name': 'Volatility 75 Index', 'short': 'V75'},
    {'symbol': 'R_100', 'name': 'Volatility 100 Index', 'short': 'V100'},
    {
      'symbol': '1HZ10V',
      'name': 'Volatility 10 (1s) Index',
      'short': 'V10(1s)',
    },
    {
      'symbol': '1HZ25V',
      'name': 'Volatility 25 (1s) Index',
      'short': 'V25(1s)',
    },
    {
      'symbol': '1HZ50V',
      'name': 'Volatility 50 (1s) Index',
      'short': 'V50(1s)',
    },
    {
      'symbol': '1HZ75V',
      'name': 'Volatility 75 (1s) Index',
      'short': 'V75(1s)',
    },
    {
      'symbol': '1HZ100V',
      'name': 'Volatility 100 (1s) Index',
      'short': 'V100(1s)',
    },
  ];

  // Contract Types
  static const List<Map<String, String>> contractTypes = [
    {'type': 'DIGITODD', 'label': 'Odd', 'category': 'digit'},
    {'type': 'DIGITEVEN', 'label': 'Even', 'category': 'digit'},
    {'type': 'DIGITMATCH', 'label': 'Digit Match', 'category': 'digit'},
    {'type': 'DIGITDIFF', 'label': 'Digit Differs', 'category': 'digit'},
    {'type': 'DIGITUNDER', 'label': 'Under', 'category': 'digit'},
    {'type': 'DIGITOVER', 'label': 'Over', 'category': 'digit'},
  ];
}
