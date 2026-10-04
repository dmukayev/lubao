import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/api_providers.dart';
import '../../providers/auth_provider.dart';

/// Новая компания — один экран после входа по коду на email (задача 022,
/// «Путь А»): имя владельца, название компании (+ русское, можно
/// поправить), страна кнопками Китай/Казахстан/Другая. Город не спрашиваем
/// (решение 2026-10-04) — по желанию позже в профиле компании.
class CompanyRegisterScreen extends ConsumerStatefulWidget {
  const CompanyRegisterScreen({super.key});

  @override
  ConsumerState<CompanyRegisterScreen> createState() => _CompanyRegisterScreenState();
}

class _CompanyRegisterScreenState extends ConsumerState<CompanyRegisterScreen> {
  final _ownerNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyNameRuController = TextEditingController();
  String? _countryId;
  bool _showAllCountries = false;
  bool _companyNameRuTouched = false;
  bool _saving = false;

  String? _ownerNameError;
  String? _companyNameError;
  String? _countryError;

  @override
  void initState() {
    super.initState();
    _companyNameController.addListener(() {
      if (!_companyNameRuTouched) {
        _companyNameRuController.text = _companyNameController.text;
      }
    });
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _companyNameController.dispose();
    _companyNameRuController.dispose();
    super.dispose();
  }

  void _selectCountry(String id) {
    setState(() {
      _countryId = id;
      _countryError = null;
    });
  }

  Future<void> _submit() async {
    final t = context.l10n;
    final ownerName = _ownerNameController.text.trim();
    final companyName = _companyNameController.text.trim();
    setState(() {
      _ownerNameError = isValidPersonName(ownerName) ? null : t.driverSetupFullNameError;
      _companyNameError = companyName.length < 2 ? t.companyRegisterNameError : null;
      _countryError = _countryId == null ? t.companyRegisterCountryError : null;
    });
    if (_ownerNameError != null || _companyNameError != null || _countryError != null) return;

    setState(() => _saving = true);
    try {
      final (company, companyMember) = await ref.read(companyRepositoryProvider).register(
            ownerName: ownerName,
            companyName: companyName,
            companyNameRu: _companyNameRuController.text.trim().isEmpty ? null : _companyNameRuController.text.trim(),
            countryId: _countryId!,
          );
      ref.read(sessionProvider.notifier).updateCompany(company, companyMember);
      // Дальше решает редирект роутера — session.companyMember теперь не
      // null, он уводит в кабинет (см. app_router.dart).
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.commonError)));
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
        error: (e, st) => ErrorView(message: t.commonError),
        data: (refData) {
          final china = refData.countries.where((c) => c.code == 'CN').firstOrNull;
          final kazakhstan = refData.countries.where((c) => c.code == 'KZ').firstOrNull;
          final otherCountries = refData.countries.where((c) => c.code != 'CN' && c.code != 'KZ').toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              AppTextField(
                label: t.companyRegisterOwnerName,
                controller: _ownerNameController,
                errorText: _ownerNameError,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: t.companyRegisterCompanyName,
                controller: _companyNameController,
                errorText: _companyNameError,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: t.companyRegisterCompanyNameRu,
                controller: _companyNameRuController,
                onChanged: (_) => _companyNameRuTouched = true,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(t.companyRegisterCountry, style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (china != null)
                    SelectableTile(
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
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(label: t.companyRegisterSubmit, loading: _saving, onPressed: _submit),
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
