import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/api_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../shared/status_helpers.dart';
import '../shared/error_feedback.dart';
import '../shared/pd_consent.dart';

const _codeLength = 4;

/// Телефон и код на одном экране (задача 021, эталон 10-auth-driver.png):
/// после «Получить код» ниже появляются ячейки кода, вход — сразу после
/// последней цифры. Автоподстановку кода из SMS (Android SMS Retriever /
/// iOS one-time-code) не делаем — платформенная интеграция вне рамок
/// задачи, пользователь вводит код вручную.
class DriverLoginScreen extends ConsumerStatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  ConsumerState<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends ConsumerState<DriverLoginScreen> {
  final _phoneController = TextEditingController();
  final _codeControllers = List.generate(_codeLength, (_) => TextEditingController());
  final _codeFocusNodes = List.generate(_codeLength, (_) => FocusNode());
  String _countryCode = 'KZ';
  bool _sendingCode = false;
  bool _verifying = false;
  bool _resending = false;
  bool _codeRequested = false;
  int _resendCooldown = 60;
  Timer? _timer;

  /// Каналы кода из админки (042 п.3) и выбор водителя; `_sentVia` — куда
  /// код ушёл на самом деле (при сбое сервер берёт следующий канал).
  List<String> _channels = const [];
  String? _channel;
  String? _sentVia;

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    try {
      final channels = await ref.read(authRepositoryProvider).driverCodeChannels();
      if (mounted) setState(() => _channels = channels);
    } catch (e) {
      // Без списка — обычный запрос: сервер сам возьмёт первый канал.
      debugPrint('DriverLoginScreen: channels: $e');
    }
  }

  String get _fullPhone => '${countryDialCodes[_countryCode] ?? '+7'}${_phoneController.text.trim()}';

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _codeControllers) {
      c.dispose();
    }
    for (final f in _codeFocusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _resendCooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown -= 1);
      }
    });
  }

  Future<void> _requestCode() async {
    final t = context.l10n;
    if (_phoneController.text.trim().isEmpty) return;
    setState(() => _sendingCode = true);
    try {
      final via = await ref.read(sessionProvider.notifier).requestDriverCode(_fullPhone, channel: _channel);
      setState(() {
        _codeRequested = true;
        _sentVia = via;
      });
      _startCooldown();
      _codeFocusNodes.first.requestFocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.commonError)));
      }
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  /// `channel` — «Не пришло? Отправить по-другому»: тот же код другим
  /// каналом сразу, без ожидания минуты (сервер это разрешает).
  Future<void> _resend({String? channel}) async {
    if (_resendCooldown > 0 && channel == null) return;
    setState(() => _resending = true);
    try {
      final via = await ref.read(sessionProvider.notifier).requestDriverCode(_fullPhone, channel: channel ?? _sentVia);
      if (mounted) setState(() => _sentVia = via);
      for (final c in _codeControllers) {
        c.clear();
      }
      _startCooldown();
      _codeFocusNodes.first.requestFocus();
    } catch (e) {
      // лимит/сеть — отсчёт не перезапускаем, но причину показываем
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _onCodeDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < _codeLength - 1) {
      _codeFocusNodes[index + 1].requestFocus();
    }
    final code = _codeControllers.map((c) => c.text).join();
    if (code.length == _codeLength) {
      _verify(code);
    }
  }

  Future<void> _verify(String code) async {
    final t = context.l10n;
    setState(() => _verifying = true);
    try {
      await ref.read(sessionProvider.notifier).verifyDriverCode(_fullPhone, code);
      // Дальше решает редирект роутера: если анкеты водителя ещё нет — на
      // регистрацию, иначе сразу в ленту (см. app_router.dart).
    } catch (e) {
      if (mounted) {
        final message = isAccountBlockedError(e)
            ? t.accountBlockedMessage
            : isTooManyAttemptsError(e)
                ? t.driverOtpTooManyAttempts
                : t.driverOtpInvalidCode;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        for (final c in _codeControllers) {
          c.clear();
        }
        _codeFocusNodes.first.requestFocus();
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final referenceData = ref.watch(referenceDataProvider);

    final appLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.driverLoginTitle),
        actions: [
          LanguagePickerButton(
            languageCode: appLocale.languageCode,
            onChanged: (code) => ref.read(localeProvider.notifier).state = Locale(code),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(
          children: [
            const LubaoLogo(height: 36),
            const SizedBox(height: AppSpacing.lg),
            referenceData.when(
              loading: () => const LoadingView(),
              error: (e, st) {
                debugPrint('DriverLoginScreen: $e');
                return ErrorView(message: t.commonError);
              },
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
                      onChanged: _codeRequested
                          ? null
                          : (value) => setState(() => _countryCode = value ?? _countryCode),
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
                    key: const Key('driverLoginPhoneField'),
                    label: t.driverLoginPhoneLabel,
                    hintText: '701 123 45 01',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    enabled: !_codeRequested,
                  ),
                ),
              ],
            ),
            if (!_codeRequested) ...[
              if (_channels.length > 1) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(t.loginChannelTitle, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final c in _channels)
                      ChoiceChip(
                        key: Key('driverLoginChannel-$c'),
                        label: Text(_channelLabel(t, c)),
                        selected: (_channel ?? _channels.first) == c,
                        onSelected: (_) => setState(() => _channel = c),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                key: const Key('driverLoginSendCodeButton'),
                label: t.driverLoginSendCode,
                loading: _sendingCode,
                onPressed: _requestCode,
              ),
              const SizedBox(height: AppSpacing.md),
              const LegalLinks(),
            ] else ...[
              const SizedBox(height: AppSpacing.lg),
              Text(t.driverOtpSubtitle(_fullPhone), style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
              if (_sentVia != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  t.loginCodeSentVia(_channelLabel(t, _sentVia!)),
                  key: const Key('driverLoginSentVia'),
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _codeLength; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 48,
                      height: 56,
                      child: TextField(
                        key: Key('driverLoginCodeDigit$i'),
                        controller: _codeControllers[i],
                        focusNode: _codeFocusNodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        enabled: !_verifying,
                        style: AppTextStyles.headline,
                        decoration: const InputDecoration(counterText: '', border: OutlineInputBorder()),
                        onChanged: (value) => _onCodeDigitChanged(i, value),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (_verifying) const Center(child: CircularProgressIndicator()),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton(
                  onPressed: _resendCooldown > 0 || _resending ? null : _resend,
                  child: Text(
                    _resendCooldown > 0 ? '${t.driverOtpResend} ($_resendCooldown s)' : t.driverOtpResend,
                  ),
                ),
              ),
              if (_channels.where((c) => c != _sentVia).isNotEmpty && _channels.length > 1) ...[
                Center(child: Text(t.loginSendOtherWay, style: AppTextStyles.caption)),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.sm,
                  children: [
                    for (final c in _channels.where((c) => c != _sentVia))
                      TextButton(
                        key: Key('driverLoginResendVia-$c'),
                        onPressed: _resending ? null : () => _resend(channel: c),
                        child: Text(_channelLabel(t, c)),
                      ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

String _channelLabel(LubaoLocalizations t, String channel) => switch (channel) {
      'whatsapp' => t.loginChannelWhatsapp,
      'telegram' => t.loginChannelTelegram,
      _ => t.loginChannelSms,
    };
