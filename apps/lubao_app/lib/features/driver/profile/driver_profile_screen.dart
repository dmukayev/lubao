import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/locale_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../shared/delete_account.dart';
import '../../shared/pd_consent.dart';

class DriverProfileScreen extends ConsumerStatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  ConsumerState<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends ConsumerState<DriverProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Сессия обновляется из /auth/me только при холодном старте приложения
    // (SessionController._restore) — если админ подтвердил верификацию, пока
    // водитель уже был в приложении, бейдж и баннер молча показывали старый
    // статус. Перетягиваем свежий профиль при каждом открытии вкладки.
    _refreshDriver();
  }

  Future<void> _refreshDriver() async {
    try {
      final fresh = await ref.read(driverRepositoryProvider).me();
      if (mounted) ref.read(sessionProvider.notifier).updateDriver(fresh);
    } catch (e) {
      debugPrint('DriverProfileScreen: failed to refresh driver status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final session = ref.watch(sessionProvider);
    final driver = session?.driver;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.profileTitle),
        actions: [IconButton(icon: const Icon(LucideIcons.pencil), onPressed: () => context.push('/driver/setup'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(driver?.fullName ?? '', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(LucideIcons.star, size: 16, color: Colors.amber),
              Text(driver == null ? ' —' : ' ${formatRating(driver.ratingAvg, driver.ratingCount)}${driver.ratingCount == 0 ? '' : ' (${driver.ratingCount})'}'),
              const SizedBox(width: 12),
              StatusBadge(
                label: (driver?.isVerified ?? false) ? t.profileVerified : t.profileNotVerified,
                color: (driver?.isVerified ?? false) ? StatusBadge.success : StatusBadge.neutral,
              ),
            ],
          ),
          if (!(driver?.isVerified ?? false)) ...[
            const SizedBox(height: AppSpacing.lg),
            _CompletenessBanner(driver: driver),
          ],
          const Divider(height: 32),
          ListTile(
            leading: const Icon(LucideIcons.phone),
            title: Text(t.profilePhone),
            subtitle: Text(session?.user.phone ?? '-'),
          ),
          ListTile(
            leading: const Icon(LucideIcons.languages),
            title: Text(t.profileLanguage),
            trailing: DropdownButton<Locale>(
              value: locale,
              items: const [
                DropdownMenuItem(value: Locale('kk'), child: Text('Қазақша')),
                DropdownMenuItem(value: Locale('ru'), child: Text('Русский')),
                DropdownMenuItem(value: Locale('zh'), child: Text('中文')),
                DropdownMenuItem(value: Locale('en'), child: Text('English')),
              ],
              onChanged: (value) {
                if (value != null) ref.read(sessionProvider.notifier).setLocale(value.languageCode);
              },
            ),
          ),
          ListTile(
            leading: const Icon(LucideIcons.truck),
            title: Text(t.garageGoToGarage),
            onTap: () => context.push('/driver/garage'),
          ),
          ListTile(
            leading: const Icon(LucideIcons.smartphone),
            title: Text(t.profileMyDevices),
            onTap: () => context.push('/devices'),
          ),
          ListTile(
            leading: const Icon(LucideIcons.bell),
            title: Text(t.profileNotificationSettings),
            onTap: () => context.push('/notifications/settings'),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            key: const Key('driverProfileLogoutButton'),
            onPressed: () => ref.read(sessionProvider.notifier).logout(),
            child: Text(t.profileLogout),
          ),
          const SizedBox(height: 8),
          const DeleteAccountButton(),
          const LegalLinks(),
        ],
      ),
    );
  }
}

/// Задача 032, п.13 (038) — верификация ЛИЧНОСТИ: только селфи и права;
/// техпаспорта живут у машин в гараже (задача 031, этап A) и на процент
/// готовности профиля не влияют.
const _requiredDriverDocTypes = [
  VerificationDocType.selfie,
  VerificationDocType.driverLicense,
];

class _CompletenessBanner extends ConsumerWidget {
  const _CompletenessBanner({required this.driver});

  final Driver? driver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final pending = driver?.verificationStatus == DriverVerificationStatus.pending;
    // Процент считается по факту одобренных обязательных документов, а не
    // по захардкоженной константе 60/80 — та не менялась независимо от
    // реального прогресса проверки (причина жалобы «висит 60% после
    // верификации в админке»).
    final docs = ref.watch(driverVerificationDocumentsProvider).valueOrNull ?? const [];
    final approvedCount =
        docs.where((d) => _requiredDriverDocTypes.contains(d.type) && d.status == VerificationDocStatus.approved).length;
    final percent = (approvedCount / _requiredDriverDocTypes.length * 100).round();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(t.profileCompleteness(percent), style: AppTextStyles.body),
          if (!pending) ...[
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              key: const Key('driverProfileVerifyButton'),
              label: t.driverVerificationRequiredAction,
              onPressed: () => context.push('/driver/verification'),
            ),
          ],
        ],
      ),
    );
  }
}
