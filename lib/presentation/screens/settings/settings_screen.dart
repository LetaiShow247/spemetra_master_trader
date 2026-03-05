import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/trading_models.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/auth_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsController _settings = Get.find();
  final AuthController _auth = Get.find();

  late final TextEditingController _tokenCtrl;
  late final TextEditingController _stakeCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _lossCtrl;

  final _riskFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tokenCtrl = TextEditingController(text: _settings.apiToken.value);
    _stakeCtrl = TextEditingController(
      text: _settings.stakeAmount.value.toStringAsFixed(2),
    );
    _targetCtrl = TextEditingController(
      text: _settings.dailyTarget.value.toStringAsFixed(2),
    );
    _lossCtrl = TextEditingController(
      text: _settings.stopLoss.value.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _stakeCtrl.dispose();
    _targetCtrl.dispose();
    _lossCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── API Connection ───────────────────────────────────────────
            _SectionHeader('API CONNECTION', Icons.link_rounded),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Deriv API Token',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _tokenCtrl,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontFamily: 'monospace',
                    ),
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Paste your Deriv API token here...',
                      prefixIcon: Icon(
                        Icons.vpn_key_outlined,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Get your API token from app.deriv.com → Account Settings → API Token',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 16),

                  // Status
                  Obx(() {
                    final status = _settings.connectionStatus;
                    final isAuth = status == ConnectionStatus.authorized;
                    final color = isAuth
                        ? AppTheme.success
                        : status == ConnectionStatus.connecting
                        ? AppTheme.warning
                        : AppTheme.textMuted;
                    return Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _settings.authStatus.value.isNotEmpty
                              ? _settings.authStatus.value
                              : status.name.toUpperCase(),
                          style: TextStyle(color: color, fontSize: 13),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 16),

                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _settings.isAuthorizing.value
                            ? null
                            : () => _settings.authorizeAndConnect(
                                _tokenCtrl.text,
                              ),
                        icon: _settings.isAuthorizing.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.bgDark,
                                ),
                              )
                            : const Icon(Icons.lock_open_rounded),
                        label: Text(
                          _settings.isAuthorizing.value
                              ? 'Connecting...'
                              : 'AUTHORIZE & CONNECT',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── Risk Parameters ──────────────────────────────────────────
            _SectionHeader('RISK PARAMETERS', Icons.tune_rounded),
            const SizedBox(height: 12),
            Form(
              key: _riskFormKey,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    _RiskField(
                      controller: _stakeCtrl,
                      label: 'Stake Amount (USD)',
                      hint: '1.00',
                      icon: Icons.attach_money_rounded,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(height: 16),
                    _RiskField(
                      controller: _targetCtrl,
                      label: 'Daily Target (USD)',
                      hint: '10.00',
                      icon: Icons.flag_rounded,
                      color: AppTheme.success,
                    ),
                    const SizedBox(height: 16),
                    _RiskField(
                      controller: _lossCtrl,
                      label: 'Stop Loss (USD)',
                      hint: '5.00',
                      icon: Icons.shield_outlined,
                      color: AppTheme.danger,
                    ),
                    const SizedBox(height: 20),

                    // Risk info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.warning.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppTheme.warning,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Trading involves risk. Only trade with funds you can afford to lose. '
                              'The AI does not guarantee profits.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveRiskSettings,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('SAVE RISK SETTINGS'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ─── Account ──────────────────────────────────────────────────
            _SectionHeader('ACCOUNT', Icons.manage_accounts_rounded),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: AppTheme.danger,
                    ),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(color: AppTheme.danger),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppTheme.textMuted,
                    ),
                    onTap: () => Get.dialog(
                      AlertDialog(
                        backgroundColor: AppTheme.bgCard,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text(
                          'Sign Out?',
                          style: TextStyle(color: AppTheme.textPrimary),
                        ),
                        content: const Text(
                          'You will be returned to the sign-in screen.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: Get.back,
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Get.back();
                              _auth.signOut();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.danger,
                            ),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _saveRiskSettings() {
    if (!_riskFormKey.currentState!.validate()) return;
    _settings.saveRiskSettings(
      stake: double.tryParse(_stakeCtrl.text) ?? 1.0,
      target: double.tryParse(_targetCtrl.text) ?? 10.0,
      loss: double.tryParse(_lossCtrl.text) ?? 5.0,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textMuted,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RiskField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color color;

  const _RiskField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: color),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        final n = double.tryParse(v);
        if (n == null || n <= 0) return 'Enter a positive number';
        return null;
      },
    );
  }
}
