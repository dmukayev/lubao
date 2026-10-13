import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/api_providers.dart';
import '../../providers/auth_provider.dart';
import '../shared/status_helpers.dart';
import '../shared/pd_consent.dart';
import '../shared/error_feedback.dart';

/// Регистрация компании — один экран, без предварительного входа (задача
/// 025, заменяет пост-кодовый экран из 022): email, пароль, имя владельца,
/// название компании (+ русское, можно поправить), страна кнопками
/// Китай/Казахстан/Другая. Город не спрашиваем (решение 2026-10-04) — по
/// желанию позже в профиле компании. Телефон для водителей — перед первой
/// публикацией груза (задача 012), не здесь.
class CompanyRegisterScreen extends ConsumerStatefulWidget {
  const CompanyRegisterScreen({super.key});

  @override
  ConsumerState<CompanyRegisterScreen> createState() => _CompanyRegisterScreenState();
}

class _CompanyRegisterScreenState extends ConsumerState<CompanyRegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyNameLatinController = TextEditingController();
  String? _countryId;
  // 058 п.8а: тип компании (по умолчанию экспедитор).
  CompanyKind _kind = CompanyKind.forwarder;
  bool _showAllCountries = false;
  /// 069: латинское название — для китайского названия; логист правит подсказку.
  bool _companyNameLatinTouched = false;
  bool _needsLatin = false;
  Timer? _latinDebounce;
  String? _companyNameLatinError;
  bool _obscurePassword = true;
  bool _offerAccepted = false;
  bool _saving = false;

  String? _emailError;
  String? _passwordError;
  String? _ownerNameError;
  String? _companyNameError;
  String? _countryError;

  @override
  void initState() {
    super.initState();
    _companyNameController.addListener(_onCompanyNameChanged);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _ownerNameController.dispose();
    _companyNameController.dispose();
    _companyNameLatinController.dispose();
    _latinDebounce?.cancel();
    super.dispose();
  }

  /// 069: иероглифы в названии → поле «Название латиницей» с пиньинем (сервер,
  /// локальная библиотека). Кириллица и латиница — поля нет.
  void _onCompanyNameChanged() {
    final name = _companyNameController.text.trim();
    final needs = hasChineseCharacters(name);
    if (needs != _needsLatin) setState(() => _needsLatin = needs);
    _latinDebounce?.cancel();
    if (!needs || _companyNameLatinTouched) return;
    _latinDebounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final suggestion = await ref.read(authRepositoryProvider).latinNameSuggestion(name);
        if (!mounted || _companyNameLatinTouched || _companyNameController.text.trim() != name) return;
        if (suggestion.latin != null) {
          _companyNameLatinController.text = suggestion.latin!;
          setState(() => _companyNameLatinError = null);
        }
      } catch (e) {
        debugPrint('CompanyRegister: latin name suggestion failed: $e');
      }
    });
  }

  void _selectCountry(String id) {
    setState(() {
      _countryId = id;
      _countryError = null;
    });
  }

  Future<void> _submit() async {
    final t = context.l10n;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final ownerName = _ownerNameController.text.trim();
    final companyName = _companyNameController.text.trim();
    setState(() {
      _emailError = email.contains('@') ? null : t.companyRegisterEmailError;
      _passwordError = password.length >= 8 ? null : t.companyRegisterPasswordError;
      _ownerNameError = isValidPersonName(ownerName) ? null : t.driverSetupFullNameError;
      _companyNameError = companyName.length < 2 ? t.companyRegisterNameError : null;
      _companyNameLatinError = _needsLatin && !isValidLatinCompanyName(_companyNameLatinController.text) ? t.companyRegisterLatinError : null;
      _countryError = _countryId == null ? t.companyRegisterCountryError : null;
    });
    if (_emailError != null ||
        _passwordError != null ||
        _ownerNameError != null ||
        _companyNameError != null ||
        _companyNameLatinError != null ||
        _countryError != null) {
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(sessionProvider.notifier).registerCompany(
            email: email,
            password: password,
            ownerName: ownerName,
            companyName: companyName,
            companyNameLatin: _needsLatin ? _companyNameLatinController.text.trim() : null,
            countryId: _countryId!,
            kind: _kind,
          );
      // Дальше решает редирект роутера — сессия с привязанной компанией
      // уводит прямо в кабинет (см. app_router.dart).
    } catch (e) {
      if (mounted) {
        if (isEmailTakenError(e)) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(t.companyRegisterEmailTaken),
            // С кнопкой Flutter не убирает SnackBar сам (persist) — висел до нажатия.
            persist: false,
            action: SnackBarAction(
              label: t.companyLoginTitle,
              onPressed: () => context.push('/login/company', extra: email),
            ),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage(t, e))));
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final referenceData = ref.watch(referenceDataProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.companyRegisterTitle)),
      body: referenceData.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('CompanyRegisterScreen: $e');
          return ErrorView(message: errorMessage(t, e));
        },
        data: (refData) {
          final china = refData.countries.where((c) => c.code == 'CN').firstOrNull;
          final kazakhstan = refData.countries.where((c) => c.code == 'KZ').firstOrNull;
          final otherCountries = refData.countries.where((c) => c.code != 'CN' && c.code != 'KZ').toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              AppTextField(
                key: const Key('companyRegisterEmail'),
                label: t.companyLoginEmailLabel,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                key: const Key('companyRegisterPassword'),
                label: t.adminLoginPasswordLabel,
                controller: _passwordController,
                obscureText: _obscurePassword,
                errorText: _passwordError,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  child: Text(_obscurePassword ? t.companyLoginShowPassword : t.companyLoginHidePassword),
                ),
              ),
              AppTextField(
                key: const Key('companyRegisterOwnerName'),
                label: t.companyRegisterOwnerName,
                controller: _ownerNameController,
                errorText: _ownerNameError,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                key: const Key('companyRegisterCompanyName'),
                label: t.companyRegisterCompanyName,
                controller: _companyNameController,
                errorText: _companyNameError,
              ),
              if (_needsLatin) ...[
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  key: const Key('companyRegisterCompanyNameLatin'),
                  label: t.companyRegisterLatinName,
                  hintText: 'Horgos Ruida Trading',
                  controller: _companyNameLatinController,
                  errorText: _companyNameLatinError,
                  onChanged: (_) {
                    _companyNameLatinTouched = true;
                    if (_companyNameLatinError != null) setState(() => _companyNameLatinError = null);
                  },
                ),
                const SizedBox(height: 4),
                Text(t.companyRegisterLatinHint, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ],
              const SizedBox(height: AppSpacing.xl),
              Text(t.companyRegisterCountry, style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (china != null)
                    SelectableTile(
                      key: const Key('companyRegisterCountryCN'),
                      label: china.name.forLanguageCode(locale),
                      selected: _countryId == china.id,
                      onTap: () => _selectCountry(china.id),
                    ),
                  if (kazakhstan != null)
                    SelectableTile(
                      label: kazakhstan.name.forLanguageCode(locale),
                      selected: _countryId == kazakhstan.id,
                      onTap: () => _selectCountry(kazakhstan.id),
                    ),
                  SelectableTile(
                    label: t.companyRegisterOtherCountry,
                    selected: _showAllCountries,
                    onTap: () => setState(() => _showAllCountries = true),
                  ),
                ],
              ),
              if (_showAllCountries) ...[
                const SizedBox(height: AppSpacing.md),
                InputDecorator(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: otherCountries.any((c) => c.id == _countryId) ? _countryId : null,
                      isExpanded: true,
                      hint: Text(t.companyRegisterOtherCountry),
                      items: otherCountries
                          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name.forLanguageCode(locale))))
                          .toList(),
                      onChanged: (value) => value == null ? null : _selectCountry(value),
                    ),
                  ),
                ),
              ],
              if (_countryError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_countryError!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(t.companyKindTitle, style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final kind in CompanyKind.values)
                    SelectableTile(
                      key: Key('companyRegisterKind-${kind.name}'),
                      label: companyKindLabel(t, kind),
                      selected: _kind == kind,
                      onTap: () => setState(() => _kind = kind),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              // 043 п.2: оферта для компании — без галочки зарегистрироваться нельзя.
              CheckboxListTile(
                key: const Key('companyRegisterOfferCheckbox'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _offerAccepted,
                onChanged: _saving ? null : (v) => setState(() => _offerAccepted = v ?? false),
                title: Text(t.companyRegisterOfferAccept, style: AppTextStyles.body),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  key: const Key('companyRegisterOfferLink'),
                  onPressed: () => openLegalPage(context, 'offer'),
                  child: Text(t.legalOffer),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                key: const Key('companyRegisterSubmit'),
                label: t.companyRegisterSubmit,
                loading: _saving,
                onPressed: _offerAccepted ? _submit : null,
              ),
              const SizedBox(height: AppSpacing.md),
              const LegalNotice(),
            ],
          );
        },
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
