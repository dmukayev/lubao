import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/api_providers.dart';
import '../../providers/auth_provider.dart';

class DriverLoginScreen extends ConsumerStatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  ConsumerState<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends ConsumerState<DriverLoginScreen> {
  final _phoneController = TextEditingController();
  String _countryCode = 'KZ';
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = context.l10n;
    final dialCode = countryDialCodes[_countryCode] ?? '+7';
    final fullPhone = '$dialCode${_phoneController.text.trim()}';
    setState(() => _loading = true);
    try {
      await ref.read(sessionProvider.notifier).requestDriverCode(fullPhone);
      if (mounted) context.push('/login/driver/otp', extra: fullPhone);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.commonError)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final referenceData = ref.watch(referenceDataProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.driverLoginTitle)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(
          children: [
            referenceData.when(
              loading: () => const LoadingView(),
              error: (e, st) => ErrorView(message: t.commonError),
              data: (refData) {
                final countries = refData.countries.where((c) => countryDialCodes.containsKey(c.code)).toList();
                return InputDecorator(
                  decoration: InputDecoration(labelText: t.driverLoginCountryLabel, border: const OutlineInputBorder()),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _countryCode,
                      isExpanded: true,
                      items: countries
                          .map((c) => DropdownMenuItem(
                                value: c.code,
                                child: Text('${c.name.forLanguageCode(locale)}  ${countryDialCodes[c.code]}'),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _countryCode = value ?? _countryCode),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppRadius.field),
                  ),
                  child: Text(countryDialCodes[_countryCode] ?? '+7'),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppTextField(
                    label: t.driverLoginPhoneLabel,
                    hintText: '701 123 45 01',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: t.driverLoginSendCode, loading: _loading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
